# pgmp -- pgxs-based makefile
#
# Copyright (C) 2011 Daniele Varrazzo
#
# This file is part of the PostgreSQL GMP Module
#
# The PostgreSQL GMP Module is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public License as
# published by the Free Software Foundation; either version 3 of the License,
# or (at your option) any later version.
#
# The PostgreSQL GMP Module is distributed in the hope that it will be
# useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Lesser
# General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public License
# along with the PostgreSQL GMP Module.  If not, see
# http://www.gnu.org/licenses/.

.PHONY: docs

# You may have to customize this to run the test suite
# REGRESS_OPTS=--user postgres

PG_CONFIG=pg_config

SHLIB_LINK=-lgmp -lm

EXTENSION = pgmp
MODULEDIR = $(EXTENSION)
MODULE_big = $(EXTENSION)

EXT_LONGVER = $(shell grep '"version":' META.json | head -1 | sed -e 's/\s*"version":\s*"\(.*\)",/\1/')
EXT_SHORTVER = $(shell grep 'default_version' $(EXTENSION).control | head -1 | sed -e "s/default_version\s*=\s'\(.*\)'/\1/")
PG91 = $(shell $(PG_CONFIG) --version | grep -qE " 8\.| 9\.0" && echo pre91 || echo 91)

SRC_C = $(wildcard src/*.c)
SRC_H = $(wildcard src/*.h)
SRCFILES = $(SRC_C) $(SRC_H)
OBJS = $(patsubst %.c,%.o,$(SRC_C))
TESTFILES = $(wildcard test/sql/*.sql) $(wildcard test/expected/*.out)
DOCS = $(wildcard docs/*.rst) docs/conf.py docs/Makefile docs/_static/pgmp.css

PKGFILES = AUTHORS COPYING README.rst Makefile \
	META.json pgmp.control \
	sql/pgmp.pysql sql/uninstall_pgmp.sql \
	$(SRCFILES) $(DOCS) $(TESTFILES) \
	$(wildcard tools/*.py)

ifeq ($(PG91),91)
INSTALLSCRIPT=sql/pgmp--$(EXT_SHORTVER).sql
UPGRADESCRIPT=sql/pgmp--unpackaged--$(EXT_SHORTVER).sql
DATA = $(INSTALLSCRIPT) $(UPGRADESCRIPT)
else
INSTALLSCRIPT=sql/pgmp.sql
DATA = $(INSTALLSCRIPT) sql/uninstall_pgmp.sql
endif

# the += doesn't work if the user specified his own REGRESS_OPTS
REGRESS = --inputdir=test setup-$(PG91) mpz mpq
EXTRA_CLEAN = $(INSTALLSCRIPT) $(UPGRADESCRIPT)

PKGNAME = pgmp-$(EXT_LONGVER)
SRCPKG = $(SRCPKG_TGZ) $(SRCPKG_ZIP)
SRCPKG_TGZ = dist/$(PKGNAME).tar.gz
SRCPKG_ZIP = dist/$(PKGNAME).zip

USE_PGXS=1
PGXS := $(shell $(PG_CONFIG) --pgxs)
include $(PGXS)

# added to the targets defined in pgxs
all: $(INSTALLSCRIPT) $(UPGRADESCRIPT)

$(INSTALLSCRIPT): sql/pgmp.pysql
	tools/unmix.py < $< > $@

$(UPGRADESCRIPT): $(INSTALLSCRIPT)
	tools/sql2extension.py --extname pgmp $< > $@

docs:
	$(MAKE) -C docs

sdist: $(SRCPKG)

$(SRCPKG): $(PKGFILES)
	ln -sf . $(PKGNAME)
	mkdir -p dist
	rm -f $(SRCPKG_TGZ)
	tar czvf $(SRCPKG_TGZ) $(addprefix $(PKGNAME)/,$^)
	rm -f $(SRCPKG_ZIP)
	zip -r $(SRCPKG_ZIP) $(addprefix $(PKGNAME)/,$^)
	rm $(PKGNAME)

# Required for testing in pgxn client on PG < 9.1
installcheck: $(INSTALLSCRIPT)

