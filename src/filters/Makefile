# ************************************************************************* #
# Organizacion del Computador II                                            #
#                                                                           #
#   Trabajo Practico 2                                                      #
#                                                                           #
# ************************************************************************* #

all: C_blur.o ASM_blur1.o ASM_blur2.o C_merge.o ASM_merge1.o ASM_merge2.o C_hsl.o ASM_hsl1.o ASM_hsl2.o filter_toX.o aux.o

CFLAGS=-Wall -Wextra -pedantic -ggdb -lm -std=c99
NASMFLAGS=-f elf64 -ggdb -F DWARF

%.o: %.c filters.h
	gcc $(CFLAGS) -c -o $@ $<

%.o: %.asm
	nasm $(NASMFLAGS) -o $@ $<

o0: CFLAGS += -O0
o0: all

o3: CFLAGS += -O3
o3: all

o3fast: CFLAGS += -O3 -ffast-math
o3fast: all

o0shift:
	make shifts
	make o0
	make shuffles

o3shift:
	make shifts
	make o3
	make shuffles

o3fastshift:
	make shifts
	make o3fast
	make shuffles

o0shuffles:
	make shuffles
	make o0

o3shuffles:
	make shuffles
	make o3

o3fastshuffles:
	make shuffles
	make o3fast

shuffles:
	cp ASM_hsl2.asm ASM_hsl2_shuffles.asm
	
shifts:
	cp ASM_hsl2.asm ASM_hsl2_shifts.asm

clean:
	rm  -f *.o
