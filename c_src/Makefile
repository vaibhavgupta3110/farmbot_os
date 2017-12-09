
LDFLAGS ?= -ludev
CFLAGS = -O3 -pedantic -Wall
CC ?= $(CROSSCOMPILE)-g++

ifneq ($(OS),Windows_NT)
	CFLAGS += -fPIC

	ifeq ($(shell uname),Darwin)
		LDFLAGS += -dynamiclib -undefined dynamic_lookup
	endif
endif

ifeq ($(ERL_INCLUDE_DIR),)
ERL_ROOT_DIR = $(shell erl -eval "io:format(\"~s~n\", [code:root_dir()])" -s init stop -noshell)
ifeq ($(ERL_ROOT_DIR),)
   $(error Could not find Erlang installation.)
endif
ERL_INCLUDE_DIR = "$(ERL_ROOT_DIR)/usr/include"
endif

ERL_CFLAGS ?= -I$(ERL_INCLUDE_DIR)

CC = g++
CFLAGS = -g -Wall
SRCS = main.cpp
PROG = fb_jpg_stream

OPENCV = `pkg-config opencv --cflags --libs`
LIBS = $(OPENCV)

$(PROG):$(SRCS)
	$(CC) $(CFLAGS) $(ERL_CFLAGS) -o $(PROG) $(SRCS) $(LIBS)
	cp $(PROG) ../priv/$(PROG)

clean:
	rm -rf $(PROG)
	rm -rf priv/$(PROG)
