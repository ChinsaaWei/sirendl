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
