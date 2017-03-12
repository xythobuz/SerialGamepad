# ----------------------------------------------------------------------------
# "THE BEER-WARE LICENSE" (Revision 42):
# <xythobuz@xythobuz.de> wrote this file.  As long as you retain this notice
# you can do whatever you want with this stuff. If we meet some day, and you
# think this stuff is worth it, you can buy me a beer in return.   Thomas Buck
# ----------------------------------------------------------------------------

# C Compiler flags for command line apps
CFLAGS ?= -Wall -pedantic -std=c11

# Targets that don't name any created files
.PHONY: all install distribute clean

# Build all binaries
all: bin/protocol bin/foohid build/Release/SerialGamepad.app
	@rm -rf bin/SerialGamepad.app
	@cp -R build/Release/SerialGamepad.app bin/SerialGamepad.app

# Install locally
install: bin/protocol bin/foohid build/Release/SerialGamepad.app
	cp bin/protocol /usr/local/bin/serial-protocol
	cp bin/foohid /usr/local/bin/foohid
	@rm -rf /Applications/SerialGamepad.app
	cp -r build/Release/SerialGamepad.app /Applications/SerialGamepad.app

# Build GUI project
build/Release/SerialGamepad.app: SerialGamepad SerialGamepad.xcodeproj
	xcodebuild

# Build protocol binary
bin/protocol: src/serial.o src/protocol.o
	@mkdir -p bin
	$(CC) -o bin/protocol src/serial.o src/protocol.o

# Build foohid binary
bin/foohid: src/serial.o src/foohid.o
	@mkdir -p bin
	$(CC) -o bin/foohid -framework IOKit src/serial.o src/foohid.o

# Build distributable installer package
distribute: build/Installer.pkg
	@mkdir -p bin
	@rm -rf bin/SerialGamepad.pkg
	@cp -R build/Installer.pkg bin/SerialGamepad.pkg

# Download foohid binary dependency
build/foohid.pkg:
	@mkdir -p build
	curl -o build/foohid.dmg \
		-L https://github.com/unbit/foohid/releases/download/0.2.1/foohid-0.2.1.dmg
	hdiutil attach build/foohid.dmg
	cp /Volumes/foohid/foohid-0.2.1.pkg build/foohid.pkg
	umount /Volumes/foohid

# Create installer pkg for our App
build/SerialGamepad.pkg: build/Release/SerialGamepad.app
	pkgbuild \
		--root build/Release/SerialGamepad.app \
		--identifier de.xythobuz.SerialGamepad \
		--install-location "/Applications/SerialGamepad.app" \
		build/SerialGamepad.pkg

# Create installer bundling our App and fooHID
build/Installer.pkg: build/SerialGamepad.pkg build/foohid.pkg Resources
	productbuild \
		--distribution Resources/Distribution.xml \
		--package-path build \
		--resources Resources \
		build/Installer.pkg

# Delete intermediate files
clean:
	rm -rf bin
	rm -rf build
	rm -rf src/*.o

