# No Budget

_text-mode user interface for [convergent DRBD/XEN farms](https://github.com/pbraun9/dnc)_

![IMAGE HERE](i/nobudget.png)

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
- a few packages (`pwgen`, `ksh93`, `sudo`)
- a working outbound email system

## Preliminary steps

pre-configure that user for prospects to register

	groupadd -g 999 register
	useradd -m -u 999 -g register -s /usr/local/bin/nobudget-register.ksh register

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

also allow prospects to reach SSH service for the `register` user anonymously.

	mv -i /etc/ssh/sshd_config /etc/ssh/sshd_config.dist
	grep -vE '^#|^$' /etc/ssh/sshd_config.dist > /etc/ssh/sshd_config.clean
	grep -vE '^#|^$' /etc/ssh/sshd_config.dist > /etc/ssh/sshd_config
	vi /etc/ssh/sshd_config

	LoginGraceTime 600
	AuthorizedKeysFile      .ssh/authorized_keys

	# no pam
	UsePam no

	# no sftp
	#Subsystem      sftp    /usr/libexec/sftp-server

	AllowGroups wheel nisusers
	PermitRootLogin yes
	HostKey /etc/ssh/ssh_host_ecdsa_key
	HostKey /etc/ssh/ssh_host_ed25519_key

	AuthenticationMethods publickey
	KbdInteractiveAuthentication no
	MaxAuthTries 3
	PasswordAuthentication no
	PermitEmptyPasswords no
	PrintMotd no
	Protocol 2
	StrictModes yes
	UseDNS no
	X11Forwarding no
	AllowTcpForwarding no

	Match user register
		AllowGroups register
		AllowUsers register
		AuthenticationMethods none
		PasswordAuthentication yes
		PermitEmptyPasswords yes

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

_assuming netbsd_

        tail -F /var/tmp/nobudget.register.error.log
	ls -lF /var/tmp/nobudget.*.log

