CC=gcc
CFLAGS=-Wall
LDFLAGS=-lcurses

PREFIX := /usr/local

nobudget:
	$(CC) $(CFLAGS) nobudget.c -o nobudget $(LDFLAGS)

nobudget-debug:
	$(CC) $(CFLAGS) -Wall -Wextra -Og -g nobudget.c -o nobudget $(LDFLAGS)

install:
	install -d $(DESTDIR)$(PREFIX)/bin/
	install -d $(DESTDIR)$(PREFIX)/lib/
	install -d $(DESTDIR)$(PREFIX)/sbin/

	install -m 755 nobudget $(DESTDIR)$(PREFIX)/bin/
	install -m 755 nobudget-display-support.ksh $(DESTDIR)$(PREFIX)/bin/
	install -m 755 nobudget-manage-guests.ksh $(DESTDIR)$(PREFIX)/bin/
	install -m 755 nobudget-new-guest.ksh $(DESTDIR)$(PREFIX)/bin/
	install -m 755 nobudget-pubkey.ksh $(DESTDIR)$(PREFIX)/sbin/
	install -m 755 nobudget-register.ksh $(DESTDIR)$(PREFIX)/bin/
	install -m 755 nobudget-update-nis.ksh $(DESTDIR)$(PREFIX)/sbin/
	install -m 644 nobudgetlib.ksh $(DESTDIR)$(PREFIX)/lib/

clean:
	rm -f nobudget

