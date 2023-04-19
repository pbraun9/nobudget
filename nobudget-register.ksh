#!/bin/ksh
set -e

debug=0

#
# shell-based PoC to register nobudget users
#

provider="Angry Cow"
from=noreply@angrycow.ru
support=support@angrycow.ru
# assuming postfix creates message-id header (always_add_missing_headers)

PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:/usr/pkg/bin:/usr/pkg/sbin

function ask_coupon_code {
        print " Please enter the coupon code or payment method: \c"
        read -r tmp
        tmp2=`echo "$tmp" | sed -r 's/[^[:alnum:]-]//g'`
        answer=`echo "$tmp2" | grep -E '^[[:alnum:]-]+$'`
        if [[ -z "$tmp" || -z "$tmp2" || -z "$answer" || "$tmp" != "$tmp2" || "$answer" != "$tmp" ]]; then
                showvar tmp
                showvar tmp2
                showvar answer

                print
                print " You have entered invalid characters"
                print
                unset tmp tmp2 answer

                ask_coupon_code
        fi
        coupon=$answer
        unset tmp tmp2 answer

        # can have comments but no need to grep them out
        thereis=`grep ^$coupon, /home/COUPON-CODES.csv`
        showvar thereis
        [[ -z $thereis ]] && echo could not find coupon code $coupon && ask_coupon_code

	integer seconds=`date +%s`
        integer validuntil=`echo $thereis | cut -f2 -d,`

        validuntilh=`echo $thereis | cut -f3 -d,`

	echo coupon code $coupon is valid until $validuntilh \($validuntil\)

        if (( seconds > validuntil )); then
                bomb coupon code $coupon has expired
        fi

	#showvar coupon
	#echo -n recording coupon code...
	#echo -n `date`, >> /home/$user/coupon-code.csv
	#echo $coupon >> /home/$user/coupon-code.csv && echo done

        unset thereis validuntil validuntilh seconds
}

function ask_user {
	print -n " Please enter desired username: \c"
	read -r tmp
	tmp2=`echo "$tmp" | sed -r 's/[^[:alnum:]_.@-]//g'`
	user=`echo "$tmp2" | grep -E '^[[:alnum:]]+$'`
	if [[ -z "$tmp" || -z "$tmp2" || -z "$user" || "$tmp" != "$tmp2" || "$user" != "$tmp" ]]; then
		showvar tmp
		showvar tmp2
		showvar user

		print
		print " You have entered invalid characters"
		print 
        	unset tmp tmp2 user

		ask_user
	fi
	unset tmp tmp2

	# users, here "register", can see NIS users without the need of sudo
	[[ ! -z `getent passwd | grep ^$user:` ]] && echo user $user already exists - please try another user name && ask_user || true
}

function ask_email {
	print -n " Please enter your email: \c"
	read -r tmp
	tmp2=`echo "$tmp" | sed -r 's/[^[:alnum:]_.@-]//g'`
	email=`echo "$tmp2" | grep -E '^[[:alnum:]]+@[[:alnum:]_.-]+\.[[:alpha:]]+$'`
	if [[ -z "$tmp" || -z "$tmp2" || -z "$email" || "$tmp" != "$tmp2" || "$email" != "$tmp" ]]; then
		showvar tmp
		showvar tmp2
		showvar email

		print
		print " You have entered invalid characters"
		print 
        	unset tmp tmp2 email

		ask_email
	fi
	unset tmp tmp2

        [[ ! -z `getent passwd | grep :$email:` ]] && echo email $email is already registered as another account && ask_email || true
}

function ask_pubkey {
	print " Please enter your SSH public key (one-line OpenSSH format):"
	read -r tmp
	tmp2=`echo "$tmp" | sed -r 's/[^[:alnum:] _+./@-]//g'`
        pubkeyformat=`echo "$tmp2" | grep -E '^[[:alnum:] _+./@-]+$'`

        if [[ -z "$tmp" || -z "$tmp2" || -z "$pubkeyformat" || "$tmp" != "$tmp2" || "$pubkeyformat" != "$tmp" ]]; then
                showvar tmp
                showvar tmp2
                showvar pubkeyformat

                print
                print " You have entered invalid characters"
                print
        	unset tmp tmp2 pubkeyformat

                ask_pubkey
        fi
        unset tmp tmp2

	showvar pubkeyformat
	pubkeytype=`echo $pubkeyformat | awk '{print $1}'`
	pubkey=`echo $pubkeyformat | awk '{print $2}'`
	comment=`echo $pubkeyformat | awk '{print $3}'`
	unset pubkeyformat

	showvar pubkeytype
	showvar pubkey
	showvar comment

	[[ -z $pubkeytype ]] && echo could not determine \$pubkeytype && ask_pubkey || true
	[[ -z $pubkey ]] && echo could not determine \$pubkey && ask_pubkey || true
	[[ -z $comment ]] && echo could not determine \$comment && ask_pubkey || true
}

function send_email_code {
	unalias pwgen || true
	code=`pwgen --no-capitalize --no-numerals --secure 5 1 | tr a-z A-Z`

	print sending registration code to $email \(STARTTLS\)... \\c
	#print Here is the code to register at $provider: $code | mail -s "$provider registration code" $email && echo done
	cat <<EOF | /usr/sbin/sendmail -t && echo done
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
        print " Please enter the $provider registration code that you have received (eventually check SPAM folder): \c"
        read -r tmp
        tmp2=`echo "$tmp" | sed -r 's/[^[:alnum:]]//g'`
        answer=`echo "$tmp2" | grep -E '^[[:alnum:]]+$'`
        if [[ -z "$tmp" || -z "$tmp2" || -z "$answer" || "$tmp" != "$tmp2" || "$answer" != "$tmp" ]]; then
                showvar tmp
                showvar tmp2
                showvar answer

                print
                print " You have entered invalid characters"
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

echo -n " Press enter key to continue"
read -r
print ''

ask_user
ask_email
ask_pubkey
ask_coupon_code

send_email_code
ask_email_code

echo " Success.  Creating user $user with public key $comment."
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
cat <<EOF | /usr/sbin/sendmail -t && echo done
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

echo -n " Press enter key to exit"
read -r

