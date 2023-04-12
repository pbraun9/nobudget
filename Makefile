CC=gcc
CFLAGS=-Wall
LDFLAGS=-lcurses

ifeq ($(PREFIX),)
    PREFIX := /usr/local
endif

nobudget:
	$(CC) $(CFLAGS) nobudget.c -o nobudget $(LDFLAGS)

nobudget-debug:
	$(CC) $(CFLAGS) -Wall -Wextra -Og -g nobudget.c -o nobudget $(LDFLAGS)

install:
	install -d $(DESTDIR)$(PREFIX)/bin/
	install -d $(DESTDIR)$(PREFIX)/lib/
	install -d $(DESTDIR)$(PREFIX)/sbin/

	install -m 755 display-support.bash $(DESTDIR)$(PREFIX)/bin/
	install -m 755 manage-guests.bash $(DESTDIR)$(PREFIX)/bin/
	install -m 755 new-guest.bash $(DESTDIR)$(PREFIX)/bin/
	install -m 755 nobudget $(DESTDIR)$(PREFIX)/bin/
	install -m 755 nobudget-register.ksh $(DESTDIR)$(PREFIX)/bin/

	install -m 644 nobudgetlib.ksh $(DESTDIR)$(PREFIX)/lib/

	install -m 755 nobudget-update-nis $(DESTDIR)$(PREFIX)/sbin/
	install -m 755 nobudget-pubkey $(DESTDIR)$(PREFIX)/sbin/

clean:
	rm -f nobudget

