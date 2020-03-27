#!/usr/bin/env bash

mnt="/mnt/bck"
incrementalDisk="/dev/disk/by-uuid/dbb5e1e2-64d7-4a53-a04f-18671dfd1c01"
incrementalPaths=("/etc" "/home" "/root" "/source" "/srv" "/var")
fullDisks=("/dev/disk/by-uuid/8dcebdc8-e6cf-49ba-985c-fbbd622425d1" "/dev/disk/by-uuid/045c7eaf-10cf-425a-a22d-cb1c9b771b23")
fullPaths=("/aur" "/bin" "/boot" "/efi" "/etc" "/home" "/lib" "/lib64" "/lost+found" "/opt" "/root" "/sbin" "/source" "/srv" "/sys" "/usr" "/var")
export log=$(mktemp)
date > "$log"

check () {
    if [[ $? -ne 0 ]]; then
        printf "\e[31mFAIL\e[0m\n"
        [[ -n "$1" ]] && echo "$1" >&2
        printf "\n"
        echo "Have a look at the logfile at: $log" >&2
        exit 1
    elif
        printf "\e[32mOK\e[0m\n"
    fi
}

printf "[i] Running as user $(whoami)\n"
printf "[*] Checking privileges ... "
[[ $(id -u) -eq 0 ]]
check "[i] Script must be run as root."

printf "[*] Checking mountpoint ... "
mountpoint -q "$mnt" 2>>"$log" >>"$log"
[[ $? -ne 0 ]]
check "[i] Mountpoint $mnt already mounted"

if [[ "$1" == "--incremental" ]] || [[ "$1" == "-i" ]]; then

    printf "[*] Performing incremental backup\n"
    printf " |- Checking for backup disk ... "
    ls -lah "$incrementalDisk" 2>>"$log" >>"$log"
    check "[!] Can't find backup disk"

    printf " |- Mounting disk ... "
    mount "$incrementalDisk" "$mnt" 2>>"$log" >>"$log"
    check

    export BUP_DIR="$mnt"

    printf " |- Creating index ... "
    bup index --exclude-rx="/\\.?(C|c)ache/" $incrementalPaths 2>>"$log" >>"$log"
    check

    printf " |- Backing up ... "
    bup save -n local $incrementalPaths 2>>"$log" >>"$log"
    check

    printf " |- Unmounting ... "
    umount "$incrementalDisk" 2>>"$log" >>"$log"
    check

    printf " |- Syncing ... "
    sync 2>>"$log" >>"$log"
    check

    printf "[i] Done\n\n"
    rm "$log"


elif [[ "$1" == "--full" ]] || [[ "$1" == "-f" ]]; then

    printf "[*] Performing full backup\n"
    printf " |- Checking disk selection ... "
    [[ ! -z "$2" ]] && [[ ! -z "${fullDisks[$2]}" ]]
    check "[!] Disk selection '$2' (Disk '${fullDisks[$2]}') invalid\n"

    printf " |- Checking for backup disk ... "
    ls -lah "${fullDisks[$2]}" 2>>"$log" >>"$log"
    check "[!] Can't find backup disk"

    printf " |- Mounting disk ... "
    mount "${fullDisks[$2]}" "$mnt" 2>>"$log" >>"$log"
    check

    printf " |- Backing up (this may take some time) ... "
    rsync -a --delete --quiet -HAXE $fullPaths "$mnt" 2>>"$log" >>"$log"
    check

    printf " |- Unmounting ... "
    umount "${fullDisks[$2]}" 2>>"$log" >>"$log"
    check

    printf " |- Syncing ... "
    sync 2>>"$log" >>"$log"
    check

    printf "[i] Done\n\n"
    rm "$log"

else

    printf "[i] Unknown option: '$1'\n"
    printf "[i] Valid options:\n"
    printf " |- -f, --full           Perform a full system backup\n"
    printf " |- -i, --incremental    Perform an incremental and partial backup\n"
    exit 1

fi
