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


## Troubleshooting

If you are running on CentOS or RedHat you may or may not find errors with the Network related functions,
complaining about missing Linux C Headers `sockios.h` to Compile,
this is not a Bug on the code but that Distro not having development libraries or having too old versions of it.

You can try installing the package `kernel-headers` for CentOS/RedHat,
to see if that fixes the problem about missing libraries.

If you know how to fix that Distro-specific detail feel free to send pull requests.

The failing functions are:

```nim
net_io_counters()
per_nic_net_io_counters()
net_if_stats()
net_connections()
```

You can workaround by using [Distros module](https://nim-lang.org/docs/distros.html#Distribution):

```nim
when not detectOs(CentOS):
  # Do something here with the Network functions.
  echo net_io_counters()
  echo per_nic_net_io_counters()
  echo net_if_stats()
  echo net_connections()
```


## Contribute

PRs accepted! Adding a single function to any platform is a huge help and can usually be done with less than an hour of work.

## License

- BSD

Original Author:   John Scillieri.
Current Developer: Juan Carlos.
