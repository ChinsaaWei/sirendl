# sirendl - A MonsterSiren music downloader
# Copyright (C) 2026 ChinsaaWei
# SPDX-License-Identifier: GPL-3.0-only
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

import httpclient, json, os, osproc, strutils, random, sequtils
import types, downloader, utils

const BASE_API_URL* = "https://monster-siren.hypergryph.com/api"

type
  AlbumProcessResult* = enum
    aprSuccess, aprFailed, aprCancelled

  SongInfo* = object
    name*: string
    cid*: string
    sourceUrl*: string
    ext*: string
    size*: int64
    errorMsg*: string

  AlbumDownloadInfo* = object
    albumId*: string
    albumName*: string
    coverUrl*: string
    songs*: seq[SongInfo]

proc getFileSize(client: HttpClient, url: string): int64 =
  try:
    let resp = client.head(url)
    if resp.code != Http200:
      return 0
    let contentLength = resp.headers.getOrDefault("Content-Length")
    if contentLength.len == 0:
      return 0
    return contentLength.parseInt()
  except:
    return 0

proc formatSize(bytes: int64): string =
  if bytes <= 0:
    return "-"
  if bytes >= 1024 * 1024:
    return formatFloat(bytes / (1024 * 1024), ffDecimal, 1) & " MB"
  if bytes >= 1024:
    return formatFloat(bytes / 1024, ffDecimal, 1) & " KB"
  return $bytes & " B"

proc fetchAlbum*(albumId: string): AlbumDownloadInfo =
  let client = newHttpClient(timeout = 30_000)
  client.headers = newHttpHeaders({
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:153.0) Gecko/20100101 Firefox/153.0"
  })

  let albumUrl = BASE_API_URL & "/album/" & albumId & "/detail"
  var resp = client.get(albumUrl)
  if resp.code != Http200:
    raise newException(IOError, "获取专辑详情失败: " & resp.status)

  var albumResp: AlbumResponse
  try:
    albumResp = resp.body.parseJson().to(AlbumResponse)
  except:
    raise newException(ValueError, "解析专辑数据失败: " & getCurrentExceptionMsg())

  if albumResp.code != 0:
    raise newException(IOError, "API返回错误: " & albumResp.msg)

  let albumData = albumResp.data
  var albumName = sanitizeFilename(albumData.name)
  if albumName.len == 0: albumName = "未知专辑"

  echo "正在获取歌曲信息..."
  var songInfos: seq[SongInfo]
  for song in albumData.songs:
    let songName = sanitizeFilename(song.name)
    let finalName = if songName.len > 0: songName else: "未知歌曲"

    let songUrl = BASE_API_URL & "/song/" & song.cid
    resp = client.get(songUrl)
    if resp.code != Http200:
      songInfos.add(SongInfo(name: finalName, cid: song.cid,
                             errorMsg: "获取失败 (HTTP " & resp.status & ")"))
      continue

    var songResp: SongResponse
    try:
      songResp = resp.body.parseJson().to(SongResponse)
    except:
      songInfos.add(SongInfo(name: finalName, cid: song.cid,
                             errorMsg: "解析数据失败"))
      continue

    if songResp.code != 0:
      songInfos.add(SongInfo(name: finalName, cid: song.cid,
                             errorMsg: songResp.msg))
      continue

    let sourceUrl = songResp.data.sourceUrl
    if sourceUrl.len == 0:
      songInfos.add(SongInfo(name: finalName, cid: song.cid,
                             errorMsg: "无下载链接"))
      continue

    songInfos.add(SongInfo(name: finalName, cid: song.cid,
                           sourceUrl: sourceUrl, ext: getFileExtension(sourceUrl),
                           size: getFileSize(client, sourceUrl)))

  return AlbumDownloadInfo(albumId: albumId, albumName: albumName,
                           coverUrl: albumData.coverUrl, songs: songInfos)

proc printAlbumSummary*(album: AlbumDownloadInfo) =
  var headers = @["序号", "歌曲名称", "文件格式", "WAV大小"]
  var rows: seq[seq[string]]
  for i, info in album.songs:
    let ext = if info.ext.len > 0: info.ext else: "-"
    rows.add(@[$(i + 1), info.name, ext, formatSize(info.size)])
  echo "\n专辑 [", album.albumName, "] 歌曲列表（共 ", album.songs.len, " 首）:"
  printTable(headers, rows)

proc processAlbum*(album: AlbumDownloadInfo): AlbumProcessResult =
  let albumName = album.albumName
  let downloadableCount = album.songs.countIt(it.sourceUrl.len > 0)
  if downloadableCount == 0:
    echo "[", albumName, "] 没有可下载的歌曲"
    return aprFailed

  let baseDir = getHomeDir() / "Data" / "MonsterSiren"
  let albumDir = baseDir / albumName
  let wavDir = albumDir / "wav"
  let flacDir = albumDir / "flac"
  createDir(albumDir); createDir(wavDir); createDir(flacDir)
  echo "创建专辑文件夹: ", albumDir

  if album.coverUrl.len > 0:
    let coverExt = getFileExtension(album.coverUrl)
    let coverPath = albumDir / ("cover" & coverExt)
    if downloadFile(album.coverUrl, coverPath):
      echo "封面下载成功: ", coverPath
    else:
      echo "封面下载失败"

  for info in album.songs:
    if info.sourceUrl.len == 0:
      echo "跳过 ", info.name, ": ", info.errorMsg
      continue
    let songPath = wavDir / (info.name & info.ext)
    if downloadFile(info.sourceUrl, songPath):
      echo "下载成功到wav文件夹: ", info.name, info.ext
    else:
      echo "下载失败: ", info.name

    sleep(rand(400) + 100)

  echo "开始转换WAV文件到FLAC格式..."
  var coverPath = albumDir / "cover.jpg"
  if not fileExists(coverPath):
    for f in walkFiles(albumDir / "cover.*"):
      let lower = toLowerAscii(f)
      if lower.endsWith(".jpg") or lower.endsWith(".jpeg") or lower.endsWith(".png"):
        coverPath = f
        break

  for wavFile in walkFiles(wavDir / "*.wav"):
    let flacFile = flacDir / (splitFile(wavFile).name & ".flac")
    var args: seq[string]
    if fileExists(coverPath):
      args = @["-i", wavFile, "-i", coverPath, "-map", "0:a", "-map", "1",
                "-c:a", "flac", "-c:v:0", "mjpeg",
                "-metadata:s:v", "title=cover",
                "-metadata:s:v", "comment=Cover (front)",
                "-metadata", "artist=MonsterSirenRecord",
                "-disposition:v:0", "attached_pic", flacFile]
    else:
      args = @["-i", wavFile, "-c:a", "flac",
                "-metadata", "artist=MonsterSirenRecord", flacFile]

    let cmd = "ffmpeg " & args.map(quoteShell).join(" ")
    let (output, exitCode) = execCmdEx(cmd)

    if exitCode == 0:
      echo "转换成功: ", extractFilename(wavFile), " -> ", extractFilename(flacFile)
    else:
      echo "转换失败: ", extractFilename(wavFile), " (返回码: ", exitCode, ")"
      if output.len > 0:
        echo "错误信息: ", output

  echo "WAV到FLAC转换完成！"
  return aprSuccess

proc runDownload*(albumIds: seq[string]): int =
  var albums: seq[AlbumDownloadInfo]
  var fetchFailed = false
  for i, albumId in albumIds:
    if albumIds.len > 1:
      echo "\n=== [", i + 1, "/", albumIds.len, "] 获取专辑ID: ", albumId, " ==="
    try:
      albums.add(fetchAlbum(albumId))
    except:
      echo "获取专辑 ", albumId, " 失败: ", getCurrentExceptionMsg()
      fetchFailed = true

  if albums.len == 0:
    echo "\n没有可处理的专辑"
    return 1

  let totalSongs = albums.mapIt(it.songs.countIt(it.sourceUrl.len > 0)).foldl(a + b)
  echo "\n共获取到 ", albums.len, " 张专辑，", totalSongs, " 首可下载歌曲："
  for album in albums:
    printAlbumSummary(album)

  stdout.write("是否开始按顺序下载以上 ", albums.len, " 张专辑共 ", totalSongs, " 首歌曲? [Y/n]: ")
  var answer = ""
  try:
    answer = readLine(stdin).strip().toLowerAscii()
  except EOFError:
    answer = "n"
  if answer.len > 0 and answer[0] == 'n':
    echo "已取消下载"
    return 0

  var failed = fetchFailed
  for i, album in albums:
    if albums.len > 1:
      echo "\n=== [", i + 1, "/", albums.len, "] 处理专辑: ", album.albumName, " ==="
    case processAlbum(album)
    of aprSuccess:
      echo "\n专辑处理完成！"
    of aprCancelled:
      echo "\n已取消下载"
    of aprFailed:
      echo "\n处理失败，请检查错误信息"
      failed = true
  if failed:
    return 1
  return 0
