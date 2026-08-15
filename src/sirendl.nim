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

import random, os, strutils
import cli, album_processor, album_list

proc printUsage(prog: string) =
  echo "用法: ", prog, " -id <专辑ID>"
  echo "示例: ", prog, " -id 9375"
  echo "也支持: ", prog, " -i 9375"
  echo "或者: ", prog, " 9375"
  echo "列出专辑: ", prog, " -l"
  echo "或者: ", prog, " --list"

when isMainModule:
  randomize()
  let opts = parseCommandLine()

  if opts.help:
    printUsage(getAppFilename().extractFilename)
    quit(0)

  if opts.list:
    try:
      let summaries = getAlbumSummaries()
      let count = min(summaries.len, 10)
      echo "最新专辑列表（共 ", summaries.len, " 张，显示前 ", count, " 张）:"
      for i in 0 ..< count:
        var line = $(i + 1) & ". " & summaries[i].name
        if summaries[i].artistes.len > 0:
          line.add(" (" & summaries[i].artistes.join(", ") & ")")
        line.add(" (ID: " & summaries[i].cid & ")")
        echo line
    except:
      echo "获取专辑列表失败: ", getCurrentExceptionMsg()
      quit(1)
    quit(0)

  if opts.albumId.len == 0:
    printUsage(getAppFilename().extractFilename)
    quit(1)

  echo "开始处理专辑ID: ", opts.albumId
  if processAlbum(opts.albumId):
    echo "\n专辑处理完成！"
  else:
    echo "\n处理失败，请检查错误信息"
    quit(1)
