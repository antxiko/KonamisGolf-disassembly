#!/usr/bin/env python3
"""Mete en el .notes los comentarios que las tandas dejaron en work/coment/.

Cada tanda es un fichero de lineas `C 0xADDR texto` (y `B 0xADDR texto`) que se
escribio APARTE, contra un tramo de direcciones, para poder repartir el trabajo
sin que dos manos se pisen el mismo fichero. Esto los junta, los valida contra
el listado y los deja en el .notes, que es de donde se genera el .asm.

Lo que se rechaza, y por que:
  - direccion que no es el principio de una instruccion del .asm: un comentario
    de linea colgado de un `defb` no sale por ninguna parte
  - direccion que ya tiene comentario en el .notes: lo escrito a mano manda
  - direcciones repetidas entre tandas: se queda la primera
  - lineas con caracteres no ASCII: el .notes es ASCII a proposito

Uso: aplica_comentarios.py <asm> <notes> <work/coment> [--escribe]
Sin --escribe solo dice lo que haria.
"""
import glob
import os
import re
import sys


def direcciones_del_asm(asm):
    """Las direcciones que son principio de instruccion, con su texto."""
    d = {}
    for ln in open(asm, encoding="utf-8").read().splitlines():
        m = re.match(r"^\t(.*?);([0-9a-f]{4})(.*)$", ln)
        if m:
            d[int(m.group(2), 16)] = m.group(1).strip()
    return d


def main(argv):
    if len(argv) < 4:
        return print(__doc__) or 2
    asm, notes, carpeta = argv[1:4]
    escribe = "--escribe" in argv

    instr = direcciones_del_asm(asm)
    texto = open(notes, encoding="utf-8").read()
    ya = set()
    for ln in texto.splitlines():
        m = re.match(r"^C (0x[0-9a-fA-F]{4}) ", ln)
        if m:
            ya.add(int(m.group(1), 16))

    nuevas, visto = [], set()
    n_fuera = n_ya = n_dup = n_mal = 0
    for fn in sorted(glob.glob(os.path.join(carpeta, "*.notes"))):
        cuenta = 0
        for ln in open(fn, encoding="utf-8").read().splitlines():
            ln = ln.rstrip()
            m = re.match(r"^([CB]) (0x[0-9a-fA-F]{4}) +(.+)$", ln)
            if not m:
                continue
            try:
                ln.encode("ascii")
            except UnicodeEncodeError:
                n_mal += 1
                continue
            dire, cuerpo = int(m.group(2), 16), m.group(3)
            if m.group(1) == "C":
                if dire not in instr:
                    n_fuera += 1
                    continue
                if dire in ya:
                    n_ya += 1
                    continue
                if dire in visto:
                    n_dup += 1
                    continue
                visto.add(dire)
            nuevas.append("%s 0x%04x %s" % (m.group(1), dire, cuerpo))
            cuenta += 1
        print("  %-28s %4d" % (os.path.basename(fn), cuenta))

    print("  ---- %d lineas nuevas" % len(nuevas))
    for n, q in (("no son instruccion", n_fuera), ("ya comentadas", n_ya),
                 ("repetidas entre tandas", n_dup), ("con acentos", n_mal)):
        if q:
            print("  ---- %d descartadas: %s" % (q, n))

    if not escribe:
        print("  (en seco: pasa --escribe para dejarlo en el .notes)")
        return 0

    cabecera = ("\n\n# ======================================================"
                "================\n# COMENTARIOS DE LINEA\n"
                "# ======================================================"
                "================\n")
    with open(notes, "a", encoding="utf-8", newline="\n") as f:
        f.write(cabecera + "\n".join(nuevas) + "\n")
    print("  escritas en %s" % notes)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
