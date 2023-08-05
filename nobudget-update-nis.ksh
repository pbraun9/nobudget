#!/bin/ksh
set -e

# ksh required for using print because bash isn't happy with echoing shadow fields
# bash: :19574: bad word specifier

PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin

[[ -z $2 ]] && echo usage: ${0##*/} user/email coupon-code && exit 1
user=$1
coupon=$2

echo -n creating UNIX user $user ...

# register user has 999 so even if one starts from scratch, we're good somehow
(( uid = `cut -f3 -d: /etc/passwd | sort -n | tail -1` + 1 ))

(( epoch = `date +%s` / 60 / 24 ))

print "$user:x:$uid:10:$coupon:/home/$user:/usr/local/bin/nobudget" >> /etc/passwd && echo -n uid $uid ...
print "$user:!:$epoch:0:99999:7:::" >> /etc/shadow && echo -n epoch $epoch ... 
mkdir /home/$user/ && echo done

# chown: /home/your@email/: Operation not permitted
#chown $uid:10 /home/$user/ && echo done

