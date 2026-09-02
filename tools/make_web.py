#!/usr/bin/env python3
"""Genera la portada de la web de Konami's Golf, en los dos idiomas.

El diseno es el compartido por la serie (tools/estilo_web.py) y la pagina sale
autocontenida, con las imagenes embebidas como data URI.

Las imagenes NO son ilustraciones ni capturas: las dibuja tools/graficos.py a
partir de los propios bytes de la ROM, ejecutando en Python los mismos
descompresores que corre el Z80, y estan comprobadas byte a byte contra la VRAM
de openMSX. Ninguna se ha retocado.

Uso: make_web.py <docs/imagenes> <salida.html> <idioma>
"""
import base64
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from estilo_web import ESTILO                                   # noqa: E402

# Las cifras salen de contar sobre el listado generado, no de escribirlas a ojo:
# 16384 = 8665 + 7719, que es lo que imprime tools/presupuesto.py (make sanity).
# RUTINAS son las etiquetas de codigo con nombre propio, las mismas que cuenta
# el .notes con su directiva L. HOYOS, PAR y METROS salen de las nueve fichas de
# cuatro bytes de 0x4D3F, con la longitud leida como BCD de TRES digitos.
CODIGO = 8665
DATOS = 7719
RUTINAS = 558
HOYOS = 9
PAR = 36
METROS = 3512


def mil(n, idioma):
    return f"{n:,}".replace(",", "." if idioma == "es" else ",")


TXT = {
    "es": dict(
        titulo="Konami's Golf — desensamblado comentado",
        aviso="<b>Aquí no hay ninguna ilustración ni captura.</b> El rótulo, "
              "el golfista y <b>los nueve campos</b> están <b>dibujados desde "
              "los bytes de la ROM</b>, ejecutando en Python los mismos "
              "descompresores que corre el Z80, y comprobados byte a byte "
              "contra la VRAM del emulador: <b>cero diferencias en "
              "385.199 bytes</b>, repartidos en 30 volcados. El listado y las cifras salen del binario y se "
              "reproducen con <code>make</code>.",
        claim="Un campo de nueve hoyos en 16 KB, donde cada hoyo se guarda una "
              "sola vez y se lee de dos maneras, los gráficos valen el doble "
              "porque el cartucho los espeja al vuelo, y el viento se sortea "
              "con el registro de refresco de la memoria.",
        ficha=["Konami · <b>© Konami 1985</b>",
               "Cartucho <b>RC-723</b>, 16 KB",
               "MSX1 · <b>página 1</b>", "Volcado <b>6c539f0a…</b>"],
        nav=[("#numbers", "Las cifras"), ("#findings", "Hallazgos"),
             ("#screens", "Lo que dibuja")],
        docnav=[("EMPEZAR.html", "Empezar"), ("EL-JUEGO.html", "El juego"),
                ("EL-CARTUCHO.html", "El cartucho"),
                ("EL-CODIGO.html", "El código"),
                ("HALLAZGOS.html", "Hallazgos"),
                ("EN-EL-EMULADOR.html", "En el emulador"),
                ("PREGUNTAS-ABIERTAS.html", "Preguntas abiertas")],
        otro=("../", "In English"),
        h_num="El cartucho en cifras", h_find="Lo que apareció al desmontarlo",
        h_scr="Lo que el cartucho dibuja",
        cifras=[("100 %", "del binario explicado"),
                (str(RUTINAS), "rutinas identificadas"),
                (str(HOYOS), "hoyos, par %d, %s m" % (PAR, mil(METROS, "es"))),
                (mil(CODIGO, "es"), "bytes de código"),
                (mil(DATOS, "es"), "bytes de datos"),
                ("0", "bytes sin identificar")],
        nota_scr="Debajo de cada imagen está de dónde sale y qué se está "
                 "viendo.",
        pie_leg="Esto es trabajo de documentación y preservación: el código y "
                "los gráficos siguen siendo de sus autores y de Konami, y la "
                "imagen del cartucho no se distribuye.",
    ),
    "en": dict(
        titulo="Konami's Golf — a commented disassembly",
        aviso="<b>There is not one illustration or capture here.</b> The "
              "wordmark, the golfer and <b>all nine courses</b> are "
              "<b>drawn from the bytes of the ROM</b>, by running in Python the "
              "same decompressors the Z80 runs, and checked byte for byte "
              "against the emulator's VRAM: <b>zero differences across "
              "385,199 bytes</b>, spread over 30 dumps. The listing and the numbers come from the binary and "
              "are reproducible with <code>make</code>.",
        claim="A nine-hole course in 16 KB, where every hole is stored once "
              "and read two ways, the graphics are worth double because the "
              "cartridge mirrors them on the fly, and the wind is drawn from "
              "the memory refresh register.",
        ficha=["Konami · <b>© Konami 1985</b>",
               "An <b>RC-723</b> 16 KB cartridge",
               "MSX1 · <b>page 1</b>", "Dump <b>6c539f0a…</b>"],
        nav=[("#numbers", "The numbers"), ("#findings", "What turned up"),
             ("#screens", "What it draws")],
        docnav=[("GETTING-STARTED.html", "Getting started"),
                ("THE-GAME.html", "The game"),
                ("THE-CARTRIDGE.html", "The cartridge"),
                ("THE-CODE.html", "The code"),
                ("FINDINGS.html", "Findings"),
                ("IN-THE-EMULATOR.html", "In the emulator"),
                ("OPEN-QUESTIONS.html", "Open questions")],
        otro=("es/", "En castellano"),
        h_num="The cartridge in numbers",
        h_find="What turned up when we took it apart",
        h_scr="What the cartridge draws",
        cifras=[("100%", "of the binary explained"),
                (str(RUTINAS), "routines identified"),
                (str(HOYOS), "holes, par %d, %s m" % (PAR, mil(METROS, "en"))),
                (mil(CODIGO, "en"), "bytes of code"),
                (mil(DATOS, "en"), "bytes of data"),
                ("0", "bytes unidentified")],
        nota_scr="Under each picture is where it comes from and what is on it.",
        pie_leg="This is documentation and preservation work: the code and "
                "artwork still belong to their authors and to Konami, and the "
                "cartridge image is not distributed.",
    ),
}

HALLAZGOS = {
    "es": [
        ("Un hoyo, un bloque, dos lectores",
         "<p>Los datos de cada hoyo se guardan <b>una sola vez</b>, y el "
         "cartucho los lee de dos maneras distintas: como <b>guión de VRAM</b> "
         "pintan el plano de la derecha, y como <b>datos</b> 0x53B2 los "
         "desgrana en una rejilla de 12 por 18 en la RAM, que es la que sabe "
         "dónde está la calle y dónde el búnker.</p>"
         "<p>Lo que engancha las dos lecturas es el último byte de la "
         "cabecera: un <code>0x80</code>, que en el intérprete significa "
         "«cambia de destino», y cuyos dos bytes de destino son justo el "
         "principio de la rejilla. Así que <b>pintar por el primer puntero "
         "pinta el hoyo entero</b>. En los nueve, las 144 celdas del plano "
         "coinciden con lo que la rejilla dice que hay.</p>"),
        ("El mismo guion dibuja el tile y su espejo, por no hacer lo que parece",
         "<p>El intérprete de guiones tiene dos puertas: una escribe en la "
         "VRAM y otra (0x601E) lee <b>el mismo formato contra la RAM</b>. Con "
         "eso, 0x5FE2 pinta un tile del campo y luego el <b>mismo tile "
         "espejado de izquierda a derecha</b> (0x5FFD), sin gastar un byte "
         "más.</p>"
         "<p>Y el espejo sale de un descuido aprovechado. 0x5FFD parece una "
         "trasposición —ocho vueltas de <code>rl (hl)</code> y "
         "<code>rra</code>, que es como se traspone una matriz de bits—, pero "
         "el <code>inc hl</code> de 0x600E está <b>fuera</b> del bucle "
         "interno: las ocho rotaciones machacan siempre <b>el mismo byte</b>, "
         "que al octavo giro vuelve a estar como estaba, mientras "
         "<code>rra</code> recoge sus bits por el otro lado. Lo que sale es la "
         "fila con los bits del revés. Se ve en el volcado: donde el guión de "
         "0x60D6 pone <code>F0</code>, el cartucho deja <code>0F</code>.</p>"
         "<p>Y el remate: 0x6013 escribe un <code>0x00</code> detrás de la fila "
         "espejada y 0x601B un <code>0x88</code> delante, que es la orden de "
         "«ocho bytes literales». O sea que 0x5FFD no devuelve unos bytes: "
         "devuelve <b>un guión de VRAM ya hecho</b>, y por eso el original y su "
         "espejo los puede pintar la misma rutina.</p>"),
        ("El viento sale del registro de refresco de la memoria",
         "<p>Al empezar cada hoyo, 0x4932 hace <code>ld a,r</code>. R es el "
         "contador de refresco de la DRAM: lo lleva el propio Z80 y avanza con "
         "cada instrucción, así que su valor en un instante cualquiera es "
         "impredecible. De ahí salen las dos cosas: los tres bits bajos más "
         "uno dan la <b>fuerza</b> del viento (1 a 8) y los dos siguientes su "
         "<b>dirección</b> (0 a 3). Sin generador de aleatorios, sin semilla y "
         "sin una tabla que ocupe sitio.</p>"
         "<p>Tiene una consecuencia práctica: <b>el viento es lo único de este "
         "cartucho que no se puede predecir leyendo la ROM</b>. Las imágenes "
         "de aquí abajo llevan su casilla en blanco por eso, y para "
         "comprobarlas contra el emulador hubo que darle los valores que cada "
         "volcado tenía en 0xE104 y 0xE105.</p>"),
        ("La ROM está cosida por solapes deliberados",
         "<p>Casi todas las tablas de este cartucho se indexan desde 1, y su "
         "entrada 0 —la que nunca se usa— está puesta <b>encima de otra "
         "cosa</b>. No es descuido: es no gastar los dos bytes.</p>"
         "<p>0x79BA cae sobre el último cuadro del golfista; 0x5B1B, sobre un "
         "<code>ld a,(hl)</code>; 0x5BDC, sobre un <code>jr</code>; 0x5470, "
         "sobre un <code>ret</code> que además es la base de una tabla de "
         "giro; 0x7538, sobre los dos últimos periodos de nota; y 0x4D3B, "
         "sobre la cola de un guión.</p>"),
        ("Los tres tercios de la pantalla, con una sola copia",
         "<p>SCREEN 2 del MSX son tres tercios independientes, y para que los "
         "tres tengan lo mismo hay que escribirlo tres veces. 0x4322 lo hace "
         "con <b>un solo <code>ldir</code> solapado</b>: copia 4.096 bytes "
         "desde 0x0000 a 0x0800. Como el destino va 0x800 por delante del "
         "origen, cuando la copia pasa del primer bloque está leyendo <b>lo "
         "que ella misma acaba de escribir</b>. Un <code>ldir</code> en vez de "
         "dos.</p>"),
        ('La altura de la bola no se guarda: es la distancia entre sus dos sprites',
         '<p>La bola son <b>dos sprites superpuestos</b>, uno negro y uno blanco. El negro se queda pegado al suelo y el blanco se levanta con la parábola, así que <b>la separación entre los dos <i>es</i> la altura</b>. No hay ninguna variable de altura en ningún sitio: hay dos coordenadas, y la altura es su resta.</p><p>Y de esa resta sale también el tamaño con que se dibuja. 0x7074 hace <code>ld a,(0xE0B0) / sub d</code> —la <i>y</i> de la capa de abajo menos la de la de arriba— y la compara con <b>0x21, 0x0F y 0x06</b>: cuatro escalones de bola, de la más gorda a la más pequeña. Cuanto más alto va, más pequeña se ve. Al posarse, 0x701B vuelve a juntar las dos capas y la altura es cero otra vez.</p>'),
        ("Una sola curva para el seno y el coseno",
         "<p>La dirección del golpe no usa dos tablas: usa <b>una curva de 66 "
         "bytes</b> en 0x52BF, leída en dos puntos separados 0x21. Coseno y "
         "seno son la misma tabla desfasada un cuarto de vuelta, que es "
         "exactamente lo que son.</p>"),
        ("No lleva la marca oculta de Konami, y se ha comprobado en serio",
         "<p>Konami escondía al final de muchos cartuchos su número de "
         "catálogo y el título en katakana; lo descubrió <b>Manuel Pazos</b> "
         "(<a href=\"https://twitter.com/ManuelPazosMSX\">@ManuelPazosMSX</a>) "
         "y el bloque vive en el offset 0x3FF0. <b>Éste no la lleva</b>, y no "
         "por no mirar: se rastrearon las 16.384 posiciones de la ROM con un "
         "buscador <b>validado antes contra cartuchos de la misma familia que "
         "sí la llevan</b> —los RC-718 y RC-729 de la serie sueltan la suya al "
         "primer intento—, que es la única manera de fiarse de un negativo. La "
         "razón se ve en el volcado: la ROM llega llena hasta 0x7FFD y sólo "
         "sobran <b>dos</b> bytes de relleno. No cabe.</p>"),
    ],
    "en": [
        ("One hole, one block, two readers",
         "<p>Each hole's data is stored <b>exactly once</b>, and the cartridge "
         "reads it two different ways: as a <b>VRAM script</b> it paints the "
         "plan view on the right, and as <b>data</b> 0x53B2 unpacks it into a "
         "12 by 18 grid in RAM, which is the one that knows where the fairway "
         "is and where the bunker.</p>"
         "<p>What hooks the two readings together is the last byte of the "
         "header: an <code>0x80</code>, which in the interpreter means «change "
         "destination», and whose two destination bytes are the start of the "
         "grid. So <b>painting from the first pointer paints the whole "
         "hole</b>. Across all nine, the plan's 144 cells agree with what the "
         "grid says is there.</p>"),
        ("The same script draws the tile and its mirror, by not doing what it looks like",
         "<p>The script interpreter has two doors: one writes to VRAM, the "
         "other (0x601E) reads <b>the same format against RAM</b>. With that, "
         "0x5FE2 paints a course tile and then the <b>same tile mirrored left "
         "to right</b> (0x5FFD), without spending one more byte.</p>"
         "<p>And the mirror comes out of a slip turned to advantage. 0x5FFD "
         "looks like a transpose — eight rounds of <code>rl (hl)</code> and "
         "<code>rra</code>, which is how you transpose a bit matrix — but the "
         "<code>inc hl</code> at 0x600E sits <b>outside</b> the inner loop: "
         "the eight rotations keep hammering <b>the same byte</b>, which by "
         "the eighth is back where it started, while <code>rra</code> collects "
         "its bits from the other end. What comes out is that row with its "
         "bits reversed. The dump shows it: where the script at 0x60D6 puts "
         "<code>F0</code>, the cartridge leaves <code>0F</code>.</p>"
         "<p>And the finish: 0x6013 writes a <code>0x00</code> after the "
         "mirrored row and 0x601B an <code>0x88</code> in front, which is the "
         "«eight literal bytes» order. So 0x5FFD does not hand back some "
         "bytes: it hands back <b>a finished VRAM script</b>, which is why the "
         "original and its mirror can be painted by the same routine.</p>"),
        ("The wind comes out of the memory refresh register",
         "<p>At the start of every hole, 0x4932 does <code>ld a,r</code>. R is "
         "the DRAM refresh counter: the Z80 keeps it itself and it advances "
         "with every instruction, so its value at any given moment is "
         "unpredictable. Both things come from there: the low three bits plus "
         "one give the wind's <b>strength</b> (1 to 8) and the next two its "
         "<b>direction</b> (0 to 3). No random generator, no seed, and no "
         "table taking up room.</p>"
         "<p>There is a practical consequence: <b>the wind is the one thing in "
         "this cartridge you cannot predict by reading the ROM</b>. That is "
         "why its cell is blank in the pictures below, and why checking them "
         "against the emulator meant feeding in whatever each dump happened to "
         "have in 0xE104 and 0xE105.</p>"),
        ("The ROM is stitched together with deliberate overlaps",
         "<p>Almost every table in this cartridge is indexed from 1, and entry "
         "0 — the one never used — is laid <b>on top of something else</b>. "
         "Not an oversight: it is not spending the two bytes.</p>"
         "<p>0x79BA falls on the golfer's last frame; 0x5B1B on an "
         "<code>ld a,(hl)</code>; 0x5BDC on a <code>jr</code>; 0x5470 on a "
         "<code>ret</code> that doubles as the base of a rotation table; "
         "0x7538 on the last two note periods; and 0x4D3B on the tail of a "
         "script.</p>"),
        ("The screen's three thirds, with a single copy",
         "<p>The MSX's SCREEN 2 is three independent thirds, and for all three "
         "to hold the same thing you have to write it three times. 0x4322 does "
         "it with <b>one overlapping <code>ldir</code></b>: it copies 4,096 "
         "bytes from 0x0000 to 0x0800. Since the destination runs 0x800 ahead "
         "of the source, once the copy passes the first block it is reading "
         "<b>what it has just written itself</b>. One <code>ldir</code> "
         "instead of two.</p>"),
        ("The ball's height is not stored: it is the gap between its two sprites",
         "<p>The ball is <b>two overlapping sprites</b>, one black and one white. The black one stays stuck to the ground and the white one rises with the parabola, so <b>the gap between them <i>is</i> the height</b>. There is no height variable anywhere: there are two coordinates, and the height is their difference.</p><p>And that same difference gives the size it is drawn at. 0x7074 does <code>ld a,(0xE0B0) / sub d</code> — the lower layer's <i>y</i> minus the upper one's — and compares it against <b>0x21, 0x0F and 0x06</b>: four ball sizes, from the fattest to the smallest. The higher it flies, the smaller it looks. On landing, 0x701B brings the two layers back together and the height is zero again.</p>"),
        ("One curve for both sine and cosine",
         "<p>The shot's direction does not use two tables: it uses <b>one "
         "66-byte curve</b> at 0x52BF, read at two points 0x21 apart. Cosine "
         "and sine are the same table shifted by a quarter turn, which is "
         "exactly what they are.</p>"),
        ("It does not carry Konami's hidden mark, and that was checked properly",
         "<p>At the end of many cartridges Konami hid its catalogue number and "
         "the title in katakana; <b>Manuel Pazos</b> "
         "(<a href=\"https://twitter.com/ManuelPazosMSX\">@ManuelPazosMSX</a>) "
         "found it, and the block lives at offset 0x3FF0. <b>This one does not "
         "have it</b>, and not for want of looking: all 16,384 positions were "
         "scanned with a finder <b>first validated against cartridges of the "
         "same family that do carry it</b> — the RC-718 and RC-729 of this "
         "series give theirs up on the first try — which is the only way to "
         "trust a negative. The dump shows why: the ROM runs full to 0x7FFD "
         "with just <b>two</b> bytes of filler left. No room.</p>"),
    ],
}

GALERIA = [
    ("hoyos.png",
     "<b>Los nueve hoyos del campo</b>, cada uno con su panel: número, par, "
     "longitud en metros y la bandera puesta donde dice el cartucho. No son "
     "capturas: los pinta en Python el mismo intérprete de guiones del Z80, "
     "leyendo los punteros de 0x79BC. Que están bien no es una impresión — el "
     "plano se comparó celda a celda contra treinta volcados de openMSX, con "
     "<b>cero diferencias</b>",
     "<b>The course's nine holes</b>, each with its panel: number, par, length "
     "in metres and the flag placed where the cartridge says. These are not "
     "captures: Python paints them with the Z80's own script interpreter, "
     "following the pointers at 0x79BC. That they are right is not an "
     "impression — the plan was compared cell by cell against thirty openMSX "
     "dumps, with <b>zero differences</b>"),
    ("campo_1.png",
     "El hoyo 1 de cerca, par 4 y 475 metros. La columna de la izquierda es el "
     "panel entero tal como lo monta el cartucho; la casilla del viento va en "
     "blanco porque ese dato no está en la ROM, lo sortea el registro R",
     "Hole 1 up close, par 4 and 475 metres. The left column is the whole "
     "panel as the cartridge builds it; the wind cell is blank because that "
     "figure is not in the ROM — the R register draws it"),
    ("campo_5.png",
     "El hoyo 5, el único par 3 del campo: 168 metros, green casi pegado al "
     "tee y búnkeres por medio",
     "Hole 5, the course's only par 3: 168 metres, with the green almost on "
     "top of the tee and bunkers in between"),
    ("titulo.png",
     "La pantalla del título, montada con los pasos del propio cartucho: el "
     "guion de 0x44E9 descomprime los 38 tiles del rótulo y 0x4354 los coloca "
     "en dos filas de 19 desde la VRAM 0x3887",
     "The title screen, built with the cartridge's own steps: the script at "
     "0x44E9 decompresses the wordmark's 38 tiles and 0x4354 lays them out in "
     "two rows of 19 from VRAM 0x3887"),
    ("bloques.png",
     "Los 54 códigos de casilla con los que se construye la vista en "
     "perspectiva, cada uno dibujado a las <b>cinco distancias</b> con que el "
     "cartucho los apila: el mismo código ocupa cuatro tiles de alto cerca y "
     "dos al fondo",
     "The 54 cell codes the perspective view is built from, each drawn at the "
     "<b>five distances</b> the cartridge stacks them at: the same code is "
     "four tiles tall up close and two at the back"),
    ("golfista.png",
     "Los siete cuadros del swing, descomprimidos desde 0x78FF y montados "
     "sprite a sprite como hace 0x5862, con su orden de prioridad",
     "The swing's seven frames, decompressed from 0x78FF and assembled sprite "
     "by sprite the way 0x5862 does it, in their priority order"),
    ("tiles.png",
     "Los 256 tiles del campo con su color, tal como quedan en la VRAM después "
     "de que 0x482E cargue los dibujos",
     "The course's 256 tiles with their colour, as they sit in VRAM once "
     "0x482E has loaded the artwork"),
    ("sprites.png",
     "Los 32 patrones de sprite de 16×16 que hay cargados durante la partida: "
     "el golfista, la bola, su sombra y la bandera",
     "The 32 sprite patterns of 16×16 loaded during play: the golfer, the "
     "ball, its shadow and the flag"),
    ("fuente.png",
     "La fuente con la que se escribe todo. No es ASCII: E0 es la H, D3 la O, "
     "D9 la L y DC la E, y las cifras son 0xF0 más el dígito",
     "The font everything is written with. It is not ASCII: E0 is H, D3 is O, "
     "D9 is L and DC is E, and the digits are 0xF0 plus the digit"),
]


def img64(ruta):
    with open(ruta, "rb") as f:
        return "data:image/png;base64," + base64.b64encode(f.read()).decode()


def main(argv):
    if len(argv) < 4:
        print(__doc__)
        return 2
    imgdir, salida, idioma = argv[1:4]
    t = TXT[idioma]

    # El "logotipo" de la cabecera no es un montaje ni una captura: es el rotulo
    # que el propio cartucho pinta en su pantalla de titulo, dibujado desde la
    # ROM por graficos.py. Si el PNG no esta, el trabajo NO esta hecho: se cae
    # al texto, y eso se ve.
    ruta_logo = os.path.join(imgdir, "rotulo.png")
    cabecera = (f'<img src="{img64(ruta_logo)}" alt="Konami&#39;s Golf">'
                if os.path.exists(ruta_logo) else "<h1>Konami&#39;s Golf</h1>")

    nav = "".join(f'<a href="{h}">{x}</a>' for h, x in t["nav"])
    nav += "".join(f'<a href="{h}">{x}</a>' for h, x in t["docnav"])
    nav += (f'<a href="{t["otro"][0]}" style="margin-left:auto;color:var(--oro)">'
            f'{t["otro"][1]}</a>')

    cifras = "".join(f'<div class="cifra"><b>{v}</b><span>{e}</span></div>'
                     for v, e in t["cifras"])
    halls = "".join(f'<div class="hall"><h3>{tit}</h3>{cuerpo}</div>'
                    for tit, cuerpo in HALLAZGOS[idioma])
    imgs = ""
    faltan = []
    for fich, es, en in GALERIA:
        ruta = os.path.join(imgdir, fich)
        if not os.path.exists(ruta):
            faltan.append(fich)
            continue
        pie = es if idioma == "es" else en
        imgs += (f'<figure><img src="{img64(ruta)}" alt="{pie}">'
                 f'<figcaption>{pie}</figcaption></figure>')
    if faltan:
        print("  (faltan %d imagenes: %s)" % (len(faltan), " ".join(faltan)))

    html = f"""<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>{t['titulo']}</title>
<style>{ESTILO}</style>
<header class="top">
  {cabecera}
  <p class="claim">{t['claim']}</p>
  <p class="ficha">{' · '.join(t['ficha'])}</p>
</header>
<p class="ficha" style="border:1px solid var(--oro);padding:.8em 1em;margin:1.5em 0">
{t['aviso']}</p>
<nav>{nav}</nav>
<section id="numbers">
  <h2>{t['h_num']}</h2>
  <div class="cifras">{cifras}</div>
</section>
<section id="findings"><h2>{t['h_find']}</h2>{halls}</section>
<section id="screens">
  <h2>{t['h_scr']}</h2>
  <p class="n">{t['nota_scr']}</p>
  <div class="galeria">{imgs}</div>
</section>
<footer><p>{t['pie_leg']}</p></footer>
"""
    with open(salida, "w", encoding="utf-8") as f:
        f.write(html)
    print("  %s: %d KB (%s)" % (salida, len(html) // 1024, idioma))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
