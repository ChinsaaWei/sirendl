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

import os

type CliResult* = object
  command*: string
  albumId*: string
  help*: bool
  errorMsg*: string

proc parseCommandLine*(): CliResult =
  var command = ""
  var albumId = ""
  var help = false
  for arg in commandLineParams():
    if arg == "-h" or arg == "--help":
      help = true
    elif command.len == 0 and (arg == "download" or arg == "list"):
      command = arg
    elif albumId.len == 0:
      albumId = arg

  var errorMsg = ""
  if not help:
    case command
    of "download":
      if albumId.len == 0:
        errorMsg = "download 命令需要一个专辑ID"
    of "":
      errorMsg = "未知命令"
    else:
      discard

  return CliResult(command: command, albumId: albumId, help: help, errorMsg: errorMsg)

proc printUsage*(prog: string) =
  echo "用法: ", prog, " <命令> [参数]"
  echo ""
  echo "命令:"
  echo "  download <专辑ID>  下载指定专辑"
  echo "  list               列出专辑"
  echo "  -h, --help         显示帮助"
  echo ""
  echo "示例: ", prog, " download 9375"
  echo "      ", prog, " list"

proc printCliError*(opts: CliResult, prog: string) =
  if opts.errorMsg.len == 0:
    return
  case opts.command
  of "download":
    echo "错误: ", opts.errorMsg
    echo "用法: ", prog, " download <专辑ID>"
  else:
    echo "错误: ", opts.errorMsg
    printUsage(prog)
