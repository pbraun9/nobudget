#!/bin/bash

(( debug = 1 ))

clear
cat <<EOF

 Which guest name would you like to maintain?

EOF
sudo /root/xen/running-guests.bash
echo
echo -n " Type a guest name: "
read -r guest
guest=${guest//[^A-Za-z0-9]}
guest=${guest,,}
(( debug > 0 )) && echo sanitized choice is $choice

echo -e \\n temp - will maintain $guest\\n

echo Press Enter key to exit
read -r

