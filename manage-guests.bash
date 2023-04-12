#!/bin/bash
set -e

debug=0

function show_help {
	cat <<EOF

             list		list all guests and their statuses
              new		create a new guest

          poweron <guest>	power on a guest
           reboot <guest>	gracefully restart a guest
          console <guest>	connect to a guest console
         poweroff <guest>	gracefully shutdown and power off a guest
          destroy <guest>	brutally power off a guest
           remove <guest>	terminate a guest and its storage

	     exit		return to main menu
EOF
	#quit		close this session
}

function list_user_guests {
	# HOME refers to registered user's in /data/users/USERNAME/
	# this is the default CWD already but we're forcing it anyhow
	cd $HOME/

	# dsh guest listing shows-up with prefix with 'pmrX: '
	echo '      Name                                        ID   Mem VCPUs        State   Time(s)'

	# symlinks created upon guest creation against ../../guests/GUESTNAME
	ugsts=`ls -1 | grep -E '^dnc[[:digit:]]'` || true # can be empty
	[[ -z $ugsts ]] && echo -e "      (empty list)\n" && return
	for ugst in $ugsts; do
		[[ ! -d /data/guests/$ugst ]] && bomb cannot find xen guest folder for $ugst - shared disk cluster offline for node `hostname`?
		tmp=`sudo /usr/local/sbin/dnc-running-guest.bash $ugst`
		[[ -z $tmp ]] && echo "      $ugst is down" || echo "$tmp"
		unset tmp
	done; unset ugst

	unset ugsts
	echo
}

# TODO check that $node is still accurate for those functions
# see function whatnode

function guest_poweron {
	[[ -z $guest ]] && bomb function guest_poweron requires \$guest
	[[ ! -x /usr/local/sbin/dnc-startguest-lowram.bash ]] && bomb /usr/local/sbin/dnc-startguest-lowram.bash not executable
	sudo /usr/local/sbin/dnc-startguest-lowram.bash $guest
}

function guest_reboot {
	[[ -z $guest ]] && bomb function guest_reboot requires \$guest
	[[ ! -x /usr/local/sbin/dnc-rebootguest.bash ]] && bomb /usr/local/sbin/dnc-rebootguest.bash not executable
	sudo /usr/local/sbin/dnc-rebootguest.bash $guest
}

function guest_console {
	[[ -z $guest ]] && bomb function guest_console requires \$guest
	[[ ! -x /usr/local/sbin/dnc-consoleguest.bash ]] && bomb /usr/local/sbin/dnc-consoleguest.bash not executable
	cat <<EOF
 Your $guest guest system can be reached as follows.

	ssh pmr.angrycow.ru -p ${guest#dnc} -l root

EOF
	echo -n "Are you sure you want to reach the physical console? [y]"
	read -r answer
	[[ $answer = y ]] && sudo /usr/local/sbin/dnc-consoleguest.bash $guest
}

function guest_poweroff {
	[[ -z $guest ]] && bomb function guest_poweroff requires \$guest
	[[ ! -x /usr/local/sbin/dnc-shutdown-guest.bash ]] && bomb /usr/local/sbin/dnc-shutdown-guest.bash not executable
	sudo /usr/local/sbin/dnc-shutdown-guest.bash $guest
}

function guest_destroy {
	[[ -z $guest ]] && bomb function guest_destroy requires \$guest
	[[ ! -x /usr/local/sbin/dnc-destroy-guest.bash ]] && bomb /usr/local/sbin/dnc-destroy-guest.bash not executable
	sudo /usr/local/sbin/dnc-destroy-guest.bash $guest
}

function guest_remove {
	[[ -z $guest ]] && bomb function guest_destroy requires \$guest
	[[ ! -x /usr/local/sbin/dnc-remove-resource.bash ]] && bomb /usr/local/sbin/dnc-remove-resource.bash not executable

	if [[ -h $HOME/$guest ]]; then
		[[ ! -d /data/guests/$guest/ ]] && bomb guest $guest does not exist although it is registered for user $USER

		echo -n un-registering guest $guest ...
		rm -f $HOME/$guest && echo done

		sudo /usr/local/sbin/dnc-remove-resource.bash $guest
	else
		[[ -d /data/guests/$guest/ ]] && bomb could not find $HOME/$guest symlink although guest does exist
		echo guest $guest does not exist
	fi
	echo
}

function presskey {
	echo
	echo -n Press Enter key to return to main menu
	read -r
}

function manage_guests {
	#echo Enter ? for help
	echo -n 'angrycow> '
	read -r cmd
	#cmd=${cmd//[^-]}
	cmd=${cmd//[^A-Za-z0-9\? ]}
	cmd=${cmd,,}
	guest=${cmd#* }
	cmd=${cmd%% *}
	(( debug > 0 )) && echo sanitized cmd is $cmd
	(( debug > 0 )) && echo eventual guest is $guest
	echo

	# TODO also allow < > and ^D
	case $cmd in
		\?)
			show_help
			;;
		l*)
			list_user_guests
			;;
		n*)
			/usr/local/bin/new-guest.bash
			;;
		poweron|cr*)
			guest_poweron
			;;
		co*)
			guest_console
			;;
		reb*)
			guest_reboot
			;;
		poweroff|shu*)
			guest_poweroff
			;;
		des)
			guest_destroy
			;;
		remove)
			guest_remove
			presskey
			;;
		exit|quit)
			exit
			;;
		#q*)
		#	echo
		#	echo -n Press Enter to close the session
		#	read -r
		#	exit
		#	;;
		*)
			;;
	esac
	unset cmd
	echo
}

clear

source /usr/local/lib/dnclib.bash

[[ -z $USER ]] && bomb USER not defined - should be `whoami`
[[ -z $HOME ]] && bomb HOME not defined for $USER
[[ ! -d /data/users/ ]] && bomb /data/ does not seem to be mounted - cluster state is non-optimal
[[ ! -d $HOME/ ]] && bomb $HOME/ does not exist

[[ ! -x /usr/local/bin/new-guest.bash ]] && bomb could not find /usr/local/bin/new-guest.bash executable

cat <<EOF

 MANAGE GUESTS

EOF

list_user_guests
while true; do
	manage_guests
done

