#!/usr/bin/env python3
"""La musica del cartucho, ejecutando su motor de sonido (ver motor_musica.py).

Pide el sonido con `pide_un_sonido` (0x72C0, A = numero; no suena en el modo de
exhibicion) y corre `corre_el_sonido` (0x7359), que la interrupcion llama cada
cuadro (0x4031). Tres fichas de 11 bytes desde 0xE661; la copia del registro 7
del PSG, en 0xE660.
Uso:  musica.py registros 0x87 [cuadros] | mp3 0x87 f.mp3 | todas docs/audio
      musica.py barrido 0x80 0xFF | emu
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import motor_musica  # noqa: E402
from motor_musica import P  # noqa: E402

TABLA = "ninguna llamada directa: está en la tabla de pistas"

PIEZAS = [
    P(0x87, "Empieza la partida", "The game starts",
      "`empieza_la_partida`"),
    P(0x8A, "El fin de la partida", "The end of the game",
      "`fin_de_la_partida`"),
    P(0x86, "El hoyo acabado", "The hole is finished",
      "`hoyo_acabado_espera`"),
    P(0x88, "Una pista de la tabla", "A track in the table", TABLA),
    P(0x89, "Otra pista de la tabla", "Another track in the table", TABLA),
    P(0x8B, "Una tercera pista de la tabla", "A third track in the table",
      TABLA),
    P(0x8C, "Una cuarta pista de la tabla", "A fourth track in the table",
      TABLA),
]

PAGINA = motor_musica.pagina_basica(
    "`corre_el_sonido`, 0x7359, y `pide_un_sonido`, 0x72C0, que le reparte "
    "los canales; lo llama la interrupción en 0x4031",
    "`corre_el_sonido`, 0x7359, and `pide_un_sonido`, 0x72C0, which hands it "
    "the channels; the interrupt calls it at 0x4031",
    "C-BIOS MSX1 japonés",
    [("«empieza la partida» (0x87) entera, 282 cuadros",
      "\"the game starts\" (0x87), whole, 282 frames"),
     ("el fin de la partida (0x8A) entero, 331 cuadros",
      "the end of the game (0x8A), whole, 331 frames")],
    [("Cómo se pide una pieza",
      "`pide_un_sonido` recibe el número en A y no hace nada en el modo de "
      "exhibición (0xE002): la demo se juega en silencio. Los números bajos "
      "son efectos (1 el silbido de la bola, 3 el golpe...) y del 0x86 en "
      "adelante hay música. Cada ficha ocupa once bytes desde 0xE661 y "
      "0xE660 guarda la copia del mezclador del PSG, que el arranque deja "
      "en 0xB8. Las pistas «de la tabla» están en la tabla de pistas pero "
      "ninguna rutina las pide con un `ld a`.",
      "How a piece is asked for",
      "`pide_un_sonido` takes the number in A and does nothing in exhibition "
      "mode (0xE002): the demo is played in silence. Low numbers are effects "
      "(1 the ball's whistle, 3 the hit...) and from 0x86 up there is music. "
      "Each record takes eleven bytes from 0xE661 and 0xE660 holds the copy "
      "of the PSG mixer, which start-up leaves at 0xB8. The tracks marked "
      "«in the table» are in the track table but no routine asks for them "
      "with an `ld a`.")])

CFG = dict(rom="golf.rom", org=0x4000, frame=0x7359, pide=0x72C0,
           ram=(0xE660, 0xE684), ram0=[(0xE660, 0xB8)],
           excluye=[0xE66A, 0xE675, 0xE680], hz=60, psg0={7: 0xB8},
           piezas=PIEZAS, pagina=PAGINA,
           cotejado=[(0x87, 282, None), (0x8A, 331, None)])

if __name__ == "__main__":
    sys.exit(motor_musica.main(CFG, sys.argv[1:]))
