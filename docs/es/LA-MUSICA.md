# La música

Todo lo que suena aquí sale de ejecutar el motor de sonido del cartucho (`corre_el_sonido`, 0x7359, y `pide_un_sonido`, 0x72C0, que le reparte los canales; lo llama la interrupción en 0x4031) en un Z80 emulado, cuadro a cuadro y a 60 por segundo, igual que lo llama el juego. Lo que el motor escribe en el PSG pasa a sonido con un AY-3-8910 (`tools/musica.py`). Cada MP3 es la pieza entera hasta donde vuelve a empezar, más 8 segundos de la vuelta apagándose; las que no se repiten acaban donde acaba el motor.

## Cotejado con openMSX

Las escrituras al PSG se han comparado cuadro a cuadro con las de openMSX (C-BIOS MSX1 japonés). En todos los cuadros el PSG queda igual:

- «empieza la partida» (0x87) entera, 282 cuadros;
- el fin de la partida (0x8A) entero, 331 cuadros.

El timbre no está cotejado: es el de un AY-3-8910 de manual, no una grabación del emulador. Las sondas están en `tools/omsx_psg.tcl` y `tools/coteja_psg.py`.

## Cómo se pide una pieza

`pide_un_sonido` recibe el número en A y no hace nada en el modo de exhibición (0xE002): la demo se juega en silencio. Los números bajos son efectos (1 el silbido de la bola, 3 el golpe...) y del 0x86 en adelante hay música. Cada ficha ocupa once bytes desde 0xE661 y 0xE660 guarda la copia del mezclador del PSG, que el arranque deja en 0xB8. Las pistas «de la tabla» están en la tabla de pistas pero ninguna rutina las pide con un `ld a`.

## Las músicas

**Empieza la partida** (0x87)

Lo pide `empieza_la_partida`; dura 4,7 s.

<audio controls preload="none" src="../audio/musica_87.mp3?v=1733aee8"></audio>

**El fin de la partida** (0x8A)

Lo pide `fin_de_la_partida`; dura 5,5 s.

<audio controls preload="none" src="../audio/musica_8A.mp3?v=8f1a2c64"></audio>

**El hoyo acabado** (0x86)

Lo pide `hoyo_acabado_espera`; dura 2,2 s.

<audio controls preload="none" src="../audio/musica_86.mp3?v=b16f7056"></audio>

**Una pista de la tabla** (0x88)

Lo pide ninguna llamada directa: está en la tabla de pistas; dura 5,5 s.

<audio controls preload="none" src="../audio/musica_88.mp3?v=fb6ec2f1"></audio>

**Otra pista de la tabla** (0x89)

Lo pide ninguna llamada directa: está en la tabla de pistas; dura 5,5 s.

<audio controls preload="none" src="../audio/musica_89.mp3?v=cb6854fd"></audio>

**Una tercera pista de la tabla** (0x8B)

Lo pide ninguna llamada directa: está en la tabla de pistas; dura 5,5 s.

<audio controls preload="none" src="../audio/musica_8B.mp3?v=2f82aaa8"></audio>

**Una cuarta pista de la tabla** (0x8C)

Lo pide ninguna llamada directa: está en la tabla de pistas; dura 5,5 s.

<audio controls preload="none" src="../audio/musica_8C.mp3?v=0d1e5c2e"></audio>
