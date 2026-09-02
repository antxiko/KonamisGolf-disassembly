# omsx_vram_hoyo.tcl - Vuelca la VRAM de un hoyo CONCRETO de Konami's Golf.
#
# La partida siempre empieza por el hoyo 1, asi que para comprobar los otros
# ocho planos hay que llevar al cartucho hasta ellos. En vez de jugarse nueve
# hoyos, esto pone UN SOLO punto de ruptura en monta_el_hoyo (0x538E) que, la
# primera vez que salta, escribe en 0xE100 el hoyo que se le pida y se quita.
# Como 0x5391 y 0x53A2 sacan de ahi los dos punteros, y 0x4902 y 0x4921 sacan
# de ahi el par, la longitud y el numero del rotulo, el cartucho dibuja ese
# hoyo como si le tocara. El punto de ruptura salta UNA vez, no cada cuadro.
#
# Variables de entorno:
#   GOLF_HOYO    el hoyo, de 1 a 9
#   GOLF_SALIDA  carpeta de salida
#
#   "C:/Program Files/openMSX/openmsx.exe" -machine Philips_VG_8020 \
#       -cart golf.rom -script tools/omsx_vram_hoyo.tcl

proc opcion {nombre porDefecto} {
    global env
    if {[info exists env($nombre)]} { return $env($nombre) }
    return $porDefecto
}

set ::SALIDA [opcion GOLF_SALIDA {C:/Users/Antxiko/Documents/DES_ASM/GOLF_DISAM/work/omsx}]
set ::HOYO [opcion GOLF_HOYO 1]
file mkdir $::SALIDA
set ::n 0
set ::puesto 0

proc vuelca {etiqueta} {
    set i [format {h%sd%02d} $::HOYO $::n]
    incr ::n
    set datos [debug read_block VRAM 0 16384]
    set f [open $::SALIDA/vram_$i.bin w]
    fconfigure $f -translation binary
    puts -nonewline $f $datos
    close $f
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

# El punto de ruptura: salta la primera vez que el cartucho va a montar un
# hoyo, cambia el numero y se borra. Nada de condiciones por cuadro.
set ::bp [debug set_bp 0x538E {} {
    if {$::puesto == 0} {
        set ::puesto 1
        debug write memory 0xE100 $::HOYO
        debug remove_bp $::bp
    }
}]

after time 17.0 { vuelca hoyo }
after time 19.0 { vuelca hoyo }
after time 20.0 { exit }

after realtime 180 {
    puts {PERRO GUARDIAN a los 180 s reales}
    exit
}
