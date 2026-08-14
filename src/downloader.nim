# src/downloader.nim
import httpclient, streams, strutils

const DEFAULT_USER_AGENT* = "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:147.0) Gecko/20100101 Firefox/147.0"

proc downloadFile*(url: string, savePath: string, timeout = 30_000): bool =
  let client = newHttpClient(timeout = timeout)
  client.headers = newHttpHeaders({
    "User-Agent": DEFAULT_USER_AGENT
  })
  try:
    let resp = client.get(url)
    if resp.code != Http200:
      echo "HTTP请求失败: ", resp.status
      return false
    var file = open(savePath, fmWrite)
    defer: file.close()
    var buffer: array[8192, byte]
    while true:
      let n = resp.bodyStream.readData(addr buffer[0], 8192)
      if n == 0: break
      discard file.writeBytes(buffer, 0, n)
    return true
  except:
    echo "下载失败: ", getCurrentExceptionMsg()
    return false
