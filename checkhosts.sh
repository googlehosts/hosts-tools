#!/bin/bash
# https://github.com/racaljk/hosts

LINE_BREAK=0
FORMAT_BREAK=0
DATE_BREAK=0

# set -xv

#
# 1. check line endings
#
chk_line() {
    local le_ret=$(dos2unix -id hosts | grep -o "[0-9]\+")

    echo -e "1. check line endings:\n"

    if [ "$le_ret" -ne 0 ]; then
        echo -e "DOS line endings $le_ret times appeared, it must be coverted!\n\n"
        LINE_BREAK=1
    else
        echo -e "All fine!\n\n"
    fi
}

#
# 2. hosts format check, only used if STRICT_HOSTS_FORMAT already set
#
chk_format() {
    echo -e "2. check hosts format:\n"

    grep "[[:digit:]]\+.[[:digit:]]\+.[[:digit:]]\+.[[:digit:]]\+[[:blank:]]\+" \
        hosts > 1.txt

    grep "[[:digit:]]\+.[[:digit:]]\+.[[:digit:]]\+.[[:digit:]]\+$(echo -e "\t")[[:alnum:]]\+" \
        hosts > 2.txt

    diff -q 1.txt 2.txt

    if [ "$?" -ne 0 ]; then
        echo -e "\nhosts format mismatch! The following rules should be normalized:"
        diff 1.txt 2.txt
        FORMAT_BREAK=1
    else
        echo -e "All fine!"
    fi

    rm -f 1.txt 2.txt
}

#
# 3. check "Last updated", only used if STRICT_HOSTS_FORMAT already set
#
chk_date() {
    local real_date=$(find hosts -printf "%CY-%Cm-%Cd")
    local in_hosts=$(grep -o "[[:digit:]]\+-[[:digit:]]\+-[[:digit:]]\+" hosts)

    echo -e "\n\n3. check hosts date:\n"

    if [ "$real_date" != "$in_hosts" ]; then
        echo -e "hosts date mismatch, last modified is $real_date, " \
                  "but hosts tells $in_hosts\n\n"
        DATE_BREAK=1
    else
        echo -e "All fine!\n\n"
    fi
}

chk_line

if [ -n $STRICT_HOSTS_FORMAT ]; then
    chk_format
    chk_date
fi

#
# Result
#
echo -e "4. Result:\n"

echo -e "line endings break?      $LINE_BREAK (1 = yes, 0 = no)"

if [ -n $STRICT_HOSTS_FORMAT ]; then
    echo -e "hosts format mismatch?   $FORMAT_BREAK (1 = yes, 0 = no)"
    echo -e "hosts date mismatch?     $DATE_BREAK (1 = yes, 0 = no)"

    ret=$(echo -e "$LINE_BREAK $FORMAT_BREAK $DATE_BREAK" | grep -o "1" | wc -w)
    exit $ret
else
    exit $LINE_BREAK
fi
