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

import algorithm, httpclient, json, strutils, unicode
import types, utils

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

proc fuzzyMatchScore*(query, name: string): int =
  if query.len == 0:
    return 0
  let q = toLower(query).toRunes
  let n = toLower(name).toRunes
  var qi = 0
  var score = 0
  var prevIdx = -1
  for i in 0 ..< n.len:
    if qi < q.len and n[i] == q[qi]:
      if i == 0:
        score += 5
      if prevIdx >= 0 and i == prevIdx + 1:
        score += 3
      score += 1
      prevIdx = i
      inc qi
  if qi < q.len:
    return 0
  if query.toLower in name.toLower:
    score += 10
  return score

proc searchAlbumSummaries*(summaries: seq[AlbumSummary], keyword: string): seq[AlbumSummary] =
  var scored: seq[tuple[score: int, album: AlbumSummary]]
  for s in summaries:
    let score = fuzzyMatchScore(keyword, s.name)
    if score > 0:
      scored.add((score, s))
  scored.sort(proc(a, b: tuple[score: int, album: AlbumSummary]): int =
    b.score - a.score)
  for item in scored:
    result.add(item.album)

proc printSearchResults*(results: seq[AlbumSummary], keyword: string) =
  if results.len == 0:
    echo "未找到匹配 \"", keyword, "\" 的专辑"
    return
  var headers = @["序号", "ID", "专辑名称", "艺术家"]
  var rows: seq[seq[string]]
  for i in 0 ..< results.len:
    let s = results[i]
    let artist = if s.artistes.len > 0: s.artistes.join(", ") else: "-"
    rows.add(@[$(i + 1), s.cid, s.name, artist])
  echo "搜索 \"", keyword, "\" 找到 ", results.len, " 张专辑:"
  printTable(headers, rows)

proc printAlbumTable*(summaries: seq[AlbumSummary], maxCount: int) =
  let count = min(summaries.len, maxCount)

  var headers = @["序号", "ID", "专辑名称", "艺术家"]
  var rows: seq[seq[string]]
  for i in 0 ..< count:
    let s = summaries[i]
    let artist = if s.artistes.len > 0: s.artistes.join(", ") else: "-"
    rows.add(@[$(i + 1), s.cid, s.name, artist])

  echo "最新专辑列表（共 ", summaries.len, " 张，显示前 ", count, " 张）:"
  printTable(headers, rows)
