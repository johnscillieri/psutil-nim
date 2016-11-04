import math

proc usage_percent*[T](used: T, total: T, places=0): float =
    ## Calculate percentage usage of 'used' against 'total'.
    try:
        result = (used / total) * 100
    except DivByZeroError:
        result = if used is float or total is float: 0.0 else: 0
    if places != 0:
        return round(result, places)
    else:
        return result
