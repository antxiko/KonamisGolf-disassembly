# The music

Everything you hear here comes from running the cartridge's own sound engine (`corre_el_sonido`, 0x7359, and `pide_un_sonido`, 0x72C0, which hands it the channels; the interrupt calls it at 0x4031) on an emulated Z80, frame by frame at 60 per second, just as the game calls it. What the engine writes to the PSG is turned into sound with an AY-3-8910 (`tools/musica.py`). Each MP3 is the whole piece up to where it starts again, plus 8 seconds of the repeat fading out; those that do not repeat end where the engine ends.

## Checked against openMSX

The PSG writes have been compared frame by frame with those of openMSX (C-BIOS MSX1 japonés). In every frame the PSG ends up the same:

- "the game starts" (0x87), whole, 282 frames;
- the end of the game (0x8A), whole, 331 frames.

The timbre is not checked: it is a textbook AY-3-8910, not a recording of the emulator. The probes are `tools/omsx_psg.tcl` and `tools/coteja_psg.py`.

## How a piece is asked for

`pide_un_sonido` takes the number in A and does nothing in exhibition mode (0xE002): the demo is played in silence. Low numbers are effects (1 the ball's whistle, 3 the hit...) and from 0x86 up there is music. Each record takes eleven bytes from 0xE661 and 0xE660 holds the copy of the PSG mixer, which start-up leaves at 0xB8. The tracks marked «in the table» are in the track table but no routine asks for them with an `ld a`.

## The tunes

**The game starts** (0x87)

Asked for by `empieza_la_partida`; lasts 4.7 s.

<audio controls preload="none" src="audio/musica_87.mp3?v=1733aee8"></audio>

**The end of the game** (0x8A)

Asked for by `fin_de_la_partida`; lasts 5.5 s.

<audio controls preload="none" src="audio/musica_8A.mp3?v=8f1a2c64"></audio>

**The hole is finished** (0x86)

Asked for by `hoyo_acabado_espera`; lasts 2.2 s.

<audio controls preload="none" src="audio/musica_86.mp3?v=b16f7056"></audio>

**A track in the table** (0x88)

Asked for by ninguna llamada directa: está en la tabla de pistas; lasts 5.5 s.

<audio controls preload="none" src="audio/musica_88.mp3?v=fb6ec2f1"></audio>

**Another track in the table** (0x89)

Asked for by ninguna llamada directa: está en la tabla de pistas; lasts 5.5 s.

<audio controls preload="none" src="audio/musica_89.mp3?v=cb6854fd"></audio>

**A third track in the table** (0x8B)

Asked for by ninguna llamada directa: está en la tabla de pistas; lasts 5.5 s.

<audio controls preload="none" src="audio/musica_8B.mp3?v=2f82aaa8"></audio>

**A fourth track in the table** (0x8C)

Asked for by ninguna llamada directa: está en la tabla de pistas; lasts 5.5 s.

<audio controls preload="none" src="audio/musica_8C.mp3?v=0d1e5c2e"></audio>
