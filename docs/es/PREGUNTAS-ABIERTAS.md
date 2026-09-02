# Preguntas abiertas

Lo que no está cerrado, dicho tal cual. Nada de esto se ha rellenado a ojo.

## Un posible fallo que no se ha comprobado

En 0x57EC hay cuatro bytes —0x28, 0x50, 0xA0 y 0xF0— que son las fronteras entre
las cinco bandas de profundidad del lienzo. 0x55B6 los indexa con el número de
banda menos uno; pero la banda llega a valer **5**, con lo que el índice 4 **se
sale de la tabla** y lee el 0x3A que ya es la instrucción de 0x57F0.

Puede ser inofensivo —0xE4C0 + 0x3A sigue cayendo dentro del lienzo— o puede ser
un fallo del cartucho. **No se ha comprobado en el emulador**, así que aquí se
queda como lo que es: una sospecha medida, no un hallazgo.

## Dos sprites al mismo sitio, en el green

Cuando los dos están en el green y las bolas caen a menos de tres píxeles, 0x551F
hace esto:

    push de              ; DE viene con 0xE1C0, el marcador del tee
    ld de,07b30h         ; el atributo del sprite 12
    call vuelca_cuatro_bytes   ; 0xE0B0, la bola -> sprite 12
    pop hl
    call vuelca_cuatro_bytes   ; 0xE1C0, el marcador -> sprite 12 OTRA VEZ

`vuelca_cuatro_bytes` **no toca DE**: sólo avanza HL. Así que la segunda llamada
vuelve a abrir la VRAM en 0x3B30 y **escribe encima de lo que acaba de poner la
primera**. La bola se pierde debajo del marcador, y el primer volcado es trabajo
tirado. Un `inc de` de más —o un 0x3B34— y serían dos sprites distintos.

Puede ser un descuido del cartucho o puede que en pantalla dé igual, porque las
dos fichas están a menos de tres píxeles y el sprite que queda tapa al otro de
todos modos. **No se ha comprobado en el emulador**: se queda como lo que es, una
sospecha medida sobre el código.

## Código al que no salta nadie

Los seis bytes de 0x6E70 son código válido —`ld a,c / neg / ld c,a / jr`—,
gemelos de los de 0x6E6A que hacen lo mismo con B. Los tres `jr` de alrededor
apuntan más allá. No se ha encontrado ningún camino que los alcance.

## La vista en perspectiva no está dibujada

De las imágenes de la web faltan las de la pantalla de juego: la vista del hoyo
desde detrás de la bola. Las piezas están: el lienzo de 20 por 16 en 0xE4C0, los
54 códigos de casilla y los bloques con que se apilan a cinco distancias, todo
dibujado en `bloques.png`. Lo que falta es la cadena que sitúa la bola en el tee
—0x4850, luego `donde_esta_la_bola` (0x5A2A) y `elige_la_rejilla` (0x5AA5) con la
franja de 0x5B1D— para saber **cuál de las cuatro rejillas se mira y desde qué
casilla**. Se paró antes de inventarlo.

## Qué dibuja cada tile del campo, con su nombre

Los 256 tiles y los 54 códigos de casilla **ya están dibujados** desde la ROM, y
se pueden mirar en `tiles.png` y `bloques.png`. Lo que sigue sin hacer es
menor: ponerle nombre a cada uno —cuál es el árbol, cuál el borde del búnker— en
los tramos `tiles_girables_1..6` y `colores_del_campo_1..10` del listado. Están
situados y decodifican limpio; lo que no tienen es etiqueta propia.
