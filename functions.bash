
function usage {
        echo
        echo " usage: ${0##*/} $@"
        echo
        exit 1
}

function bomb {
        time=`date +%s`

        echo $time - user=$user guestid=$guestid minor=$minor guest=$guest name=$name - $@ >> /var/log/dnc.error.log
        echo
        echo Error: $@
        echo

        unset time
        exit 1
}

