#!/usr/bin/env python3
"""Dibuja los graficos de Konami's Golf desde los bytes del cartucho.

Ninguna de estas imagenes es una captura del emulador: todas se montan
leyendo la ROM y corriendo en Python los MISMOS pasos que el Z80 da en la
maquina. El interprete de guiones (0x4380/0x4389), su gemelo que vuelca a la
RAM (0x601E), el espejo de tiles (0x5FFD), la carga entera de los dibujos del
campo (0x5E03), el desgranado de la rejilla del hoyo (0x53B2) y el reparto de
bloques de la vista (0x5556) estan aqui reproducidos orden a orden. Eso es lo
que convierte el dibujo en una prueba: si un rango o un formato estuvieran mal
leidos, saldria ruido.

Lo que dibuja (en docs/imagenes/):
  rotulo.png       el logotipo Konami's Golf: los 38 tiles 0x40-0x65
  titulo.png       la pantalla del menu entera, con el logotipo y las opciones
  campo_1..9.png   LOS NUEVE HOYOS: la cabecera del panel y el plano del hoyo,
                   con la bandera puesta donde dice la tabla de 0x5BDC
  hoyos.png        los nueve juntos en una lamina
  bloques.png      los 54 codigos de casilla, cada uno dibujado a las cinco
                   distancias con que monta_la_vista los pone en el lienzo
  golfista.png     los siete cuadros del swing (0x78FF)
  tiles.png        los 256 tiles cargados al empezar a jugar
  fuente.png       los 96 tiles de texto (0xA0-0xFF) de la pantalla del menu
  sprites.png      los 32 patrones de sprite de 16x16

Uso: graficos.py <rom> <org> <docs/imagenes>
     graficos.py --comprueba <rom> <org> <carpeta de volcados>...

El segundo modo compara byte a byte lo que monta este guion con la VRAM de
verdad que vuelcan tools/omsx_vram.tcl y tools/omsx_vram_hoyo.tcl desde
openMSX. Mirar el dibujo no basta.
"""
import os
import struct
import sys
import zlib

# --------------------------------------------------------------------------
# La paleta del TMS9918. El color 0 es transparente y, con el registro 7 a
# 0xE1 (0x447A), lo que quede transparente se ve del color del borde: negro.
# --------------------------------------------------------------------------
PALETA = [
    (0, 0, 0), (0, 0, 0), (62, 184, 73), (116, 208, 125),
    (89, 85, 224), (128, 118, 241), (185, 94, 81), (101, 219, 239),
    (219, 101, 89), (255, 137, 125), (204, 195, 94), (222, 208, 135),
    (58, 162, 65), (183, 102, 181), (204, 204, 204), (255, 255, 255),
]

FONDO = (0x20, 0x20, 0x30)
REJA = (0x38, 0x38, 0x4A)
SEPARA = (0x2A, 0x2A, 0x38)

# Los ocho registros del VDP (DATA_registros_del_vdp, 0x447A) dicen donde esta
# cada tabla. No se copia ninguna direccion de otro juego: salen de aqui.
REGISTROS = 0x447A


class Vdp(object):
    """Las tablas de la VRAM tal como las coloca este cartucho."""

    def __init__(self, rom, org):
        r = rom[REGISTROS - org:REGISTROS - org + 8]
        self.regs = list(r)
        self.nombres = r[2] * 0x400              # 0x0E -> 0x3800
        self.patrones = (r[4] & 0x04) * 0x800    # 0x07 -> 0x2000
        self.colores = (r[3] & 0x80) * 0x40      # 0x7F -> 0x0000
        self.sprite_attr = r[5] * 0x80           # 0x76 -> 0x3B00
        self.sprite_pat = r[6] * 0x800           # 0x03 -> 0x1800
        self.sprites_16 = bool(r[1] & 0x02)      # 0xE2 -> sprites de 16x16


# --------------------------------------------------------------------------
# PNG sin dependencias
# --------------------------------------------------------------------------
def png(w, h, px, fn):
    raw = b"".join(b"\0" + bytes(px[y * w * 3:(y + 1) * w * 3]) for y in range(h))

    def chunk(t, d):
        return (struct.pack(">I", len(d)) + t + d
                + struct.pack(">I", zlib.crc32(t + d) & 0xFFFFFFFF))
    with open(fn, "wb") as f:
        f.write(b"\x89PNG\r\n\x1a\n"
                + chunk(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, 2, 0, 0, 0))
                + chunk(b"IDAT", zlib.compress(raw, 9)) + chunk(b"IEND", b""))


class Rom(object):
    def __init__(self, datos, org):
        self.d, self.org = datos, org

    def b(self, a):
        return self.d[a - self.org]

    def w(self, a):
        return self.d[a - self.org] | (self.d[a - self.org + 1] << 8)

    def wbe(self, a):
        """La palabra con el byte ALTO primero, que es como el interprete de
        guiones lee su cabecera (0x4380: ld d,(hl) / inc hl / ld e,(hl))."""
        return (self.d[a - self.org] << 8) | self.d[a - self.org + 1]


# ==========================================================================
# EL INTERPRETE DE GUIONES DEL CARTUCHO (0x4380 y 0x4389), TAL CUAL
# ==========================================================================
class Vram(object):
    """La VRAM con su puntero de escritura, que es lo que el VDP autoincrementa
    y lo que hace que dos guiones seguidos se pinten uno detras de otro."""

    def __init__(self):
        self.m = bytearray(0x4000)
        self.p = 0

    def abre(self, de):
        """abre_la_vram_para_escribir (0x4403): DE trae el bit 14 puesto."""
        self.p = de & 0x3FFF

    def pon(self, v):
        self.m[self.p] = v & 0xFF
        self.p = (self.p + 1) & 0x3FFF


def pinta_guion(rom, hl, vram):
    """pinta_guion (0x4380): el destino sale de los dos primeros bytes, BYTE
    ALTO PRIMERO, y sigue en 0x4389."""
    vram.abre(rom.wbe(hl))
    return pinta_guion_aqui(rom, hl + 2, vram)


def pinta_guion_de(rom, hl, vram, de):
    """pinta_guion_de (0x4384): igual pero con el destino ya en DE."""
    vram.abre(de)
    return pinta_guion_aqui(rom, hl, vram)


def pinta_guion_aqui(rom, hl, vram):
    """pinta_guion_aqui (0x4389). Las cinco ordenes, exactamente como las
    reparte 0x43AB:

      0x01 nb  el bloque de (nb and 0x0F) bytes, repetido (nb shr 4) veces
      0x02..0x7F  racha: repite n veces el byte que va detras
      0x81..0xFF  literal: copia (n and 0x7F) bytes tal cual
      0x80        cambia de destino, que viene detras en dos bytes
      0x00        fin

    Devuelve donde se quedo el guion, que es lo que permite encadenar los
    trozos igual que hace el cartucho.
    """
    while True:
        x = rom.b(hl)
        hl += 1
        if x == 0x01:                       # 0x438B: la orden del bloque
            nb = rom.b(hl)
            hl += 1
            largo = nb & 0x0F
            veces = (nb & 0xF0) >> 4
            veces = veces if veces else 256   # dec c desde 0 da 256 vueltas
            for _ in range(veces):
                for i in range(largo):
                    vram.pon(rom.b(hl + i))
            hl += largo
            continue
        n = x & 0x7F
        if n == 0:                          # 0x43AE: 0x00 acaba, 0x80 recoloca
            if x == 0x00:
                return hl
            vram.abre(rom.wbe(hl))
            hl += 2
            continue
        if n == x:                          # bit 7 claro: racha
            v = rom.b(hl)
            hl += 1
            for _ in range(n):
                vram.pon(v)
        else:                               # bit 7 puesto: literal
            for i in range(n):
                vram.pon(rom.b(hl + i))
            hl += n


def descomprime_en_ram(rom, hl, ram):
    """descomprime_en_ram (0x601E): el mismo formato de rachas y literales,
    pero volcado a la RAM 0xE060. No entiende ni el 0x01 ni el 0x80: para en
    el primer byte cuyos siete bits bajos sean cero."""
    de = 0
    while True:
        x = rom.b(hl)
        hl += 1
        n = x & 0x7F
        if n == 0:
            return hl
        if n == x:
            v = rom.b(hl)
            hl += 1
            for _ in range(n):
                ram[de] = v
                de += 1
        else:
            for _ in range(n):
                ram[de] = rom.b(hl)
                hl += 1
                de += 1


def gira_el_tile(ram):
    """gira_el_tile (0x5FFD). OJO: no traspone nada.

    El `inc hl` de 0x600E esta FUERA del bucle interno, o sea que las ocho
    vueltas de `rl (hl)` / `rra` machacan SIEMPRE EL MISMO byte: cada `rl`
    saca su bit alto al acarreo y cada `rra` lo mete por arriba de A. Al cabo
    de las ocho, A es el byte con los BITS DEL REVES. Repetido para las ocho
    filas, lo que sale es el tile ESPEJADO DE IZQUIERDA A DERECHA.

    Comprobado contra la VRAM: el guion de 0x60D6 rinde FF FF FF FF FF FF F0
    00 y el cartucho deja en 0x21C8 FF FF FF FF FF FF 0F 00, que es el mismo
    dibujo con cada byte volteado, no su traspuesta (que seria 00 F0 FF FF FF
    FF FF FF).

    Deja el resultado hecho un guion: 0x88 delante (0x601B) y 0x00 detras
    (0x6016), que es lo que 0x5FF5 vuelve a pintar.
    """
    girado = []
    for x in ram[:8]:
        a = 0
        for _ in range(8):                 # 0x6008: rl (hl) / rra, ocho veces
            a = ((a >> 1) | ((x & 0x80) << 0)) & 0xFF
            x = (x << 1) & 0xFF
        girado.append(a)
    return girado


def pinta_el_guion_c_veces(rom, hl, vram, c):
    """pinta_el_guion_c_veces (0x5FD4): el mismo guion C veces seguidas, cada
    una detras de la anterior. Devuelve HL detras del guion, UNA vez."""
    fin = hl
    for _ in range(c):
        fin = pinta_guion_aqui(rom, hl, vram)
    return fin


def pinta_el_tile_y_su_giro(rom, hl, vram, b, c):
    """pinta_el_tile_y_su_giro (0x5FE2): pinta C veces el trozo de HL y luego
    otras C veces ESE MISMO TROZO ESPEJADO (ver gira_el_tile), y da B vueltas
    avanzando por los guiones que van seguidos en la ROM. Asi es como el
    cartucho se ahorra la mitad de los dibujos: la ladera que cae a la derecha
    y la que cae a la izquierda son el mismo tile volteado."""
    for _ in range(b):
        fin = pinta_el_guion_c_veces(rom, hl, vram, c)
        ram = bytearray(8)
        descomprime_en_ram(rom, hl, ram)
        girado = gira_el_tile(ram)
        for _ in range(c):
            for v in girado:
                vram.pon(v)
        hl = fin
    return hl


def replica_los_tercios(vram, lee, escribe):
    """replica_los_tercios (0x4322): 4096 bytes de VRAM a VRAM. Como el destino
    va 0x800 por delante del origen, la primera mitad copia el tercio 0 en el 1
    y la segunda ese mismo en el 2: los tres quedan iguales."""
    lee &= 0x3FFF
    escribe &= 0x3FFF
    for _ in range(0x1000):
        vram.m[escribe] = vram.m[lee]
        lee = (lee + 1) & 0x3FFF
        escribe = (escribe + 1) & 0x3FFF


# ==========================================================================
# LA PANTALLA DEL TITULO Y EL MENU
# ==========================================================================
def carga_el_titulo(rom, vdp=None):
    """Lo que INIT deja puesto entre 0x40C3 y 0x40F7: el guion gordo de 0x44E9
    con los patrones y los colores del rotulo, las dos colas de 0x4703 y
    0x46B0 (que entran con el destino ya fijado) y el guion de colores de
    0x4782, y al final los tres tercios replicados."""
    vram = Vram()
    pinta_guion(rom, 0x44E9, vram)                 # 0x40C3, parametro 0x40C6
    pinta_guion_de(rom, 0x4703, vram, 0x6680)      # 0x40C8: cola a 0x2680
    pinta_guion(rom, 0x4782, vram)                 # 0x40D4, parametro 0x40D7
    pinta_guion_de(rom, 0x46B0, vram, 0x6780)      # 0x40D9: cola a 0x2780
    replica_los_tercios(vram, 0x0000, 0x0800)      # 0x40EB: los colores
    replica_los_tercios(vram, 0x2000, 0x2800)      # 0x40F4: los patrones
    return vram


def pinta_el_logotipo(rom, vram, de=0x7887):
    """pinta_el_logotipo (0x4354): diecinueve tiles correlativos desde el 0x40
    en la fila de la VRAM DE, y otros diecinueve desde el 0x53 una fila mas
    abajo. Los 38 tiles 0x40-0x65 son el logotipo."""
    for base in (0x40, 0x53):
        vram.abre(de)
        for k in range(0x13):
            vram.pon(base + k)
        de += 0x20
    return de


def monta_la_pantalla_del_menu(rom, vram):
    """monta_la_pantalla_del_menu (0x42C7): borra la tabla de nombres, pinta
    los cuatro guiones que arrancan en 0x4482 -los dos rotulos fijos y las
    tres opciones- y remata con el logotipo."""
    for i in range(0x300):
        vram.m[0x3800 + i] = 0
    hl = 0x4482
    for _ in range(4):
        hl = pinta_guion(rom, hl, vram)
    pinta_el_logotipo(rom, vram)
    return vram


def pinta_el_cursor_del_menu(rom, vram, opcion=0):
    """pinta_el_cursor_del_menu (0x42D6): la fila de siete bytes de 0x42E2 que
    le toca a la opcion, volcada de dos en dos desde la VRAM 0x3A25 subiendo
    dos filas cada vez. El 0xFF corta."""
    hl = 0x42E2 + 7 * (opcion + 1)           # 0x42D1: siete por opcion CONTADA
    de = 0x3A25
    while rom.b(hl) != 0xFF:                 # 0x42DB: el 0xFF corta
        vram.m[de & 0x3FFF] = rom.b(hl)
        vram.m[(de + 1) & 0x3FFF] = rom.b(hl + 1)
        hl += 2
        # 0x42E3 suma 0x40 SOLO a E: la cuenta da la vuelta dentro de la misma
        # pagina de 256 bytes, y por eso las tres parejas caen en 0x3A25,
        # 0x3A65 y 0x3AA5, las tres lineas de opciones
        de = (de & 0xFF00) | ((de + 0x40) & 0xFF)


# ==========================================================================
# LOS DIBUJOS DEL CAMPO (carga_los_dibujos_del_campo, 0x5E03)
# ==========================================================================
def carga_los_dibujos_del_campo(rom, v=None):
    """carga_los_dibujos_del_campo (0x5E03), orden a orden.

    Sube a la VRAM los patrones de todas las casillas del campo y sus colores.
    Casi todo entra por parejas tile/tile-girado (0x5FE2), que es como el
    cartucho se ahorra la mitad de los dibujos: la misma ficha vale para la
    ladera que sube y para la que va de lado.
    """
    v = Vram() if v is None else v
    v.abre(0x6008)                                        # 5E03: VRAM 0x2008
    hl = 0x603B
    guardado = hl
    for _ in range(10):                                   # 5E0D: tanda 1
        hl = pinta_el_guion_c_veces(rom, hl, v, 2)
    hl = guardado
    for _ in range(10):                                   # 5E17: tanda 2
        hl = pinta_el_guion_c_veces(rom, hl, v, 2)
    hl = pinta_guion_aqui(rom, hl, v)                     # 5E20
    guardado = hl
    replica_los_tercios(v, 0x2000, 0x2800)                # 5E2A
    hl = guardado
    v.abre(0x61A8)                                        # 5E2F
    pinta_el_tile_y_su_giro(rom, hl, v, 4, 4)             # 5E38
    v.abre(0x69A8)                                        # 5E3C
    hl = pinta_el_tile_y_su_giro(rom, guardado, v, 4, 4)  # 5E45
    de = 0x62A8                                           # 5E48
    for _ in range(2):                                    # 5E4D: tanda 3
        v.abre(de)
        hl = pinta_el_tile_y_su_giro(rom, 0x60EF, v, 2, 1)
        hl = pinta_guion_aqui(rom, hl, v)
        hl = pinta_el_tile_y_su_giro(rom, hl, v, 2, 1)
        hl = pinta_guion_aqui(rom, hl, v)
        de = 0x6AA8
    for _ in range(2):                                    # 5E6E: tanda 4
        hl = pinta_el_tile_y_su_giro(rom, 0x613E, v, 8, 1)
        hl = pinta_guion_aqui(rom, hl, v)
        hl = pinta_el_tile_y_su_giro(rom, hl, v, 8, 1)
        v.abre(0x7328)
    de = 0x6470                                           # 5E8A
    for _ in range(2):                                    # 5E8F: tanda 5
        v.abre(de)
        hl = pinta_el_tile_y_su_giro(rom, 0x61CD, v, 3, 1)
        hl = pinta_guion_aqui(rom, hl, v)
        hl = pinta_el_tile_y_su_giro(rom, hl, v, 2, 1)
        hl = pinta_guion_aqui(rom, hl, v)
        de = 0x6C70
    for _ in range(2):                                    # 5EB0: tanda 6
        hl = pinta_el_tile_y_su_giro(rom, 0x621B, v, 7, 1)
        hl = pinta_guion_aqui(rom, hl, v)
        v.abre(0x74F0)
    guardado = hl                                         # 5EC6
    hl = pinta_guion_de(rom, hl, v, 0x6E00)               # 5ECA
    hl = pinta_el_tile_y_su_giro(rom, hl, v, 1, 1)        # 5ED0
    hl = pinta_guion_de(rom, guardado, v, 0x7600)         # 5ED7
    hl = pinta_el_tile_y_su_giro(rom, hl, v, 1, 1)        # 5EDD
    hl = pinta_guion(rom, hl, v)                          # 5EE0

    de = 0x4008                                           # 5EE3: los colores
    for _ in range(3):                                    # 5EE8: un tercio
        pt = 0x62CD
        v.abre(de)
        for pt in (0x62CD, 0x62D2):
            for _ in range(10):
                pinta_guion_aqui(rom, pt, v)
        pinta_guion_aqui(rom, 0x62D7, v)
        de += 0x800
    v.abre(0x41A8)                                        # 5F12
    for _ in range(8):
        hl = pinta_guion_aqui(rom, 0x62EA, v)
    v.abre(0x49A8)                                        # 5F24
    for _ in range(8):
        hl = pinta_guion_aqui(rom, 0x62EA, v)
    hl = pinta_guion_aqui(rom, hl, v)                     # 5F36
    hl = pinta_guion_de(rom, 0x62F3, v, 0x42A8)           # 5F3F
    hl = pinta_guion_de(rom, hl, v, 0x4AF0)               # 5F45
    hl = pinta_guion_de(rom, 0x62FE, v, 0x52F0)           # 5F4E
    hl = pinta_guion_de(rom, 0x631D, v, 0x4470)           # 5F58
    hl = pinta_guion_de(rom, 0x631D, v, 0x4C70)           # 5F5F
    hl = pinta_guion_aqui(rom, hl, v)                     # 5F62
    de = 0x3FD0                                           # 5F65
    for _ in range(3):                                    # 5F6A: los tercios
        de += 0x800
        hl = pinta_guion_de(rom, 0x6354, v, de)
    hl = pinta_guion(rom, hl, v)                          # 5F79
    de = 0x5F50                                           # 5F7C
    for _ in range(3):                                    # 5F81: el marco
        de += 0x800
        hl = pinta_guion_de(rom, 0x6A45, v, de)
    v.abre(0x6580)                                        # 5F90
    hl = pinta_el_tile_y_su_giro(rom, hl, v, 7, 1)        # 5F99
    v.abre(0x6380)                                        # 5F9C
    hl = pinta_el_tile_y_su_giro(rom, 0x6A71, v, 7, 1)    # 5FA9
    v.abre(0x6400)                                        # 5FAC
    hl = pinta_el_tile_y_su_giro(rom, 0x6A71, v, 7, 1)    # 5FB6
    v.abre(0x6D80)                                        # 5FB9
    hl = pinta_el_tile_y_su_giro(rom, hl, v, 7, 1)        # 5FC2
    v.abre(0x7580)                                        # 5FC5
    hl = pinta_el_tile_y_su_giro(rom, hl, v, 8, 1)        # 5FCE
    pinta_guion(rom, hl, v)                               # 5FD1
    return v


def vram_del_juego(rom, golfista=True):
    """La VRAM tal como la deja el cartucho al empezar a jugar, siguiendo la
    misma cadena que el Z80:

      0x4093  INIT borra los 16 KB (el `ld a,e` de 0x409A siempre vale cero)
      0x40C3  la pantalla del titulo y sus cuatro guiones
      0x4196  menu_sale: borra la tabla de nombres y esconde los 32 sprites
      0x419C  el guion 0x47D1, que sube los patrones de sprite y sus atributos
      0x482E  carga_los_dibujos_del_campo
    """
    v = carga_el_titulo(rom, None)
    for i in range(0x300):                       # 0x430F
        v.m[0x3800 + i] = 0
    for i in range(0x80):                        # 0x43CC: 0xCF en los 32 sprites
        v.m[0x3B00 + i] = 0xCF
    pinta_guion(rom, 0x47D1, v)                  # 0x419C, parametro 0x419F
    carga_los_dibujos_del_campo(rom, v)          # 0x482E, encima de lo anterior
    pinta_guion(rom, 0x4D27, v)                  # 0x4841: la chapa 1P
    if golfista:
        # 0x4989 solo sube el monigote cuando 0xE144 esta puesto, o sea con la
        # bola en el tee: en una partida de verdad pasa en el hoyo 1 y ya se
        # queda para los ocho siguientes
        pinta_guion(rom, 0x7699, v)
    pinta_los_golpes_del_hoyo(v, 0)              # 0x4C7C: SHOT 00
    return v


def pinta_el_viento(vram, fuerza, direccion):
    """hoyo_siguiente_marcador (0x493E y 0x4949): los dos tiles del viento en la
    fila 3 del panel. La DIRECCION es el tile 0xCA mas 0..3, en la VRAM 0x387B
    (columna 27), y la FUERZA el tile 0xF0 mas 1..8, en la 0x387D (columna 29).

    Los dos valores los sortea 0x4932 con `ld a,r`, asi que no salen de la ROM:
    para comparar contra un volcado hay que darle los que ese volcado tenia en
    0xE104 (fuerza) y 0xE105 (direccion)."""
    vram.m[0x387B] = 0xCA + (direccion & 3)
    vram.m[0x387D] = 0xF0 | (fuerza & 0x0F)


def pinta_los_golpes_del_hoyo(vram, golpes, jugador=0):
    """pinta_los_golpes_del_hoyo (0x4C7C y 0x4C86): las dos cifras BCD de los
    golpes del hoyo (0xE106) en la VRAM 0x389D, y las del segundo en 0x38BD."""
    de = 0x389D + 0x20 * jugador
    vram.m[de] = 0xF0 | ((golpes >> 4) & 0x0F)
    vram.m[de + 1] = 0xF0 | (golpes & 0x0F)


# El guion 0x47D1 deja en la VRAM 0x3B40 los cuatro atributos de la bandera
# (sprites 16 a 19, escondidos con y = 0xCF), y 0x53EF le escribe al 16 la
# posicion que 0x53E5 saca de la tabla de 0x5BDC: esa es la bandera del plano.
SPRITE_DE_LA_BANDERA = 16


def dibuja_el_sprite(vram, vdp, px, w, k, x0, y0, esc, x, y):
    """Pinta el sprite k de 16x16 sobre una imagen ya montada, con el color de
    su atributo. Sirve para poner la bandera encima del plano."""
    at = vdp.sprite_attr + 4 * k
    pat, color = vram[at + 2], vram[at + 3] & 0x0F
    base = vdp.sprite_pat + (pat & 0xFC) * 8
    for cuarto in range(4):
        ox, oy = (cuarto // 2) * 8, (cuarto % 2) * 8
        for f in range(8):
            v = vram[(base + cuarto * 8 + f) & 0x3FFF]
            for c in range(8):
                if not (v >> (7 - c)) & 1:
                    continue
                for a in range(esc):
                    for b in range(esc):
                        ax = x0 + (x + ox + c) * esc + b
                        ay = y0 + (y + oy + f) * esc + a
                        if 0 <= ax < w and 0 <= ay and (ay * w + ax) * 3 + 3 <= len(px):
                            pon(px, w, ax, ay, PALETA[color])


# ==========================================================================
# LOS NUEVE HOYOS
# ==========================================================================
# Las dos tablas de punteros del hoyo. 0x5391 y 0x53A2 las indexan con el
# numero de hoyo POR DOS desde 0x79BA y 0x79CC, o sea que la entrada 0 no
# existe y el hoyo 1 esta en 0x79BC y 0x79CE.
CABECERAS = 0x79BA
REJILLAS = 0x79CC
FICHAS = 0x4D3F         # nueve fichas de 4 bytes: par y longitud en BCD
BANDERAS = 0x5BDC       # 0x53DA la indexa igual: el hoyo 1 esta en 0x5BDE
COLUMNA_BANDERA = 0x57A0   # 0x59BD la indexa con el hoyo, entrada 0 postiza

# Donde cae el plano del hoyo en la tabla de nombres. NO se supone: sale del
# 0x80 con que acaba la cabecera, y se comprueba en comprueba_los_hoyos.
PLANO_FILA, PLANO_COL, PLANO_ANCHO, PLANO_ALTO = 7, 22, 9, 16


def puntero(rom, tabla, hoyo):
    """Igual que 0x5394: el numero de hoyo por dos sobre la base de la tabla."""
    return rom.w(tabla + 2 * hoyo)


def pinta_el_hoyo(rom, hoyo, vram, rotulos=True):
    """El plano del hoyo, pintado por su CABECERA (0x79BC).

    La cabecera es un guion normal que escribe los rotulos de la columna de la
    derecha -HOLE, PAR, la longitud y el resto- y acaba en un 0x80 que
    recoloca el destino en 0x38F6; los bytes que siguen a ese 0x80 son la
    MISMA rejilla que 0x53B2 lee como datos. Por eso con una sola llamada sale
    el hoyo entero.
    """
    if hoyo != 1 and rotulos:
        # Solo la cabecera del hoyo 1 lleva los rotulos HOLE, PAR, WIND, SHOT
        # y la M de los metros (43 bytes); las otras ocho son de doce bytes y
        # se limitan a reescribir el par y las tres cifras de la longitud. Como
        # la partida siempre empieza por el hoyo 1, en pantalla los rotulos
        # siguen puestos: aqui se hace lo mismo.
        pinta_guion(rom, puntero(rom, CABECERAS, 1), vram)
    return pinta_guion(rom, puntero(rom, CABECERAS, hoyo), vram)


def monta_el_hoyo(rom, hoyo):
    """monta_el_hoyo (0x53A4): desgrana la rejilla del hoyo en 0xE200.

    Doce columnas por dieciocho filas. La primera tanda de relleno son 26
    bytes 0x31 -dos filas enteras y dos casillas mas-, y luego van tres por
    fila: la ultima columna de la de arriba y las dos primeras de la de abajo.
    Los dos `inc hl` de 0x53B8 se saltan la cabecera del guion la primera vez
    y los dos bytes `17 00` -las 23 celdas en blanco de la fila de nombres-
    todas las demas.
    """
    hl = puntero(rom, REJILLAS, hoyo)
    rejilla = bytearray()
    b, c = 0x1A, 0x10
    while True:
        rejilla += bytes([0x31]) * b
        hl += 2
        a = rom.b(hl)
        hl += 1
        if a & 0xF0:                       # 0x89: los nueve codigos tal cual
            rejilla += bytes(rom.d[hl - rom.org:hl - rom.org + 9])
            hl += 9
        else:                              # 0x09: el mismo codigo nueve veces
            n = rom.b(hl - 1)
            v = rom.b(hl)
            hl += 1
            rejilla += bytes([v]) * n
        b = 3
        c -= 1
        if c == 0:
            return rejilla


def rejilla_en_filas(rejilla):
    """Las 18 filas de 12 casillas. La ultima casilla no llega a escribirse
    (215 bytes de 216): el cartucho no la mira nunca."""
    r = bytearray(rejilla) + bytes(216 - len(rejilla))
    return [list(r[f * 12:(f + 1) * 12]) for f in range(18)]


def ficha_del_hoyo(rom, hoyo):
    """DATA_fichas_de_los_hoyos (0x4D3F): cuatro bytes por hoyo, con el par y
    la longitud en BCD de tres digitos y el byte alto primero. El cuarto
    nibble siempre es cero."""
    p = FICHAS + 4 * (hoyo - 1)
    par = rom.b(p) & 0x0F
    largo = ((rom.b(p + 1) >> 4) * 100 + (rom.b(p + 1) & 0x0F) * 10
             + (rom.b(p + 2) >> 4))
    return par, largo, rom.b(p + 3)


def bandera_del_hoyo(rom, hoyo):
    """DATA_banderas (0x5BDC + 2*hoyo): los dos bytes NO son casillas, son el
    atributo del sprite de la bandera: 0x53E5 le suma 0xA0 al primero para
    sacar la x y 0x53EB le suma 0x20 al segundo para sacar la y, y los manda
    a la VRAM 0x3B40. Devuelve (x, y) ya en pixeles de pantalla."""
    p = BANDERAS + 2 * hoyo
    return rom.b(p) + 0xA0, rom.b(p + 1) + 0x20


# ==========================================================================
# DIBUJO
# ==========================================================================
def celda(vram, vdp, t, tercio):
    """Los ocho pares (patron, color) de un tile en un tercio de pantalla."""
    pb = vdp.patrones + tercio * 0x800 + t * 8
    cb = vdp.colores + tercio * 0x800 + t * 8
    return [(vram[pb + f], vram[cb + f]) for f in range(8)]


def lienzo(w, h, color=FONDO):
    return bytearray(bytes(color) * (w * h))


def pon(px, w, x, y, color):
    px[(y * w + x) * 3:(y * w + x) * 3 + 3] = bytes(color)


def pinta_celdas(vram, vdp, celdas, esc=2, tercio_de=None, fondo=None):
    """Una rejilla de tiles como la lee el VDP en SCREEN 2."""
    alto, ancho = len(celdas), len(celdas[0])
    w, h = ancho * 8 * esc, alto * 8 * esc
    px = lienzo(w, h, (0, 0, 0))
    for fila in range(alto):
        tercio = 0 if tercio_de is None else tercio_de(fila)
        for col in range(ancho):
            t = celdas[fila][col]
            for f, (linea, color) in enumerate(celda(vram, vdp, t, tercio)):
                tinta = PALETA[color >> 4] if color >> 4 else (fondo or PALETA[0])
                papel = PALETA[color & 15] if color & 15 else (fondo or PALETA[0])
                for x in range(8):
                    c = tinta if (linea >> (7 - x)) & 1 else papel
                    for dy in range(esc):
                        for dx in range(esc):
                            pon(px, w, (col * 8 + x) * esc + dx,
                                (fila * 8 + f) * esc + dy, c)
    return w, h, px


def pantalla(vram, vdp, esc=2):
    """Las 24x32 celdas de la tabla de nombres, cada tercio con sus patrones."""
    celdas = [[vram[vdp.nombres + f * 32 + c] for c in range(32)]
              for f in range(24)]
    return pinta_celdas(vram, vdp, celdas, esc, lambda f: f // 8)


def recorte(vram, vdp, fila, col, alto, ancho, esc=3):
    """Un trozo de la pantalla, con el tercio que le toca a cada fila."""
    celdas = [[vram[vdp.nombres + (fila + f) * 32 + col + c] for c in range(ancho)]
              for f in range(alto)]
    return pinta_celdas(vram, vdp, celdas, esc, lambda f: (fila + f) // 8)


def hoja(vram, vdp, primero, ultimo, cols=16, esc=3, margen=1, tercio=0):
    """Los tiles de `primero` a `ultimo` en una rejilla, con su color."""
    n = ultimo - primero + 1
    filas = (n + cols - 1) // cols
    lado = 8 * esc + margen
    w, h = cols * lado + margen, filas * lado + margen
    px = lienzo(w, h, REJA)
    for k in range(n):
        gx, gy = margen + (k % cols) * lado, margen + (k // cols) * lado
        for f, (linea, color) in enumerate(celda(vram, vdp, primero + k, tercio)):
            tinta, papel = PALETA[color >> 4], PALETA[color & 15]
            if color == 0:
                tinta = papel = FONDO
            for c in range(8):
                col = tinta if (linea >> (7 - c)) & 1 else papel
                for a in range(esc):
                    for bq in range(esc):
                        pon(px, w, gx + c * esc + bq, gy + f * esc + a, col)
    return w, h, px


def hoja_sprites(vram, vdp, n, cols=8, esc=3, margen=2, base=None):
    """Los sprites de 16x16: cuatro patrones de 8x8, en el orden del VDP."""
    base = vdp.sprite_pat if base is None else base
    filas = (n + cols - 1) // cols
    lado = 16 * esc + margen
    w, h = cols * lado + margen, filas * lado + margen
    px = lienzo(w, h, REJA)
    for k in range(n):
        gx, gy = margen + (k % cols) * lado, margen + (k // cols) * lado
        for cuarto in range(4):
            ox, oy = (cuarto // 2) * 8, (cuarto % 2) * 8
            for f in range(8):
                v = vram[(base + k * 32 + cuarto * 8 + f) & 0x3FFF]
                for c in range(8):
                    col = PALETA[15] if (v >> (7 - c)) & 1 else FONDO
                    for a in range(esc):
                        for bq in range(esc):
                            pon(px, w, gx + (ox + c) * esc + bq,
                                gy + (oy + f) * esc + a, col)
    return w, h, px


def junta(trozos, sep=8, cols=None, fondo=SEPARA):
    """Pega imagenes en una rejilla, todas del mismo tamano."""
    cols = len(trozos) if cols is None else cols
    filas = (len(trozos) + cols - 1) // cols
    tw = max(t[0] for t in trozos)
    th = max(t[1] for t in trozos)
    w = cols * tw + sep * (cols + 1)
    h = filas * th + sep * (filas + 1)
    px = lienzo(w, h, fondo)
    for k, (aw, ah, ap) in enumerate(trozos):
        x0 = sep + (k % cols) * (tw + sep)
        y0 = sep + (k // cols) * (th + sep)
        for y in range(ah):
            px[((y0 + y) * w + x0) * 3:((y0 + y) * w + x0 + aw) * 3] = \
                ap[y * aw * 3:(y + 1) * aw * 3]
    return w, h, px


# ==========================================================================
# LOS BLOQUES DE LA VISTA (monta_la_vista, 0x5501)
# ==========================================================================
# La vista de la izquierda se monta en un lienzo de 20 columnas por 16 filas
# (0xE4C0) en cinco BANDAS de profundidad: la 1 es la mas lejana y ocupa dos
# filas, la 2 otras dos, y las 3, 4 y 5 cuatro cada una. Cada casilla de la
# rejilla se convierte en un bloque de CUATRO tiles de ancho por dos o cuatro
# de alto, elegido con dos tablas encadenadas.
BLOQUES_BAJOS = 0x79E0     # cinco punteros, uno por banda: codigos 0x01-0x28
BLOQUES_ALTOS = 0x7DF4     # los mismos cinco para los codigos 0x29 en adelante
BLOQUE_DEL_BORDE = 0x7DEA  # el codigo 0xC4 no pasa por ninguna tabla (0x5566)
CODIGO_DEL_TEE = 0xEA      # 0x5586 lo dobla al indice 11 de la segunda familia
FILA_DEL_LIENZO = 7        # 0x5D0B vuelca el lienzo a la VRAM 0x38E1


def bloque_de_la_casilla(rom, codigo, banda):
    """Donde esta el bloque de un codigo de casilla en una banda, siguiendo
    0x5556-0x5594: la primera tabla se indexa con (banda-1)*2 y la segunda con
    (codigo-1)*2, o con (codigo-0x28-1)*2 en la familia alta."""
    alto = 2 if banda <= 2 else 4
    if codigo == 0xC4:                          # 0x5562: el borde, suelto
        return BLOQUE_DEL_BORDE, alto
    if codigo < 0x29:                           # 0x556D
        tabla = rom.w(BLOQUES_BAJOS + 2 * (banda - 1))
        i = codigo
    else:
        tabla = rom.w(BLOQUES_ALTOS + 2 * (banda - 1))
        i = (codigo - 0x28) & 0xFF              # 0x5580
        if i == 0xC2:                           # 0x5582: el tee (0xEA)
            i -= 0xB7
    return rom.w(tabla + 2 * (i - 1)), alto


def dibuja_el_bloque(rom, p, alto):
    """Las filas de cuatro tiles de un bloque (0x5597-0x55E3): un byte no nulo
    abre una fila de cuatro tiles literales; un 0x00 es el atajo, y el byte que
    va detras se repite cuatro veces en DOS filas seguidas."""
    filas = []
    while len(filas) < alto:
        if rom.b(p):
            filas.append([rom.b(p + i) for i in range(4)])
            p += 4
        else:
            t = rom.b(p + 1)
            filas += [[t] * 4, [t] * 4]
            p += 2
    return filas[:alto]


def codigos_de_casilla(rom):
    """Los codigos que salen de verdad en las nueve rejillas, mas el borde."""
    vistos = set([0xC4])
    for h in range(1, 10):
        vistos |= set(monta_el_hoyo(rom, h))
    return sorted(vistos)


def hoja_de_bloques(rom, vram, vdp, codigos, esc=2, cols=9, margen=4):
    """Cada codigo de casilla dibujado a las CINCO distancias, una debajo de
    otra: es la columna que monta_la_vista pondria en el lienzo si todo el
    campo fuera de ese terreno. Cada fila usa el tercio de pantalla que le
    tocaria de verdad, porque 0x5D0B vuelca el lienzo a la VRAM 0x38E1 -fila 7,
    columna 1- y los tres tercios de este cartucho NO son iguales."""
    alto_tiles = 2 + 2 + 4 + 4 + 4
    aw, ah = 4 * 8 * esc, alto_tiles * 8 * esc
    filas = (len(codigos) + cols - 1) // cols
    w = cols * (aw + margen) + margen
    h = filas * (ah + margen) + margen
    px = lienzo(w, h, REJA)
    for k, cod in enumerate(codigos):
        gx = margen + (k % cols) * (aw + margen)
        gy = margen + (k // cols) * (ah + margen)
        y = 0
        for banda in range(1, 6):
            p, alto = bloque_de_la_casilla(rom, cod, banda)
            for f, fila in enumerate(dibuja_el_bloque(rom, p, alto)):
                for c, t in enumerate(fila):
                    tercio = (FILA_DEL_LIENZO + y + f) // 8
                    for l, (linea, color) in enumerate(
                            celda(vram, vdp, t, tercio)):
                        tinta = PALETA[color >> 4] if color >> 4 else FONDO
                        papel = PALETA[color & 15] if color & 15 else FONDO
                        for b in range(8):
                            col = tinta if (linea >> (7 - b)) & 1 else papel
                            for a in range(esc):
                                for e in range(esc):
                                    pon(px, w, gx + (c * 8 + b) * esc + e,
                                        gy + ((y + f) * 8 + l) * esc + a, col)
            y += alto
    return w, h, px


CUADROS_DEL_GOLFISTA = 0x78FF     # siete cuadros de 27 bytes: nueve sprites
                                  # de (y, x, patron) cada uno
GOLFISTA_Y, GOLFISTA_X = 0x70, 0x2C   # 0x4977: ld hl,0x2C70 / ld (0xE162),hl


def cuadros_del_golfista(rom):
    """Los siete cuadros del swing, tal como los arma pinta_al_golfista
    (0x5862): nueve sprites de tres bytes -y, x y numero de patron- a los que
    0x5883 y 0x5888 les suman la posicion de 0xE162/0xE163. Una y de 0xCF
    (0x587F) deja el sprite escondido y NO se le suma nada."""
    cuadros = []
    for k in range(7):
        p = CUADROS_DEL_GOLFISTA + 27 * k
        uno = []
        for i in range(9):
            y, x, pat = rom.b(p + 3 * i), rom.b(p + 3 * i + 1), rom.b(p + 3 * i + 2)
            uno.append((y if y == 0xCF else (y + GOLFISTA_Y) & 0xFF,
                        (x + GOLFISTA_X) & 0xFF, pat))
        cuadros.append(uno)
    return cuadros


def hoja_del_golfista(rom, vram, vdp, esc=3, margen=3):
    """Los siete cuadros del monigote, uno al lado de otro, con el color que
    el guion 0x7699 deja en los atributos de los sprites 1 a 9."""
    cuadros = cuadros_del_golfista(rom)
    visibles = [[s for s in c if s[0] != 0xCF] for c in cuadros]
    numero = [[n for n, s in enumerate(c) if s[0] != 0xCF] for c in cuadros]
    ys = [s[0] for c in visibles for s in c]
    xs = [s[1] for c in visibles for s in c]
    y0, y1 = min(ys), max(ys) + 16
    x0, x1 = min(xs), max(xs) + 16
    aw, ah = x1 - x0, y1 - y0
    w = 7 * (aw * esc + margen) + margen
    h = ah * esc + 2 * margen
    px = lienzo(w, h, FONDO)
    for k, cuadro in enumerate(visibles):
        gx = margen + k * (aw * esc + margen)
        # En el TMS9918 manda el sprite de numero MAS BAJO, asi que se pintan
        # del ultimo al primero para que el 1 quede encima
        for n, (y, x, pat) in reversed(list(enumerate(cuadro))):
            color = vram[vdp.sprite_attr + 4 * (numero[k][n] + 1) + 3] & 0x0F
            base = vdp.sprite_pat + (pat & 0xFC) * 8
            for cuarto in range(4):
                ox, oy = (cuarto // 2) * 8, (cuarto % 2) * 8
                for f in range(8):
                    v = vram[(base + cuarto * 8 + f) & 0x3FFF]
                    for c in range(8):
                        if not (v >> (7 - c)) & 1:
                            continue
                        for a in range(esc):
                            for b in range(esc):
                                ax = gx + (x - x0 + ox + c) * esc + b
                                ay = margen + (y - y0 + oy + f) * esc + a
                                if 0 <= ax < w and 0 <= ay < h:
                                    pon(px, w, ax, ay, PALETA[color])
    return w, h, px


# ==========================================================================
# LA COMPROBACION CONTRA LA VRAM DE VERDAD
# ==========================================================================
def lee_info(fn):
    d = {}
    for linea in open(fn, encoding="utf-8"):
        k, _, v = linea.strip().partition(" ")
        d[k] = v
    return d


def comprueba_la_rom(rom, vdp):
    """Las comprobaciones que no necesitan emulador, porque el propio cartucho
    guarda cada hoyo DOS veces y las dos lecturas tienen que coincidir:

    - el plano que sale de pintar la cabecera (0x79BC) como guion de VRAM tiene
      que ser, celda a celda, la rejilla que 0x53B2 desgrana de los MISMOS
      bytes leidos como datos (0x79CE);
    - la bandera, cuyo sitio sale de la tabla de sprites de 0x5BDC, tiene que
      caer en la columna que dice la tabla de 0x57A0 y sobre una casilla de
      green (0x29 o 0x2A);
    - las tres cifras que la cabecera escribe en la VRAM 0x385B tienen que ser
      la longitud que 0x4D3F copia en 0xE102.
    """
    mal = 0
    print("  hoyo  cabecera  rejilla  par  largo  plano=rejilla  bandera")
    for h in range(1, 10):
        v = Vram()
        pinta_el_hoyo(rom, h, v, rotulos=False)
        plano = [[v.m[vdp.nombres + (PLANO_FILA + f) * 32 + PLANO_COL + c]
                  for c in range(PLANO_ANCHO)] for f in range(PLANO_ALTO)]
        rejilla = rejilla_en_filas(monta_el_hoyo(rom, h))
        mismo = sum(1 for f in range(PLANO_ALTO) for c in range(PLANO_ANCHO)
                    if plano[f][c] != rejilla[2 + f][2 + c])
        par, largo, _ = ficha_del_hoyo(rom, h)
        x, y = bandera_del_hoyo(rom, h)
        # el plano empieza en la fila 7 y la columna 22 de la pantalla, y la
        # rejilla lleva dos filas y dos columnas de relleno por delante
        col = (x - PLANO_COL * 8) // 8 + 2
        fila = (y - PLANO_FILA * 8) // 8 + 2
        codigo = rejilla[fila][col]
        columna_ok = col == rom.b(COLUMNA_BANDERA + h)
        verde = codigo in (0x29, 0x2A)
        # las tres cifras de la longitud que la cabecera escribe en 0x385B
        cifras = [v.m[vdp.nombres + 0x5B + i] for i in range(3)]
        digitos = int("".join(str(c & 0x0F) for c in cifras))
        mal += mismo + (0 if columna_ok else 1) + (0 if verde else 1)             + (0 if digitos == largo else 1)
        print("   %d     0x%04X   0x%04X   %d   %3d m   %3d/144      "
              "columna %2d %s, casilla 0x%02X %s, cifras %d %s"
              % (h, puntero(rom, CABECERAS, h), puntero(rom, REJILLAS, h),
                 par, largo, PLANO_ALTO * PLANO_ANCHO - mismo, col,
                 "OK" if columna_ok else "MAL", codigo,
                 "GREEN" if verde else "NO ES GREEN", digitos,
                 "OK" if digitos == largo else "MAL"))
    pares = sum(ficha_del_hoyo(rom, h)[0] for h in range(1, 10))
    largos = sum(ficha_del_hoyo(rom, h)[1] for h in range(1, 10))
    print("  suma: par %d en %d m" % (pares, largos))
    return mal


def comprueba(rom, vdp, carpetas):
    """Compara byte a byte lo que monta este guion con la VRAM que openMSX
    vuelca (tools/omsx_vram.tcl y tools/omsx_vram_hoyo.tcl).

    De cada volcado se lee en que estaba el cartucho -0xE003 dice si la partida
    corre y 0xE100 que hoyo es- y se monta aqui ESE mismo instante. Las cifras
    que salgan son la prueba de que las imagenes no son una interpretacion.
    """
    import glob
    tot = {}
    print("  --- lo que se comprueba SIN emulador, de la ROM contra si misma ---")
    mal_rom = comprueba_la_rom(rom, vdp)
    print("  --- y ahora contra la VRAM de openMSX ---")

    def suma(k, mal, n):
        a, b = tot.get(k, (0, 0))
        tot[k] = (a + mal, b + n)

    def cuenta(real, mio, ini, fin):
        return sum(1 for x in range(ini, fin) if real[x] != mio[x]), fin - ini

    def nombres(real, mio, fila, col, alto, ancho):
        mal = 0
        for f in range(alto):
            for c in range(ancho):
                a = vdp.nombres + (fila + f) * 32 + col + c
                if real[a] != mio[a]:
                    mal += 1
        return mal, alto * ancho

    titulo = carga_el_titulo(rom)
    menu = Vram()
    menu.m[:] = titulo.m
    monta_la_pantalla_del_menu(rom, menu)
    pinta_el_cursor_del_menu(rom, menu, 0)
    def referencia(hoyo, rotulos=True, golfista=True):
        v = vram_del_juego(rom, golfista=golfista)
        pinta_el_hoyo(rom, hoyo, v, rotulos=rotulos)
        v.m[vdp.nombres + 0x1D] = 0xF0 | hoyo          # 0x4921
        x, y = bandera_del_hoyo(rom, hoyo)             # 0x53EF
        a = vdp.sprite_attr + 4 * SPRITE_DE_LA_BANDERA
        v.m[a], v.m[a + 1] = y, x
        return v

    # Los volcados de tools/omsx_vram_hoyo.tcl fuerzan 0xE100 ANTES del primer
    # monta_el_hoyo, o sea que en esas partidas el hoyo 1 no llega a jugarse y
    # no se pintan sus rotulos (HOLE, PAR, WIND, SHOT y la M). Para comparar
    # contra ESO hace falta la misma situacion.
    planos = {(h, r): referencia(h, rotulos=r) for h in range(1, 10)
              for r in (True, False)}

    tabla = list(rom.d[REGISTROS - rom.org:REGISTROS - rom.org + 8])
    vistos = saltados = 0
    for carpeta in carpetas:
        for fn in sorted(glob.glob(os.path.join(carpeta, "info_*.txt"))):
            d = lee_info(fn)
            v = fn.replace("info_", "vram_").replace(".txt", ".bin")
            if not os.path.exists(v):
                continue
            real = open(v, "rb").read()
            regs = [int(x, 16) for x in d["regs"].split()]
            if regs != tabla:
                # el cartucho aun no ha pasado por 0x40B0: no hay nada suyo
                saltados += 1
                continue
            vistos += 1
            suma("los ocho registros del VDP (0x447A)", 0, 8)
            if d.get("juego_en_marcha") == "0":
                # El titulo tiene una animacion -el rotulo sube de fila en fila
                # con 0x4110- y sus volcados no valen para comparar: solo se
                # miran los que ya son el menu, que se reconocen porque el
                # logotipo esta en su sitio (0x4354 deja el tile 0x40 en la
                # fila 4, columna 7) y el cursor en la primera opcion
                if not (real[vdp.nombres + 4 * 32 + 7] == 0x40
                        and real[vdp.nombres + 0x225] == 0xA1):
                    saltados += 1
                    continue
                suma("LA PANTALLA DEL MENU (24x32 celdas)",
                     *nombres(real, menu.m, 0, 0, 24, 32))
                suma("patrones del menu 0x2000-0x37FF",
                     *cuenta(real, menu.m, 0x2000, 0x3800))
                suma("colores del menu 0x0000-0x17FF",
                     *cuenta(real, menu.m, 0x0000, 0x1800))
                continue
            hoyo = int(d.get("hoyo", "0"))
            if not 1 <= hoyo <= 9:
                saltados += 1
                continue
            entero = not (d.get("etiqueta") == "hoyo" and hoyo != 1)
            mio = planos[(hoyo, entero)].m
            suma("patrones del campo 0x2000-0x37FF",
                 *cuenta(real, mio, 0x2000, 0x3800))
            suma("colores del campo 0x0000-0x17FF",
                 *cuenta(real, mio, 0x0000, 0x1800))
            # Los dos primeros patrones de sprite (0x1800-0x183F) son la bola
            # y su sombra, y 0x6C2F los redibuja mientras vuela, asi que no se
            # comparan. El resto si.
            for a, b in ((0x1840, 0x18C0), (0x1CC0, 0x2000)):
                suma("patrones de sprite 0x1840-0x18BF y 0x1CC0-0x1FFF",
                     *cuenta(real, mio, a, b))
            # El monigote (0x18C0-0x1CBF) solo se sube cuando 0xE144 esta
            # puesto, o sea con la bola en el tee (0x4983). En una partida de
            # verdad eso pasa en el hoyo 1 y los patrones se quedan; en los
            # volcados forzados depende del hoyo, asi que se comparan solo
            # cuando el cartucho los tenia cargados.
            if any(real[0x18C0:0x1CC0]):
                suma("EL MONIGOTE, patrones de sprite 0x18C0-0x1CBF",
                     *cuenta(real, vram_del_juego(rom).m, 0x18C0, 0x1CC0))
            # Sprite 16: la bandera del plano, que coloca 0x53EF
            suma("el sprite 16, la bandera del plano (y, x, patron, color)",
                 *cuenta(real, mio, 0x3B40, 0x3B44))
            suma("EL PLANO DEL HOYO (16x9 celdas)",
                 *nombres(real, mio, PLANO_FILA, PLANO_COL,
                          PLANO_ALTO, PLANO_ANCHO))
            # La cabecera: HOLE, PAR, la longitud, el VIENTO y SHOT. La fila
            # del viento la sortea 0x4932 con `ld a,r` y no sale de la ROM,
            # pero el volcado dice que salio (0xE104 y 0xE105): con eso se
            # pintan sus dos tiles igual que 0x493E y 0x4949 y la fila se
            # compara entera, como las otras cuatro.
            pinta_el_viento(planos[(hoyo, entero)],
                            int(d["viento"]), int(d["viento_dir"]))
            for fila in range(5):
                suma("la cabecera del hoyo (5 filas de 9 celdas)",
                     *nombres(real, mio, fila, 22, 1, 9))
            suma("la chapa 1P de la fila 0 (celdas 1 y 2)",
                 *nombres(real, mio, 0, 1, 1, 2))

    print("  %d volcados de openMSX comparados (%d saltados: el cartucho aun no"
          " habia programado el VDP o no habia hoyo)" % (vistos, saltados))
    peor = suma_mal = suma_n = 0
    for k in sorted(tot):
        mal, n = tot[k]
        peor = max(peor, mal)
        suma_mal += mal
        suma_n += n
        print("  %-44s %6d / %-7d bytes distintos" % (k, mal, n))
    # La cifra que se publica: cuanto se ha comparado de verdad contra el
    # emulador. Se imprime contada, no escrita a ojo en ningun sitio.
    print("  %-44s %6d / %-7d EN TOTAL" % ("", suma_mal, suma_n))
    return 0 if peor == 0 and mal_rom == 0 else 1


# ==========================================================================
def main(argv):
    if len(argv) < 4:
        return print(__doc__) or 2
    if argv[1] == "--comprueba":
        rom = Rom(open(argv[2], "rb").read(), int(argv[3], 0))
        return comprueba(rom, Vdp(rom.d, rom.org), argv[4:])
    rom = Rom(open(argv[1], "rb").read(), int(argv[2], 0))
    salida = argv[3]
    vdp = Vdp(rom.d, rom.org)
    os.makedirs(salida, exist_ok=True)

    def guarda(nombre, imagen, que):
        w, h, px = imagen
        png(w, h, px, os.path.join(salida, nombre))
        print("  %-18s %4dx%-4d  %s" % (nombre, w, h, que))

    print("VDP: nombres 0x%04X patrones 0x%04X colores 0x%04X sprites 0x%04X/0x%04X"
          % (vdp.nombres, vdp.patrones, vdp.colores, vdp.sprite_pat,
             vdp.sprite_attr))

    # --- el titulo y el menu ---------------------------------------------
    titulo = carga_el_titulo(rom, vdp)
    menu = Vram()
    menu.m[:] = titulo.m
    monta_la_pantalla_del_menu(rom, menu)
    pinta_el_cursor_del_menu(rom, menu, 0)
    guarda("titulo.png", pantalla(menu.m, vdp, 2),
           "la pantalla del menu entera")
    # 0x4354 deja el logotipo en las filas 4 y 5, columnas 7 a 25; se recorta
    # con una fila y una columna de margen a cada lado, que estan en blanco
    guarda("rotulo.png", recorte(menu.m, vdp, 3, 6, 4, 21, 6),
           "el logotipo: los 38 tiles 0x40-0x65")

    # --- los nueve campos -------------------------------------------------
    juego = vram_del_juego(rom)
    guarda("tiles.png", hoja(juego.m, vdp, 0x00, 0xFF, 16, 3),
           "los 256 tiles del campo, con su color")
    guarda("sprites.png", hoja_sprites(juego.m, vdp, 32, 8, 3),
           "los 32 sprites de 16x16 que hay cargados al empezar")
    planos = []
    for hoyo in range(1, 10):
        v = Vram()
        v.m[:] = juego.m
        pinta_el_hoyo(rom, hoyo, v)
        # 0x4921: el numero de hoyo es el tile 0xF0 mas el numero
        v.m[vdp.nombres + 0x1D] = 0xF0 | hoyo
        # 0x53EF: la posicion de la bandera va al sprite 8
        x, y = bandera_del_hoyo(rom, hoyo)
        a = vdp.sprite_attr + 4 * SPRITE_DE_LA_BANDERA
        v.m[a], v.m[a + 1] = y, x
        esc = 4
        w, h, px = recorte(v.m, vdp, 0, 22, 23, 9, esc)
        # el sprite se dibuja donde manda su atributo, descontando el recorte
        dibuja_el_sprite(v.m, vdp, px, w, SPRITE_DE_LA_BANDERA, 0, 0, esc,
                         x - 22 * 8, y + 1)
        planos.append((w, h, px))
        guarda("campo_%d.png" % hoyo, planos[-1],
               "hoyo %d, par %d, %d m" % ((hoyo,) + ficha_del_hoyo(rom, hoyo)[:2]))
    guarda("hoyos.png", junta(planos, 10, 5), "los nueve hoyos juntos")

    # --- lo demas ---------------------------------------------------------
    # La fuente se dibuja de la VRAM DEL MENU: al empezar la partida, el campo
    # reaprovecha los tiles 0xB0-0xBD -el final de la letra pequena, la de los
    # rotulos del menu- y de la letra grande solo se lleva el 0xEA. Lo demas
    # (0xD1-0xE9 y las cifras 0xF0-0xF9) dura toda la partida.
    guarda("fuente.png", hoja(menu.m, vdp, 0xA0, 0xFF, 16, 4),
           "los 96 tiles de texto: las dos letras, las cifras y las flechas")
    guarda("golfista.png", hoja_del_golfista(rom, juego.m, vdp),
           "los siete cuadros del swing (0x78FF), montados como 0x5862")
    codigos = codigos_de_casilla(rom)
    guarda("bloques.png", hoja_de_bloques(rom, juego.m, vdp, codigos),
           "los %d codigos de casilla, cada uno a las cinco distancias"
           % len(codigos))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
