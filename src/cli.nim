# src/cli.nim
import os, strutils

type CliResult* = object
  albumId*: string
  help*: bool

proc parseCommandLine*(): CliResult =
  var albumId = ""
  var help = false
  var args = commandLineParams()
  var i = 0
  while i < args.len:
    let arg = args[i]
    if arg == "-h" or arg == "--help":
      help = true
    elif arg.startsWith("-id="):
      albumId = arg[4..^1]
    elif arg == "-id" or arg == "-i":
      inc i
      if i < args.len:
        albumId = args[i]
    else:
      if albumId.len == 0:
        albumId = arg
    inc i
  return CliResult(albumId: albumId, help: help)
