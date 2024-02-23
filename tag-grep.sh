#!/usr/bin/env bash
if [[ -n "$2" ]]; then
	tags=`git tag --sort=-committerdate | grep "$2"`
else
	tags=`git tag --sort=-committerdate`
fi
for tag in $tags; do
	printf "$tag "
	git grep -rn "$1" "$tag" | wc -l
done
