# No Budget

_text-mode user interface for [convergent XEN farms](https://github.com/pbraun9/xen)_

Build and install nobudget onto the system.

	cd nobudget/
	make
	make install

Eventually disable password-based authentication altogether and take over 22/tcp.

_assuming the casual SSH daemon is running on another port_

	vi /etc/ssh/sshd_config_nobudget

	AllowGroups budgetusers
	PermitRootLogin no
	Port 22
	PidFile /var/run/sshd_nobudget.pid
	HostKey /etc/ssh/ssh_host_ed25519_key
	HostKey /etc/ssh/ssh_host_ecdsa_key
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

	vi /etc/rc.d/rc.local

	echo -n starting nobudget sshd ...
	/usr/sbin/sshd -f /etc/ssh/sshd_config_nobudget && echo done || echo FAIL

hard-code the shared group for nobudget users

	groupadd -g 1004 budgetusers

create users and let them reach the text UI

	user=USERNAME

	useradd -m -g budgetusers -b /data/users -s /usr/local/bin/nobudget $user
	chmod 700 /data/users/$user/
	passwd --unlock $user

and put user's SSH public key in place.

