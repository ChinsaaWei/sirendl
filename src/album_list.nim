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

import httpclient, json
import types

const BASE_API_URL = "https://monster-siren.hypergryph.com/api"

proc getAlbumSummaries*(): seq[AlbumSummary] =
  let client = newHttpClient(timeout = 30_000)
  client.headers = newHttpHeaders({
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:153.0) Gecko/20100101 Firefox/153.0"
  })

  let resp = client.get(BASE_API_URL & "/albums")
  if resp.code != Http200:
    raise newException(IOError, "获取专辑列表失败: " & resp.status)

  var albumsResp: AlbumsResponse
  try:
    albumsResp = resp.body.parseJson().to(AlbumsResponse)
  except:
    raise newException(IOError, "解析专辑列表数据失败: " & getCurrentExceptionMsg())

  if albumsResp.code != 0:
    raise newException(IOError, "API返回错误: " & albumsResp.msg)

  return albumsResp.data
