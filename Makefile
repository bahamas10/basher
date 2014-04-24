PREFIX ?= /opt/local
PROG    = basher
BIN     = $(PREFIX)/bin/$(PROG)

all:

install:
	cp $(PROG) $(BIN)
	chmod +x $(BIN)

uninstall:
	rm -f $(BIN)

.PHONY: all install uninstall
