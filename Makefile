.PHONY: build clean install rel rel_commit sbm_up srcs uninstall

# Currently not meant to be modified, as the build does not account for it.
PROGNAME = syscfg

DESTDIR =
PREFIX  = /usr/local
BINDIR  = $(PREFIX)/bin
MAN1DIR = $(PREFIX)/share/man/man1

build: ./$(PROGNAME)
./$(PROGNAME): ./src/syscfg.sh
	sh ./scripts/build.sh ./src/syscfg.sh

clean:
	rm -fv ./$(PROGNAME)

# Note: `install` is not POSIX and the `-D` option is not portable.
#
# Leverages the timestamp checking capability of `make` to individually decide
# whether to install all or some of the associated program files.
install: $(DESTDIR)$(BINDIR)/$(PROGNAME) \
         $(DESTDIR)$(MAN1DIR)/$(PROGNAME).1
$(DESTDIR)$(BINDIR)/$(PROGNAME): ./$(PROGNAME)
	install -Dm755 $< $@
$(DESTDIR)$(MAN1DIR)/$(PROGNAME).1: ./doc/$(PROGNAME).1
	install -Dm644 $< $@

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
	rm -fv $(DESTDIR)$(BINDIR)/$(PROGNAME)
	rm -fv $(DESTDIR)$(MAN1DIR)/$(PROGNAME).1
