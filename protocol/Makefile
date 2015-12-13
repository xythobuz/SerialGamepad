# Copyright 2015 Thomas Buck <xythobuz@xythobuz.de>

all: proto

proto: serial.o main.o
	$(CC) -o proto serial.o main.o

clean:
	rm -rf proto main.o serial.o

