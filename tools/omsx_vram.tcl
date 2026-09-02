# omsx_vram.tcl - Vuelca la VRAM de verdad de Konami's Golf para comprobar los PNG.
#
# Para que sirve: tools/graficos.py monta las imagenes de la web ejecutando en
# Python los pasos del cartucho (el interprete de guiones 0x4380, la carga de
# dibujos del campo 0x5E03 y el desgranado de la rejilla 0x53B2). Mirar el
# dibujo no basta: hay que comparar sus bytes con los que el VDP tiene de
# verdad. Esto deja correr el juego y en varios instantes vuelca los 16 KB de
# VRAM, los ocho registros del VDP y las variables que dicen QUE se estaba
# dibujando (sobre todo 0xE100, el hoyo, y 0xE012, el modo).
#
# No pone NINGUN punto de ruptura: los volcados van por reloj emulado, que es
# lo unico que no ahoga al emulador.
#
# Variables de entorno:
#   GOLF_SALIDA  carpeta de salida (por defecto work/omsx)
#
#   "C:/Program Files/openMSX/openmsx.exe" -machine Philips_VG_8020 \
#       -cart golf.rom -script tools/omsx_vram.tcl

proc opcion {nombre porDefecto} {
    global env
    if {[info exists env($nombre)]} { return $env($nombre) }
    return $porDefecto
}

set ::SALIDA [opcion GOLF_SALIDA {C:/Users/Antxiko/Documents/DES_ASM/GOLF_DISAM/work/omsx}]
file mkdir $::SALIDA
set ::n 0

proc vuelca {etiqueta} {
    set i [format %02d $::n]
    incr ::n
    # los 16 KB de VRAM tal cual los ve el VDP
    set datos [debug read_block VRAM 0 16384]
    set f [open $::SALIDA/vram_$i.bin w]
    fconfigure $f -translation binary
    puts -nonewline $f $datos
    close $f
    # los ocho registros, que dicen donde esta cada tabla
    set r {}
    for {set k 0} {$k < 8} {incr k} {
        lappend r [format %02X [debug read {VDP regs} $k]]
    }
    set f [open $::SALIDA/info_$i.txt w]
    puts $f [format {etiqueta %s} $etiqueta]
    puts $f [format {tiempo %s} [machine_info time]]
    puts $f [format {regs %s} [join $r { }]]
    foreach {nombre dir} {contador 0xE000 reloj 0xE001 sin_juego 0xE002
                          juego_en_marcha 0xE003 opcion 0xE00A modo 0xE012
                          hoyo 0xE100 par 0xE101 largo_alto 0xE102
                          largo_bajo 0xE103 viento 0xE104 viento_dir 0xE105
                          golpes 0xE106 estado 0xE122 dibujando 0xE129
                          columna_bola 0xE130 fila_bola 0xE131} {
        puts $f [format {%s %d} $nombre [debug read memory $dir]]
    }
    close $f
    catch { screenshot -raw $::SALIDA/pant_$i.png }
}

# --- la barra de espacio, para elegir en el menu ---------------------------
proc pulsa {} {
    keymatrixdown 8 0x01
    after time 0.3 suelta
}
proc suelta {} {
    keymatrixup 8 0x01
}

# --- calendario -------------------------------------------------------------
# El titulo dura unos segundos y despues sale el menu; si nadie toca nada, el
# reloj de 0xE001 se agota en 0x4172 y la partida arranca sola. Con eso basta:
# no hace falta jugar para que la VRAM tenga los dibujos del campo y el plano
# del hoyo.
after time  7.0 { vuelca titulo }
after time  9.0 { vuelca titulo }
after time 10.5 { vuelca menu }
after time 11.5 { vuelca menu }
after time 12.5 { vuelca menu }
after time 13.5 { vuelca menu }
after time 14.5 { vuelca menu }
after time 16.0 { vuelca juego }
after time 24.0 { vuelca juego }
after time 34.0 { vuelca juego }
after time 44.0 { vuelca juego }
after time 54.0 { vuelca juego }
after time 56.0 { exit }

# perro guardian de tiempo REAL: un guion roto no puede colgar el emulador
after realtime 240 {
    puts {PERRO GUARDIAN a los 240 s reales}
    exit
}
