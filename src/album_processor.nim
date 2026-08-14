# src/album_processor.nim
import httpclient, json, os, osproc, strutils, random, sequtils
import types, downloader, utils

const BASE_API_URL* = "https://monster-siren.hypergryph.com/api"

proc processAlbum*(albumId: string): bool =
  let client = newHttpClient(timeout = 30_000)
  client.headers = newHttpHeaders({
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:153.0) Gecko/20100101 Firefox/153.0"
  })

  let albumUrl = BASE_API_URL & "/album/" & albumId & "/detail"
  var resp = client.get(albumUrl)
  if resp.code != Http200:
    echo "获取专辑详情失败: ", resp.status
    return false

  var albumResp: AlbumResponse
  try:
    albumResp = resp.body.parseJson().to(AlbumResponse)
  except:
    echo "解析专辑数据失败: ", getCurrentExceptionMsg()
    return false

  if albumResp.code != 0:
    echo "API返回错误: ", albumResp.msg
    return false

  let albumData = albumResp.data
  var albumName = sanitizeFilename(albumData.name)
  if albumName.len == 0: albumName = "未知专辑"
  echo "处理专辑: ", albumName

  let baseDir = getHomeDir() / "Data" / "MonsterSiren"
  let albumDir = baseDir / albumName
  let wavDir = albumDir / "wav"
  let flacDir = albumDir / "flac"
  createDir(albumDir); createDir(wavDir); createDir(flacDir)
  echo "创建专辑文件夹: ", albumDir

  if albumData.coverUrl.len > 0:
    let coverExt = getFileExtension(albumData.coverUrl)
    let coverPath = albumDir / ("cover" & coverExt)
    if downloadFile(albumData.coverUrl, coverPath):
      echo "封面下载成功: ", coverPath
    else:
      echo "封面下载失败"

  let songs = albumData.songs
  echo "找到 ", songs.len, " 首歌曲"
  for song in songs:
    let songName = sanitizeFilename(song.name)
    let finalName = if songName.len > 0: songName else: "未知歌曲"

    let songUrl = BASE_API_URL & "/song/" & song.cid
    resp = client.get(songUrl)
    if resp.code != Http200:
      echo "获取歌曲详情失败: ", finalName, " (HTTP ", resp.status, ")"
      continue

    var songResp: SongResponse
    try:
      songResp = resp.body.parseJson().to(SongResponse)
    except:
      echo "解析歌曲数据失败: ", finalName
      continue

    if songResp.code != 0:
      echo "歌曲API返回错误: ", finalName, ": ", songResp.msg
      continue

    let sourceUrl = songResp.data.sourceUrl
    if sourceUrl.len == 0:
      echo "歌曲 ", finalName, " 无下载链接"
      continue

    let songExt = getFileExtension(sourceUrl)
    let songPath = wavDir / (finalName & songExt)
    if downloadFile(sourceUrl, songPath):
      echo "下载成功到wav文件夹: ", finalName, songExt
    else:
      echo "下载失败: ", finalName

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
  return true
