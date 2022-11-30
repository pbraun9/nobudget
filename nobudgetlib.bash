
function usage {
        echo
        echo " usage: ${0##*/} $@"
        echo
        exit 1
}

function bomb {
        time=`date +%Y-%m-%d %H:%M:%S`

        echo $time - user=$user guestid=$guestid minor=$minor guest=$guest name=$name - $@ >> /var/tmp/nobudget.error.log
        echo
        echo Error: $@
        echo

        unset time
        exit 1
}

