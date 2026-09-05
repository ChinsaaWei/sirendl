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
import types, downloader, utils, i18n

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
    raise newException(IOError, t("error.fetch_album_failed") & resp.status)

  var albumResp: AlbumResponse
  try:
    albumResp = resp.body.parseJson().to(AlbumResponse)
  except:
    raise newException(ValueError, t("error.parse_album_failed") & getCurrentExceptionMsg())

  if albumResp.code != 0:
    raise newException(IOError, t("error.api_error") & albumResp.msg)

  let albumData = albumResp.data
  var albumName = sanitizeFilename(albumData.name)
  if albumName.len == 0: albumName = t("misc.unknown_album")

  echo t("status.fetch_tracks")
  var songInfos: seq[SongInfo]
  for song in albumData.songs:
    let songName = sanitizeFilename(song.name)
    let finalName = if songName.len > 0: songName else: t("misc.unknown_track")

    let songUrl = BASE_API_URL & "/song/" & song.cid
    resp = client.get(songUrl)
    if resp.code != Http200:
      songInfos.add(SongInfo(name: finalName, cid: song.cid,
                             errorMsg: t("error.song_http_failed") % [resp.status]))
      continue

    var songResp: SongResponse
    try:
      songResp = resp.body.parseJson().to(SongResponse)
    except:
      songInfos.add(SongInfo(name: finalName, cid: song.cid,
                             errorMsg: t("error.song_parse_failed")))
      continue

    if songResp.code != 0:
      songInfos.add(SongInfo(name: finalName, cid: song.cid,
                             errorMsg: songResp.msg))
      continue

    let sourceUrl = songResp.data.sourceUrl
    if sourceUrl.len == 0:
      songInfos.add(SongInfo(name: finalName, cid: song.cid,
                             errorMsg: t("error.song_no_link")))
      continue

    songInfos.add(SongInfo(name: finalName, cid: song.cid,
                           sourceUrl: sourceUrl, ext: getFileExtension(sourceUrl),
                           size: getFileSize(client, sourceUrl)))

  return AlbumDownloadInfo(albumId: albumId, albumName: albumName,
                           coverUrl: albumData.coverUrl, songs: songInfos)

proc printAlbumSummary*(album: AlbumDownloadInfo) =
  var headers = @[t("table.col_no"), t("table.col_track"), t("table.col_format"), t("table.col_wav_size")]
  var rows: seq[seq[string]]
  for i, info in album.songs:
    let ext = if info.ext.len > 0: info.ext else: "-"
    rows.add(@[$(i + 1), info.name, ext, formatSize(info.size)])
  echo t("album.summary") % [album.albumName, $(album.songs.len)]
  printTable(headers, rows)

proc processAlbum*(album: AlbumDownloadInfo): AlbumProcessResult =
  let albumName = album.albumName
  let downloadableCount = album.songs.countIt(it.sourceUrl.len > 0)
  if downloadableCount == 0:
    echo t("album.no_downloadable") % [albumName]
    return aprFailed

  let baseDir = getHomeDir() / "Data" / "MonsterSiren"
  let albumDir = baseDir / albumName
  let wavDir = albumDir / "wav"
  let flacDir = albumDir / "flac"
  createDir(albumDir); createDir(wavDir); createDir(flacDir)
  echo t("status.creating_folder"), albumDir

  if album.coverUrl.len > 0:
    let coverExt = getFileExtension(album.coverUrl)
    let coverPath = albumDir / ("cover" & coverExt)
    if downloadFile(album.coverUrl, coverPath):
      echo t("status.cover_downloaded"), coverPath
    else:
      echo t("status.cover_failed")

  for info in album.songs:
    if info.sourceUrl.len == 0:
      echo t("status.skipping") % [info.name, info.errorMsg]
      continue
    let songPath = wavDir / (info.name & info.ext)
    if downloadFile(info.sourceUrl, songPath):
      echo t("status.track_downloaded") % [info.name & info.ext]
    else:
      echo t("status.track_failed") % [info.name]

    sleep(rand(400) + 100)

  echo t("status.converting")
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
      echo t("status.converted") % [extractFilename(wavFile), extractFilename(flacFile)]
    else:
      echo t("status.convert_failed") % [extractFilename(wavFile), $exitCode]
      if output.len > 0:
        echo t("status.convert_output"), output

  echo t("status.conversion_done")
  return aprSuccess

proc runDownload*(albumIds: seq[string]): int =
  var albums: seq[AlbumDownloadInfo]
  var fetchFailed = false
  for i, albumId in albumIds:
    if albumIds.len > 1:
      echo t("progress.fetch_album") % [$(i + 1), $(albumIds.len), albumId]
    try:
      albums.add(fetchAlbum(albumId))
    except:
      echo t("error.fetch_album_run") % [albumId, getCurrentExceptionMsg()]
      fetchFailed = true

  if albums.len == 0:
    echo t("error.no_albums")
    return 1

  let totalSongs = albums.mapIt(it.songs.countIt(it.sourceUrl.len > 0)).foldl(a + b)
  echo t("progress.summary_overview") % [$(albums.len), $(totalSongs)]
  for album in albums:
    printAlbumSummary(album)

  stdout.write(t("prompt.confirm") % [$(albums.len), $(totalSongs)])
  var answer = ""
  try:
    answer = readLine(stdin).strip().toLowerAscii()
  except EOFError:
    answer = "n"
  if answer.len > 0 and answer[0] == 'n':
    echo t("status.cancelled")
    return 0

  var failed = fetchFailed
  for i, album in albums:
    if albums.len > 1:
      echo t("progress.processing_album") % [$(i + 1), $(albums.len), album.albumName]
    case processAlbum(album)
    of aprSuccess:
      echo t("status.album_done")
    of aprCancelled:
      echo t("status.cancelled_nl")
    of aprFailed:
      echo t("error.process_failed")
      failed = true
  if failed:
    return 1
  return 0
