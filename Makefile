PROG = syscfg
build: ./$(PROG)

DESTDIR =
PREFIX  = /usr/local
BINDIR  = $(PREFIX)/bin
MAN1DIR = $(PREFIX)/share/man/man1

# A 'FORCE' prerequisite to always run a certain target. Similar to a target
# defined in `.PHONY`.
FORCE:

./$(PROG): ./src/$(PROG).sh
	@sh ./scripts/build.sh "$(PROG)" $^

clean: FORCE
	rm -fv ./$(PROG)

# Note: `install` is not POSIX and the `-D` option is not portable.
#
# Leverages the timestamp checking capability of `make` to individually decide
# whether to install all or some of the associated program files.
install: $(DESTDIR)$(BINDIR)/$(PROG) \
         $(DESTDIR)$(MAN1DIR)/$(PROG).1
$(DESTDIR)$(BINDIR)/$(PROG): ./$(PROG)
	install -Dm755 $< $@
$(DESTDIR)$(MAN1DIR)/$(PROG).1: ./doc/$(PROG).1
	install -Dm644 $< $@

rel: FORCE
	@test -n "$(REL)" || { echo 'REL is empty'; exit 2; }
	@test -n "$(PRE)" || { echo 'PRE is empty'; exit 2; }
	@test -n "$(CUR)" || { echo 'CUR is empty'; exit 2; }
	@test -n "$(NEWS)" || { echo 'NEWS is empty'; exit 2; }
	sh ./scripts/rel.sh "$(REL)" "$(PRE)" "$(CUR)" "$(NEWS)"

rel_commit: FORCE
	@test -n "$(NEWS)" || { echo 'NEWS is empty'; exit 2; }
	sh ./scripts/rel_commit.sh "$(NEWS)"

sbm_up: FORCE
	@test -n "$(SUB)" || { echo 'SUB is empty'; exit 2; }
	@test -n "$(TAG)" || { echo 'TAG is empty'; exit 2; }
	sh ./scripts/sbm_up.sh "$(SUB)" "$(TAG)" "$(ALIAS)"

srcs: FORCE
	sh ./scripts/srcs.sh

uninstall: FORCE
	rm -fv $(DESTDIR)$(BINDIR)/$(PROG)
	rm -fv $(DESTDIR)$(MAN1DIR)/$(PROG).1
