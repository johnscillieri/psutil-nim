# psutil-nim

> Port of Python's [psutil](https://github.com/giampaolo/psutil) to Nim

## Warning: This package is currently in beta and only works on Linux! Pull requests with bug fixes and support for other platforms are welcome!

## Table of Contents

- [Background](#background)
- [Installation](#installation)
- [Usage](#usage)
- [Contribute](#contribute)
- [License](#license)

## Background

I love Python and [psutil](https://github.com/giampaolo/psutil) but bundling a
Python app is a pain. Having a psutil library in Nim seemed like the logical
next step.

## Install

``` nimble install psutil ```

This package is in beta and currently only works on Linux. Most of the
process-specific functionality hasn't been implemented yet. I'll bump it to 1.0
once I have full Linux parity with psutil and then I'll start adding platforms.

## Usage

Just some basic usage below until I get the example apps working and can mirror
what's in psutil's documentation. Take a look at the scripts folder for some
basic examples as well.

```
import psutil

echo net_if_addrs()
echo boot_time()
echo users()
```

## Contribute

PRs accepted! Adding a single function to any platform is a huge help and can usually be done with less than an hour of work.

## License

BSD © John Scillieri
