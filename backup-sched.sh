#!/usr/bin/env bash

backupSh="/root/backup.sh"
config="/root/.backup-sched"
if [[ ! -f "$config" ]]; then
    touch "$config"
fi
sched=$(cat "$config")

if [[ $(id -u) -ne 0 ]]; then
    echo "Backup scheduler has to be run as root (Current user $(whoami)/$(id -u))" >&2
    exit 1
fi

now=$(date +%s)

lastInc=$(grep "inc" "$config" | grep -oE "^[0-9]+")
if [[ -z "$lastInc" ]] || [[ "$(( $now - $lastInc ))" -ge "$(( 60 * 60 * 24 * 6 ))" ]]; then
    $backupSh --incremental || exit 1
    (echo "$sched" | grep -v "inc"; echo "$now inc") | tee "$config"
    exit 0
fi

# TODO: Encrypt Full A Backup
lastFullA=$(grep "fulla" "$config" | grep -oE "^[0-9]+")
if [[ -z "$lastFullA" ]] || [[ "$(( $now - $lastFullA ))" -ge "$(( 60 * 60 * 24 * 90 ))" ]]; then
    $backupSh --full 0 || exit 1
    (echo "$sched" | grep -v "fulla"; echo "$now fulla") | tee "$config"
    exit 0
fi

lastFullB=$(grep "fullb" "$config" | grep -oE "^[0-9]+")
if [[ -z "$lastFullB" ]] || [[ "$(( $now - $lastFullB ))" -ge "$(( 60 * 60 * 24 * 30 ))" ]]; then
    $backupSh --full 1 || exit 1
    (echo "$sched" | grep -v "fullb"; echo "$now fullb") | tee "$config"
    exit 0
fi
