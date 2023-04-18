# No Budget

_text-mode user interface for [convergent DRBD/XEN farms](https://github.com/pbraun9/dnc)_

_tested on netbsd93_

# Overview

To be highly available, No Budget requires at least two nodes e.g.

        ypmaster
        ypslave

The nobudget text-mode user interface can be balanced on both, however there's only one NIS master at a time, this is why
NIS user creation is only done on the NIS master (see nobudget-register.ksh which checks which master there is before call
ing it).

## Permission model

There is a specific `register` user on both nis/nobudget nodes for prospects to create user accounts.
This user has the rights to call the `nobudget-update-nis.ksh` and `nobudget-pubkey.ksh` scripts (see sudoers setup).

## Requirements

- a NIS master (and eventually a NIS slave, with the ability to ssh as root to one another)
- a few packages (`pwgen`, `ksh93`)
- a working outbound email system

## Preliminary steps

pre-configure that user for prospects to register

	groupadd -g 999 register
	useradd -m -u 999 -g register -s /bin/ksh register
	# -s /usr/local/bin/nobudget-register.ksh

allow the TUIs as shell

	vi /etc/shells

	/usr/local/bin/nobudget-register.ksh
	/usr/local/bin/nobudget

allow the `register` user to create new NIS users
and the `nisusers` group to ssh to DRBD/XEN nodes

	vi /etc/sudoers

	register ALL=(root) NOPASSWD: /usr/local/sbin/nobudget-update-nis.ksh
	register ALL=(root) NOPASSWD: /usr/local/sbin/nobudget-pubkey.ksh

	# quick & dirty for now
	%nisusers ALL=(root) NOPASSWD: /usr/bin/ssh

## Install

Build and install nobudget onto the system.

        git clone https://github.com/pbraun9/nobudget.git
        cd nobudget/
	make
        make install

## Setup

        cp nobudget.conf /etc/
        vi /etc/nobudget.conf

## Operations

        tail -F /var/tmp/nobudget*log

<!--
## Sysprep for the management console

hard-code a shared group for nobudget users

	groupadd -g 1004 budgetusers

disable password authentication and take over 22/tcp

_assuming the casual SSH daemon is running on another port_

	vi /etc/ssh/sshd_config_nobudget

	AllowGroups budgetusers wheel
	PermitRootLogin no
	Port 22
	PidFile /var/run/sshd_nobudget.pid
	HostKey /etc/ssh/ssh_host_ecdsa_key_nobudget
	HostKey /etc/ssh/ssh_host_ed25519_key_nobudget
	# no sftp

	AuthenticationMethods publickey
	AuthorizedKeysFile .ssh/authorized_keys
	Ciphers aes128-ctr,aes192-ctr,aes256-ctr,aes128-gcm@openssh.com,aes256-gcm@openssh.com
	KbdInteractiveAuthentication no
	MaxAuthTries 3
	PasswordAuthentication no
	PermitEmptyPasswords no
	PrintMotd no
	Protocol 2
	StrictModes yes
	UseDNS no
	UsePAM no
	X11Forwarding no
	AllowTcpForwarding no

enable at boot-time

	vi /etc/rc.d/rc.local

	echo -n starting nobudget sshd ...
	/usr/sbin/sshd -f /etc/ssh/sshd_config_nobudget && echo done || echo FAIL

## Operations for the management console

create a user for testing

	useradd -m -u 1004 -g budgetusers -b /data/users -s /usr/local/bin/nobudget budgetuser
	passwd --delete budgetuser
	passwd --unlock budgetuser
	chmod 700 /data/users/budgetuser/

and put QA's SSH public key in place.

<!--
here's a workaround for sudo and pam not to complain about NIS users

	cd /etc/
	cp -R pam.d/ pam.d.dist/
	vi pam.d/su

	auth            sufficient      pam_wheel.so trust use_uid
-->

## Sysprep for the registration process

prepare a user that will be used for the registration process

	groupadd -g 1002 register
	useradd -m -u 1002 -g register -s /usr/local/bin/nobudget-register.ksh register
	passwd --delete register
	passwd --unlock register
	chmod 700 /home/register/

note mailx wants $HOME to exist - this is why we provided a true homedir

add this onto sshd_config_nobudget - enable empty password for that specific user

        vi /etc/ssh/sshd_config_nobudget

	Match user register
		AllowGroups register
		AllowUsers register
		AuthenticationMethods none
		PasswordAuthentication yes
		PermitEmptyPasswords yes

also create a dedicated user for handling priviledged commands

	groupadd -g 1003 register-helper
        useradd -m -u 1003 -g register-helper -s /bin/bash register-helper

tune sudo accordingly

	vi /etc/sudoers

	# this is for the YP master - calling pmr1 on the internal network SSH service
	register-helper ALL=(root) NOPASSWD: /usr/local/sbin/nobudget-update-nis

	# this is for any node further creating NIS user on the shared-disk
	# and checking NIS user existance with getent
	register ALL=(root) NOPASSWD: /usr/local/sbin/nobudget-pubkey
	register ALL=(root) NOPASSWD: /usr/bin/getent passwd

	# this is for registered users to create and manage guests
	# used by nobudget/new-guest.bash
	%wheel ALL=(root) NOPASSWD: /usr/local/sbin/dnc-new-resource.bash
	%wheel ALL=(root) NOPASSWD: /usr/local/sbin/dnc-newguest-debian.bash
	%wheel ALL=(root) NOPASSWD: /usr/local/sbin/dnc-newguest-netbsd.bash
	%wheel ALL=(root) NOPASSWD: /usr/local/sbin/dnc-newguest-slack.bash
	# used by nobudget/manage-guests.bash
	%wheel ALL=(root) NOPASSWD: /usr/local/sbin/dnc-running-guest.bash
	%wheel ALL=(root) NOPASSWD: /usr/local/sbin/dnc-startguest-lowram.bash
	%wheel ALL=(root) NOPASSWD: /usr/local/sbin/dnc-rebootguest.bash
	%wheel ALL=(root) NOPASSWD: /usr/local/sbin/dnc-shutdown-guest.bash

## Operations for the registration process

you are now ready to proceed with online user registration

	ssh your.domain.tld -l register

## Cluster requirements (optional)

nobudget users can be [NIS](https://pub.nethence.com/network/nis-master) or LDAP powered

make sure NIS starts serving at UID and GID 1005

	vi /etc/yp/Makefile

	MINUID=1005
	MINGID=1005

prepare SSH host keys to be shared across the cluster nodes, so users don't notice when ever the [keepalived](https://pub.nethence.com/daemons/keepalived) VIP moves around.

	cluster=CLUSTER-NAME

	ssh-keygen -q -t ed25519 -f /etc/ssh/ssh_host_ed25519_key_nobudget -C root@$cluster -N ''
	ssh-keygen -q -t ecdsa -f /etc/ssh/ssh_host_ecdsa_key_nobudget -C root@$cluster -N ''
-->

