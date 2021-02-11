#!/usr/bin/env bash

mnt="/mnt/bck"
incrementalDisk="/dev/disk/by-uuid/dbb5e1e2-64d7-4a53-a04f-18671dfd1c01"
incrementalPaths="/root /source /srv /etc /var /home"
fullDisks=("/dev/disk/by-uuid/8dcebdc8-e6cf-49ba-985c-fbbd622425d1" "/dev/disk/by-uuid/045c7eaf-10cf-425a-a22d-cb1c9b771b23")
fullPaths="/aur /bin /boot /efi /etc /home /lib /lib64 /lost+found /opt /root /sbin /source /srv /usr /var"
export log=$(mktemp -p '/root/log')
date > "$log"

check () {
    if [[ $? -ne 0 ]]; then
        printf "\e[31mFAIL\e[0m\n" | tee -a "$log" >&2
        [[ -n "$1" ]] && echo "$1" | tee -a "$log" >&2
        printf "\n" | tee -a "$log"
        echo "Have a look at the logfile at: $log" >&2
        exit 1
    else
        printf "\e[32mOK\e[0m\n" | tee -a "$log"
    fi
}

printf "[i] Running as user $(whoami)\n" | tee -a "$log"
printf "[*] Checking privileges ... " | tee -a "$log"
[[ $(id -u) -eq 0 ]]
check "[i] Script must be run as root."

printf "[*] Checking mountpoint ... " | tee -a "$log"
mountpoint -q "$mnt" 2>>"$log" >>"$log"
[[ $? -ne 0 ]]
check "[i] Mountpoint $mnt already mounted"

if [[ "$1" == "--incremental" ]] || [[ "$1" == "-i" ]]; then

    printf "[*] Performing incremental backup\n" | tee -a "$log"
    printf " |- Checking for backup disk ... " | tee -a "$log"
    ls -lah "$incrementalDisk" 2>>"$log" >>"$log"
    check "[!] Can't find backup disk"

    printf " |- Mounting disk ... " | tee -a "$log"
    mount "$incrementalDisk" "$mnt" 2>>"$log" >>"$log"
    check

    export BUP_DIR="$mnt"

    printf " |- Creating index ... " | tee -a "$log"
    bup index --exclude-rx="/\\.?(C|c)ache/" $incrementalPaths 2>>"$log" >>"$log"
    check

    printf " |- Backing up ... " | tee -a "$log"
    bup save -vv -n local $incrementalPaths 2>>"$log" >>"$log"
    check

    printf " |- Unmounting ... " | tee -a "$log"
    umount "$incrementalDisk" 2>>"$log" >>"$log"
    check

    printf " |- Syncing ... " | tee -a "$log"
    sync 2>>"$log" >>"$log"
    check

    printf "[i] Done\n\n" | tee -a "$log"


elif [[ "$1" == "--full" ]] || [[ "$1" == "-f" ]]; then

    printf "[*] Performing full backup\n" | tee -a "$log"
    printf " |- Checking disk selection ... " | tee -a "$log"
    [[ ! -z "$2" ]] && [[ ! -z "${fullDisks[$2]}" ]]
    check "[!] Disk selection '$2' (Disk '${fullDisks[$2]}') invalid\n"

    printf " |- Checking for backup disk ... " | tee -a "$log"
    ls -lah "${fullDisks[$2]}" 2>>"$log" >>"$log"
    check "[!] Can't find backup disk"

    printf " |- Mounting disk ... " | tee -a "$log"
    mount "${fullDisks[$2]}" "$mnt" 2>>"$log" >>"$log"
    check

    printf " |- Backing up (this may take some time) ... " | tee -a "$log"
    rsync -rlptgoDHAXE --progress --delete $fullPaths "$mnt" 2>>"$log" >>"$log"
    check

    printf " |- Unmounting ... " | tee -a "$log"
    umount "${fullDisks[$2]}" 2>>"$log" >>"$log"
    check

    printf " |- Syncing ... " | tee -a "$log"
    sync 2>>"$log" >>"$log"
    check

    printf "[i] Done\n\n" | tee -a "$log"

else

    printf "[i] Unknown option: '$1'\n"
    printf "[i] Valid options:\n"
    printf " |- -f, --full           Perform a full system backup\n"
    printf " |- -i, --incremental    Perform an incremental and partial backup\n"
    rm "$log"
    exit 1

fi
