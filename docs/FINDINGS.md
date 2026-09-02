# Findings

## One hole, one block, two readers

Each hole's data is stored **exactly once**. As a VRAM script it paints the plan
on the right; as data, 0x53B2 unpacks it into a 12 by 18 grid in RAM — the one
that knows where the fairway is and where the bunker is.

What joins the two readings is the last byte of the header: a `0x80`, which in the
interpreter means "change destination", and whose two destination bytes are
exactly the start of the grid. So **painting from the first pointer paints the
whole hole**, and the two pointer tables the cartridge carries are not both
needed.

## The same script draws a tile and its mirror

The script interpreter has two doors: one writes to VRAM and another (0x601E)
reads **the same format against RAM**. With that, 0x5FE2 paints a course tile and
then the **same tile mirrored left to right** (0x5FFD), without spending one more
byte: every symmetrical piece of the course is stored just once.

The trick is in what 0x5FFD does **not** do. It looks like a transpose, but the
`inc hl` at 0x600E sits **outside** the bit loop: the eight rounds of `rl (hl)`
keep rotating the **same** byte, which by the eighth is back where it started,
while `rra` collects its bits from the other end. Out comes the row with its bits
reversed. The dump shows it: where the script at 0x60D6 puts `F0`, the cartridge
leaves `0F` in VRAM.

And the finish: 0x6013 writes a `0x00` after the mirrored row and 0x601B an
`0x88` in front, which in the interpreter is the «eight literal bytes» order. So
0x5FFD does not hand back some bytes: it hands back **a finished VRAM script**,
which is why the original and its mirror can be painted by the same routine.

## The ROM is stitched together with deliberate overlaps

Almost every table here is indexed from 1, and its entry 0 — the one never used —
is laid **on top of something else**. This is not coincidence or sloppiness: it
is a way of not spending the two bytes.

- 0x79BA falls on the golfer's last frame
- 0x5B1B, on a `ld a,(hl)`
- 0x5BDC, on a `jr`
- 0x5470, on a `ret` — which is also the base of a rotation table
- 0x7538, on the last two note periods
- 0x4D3B, on the tail of a script

## Copying the screen's three thirds with a single copy

0x4322 replicates the VRAM contents across SCREEN 2's three thirds, and it does it
with **one overlapping `ldir`**: it copies 4,096 bytes from 0x0000 to 0x0800.
Because the destination runs 0x800 ahead of the source, once the copy passes the
first block it is reading **what it has just written itself**. One `ldir` instead
of two.

## The ball's height is not stored: it is the gap between its two sprites

The ball is **two overlapping sprites**, one black and one white. The black one
stays stuck to the ground and the white one rises with the parabola, so **the gap
between them *is* the height**. There is no height variable anywhere: there are
two coordinates, and the height is their difference.

And that same difference gives the size it is drawn at. 0x7074 does
`ld a,(0xE0B0) / sub d` — the lower layer's *y* minus the upper one's — and
compares it against **0x21, 0x0F and 0x06**: four ball sizes, from the fattest to
the smallest. The higher it flies, the smaller it looks. On landing, 0x701B
brings the two layers back together and the height is zero again.

## A single curve for both sine and cosine

The shot's direction does not use two tables: it uses **one 66-byte curve** at
0x52BF, read at two points 0x21 apart. Cosine and sine are the same table, offset.
