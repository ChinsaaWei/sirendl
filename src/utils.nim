# src/utils.nim
import uri, os

proc sanitizeFilename*(name: string): string =
  result = ""
  for ch in name:
    if ch notin ['/', '\\', ':', '*', '?', '"', '<', '>', '|']:
      result.add(ch)

proc getFileExtension*(path: string): string =
  try:
    let u = parseUri(path)
    let ext = splitFile(u.path).ext
    if ext.len == 0: ".wav" else: ext
  except:
    ".wav"
