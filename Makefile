# ----------------------------------------------------------------------------
# "THE BEER-WARE LICENSE" (Revision 42):
# <xythobuz@xythobuz.de> wrote this file.  As long as you retain this notice
# you can do whatever you want with this stuff. If we meet some day, and you
# think this stuff is worth it, you can buy me a beer in return.   Thomas Buck
# ----------------------------------------------------------------------------

CFLAGS ?= -Wall -pedantic -std=c11

all: bin/protocol bin/foohid

install: all
	cp bin/protocol ~/bin/protocol
	cp bin/foohid ~/bin/foohid

bin/protocol: src/serial.o src/protocol.o
	@mkdir -p bin
	$(CC) -o bin/protocol src/serial.o src/protocol.o

bin/foohid: src/serial.o src/foohid.o
	@mkdir -p bin
	$(CC) -o bin/foohid -framework IOKit src/serial.o src/foohid.o

clean:
	rm -rf bin
	rm -rf src/*.o

