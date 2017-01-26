#!/bin/bash
# https://github.com/racaljk/hosts

EOL_BREAK=0
FORMAT_BREAK=0
DATE_BREAK=0

chk_eol()
{
	printf "\e[33;1mCheck line endings:\e[0m\n"

	if file "$1" | grep -q "CRLF"; then
		printf "\e[31mERROR: DOS line endings appeared, "
		printf "it must be coverted now!\e[0m\n\n"
		EOL_BREAK=1
	else
		printf "\e[32mAll is well!\e[0m\n\n"
	fi
}

# Check TAB, leading and trailing whitespace.
chk_format()
{
	printf "\e[33;1mCheck hosts format:\e[0m\n"

	# Filter out all comments, and add all hosts records to 1.swp.
	grep -Pv "^[ \t]*#" "$1" | grep -P "(\d+\.){3}\d+" > 1.swp
	# a line with trailing whitespace will be add to 1.swp.
	grep -P "[ \t]+$" "$1" >> 1.swp
	# Filter out all comments, need not to be formatted lines add to 2.swp
	grep -Pv "^[ \t]*#" "$1" | grep -P "^(\d+\.){3}\d+\t\w" > 2.swp

	if ! diff 1.swp 2.swp > 0.swp; then
		printf "\e[31mNOTICE: The following lines should be normalized:\e[0m\n"
		cat 0.swp; printf "\n"
		FORMAT_BREAK=1
	else
		printf "\e[32mAll is well!\e[0m\n\n"
	fi

	rm -f 0.swp 1.swp 2.swp
}

cmp_date()
{
	if [ "$1" != "$2" ]; then
		printf "\e[31mNOTICE: The last updated should be $1, "
		printf "but hosts tells $2\e[0m\n\n"
		DATE_BREAK=1
	else
		printf "\e[32mAll is well!\e[0m\n\n"
	fi
}

chk_date()
{
	local sys_date=$(date +%F)
	local commit_date=$(git log --pretty=format:"%cd" --date=short -1 "$1")
	local in_file=$(grep -m1 -Po "(?<=Last updated: )\d{4}-\d{2}-\d{2}" "$1")

	printf "\e[33;1mCheck hosts date:\e[0m\n"

	# check if hosts file changes.
	if git diff --exit-code "$1" &> /dev/null; then
		# hosts file has not been modified.
		cmp_date "$commit_date" "$in_file"
	else
		# hosts file has been modified but not committed.
		cmp_date "$sys_date" "$in_file"
	fi
}

if [ -z "$1" ]; then
	echo "Usage: $0 [file]"
	exit 4
fi

chk_eol "$1"
chk_format "$1"
chk_date "$1"

exit $(( $EOL_BREAK + $FORMAT_BREAK + $DATE_BREAK ))
