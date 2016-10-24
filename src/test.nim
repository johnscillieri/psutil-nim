import tables

import psutil

echo "net_if_addrs:\n", net_if_addrs()

echo "\nboot_time: ", boot_time()

echo "\nusers:\n", users()

echo "\npids:\n", pids()

echo "\npid_exists: 1=", pid_exists(1), " 999=", pid_exists(999)
