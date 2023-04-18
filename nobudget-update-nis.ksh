#!/bin/ksh
set -e

#
# connect to the NIS master on the cluster vlan and rebuild maps
#

PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:/usr/pkg/bin:/usr/pkg/sbin

[[ -z $2 ]] && echo usage: ${0##*/} user email && exit 1
user=$1
email=$2

[[ ! -x `which ypwhich` ]] && echo ypwhich executable not found && exit 1
#[[ ! -x `which pwgen` ]] && echo pwgen executable not found && exit 1

# determine who's the current nis master
echo -n searching for NIS master server ...
ypmaster=`ypwhich` && echo $ypmaster

echo -n creating UNIX user $user on $ypmaster ...
ssh $ypmaster -l root "/usr/sbin/useradd -m -g nisusers -c $email -s /usr/local/bin/nobudget $user && echo done"

#echo -n unlocking user $user ...
#unalias pwgen 2>/dev/null || true
#(echo -n "$user:"; pwgen 16 1) | chpasswd $user & echo done

# we want the maps to be re-generated as soon as possible
# so the host can see the user eventually already exists
echo -n updating NIS on $ypmaster ...
ssh $ypmaster -l root "cd /var/yp/ && make >/dev/null && echo done"

