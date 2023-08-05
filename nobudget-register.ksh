#!/bin/ksh
set -e

# mksh doesn't like (( debug = 0 ))
debug=0

#
# shell-based PoC to register nobudget users
#

provider="Angry Cow"

# assuming postfix creates message-id header (always_add_missing_headers)
from=noreply@angrycow.ru
support=support@angrycow.ru

PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin
# /usr/pkg/bin:/usr/pkg/sbin

function ask_coupon {
        #print " Please enter a coupon code or payment method: \c"
        print " Please enter your coupon code: \c"
        read -r tmp
        tmp2=`echo "$tmp" | sed -r 's/[^[:alnum:]-]//g'`
        answer=`echo "$tmp2" | grep -E '^[[:alnum:]-]+$'`
        if [[ -z "$tmp" || -z "$tmp2" || -z "$answer" || "$tmp" != "$tmp2" || "$answer" != "$tmp" ]]; then
                showvar tmp
                showvar tmp2
                showvar answer

                bomb " You have entered invalid characters"
                #print
                #print " You have entered invalid characters"
                #print
                unset tmp tmp2 answer

                ask_coupon
        fi
        coupon=$answer
        unset tmp tmp2 answer

        thereis=`grep -v ^# /var/tmp/COUPON-CODES.csv | grep ^$coupon,`
        showvar thereis
        [[ -z $thereis ]] && bomb could not find coupon code $coupon

	integer seconds=`date +%s`
        integer validuntil=`echo $thereis | cut -f2 -d,`

        validuntilh=`echo $thereis | cut -f3 -d,`

	echo coupon code $coupon is valid until $validuntilh

        if (( seconds > validuntil )); then
                #echo coupon code $coupon has expired
		#echo
		#ask_coupon
                bomb coupon code $coupon has expired
        fi

        unset thereis validuntil validuntilh seconds
}

function define_user {
	[[ -z $email ]] && bomb function define_user requires \$email

	# TODO check how many @ iterations, if more than one, that's a problem
	# note we've checked that the address exists for now
	user=$email

	# since both useradd and pwd_mkdb cannot handle @
	# we are using alternate user names for now
	#user=`echo $email | sed 's/@/__/'`

	# users incl. "register", can see NIS users without the need of sudo
	#[[ ! -z `getent passwd | grep ^$user:` ]] && echo user $user is already registered && ask_email || true
	#[[ ! -z `getent passwd | grep ^$user:` ]] && bomb user $user is already registered || true
	[[ ! -z `grep ^$user: /etc/passwd` ]] && bomb user $user is already registered || true
}

function ask_email {
	print -n " Please enter your email address: \c"
	read -r tmp
	tmp2=`echo "$tmp" | sed -r 's/[^[:alnum:]_.@-]//g'`
	email=`echo "$tmp2" | grep -E '^[[:alnum:]]+@[[:alnum:]_.-]+\.[[:alpha:]]+$'`
	if [[ -z "$tmp" || -z "$tmp2" || -z "$email" || "$tmp" != "$tmp2" || "$email" != "$tmp" ]]; then
		showvar tmp
		showvar tmp2
		showvar email

		bomb " You have entered invalid characters"
		#print
		#print " You have entered invalid characters"
		#print 
        	unset tmp tmp2 email

		ask_email
	fi
	unset tmp tmp2

        #[[ ! -z `getent passwd | grep :$email:` ]] && echo email $email is already registered && ask_email || true
        #[[ ! -z `getent passwd | grep :$email:` ]] && bomb email $email is already registered || true
        [[ ! -z ` grep ^$email: /etc/passwd` ]] && bomb email $email is already registered || true
	define_user
}

function ask_pubkey {
	print " Please enter your SSH public key (OpenSSH format one-liner):"
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
	unset pubkeyformat

	showvar pubkeytype
	showvar pubkey

	#[[ -z $pubkeytype ]] && echo could not determine \$pubkeytype && ask_pubkey || true
	[[ -z $pubkeytype ]] && bomb could not determine \$pubkeytype || true
	#[[ -z $pubkey ]] && echo could not determine \$pubkey && ask_pubkey || true
	[[ -z $pubkey ]] && bomb could not determine \$pubkey || true
}

function send_email_code {
	#unalias pwgen || true
	code=`pwgen --no-capitalize --no-numerals --secure 5 1 | tr a-z A-Z`

	print sending registration code to $email \(STARTTLS\)... \\c
	#print ... | mail -s "$provider registration code" $email && echo done
	cat <<EOF | /usr/sbin/sendmail -t && echo done
From: $provider <$from>
To: $email
Subject: $provider registration code

Here is your code to confirm your email address and register at $provider: $code

-- 
This is alpha test software
Please send issues and feedback to <$support>
EOF

}

function ask_email_code {
        #print
        #print Verification code has been sent by email!
	#print
        print " Please enter the $provider registration code that you have received: \c"
	# (eventually check SPAM folder)
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
#[[ ! -x `whence sudo` ]] && bomb cannot find sudo executable

clear

# REGISTRATION FORM
cat <<EOF

	      Welcome to $provider

 You will be asked the following information to create an account:

	o  Email address

	o  SSH public key

	o  Coupon code

EOF
# or payment method
#	o  Phone number

echo -n " Press enter key to continue"
read -r
print ''

ask_email
[[ -z $email ]] && bomb \$email not defined
[[ -z $user ]] && bomb \$user not defined
showvar email
showvar user

# TODO check pubkey types...
ask_pubkey
[[ -z $pubkeytype ]] && bomb \$pubkeytype not defined
[[ -z $pubkey ]] && bomb \$pubkey not defined
showvar pubkeytype
showvar pubkey

ask_coupon
[[ -z $coupon ]] && bomb \$coupon not defined
showvar coupon

send_email_code
[[ -z $code ]] && bomb \$code not defined

ask_email_code

echo " Success.  Creating user $user with public key type $pubkeytype"

# this is now tested earlier
#[[ -n `grep ^$user: /etc/passwd` ]] && bomb user $user already exists - please try another user name
#[[ -n `getent passwd | grep ^$user:` ]] && bomb echo user $user already exists - please try another user name

# no need for user homedirs
#[[ -d /home/$user/ ]] && bomb user $user does not exist yet but /home/$user/ already exists

# user comment = coupon code here
/usr/local/sbin/nobudget-update-nis.ksh $email $coupon

# provide ssh comment as username/email
/usr/local/sbin/nobudget-pubkey.ksh $email $pubkeytype $pubkey $email

echo -n sending confirmation email...
#cat <<EOF | mail -s "$provider account registered" $email && echo done
cat <<EOF | /usr/sbin/sendmail -t && echo done
From: $provider <$from>
To: $email
Subject: Welcome to $provider

Your $provider account $user is now registered.

You can reach the management interface as follows.

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

