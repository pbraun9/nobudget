#!/bin/ksh
set -e

debug=0

#
# create new guest from template
# executed as registrated user
#

function build_up_debian {
	[[ -z $1 ]] && bomb function build_up_debian needs \$tpl
	tpl=$1

	next_available
	ask_name
	sudo ssh $random_node /usr/local/sbin/dnc-new-resource.bash $tpl $avail
	sudo ssh $random_node /usr/local/sbin/dnc-newguest-debian.bash $avail $name
	ready
}

function build_up_netbsd {
	[[ -z $1 ]] && bomb function build_up_netbsd needs \$tpl
	tpl=$1

	next_available
	ask_name
	sudo ssh $random_node /usr/local/sbin/dnc-new-resource.bash $tpl $avail
	sudo ssh $random_node /usr/local/sbin/dnc-newguest-netbsd.bash $avail $name
	ready
}

function build_up_slackware {
        [[ -z $1 ]] && bomb function build_up_slackware needs \$tpl
        tpl=$1

	next_available
	ask_name
	sudo ssh $random_node /usr/local/sbin/dnc-new-resource.bash $tpl $avail
	sudo ssh $random_node /usr/local/sbin/dnc-newguest-slack.bash $avail $name
	ready
}

function ask_system {
	cat <<EOF
 Which system would you like to deploy?

  1. Debian 11 (bullseye)
  2. NetBSD/amd64 9.3
  3. Slackware Linux 15.0 64-bit

EOF

	echo -n " Type a number: "
	read -r choice
	choice=${choice//[^0-9]}
	#choice=${choice,,}
	(( debug > 0 )) && echo sanitized choice is $choice
	echo

	case $choice in
		1) build_up_debian debian11jan2023 ;;
		2) build_up_netbsd TPL ;;
		3) build_up_slackware TPL ;;
		*) return ;;
	esac
}

function next_available {
	# grab last used drbd minor
	#last=`grep minor /etc/drbd.d/*.res | sort -V -k3 | awk '{print $4}' | cut -f1 -d';' | tail -1`
	last=`sudo ssh $random_node grep minor /etc/drbd.d/*.res | awk '{print $NF}' | cut -f1 -d';' | sort -bn | tail -1`

	(( debug > 0 )) && echo last is $last
	[[ -z $last ]] && bomb $prgnam function ${0##*/} was not able to define \$last

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
	(( avail > 64998 )) && bomb guest id limit 64999 is reached - cluster is too old or cannot handle that amount of guests

	[[ -f dnc$avail ]] && bomb $prgnam function ${0##*/} - dnc$avail is already referenced for user $USER
}

function ask_name {
	echo -n " What target system hostname would you like to set? [dnc$avail]"
	read -r input
	typeset -l name=${input//[^A-Za-z0-9-]}
	[[ -z $name ]] && name=dnc$avail
}

# this one runs as root anyhow - no need for su
if (( auto == 1 )); then
	tpl=slack150
	next_available
	name=dnc$avail
	sudo ssh $random_node /usr/local/sbin/dnc-new-resource.bash $tpl $avail
	sudo ssh $random_node /usr/local/sbin/dnc-newguest-slack.bash $avail $name
	exit
fi

function ready {
	echo -n referencing guest dnc$avail for user $USER ...
	echo created `date` > $HOME/dnc$avail && echo done

	cat <<EOF

 Wait 30 seconds meanwhile spanning tree settles down and you will be able reach the system as follows.

	ssh pmr.angrycow.ru -p $avail -l root

EOF

	echo " Return to previous menu (press enter key)"
	read -r
	exit
}

function define_random_node {
	(( random = RANDOM % cluster_size + 1 ))
	random_node=$prefix$random

	(( debug > 0 )) && echo random_node is $random_node

	# netbsd syntax
	ping -c1 -w1 $random_node >/dev/null || define_random_node

	unset random
}

prgnam=${0##*/}

[[ ! -f /usr/local/lib/nobudgetlib.ksh ]] && echo could not find /usr/local/lib/nobudgetlib.ksh && exit 1
[[ ! -f /etc/nobudget.conf ]] && echo could not find /etc/nobudget.conf && exit 1

. /usr/local/lib/nobudgetlib.ksh
. /etc/nobudget.conf

[[ -z $cluster_size ]] && bomb $prgnam - \$cluster_size not defined
[[ -z $prefix ]] && bomb $prgnam - \$prefix not defined

[[ -z $USER ]] && bomb $prgnam - \$USER not defined - should be `whoami`
[[ -z $HOME ]] && bomb $prgnam - \$HOME not defined for $USER
[[ ! -d $HOME/ ]] && bomb $prgnam - $HOME/ does not exist

[[ $1 = auto ]] && auto=1

define_random_node

clear

echo
echo NEW GUEST
echo
while true; do
	ask_system
done

# new-guest can be called either from main menu or from manage-guests
echo -n " Return to previous menu (press enter key)"
read -r

