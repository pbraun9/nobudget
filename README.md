# No Budget

_text-mode user interface for [convergent XEN farms](https://github.com/pbraun9/xen)_

## Install

Build and install nobudget onto the system.

	cd nobudget/
	make
	make install

Prepare an anonymous user that will be used for the registration process

	groupadd -g 1002 register
	useradd -m -u 1002 -g register -s /usr/local/bin/nobudget-register.ksh register
	passwd --unlock register
	#passwd --delete register

Disable password authentication but for that specific user and take over 22/tcp.

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

	Match user register
		AllowGroups register
		AllowUsers register
		AuthenticationMethods none
		PasswordAuthentication yes
		PermitEmptyPasswords yes

Note mailx wants $HOME to exist - this is why we provided a true homedir

	ls -alF /home/register/

Enable at system startup

	vi /etc/rc.d/rc.local

	echo -n starting nobudget sshd ...
	/usr/sbin/sshd -f /etc/ssh/sshd_config_nobudget && echo done || echo FAIL

## Operations

Create new users using registration process as follows.

	ssh your.domain.tld -l register

If not using the anonymous registration process, you can otherwise create users manually and let them reach the text UI as follows.

	user=USERNAME

	useradd -m -g budgetusers -b /data/users -s /usr/local/bin/nobudget $user
	chmod 700 /data/users/$user/
	passwd --unlock $user
	#passwd --delete $user

and put user's SSH public key in place.

## Cluster requirements (optional)

Hard-code the shared group for nobudget users (users can be [NIS](https://pub.nethence.com/network/nis-master) or LDAP powered).

	groupadd -g 1004 budgetusers

Prepare SSH host keys to be shared across the cluster nodes, so users don't notice when ever the [keepalived](https://pub.nethence.com/daemons/keepalived) VIP moves around.

	cluster=CLUSTER-NAME

	ssh-keygen -q -t ed25519 -f /etc/ssh/ssh_host_ed25519_key_nobudget -C root@$cluster -N ''
	ssh-keygen -q -t ecdsa -f /etc/ssh/ssh_host_ecdsa_key_nobudget -C root@$cluster -N ''

