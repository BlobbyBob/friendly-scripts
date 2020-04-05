#!/usr/bin/env bash

# Devices to switch between
declare -a devNames=("alsa_output.pci-0000_0d_00.4.analog-stereo"
		"alsa_output.usb-Logitech_G533_Gaming_Headset-00.iec958-stereo"
    "alsa_output.pci-0000_0d_00.4.analog-stereo")
declare -a portNames=("analog-output-lineout" "iec958-stereo-output" "analog-output-headphones")
declare -a displayNames=("Speakers" "Wireless Headset" "Wired Headset")
declare -a defaultVolumes=(65535 30000 15000)

# If the output length of the pacmd list-sinks command changes this needs to be adjusted
sinkInfoSize=70

# Get current device
runningName=$(pacmd list-sinks | grep -B 3 "state: RUNNING" | grep "name:" | grep -oE "<.+>" | grep -oE "[^<>]+")
runningPort=$(pacmd list-sinks | grep -A $sinkInfoSize RUNNING | tail -20 | grep "active port" | grep -oE "<.+>" | grep -oE "[^<>]+")
index=
for (( i=0; i<${#devNames[@]}; i++ ));
do
	if [[ "${devNames[$i]}" == "$runningName" ]] && [[ "${portNames[$i]}" == "$runningPort" ]]; then
		index=$i
		break
	fi
done

# Get current input programs indices
programs=$(pacmd list-sink-inputs | grep "index:" | grep -oE "[0-9]+")


if [[ -n "$DBG" ]]; then
	echo "[DBG] runningName: '$runningName'"
	echo "[DBG] runningPort: '$runningPort'"
	echo "[DBG] index: '$index'"
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
	available=$(pacmd list-sinks | grep -A $sinkInfoSize "${devNames[$new]}" | grep -A 8 "ports:" | grep "${portNames[$new]}" | grep -oE "available: [a-z]+" | grep -oE ": [a-z]+" | grep -oE "[a-z]+")
	if [[ -n "$DBG" ]]; then
		echo "[DBG] available: $available (${devNames[$new]})"
	fi
	if [[ "$available" == "yes" ]] || [[ "$available" == "unknown" ]]; then

		# Move inputs if device changes
		if [[ "${devNames[$index]}" != "${devNames[$new]}" ]]; then
			while read -r line; do
				pacmd move-sink-input "$line" "${devNames[$new]}"
			done <<< "$programs"
		fi

		pacmd set-sink-volume "${devNames[$new]}" ${defaultVolumes[$new]}
		pacmd set-sink-port "${devNames[$new]}" "${portNames[$new]}"
		pacmd set-default-sink "${devNames[$new]}"
		#notify-send 'Audio Switch' "Current device: ${displayNames[$new]}" --icon=audio-volume-high
		break
	fi
done
