#!/bin/bash

(( debug = 0 ))

function bomb {
        time=`date "+%Y-%m-%d %H:%M:%S"`

        echo "$time - error: $@" >> /var/tmp/nobudget.$USER.error.log 2>&1
        echo
        echo "error: $@"
        echo

        echo -n press enter key to exit
        read -r

	unset time
        exit 1
}

function asksystem {
	cat <<EOF
 Which system would you like to deploy?

  1. Debian 11 (Bullseye)
  2. NetBSD current (Sep 2022)
  3. Slackware Linux 64-bit 15.0
  4. Ubuntu 22 (Jammy Jellyfish)

EOF
# Sabotage Linux

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
			su -c "/root/xen/new-resource.bash $tpl $avail" root && \
			su -c "/root/xen/newguest-debian.bash $avail $name" root \
				&& echo $avail,$tpl,$name >> $HOME/guests.csv \
				&& ready
			echo " Press Enter to return to previous menu"
			read -r
			exit
			;;
		2)	tpl=netbsd-current
			nextavailable
			askname
			su -c "/root/xen/new-resource.bash $tpl $avail" root && \
			su -c "/root/xen/newguest-netbsd.bash $avail $name" root \
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
			su -c "/root/xen/new-resource.bash $tpl $avail" root && \
			su -c "/root/xen/newguest-slack.bash $avail $name" root \
				&& echo $avail,$tpl,$name >> $HOME/guests.csv \
				&& ready
			echo " Press Enter to return to previous menu"
			read -r
			exit
			;;
		4)	tpl=jammy
			nextavailable
			askname
			su -c "/root/xen/new-resource.bash $tpl $avail" root && \
			su -c "/root/xen/newguest-debian.bash $avail $name" root \
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
	# grab last used drbd minor but avoid 200-254 (reserved)
	last=`cut -f1 -d, /data/users/*/guests.csv | sort -V | tail -1`

	# that works even though we might have an empty variable (newly installed cluster)
	if (( last < 1024 )); then
		# while starting a cluster from scratch, guest ids start with 1024 to match DNAT
		(( avail = 1024 ))
	else
		# grab the next available guest id
		(( avail = last + 1 ))
	fi

	(( debug > 0 )) && echo avail is $avail

	# 64999+ are reserved
	(( avail > 65998 )) && echo guest id 64999? - cluster is too old or cannot handle that amount of instances && exit 1
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
	su -c "/root/xen/new-resource.bash $tpl $avail" root
	su -c "/root/xen/newguest-slack.bash $avail" root \
		&& echo $avail,$tpl,$name >> $HOME/guests.csv
	exit
fi

function ready {
	cat <<EOF
 Wait 30 seconds until spanning tree settles down and you will be able reach the system as follows.

	ssh pmr.angrycow.ru -p $avail -l root

EOF
}

clear

[[ -z $USER ]] && bomb USER not defined - should be `whoami`
[[ -z $HOME ]] && bomb HOME not defined for $USER
[[ ! -d /data/users/ ]] && bomb /data/ does not seem to be mounted - cluster state is non-optimal
[[ ! -d $HOME/ ]] && bomb $HOME/ does not exist

[[ $1 = auto ]] && auto=1

echo
echo NEW GUEST
echo
while true; do
	asksystem
done

# new-guest can be called either from main menu or from manage-guests
echo -n Press Enter key to return to previous menu
read -r

