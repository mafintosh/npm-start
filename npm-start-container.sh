#!/bin/bash

update_path () {
  local prev=""
  local rel="node_modules/.bin"
  local result=""
  local curr=$PWD

  while [ "$PWD" != "$prev" ]; do
    prev="$PWD"
    [ -d "node_modules/.bin" ] && result="$result$rel:"
    rel="../$rel"
    cd ..
  done
  cd $curr

  export PATH="$result$PATH"
}

subprocs () {
  for pid in $(ps ax -o ppid,pid | awk "\$1 == $1 {print \$2}"); do
    echo $pid
    subprocs $pid
  done
}

load_container_limits () {
  eval $(node -e "\
    fs = require('fs');\
    fs.readFile('/sys/fs/cgroup/memory/memory.limit_in_bytes', 'utf8', function(err, data){\
      if (err) { return }\
      if (memory_limit_in_bytes === 18446744073709551615) { return }\
      memory_limit_in_bytes = parseInt(data);\
      var max_old_space_size = (memory_limit_in_bytes / kilo / kilo);\
      console.log('export memory_limit_flags=\" --max_old_space_size='+max_old_space_size\"')\
    });\
  " 2> /dev/null)
}

load_package () {
  eval $(node -e "\
    var p = require('./package');\
    var s = p.scripts || {};\
    console.log('export npm_package_name='+JSON.stringify(p.name || ''));\
    console.log('export npm_package_main='+JSON.stringify(p.main || ''));\
    console.log('export npm_package_version='+JSON.stringify(p.version || ''));\
    console.log('export npm_package_scripts_start='+JSON.stringify(s.start || ''));\
    console.log('export npm_package_scripts_prestart='+JSON.stringify(s.prestart || ''));\
    console.log('export npm_package_scripts_poststart='+JSON.stringify(s.poststart || ''));\
  " 2> /dev/null)
}

on_exit () {
  local pids=($(subprocs $$))
  kill ${pids[@]:1} 2>/dev/null >/dev/null
  wait ${pids[0]}
}

on_proxy_exit () {
  kill $PID
  wait $PID
}

print_header () {
  printf "\n> $npm_package_name@$npm_package_version $1 $PWD\n> $2\n\n"
}

run_start () {
  echo "node$memory_limit_flags $npm_package_main"
  [ "$npm_package_scripts_start" = "" ] && [ -f "$npm_package_main" ] && npm_package_scripts_start="node$memory_limit_flags $npm_package_main"
  [ "$npm_package_scripts_start" = "" ] && [ -f server.js ] && npm_package_scripts_start="node$memory_limit_flags server.js"
  [ "$npm_package_scripts_start" = "" ] && [ -f index.js ] && npm_package_scripts_start="node$memory_limit_flags index.js"

  if [ "$npm_package_scripts_start" = "" ]; then
    echo "Error: No start script specified." >&2
    exit 1
  fi

  print_header start "$npm_package_scripts_start"
  trap on_exit EXIT
  sh -c "true && $npm_package_scripts_start \"\$@\"" start "$@" # true && to force a subshell
  return $?
}

run_prestart () {
  if [ "$npm_package_scripts_prestart" != "" ]; then
    print_header prestart "$npm_package_scripts_prestart"
    sh -c "$npm_package_scripts_prestart \"\$@\"" prestart "$@"
    return $?
  fi
}

run_poststart () {
  if [ "$npm_package_scripts_poststart" != "" ]; then
    print_header poststart "$npm_package_scripts_poststart"
    sh -c "$npm_package_scripts_poststart \"\$@\"" poststart "$@"
    return $?
  fi
}

update_path

# always fork to get rid of weird "terminated" message
# also this gives us docker support since we don't run as pid=1
if [ "$npm_start_fork" = "" ]; then
  trap on_proxy_exit SIGTERM
  npm_start_fork=true "$0" "$@" &
  PID=$!
  wait $PID
else
  load_package
  load_container_limits
  run_prestart "$@" && run_start "$@" && run_poststart "$@"
fi
