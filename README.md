# No Budget

_text-mode user interface for [convergent XEN farms](https://github.com/pbraun9/xen)_

Build and install nobudget onto the system.

	cd nobudget/
	make
	make install

Eventually disable password-based authentication altogether and take over 22/tcp.

_assuming the casual SSH daemon is running on another port_

	vi /etc/ssh/sshd_config_nobudget

	AllowGroups nobudget
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

You are now ready to create users and let them reach your IaaS console.

	user=USERNAME

	groupadd nobudget
	useradd -m -g nobudget -s /usr/local/bin/nobudget $user
	chmod 700 /home/$user/
	passwd --unlock $user

and put user's SSH public key in place.

