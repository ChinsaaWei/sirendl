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

import uri, os, strutils, unicode

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

proc displayWidth(s: string): int =
  for r in s.runes:
    if ord(r) < 0x80:
      inc result
    else:
      inc result, 2

proc padRight(s: string, width: int): string =
  result = s
  for _ in 0 ..< max(width - displayWidth(s), 0):
    result.add(' ')

proc printTable*(headers: seq[string], rows: seq[seq[string]]) =
  let colCount = headers.len
  if colCount == 0:
    return

  var widths = newSeq[int](colCount)
  for c in 0 ..< colCount:
    widths[c] = displayWidth(headers[c])
  for row in rows:
    for c in 0 ..< min(colCount, row.len):
      widths[c] = max(widths[c], displayWidth(row[c]))

  var sep = "+"
  for w in widths:
    sep.add(repeat("-", w + 2))
    sep.add("+")

  echo sep
  var headerLine = "| "
  for c in 0 ..< colCount:
    headerLine.add(padRight(headers[c], widths[c]))
    headerLine.add(" | ")
  echo headerLine
  echo sep

  for row in rows:
    var line = "| "
    for c in 0 ..< colCount:
      let cell = if c < row.len: row[c] else: ""
      line.add(padRight(cell, widths[c]))
      line.add(" | ")
    echo line
  echo sep
