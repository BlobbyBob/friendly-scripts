#!/usr/bin/env bash

# Devices to switch between
towerOut=`pactl list sinks | grep -i -B 1 starship | grep -oE "Name:.[^ ]+" | cut -d' ' -f 2`
usbOut=`pactl list sinks | grep -i -B 1 wireless | grep -oE "Name:.[^ ]+" | cut -d' ' -f 2`

declare -a devNames=("$towerOut" "$usbOut" "$towerOut")
declare -a portNames=("analog-output-lineout" "analog-output" "analog-output-headphones")
declare -a displayNames=("Speakers" "Wireless Headset" "Wired Headset")
declare -a defaultVolumes=(15000 15000 15000)

# If the output length of the pacmd list-sinks command changes this needs to be adjusted
sinkInfoSize=60

# Get current device
index=`cat ~/.audiochoice`

# Get current input programs indices
programs=$(pactl list sink-inputs | grep -oE '#.+' | grep -oE "[0-9]+")


if [[ -n "$DBG" ]]; then
	echo "[DBG] index: '$index'"
	set -x
fi

# Get next available device+port
new=$index
while : ; do
	new=$(( ($new+1) % ${#devNames[@]} ))
	if [[ $new == $index ]]; then
		if [[ -n "$DBG" ]]; then
			echo "[DBG] No other devices available"
		fi
		break # No other device available
	fi
	available=$(pactl list sinks | grep -A $sinkInfoSize "Name: ${devNames[$new]}" | grep -A 8 "Ports" | grep "${portNames[$new]}" | grep -oE ', (not )?available')
	if [[ -n "$DBG" ]]; then
	    echo "[DBG] cmd="'pactl list sinks | grep -A $sinkInfoSize "Name: ${devNames[$new]}" | grep -A 8 "Ports" | grep "${portNames[$new]}" | grep -oE '"'"', (not )?available'"'"
		echo "[DBG] available: $available (${devNames[$new]})"
		echo "[DBG] programs: $programs" 
	fi
	if echo "$available" | grep -v not; then

		# Move inputs if device changes
		if [[ "${devNames[$index]}" != "${devNames[$new]}" ]]; then
			while read -r line; do
				pactl move-sink-input "$line" "${devNames[$new]}" || ([ -n "$DBG" ] && echo "move-sink-input error")
			done <<< "$programs"
		fi

		pactl set-sink-volume "${devNames[$new]}" ${defaultVolumes[$new]} || ([ -n "$DBG" ] && echo "set-sink-volume error")
		pactl set-sink-port "${devNames[$new]}" "${portNames[$new]}" || ([ -n "$DBG" ] && echo "set-sink-port error")
		pactl set-default-sink "${devNames[$new]}" || ([ -n "$DBG" ] && echo "set-default-sink error")
		
		echo "$new" > ~/.audiochoice		
		break
	fi
done
