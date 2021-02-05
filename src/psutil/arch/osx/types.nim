type gid_t* = distinct uint32


type uid_t* = distinct uint32


type off_t* {.importc:"off_t",header:"<sys/types.h>".} = object # https://stackoverflow.com/questions/9073667/where-to-find-the-complete-definition-of-off-t-type
