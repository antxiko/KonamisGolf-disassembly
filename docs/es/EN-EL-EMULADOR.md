# En el emulador

Los dibujos de esta web salen de la ROM, no del emulador. Pero **mirar una imagen
no basta para creérsela**: en esta serie se vuelca la VRAM de openMSX y se compara
byte a byte contra lo que monta el Python. Si cuadran, el formato está bien leído.

De este cartucho se volcaron **30 pantallas** —el título, el menú y los nueve
hoyos— y la comparación cubre **385.199 bytes**: los patrones y los colores de
las dos pantallas, los patrones de sprite, el plano del hoyo, su cabecera entera
y los ocho registros del VDP. Salen **cero diferencias**. La orden que lo hace
es

    python tools/graficos.py --comprueba golf.rom 0x4000 work/omsx

y la única casilla que hubo que darle es la del viento, que no está en la ROM:
la sortea `ld a,r`, así que se le pasan los valores que cada volcado tenía.

## Cargarlo

    openmsx -machine Philips_VG_8020 -cart golf.rom

## Los guiones de medida

En `tools/` hay guiones de TCL para openMSX que sirven para comprobar, no para
ilustrar: vuelcan los 16 KB de VRAM y los registros del VDP, y salen solos con un
perro guardián de tiempo real para que un guión roto no deje el emulador colgado.

Dos cosas aprendidas a base de perder tiempo, por si escribes los tuyos: en TCL no
pongas comillas anidadas dentro de una cadena (usa `{VDP regs}`), y **no pongas
puntos de ruptura que disparen en cada fotograma** dentro de rutinas de dibujo,
porque ahogan al emulador y no llega ni a arrancar la partida.
