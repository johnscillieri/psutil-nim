# users

users() returns a sequence of the type User. User type holds information on the users on the system.

# The functions
```nim
proc users*(): seq[User] =
    result = newSeq[User]()

    setutent()

    var ut = getutent()
    while ut != nil:
        let is_user_proc = ut.ut_type == USER_PROCESS
        if not is_user_proc:
            ut = getutent()
            continue

        var hostname = $ut.ut_host
        if hostname == ":0.0" or hostname == ":0":
            hostname = "localhost"

        let user_tuple = User( name:($ut.ut_user.join().strip.replace("\x00", "")),
                               terminal:($ut.ut_line.join().strip.replace("\x00", "")),
                               started:ut.ut_tv.tv_sec.float )
        result.add( user_tuple )
        ut = getutent()

    endutent()
```

# The type

- [Users](../types/Users.md)