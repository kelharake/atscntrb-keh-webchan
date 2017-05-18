INCLUDE += -lwebsockets
INCLUDE += -ldill
INCLUDE += -lgc
INCLUDE += -pthread -lpthread -luuid

INCLUDE += $(patsubst %,-I %,$(subst :, ,$(PATSHOMELOCS)))

CC       = gcc
PATSCC   = patscc
PATSCC2  = $(PATSCC) $(INCLUDE)

all: test-chatroom0.out test-echoserver0.out

%.out: %.dats
	$(PATSCC) -DATS_MEMALLOC_LIBC $(INCLUDE) -o $@ $<

clean:
	rm -f *.out
	rm -f *_dats.c

