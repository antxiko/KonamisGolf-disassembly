# El cartucho

Konami's Golf es un **RC-723** de Konami, de 1985: 16 KB en la página 1, sin
cambio de banco.

## INIT no está donde suele

La cabecera `AB` declara sólo INIT, y lo pone en **0x4053**. En el resto de
cartuchos de la casa de esta época INIT va en 0x4010 — aquí 0x4010 es otra cosa:
**el manejador de la interrupción**, que INIT engancha en H.KEYI antes de
limpiar la RAM y colocar la pila. A partir de ahí el programa principal no hace
nada y todo el juego corre dentro de la interrupción de cada cuadro.

## No lleva la marca oculta de Konami

Konami escondió al final de muchos de sus cartuchos su número de catálogo y el
título en katakana; lo descubrió **Manuel Pazos**
([@ManuelPazosMSX](https://twitter.com/ManuelPazosMSX)), y el bloque vive en el
offset 0x3FF0.

**Éste no la lleva**, y se comprobó rastreando las 16.384 posiciones de la ROM,
no sólo el final, con un buscador validado antes contra cuatro cartuchos de la
misma familia que sí la llevan. La razón se ve en el volcado: la ROM llega
**llena de código hasta 0x7FFD** y sólo sobran dos bytes de relleno.

## La pantalla, del revés

SCREEN 2, pero con las tablas colocadas al contrario de lo habitual: los colores
en 0x0000, los patrones en 0x2000, los nombres en 0x3800 y los sprites en 0x1800
y 0x3B00. Los ocho registros del VDP salen de una tabla de la propia ROM, en
0x447A.

## El reparto de los 16 KB

| | bytes | |
|---|---|---|
| código trazado | 8.665 | 52,89 % |
| datos identificados | 7.719 | 47,11 % |
| **sin explicar** | **0** | **0,00 %** |
