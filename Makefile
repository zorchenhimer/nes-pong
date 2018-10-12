
CA = c:/cc65/bin/ca65.exe
LD = c:/cc65/bin/ld65.exe

# Mapper configuration for linker
NESCFG = nes_000.cfg

# Name of the main source file
NAME = pong

# any CHR files included
CHR = pong.chr

# List of all the sources files
SOURCES = $(NAME).asm

# misc
RM = rm

.PHONY: clean default

default: all
all: bin/ bin/$(NAME).nes bin/$(NAME).mlb

clean:
	$(RM) bin/*.*

bin/:
	mkdir bin

bin/$(NAME).o: $(SOURCES)
	$(CA) -g \
		-t nes \
		-o bin/$(NAME).o\
		-l bin/$(NAME).lst \
		$(NAME).asm

bin/$(NAME).nes: bin/$(NAME).o $(CHR) $(NESCFG)
	$(LD) -o bin/$(NAME).nes \
		-C $(NESCFG) \
		-m bin/$(NAME).nes.map \
		-Ln bin/$(NAME).labels \
		--dbgfile bin/$(NAME).nes.db \
		bin/$(NAME).o

bin/$(NAME).mlb: bin/$(NAME).nes
	perl.exe ../nes-symbols.pl bin/$(NAME).labels
