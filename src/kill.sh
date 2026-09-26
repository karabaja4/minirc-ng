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

_check_all_killed() {
    _not_killed=''
    for _d in /proc/[0-9]*
    do
        [ -e "${_d}/exe" ] || continue
        _pid="${_d#/proc/}"

        if [ "${_pid}" != "1" ] && [ "${_pid}" != "${$}" ]
        then
            _cmdline="$(tr '\0' ' ' < "${_d}/cmdline" 2>/dev/null)"
            _not_killed="$(printf '%s%s %s\n' "${_not_killed}" "${_pid}" "${_cmdline}")"
        fi
    done
    if [ -n "${_not_killed}" ]
    then
        printf 'Not killed after %s:\n%s' "${_action}" "${_not_killed}"
        return 1
    fi
    return 0
}

if [ "${_action}" = 'TERM' ]
then
    rm -f "${_kill_file}"
    trap '_echo "Caught TERM"' TERM
    _kill TERM
fi

sleep 3

if _check_all_killed
then
    _echo "All processes exited after ${_action}"
else
    _echo "Failed to ${_action} all processes"
    if [ "${_action}" = 'TERM' ]
    then
        touch "${_kill_file}"
        _kill KILL
    fi
fi
