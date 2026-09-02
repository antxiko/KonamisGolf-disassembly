# El código

## Un bucle muerto, y toda la máquina en la interrupción

INIT (0x4053) pone un `0xC3` en H.KEYI y la dirección **0x4010** detrás, borra
los 0x7FE bytes de 0xE000 a 0xE7FF con un `ldir` y deja la pila justo debajo. A
partir de ahí el programa principal no hace nada: el juego entero corre dentro de
la interrupción de cada cuadro.

## Una rutina que lee su propio parámetro

0x4379 empieza con `ex (sp),hl`: coge la dirección de retorno —que apunta al byte
de después del CALL—, lee de ahí una palabra de dieciséis bits, y devuelve la
dirección ya avanzada para volver **detrás** del parámetro. O sea que el
parámetro va **pegado al CALL, dentro del flujo de código**.

Hay trece llamadas así, y las trece palabras apuntan dentro de la ROM. Este
detalle es el que hace que un desensamblador ingenuo se pierda: el primer
parámetro es 0x44E9, y su byte bajo, un `0xE9`, se lee como un `jp (hl)` que no
existe.

## El intérprete de guiones

Casi todo lo que se dibuja va comprimido y lo vuelca un mismo intérprete
(0x4380 / 0x4389). El formato, medido:

- cabecera de dos bytes con el destino, **byte alto primero**
- `0x01 rl` — UN byte con dos nibbles: el bajo dice cuántos bytes tiene el
  bloque y el alto cuántas veces se repite (un 0 vale por 256)
- `0x02..0x7F` — racha: repite el byte siguiente
- `0x81..0xFF` — literal: copia tantos bytes
- `0x80` — cambio de destino
- `0x00` — fin

Y hay una segunda puerta, en 0x601E, que lee **el mismo formato pero contra la
RAM**. Gracias a eso 0x5FE2 puede pintar un tile del campo y después el **mismo
tile espejado de izquierda a derecha** (0x5FFD), sin gastar un byte más de ROM.
No es una trasposición aunque lo parezca: el `inc hl` de 0x600E está fuera del
bucle de bits, así que las ocho vueltas de `rl (hl)` giran siempre el mismo
byte y lo que sale es esa fila con los bits del revés. El remate es que 0x6013
y 0x601B le ponen delante un `0x88` y detrás un `0x00`, con lo que la fila
espejada sale ya convertida en un guión de VRAM que pinta la misma rutina.

## Los hoyos

Dos tablas de nueve punteros, en 0x79BC y 0x79CE. La primera lleva a la cabecera
del hoyo y la segunda a su rejilla, pero no hace falta usar las dos: la cabecera
termina en un `0x80` cuyo destino es el principio de la rejilla.

Cada casilla de la rejilla es un código que se dibuja como un bloque de cuatro
tiles de ancho por dos o cuatro de alto, sobre un lienzo de 20 por 16 en RAM, en
cinco bandas de profundidad. Los códigos 0x01 a 0x28 van por unas tablas y los
0x29 a 0x34 por otras; el 0xEA es el tee, el 0xC4 el borde, y el 0x29 y el 0x2A
son el green. El tipo de terreno lo clasifica 0x5BF0 con unos umbrales, y es lo
que decide si el golpe sale a medias.

Y para poder mirar el hoyo desde cuatro ángulos, tres tablas de 48 códigos
(0x5471, 0x54A1 y 0x54D1) **giran los códigos de casilla**, y el juego mantiene
cuatro rejillas: una sin girar, dos giradas y una del revés.
