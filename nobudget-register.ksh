#!/bin/ksh
set -e

#
# shell-based PoC to register nobudget users
#

debug=0

provider=Angrycow
support=support@angrycow.ru

source /usr/local/lib/nobudgetlib.ksh

function ask_user {
	print -n Please enter desired username: \\c
	read -r tmp
	tmp2=`echo "$tmp" | sed -r 's/[^[:alnum:]_.@-]//g'`
	user=`echo "$tmp2" | grep -E '^[[:alnum:]]+$'`
	if [[ -z "$tmp" || -z "$tmp2" || -z "$user" || "$tmp" != "$tmp2" || "$user" != "$tmp" ]]; then
		debugvar tmp
		debugvar tmp2
		debugvar user

		print
		print You have entered invalid characters
		print 
        	unset tmp tmp2 user

		ask_user
	fi
	unset tmp tmp2

	tmp=`getent passwd | grep ^$user:`
	if [[ -n $tmp ]]; then
		echo user $user already exists - please try another user name
		unset tmp
		ask_user
	fi
	unset tmp
}

function ask_email {
	print -n Please enter your email: \\c
	read -r tmp
	tmp2=`echo "$tmp" | sed -r 's/[^[:alnum:]_.@-]//g'`
	email=`echo "$tmp2" | grep -E '^[[:alnum:]]+@[[:alnum:]_.-]+\.[[:alpha:]]+$'`
	if [[ -z "$tmp" || -z "$tmp2" || -z "$email" || "$tmp" != "$tmp2" || "$email" != "$tmp" ]]; then
		debugvar tmp
		debugvar tmp2
		debugvar email

		print
		print You have entered invalid characters
		print 
        	unset tmp tmp2 email

		ask_email
	fi
	unset tmp tmp2

	# TODO help the user to recover exitinng account instead
        tmp=`getent passwd | grep :$email:`
        if [[ -n $tmp ]]; then
                echo email $email is already registered
                unset tmp
                ask_email
        fi
        unset tmp
}

function ask_pubkey {
	print Please enter your SSH public key and comment \(one line\):
	read -r tmp
	tmp2=`echo "$tmp" | sed -r 's/[^[:alnum:] _./@-]//g'`
        pubkey=`echo "$tmp2" | grep -E '^[[:alnum:] _./@-]+$'`
        if [[ -z "$tmp" || -z "$tmp2" || -z "$pubkey" || "$tmp" != "$tmp2" || "$pubkey" != "$tmp" ]]; then
                debugvar tmp
                debugvar tmp2
                debugvar pubkey

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
	print Here is the code to register at $provider: $code | mail -s "$provider registration code" $email && echo done
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
                debugvar tmp
                debugvar tmp2
                debugvar answer

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

clear

[[ ! -x `whence pwgen` ]] && bomb cannot find pwgen executable

# REGISTRATION FORM
cat <<EOF

	      Welcome to $provider
	         (alpha test)

 You will be asked the following informations to register:

	o  New username

	o  Your email address

	o  Your SSH public key and comment

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
debugvar user
debugvar pubkeytype
debugvar pubkey
debugvar comment
debugvar email

# this is now tested earlier
#[[ -n `grep ^$user: /etc/passwd` ]] && bomb user $user already exists - please try another user name
#[[ -n `getent passwd | grep ^$user:` ]] && bomb echo user $user already exists - please try another user name

mkdir -p /data/users/
[[ -d /data/users/$user/ ]] && bomb user $user does not exist yet but its homedir already exists

# determine who's the current nis master
echo -n searching for NIS master server...
ypmaster=`ypwhich` && echo done

# use internal network SSH service
ssh $ypmaster -l register-helper -p 64999 "sudo nobudget-update-nis $user $email"

#echo creating budget user $user ...
sudo nobudget-pubkey $user $pubkeytype $pubkey $comment

echo -n sending confirmation email...
cat <<EOF | mail -s "$provider account registered" $email && echo done

 Welcome to $provider, your account $user is registered.

 You can now login to your $provider account and manage guest systems as follows.

        ssh pmr.angrycow.ru -l $user

-- 
This is alpha test - please send issues and feedback to <$support>
EOF

cat <<EOF

 You can now login to your $provider account and manage guest systems as follows.

        ssh pmr.angrycow.ru -l $user

EOF

echo -n Press enter key to exit
read -r

#$HOME/nobudget/verifycode.py $email $code && print done || bomb failed to verify code
#$HOME/nobudget/resendcode.py $email $code && print done || bomb failed to verify code
#$HOME/nobudget/registeruser.py $email \\"$pubkey\\" && print done || bomb failed to create user
#[[ ! -x `whence $HOME/nobudget/registeruser` ]] && bomb $HOME/nobudget/registeruser executable missing

