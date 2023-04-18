#!/bin/ksh
set -e

#
# setup new SSH pubkeys for registered user
#
# let us do that one locally for now - we can assume /home/ is shared anyways
# user's pubkeys could be deployed from any nis/nobudget guest
#

[[ -z $4 ]] && echo usage: ${0##*/} user pubkeytype pubkey comment && exit 1
user=$1
pubkeytype=$2
pubkey=$3
comment=$4

# was created with useradd -m
[[ ! -d /home/$user/ ]] && echo error: /home/$user/ does not exist && exit 1

# should not exist yet
[[ -d /home/$user/.ssh/ ]] && echo error: /home/$user/.ssh/ folder already exists && exit 1

echo -n adding SSH public key for $user ...
mkdir /home/$user/.ssh/
echo $pubkeytype $pubkey $comment >> /home/$user/.ssh/authorized_keys && echo done

echo -n fixing permissions for $user ...
chown -R $user. /home/$user/
chmod 700 /home/$user/
chmod 700 /home/$user/.ssh/
chmod 600 /home/$user/.ssh/authorized_keys && echo done

