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

import std/os, std/strutils, std/tables, std/json

type Lang* = enum
  langEn, langZh

const
  zhContent = staticRead("../locales/zh-CN.json")
  enContent = staticRead("../locales/en.json")

var currentLang* = Lang.langEn

var strings: Table[string, string]

proc detectWindowsLocale(): string =
  when defined(windows):
    proc GetUserDefaultUILanguage(): uint16
      {.stdcall, importc: "GetUserDefaultUILanguage", dynlib: "kernel32".}
    let langid = GetUserDefaultUILanguage()
    let primary = langid and 0x03FF
    let sublang = (langid shr 10) and 0x03F
    if primary == 0x04 and (sublang == 0x02 or sublang == 0x04):
      return "zh_CN"
    return "en_US"
  else:
    return ""

proc detectLang*(): Lang =
  var locale = ""
  for v in ["LC_ALL", "LC_MESSAGES", "LANG", "LANGUAGE"]:
    let s = getEnv(v)
    if s.len > 0:
      locale = s
      break
  if locale.len == 0:
    locale = detectWindowsLocale()

  let lower = locale.toLowerAscii()
  if lower.startsWith("zh_cn") or lower.startsWith("zh-cn") or
     lower.startsWith("zh_hans") or lower.startsWith("zh-hans") or
     lower.startsWith("zh_sg") or lower.startsWith("zh-sg"):
    return langZh
  return langEn

proc langContent(lang: Lang): string =
  case lang
  of langZh: zhContent
  of langEn: enContent

proc collectStrings(node: JsonNode, prefix: string, acc: var Table[string, string]) =
  for key, val in node:
    let fullKey = if prefix.len == 0: key else: prefix & "." & key
    if val.kind == JString:
      acc[fullKey] = val.getStr()
    elif val.kind == JObject:
      collectStrings(val, fullKey, acc)

proc loadStrings(content: string): Table[string, string] =
  result = initTable[string, string]()
  collectStrings(parseJson(content), "", result)

proc initI18n*() =
  currentLang = detectLang()
  strings = loadStrings(langContent(currentLang))

proc t*(key: string): string =
  strings.getOrDefault(key)
