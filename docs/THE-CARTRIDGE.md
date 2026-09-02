# The cartridge

Konami's Golf is Konami's **RC-723**, from 1985: 16 KB in page 1, with no bank
switching.

## INIT is not where it usually is

The `AB` header declares only INIT, and puts it at **0x4053**. In the house's
other cartridges of this era INIT sits at 0x4010 — here 0x4010 is something else:
**the interrupt handler**, which INIT hooks into H.KEYI before clearing the RAM
and placing the stack. From then on the main program does nothing and the whole
game runs inside the per-frame interrupt.

## It does not carry Konami's hidden mark

At the end of many of its cartridges Konami hid its catalogue number and the
title in katakana; **Manuel Pazos**
([@ManuelPazosMSX](https://twitter.com/ManuelPazosMSX)) found it, and the block
lives at offset 0x3FF0.

**This one does not have it**, checked by scanning all 16,384 positions of the
ROM rather than just the tail, with a finder first validated against four other
cartridges of the same family that do carry it. The dump shows why: the ROM runs
**full of code right up to 0x7FFD**, with two bytes of filler left over.

## The screen, back to front

SCREEN 2, but with the tables laid out the opposite way round from usual: colours
at 0x0000, patterns at 0x2000, names at 0x3800, and sprites at 0x1800 and
0x3B00. The eight VDP registers come from a table in the ROM itself, at 0x447A.

## How the 16 KB break down

| | bytes | |
|---|---|---|
| traced code | 8,665 | 52.89 % |
| identified data | 7,719 | 47.11 % |
| **unexplained** | **0** | **0.00 %** |
