#   Copyright (C) 2008 Rocky Bernstein rocky@gnu.org
#
#   kshdb is free software; you can redistribute it and/or modify it under
#   the terms of the GNU General Public License as published by the Free
#   Software Foundation; either version 2, or (at your option) any later
#   version.
#
#   kshdb is distributed in the hope that it will be useful, but WITHOUT ANY
#   WARRANTY; without even the implied warranty of MERCHANTABILITY or
#   FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
#   for more details.
#   
#   You should have received a copy of the GNU General Public License along
#   with kshdb; see the file COPYING.  If not, write to the Free Software
#   Foundation, 59 Temple Place, Suite 330, Boston, MA 02111 USA.

AUTOMAKE_OPTIONS = dist-bzip2

if INSTALL_EMACS_LISP
emacs = emacs
else
emacs =
endif
SUBDIRS = command doc $(emacs) lib test

pkgdata_DATA =       \
	dbg-pre.sh   \
	dbg-io.sh    \
	dbg-main.sh  \
	dbg-opts.sh  \
	dbg-trace.sh \
	getopts_long.sh

# Set up the install target 
bin_SCRIPTS = kshdb

EXTRA_DIST = $(pkgdata_DATA) THANKS

MAINTAINERCLEANFILES = ChangeLog

test: check

# Unit testing
check-unit: test-unit

test-unit:
	cd test/unit && make check

test-integration:
	cd test/integration && make check

phony = check test-unit check-unit

if MAINTAINER_MODE

CL = ChangeLog
ChangeLog:
	git log --pretty --numstat --summary | $(GIT2CL) > $@

ACLOCAL_AMFLAGS=-I .

endif

.PHONY: $(CL) test
