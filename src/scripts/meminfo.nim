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
## SWAP
## ----
## Total      :      0B
## Used       :      0B
## Free       :      0B
## Percent    :     0.0
## Sin        :      0B
## Sout       :      0B

import strutils
import stringinterpolation
import ../psutil

proc formatSize( bytes: int, precision: range[1..3] ): string =
    result = formatSize( bytes, includeSpace=true, prefix=bpColloquial )
    let items = result.split()
    let number_parts = items[0].split(".")
    result = number_parts[0] & "." & number_parts[1][0..<precision] & items[1][0]

proc pprint_object[T]( obj: T ) =
    for name, value in obj.fieldPairs():
        var to_print: string
        if name == "percent":
            to_print = formatFloat( value.float, precision=3 )
        else:
            to_print = formatSize( value.int, precision=1 )
        echo("%-10s : %7s".format( name.capitalizeAscii(), to_print ) )

proc main() =
    echo("MEMORY\n------")
    pprint_object( psutil.virtual_memory() )
    echo("\nSWAP\n----")
    pprint_object( psutil.swap_memory() )


when isMainModule:
    main()
