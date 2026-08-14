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

import random, os
import cli, album_processor

when isMainModule:
  randomize()
  let opts = parseCommandLine()   # 改名，避免冲突

  if opts.help or opts.albumId.len == 0:
    echo "用法: ", getAppFilename().extractFilename, " -id <专辑ID>"
    echo "示例: ", getAppFilename().extractFilename, " -id 9375"
    echo "也支持: ", getAppFilename().extractFilename, " -i 9375"
    echo "或者: ", getAppFilename().extractFilename, " 9375"
    quit(if opts.help: 0 else: 1)

  echo "开始处理专辑ID: ", opts.albumId
  if processAlbum(opts.albumId):
    echo "\n专辑处理完成！"
  else:
    echo "\n处理失败，请检查错误信息"
    quit(1)
