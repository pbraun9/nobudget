#!/bin/bash
set -e

debug=0

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

function showhelp {
	cat <<EOF

        list            list all guests and their statuses
        new		deploy a new guest
        terminate       terminate a guest and its storage

        start		power on a guest
        reboot          reboot a guest
        stop		gracefully shutdown and power off a guest
        destroy         brutally power off a guest

        console         connect to a guest console

	exit		return to main menu

EOF
	#quit		close this session
}

function allguests {
	# TODO hmm that one wouldnt get refreshed in case of a new guest gets ordered
	[[ -z $folders ]] && folders=`find /data/guests/dnc* -type d -maxdepth 0`
	for guestpath in $folders; do
		guest=${guestpath##*/}

		echo -n $guest | sed 's/^/\t/'
		cat $guestpath/state | sed 's/^/\t/'

		unset guest
	done
	unset guestpath

	# might be re-used
	#unset folders
}

# TODO check that $node is still accurate for those functions
# see function whatnode

function cr {
	[[ -z $node ]] && bomb function cr requires \$node
	[[ -z $guest ]] && bomb function cr requires \$guest

	echo creating $guest
	ssh $node -t xl create $guest && echo created
	echo
}

function co {
	[[ -z $node ]] && bomb function co requires \$node
	[[ -z $guest ]] && bomb function co requires \$guest

}

function shu {
	[[ -z $node ]] && bomb function shu requires \$node
	[[ -z $guest ]] && bomb function shu requires \$guest

}

function des {
	[[ -z $node ]] && bomb function des requires \$node
	[[ -z $guest ]] && bomb function des requires \$guest

}

function manage_guests {
	echo -n "> "
	read -r cmd
	#cmd=${cmd//[^A-Za-z0-9-]}
	cmd=${cmd//[^A-Za-z\?]}
	cmd=${cmd,,}
	(( debug > 0 )) && echo sanitized cmd is $cmd

	# TODO also allow < > and ^D
	case $cmd in
		\?)
			showhelp
			;;
		co*)
			echo reaching out to $guest console
			ssh $node -t xl console $guest && echo TODO CLOSING CONSOLE || echo TADAAA
			echo
			;;
		cr*)
			cr
			;;
		des)
			echo destroying $guest
			ssh $node -t xl destroy $guest && echo destroyed
			echo
			;;
		l*)
			allguests
			;;
		n*)
			$HOME/nobudget/new-guest.bash
			;;
		r*)
			echo rebooting $guest
			ssh $node -t xl reboot $guest && echo rebooting
			echo
			;;
		shu)
			echo shutting down $guest
			ssh $node -t xl shutdown $guest && echo shutting down
			echo
			;;
		terminate)
			echo TODO TERMINATE A GUEST
			;;
		e*|q*)
			#echo
			#echo -n Press Enter key to return to main menu
			#read -r
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
}

clear

[[ -z $USER ]] && bomb USER not defined - should be `whoami`
[[ -z $HOME ]] && bomb HOME not defined for $USER
[[ ! -d /data/users/ ]] && bomb /data/ does not seem to be mounted - cluster state is non-optimal
[[ ! -d $HOME/ ]] && bomb $HOME/ does not exist

[[ ! -x /usr/local/bin/new-guest.bash ]] && bomb could not find /usr/local/bin/new-guest.bash executable

echo
echo MANAGE GUESTS
echo
echo Enter ? for help

while true; do
	manage_guests
done

