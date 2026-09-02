# The game

Konami's Golf is a **nine-hole** course, par **36**, **3,512 metres**, in a 16 KB
cartridge. Three modes: one player stroke play, two players stroke play, and two
players match play.

## The course

| Hole | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 |
|---|---|---|---|---|---|---|---|---|---|
| Par | 4 | 4 | 4 | 5 | 3 | 4 | 4 | 4 | 4 |
| Metres | 475 | 360 | 362 | 475 | 168 | 477 | 472 | 244 | 479 |

Those numbers are not typed in by hand: they come from the table at 0x4D3F, nine
four-byte records holding the par and the length in BCD. And the nine holes on
this site are **drawn from the ROM**, not captured.

## Each hole is stored once and read two ways

This is the neatest thing in the cartridge. A hole's data is **a single block**,
and the game walks it twice with two different readers:

- As a **VRAM script** it paints the plan you see on the right, sixteen rows of
  nine tiles.
- As **data**, 0x53B2 unpacks it into a grid of **12 columns by 18 rows** in RAM
  — the one that knows whether you are on the fairway, in a bunker, in the
  rough, on the green or out of bounds.

And the joint between the two readings is a piece of craft: the last byte of the
header is a `0x80` — the interpreter's "change destination" code — and its two
destination bytes are exactly the start of the grid. So **painting from the
first pointer paints the whole hole**.

## The shot

Thirteen clubs, read from their own tiles: **1W 3W 1I 3I 4I 5I 6I 7I 8I 9I PW SW
PT**. The range comes from the table at 0x5152, minus whatever you lose
depending on where you stop the power bar (0x516C, or 0x5177 for the putter). In
a bunker it is halved; in the rough with club 2 or above, 48 is taken off.

The direction comes from **a single 66-byte curve**, read at two points 0x21
apart: sine and cosine off the same table. And there is spin — STRAIGHT, SLICE,
HOOK — which bends the ball on its own.

## The wind is not decoration

It is rolled at the start of each hole with `ld a,r`: a strength from 1 to 8 and
one of four directions, painted on the panel's WIND row.

What it does is not push **harder**, but **more often**. Every nudge is the same
size; what changes is how many frames apart they arrive. 0x6C4C reloads the
0xE03C countdown with **20 if the club is a wood** — the 1W or the 3W, the first
two — and with **10 for anything else**, then subtracts the wind strength from
that. At wind 8, an iron gets a nudge every 2 counted frames and a wood every 12.
On top of that the countdown only advances on one frame in four (`and 3` on the
0xE000 counter), so the real clock is four times slower.

Put another way: **the woods are the clubs that suffer the wind least**, which is
the opposite of what you would expect from a club that sends the ball high and
far.
