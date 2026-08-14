# sirendl - A MonsterSiren song downloader
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
