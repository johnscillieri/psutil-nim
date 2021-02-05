# users

users() returns a sequence of the type User. User type holds information on the users on the system.

# The function
```nim
proc users*(): seq[User] = 
    var count: DWORD = 0
    var sessions: PWTS_SESSION_INFO 
    if WTSEnumerateSessionsW(WTS_CURRENT_SERVER_HANDLE, 0, 1, addr sessions, addr count) == 0:
        raiseError()

    for i in 0 ..< count:
        let currentSession =  cast[PWTS_SESSION_INFO](cast[int](sessions) + (sizeof(WTS_SESSION_INFO)*i))
        let sessionId = currentSession.sessionId

        let user = getUserForSession(WTS_CURRENT_SERVER_HANDLE, sessionId)
        if user == "": continue

        let address = getAddressForSession(WTS_CURRENT_SERVER_HANDLE, sessionId)
        let login_time = getLoginTimeForSession(WTS_CURRENT_SERVER_HANDLE, sessionId)
        
        result.add(User(name:user, host:address, started:login_time))

    WTSFreeMemory(sessions)
```

# The type

- [Users](../types/Users.md)