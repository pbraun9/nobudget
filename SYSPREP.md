# nobudget sysprep

_tested on sabotage linux (busybox)_

setup that guest with two interfaces, one on the user network and one on the cluster network
-- here's the additional setup for cluster network e.g.

	vi /etc/rc.local

	# 22/tcp dnat --> cluster network
        ifconfig eth1 x.x.x.x netmask 255.255.255.0 up

also tune your dnat rules on the VIP as follows

                # nobudget service points to cluster network
                # dropbear holds 22/tcp so we go 2222/tcp
                iif $nic tcp dport 22 dnat x.x.x.x:2222;

pre-configure that user for prospects to register

	addgroup -g 999 register
	adduser -s /usr/local/bin/nobudget-register.ksh -G register -D -u 999 register

eventually fix the comment field to reflect the hostname

	vi /etc/passwd

	register:x:999:999:register@nobudget:/home/register:/usr/local/bin/nobudget-register.ksh

allow the text UIs as shells

	echo /usr/local/bin/nobudget-register.ksh >> /etc/shells
	echo /usr/local/bin/nobudget >> /etc/shells

make it possible for the register user to create system users

        cd /etc/
        chgrp register passwd
        chgrp register shadow
        chmod g+rw passwd
        chmod g+rw shadow

	cd /
	chown register:register home/
	# remains 755 ok

allow prospects to reach SSH service for the `register` user anonymously

	butch install openssh

	mv -i /etc/ssh/sshd_config /etc/ssh/sshd_config.dist
	grep -vE '^#|^$' /etc/ssh/sshd_config.dist > /etc/ssh/sshd_config.clean
	grep -vE '^#|^$' /etc/ssh/sshd_config.dist > /etc/ssh/sshd_config
	vi /etc/ssh/sshd_config

	# do not interfere with dropbear
	Port 2222

	# dirty hack to let users login although they don't have ownership of .ssh/
	strictmodes no

	match user register
		allowgroups register
		allowusers register
		authenticationmethods none
		passwordauthentication yes
		permitemptypasswords yes

ready to go

        ls -lF /var/service/openssh/down
        rm -f /var/service/openssh/down
        sv up openssh
        sv status openssh

and finally enable outbonud email

	cd /etc/ssl/
	wget https://curl.se/ca/cacert.pem

        butch list | grep libressl
        butch install msmtp
        ldd /bin/msmtp | grep ssl
	vi /etc/msmtprc

	...
	port 465
	tls on
	tls_starttls off
	tls_certcheck on
	tls_trust_file /etc/ssl/cacert.pem

### acceptance

you can test nobudget from within the system without SSH as such

        butch install su
        su - register
        #su - register -s /bin/bash

