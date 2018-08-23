CC=gcc
CFLAGS=-Wall
LDFLAGS=-lcurses

nobudget:
	$(CC) $(CFLAGS) nobudget.c -o nobudget $(LDFLAGS)

clean:
	rm -f nobudget

