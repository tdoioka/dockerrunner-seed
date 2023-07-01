#!/bin/bash

# Container User name.
CUSER=${CUSER:-user}
CHOME=/home/${CUSER}
# Get user UID and GID from /work directory for Chane IDs to same.
HOST_UID=${HOST_UID:-$(stat -c %u /work)}
HOST_GID=${HOST_GID:-$(stat -c %g /work)}

# Change user name and home dir.
if [[ "${CUSER}" != user ]]; then
  groupmod -n "${CUSER}" user
  usermod  -l "${CUSER}" user
  usermod  -d "${CHOME}" -m "${CUSER}"
fi
# Change user UID and GID.
if [[ $HOST_UID -ne $(id -u "${CUSER}") ]] ||
     [[ $HOST_GID -ne $(id -g "${CUSER}") ]]; then
  groupmod -g "${HOST_GID}" "${CUSER}"
  usermod  -u "${HOST_UID}" "${CUSER}"
  chown "${HOST_UID}:${HOST_GID}" -R "${CHOME}"
fi

# Launch up new tty for emacsclient connection.
cat << __eof__ > /tmp/runscript
#!$SHELL
script -c 'exec $@' /dev/null
__eof__
chmod a+rx /tmp/runscript

exec /usr/sbin/gosu "${CUSER}" /tmp/runscript
