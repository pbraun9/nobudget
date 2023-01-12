
function bomb {
        time=`date "+%Y-%m-%d %H:%M:%S"`

        echo "$time - error: $@" >> /var/tmp/nobudget-register.error.log 2>&1
        echo
        echo "error: $@"
        echo

        echo -n press enter key to exit
        read -r

        unset time
        exit 1
}

function debugvar {
        (( debug != 1 )) && return

        print debug: $1 is \\c
        eval "print \$$1"
}

