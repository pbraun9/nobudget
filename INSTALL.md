# nobudget install

_tested on sabotage linux (netbsd curses)_

Requirements

	butch install mksh && ln -s mksh /bin/ksh
	butch install pwgen
	butch install sed

Build and install nobudget onto the system.

	butch install git
	butch install less
        git clone https://github.com/pbraun9/nobudget.git
        cd nobudget/
	make
        make install

Setup

        cp nobudget.conf /etc/
        vi /etc/nobudget.conf

Operations

        tail -F /var/tmp/nobudget.register.error.log
	ls -lF /var/tmp/nobudget.*.log

