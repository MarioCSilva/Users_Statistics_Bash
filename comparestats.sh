#!/bin/bash
only_one="n"
sort_tp="sort"

function how_to() {
    echo
    echo "How To Use This Script:"
    echo "	Options:"
    echo "		-r:             Sort in reverse order"
    echo "	You may choose only one of these:"
    echo "		-n:             Sort by number of sessions"
    echo "		-t:             Sort by total logged time"
    echo "		-a:             Sort by maximum logged time"
    echo "		-i:             Sort by minimum logged time"
    echo
}

function valOpt() {
    if [[ $only_one == "y" ]]; then
        echo "Can't select these arguments together"
		how_to
		exit 1
	fi
	only_one="y"
}

while getopts 'rntai' opt; do
	case "$opt" in
		r)
			sort_tp="$sort_tp -r"    
		   	;;
		n)
			sort_tp="$sort_tp -n -k2"
			valOpt
		   	;;
		t)
			sort_tp="$sort_tp -n -k3"
			valOpt
		   	;;
		a)
			sort_tp="$sort_tp -n -k4"
			valOpt
		   	;;
	   	i)
			sort_tp="$sort_tp -n -k5"
			valOpt
		   	;;
		*)
			how_to
			exit 1;
			;;
	esac
done

# Validates and reads both files
file1="${@:(-2):1}"; file2="${@:(-1):1}"
if [ ! -f $file1 ] || [ ! -f $file2 ]; then
	printf "File wasn't found.\n";
	how_to
	exit 1
fi
IFS=$'\n'
userstats=(`cat $file1`); userstats2=(`cat $file2`)

# Puts the userstats2 into the array userstats by finding the correspondent user and making the difference
for stats in ${userstats2[@]}; do
	IFS=$' '
	stats=($stats)
	IFS=$'\n'
	user=${stats[0]}; count=${stats[1]}; total=${stats[2]}; time_max=${stats[3]}; time_min=${stats[4]}
	found=false; i=0
	for stats in ${userstats[@]}; do
		IFS=$' '
		stats=($stats)
		IFS=$'\n'
		if [[ ${stats[0]} == $user ]]; then
			found=true
			let "count = stats[1] - count"
			let "total = stats[2] - total"
			let "time_max = stats[3] - time_max"
			let "time_min = stats[4] - time_min"
			userstats[i]=$(echo "$user $count $total $time_max $time_min")		
		fi
		let "i = i + 1"
	done
	if ! $found; then userstats[i]=$(echo "$user $count $total $time_max $time_min"); fi
done

# Outputs the sorted userstats' list
IFS=$' '
printf '%s\n' "${userstats[@]}" | $sort_tp