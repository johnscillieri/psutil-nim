import unittest
import osproc
import sequtils
import strutils

import ../src/psutil


test "test users":
    let output = execProcess("who").strip()
    if output != "":
        let lines = output.splitlines()
        echo "dbg: ", lines[0].splitWhitespace()
        let users = mapIt( lines, it.splitWhitespace()[0] )
        check( len(users) == len(psutil.users()) )

        let terminals = mapIt( lines, it.splitWhitespace()[1] )
        for u in psutil.users():
            check( u.name in users )
            check( u.terminal in terminals )
