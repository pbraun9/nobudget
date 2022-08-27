#!/bin/bash

(( debug = 1 ))

function nextavailable {
	# last used drbd minor
	last=`sort -n $HOME/guests.csv | tail -1 | cut -f1 -d,`

	(( avail = last + 1 ))
	(( debug > 0 )) && echo avail is $avail
}

clear
cat <<EOF

 Which GNU/Linux distribution would you like to have?

  1. Debian 11 (bullseye)
  2. Slackware64 15.0
  3. Ubuntu 22 (Jammy Jellyfish)

EOF
  #- Sabotage Linux
echo -n " Type a number: "
read -r choice
choice=${choice//[^0-9]}
#choice=${choice,,}
(( debug > 0 )) && echo sanitized choice is $choice

case $choice in
	1)	tpl=bullseye
		nextavailable
		sudo /root/xen/newguest-debian.bash bullseye $avail \
			&& echo $avail,$tpl >> $HOME/guests.csv
		;;
	2)	tpl=slack
		nextavailable
		sudo /root/xen/newguest-slack.bash slack $avail \
			&& echo $avail,$tpl >> $HOME/guests.csv
		;;
	3)	tpl=jammy
		nextavailable
		sudo /root/xen/newguest-debian.bash jammy $avail \
			&& echo $avail,$tpl >> $HOME/guests.csv
		;;
esac

echo Press Enter key to exit
read -r

