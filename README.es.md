# Konami's Golf (Konami, RC-723) — desensamblado comentado

Un desensamblado comentado del cartucho de 16 KB para MSX, reproducible byte a
byte.

**[Leer el trabajo →](https://antxiko.github.io/KonamisGolf-disassembly/es/)**
· [In English](README.md)

    make            # traza, genera el listado, lo reensambla y pasa los tests
    make verify     # la prueba que decide: reensamblar tiene que devolver la ROM
    make sanity     # que ni un byte quede sin explicar
    make densidad   # cuánto está comentado, rutina a rutina
    make web        # rehace la web

La ROM **no se distribuye aquí**. Va en la raíz como `golf.rom`, 16384 bytes,
sha256

    6c539f0a4b46b3f723ded723a3bac036550e58385a6a9be73afb8ceb8c7ecae3

`make comprueba` lo verifica.

## Cómo está

| | |
|---|---|
| reensambla byte a byte | sí |
| bytes explicados | 16.384 de 16.384 (100 %) |
| código trazado | 8.665 bytes |
| datos identificados | 7.719 bytes en 127 rangos con nombre |
| comentado | 1643 comentarios de línea, 35,4 % |
| rutinas por debajo del 10 % | 0 de 558 |

Las anotaciones viven aparte del listado, ancladas a la dirección que describen,
así que sobreviven a un retrazado. Lo que guarda el `.notes`:

| | |
|---|---|
| etiquetas con nombre | 558 |
| comentarios anclados | 1625 |
| rangos de datos con explicación | 127 |

Y los dibujos de la web no son capturas: los pinta Python ejecutando los mismos
descompresores que corre el Z80, y están comprobados contra la VRAM de openMSX
en **385.199 bytes con cero diferencias**.

## Qué hay aquí

- `src/golf.asm` — el listado; generado, no escrito a mano
- `src/golf.notes` — las anotaciones, ancladas a direcciones
- `src/golf.entries` — los puntos de entrada, cada uno justificado
- `docs/` — la web, en castellano y en inglés
- `tools/` — el trazador, el generador del listado, los recorredores de datos y
  los descompresores que dibujan las imágenes de la web desde la ROM

## El trabajo

| | |
|---|---|
| [Empezar](docs/es/EMPEZAR.md) | qué hace falta y qué hace cada orden |
| [El juego](docs/es/EL-JUEGO.md) | nueve hoyos, par 36, y un viento que no empuja más fuerte sino más a menudo |
| [El cartucho](docs/es/EL-CARTUCHO.md) | la cabecera, la pantalla del revés y por qué no lleva marca oculta |
| [El código](docs/es/EL-CODIGO.md) | el intérprete de guiones, los hoyos y el espejo de tiles |
| [Hallazgos](docs/es/HALLAZGOS.md) | lo que dice el binario |
| [En el emulador](docs/es/EN-EL-EMULADOR.md) | qué se puede medir, y cómo |
| [Preguntas abiertas](docs/es/PREGUNTAS-ABIERTAS.md) | lo que aún no está cerrado |

Ver `AVISO-LEGAL.md`.
