#!/bin/sh

_kill_file='/tmp/minirc-kill'
_action='TERM'

if [ "${1}" = 'killcheck' ]
then
    if [ -f "${_kill_file}" ]
    then
        _action='KILL'
    else
        exit 0
    fi
fi

_echo() {
    printf '[%s][%s] %s\n' "${$}" "${0##*/}" "${1}"
}

_kill() {
    _echo "Sending ${1} to all"
    /bin/busybox kill "-${1}" -1
}

if [ "${_action}" = 'TERM' ]
then
    rm -f "${_kill_file}"
    trap '_echo "Caught TERM"' TERM
    _kill TERM
fi

sleep 3
_out="$(pstree -p)"

_lc="$(printf '%s' "${_out}" | grep -c -v '^[[:space:]]*$')"
if [ "${_lc}" -eq 1 ]
then
    _echo "After ${_action}: ${_out}"
else
    _echo "After ${_action}:"
    printf '%s\n' "${_out}"
fi

if printf '%s' "${_out}" | grep -q '^init([0-9][0-9]*)---sh([0-9][0-9]*)---pstree([0-9][0-9]*)$'
then
    _echo "All processes exited after ${_action}"
else
    _echo "Failed to ${_action} all processes"
    if [ "${_action}" = 'TERM' ]
    then
        printf '%s\n' "${_out}" > "${_kill_file}"
        _kill KILL
    fi
fi
