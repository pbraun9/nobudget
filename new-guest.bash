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

# su instead of sudo to avoid pam complain about NIS users
# HOME here refers to the registrated user

function build-up-debian {
	[[ -z $1 ]] && bomb function build-up-debian needs \$tpl
	tpl=$1

	nextavailable
	askname
	su - -m -c "/usr/local/sbin/dnc-new-resource.bash $tpl $avail" root && \
	su - -m -c "/usr/local/sbin/dnc-newguest-debian.bash $avail $name" root && ready
}

function build-up-netbsd {
	[[ -z $1 ]] && bomb function build-up-netbsd needs \$tpl
	tpl=$1

	nextavailable
	askname
	su - -m -c "/usr/local/sbin/dnc-new-resource.bash $tpl $avail" root && \
	su - -m -c "/usr/local/sbin/dnc-newguest-netbsd.bash $avail $name" root && ready
}

function build-up-slackware {
        [[ -z $1 ]] && bomb function build-up-slackware needs \$tpl
        tpl=$1

	nextavailable
	askname
	su - -m -c "/usr/local/sbin/dnc-new-resource.bash $tpl $avail" root && \
	su - -m -c "/usr/local/sbin/dnc-newguest-slack.bash $avail $name" root && ready
}

function asksystem {
	cat <<EOF
 Which system would you like to deploy?

  1. Debian 11 (bullseye)

EOF
#  1. CRUX 3.7
#  2. NetBSD current (Sep 2022)
#  3. Slackware Linux 15.0 (64-bit)
#  5. Sabotage Linux

	echo -n " Type a number: "
	read -r choice
	choice=${choice//[^0-9]}
	#choice=${choice,,}
	(( debug > 0 )) && echo sanitized choice is $choice
	echo

	case $choice in
		1) build-up-debian debian11jan2023 ;;
		#2) build-up-netbsd TPL ;;
		#3) build-up-slackware TPL ;;
		*) return ;;
	esac
}

function nextavailable {
	# grab last used drbd minor
	last=`grep minor /etc/drbd.d/*.res | sort -V -k3 | awk '{print $4}' | cut -f1 -d';' | tail -1`

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
}

function askname {
	echo -n " What target system hostname would you like to set? [dnc$avail]"
	read -r input
	name=${input//[^A-Za-z0-9-]}
	name=${name,,}
	[[ -z $name ]] && name=dnc$avail
}

# this one runs as root anyhow - no need for su
if (( auto == 1 )); then
	tpl=slack150
	nextavailable
	name=dnc$avail
	/usr/local/sbin/dnc-new-resource.bash $tpl $avail
	/usr/local/sbin/dnc-newguest-slack.bash $avail $name
	exit
fi

function ready {
	echo -n referencing guest dnc$avail for user $USER ...
	ln -s ../../guests/dnc$avail $HOME/dnc$avail && echo done

	cat <<EOF

 Wait 30 seconds until spanning tree settles down and you will be able reach the system through destination NAT as follows.

	ssh pmr.angrycow.ru -p $avail -l root

EOF

	echo " Return to previous menu (press enter key)"
	read -r
	exit
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
echo -n " Return to previous menu (press enter key)"
read -r

