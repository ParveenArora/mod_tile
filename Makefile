UNAME := $(shell uname)
OSARCH= $(shell uname -m)

APXS      = $(shell which apxs || which apxs2 || echo "need apxs"; exit 1)
$(if $(wildcard $(APXS)),,$(error "cannot find apxs or apxs2")) 

builddir     = .
top_dir:=$(shell ${APXS} -q exp_installbuilddir)
top_dir:=$(shell /usr/bin/dirname ${top_dir})

top_srcdir   = ${top_dir}
top_builddir = ${top_dir}

include ${top_builddir}/build/special.mk

CXX := g++
CXXFLAGS += -Wall

APACHECTL = $(shell which apachectl || which apache2ctl)
EXTRA_CFLAGS = -I$(builddir)

EXTRA_CPPFLAGS += -g -O2 -Wall

all: local-shared-build renderd speedtest render_list render_old convert_meta render_expired

install: ${DESTDIR}/etc/renderd.conf


${DESTDIR}/etc/renderd.conf:
ifeq ($(UNAME), Darwin)
	cp renderd.conf ${DESTDIR}/etc/renderd.conf
else
	cp -u renderd.conf ${DESTDIR}/etc/renderd.conf
endif


clean:
	rm -f *.o *.lo *.slo *.la .libs/*
	rm -f renderd render_expired render_list speedtest render_old convert_meta
	make -C iniparser3.0b veryclean

RENDER_CPPFLAGS += -g -O2 -Wall
RENDER_CPPFLAGS += -I/usr/local/include/mapnik -I/usr/local/include/
RENDER_CPPFLAGS += $(shell freetype-config --cflags)

RENDER_LDFLAGS += -g
RENDER_LDFLAGS += -lpthread

ifeq ($(OSARCH), x86_64)
RENDER_LDFLAGS += -L/usr/local/lib64
else
RENDER_LDFLAGS += -L/usr/local/lib
endif

RENDER_LDFLAGS += -lmapnik -Liniparser3.0b -liniparser

ifeq ($(UNAME), Darwin)
RENDER_LDFLAGS += -licuuc -lboost_regex
endif

renderd: store.c daemon.c gen_tile.cpp dir_utils.c protocol.h render_config.h dir_utils.h store.h iniparser3.0b/libiniparser.a
	$(CXX) -o $@ $^ $(RENDER_LDFLAGS) $(RENDER_CPPFLAGS)

speedtest: render_config.h protocol.h dir_utils.c dir_utils.h

render_list: render_config.h protocol.h dir_utils.c dir_utils.h render_list.c
	$(CC) $(EXTRA_CPPFLAGS) -o $@ $^ -lpthread

render_expired: render_config.h protocol.h dir_utils.c dir_utils.h render_expired.c
	$(CC) $(EXTRA_CPPFLAGS) -o $@ $^ -lpthread

render_old: render_config.h protocol.h dir_utils.c dir_utils.h render_old.c
	$(CC) $(EXTRA_CPPFLAGS) -o $@ $^ -lpthread

convert_meta: render_config.h protocol.h dir_utils.c dir_utils.h store.c

iniparser: iniparser3.0b/libiniparser.a

iniparser3.0b/libiniparser.a: iniparser3.0b/src/iniparser.c
	make -C iniparser3.0b libiniparser.a

MYSQL_CFLAGS += -g -O2 -Wall
MYSQL_CFLAGS += $(shell mysql_config --cflags)

MYSQL_LDFLAGS += $(shell mysql_config --libs)

mysql2file: mysql2file.c
	$(CC) $(MYSQL_CFLAGS) $(MYSQL_LDFLAGS) -o $@ $^

deb:
	debuild

# Not sure why this is not created automatically
.deps:
	touch .deps
