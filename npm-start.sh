#!/bin/bash

subprocs () {
  for pid in $(ps a -o ppid,pid | awk "\$1 == $1 {print \$2}"); do
    echo $pid
    subprocs $pid
  done
}

load_package () {
  eval $(node -e "\
    var p = require('./package');\
    var s = p.scripts || {};\
    console.log('npm_package_name='+JSON.stringify(p.name || ''));\
    console.log('npm_package_version='+JSON.stringify(p.version || ''));\
    console.log('npm_package_scripts_start='+JSON.stringify(s.start || ''));\
    console.log('npm_package_scripts_prestart='+JSON.stringify(s.prestart || ''));\
    console.log('npm_package_scripts_poststart='+JSON.stringify(s.poststart || ''));\
  " 2> /dev/null)
}

on_exit () {
  local pids=($(subprocs $$))
  kill ${pids[@]:1} 2>/dev/null >/dev/null
  wait ${pids[0]}
}

print_header () {
  printf "\n> $npm_package_name@$npm_package_version $1 $PWD\n> $2\n\n"
}

run_start () {
  [ "$npm_package_scripts_start" = "" ] && [ -f server.js ] && npm_package_scripts_start="node server.js"
  [ "$npm_package_scripts_start" = "" ] && [ -f index.js ] && npm_package_scripts_start="node index.js"

  if [ "$npm_package_scripts_start" = "" ]; then
    echo "Error: No start script specified." >&2
    exit 1
  fi

  print_header start "$npm_package_scripts_start"
  trap on_exit EXIT
  sh -c "true && $npm_package_scripts_start" # true && to force a subshell
  return $?
}

run_prestart () {
  if [ "$npm_package_scripts_prestart" != "" ]; then
    print_header restart "$npm_package_scripts_prestart"
    sh -c "$npm_package_scripts_prestart"
    return $?
  fi
}

run_poststart () {
  if [ "$npm_package_scripts_poststart" != "" ]; then
    print_header restart "$npm_package_scripts_poststart"
    sh -c "$npm_package_scripts_poststart"
    return $?
  fi
}

load_package
run_prestart && run_start && run_poststart
