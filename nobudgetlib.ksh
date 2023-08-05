
# both to log file and sdtout
function bomb {
        time=`date "+%Y-%m-%d %H:%M:%S"`

	# writing there meanwhile, so both register and users can write logs
	# besides, users do not currently have write access to their own home dir
        echo "$time - error: $@" >> /var/tmp/nobudget.$USER.error.log 2>&1

	#echo "$time - error: $@" >> /home/$USER/nobudget.error.log 2>&1

        echo
        echo "error: $@"
        echo

        echo -n press enter key to exit
        read -r

        unset time
        exit 1
}

function showvar {
        (( debug != 1 )) && return

        print debug: $1 is \\c
        eval "print \$$1"
}

# defines $node
function whatnode {
        [[ -z $guest ]] && bomb function $0 requires \$guest

        node=`dsh -e -g xen "xl list $guest 2>&1 | sed 1d | cut -f1 -d' '| grep -v 'rc=-6'" | cut -f1 -d:`

        [[ -z $node ]] && bomb guest $guest does not seem to be running anywhere in the farm
}

