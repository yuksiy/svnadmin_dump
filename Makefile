# System Configuration
srcdir = .

prefix ?= /usr/local
exec_prefix ?= $(prefix)

scriptbindir ?= $(prefix)/bin
datadir ?= $(scriptbindir)

bindir ?= $(exec_prefix)/bin
libdir ?= $(exec_prefix)/lib
sbindir ?= $(exec_prefix)/sbin

sysconfdir ?= $(prefix)/etc
infodir ?= $(prefix)/info
mandir ?= $(prefix)/man
localstatedir ?= $(prefix)/var

CHECK_SCRIPT_SH = /bin/sh -n

INSTALL = /usr/bin/install -p
INSTALL_PROGRAM = $(INSTALL)
INSTALL_SCRIPT = $(INSTALL)
INSTALL_DATA = $(INSTALL) -m 644


# Inference Rules

# Macro Defines
PROJ = svnadmin_dump
VER = 1.0.0

PKG_SORT_KEY ?= 6,6

SUBDIRS-TEST-SCRIPTS-SH = \

SUBDIRS-TEST = \
				$(SUBDIRS-TEST) \

SUBDIRS = \
				$(SUBDIRS-TEST-SCRIPTS-SH) \

PROGRAMS = \

SCRIPTS-SH = \
				svnadmin_dump.sh \

SCRIPTS-OTHER = \

SCRIPTS = \
				$(SCRIPTS-SH) \
				$(SCRIPTS-OTHER) \

DATA = \

# Target List
test-recursive \
:
	@target=`echo $@ | sed s/-recursive//`; \
	list='$(SUBDIRS)'; \
	for subdir in $$list; do \
		echo "Making $$target in $$subdir"; \
		echo " (cd $$subdir && $(MAKE) $$target)"; \
		(cd $$subdir && $(MAKE) $$target); \
	done

all: \
				$(PROGRAMS) \
				$(SCRIPTS) \
				$(DATA) \

# Executables

# Source Objects

# Clean Up Everything
clean:
	rm -f *.$(o) $(PROGRAMS)

# Check
check: check-SCRIPTS-SH

check-SCRIPTS-SH:
	@list='$(SCRIPTS-SH)'; \
	for i in $$list; do \
		echo " $(CHECK_SCRIPT_SH) $$i"; \
		$(CHECK_SCRIPT_SH) $$i; \
	done

# Test
test:
	$(MAKE) test-recursive

# Install
install: install-SCRIPTS install-DATA

install-SCRIPTS:
	@list='$(SCRIPTS)'; \
	if [ ! -d "$(DESTDIR)$(scriptbindir)/" ]; then \
		echo " mkdir -p $(DESTDIR)$(scriptbindir)/"; \
		mkdir -p $(DESTDIR)$(scriptbindir)/; \
	fi;\
	for i in $$list; do \
		echo " $(INSTALL_SCRIPT) $$i $(DESTDIR)$(scriptbindir)/"; \
		$(INSTALL_SCRIPT) $$i $(DESTDIR)$(scriptbindir)/; \
	done

install-DATA:
	@list='$(DATA)'; \
	if [ ! -d "$(DESTDIR)$(datadir)/" ]; then \
		echo " mkdir -p $(DESTDIR)$(datadir)/"; \
		mkdir -p $(DESTDIR)$(datadir)/; \
	fi;\
	for i in $$list; do \
		echo " $(INSTALL_DATA) $$i $(DESTDIR)$(datadir)/"; \
		$(INSTALL_DATA) $$i $(DESTDIR)$(datadir)/; \
	done

# Pkg
pkg:
	@$(MAKE) DESTDIR=$(CURDIR)/$(PROJ)-$(VER).$(ENVTYPE) install; \
	tar cvf ./$(PROJ)-$(VER).$(ENVTYPE).tar ./$(PROJ)-$(VER).$(ENVTYPE) > /dev/null; \
	tar tvf ./$(PROJ)-$(VER).$(ENVTYPE).tar 2>&1 | sort -k $(PKG_SORT_KEY) | tee ./$(PROJ)-$(VER).$(ENVTYPE).tar.list.txt; \
	gzip -f ./$(PROJ)-$(VER).$(ENVTYPE).tar; \
	rm -fr ./$(PROJ)-$(VER).$(ENVTYPE)
