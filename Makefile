.PHONY: build clean install rel rel_commit sbm_up srcs uninstall

# Currently not meant to be modified, as the build does not account for it.
PROGNAME = syscfg

DESTDIR =
PREFIX  = /usr/local
BINDIR  = $(PREFIX)/bin
MAN1DIR = $(PREFIX)/share/man/man1

BIN_INSTALL  = $(BINDIR)/$(PROGNAME)
MAN1_INSTALL = $(MAN1DIR)/$(PROGNAME).1

# Note: `install` is not POSIX and the `-D` option is not portable.
INS       = install
BIN_FLAGS = -D -m 755
MAN_FLAGS = -D -m 644

build: ./$(PROGNAME)
./$(PROGNAME): ./src/syscfg.sh
	sh ./scripts/build.sh ./src/syscfg.sh

clean:
	rm -fv ./$(PROGNAME)

# Leverages the timestamp checking capability of `make` to individually decide
# whether to install all or some of the associated program files.
install: $(DESTDIR)$(BIN_INSTALL) \
         $(DESTDIR)$(MAN1_INSTALL)
$(DESTDIR)$(BIN_INSTALL): ./$(PROGNAME)
	$(INS) $(BIN_FLAGS) $< $@
$(DESTDIR)$(MAN1_INSTALL): ./doc/$(PROGNAME).1
	$(INS) $(MAN_FLAGS) $< $@

rel:
	@test -n "$(REL)" || { echo 'REL is empty'; exit 2; }
	@test -n "$(PRE)" || { echo 'PRE is empty'; exit 2; }
	@test -n "$(CUR)" || { echo 'CUR is empty'; exit 2; }
	@test -n "$(NEWS)" || { echo 'NEWS is empty'; exit 2; }
	sh ./scripts/rel.sh "$(REL)" "$(PRE)" "$(CUR)" "$(NEWS)"

rel_commit:
	@test -n "$(NEWS)" || { echo 'NEWS is empty'; exit 2; }
	sh ./scripts/rel_commit.sh "$(NEWS)"

sbm_up:
	@test -n "$(SUB)" || { echo 'SUB is empty'; exit 2; }
	@test -n "$(TAG)" || { echo 'TAG is empty'; exit 2; }
	sh ./scripts/sbm_up.sh "$(SUB)" "$(TAG)"

srcs:
	sh ./scripts/srcs.sh

uninstall:
	rm -fv $(DESTDIR)$(BIN_INSTALL)
	rm -fv $(DESTDIR)$(MAN1_INSTALL)
