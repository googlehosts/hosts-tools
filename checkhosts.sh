#!/bin/bash
# https://github.com/racaljk/hosts

LINE_BREAK=0
FORMAT_BREAK=0
DATE_BREAK=0

# 1. check line endings
#
chk_line() {
    local ret=$(dos2unix -id "$1" | egrep -o "[0-9]+")

    echo -e "1. check line endings:\n"

    if [ "$ret" -ne 0 ]; then
        echo -e "\033[41mDOS line endings $ret times appeared, " \
                    "it must be coverted!\033[0m\n\n"
        LINE_BREAK=1
    else
        echo -e "\033[42mAll is well!\033[0m\n\n"
    fi
}

# 2. check hosts format, only used if STRICT_HOSTS_FORMAT already set
#
chk_format() {
    local loc="[0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+"
    local in_fmt="[0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+$(echo -e "\t")[[:alnum:]]\+"

    echo -e "2. check hosts format:\n"

    grep "$loc" "$1" > 1.txt
    grep "$in_fmt" "$1" > 2.txt

    diff -q 1.txt 2.txt

    if [ "$?" -ne 0 ]; then
        echo -e "\n\033[41mhosts format mismatch! " \
                    "The following rules should be normalized:\033[0m"
        diff 1.txt 2.txt
        FORMAT_BREAK=1
    else
        echo -e "\033[42mAll is well!\033[0m"
    fi

    echo -e "\n"
    rm -f 1.txt 2.txt
}

# 3. check "Last updated", only used if STRICT_HOSTS_FORMAT already set
#
chk_date() {
    # system date
    local real_date=$(date +%F)
    # date in git repo's log
    local repo_date=$(git log --date=short "$1" | egrep -o "[0-9]+-[0-9]+-[0-9]+" -m 1)
    # date string in hosts file.
    local hosts_date=$(egrep -o "[0-9]+-[0-9]+-[0-9]+" "$1")

    echo -e "3. check hosts date:\n"

    # detect hosts file changes
    if git diff --exit-code "$1" > /dev/null; then
        # hosts file isn't changed, compare date with git's log.
        if [ "$repo_date" != "$hosts_date" ]; then
            echo -e "\033[41mhosts date mismatch, last modified is $repo_date, " \
                    "but hosts tells $hosts_date\033[0m\n\n"
            DATE_BREAK=1
        else
            echo -e "\033[42mAll is well!\033[0m\n\n"
        fi
    else
        # hosts file is being editing, and not commit yet.
        # Compare date with system date.
        if [ "$real_date" != "$hosts_date" ]; then
            echo -e "\033[41mhosts date mismatch, last modified is $real_date, " \
                    "but hosts tells $hosts_date\033[0m\n\n"
            DATE_BREAK=1
        else
            echo -e "\033[42mAll is well!\033[0m\n\n"
        fi
    fi
}

#
# Result
#
result () {
    echo -e "Result:\n"

    echo -e "line endings break?      $LINE_BREAK (1 = yes, 0 = no)"

    if [ -n "$STRICT_HOSTS_FORMAT" ]; then
        echo -e "hosts format mismatch?   $FORMAT_BREAK (1 = yes, 0 = no)"
        echo -e "hosts date mismatch?     $DATE_BREAK (1 = yes, 0 = no)"

        local ret=$(echo -e "$LINE_BREAK $FORMAT_BREAK $DATE_BREAK" \
            | grep -o "1" | wc -w)
        exit $ret
    else
        exit $LINE_BREAK
    fi
}

if [ "$1" = "" ]; then
    echo -e "\033[41mError, requires an argument!\033[0m"
    exit -1
fi

chk_line "$1"

if [ -n "$STRICT_HOSTS_FORMAT" ]; then
    chk_format "$1"
    chk_date "$1"
fi

result
