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

type
  AlbumResponse* = object
    code*: int
    msg*: string
    data*: Album

  Album* = object
    name*: string
    coverUrl*: string
    songs*: seq[Song]

  Song* = object
    cid*: string
    name*: string

  SongResponse* = object
    code*: int
    msg*: string
    data*: SongData

  SongData* = object
    sourceUrl*: string
