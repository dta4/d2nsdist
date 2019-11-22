#!/bin/bash
set -e

# usage: file_env VAR [DEFAULT]
#    ie: file_env 'XYZ_DB_PASSWORD' 'example'
#  (will allow for "$XYZ_DB_PASSWORD_FILE" to fill in the value of
#   "$XYZ_DB_PASSWORD" from a file, especially for Docker's secrets feature)
function file_env() {
  local var="$1"
  local fileVar="${var}_FILE"
  local def="${2:-}"
  if [ "${!var:-}" ] && [ "${!fileVar:-}" ]; then
    echo >&2 "error: both $var and $fileVar are set (but are exclusive)"
    exit 1
  fi
  local val="$def"
  if [ "${!var:-}" ]; then
    val="${!var}"
  elif [ "${!fileVar:-}" ]; then
    val="$(< "${!fileVar}")"
  fi
  export "$var"="$val"
  unset "$fileVar"
}

# envs=(
#   XYZ_API_TOKEN
# )
# haveConfig=
# for e in "${envs[@]}"; do
#   file_env "$e"
#   if [ -z "$haveConfig" ] && [ -n "${!e}" ]; then
#     haveConfig=1
#   fi
# done

echo Running: "$@"

WEB_PASSWORD=${WEB_PASSWORD:-password}
WEB_APITOKEN=${WEB_APITOKEN:-token}
declare -A CONSOLE_ACL
CONSOLE_ACL=${CONSOLE_ACL:-"\"172.16.0.0/12\"" "\"127.0.0.1/8\"" "\"::1/128\""}

# Avoid destroying bootstrapping by simple start/stop
if [[ ! -e /.bootstrapped ]]; then
  ### list none idempotent configuration code blocks, here...

  if [ -z $CONSOLE_KEY ]; then
    CONSOLE_KEY=`echo "makeKey()" | stdbuf -oL dnsdist -l 127.0.0.1:4711 | tail -1`
    echo
    echo Set console key: $CONSOLE_KEY
    echo
    CONSOLE_KEY=`echo $CONSOLE_KEY | sed -e 's/^.*("//' | sed -e 's/")$//'`
  fi

  touch /.bootstrapped
fi

if [ -z $CONSOLE_KEY ]; then
  CONSOLE_KEY=`grep '^setKey("' /etc/dnsdist.conf | sed -e 's/^.*("//' | sed -e 's/")$//'`
fi

. /mo
cat /etc/dnsdist.mustache | mo -e > /etc/dnsdist.conf

if [[ `basename ${1}` == "dnsdist" ]]; then # prod
  exec "$@" #</dev/null #>/dev/null 2>&1
else # dev
  : # nop
  dnsdist -v --disable-syslog --supervised >/var/log/dnsdist.log 2>&1 &
fi

# fallthrough...
exec "$@"
