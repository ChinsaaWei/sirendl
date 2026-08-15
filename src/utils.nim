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

import uri, os

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
