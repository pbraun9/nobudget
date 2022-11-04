#!/bin/bash

(( debug = 0 ))

function bomb {
	echo error: $@
	exit 1
}

function ready {
	cat <<EOF
 Wait 30 seconds until spanning tree settles down and you will be able reach this system as such.

	ssh pmr.angrycow.ru -p $avail -l root

EOF
}

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
				&& echo $avail,$tpl,$name >> $HOME/guests.csv \
				&& ready
			echo " Press Enter to return to previous menu"
			read -r
			exit
			;;
		2)	tpl=netbsd-current
			nextavailable
			askname
			sudo /root/xen/new-resource.bash $tpl $avail && \
			sudo /root/xen/newguest-netbsd.bash $avail $name \
				&& echo $avail,$tpl,$name >> $HOME/guests.csv \
				&& ready
			echo " Press Enter to return to previous menu"
			read -r
			exit
			;;
		3)	tpl=slack150
			#tpl=slackf2fs
			nextavailable
			askname
			sudo /root/xen/new-resource.bash $tpl $avail && \
			sudo /root/xen/newguest-slack.bash $avail $name \
				&& echo $avail,$tpl,$name >> $HOME/guests.csv \
				&& ready
			echo " Press Enter to return to previous menu"
			read -r
			exit
			;;
		4)	tpl=jammy
			nextavailable
			askname
			sudo /root/xen/new-resource.bash $tpl $avail && \
			sudo /root/xen/newguest-debian.bash $avail $name \
				&& echo $avail,$tpl,$name >> $HOME/guests.csv \
				&& ready
			echo " Press Enter to return to previous menu"
			read -r
			exit
			;;
		*)	return
			;;
	esac
}

function nextavailable {
	if [[ -f $HOME/guests.csv ]]; then
		# grab last used drbd minor but avoid 200-254 (reserved)
		last=`cut -f1 -d, $HOME/guests.csv | sort -V | tail -1`
	else
		# TODO
		last=1023
	fi

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
	(( avail > 65998 )) && echo cannot handle that amount of instances && exit 1
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
	#tpl=slackf2fs
	nextavailable
	name=dnc$avail
	sudo /root/xen/new-resource.bash $tpl $avail
	sudo /root/xen/newguest-slack.bash $avail \
		&& echo $avail,$tpl,$name >> $HOME/guests.csv
	exit
fi

clear

[[ -z $HOME ]] && bomb HOME not defined

[[ $1 = auto ]] && auto=1

while true; do
	asksystem
done

echo Press Enter key to exit
read -r

