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

import os, strutils, i18n

type CliResult* = object
  command*: string
  albumIds*: seq[string]
  searchKeyword*: string
  listCount*: int
  help*: bool
  errorMsg*: string

proc parseCommandLine*(): CliResult =
  var command = ""
  var albumIds: seq[string]
  var searchKeyword = ""
  var listCount = 10
  var countErr = ""
  var help = false
  var hasCount = false
  for arg in commandLineParams():
    if arg == "-h" or arg == "--help":
      help = true
    elif command.len == 0 and (arg == "download" or arg == "list" or arg == "search"):
      command = arg
    elif command == "download":
      albumIds.add(arg)
    elif command == "search" and searchKeyword.len == 0:
      searchKeyword = arg
    elif command == "list" and not hasCount:
      hasCount = true
      if arg.len > 0 and arg.allCharsInSet(Digits):
        listCount = parseInt(arg)
      else:
        countErr = t("error.list_count_invalid")

  var errorMsg = ""
  if not help:
    case command
    of "download":
      if albumIds.len == 0:
        errorMsg = t("error.download_requires_id")
    of "search":
      if searchKeyword.len == 0:
        errorMsg = t("error.search_requires_keyword")
    of "list":
      if countErr.len > 0:
        errorMsg = countErr
    of "":
      errorMsg = t("error.unknown_command")
    else:
      discard

  return CliResult(command: command, albumIds: albumIds, searchKeyword: searchKeyword,
                   listCount: listCount, help: help, errorMsg: errorMsg)

proc printUsage*(prog: string) =
  echo t("usage.title") % [prog]
  echo ""
  echo t("usage.commands")
  echo t("usage.download_line")
  echo t("usage.list_line")
  echo t("usage.search_line")
  echo t("usage.help_line")
  echo ""
  echo t("usage.examples")
  echo t("usage.example_download") % [prog]
  echo t("usage.example_list") % [prog]
  echo t("usage.example_list15") % [prog]
  echo t("usage.example_search") % [prog]

proc printCliError*(opts: CliResult, prog: string) =
  if opts.errorMsg.len == 0:
    return
  echo t("error.prefix"), opts.errorMsg
  case opts.command
  of "download":
    echo t("usage.download_inline") % [prog]
  else:
    printUsage(prog)
