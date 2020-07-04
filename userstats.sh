#!/bin/bash
argu=".*"
sort_tp="sort"
only_one="n"
file_ses="last -w"

function how_to(){
    printf "\nHow To Use This Script:\n\tOptions:\n"
    echo "		-r:             Sort in reverse order"
    echo '		-s "date":      Filter sessions logged after "date"'
    echo '		-e "date":      Filter sessions logged before "date"'
    echo '                -u "pattern":   Filter sessions that are from users that match the "pattern"'
    echo '		-g "group":     Filter sessions that are from users that belong to the group "group"'
    echo '		-f "file":      Use "file" to get the users sessions'
    printf "\n\tYou May Choose Only One Of These:\n"
    echo "		-n:             Sort by number of sessions"
    echo "		-t:             Sort by total logged time"
    echo "		-a:             Sort by maximum logged time"
    echo "		-i:             Sort by minimum logged time"
}
function includes() {
    for element in ${user_group[@]}; do
        if [ "${element}" == "${group}" ]; then
            echo "y"
            return
        fi
    done
    echo "n"
    return
}
function valArg() {
    if [[ $1 == -* ]]; then
        printf "Invalid Argument.\n"
        how_to
        exit 1;
    fi
}
function valOpt(){
    if [[ $only_one == "y" ]];then
        echo "Can't select these arguments together"
        how_to
        exit 1;
    fi
    only_one="y"
}
function dateCheck() {
    if ! [[ $(tr "[:upper:]" "[:lower:]" <<<"$(date "+%b %d %H:%M" -d "${OPTARG}")") = $(tr "[:upper:]" "[:lower:]" <<<"${OPTARG}") ]]; then
        echo "The date isn't valid."
        how_to
        exit 1;
    fi
}
while getopts 'u:f:s:e:g:rnait' opt; do
   case "$opt" in
       u)
            valArg $OPTARG
            argu="$OPTARG"
            ;;
       g)
           valArg $OPTARG
           group=$OPTARG
           ;;
       f)
           if [ -f "$OPTARG" ] ; then
                file_ses="$file_ses -f $OPTARG";
           else
                printf "File wasn't found.\n";
                how_to
                exit 1;
           fi
           ;;
       s)
            valArg $OPTARG
            dateCheck
            start_date=$(date -d "$OPTARG" +"%Y-%m-%d %H:%M")
            file_ses="${file_ses} -s \"$start_date\""
           ;;
        e)
            valArg $OPTARG
            dateCheck
            end_date=$(date -d "$OPTARG" +"%Y-%m-%d %H:%M")
            file_ses="${file_ses} -t \"$end_date\""
           ;;
       i)
            sort_tp="$sort_tp -n -k5"
            valOpt
           ;;
       a)
            sort_tp="$sort_tp -n -k4"
            valOpt
           ;;
       t)
            sort_tp="$sort_tp -n -k3"
            valOpt
           ;;
       n)
            sort_tp="$sort_tp -n -k2"
            valOpt
           ;;
       r)
            sort_tp="$sort_tp -r"    
           ;;
        *)
            how_to
            exit 1;
            ;;
    esac
done
shift $((OPTIND -1))

users=($(eval $file_ses | awk '{ if (( $1 !~ /reboot/ && $1 !~ /wtmp/ && $1 !~ /shutdown/  && $10 !~ /in/ && $10 !~ /no/ )) {print $1}}' | sort |uniq | grep "$argu" ))

for user in ${users[@]}; do
    if [ -n "$group" ]; then
        user_group=($(id -G -n $user ))
        if [ $(includes) == "n" ]; then
            continue
        fi
    fi

    count=$(eval $file_ses | awk '{ if (( $1 !~ /reboot/ && $1 !~ /wtmp/ && $1 !~ /shutdown/  && $10 !~ /in/ && $10 !~ /no/ )) {print $1}}' | grep -o $user | wc -l)
    time_log=($(eval $file_ses | awk '{ if (( $1 !~ /reboot/ && $1 !~ /wtmp/ && $1 !~ /shutdown/  && $10 !~ /in/ && $10 !~ /no/ )) {print}}' | grep "$user" | awk '{ print $10 }' | tr " " " " | sed 's/[-)(]//g'))
    
    let "total = 0"
    for value in ${time_log[@]}; do
        if (( ${#value} > 5 )); then
            time_session=$(echo $value | tr '+' ':' | awk -F: '{ print ($1 * 1440) + ($2 * 60) + $3 }')
        else
            time_session=$(echo $value | awk -F: '{ print ($1 * 60) + $2 }')
        fi
        if (( $total == 0 )) ; then
            let "time_max = time_session"
            let "time_min = time_session"
        fi
        total=$(($total + $time_session))
        
        if (( time_session < time_min )); then
            time_min=$time_session
        fi

        if (( time_session > time_max )); then
            time_max=$time_session
        fi
    done
    userstats[${#userstats[@]}]=$(echo "$user $count $total $time_max $time_min")
done

if [[ ${users[0]} == "" || ${userstats[0]} == "" ]]; then
	echo "No Users Were Found."	
    how_to
	exit 1;
fi

printf '%s\n' "${userstats[@]}" | $sort_tp