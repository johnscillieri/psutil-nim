type Address* = object of RootObj
    family*: int
    address*: string
    netmask*: string
    broadcast*: string
    ptp*: string

type User* = object
    name*: string
    terminal*: string
    host*: string
    started*: float
