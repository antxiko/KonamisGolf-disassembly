# Open questions

What is not settled, said plainly. None of this has been filled in by guessing.

## A possible bug that has not been checked

At 0x57EC there are four bytes — 0x28, 0x50, 0xA0 and 0xF0 — which are the
boundaries between the canvas's five depth bands. 0x55B6 indexes them with the
band number minus one; but the band goes as high as **5**, so index 4 **runs off
the end of the table** and reads the 0x3A that is already the instruction at
0x57F0.

It may be harmless — 0xE4C0 + 0x3A still lands inside the canvas — or it may be a
bug in the cartridge. **It has not been checked in the emulator**, so it stays
here as what it is: a measured suspicion, not a finding.

## Two sprites to the same slot, on the green

When both players are on the green and the balls land within three pixels of each
other, 0x551F does this:

    push de              ; DE arrives holding 0xE1C0, the tee marker
    ld de,07b30h         ; sprite 12's attribute
    call vuelca_cuatro_bytes   ; 0xE0B0, the ball -> sprite 12
    pop hl
    call vuelca_cuatro_bytes   ; 0xE1C0, the marker -> sprite 12 AGAIN

`vuelca_cuatro_bytes` **does not touch DE**: it only advances HL. So the second
call reopens VRAM at 0x3B30 and **writes over what the first one just put there**.
The ball is lost under the marker, and the first transfer is wasted work. One
more `inc de` — or a 0x3B34 — and they would be two different sprites.

It may be an oversight in the cartridge, or it may not matter on screen, since
the two attributes are within three pixels and whichever sprite survives covers
the other anyway. **It has not been checked in the emulator**: it stays here as
what it is, a measured suspicion about the code.

## Code nobody jumps to

The six bytes at 0x6E70 are valid code — `ld a,c / neg / ld c,a / jr` — twins of
the ones at 0x6E6A that do the same to B. The three `jr`s around them all point
past. No path has been found that reaches them.

## The perspective view is not drawn

The gameplay screen is missing from the pictures on this site: the view of the
hole from behind the ball. The pieces are there — the 20 by 16 canvas at 0xE4C0,
the 54 cell codes and the blocks they are stacked from at five distances, all
drawn in `bloques.png`. What is missing is the chain that puts the ball on the
tee — 0x4850, then `donde_esta_la_bola` (0x5A2A) and `elige_la_rejilla` (0x5AA5)
with the strip at 0x5B1D — to know **which of the four grids is being looked at
and from which cell**. We stopped rather than invent it.

## What each course tile draws, by name

All 256 tiles and the 54 cell codes **are now drawn** from the ROM, and can be
looked at in `tiles.png` and `bloques.png`. What is still undone is smaller:
naming each one — which is the tree, which the bunker's edge — across the
`tiles_girables_1..6` and `colores_del_campo_1..10` stretches of the listing.
They are placed and they decode cleanly; what they lack is a label of their
own.
