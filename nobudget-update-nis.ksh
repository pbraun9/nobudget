#!/bin/ksh
set -e

#
# connect to the NIS master on the cluster vlan and rebuild maps
# useradd doesn't allow @ so we're going pwd_mkdb

PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:/usr/pkg/bin:/usr/pkg/sbin

[[ -z $2 ]] && echo usage: ${0##*/} username/email coupon-code && exit 1
user=$1
coupon=$2

[[ ! -x `which ypwhich` ]] && echo ypwhich executable not found && exit 1
#[[ ! -x `which pwgen` ]] && echo pwgen executable not found && exit 1

# determine who's the current nis master
echo -n searching for NIS master server ...
ypmaster=`ypwhich` && echo $ypmaster

echo -n creating UNIX user $user on $ypmaster ...
ssh $ypmaster -l root /usr/sbin/useradd -m -g nisusers -c $coupon -s /usr/local/bin/nobudget $user && echo done
#ssh $ypmaster -l root echo $user:*:1000:100:$coupon:/home/$user:/usr/local/bin/nobudget >> /etc/passwd && echo done

# useradd: Can't add user `pouet@pouet.fr': invalid login name
# pwd_mkdb: user `pbraun@nethence.com' not found in password file

# https://man.netbsd.org/pwd_mkdb.8
#echo -n updating password database on $ypmaster ...
#ssh $ypmaster -l root /usr/sbin/pwd_mkdb -wu $user /etc/master.passwd && echo done

#echo -n unlocking user $user ...
#unalias pwgen 2>/dev/null || true
#(echo -n "$user:"; pwgen 16 1) | chpasswd $user & echo done

# we want the maps to be re-generated as soon as possible
# so the host can see the user eventually already exists
echo -n updating NIS on $ypmaster ...
ssh $ypmaster -l root "cd /var/yp/ && make >/dev/null && echo done"

