CC = gcc
CFLAGS = -Wall -Wextra -O2

all: khulna

khulna: khulna.tab.c lex.yy.c main.c
	$(CC) $(CFLAGS) -o khulna khulna.tab.c lex.yy.c main.c

khulna.tab.c khulna.tab.h: khulna.y
	bison -d khulna.y

lex.yy.c: khulna.l khulna.tab.h
	flex khulna.l

clean:
	rm -f khulna lex.yy.c khulna.tab.c khulna.tab.h

.PHONY: all clean


