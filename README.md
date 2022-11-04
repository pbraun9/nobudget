# No Budget

Install nobudget onto the system.

	cd nobudget/
	make
	make install

Assuming SSH is running on an exotic port, take over 22/tcp.

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

	vi /etc/rc.d/rc.local

	/usr/sbin/sshd -f /etc/ssh/sshd_config_nobudget && echo NOBUDGET SSHD

