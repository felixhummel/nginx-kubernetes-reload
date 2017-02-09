#!/bin/bash

{
  echo "INFO: Starting nginx"
  nginx "$@" && exit 1
} &

nginx_pid=$!

watches=${WATCH_PATHS:-"/etc/nginx/"}

echo "INFO: Setting up watches for ${watches[@]}"

{
  echo "INFO: nginx PID = $nginx_pid"
  inotifywait -r -q -e modify,move,create,delete --timefmt '%y-%m-%d %H:%M:%S' -m --format '%e %T %f' \
  ${watches[@]} | while read event date time fname; do
    echo "INFO: At ${time} on ${date}, config file ${fname} changed (event=${event})"
    nginx -t
    if [ $? -ne 0 ]; then
      echo "ERROR: New configuration is invalid!!"
    else
      echo "INFO: New configuration is valid, reloading nginx"
      nginx -s reload
    fi
  done
  echo "INFO: inotifywait failed, killing nginx"

  kill -TERM $nginx_pid
} &

wait -n $nginx_pid
