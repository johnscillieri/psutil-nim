import ../src/psutil
import strformat
template echo_proc(x: untyped) =
  echo "\n\n", astToStr(x), "\n", x
    

echo fmt"{getnativearch()}"
# echo_proc pid_exists(77724)
echo_proc pids_with_names()
for pid in pids():
  echo pid_path(pid)
  echo fmt"{pid_arch(pid)}"
  echo fmt"{pid_user(pid)}"
  echo fmt"{pid_domain(pid)}"
  echo fmt"{pid_domain_user(pid)}"

var du = disk_usage("C:\\")
echo du.total
echo_proc pid_paths(pids())
echo_proc pid_parent(pids()[0])
echo_proc psutil_get_drive_type("C:\\")
echo_proc process_exists("test_windows.exe")