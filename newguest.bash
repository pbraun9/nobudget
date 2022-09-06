#!/bin/bash

debug=0

[[ $1 = auto ]] && auto=1

function asksystem {
	cat <<EOF

 Which system would you like to deploy?

  1. Debian 11 (Bullseye)
  2. NetBSD current (Sep 2022)
  3. Slackware Linux 15.0
  4. Ubuntu 22 (Jammy Jellyfish)

EOF
	  #- Sabotage Linux
	echo -n " Type a number: "
	read -r choice
	choice=${choice//[^0-9]}
	#choice=${choice,,}
	(( debug > 0 )) && echo sanitized choice is $choice
	echo

	case $choice in
		1)	tpl=bullseye
			nextavailable
			askname
			sudo /root/xen/new-resource.bash $tpl $avail && \
			sudo /root/xen/newguest-debian.bash $avail $name \
				&& echo $avail,$tpl,$name >> $HOME/guests.csv
			echo " Press Enter to return to previous menu"
			read -r
			exit
			;;
		2)	tpl=netbsd-current
			nextavailable
			askname
			sudo /root/xen/new-resource.bash $tpl $avail && \
			sudo /root/xen/newguest-netbsd.bash $avail $name \
				&& echo $avail,$tpl,$name >> $HOME/guests.csv
			echo " Press Enter to return to previous menu"
			read -r
			exit
			;;
		3)	tpl=slack150
			nextavailable
			askname
			sudo /root/xen/new-resource.bash $tpl $avail && \
			sudo /root/xen/newguest-slack.bash $avail $name \
				&& echo $avail,$tpl,$name >> $HOME/guests.csv
			echo " Press Enter to return to previous menu"
			read -r
			exit
			;;
		4)	tpl=jammy
			nextavailable
			askname
			sudo /root/xen/new-resource.bash $tpl $avail && \
			sudo /root/xen/newguest-debian.bash $avail $name \
				&& echo $avail,$tpl,$name >> $HOME/guests.csv
			echo " Press Enter to return to previous menu"
			read -r
			exit
			;;
		*)	return
			;;
	esac
}

function nextavailable {
	# grab last used drbd minor but avoid 200-254 (reserved)
	last=`cut -f1 -d, $HOME/guests.csv | sort -V | tail -1`

	if (( last < 1024 )); then
		# while starting a cluster from scratch, guest ids start with 1024 to match DNAT
		(( avail = 1024 ))
	else
		# simply increment to grab the next available guest id
		# TODO also re-use previously removed guest ids
		(( avail = last + 1 ))
	fi

	(( debug > 0 )) && echo avail is $avail

	# 64999+ are reserved
	(( avail > 65998 )) && echo that is too much instances && exit 1
}

function askname {
	echo -n " What target system hostname would you like to set? [dnc$avail]"
	read -r input
	name=${input//[^A-Za-z0-9-]}
	name=${name,,}
	[[ -z $name ]] && name=dnc$avail
}

if (( auto == 1 )); then
	tpl=slack150
	nextavailable
	name=dnc$avail
	sudo /root/xen/new-resource.bash $tpl $avail $name
	sudo /root/xen/newguest-slack.bash $tpl $avail $name \
		&& echo $avail,$tpl,$name >> $HOME/guests.csv
	exit
fi

clear

while true; do
	asksystem
done

echo Press Enter key to exit
read -r

