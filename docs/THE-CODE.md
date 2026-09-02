# The code

## One dead loop, and the whole machine in the interrupt

INIT (0x4053) puts a `0xC3` into H.KEYI with the address **0x4010** behind it,
clears the 0x7FE bytes from 0xE000 to 0xE7FF with an `ldir` and drops the stack
just below. From there the main program does nothing: the entire game runs inside
the per-frame interrupt.

## A routine that reads its own parameter

0x4379 starts with `ex (sp),hl`: it takes the return address — which points at
the byte after the CALL — reads a sixteen-bit word from there, and hands back the
address already advanced so the return lands **past** the parameter. In other
words the parameter sits **right after the CALL, inside the code stream**.

There are thirteen such calls, and all thirteen words point inside the ROM. This
is the detail that loses a naive disassembler: the first parameter is 0x44E9, and
its low byte, an `0xE9`, reads as a `jp (hl)` that does not exist.

## The script interpreter

Almost everything drawn is compressed and dumped by one interpreter
(0x4380 / 0x4389). The format, measured:

- a two-byte header with the destination, **high byte first**
- `0x01 rl` — ONE byte holding two nibbles: the low one is how many bytes the
  block has, the high one how many times it repeats (a 0 counts as 256)
- `0x02..0x7F` — a run: repeat the next byte
- `0x81..0xFF` — literal: copy that many bytes
- `0x80` — change destination
- `0x00` — end

And there is a second door, at 0x601E, that reads **the same format but against
RAM**. That is what lets 0x5FE2 paint a course tile and then the **same tile
mirrored left to right** (0x5FFD), without spending one more byte of ROM.
It is not a transpose, although it looks like one: the `inc hl` at 0x600E sits
outside the bit loop, so the eight rounds of `rl (hl)` keep rotating the same
byte and what comes out is that row with its bits reversed. The finish is that
0x6013 and 0x601B put an `0x88` in front and a `0x00` behind, so the mirrored
row comes out already turned into a VRAM script the same routine can paint.

## The holes

Two tables of nine pointers, at 0x79BC and 0x79CE. The first leads to the hole's
header and the second to its grid, but you do not need both: the header ends in a
`0x80` whose destination is the start of the grid.

Each grid cell is a code drawn as a block four tiles wide by two or four tall,
onto a 20 by 16 canvas in RAM, in five depth bands. Codes 0x01 to 0x28 go through
one set of tables and 0x29 to 0x34 through another; 0xEA is the tee, 0xC4 the
edge, and 0x29 and 0x2A are the green. The terrain type is classified by 0x5BF0
against a set of thresholds, and that is what decides whether your shot comes out
short.

And so the hole can be looked at from four angles, three tables of 48 codes
(0x5471, 0x54A1 and 0x54D1) **rotate the cell codes**, with the game keeping four
grids: one unrotated, two rotated and one reversed.
