# src/types.nim

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
