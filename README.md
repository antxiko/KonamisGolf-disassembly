# Konami's Golf (Konami, RC-723) — a commented disassembly

A commented disassembly of the 16 KB MSX cartridge, reproducible byte for byte.

**[Read the work →](https://antxiko.github.io/KonamisGolf-disassembly/)**
· [En castellano](README.es.md)

    make            # traces, builds the listing, reassembles it and runs the tests
    make verify     # the test that decides: reassembling must give back the ROM
    make sanity     # that not one byte is left unexplained
    make densidad   # how much is commented, routine by routine
    make web        # rebuilds the site

The ROM is **not distributed here**. Put your own dump in the root as
`golf.rom`, 16384 bytes, sha256

    6c539f0a4b46b3f723ded723a3bac036550e58385a6a9be73afb8ceb8c7ecae3

`make comprueba` checks it.

## Where it stands

| | |
|---|---|
| reassembles byte for byte | yes |
| bytes explained | 16,384 of 16,384 (100%) |
| traced code | 8,665 bytes |
| identified data | 7,719 bytes across 127 named ranges |
| commented | 1643 line comments, 35.4% |
| routines below 10% | 0 of 558 |

The annotations live apart from the listing, anchored to the address they
describe, so they survive a re-trace. What the `.notes` holds:

| | |
|---|---|
| named labels | 558 |
| anchored comments | 1625 |
| explained data ranges | 127 |

And the site's pictures are not captures: Python paints them by running the same
decompressors the Z80 runs, and they are checked against openMSX's VRAM across
**385,199 bytes with zero differences**.

## What is here

- `src/golf.asm` — the listing; generated, not hand-written
- `src/golf.notes` — the annotations, anchored to addresses
- `src/golf.entries` — the entry points, each one justified
- `docs/` — the site, in English and Spanish
- `tools/` — the tracer, the listing builder, the data walkers and the
  decompressors that draw the site's images from the ROM

## The work

| | |
|---|---|
| [Getting started](docs/GETTING-STARTED.md) | what you need and what each command does |
| [The game](docs/THE-GAME.md) | nine holes, par 36, and a wind that pushes not harder but more often |
| [The cartridge](docs/THE-CARTRIDGE.md) | the header, the upside-down screen and why it carries no hidden mark |
| [The code](docs/THE-CODE.md) | the script interpreter, the holes and the tile mirror |
| [Findings](docs/FINDINGS.md) | what the binary says |
| [In the emulator](docs/IN-THE-EMULATOR.md) | what can be measured, and how |
| [Open questions](docs/OPEN-QUESTIONS.md) | what is not settled yet |

See `LEGAL-NOTICE.md`.
