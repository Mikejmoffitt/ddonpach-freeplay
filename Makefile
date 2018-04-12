AS=asl
P2BIN=p2bin
SRC=patch.s
BSPLIT=bsplit
MAME=mame

ASFLAGS=-i . -n -U

.PHONY: prg.bin

all: prg.bin

prg.orig: b1.u27.orig b2.u26.orig
	$(BSPLIT) c b1.u27.orig b2.u26.orig prg.orig

prg.o: prg.orig
	$(AS) $(SRC) $(ASFLAGS) -o prg.o

prg.bin: prg.o
	$(P2BIN) $< $@ -r \$$-0xFFFFF
	$(BSPLIT) s prg.bin b1.u27 b2.u26
	rm prg.o

test: prg.bin
	$(MAME) -debug ddonpach

clean:
	@-rm prg.bin
	@-rm prg.o
	@-rm prg.orig
	@-cp u42.int.orig u42.int
	@-cp u41.int.orig u41.int
