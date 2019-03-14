## echo system memory information.
## $ nim c -r meminfo.nim
## MEMORY
## ------
## Total      :    9.7G
## Available  :    4.9G
## Percent    :    49.0
## Used       :    8.2G
## Free       :    1.4G
## Active     :    5.6G
## Inactive   :    2.1G
## Buffers    :  341.2M
## Cached     :    3.2G
##
## SWAP
## ----
## Total      :      0B
## Used       :      0B
## Free       :      0B
## Percent    :     0.0
## Sin        :      0B
## Sout       :      0B

import strutils
import strformat
import psutil

proc pprint_object[T]( obj: T ): void =
  var n: string
  var v: float
  for name, value in obj.fieldPairs:
    n = $name
    v = value.float
    if name == "percent":
      n = &"{n:<10}:{v.float:>10.1f} %"
    else:
      n = &"{n:<10}:{formatSize(v.int, prefix=bpColloquial, includeSpace=true):>12}"
    echo n

proc main() =
  echo("MEMORY\n------")
  pprint_object(psutil.virtual_memory())
  echo("\nSWAP\n----")
  pprint_object(psutil.swap_memory())


when isMainModule:
  main()
