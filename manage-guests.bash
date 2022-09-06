#!/bin/bash
set -e

debug=0

function showhelp {
	cat <<EOF

 Available commands

        console         reach a guest console
        create          power on a guest
        destroy         brutally power off a guest
        list            list all guests and their statuses
        new		deploy a new guest
        reboot          reboot a guest
        shutdown        gracefully power off a guest
        terminate       terminate a guest and its storage

        back		return to previous menu
	quit		close this session

EOF
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

function manageguests {
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
			$HOME/nobudget/newguest.bash
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
		b*)
			echo " Press Enter to return to previous menu"
			read -r
			exit
			;;
		q*)
			echo
			echo " Press Enter to close the session"
			read -r
			exit
			;;
		*)
			echo unknown command
			;;
	esac
	unset cmd
}

source $HOME/nobudget/functions.bash

[[ ! -f $HOME/nobudget/newguest.bash ]] && bomb could not find $HOME/nobudget/newguest.bash

clear
echo MANAGE GUESTS
echo
allguests
echo
echo Enter ? for help

while true; do
	manageguests
done

