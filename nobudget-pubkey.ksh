#!/bin/ksh
set -e

PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin

[[ -z $4 ]] && echo usage: ${0##*/} user/email pubkeytype pubkey comment && exit 1
user=$1
pubkeytype=$2
pubkey=$3
comment=$4

[[ ! -d /home/$user/ ]] && echo error: /home/$user/ does not exist && exit 1

[[ -d /home/$user/.ssh/ ]] && echo error: /home/$user/.ssh/ folder already exists && exit 1

echo -n adding ssh public key for $user ...
mkdir /home/$user/.ssh/
# this is first-time hence creating the file
echo $pubkeytype $pubkey $comment > /home/$user/.ssh/authorized_keys && echo done

echo -n fixing permissions for $user ...

#/sbin/chown -R $user. /home/$user/

# TODO allow only group users
/bin/chmod 755 /home/$user/
/bin/chmod 755 /home/$user/.ssh/
/bin/chmod 644 /home/$user/.ssh/authorized_keys && echo done

