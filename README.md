# psutil-nim

> Port of Python's [psutil](https://github.com/giampaolo/psutil) to Nim

## Table of Contents

- [Background](#background)
- [Installation](#installation)
- [Usage](#usage)
- [Contribute](#contribute)
- [License](#license)

## Background

I love Python and [psutil](https://github.com/giampaolo/psutil) and all the
power they provide but bundling a Python app is a pain. Having a psutil library
in Nim seemed like the logical next step.

## Install

There's really no good way to install right now. Clone/download the repo and
include it in your project tree. Once I have a somewhat complete Linux version
I'll put it up on Nimble.

## Usage

Just some basic usage below until I get the example apps working and can mirror
what's in psutil's documentation.

```
import psutil

echo net_if_addrs()
echo boot_time()
echo users()
```

## Contribute

PRs accepted!

## License

BSD © John Scillieri
