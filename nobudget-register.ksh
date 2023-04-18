#!/bin/ksh
set -e

#
# shell-based PoC to register nobudget users
#

debug=0

provider="Angry Cow"
from=noreply@angrycow.ru
support=support@angrycow.ru
# assuming postfix creates message-id header (always_add_missing_headers)

function ask_user {
	print -n Please enter desired username: \\c
	read -r tmp
	tmp2=`echo "$tmp" | sed -r 's/[^[:alnum:]_.@-]//g'`
	user=`echo "$tmp2" | grep -E '^[[:alnum:]]+$'`
	if [[ -z "$tmp" || -z "$tmp2" || -z "$user" || "$tmp" != "$tmp2" || "$user" != "$tmp" ]]; then
		showvar tmp
		showvar tmp2
		showvar user

		print
		print You have entered invalid characters
		print 
        	unset tmp tmp2 user

		ask_user
	fi
	unset tmp tmp2

	# users, here "register", can see NIS users without the need of sudo
	[[ ! -z `getent passwd | grep ^$user:` ]] && echo user $user already exists - please try another user name && ask_user || true
}

function ask_email {
	print -n Please enter your email: \\c
	read -r tmp
	tmp2=`echo "$tmp" | sed -r 's/[^[:alnum:]_.@-]//g'`
	email=`echo "$tmp2" | grep -E '^[[:alnum:]]+@[[:alnum:]_.-]+\.[[:alpha:]]+$'`
	if [[ -z "$tmp" || -z "$tmp2" || -z "$email" || "$tmp" != "$tmp2" || "$email" != "$tmp" ]]; then
		showvar tmp
		showvar tmp2
		showvar email

		print
		print You have entered invalid characters
		print 
        	unset tmp tmp2 email

		ask_email
	fi
	unset tmp tmp2

        [[ ! -z `getent passwd | grep :$email:` ]] && echo email $email is already registered as another account && ask_email || true
}

function ask_pubkey {
	print Please enter your SSH public key and comment \(one line\):
	read -r tmp
	tmp2=`echo "$tmp" | sed -r 's/[^[:alnum:] _./@-]//g'`
        pubkey=`echo "$tmp2" | grep -E '^[[:alnum:] _./@-]+$'`
        if [[ -z "$tmp" || -z "$tmp2" || -z "$pubkey" || "$tmp" != "$tmp2" || "$pubkey" != "$tmp" ]]; then
                showvar tmp
                showvar tmp2
                showvar pubkey

                print
                print You have entered invalid characters
                print
        	unset tmp tmp2 pubkey

                ask_pubkey
        fi
        unset tmp tmp2
	pubkeytype=`echo $pubkey | awk '{print $1}'`
	comment=`echo $pubkey | awk '{print $3}'`
	pubkey=`echo $pubkey | awk '{print $2}'`
}

function send_email_code {
	unalias pwgen || true
	code=`pwgen --no-capitalize --no-numerals --secure 5 1 | tr a-z A-Z`

	print "sending registration code to $email (STARTTLS)... \c"
	#print Here is the code to register at $provider: $code | mail -s "$provider registration code" $email && echo done
	cat <<EOF | sendmail -t && echo done
From: $provider <$from>
To: $email
Subject: $provider registration code

Here is the code to register at $provider: $code

-- 
This is alpha test software
<https://github.com/pbraun9/nobudget>
Please send issues and feedback to <$support>
EOF

}

function ask_email_code {
        #print
        #print Verification code has been sent by email!
	#print
        print Please enter the $provider registration code that you have received: \\c
        read -r tmp
        tmp2=`echo "$tmp" | sed -r 's/[^[:alnum:]]//g'`
        answer=`echo "$tmp2" | grep -E '^[[:alnum:]]+$'`
        if [[ -z "$tmp" || -z "$tmp2" || -z "$answer" || "$tmp" != "$tmp2" || "$answer" != "$tmp" ]]; then
                showvar tmp
                showvar tmp2
                showvar answer

                print
                print You have entered invalid characters
                print
        	unset tmp tmp2 answer

                ask_email_code
        fi
        unset tmp tmp2

	if [[ $answer != $code ]]; then
		echo That is not the right registration code.  Please try again or start a new SSH session.
		# retry to provide code right away
                ask_email_code
	fi
}

[[ ! -f /usr/local/lib/nobudgetlib.ksh ]] && echo could not find /usr/local/lib/nobudgetlib.ksh && exit 1

. /usr/local/lib/nobudgetlib.ksh

[[ ! -x `whence pwgen` ]] && bomb cannot find pwgen executable

clear

# REGISTRATION FORM
cat <<EOF

	      Welcome to $provider

 You will be asked the following informations to create an account:

	o  Define a username

	o  Your email address

	o  Your SSH public key and comment

	o  Coupon code or payment method

EOF
#	o  Phone number

echo -n Press enter key to continue
read -r
print ''

ask_user
ask_email
ask_pubkey

send_email_code
ask_email_code

echo "Success.  Creating user $user with public key $comment."
showvar user
showvar pubkeytype
showvar pubkey
showvar comment
showvar email

# this is now tested earlier
#[[ -n `grep ^$user: /etc/passwd` ]] && bomb user $user already exists - please try another user name
#[[ -n `getent passwd | grep ^$user:` ]] && bomb echo user $user already exists - please try another user name

[[ -d /home/$user/ ]] && bomb user $user does not exist yet but /home/$user/ already exists

sudo /usr/local/sbin/nobudget-update-nis.ksh $user $email
sudo /usr/local/sbin/nobudget-pubkey.ksh $user $pubkeytype $pubkey $comment

echo -n sending confirmation email...
#cat <<EOF | mail -s "$provider account registered" $email && echo done
cat <<EOF | sendmail -t && echo done
From: $provider <$from>
To: $email
Subject: Welcome to $provider

Your $provider account $user is now registered.

Here is how to access the management interface.

        ssh pmr.angrycow.ru -l $user

-- 
This is alpha test software
<https://github.com/pbraun9/nobudget>
Please send issues and feedback to <$support>
EOF
# Here is how to login and manage your guest systems.

cat <<EOF

You can now login and manage your guest systems as follows.

        ssh pmr.angrycow.ru -l $user

EOF

echo -n Press enter key to exit
read -r

#$HOME/nobudget/verifycode.py $email $code && print done || bomb failed to verify code
#$HOME/nobudget/resendcode.py $email $code && print done || bomb failed to verify code
#$HOME/nobudget/registeruser.py $email \\"$pubkey\\" && print done || bomb failed to create user
#[[ ! -x `whence $HOME/nobudget/registeruser` ]] && bomb $HOME/nobudget/registeruser executable missing

