#!/bin/bash

on_exit () {
  # find all subprocesses by looking up our process group (+3 to not parse headers+bash)
  local pids=($(ps -g $$ -o pid | tail -n +3))
  # kill all process except the first one which in 'npm start'
  kill ${pids[@]:1} 2>/dev/null >/dev/null
  # wait 'npm start' to exit since that means sub processes are dead
  wait ${pids[0]}
}

trap on_exit EXIT
npm start "$@"