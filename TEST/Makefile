INCLUDE += -lwebsockets
INCLUDE += -ldill
INCLUDE += -lgc

INCLUDE += $(patsubst %,-I %,$(subst :, ,$(PATSHOMELOCS)))

CC       = gcc
PATSCC   = patscc
PATSCC2  = $(PATSCC) $(INCLUDE)

all: test01.out test02.out

%.out: %.dats
	$(PATSCC) -DATS_MEMALLOC_GCBDW $(INCLUDE) -o $@ $<

clean:
	rm -f *.out
	rm -f *_dats.c

