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
	install -m 755 nobudget $(DESTDIR)$(PREFIX)/bin/
	install -m 755 new-guest.bash $(DESTDIR)$(PREFIX)/bin/
	install -m 755 manage-guests.bash $(DESTDIR)$(PREFIX)/bin/
	install -m 755 display-support.bash $(DESTDIR)$(PREFIX)/bin/
	install -d $(DESTDIR)$(PREFIX)/lib/
	install -m 644 nobudgetlib.bash $(DESTDIR)$(PREFIX)/lib/
	@#install -m 644 support.txt $(DESTDIR)$(PREFIX)/lib/

clean:
	rm -f nobudget

