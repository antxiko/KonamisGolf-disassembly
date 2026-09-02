# Hallazgos

## Un hoyo, un bloque, dos lectores

Los datos de cada hoyo se guardan **una sola vez**. Como guion de VRAM pintan el
plano de la derecha; como datos, 0x53B2 los desgrana en una rejilla de 12 por 18
en la RAM, que es la que sabe dónde está la calle y dónde el búnker.

Lo que engancha las dos lecturas es el último byte de la cabecera: un `0x80`, que
en el intérprete significa "cambia de destino", y cuyos dos bytes de destino son
justo el principio de la rejilla. Así que **pintar por el primer puntero pinta el
hoyo entero**, y no hacen falta las dos tablas de punteros que el cartucho lleva.

## El mismo guion dibuja el tile y su espejo

El intérprete de guiones tiene dos puertas: una escribe en la VRAM y otra
(0x601E) lee **el mismo formato contra la RAM**. Con eso, 0x5FE2 pinta un tile
del campo y luego el **mismo tile espejado de izquierda a derecha** (0x5FFD),
sin gastar un byte más: todo dibujo simétrico del campo se guarda una sola
vez.

El truco está en lo que 0x5FFD **no** hace. Parece una trasposición, pero el
`inc hl` de 0x600E está **fuera** del bucle de bits: las ocho vueltas de
`rl (hl)` rotan siempre el **mismo** byte, que al octavo giro vuelve a estar
como estaba, mientras `rra` va recogiendo los bits por el otro lado. Sale la
fila con los bits del revés. Se ve en el volcado: donde el guion de 0x60D6 pone
`F0`, el cartucho deja `0F` en la VRAM.

Y el remate: 0x6013 escribe un `0x00` detrás de la fila espejada y 0x601B un
`0x88` delante, que en el intérprete es la orden de «ocho bytes literales».
O sea que 0x5FFD no devuelve unos bytes: devuelve **un guión de VRAM ya
hecho**, y por eso el original y su espejo los puede pintar la misma rutina.

## La ROM está cosida por solapes deliberados

Casi todas las tablas de este cartucho se indexan desde 1, y su entrada 0 —la que
nunca se usa— está puesta **encima de otra cosa**. No es casualidad ni descuido:
es una manera de no gastar los dos bytes.

- 0x79BA cae sobre el último cuadro del golfista
- 0x5B1B, sobre un `ld a,(hl)`
- 0x5BDC, sobre un `jr`
- 0x5470, sobre un `ret` — que además es la base de una tabla de giro
- 0x7538, sobre los dos últimos periodos de nota
- 0x4D3B, sobre la cola de un guion

## Copiar los tres tercios de la pantalla con una sola copia

0x4322 replica el contenido de la VRAM en los tres tercios de SCREEN 2, y lo hace
con **un solo `ldir` solapado**: copia 4.096 bytes desde 0x0000 a 0x0800. Como el
destino va 0x800 por delante del origen, cuando la copia pasa del primer bloque
está leyendo **lo que ella misma acaba de escribir**. Un `ldir` en vez de dos.

## La altura de la bola no se guarda: es la distancia entre sus dos sprites

La bola son **dos sprites superpuestos**, uno negro y uno blanco. El negro se
queda pegado al suelo y el blanco se levanta con la parábola, así que **la
separación entre los dos *es* la altura**. No hay ninguna variable de altura en
ningún sitio: hay dos coordenadas, y la altura es su resta.

Y de esa resta sale también el tamaño con que se dibuja. 0x7074 hace
`ld a,(0xE0B0) / sub d` —la *y* de la capa de abajo menos la de la de arriba— y
la compara con **0x21, 0x0F y 0x06**: cuatro escalones de bola, de la más gorda
a la más pequeña. Cuanto más alto va, más pequeña se ve. Al posarse, 0x701B
vuelve a juntar las dos capas y la altura es cero otra vez.

## Una sola curva para el seno y el coseno

La dirección del golpe no usa dos tablas: usa **una curva de 66 bytes** en
0x52BF, leída en dos puntos separados 0x21. Coseno y seno son la misma tabla
desfasada.
