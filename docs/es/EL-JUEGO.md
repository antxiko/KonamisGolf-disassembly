# El juego

Konami's Golf es un campo de **nueve hoyos**, par **36** y **3.512 metros**, en
un cartucho de 16 KB. Tres modos: un jugador a golpes, dos jugadores a golpes, y
dos jugadores por hoyos.

## El campo

| Hoyo | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 |
|---|---|---|---|---|---|---|---|---|---|
| Par | 4 | 4 | 4 | 5 | 3 | 4 | 4 | 4 | 4 |
| Metros | 475 | 360 | 362 | 475 | 168 | 477 | 472 | 244 | 479 |

Esas cifras no están escritas en la web a ojo: salen de la tabla de 0x4D3F,
nueve fichas de cuatro bytes con el par y la longitud en BCD. Y los nueve hoyos
de esta página están **dibujados desde la ROM**, no capturados.

## Cada hoyo se guarda una vez y se lee de dos maneras

Esto es lo más bonito del cartucho. Los datos de un hoyo son **un solo bloque**,
y el juego lo recorre dos veces con dos lectores distintos:

- Como **guion de VRAM** pinta el plano que ves a la derecha, dieciséis filas de
  nueve tiles.
- Como **datos**, 0x53B2 lo desgrana en una rejilla de **12 columnas por 18
  filas** en la RAM, que es la que sabe si estás en calle, búnker, rough, green
  o fuera de límites.

Y el enganche entre las dos lecturas es un detalle de orfebrería: el último byte
de la cabecera es un `0x80` —el código de "cambio de destino" del intérprete— y
sus dos bytes de destino son justamente el principio de la rejilla. Así que
**pintar por el primer puntero pinta el hoyo entero**.

## El golpe

Trece palos, leídos de sus propios tiles: **1W 3W 1I 3I 4I 5I 6I 7I 8I 9I PW SW
PT**. El alcance sale de la tabla de 0x5152, menos lo que se pierda según dónde
pares la barra de fuerza (0x516C, u 0x5177 si es el putter). Si estás en búnker
se parte por la mitad; en rough con un palo del 2 para arriba, se le restan 48.

La dirección sale de **una sola curva de 66 bytes**, leída en dos sitios
separados 0x21: seno y coseno de la misma tabla. Y hay efecto —STRAIGHT, SLICE,
HOOK— que tuerce la bola por su cuenta.

## El viento no es decorativo

Se sortea al empezar cada hoyo con `ld a,r`: una fuerza de 1 a 8 y una de cuatro
direcciones, y se pintan en la fila WIND del panel.

Lo que hace no es empujar **más fuerte**, sino **más a menudo**. Cada empujón es
igual; lo que cambia es cada cuántos cuadros llega. 0x6C4C recarga la cuenta de
0xE03C con **20 si el palo es un madera** —el 1W o el 3W, los dos primeros— y con
**10 con cualquier otro**, y a esa cifra le resta la fuerza del viento. Con
viento 8, un hierro recibe un empujón cada 2 cuadros contados y un madera cada
12. Encima, la cuenta sólo avanza en uno de cada cuatro cuadros (`and 3` sobre el
contador de 0xE000), así que el reloj real es cuatro veces más lento.

Dicho de otro modo: **los maderas son los que menos sufren el viento**, que es
justo al revés de lo que uno esperaría de un palo que manda la bola alta y
lejos.
