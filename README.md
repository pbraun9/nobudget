# No Budget

_text-mode user interface for [convergent XEN farms](https://github.com/pbraun9/xen)_

## Installation

Build and install nobudget onto the system.

	cd nobudget/
	make
	make install

## Sysprep for the management console

hard-code a shared group for nobudget users

	groupadd -g 1004 budgetusers

disable password authentication and take over 22/tcp

_assuming the casual SSH daemon is running on another port_

	vi /etc/ssh/sshd_config_nobudget

	AllowGroups budgetusers
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
	register ALL=(root) NOPASSWD: /usr/local/sbin/nobudget-pubkey

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

