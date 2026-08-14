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
