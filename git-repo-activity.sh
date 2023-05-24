#!/bin/bash

SINCE=$1

USAGE=$(cat <<-END
$0 SINCE
  SINCE    yyyy/mm/dd formatted date or something like "3 months"
END
)

test "${SINCE}" ||  { echo "${USAGE}" ; exit 1; }

WHEN=`date +%s`
HEADER="Who,Num PRs,Files Changed,Lines Added,Lines Deleted, Total Lines (delta),Add/Delete Ratio"
FILE_NAME_MERGECOUNT="/tmp/name-and-mergecount-${WHEN}.csv"

git shortlog \
    -sne \
    --since="${SINCE}" \
    | sort -r \
    | awk '{first = $1; $1=""; print $0 "," first}' \
    > ${FILE_NAME_MERGECOUNT}

echo ${HEADER}
while read line; do
    who=`echo ${line} | cut -f1 -d',' | sed 's/ <.*//g'`
    printf "%s", "${line}"
    git log \
    --shortstat \
    --author="${who}" \
    --pretty=tformat: \
    --numstat \
    --since="${SINCE}" \
    | grep -E "fil(e|es) changed" \
    | awk '{files+=$1; inserted+=$4; deleted+=$6; delta+=$4-$6; ratio=deleted/inserted} END {printf "%s,%s,%s,%s,%s\n", files, inserted, deleted, delta, ratio}'
done < ${FILE_NAME_MERGECOUNT}

rm ${FILE_NAME_MERGECOUNT}
