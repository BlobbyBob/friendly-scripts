#!/usr/bin/env bash
if [[ -n "$2" ]]; then
	tags=`hg tags -T '{tag}\n' | grep "$2"`
else
	tags=`hg tags -T '{tag}\n'`
fi
for tag in $tags; do
	printf "$tag "
	hg grep -nr "$tag" "$1" | wc -l
done
