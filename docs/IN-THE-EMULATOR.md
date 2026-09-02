# In the emulator

The drawings on this site come from the ROM, not from the emulator. But **looking
at a picture is not enough to believe it**: in this series the VRAM is dumped from
openMSX and compared byte for byte against what the Python builds. If they match,
the format has been read correctly.

For this cartridge **30 screens** were dumped — the title, the menu and the nine
holes — and the comparison covers **385,199 bytes**: patterns and colours of
both screens, the sprite patterns, the hole's plan view, its whole header and
the eight VDP registers. It comes out at **zero differences**. The command
that does it is

    python tools/graficos.py --comprueba golf.rom 0x4000 work/omsx

and the only cell it had to be handed is the wind, which is not in the ROM:
`ld a,r` draws it, so each dump's own values are fed in.

## Loading it

    openmsx -machine Philips_VG_8020 -cart golf.rom

## The measuring scripts

`tools/` holds openMSX TCL scripts meant for checking, not for illustrating: they
dump the 16 KB of VRAM and the VDP registers and exit on their own, with a
real-time watchdog so a broken script cannot leave the emulator hanging.

Two things learned the hard way, in case you write your own: in TCL do not nest
quotes inside a string (use `{VDP regs}`), and **do not set breakpoints that fire
every frame** inside drawing routines — they choke the emulator, which then never
even gets a game started.
