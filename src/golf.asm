; ==========================================================================
; KONAMI'S GOLF - Konami - MSX1 - cartucho RC-723 de 16 KB en la pagina 1
; ==========================================================================
; Generado por tools/mkasm.py a partir del trazado de flujo real.
; Los comentarios provienen de tools/../src/*.notes y estan anclados a
; direccion, de modo que sobreviven a un retrazado.
; ==========================================================================

	org 0x04000


; ----------------------------------------------------------------------
; DATOS cabecera_del_cartucho: La AB de la BIOS y sus cinco punteros: solo
;   declara INIT, y lo pone en 0x4053; STATEMENT, DEVICE, TEXT y las dos
;   reservas van a cero
;   0x4000..0x4010  (16 bytes)
DATA_cabecera_del_cartucho:
	defb 041h,042h,053h,040h	; 4000
	defb 000h,000h,000h,000h	; 4004
	defb 000h,000h,000h,000h	; 4008
	defb 000h,000h,000h,000h	; 400c

; ======================================================================
; CODIGO 0x4010..0x40c6  (182 bytes)
; ======================================================================


interrupcion:		; Un cuadro del juego; lo engancha INIT en H.KEYI
	call 0013eh		;4010   ; BIOS RDVDP - Reads VDP status register
	ld hl,0e01dh		;4013   ; 0xE01D es el aviso de que la interrupcion ha tocado el VDP
	ld (hl),001h		;4016
	inc hl			;4018
	ld a,(hl)			;4019   ; 0xE01E lo levanta el programa principal mientras le da una direccion al VDP
	or a			;401a
	ret nz			;401b   ; y si esta a medias, este cuadro se pierde entero
	ld l,a			;401c   ; A vale cero: HL baja a 0xE000, el contador de cuadros
	inc (hl)			;401d   ; sube un cuadro
	ld a,(hl)			;401e
	and 01fh		;401f   ; uno de cada treinta y dos
	jr nz,interrupcion_baja_el_reloj		;4021
	inc hl			;4023
	dec (hl)			;4024   ; baja el reloj de 0xE001, el que espera 0x434B
interrupcion_baja_el_reloj:		; Cada 32 cuadros baja el reloj de 0xE001, el que esperan 0x434B y el menu. OJO: el `ld l,a` de 0x401C entra con A=0 -viene de un `or a` que dio Z-, asi que HL queda en 0xE000 y el `dec (hl)` de 0x4024 cae en 0xE001, no en 0xE01F
	call lee_el_mando_del_menu		;4025   ; el mando del menu se lee siempre, incluso con el juego corriendo
	ld a,(0e002h)		;4028   ; 0xE002 vale uno en el modo de exhibicion: entonces ni mandos ni sonido
	or a			;402b
	jr nz,interrupcion_toca_el_juego		;402c
	call lee_los_mandos		;402e
	call corre_el_sonido		;4031   ; un paso del reproductor por cuadro
	di			;4034
interrupcion_toca_el_juego:		; Si 0xE003 esta puesto, corre un paso del juego con 0x4F37
	ld a,(0e003h)		;4035   ; 0xE003 solo esta puesto mientras se esta jugando un hoyo
	or a			;4038
	jr z,interrupcion_rearma		;4039
	ld a,(0e014h)		;403b   ; 0xE014 es el pestillo contra la reentrada: 0x4F37 lo baja nada mas empezar
	or a			;403e
	ret z			;403f   ; si el cuadro anterior sigue vivo, este se salta
	call un_cuadro_del_juego		;4040
interrupcion_rearma:		; Deja 0xE01D y 0xE014 a uno y vuelve a entrar si el VDP dice que hay otra interrupcion pendiente
	ld a,001h		;4043
	ld (0e01dh),a		;4045   ; deja dicho que el VDP ha cambiado de manos, para que 0x4403 repita la direccion
	ld (0e014h),a		;4048   ; y vuelve a armar el pestillo del cuadro
	call 0013eh		;404b   ; BIOS RDVDP - Reads VDP status register
	rlca			;404e   ; el bit 7 del estado del VDP: hay otra interrupcion esperando
	jp c,interrupcion		;404f   ; el cuadro perdido se corre entero aqui mismo, sin salir de la interrupcion
	ret			;4052
init:		; Engancha la interrupcion en 0x4010, limpia la RAM y arranca
	di			;4053
	ld hl,0fd9ah		;4054
	ld (hl),0c3h		;4057   ; pone un jp en H.KEYI (0xFD9A)
	ld hl,interrupcion		;4059   ; y detras la direccion del manejador
	ld (0fd9bh),hl		;405c
	ld hl,0e000h		;405f
	ld de,0e001h		;4062
	ld bc,007feh		;4065   ; borra los 0x7FE bytes de 0xE000 a 0xE7FF
	ld (hl),l			;4068   ; L vale cero: el relleno es un cero
	ldir		;4069
	ld sp,hl			;406b   ; la pila queda justo debajo de lo borrado
	ld a,0b8h		;406c   ; 0xB8 en el mezclador del PSG: los tres tonos abiertos y el ruido cerrado
	ld (0e660h),a		;406e
	call escribe_el_mezclador		;4071
	ld a,008h		;4074   ; los registros 8, 9 y 10 del PSG son los tres volumenes
	ld e,000h		;4076
	ld b,003h		;4078
init_calla_el_psg:		; Pone a cero los registros 8, 9 y 10 del PSG, o sea los tres volumenes
	call 00093h		;407a   ; BIOS WRTPSG - Writes data to PSG-register
	inc a			;407d
	djnz init_calla_el_psg		;407e
	ld de,081a2h		;4080   ; sin identificar: deja el VDP apuntando a la VRAM 0x01A2 y no escribe nada
	call abre_la_vram_para_escribir_2		;4083
	ld a,00fh		;4086
	ld e,0cfh		;4088   ; 0xCF en el registro 15 del PSG: deja el puerto de mandos 1 en lectura
	call 00093h		;408a   ; BIOS WRTPSG - Writes data to PSG-register
	call 00132h		;408d   ; BIOS CHGCAP - Alternates the CAPS lamp status
	im 1		;4090   ; modo 1 de interrupcion: la BIOS acaba saltando al jp que init ha puesto en H.KEYI
	di			;4092
	ld de,04000h		;4093   ; el 0x40 sirve dos veces: es la VRAM 0x0000 para escribir y las 64 tandas del borrado
	call abre_la_vram_para_escribir_2		;4096
init_borra_la_vram:		; Pone a CERO los 16 KB de VRAM: 0x4093 deja DE en 0x4000 y E no se toca en todo el bucle, asi que las 64 tandas de 256 bytes escriben ceros
	ld b,e			;4099   ; E vale cero, o sea 256 bytes por tanda
	ld a,e			;409a   ; y el byte de relleno tambien es cero
	call rellena_con_a		;409b
	dec d			;409e   ; sesenta y cuatro tandas: los 16 KB enteros de VRAM a cero
	jr nz,init_borra_la_vram		;409f
	call 00096h		;40a1   ; BIOS RDPSG - Reads value from PSG-register
	ld a,001h		;40a4
	ld (0e01eh),a		;40a6   ; levanta 0xE01E para que la interrupcion no toque el VDP mientras se programa
	ld hl,0447ah		;40a9   ; los ocho valores de R0 a R7 estan en 0x447A
	ld d,008h		;40ac
	ld c,000h		;40ae   ; empieza por el registro 0
init_programa_el_vdp:		; Mete los ocho valores de 0x447A en los registros 0 a 7
	ld b,(hl)			;40b0
	call 00047h		;40b1   ; BIOS WRTVDP - Writes data in the VDP-register
	inc hl			;40b4
	inc c			;40b5
	dec d			;40b6
	jr nz,init_programa_el_vdp		;40b7
	xor a			;40b9
	ld (0e01eh),a		;40ba   ; baja 0xE01E: el VDP ya esta programado
	ei			;40bd
	ld a,001h		;40be   ; un tic del reloj de 0xE001, o sea treinta y dos cuadros
	call espera_al_reloj		;40c0
	call lee_parametro		;40c3   ; la pantalla del titulo, con el guion de 0x44E9 que va detras del propio call

; ----------------------------------------------------------------------
; DATOS parametro_40c6: Parametro en linea del call de 0x40C3: apunta a 0x44E9
;   0x40c6..0x40c8  (2 bytes)
DATA_parametro_40c6:
	defw 044e9h	; 40c6  -> DATA_guion_pantalla_de_titulo

; ======================================================================
; CODIGO 0x40c8..0x40d7  (15 bytes)
; ======================================================================


titulo_pinta_cola_1:		; Manda la cola del guion del titulo (0x4703) a la VRAM 0x2680
	ld de,06680h		;40c8   ; VRAM 0x2680: el abecedario en los tiles 0xD0 en adelante, el de KONAMI 1985 y el panel
	ld hl,04703h		;40cb
	call abre_la_vram_para_escribir_2		;40ce
	call pinta_guion_aqui		;40d1
	call lee_parametro		;40d4   ; y ahora los colores del rotulo, con el guion de 0x4782

; ----------------------------------------------------------------------
; DATOS parametro_40d7: Parametro en linea del call de 0x40D4: apunta a 0x4782
;   0x40d7..0x40d9  (2 bytes)
DATA_parametro_40d7:
	defw 04782h	; 40d7  -> DATA_guion_colores_del_titulo

; ======================================================================
; CODIGO 0x40d9..0x419f  (198 bytes)
; ======================================================================


titulo_pinta_cola_2:		; Manda la otra cola (0x46B0) a la VRAM 0x2780, replica los tercios de patrones y colores con 0x4322 y arranca el bucle del titulo. El `ldir` de 0x40FC escribe en 0x4110, que es la propia ROM: no hace nada
	ld de,06780h		;40d9   ; VRAM 0x2780: las diez cifras, tiles 0xF0 a 0xF9
	call abre_la_vram_para_escribir_2		;40dc
	ld hl,046b0h		;40df   ; el mismo guion de letras acaba repintandose en 0x2528, tiles 0xA5 en adelante: dos abecedarios iguales de dos colores
	call pinta_guion_aqui		;40e2
	ld de,00000h		;40e5   ; los colores, del tercio 0 al 1
	ld hl,04800h		;40e8   ; el destino va 0x800 por delante del origen: la segunda mitad copia lo que acaba de escribir la primera
	call replica_los_tercios		;40eb
	ld de,02000h		;40ee   ; y lo mismo con los patrones
	ld hl,06800h		;40f1
	call replica_los_tercios		;40f4
	ld de,titulo_espera		;40f7   ; el destino del ldir es 0x4110, o sea la propia ROM del cartucho
	ld c,050h		;40fa
	ldir		;40fc   ; asi que estos ochenta bytes no cambian nada
	ld a,008h		;40fe   ; ocho tics de treinta y dos cuadros: el rotulo dura unos cinco segundos
	ld (0e001h),a		;4100
	ei			;4103
	ld a,(0e006h)		;4104   ; 0xE006 no aparece escrito en ningun otro sitio del listado: este salto no llega a tomarse
	or a			;4107
	jr nz,titulo_al_menu		;4108
	ld hl,07a8bh		;410a   ; el rotulo de KONAMI arranca en la fila 20, columna 11 de la tabla de nombres
	ld (0e020h),hl		;410d   ; 0xE020 guarda la direccion de VRAM de su fila de arriba
titulo_espera:		; El bucle del titulo: cada cuatro cuadros sube el logotipo de la casa una fila de la tabla de nombres -ocho pixeles- y espera a que alguien pulse o a que se agote el reloj
	ld hl,0e000h		;4110
	ld a,(hl)			;4113
	and 003h		;4114   ; solo se mueve cuando el contador de cuadros es multiplo de cuatro
	jr nz,titulo_cuenta_atras		;4116
	inc (hl)			;4118   ; y lo adelanta dos, para que no le vuelva a tocar enseguida
	inc (hl)			;4119
	ld de,(0e020h)		;411a   ; donde esta ahora la fila de arriba del rotulo
	ld hl,0786bh		;411e   ; el tope es la VRAM 0x386B: fila 3, columna 11
	xor a			;4121
	sbc hl,de		;4122   ; arriba del todo deja de subir y solo cuenta el tiempo
	jr z,titulo_mira_si_sigue		;4124
	di			;4126

; ----------------------------------------------------------------------
; ----- El rotulo son veintiseis tiles correlativos repartidos en tres filas -----
; ----------------------------------------------------------------------
	xor a			;4127   ; empieza por el tile 0x00
	ld b,003h		;4128   ; tres tiles en la fila de arriba: la punta de la K
	call pinta_tiles_correlativos		;412a
	ld b,00bh		;412d   ; once en la de en medio
	call pinta_tiles_correlativos		;412f
	ld b,00ch		;4132   ; doce en la de abajo, hasta el tile 0x19
	call pinta_tiles_correlativos		;4134
	ld b,00ch		;4137   ; y borra los doce de la cuarta fila, la que el rotulo acaba de dejar al subir
	call abre_la_vram_para_escribir_2		;4139
	xor a			;413c   ; el xor a no llega a usarse: 0x4463 rellena con C, no con A
	call rellena_vram_con_c_2		;413d
	ei			;4140
	ld hl,0e020h		;4141
	ld a,(hl)			;4144
	sub 020h		;4145   ; sube una fila entera, treinta y dos tiles
	ld (hl),a			;4147
	jr nc,titulo_mira_si_sigue		;4148
	inc hl			;414a
	dec (hl)			;414b   ; con su prestamo en el byte alto de la direccion
titulo_mira_si_sigue:		; Sale del bucle si 0xE001 se ha agotado
	ld a,(0e001h)		;414c   ; cuando el reloj de 0xE001 se agota, al menu
	or a			;414f
	jr z,titulo_al_menu		;4150
titulo_cuenta_atras:		; Deja correr el rotulo mientras los seis bits bajos de 0xE005 no lleguen a cero
	ld a,(0e005h)		;4152
	and 03fh		;4155   ; cualquier direccion o disparo corta el rotulo
	jr z,titulo_espera		;4157
titulo_al_menu:		; Borra la pantalla, pinta el cursor del menu y se queda esperando la eleccion
	di			;4159
	call monta_la_pantalla_del_menu		;415a
	call pinta_el_cursor_del_menu		;415d
	ld a,008h		;4160   ; otros 256 cuadros para elegir; si se agotan, arranca la exhibicion
	ld (0e001h),a		;4162
	ei			;4165
menu_espera:		; Lee el mando; con el disparo del joystick, el ESPACIO o SELECT sale por 0x417B, y si no repite mientras quede tiempo. Deja 0xE002 a 1 en cada vuelta -el modo de exhibicion es lo que hay por omision- y solo a 0 cuando caza la pulsacion. Las teclas salen de 0x42A6, que mira los bits 4 y 5: el 4 es el espacio, de la fila 8, y el 5 el bit 6 de la fila 7, que es SELECT
	call mueve_el_menu		;4166
	ld hl,0e002h		;4169
	ld (hl),000h		;416c   ; 0xE002 a cero: partida de verdad
	jr c,menu_elegido		;416e   ; el acarreo que devuelve 0x4296 es el disparo: hay opcion elegida
	ld (hl),001h		;4170   ; mientras nadie elija, 0xE002 se queda a uno: modo de exhibicion
	ld a,(0e001h)		;4172
	or a			;4175
	jp z,menu_sale		;4176   ; al agotarse el tiempo se sale sin elegir, y 0xE002 se queda a uno
	jr menu_espera		;4179
menu_elegido:		; Guarda la opcion en 0xE012 y hace parpadear su rotulo (0x44A1, 0x44B9 o 0x44D1) con 0x43D5
	xor a			;417b
	ld hl,0e00ah		;417c   ; 0xE00A es la opcion sobre la que esta el cursor, de 0 a 2
	ld a,(hl)			;417f
	ld (0e012h),a		;4180   ; 0xE012 fija el modo: 0 un jugador, 1 dos a golpes, 2 partido por hoyos
	ld a,(hl)			;4183
	ld hl,044a1h		;4184   ; el guion del rotulo elegido, el que va a parpadear
	or a			;4187
	jr z,menu_parpadea		;4188
	ld hl,044b9h		;418a
	dec a			;418d
	jr z,menu_parpadea		;418e
	ld hl,044d1h		;4190
menu_parpadea:		; Entra en el parpadeo con el rotulo ya elegido en HL
	call parpadea_el_rotulo		;4193
menu_sale:		; Borra la tabla de nombres, corta la lista de sprites y pinta el guion de 0x47D1
	call borra_la_tabla_de_nombres		;4196
	call corta_la_lista_de_sprites		;4199
	call lee_parametro		;419c   ; el guion de 0x47D1: patrones y atributos de los sprites

; ----------------------------------------------------------------------
; DATOS parametro_419f: Parametro en linea del call de 0x419C: apunta a 0x47D1
;   0x419f..0x41a1  (2 bytes)
DATA_parametro_419f:
	defw 047d1h	; 419f  -> DATA_guion_sprites_del_titulo

; ======================================================================
; CODIGO 0x41a1..0x4220  (127 bytes)
; ======================================================================


arranca_el_juego:		; Abre las interrupciones y salta a 0x482E
	ei			;41a1
	jp empieza_la_partida		;41a2
lee_el_disparo:		; Enciende el registro 15 del PSG segun el acarreo y devuelve el 14 complementado: los botones del joystick
	ld e,08fh		;41a5   ; el registro 15 del PSG elige el puerto de mandos: 0x8F el 1 y 0xCF el 2
	jr nc,lee_el_disparo_puerto_2		;41a7
	ld e,0cfh		;41a9
lee_el_disparo_puerto_2:		; Entrada con el puerto 2 ya elegido
	ld a,00fh		;41ab
	call 00093h		;41ad   ; BIOS WRTPSG - Writes data to PSG-register
	ld a,00eh		;41b0   ; el registro 14 trae las cuatro direcciones y los dos botones
	call 00096h		;41b2   ; BIOS RDPSG - Reads value from PSG-register
	cpl			;41b5   ; el PSG los da a cero cuando se pulsan: hay que darles la vuelta
	ret			;41b6
lee_el_teclado_extra:		; Junta las filas 2, 3, 5 y 6 del teclado y arma con ellas una mascara de direcciones y botones equivalente a la del joystick
	ld de,00205h		;41b7   ; las cuatro filas del teclado que hacen de mando del segundo jugador: la 5 y la 2 en DE, la 3 y la 6 en HL
	ld hl,00306h		;41ba
	ld a,e			;41bd
	call lee_fila_del_teclado		;41be
	and 090h		;41c1   ; de la fila 5, la W (bit 4) y la Z (bit 7)
	call lee_fila_del_teclado_d		;41c3
	and 040h		;41c6   ; de la fila 2, la A (bit 6)
	or e			;41c8
	ld e,a			;41c9
	ld a,h			;41ca
	call lee_fila_del_teclado		;41cb
	bit 1,a		;41ce   ; el bit 1 de la fila 3 es la D
	jr z,teclado_extra_recoloca		;41d0
	set 5,e		;41d2   ; que se guarda de momento en el bit 5
teclado_extra_recoloca:		; Rota la mascara media palabra y reparte los bits que faltan
	ld a,e			;41d4
	rlca			;41d5   ; cuatro rotaciones: el nibble alto baja al bajo
	rlca			;41d6
	rlca			;41d7
	rlca			;41d8
	ld e,a			;41d9
	and 005h		;41da   ; y de ahi salen ya en su sitio la W como arriba (bit 0) y la A como izquierda (bit 2)
	bit 1,e		;41dc   ; la D pasa a ser derecha, el bit 3
	jr z,teclado_extra_bit_3		;41de
	set 3,a		;41e0
teclado_extra_bit_3:		; Copia el bit 3 al 1
	bit 3,e		;41e2   ; y la Z, abajo, el bit 1
	jr z,teclado_extra_bit_0		;41e4
	set 1,a		;41e6
teclado_extra_bit_0:		; Copia el bit 0 al 4
	ld e,a			;41e8
	ld a,l			;41e9   ; la fila 6 del teclado
	call lee_fila_del_teclado		;41ea
	bit 0,a		;41ed   ; su bit 0 es SHIFT, que hace de disparo
	jr z,teclado_extra_fin		;41ef
	set 4,e		;41f1
teclado_extra_fin:		; Devuelve la mascara montada
	ld a,e			;41f3
	ret			;41f4
lee_fila_del_teclado_d:		; Pasa D como fila y sigue
	ld e,a			;41f5
	ld a,d			;41f6
lee_fila_del_teclado:		; SNSMAT de la fila que va en A, complementado: 1 es tecla pulsada
	call 00141h		;41f7   ; BIOS SNSMAT - Returns the value of the specified line from the keyboard matrix
	cpl			;41fa   ; SNSMAT da un cero por tecla pulsada: le da la vuelta para que se parezca al joystick
	ret			;41fb
lee_las_direcciones:		; Lee la fila 8 -las teclas de cursor y el espacio-, la traduce con 0x420B y le anade el disparo
	ld a,e			;41fc   ; en E, la fila de las teclas de cursor y el espacio: la 8
	call lee_fila_del_teclado		;41fd
	call traduce_las_direcciones		;4200
	call lee_fila_del_teclado_d		;4203
	and 040h		;4206   ; de la fila que va en D solo se mira el bit 6
	rrca			;4208   ; que entra como segundo disparo, el bit 5
	or e			;4209
	ret			;420a
traduce_las_direcciones:		; Coge el nibble alto de la fila 8, lo busca en 0x4220 y le pega en el bit 4 el espacio
	ld c,000h		;420b
	rrca			;420d   ; el bit 0 de la fila 8 es la barra de espacio
	jr nc,traduce_las_direcciones_nibble		;420e
	set 4,c		;4210   ; que hace de disparo, el bit 4
traduce_las_direcciones_nibble:		; Termina de bajar el nibble antes de indexar
	rrca			;4212
	rrca			;4213
	rrca			;4214
	and 00fh		;4215   ; en el nibble alto van las cuatro teclas de cursor
	ld hl,04220h		;4217   ; 0x4220 las traduce a la misma mascara que da el joystick
	call suma_a_a_hl		;421a
	ld a,(hl)			;421d
	or c			;421e
	ret			;421f

; ----------------------------------------------------------------------
; DATOS tabla_direcciones_teclado: Traduce el nibble alto de la fila 8 del
;   teclado -izquierda, arriba, abajo, derecha- a la mascara 1=arriba 2=abajo
;   4=izquierda 8=derecha, y da 0x0F a las combinaciones imposibles. La lee
;   0x420B, que indexa con 0x43FE
;   0x4220..0x4230  (16 bytes)
DATA_tabla_direcciones_teclado:
	defb 000h,004h,001h,005h,002h,006h,00fh,00fh,008h,00fh,009h,00fh,00ah,00fh,00fh,00fh	; 4220  ................

; ======================================================================
; CODIGO 0x4230..0x42e9  (185 bytes)
; ======================================================================


lee_los_mandos:		; Lee el joystick -uno o los dos, segun 0xE012- y las teclas, y deja en 0xE00C y 0xE00F lo pulsado, lo de antes y el flanco de cada jugador
	ld b,001h		;4230
	ld a,(0e012h)		;4232   ; con dos jugadores hay que leer los dos puertos
	or a			;4235
	jr z,lee_los_mandos_jugador		;4236
	ld b,002h		;4238
lee_los_mandos_jugador:		; Empieza por la ficha del jugador 1
	ld hl,0e00ch		;423a
lee_los_mandos_puerto:		; Una vuelta por puerto: los seis bits de un joystick a su ficha
	call lee_el_disparo		;423d
	and 03fh		;4240   ; los seis bits utiles: cuatro direcciones y dos botones
	ld (hl),a			;4242   ; 0xE00C es el mando del jugador 1
	ld hl,0e00fh		;4243   ; y 0xE00F el del 2
	scf			;4246   ; con el acarreo puesto, la vuelta siguiente lee el puerto 2
	djnz lee_los_mandos_puerto		;4247
	ld de,00008h		;4249   ; en E la fila 8, las teclas de cursor; en D la fila 0, de la que solo se usa el bit 6, la tecla 6
	call lee_las_direcciones		;424c
	ld d,a			;424f
	ld hl,0e00ch		;4250
	ld a,(hl)			;4253
	or d			;4254   ; el teclado se suma al joystick del primer jugador
	ld (hl),a			;4255
	ld a,(0e012h)		;4256
	or a			;4259
	ld b,001h		;425a
	jr z,lee_los_mandos_flancos		;425c   ; con un solo jugador no se miran las teclas del segundo
	call lee_el_teclado_extra		;425e   ; el segundo juega con W arriba, A izquierda, Z abajo, D derecha y SHIFT
	ld d,a			;4261
	ld hl,0e00fh		;4262
	ld a,(hl)			;4265
	or d			;4266   ; que se suman igual a su joystick
	ld (hl),a			;4267
	ld b,002h		;4268
lee_los_mandos_flancos:		; Vuelve a la primera ficha para sacar los flancos
	ld hl,0e00ch		;426a
lee_los_mandos_flanco:		; Compara lo de este cuadro con lo del anterior y anota lo que se acaba de pulsar
	ld a,(hl)			;426d   ; lo pulsado en este cuadro
	inc hl			;426e
	cp (hl)			;426f   ; contra lo del cuadro anterior, guardado en 0xE00D
	ld c,a			;4270
	jr nz,lee_los_mandos_guarda		;4271
	inc hl			;4273
	ld (hl),a			;4274   ; 0xE00E solo se refresca cuando el mando repite: es el estado ya asentado
	dec hl			;4275
lee_los_mandos_guarda:		; Guarda el estado de este cuadro y pasa a la ficha siguiente
	ld (hl),c			;4276
	ld l,00fh		;4277   ; y a por la ficha del segundo jugador, en 0xE00F
	djnz lee_los_mandos_flanco		;4279
	ret			;427b
lee_el_mando_del_menu:		; Lo que mueve el menu: junta los dos joysticks y, si ninguno dice nada, las filas 7 y 8 del teclado. El resultado va a 0xE005
	ld b,002h		;427c
	or a			;427e   ; el acarreo a cero: empieza por el puerto 1
lee_el_mando_del_menu_puerto:		; Una vuelta por puerto
	call lee_el_disparo		;427f
	and 03fh		;4282
	ld (0e005h),a		;4284   ; 0xE005 es lo unico que mira el menu
	or a			;4287
	ret nz			;4288   ; si el joystick ya dice algo, ni se toca el teclado
	scf			;4289
	djnz lee_el_mando_del_menu_puerto		;428a
	ld de,00708h		;428c   ; las filas 7 y 8: cursores, espacio y la tecla SELECT
	call lee_las_direcciones		;428f
	ld (0e005h),a		;4292
	ret			;4295
mueve_el_menu:		; Con el disparo devuelve acarreo -opcion elegida-; con arriba o abajo cambia 0xE00A dando la vuelta entre 0 y 2. El bit 0 de 0xE00B es el pestillo que impide repetir mientras se siga pulsando
	ld hl,0e00bh		;4296   ; 0xE00B lleva el pestillo: su bit 0 impide repetir mientras no se suelte
	ld a,(0e005h)		;4299   ; 0xE005 trae lo que ha leido el mando del menu
	ld b,a			;429c
	or a			;429d
	jr nz,mueve_el_menu_pulsado		;429e
	ld (hl),a			;42a0   ; al soltar, el pestillo se abre
	ret			;42a1
mueve_el_menu_pulsado:		; Ya hay algo pulsado: mira si es disparo o direccion
	bit 0,(hl)		;42a2   ; con el pestillo echado no hace nada hasta que se suelte
	ret nz			;42a4
	ld a,b			;42a5
	and 030h		;42a6   ; los bits 4 y 5 son los dos disparos
	or a			;42a8
	scf			;42a9   ; y se vuelve con acarreo: opcion elegida
	ret nz			;42aa
	ld a,b			;42ab
	and 003h		;42ac   ; el bit 0 es arriba y el 1 abajo
	set 0,(hl)		;42ae   ; echa el pestillo para que un toque valga por uno
	dec a			;42b0   ; un uno era arriba
	jr nz,mueve_el_menu_baja		;42b1
	dec hl			;42b3   ; 0xE00A: la opcion sobre la que esta el cursor
	ld a,(hl)			;42b4
	sub 001h		;42b5
	jr nc,mueve_el_menu_sube		;42b7
	ld a,002h		;42b9   ; por debajo de la primera se pasa a la tercera
mueve_el_menu_sube:		; Guarda la opcion tras subir, dando la vuelta a 2
	ld (hl),a			;42bb
	jr pinta_el_cursor_del_menu		;42bc
mueve_el_menu_baja:		; Baja la opcion, dando la vuelta a 0
	dec hl			;42be
	ld a,(hl)			;42bf
	inc a			;42c0
	cp 003h		;42c1   ; solo hay tres opciones
	jr nz,mueve_el_menu_guarda		;42c3
	xor a			;42c5   ; y de la tercera se vuelve a la primera
mueve_el_menu_guarda:		; Deja la opcion nueva
	ld (hl),a			;42c6
pinta_el_cursor_del_menu:		; Coge de 0x42E2 la fila de siete bytes que le toca a la opcion 0xE00A y la vuelca de dos en dos a partir de la VRAM 0x3A25, subiendo dos filas cada vez
	ld hl,0e00ah		;42c7
	di			;42ca
	ld a,(hl)			;42cb
	ld de,07a25h		;42cc   ; VRAM 0x3A25: fila 17, columna 5, dos columnas antes del rotulo
	ld b,(hl)			;42cf
	inc b			;42d0   ; una vuelta de mas, a proposito
	ld hl,042e2h		;42d1   ; porque entra por 0x42E2, siete bytes antes de la tabla: la vuelta de mas lo deja en la fila 0
pinta_el_cursor_avanza:		; Suma siete por cada opcion contada
	ld a,007h		;42d4   ; siete bytes por fila de la tabla
	call suma_a_a_hl		;42d6
	djnz pinta_el_cursor_avanza		;42d9
pinta_el_cursor_fila:		; Escribe una pareja de tiles y salta dos filas; el 0xFF corta
	ld a,(hl)			;42db
	inc a			;42dc
	ret z			;42dd   ; el 0xFF del final de la fila corta el bucle
	ld b,002h		;42de   ; dos tiles: el cursor en su opcion, dos ceros en las otras dos
	call vuelca_b_bytes_en_vram_di		;42e0
	ld a,040h		;42e3   ; 0x40 son dos filas de la tabla de nombres: las opciones van una si una no
	add a,e			;42e5
	ld e,a			;42e6
	jr pinta_el_cursor_fila		;42e7

; ----------------------------------------------------------------------
; DATOS cursor_del_menu: Tres filas de siete bytes, una por opcion. Cada fila
;   lleva los dos tiles del cursor -0xA1 0xA2- en su pareja y ceros en las
;   otras dos, mas un 0xFF de fin. 0x42D1 entra por 0x42E2 y suma 7 por cada
;   opcion contada en 0xE00A; 0x42DB las vuelca de dos en dos a partir de la
;   VRAM 0x3A25, subiendo 0x40 -dos filas- cada vez
;   0x42e9..0x42fe  (21 bytes)
DATA_cursor_del_menu:
	defb 0a1h,0a2h,000h,000h,000h,000h,0ffh	; 42e9
	defb 000h,000h,0a1h,0a2h,000h,000h,0ffh	; 42f0
	defb 000h,000h,000h,000h,0a1h,0a2h,0ffh	; 42f7

; ======================================================================
; CODIGO 0x42fe..0x447a  (380 bytes)
; ======================================================================


monta_la_pantalla_del_menu:		; Borra la tabla de nombres, pinta los cuatro guiones de 0x4482 y el logotipo
	call borra_la_tabla_de_nombres		;42fe
	ld hl,04482h		;4301   ; cuatro guiones seguidos: el de los rotulos fijos y los tres de las opciones
	ld b,004h		;4304
monta_la_pantalla_del_menu_guion:		; Una vuelta por guion
	push bc			;4306
	call pinta_guion		;4307   ; 0x4380 deja HL detras del 0x00 final, o sea en el guion siguiente
	pop bc			;430a
	djnz monta_la_pantalla_del_menu_guion		;430b
	jr pinta_el_logotipo		;430d
borra_la_tabla_de_nombres:		; Escribe 768 ceros a partir de la VRAM 0x3800
	di			;430f
	ld de,07800h		;4310   ; VRAM 0x3800: la tabla de nombres
	call abre_la_vram_para_escribir_2		;4313
	ld h,003h		;4316   ; tres tandas de 256: las 768 casillas de la pantalla
	xor a			;4318
borra_la_tabla_de_nombres_tercio:		; Un tercio de 256 bytes por vuelta
	ld b,a			;4319   ; con B a cero el bucle da las 256 vueltas
	call rellena_con_a		;431a
	dec h			;431d   ; un tercio de pantalla por vuelta
	jr nz,borra_la_tabla_de_nombres_tercio		;431e
	ei			;4320
	ret			;4321
replica_los_tercios:		; Copia 4096 bytes de VRAM a VRAM leyendo de DE y escribiendo en HL. Como el destino va 0x800 por delante del origen, la primera vuelta copia el tercio 0 en el 1 y la segunda copia ese mismo en el 2: con una sola llamada los tres tercios quedan iguales
	ld bc,00fffh		;4322   ; 4095 bytes en vez de 4096: el ultimo byte se queda sin copiar
	exx			;4325
	ld a,(00007h)		;4326   ; en 0x0007 la BIOS guarda el puerto por el que se escribe a la VRAM
	ld d,a			;4329
	ld a,(00006h)		;432a   ; y en 0x0006 el puerto por el que se lee
	ld e,a			;432d
	exx			;432e
replica_los_tercios_byte:		; Un byte por vuelta, reprogramando el VDP para leer y para escribir
	call abre_la_vram_para_leer		;432f   ; cada byte cuesta dos direcciones nuevas al VDP: esta es la de leer
	inc de			;4332
	exx			;4333
	ld c,e			;4334   ; el puerto de lectura, escondido en E prima
	in a,(c)		;4335
	exx			;4337
	ex de,hl			;4338   ; cambia origen y destino de sitio
	push af			;4339   ; se lleva el byte a la pila mientras reprograma el VDP
	call abre_la_vram_para_escribir_2		;433a   ; y esta es la de escribir
	inc de			;433d
	pop af			;433e
	exx			;433f
	ld c,d			;4340   ; el puerto de escritura, en D prima
	out (c),a		;4341
	exx			;4343
	ex de,hl			;4344
	dec bc			;4345
	ld a,b			;4346
	or c			;4347
	jr nz,replica_los_tercios_byte		;4348
	ret			;434a
espera_al_reloj:		; Pone A en 0xE001 y no vuelve hasta que la interrupcion lo baja a cero
	ld hl,0e001h		;434b   ; 0xE001 lo baja la interrupcion una vez cada treinta y dos cuadros
	ld (hl),a			;434e
espera_al_reloj_bucle:		; El bucle de espera
	ld a,(hl)			;434f
	or a			;4350
	jr nz,espera_al_reloj_bucle		;4351
	ret			;4353
pinta_el_logotipo:		; Dos filas de diecinueve tiles correlativos, la primera desde el 0x40 y la segunda desde el 0x53, a partir de la VRAM 0x3887
	ld de,07887h		;4354   ; VRAM 0x3887: fila 4, columna 7
	ld a,040h		;4357   ; los diecinueve tiles de arriba del rotulo, del 0x40 al 0x52
	call pinta_diecinueve_tiles		;4359
	ld a,053h		;435c   ; y los diecinueve de abajo, del 0x53 al 0x65
pinta_diecinueve_tiles:		; Escribe diecinueve tiles correlativos desde A y baja DE una fila
	ld b,013h		;435e
pinta_tiles_correlativos:		; Igual pero con B tiles
	push af			;4360
	call abre_la_vram_para_escribir_2		;4361
	pop af			;4364
pinta_tiles_correlativos_uno:		; El bucle que los escupe por el puerto de datos
	ex af,af'			;4365   ; esconde el numero de tile en A prima para poder usar A con el puerto
	exx			;4366
	ld a,(00007h)		;4367   ; el puerto de datos del VDP, leido en el banco alterno
	ld c,a			;436a
	ex af,af'			;436b
	out (c),a		;436c   ; los escupe uno tras otro sin volver a dar la direccion
	exx			;436e
	inc a			;436f   ; cada tile es el siguiente del anterior
	djnz pinta_tiles_correlativos_uno		;4370
	ex de,hl			;4372
	ld de,00020h		;4373   ; 0x20 baja DE una fila entera de la tabla de nombres
	add hl,de			;4376
	ex de,hl			;4377
	ret			;4378
lee_parametro:		; Toma la palabra de 16 bits que va detras del CALL
	ex (sp),hl			;4379   ; saca de la pila la direccion de retorno, que apunta al parametro
	ld e,(hl)			;437a
	inc hl			;437b
	ld d,(hl)			;437c
	inc hl			;437d
	ex (sp),hl			;437e   ; la devuelve ya avanzada, para volver detras del parametro
	ex de,hl			;437f
pinta_guion:		; Toma el destino de los dos primeros bytes y sigue en 0x4389
	ld d,(hl)			;4380   ; la cabecera del guion: el destino, byte alto primero
	inc hl			;4381
	ld e,(hl)			;4382
	inc hl			;4383
pinta_guion_de:		; Igual pero con el destino ya en DE
	di			;4384
	call abre_la_vram_para_escribir		;4385
	di			;4388
pinta_guion_aqui:		; Las ordenes del guion, con el destino ya fijado en el VDP
	ld a,(hl)			;4389   ; la orden que toca
	inc hl			;438a
	cp 001h		;438b   ; la orden 0x01 es la del bloque repetido
	jr nz,pinta_guion_orden		;438d
	ld a,(hl)			;438f
	and 00fh		;4390   ; el nibble bajo es el tamano del bloque
	ld b,a			;4392
	ld a,(hl)			;4393
	inc hl			;4394
	and 0f0h		;4395   ; y el alto, las veces que se repite
	rrca			;4397
	rrca			;4398
	rrca			;4399
	rrca			;439a
	ld c,a			;439b   ; hasta quince repeticiones de hasta quince bytes
pinta_guion_repite:		; La orden 0x01: escribe el bloque de B bytes C veces seguidas
	push hl			;439c   ; guarda el principio del bloque: cada vuelta lo lee entero otra vez
	push bc			;439d
	call vuelca_b_bytes		;439e   ; y lo escribe de una tirada
	pop bc			;43a1
	pop hl			;43a2
	dec c			;43a3
	jr nz,pinta_guion_repite		;43a4
pinta_guion_salta_el_bloque:		; Adelanta HL los B bytes del bloque que se acaba de repetir
	inc hl			;43a6   ; ahora si, adelanta HL los bytes del bloque
	djnz pinta_guion_salta_el_bloque		;43a7
	jr pinta_guion_aqui		;43a9
pinta_guion_orden:		; Reparte la orden: literal si trae el bit 7, racha si no, y 0 o 0x80 si son los seis bits bajos a cero
	ld c,a			;43ab
	and 07fh		;43ac   ; quita el bit 7: lo que queda es la cuenta
	jr z,pinta_guion_fin		;43ae   ; con los siete bits bajos a cero es un 0x00 o un 0x80
	ld b,a			;43b0
	cp c			;43b1   ; si el bit 7 no estaba, es una racha
	jr nz,pinta_guion_literal		;43b2
	ld a,(hl)			;43b4   ; el byte que se repite va justo detras
	inc hl			;43b5
	call rellena_con_a		;43b6
	jr pinta_guion_aqui		;43b9
pinta_guion_literal:		; Copia B bytes tal cual
	call vuelca_b_bytes		;43bb
	jr pinta_guion_aqui		;43be
pinta_guion_fin:		; El 0x00 vuelve; el 0x80 recarga el destino y sigue
	cp c			;43c0   ; el 0x80 recarga el destino y sigue; el 0x00 acaba el guion
	jr nz,pinta_guion		;43c1
	ret			;43c3
borra_memoria:		; Pone a cero BC bytes desde HL con el truco del ldir solapado
	push hl			;43c4   ; DE queda un byte por delante de HL
	pop de			;43c5
	inc de			;43c6
	ld (hl),000h		;43c7   ; y el ldir se persigue a si mismo: un solo cero se reparte por todo el bloque
	ldir		;43c9
	ret			;43cb
corta_la_lista_de_sprites:		; Escribe 0xCF ochenta veces desde la VRAM 0x3B00: esconde los treinta y dos sprites
	ld de,07b00h		;43cc
	ld bc,080cfh		;43cf   ; 0xCF en los 128 bytes de atributos: los treinta y dos sprites se van fuera de pantalla
	jp rellena_vram_con_c_di		;43d2
parpadea_el_rotulo:		; Pinta y borra el guion de HL al ritmo del bit 3 del contador de cuadros hasta que se enciende el bit 6, o sea 64 cuadros
	xor a			;43d5
	ld (0e000h),a		;43d6   ; pone el contador de cuadros a cero para medir el parpadeo
parpadea_el_rotulo_vuelta:		; Una vuelta: borrar veintiseis tiles o pintar el guion
	ei			;43d9
	ld a,(0e000h)		;43da
	bit 3,a		;43dd   ; el bit 3 del contador cambia cada ocho cuadros
	di			;43df
	jr z,parpadea_el_rotulo_pinta		;43e0
	push hl			;43e2
	ld d,(hl)			;43e3   ; el destino sale de la cabecera del propio guion
	inc hl			;43e4
	ld e,(hl)			;43e5
	inc hl			;43e6
	ld b,01ah		;43e7   ; veintiseis tiles, algo mas que los veinte del rotulo
	ld c,000h		;43e9   ; y el tile 0 es el blanco
	call rellena_vram_con_c_2		;43eb
	pop hl			;43ee
	jr parpadea_el_rotulo_vuelta		;43ef
parpadea_el_rotulo_pinta:		; La mitad que pinta
	push hl			;43f1
	call pinta_guion		;43f2   ; la otra mitad del parpadeo: el rotulo entero
	ld hl,0e000h		;43f5
	bit 6,(hl)		;43f8   ; el bit 6: a los sesenta y cuatro cuadros, cuatro parpadeos, se acaba
	pop hl			;43fa
	jr z,parpadea_el_rotulo_vuelta		;43fb
	ret			;43fd
suma_a_a_hl:		; HL += A, sin tocar nada mas. La rutina mas llamada del cartucho
	add a,l			;43fe
	ld l,a			;43ff
	ret nc			;4400   ; solo toca H cuando el byte bajo se desborda
	inc h			;4401
	ret			;4402
abre_la_vram_para_escribir:		; SETWRT de la BIOS con DE, y lo repite si la interrupcion ha tocado el VDP por medio (0xE01D)
	xor a			;4403
	ld (0e01dh),a		;4404   ; 0xE01D a cero: si la interrupcion entra por medio, lo levantara
	inc a			;4407
	ld (0e01eh),a		;4408   ; y 0xE01E le dice que no toque el VDP
	ex de,hl			;440b
	call 00053h		;440c   ; BIOS SETWRT - Enables VDP to write
	di			;440f
	ex de,hl			;4410
	ld a,(0e01dh)		;4411   ; si aun asi se ha colado, hay que dar la direccion otra vez
	or a			;4414
	jr nz,abre_la_vram_para_escribir		;4415
	ld (0e01eh),a		;4417   ; y suelta el VDP
	ret			;441a
abre_la_vram_para_leer:		; Lo mismo con SETRD
	xor a			;441b
	ld (0e01dh),a		;441c   ; la misma trampa, pero esta no llega a levantar 0xE01E
	ex de,hl			;441f
	call 00050h		;4420   ; BIOS SETRD - Enables VDP to read
	di			;4423
	ex de,hl			;4424
	ld a,(0e01dh)		;4425   ; si la interrupcion se ha colado, repite
	or a			;4428
	jr nz,abre_la_vram_para_leer		;4429
	ret			;442b
abre_la_vram_para_escribir_2:		; La gemela de 0x4403, sin tocar 0xE01E
	xor a			;442c
	ld (0e01dh),a		;442d   ; 0xE01D a cero para enterarse de si la interrupcion toca el VDP
	ex de,hl			;4430
	call 00053h		;4431   ; BIOS SETWRT - Enables VDP to write
	di			;4434
	ex de,hl			;4435
	ld a,(0e01dh)		;4436   ; y si lo ha tocado, vuelve a dar la direccion
	or a			;4439
	jr nz,abre_la_vram_para_escribir_2		;443a
	ret			;443c
vuelca_b_bytes_en_vram:		; Abre la VRAM en DE y escribe los B bytes que hay en HL
	call abre_la_vram_para_escribir		;443d
vuelca_b_bytes:		; Solo el bucle, con la direccion ya puesta
	push bc			;4440   ; el out con C machaca B: por eso guarda BC en cada vuelta
	ld a,(00007h)		;4441   ; el puerto de datos del VDP, de 0x0007 de la BIOS
	ld c,a			;4444
	ld a,(hl)			;4445
	out (c),a		;4446   ; sin repetir la direccion: el VDP la sube sola
	inc hl			;4448
	pop bc			;4449
	djnz vuelca_b_bytes		;444a
	ret			;444c
vuelca_b_bytes_en_vram_2:		; La gemela que usa 0x442C
	call abre_la_vram_para_escribir_2		;444d
	jr vuelca_b_bytes		;4450
rellena_vram_con_c:		; Abre la VRAM en DE y escribe B veces el byte C
	call abre_la_vram_para_escribir		;4452
rellena_con_c:		; Pasa C a A y sigue
	ld a,c			;4455
rellena_con_a:		; Escribe B veces el byte A por el puerto de datos
	push bc			;4456   ; guarda BC porque C va a hacer de puerto
	push af			;4457
	ld a,(00007h)		;4458   ; el puerto de datos del VDP
	ld c,a			;445b
	pop af			;445c
	out (c),a		;445d   ; el mismo byte B veces
	pop bc			;445f
	djnz rellena_con_a		;4460
	ret			;4462
rellena_vram_con_c_2:		; La gemela que usa 0x442C
	call abre_la_vram_para_escribir_2		;4463
	ld a,c			;4466   ; aqui el byte de relleno viaja en C
	jr rellena_con_a		;4467
de_quien_es_el_turno:		; Devuelve Z si 0xE013 vale cero, o sea si juega el primero
	ld a,(0e013h)		;4469   ; 0xE013 vale cero mientras juega el primero
	or a			;446c
	ret			;446d
vuelca_b_bytes_en_vram_di:		; 0x444D metida entre di y ei
	di			;446e
	call vuelca_b_bytes_en_vram_2		;446f
	ei			;4472
	ret			;4473
rellena_vram_con_c_di:		; 0x4463 metida entre di y ei
	di			;4474
	call rellena_vram_con_c_2		;4475
	ei			;4478
	ret			;4479

; ----------------------------------------------------------------------
; DATOS registros_del_vdp: Los ocho valores R0-R7 que 0x40A9 mete con WRTVDP:
;   SCREEN 2 con los colores en 0x0000, los patrones en 0x2000, los nombres en
;   0x3800 y los sprites de 16x16 en 0x1800/0x3B00
;   0x447a..0x4482  (8 bytes)
DATA_registros_del_vdp:
	defb 002h,0e2h,00eh,07fh,007h,076h,003h,0e1h	; 447a  .....v..

; ----------------------------------------------------------------------
; DATOS guion_rotulos_del_menu: Guion de VRAM con las dos lineas fijas del
;   menu, leidas de los tiles: (c)KONAMI 1985 en la fila 8 columna 11, y PLAY
;   SELECT en la fila 13 columna 11. Lo pintan las cuatro vueltas de 0x4301
;   0x4482..0x44a1  (31 bytes)
DATA_guion_rotulos_del_menu:
	defb 079h,00bh,08ch,0eah,0d7h,0d3h,0e6h,0dah,0e1h,0d5h,000h,0f1h,0f9h,0f8h,0f5h,080h	; 4482  y...............
	defb 079h,0abh,08bh,0d8h,0d9h,0dah,0dbh,000h,0deh,0dch,0d9h,0dch,0d6h,0d4h,000h	; 4492  y..............

; ----------------------------------------------------------------------
; DATOS guion_opcion_1: Guion de VRAM: 20 tiles en 0x3A27 que dicen 1PLAYER
;   STROKE PLAY. 0x4184 la elige cuando 0xE00A vale 0, y 0x43D5 la hace
;   parpadear
;   0x44a1..0x44b9  (24 bytes)
DATA_guion_opcion_1:
	defb 07ah,027h,094h,0b8h,0adh,0aeh,0afh,0b0h,0b1h,0b2h,000h,000h,0b3h,0a9h,0b2h,0a8h	; 44a1  z'..............
	defb 0ach,0b1h,000h,0adh,0aeh,0afh,0b0h,000h	; 44b1  ........

; ----------------------------------------------------------------------
; DATOS guion_opcion_2: Guion de VRAM: 20 tiles en 0x3A67 que dicen 2PLAYERS
;   STROKE PLAY (0xE00A = 1)
;   0x44b9..0x44d1  (24 bytes)
DATA_guion_opcion_2:
	defb 07ah,067h,094h,0b9h,0adh,0aeh,0afh,0b0h,0b1h,0b2h,0b3h,000h,0b3h,0a9h,0b2h,0a8h	; 44b9  zg..............
	defb 0ach,0b1h,000h,0adh,0aeh,0afh,0b0h,000h	; 44c9  ........

; ----------------------------------------------------------------------
; DATOS guion_opcion_3: Guion de VRAM: 20 tiles en 0x3AA7 que dicen 2PLAYERS
;   MATCH  PLAY (0xE00A = 2)
;   0x44d1..0x44e9  (24 bytes)
DATA_guion_opcion_3:
	defb 07ah,0a7h,094h,0b9h,0adh,0aeh,0afh,0b0h,0b1h,0b2h,0b3h,000h,0b4h,0afh,0a9h,0abh	; 44d1  z...............
	defb 0b5h,000h,000h,0adh,0aeh,0afh,0b0h,000h	; 44e1  ........

; ----------------------------------------------------------------------
; DATOS guion_pantalla_de_titulo: Guion de VRAM del rotulo: colores
;   0x0000-0x07CF y patrones 0x200E-0x2757. Va en linea tras el call de
;   0x40C3.
;   0x44e9..0x46b0  (455 bytes)
DATA_guion_pantalla_de_titulo:
	defb 065h,008h,090h,000h,00fh,0bfh,0ffh,0ffh,0ffh,0bfh,00fh,000h,000h,0fch,0c0h,0c0h	; 44e9  e...............
	defb 080h,080h,000h,080h,067h,050h,088h,03ch,042h,099h,0a1h,0a1h,099h,042h,03ch,080h	; 44f9  ....gP.<B....B<.
	defb 060h,00eh,082h,007h,00fh,006h,000h,082h,0f8h,0f0h,004h,03eh,004h,03fh,08bh,01fh	; 4509  `..........>.?..
	defb 03fh,07fh,0ffh,0feh,0fch,0f8h,0f0h,0e0h,0c0h,080h,003h,000h,002h,03eh,005h,000h	; 4519  ?............>..
	defb 083h,01fh,07fh,0fbh,005h,000h,083h,00fh,0cfh,0efh,005h,000h,083h,078h,0fch,0bch	; 4529  .............x..
	defb 005h,000h,083h,03fh,07fh,0f3h,005h,000h,083h,087h,0c7h,0c7h,005h,000h,083h,0bch	; 4539  ...?............
	defb 0feh,0dfh,005h,000h,088h,078h,0fch,0bch,060h,0f0h,0f0h,060h,000h,003h,0f0h,002h	; 4549  .....x..`..`....
	defb 03fh,006h,03eh,088h,0f8h,0fch,0feh,07fh,03fh,01fh,00fh,007h,003h,03eh,085h,07eh	; 4559  ?.>.....?....>.~
	defb 0fch,0fch,0f8h,0e0h,005h,0f1h,083h,0fbh,07fh,01fh,006h,0efh,082h,0cfh,00fh,008h	; 4569  ................
	defb 01eh,088h,0e1h,003h,03fh,0f1h,0e1h,0f3h,07fh,01eh,007h,0e7h,081h,0f7h,008h,08fh	; 4579  ....?...........
	defb 008h,01eh,082h,0f1h,0f2h,004h,0f5h,08ah,0f2h,0f1h,0e0h,010h,0c8h,068h,0c8h,028h	; 4589  .............h.(
	defb 010h,0e0h,080h,062h,000h,08dh,0f0h,0f1h,0f3h,0f7h,0ffh,0ffh,0feh,0feh,0f8h,0f0h	; 4599  ...b............
	defb 0e0h,0c0h,080h,007h,000h,084h,01eh,07fh,0ffh,0f3h,005h,000h,083h,087h,0c7h,0c7h	; 45a9  ................
	defb 005h,000h,083h,070h,0fch,09eh,005h,000h,083h,03fh,03fh,003h,005h,000h,083h,08eh	; 45b9  ...p.....??.....
	defb 0cfh,0cfh,005h,000h,083h,073h,0ffh,07eh,08dh,002h,005h,005h,002h,000h,083h,0e3h	; 45c9  .....s.~........
	defb 0f3h,087h,047h,047h,083h,002h,003h,080h,004h,000h,084h,00fh,01fh,01fh,01ch,004h	; 45d9  ..GG............
	defb 000h,084h,080h,0c0h,0c0h,040h,098h,000h,000h,001h,003h,003h,007h,007h,007h,03eh	; 45e9  .....@.........>
	defb 0ffh,0ffh,0e3h,0c1h,081h,080h,080h,000h,080h,0c0h,0e0h,0e0h,0e1h,003h,003h,004h	; 45f9  ................
	defb 000h,084h,078h,0feh,0ffh,0cfh,008h,01ch,081h,03ch,004h,03fh,083h,033h,030h,030h	; 4609  ..x......<.?.300
	defb 005h,080h,003h,000h,090h,0ffh,0ffh,0f7h,0f3h,0f1h,0f0h,0f0h,0f0h,001h,081h,0c1h	; 4619  ................
	defb 0e1h,0f0h,0f8h,07ch,03eh,004h,0e1h,084h,0f3h,0ffh,07fh,01eh,004h,0e7h,084h,0c7h	; 4629  ...|>...........
	defb 0c7h,087h,007h,008h,00eh,088h,001h,03fh,07fh,071h,071h,07fh,07fh,03dh,007h,0ceh	; 4639  .......?.qq..=..
	defb 081h,0eeh,008h,03ch,008h,073h,008h,080h,08ah,01fh,00fh,007h,000h,030h,03fh,01fh	; 4649  ...<.s.......0?.
	defb 00fh,000h,0c0h,004h,0e0h,082h,0c0h,080h,003h,007h,002h,003h,083h,001h,000h,000h	; 4659  ................
	defb 088h,087h,087h,080h,0c1h,0e3h,0ffh,0ffh,03eh,004h,0e7h,084h,0c3h,0c3h,081h,000h	; 4669  ........>.......
	defb 004h,087h,085h,0cfh,0ffh,0feh,078h,09dh,003h,09ch,004h,01ch,082h,0fch,0feh,006h	; 4679  ......x.........
	defb 030h,080h,040h,000h,07fh,0f0h,07fh,0f0h,080h,042h,000h,07fh,0c1h,07fh,0c1h,040h	; 4689  0.@......B.....@
	defb 0c1h,080h,045h,000h,018h,0f0h,07fh,070h,051h,070h,080h,047h,050h,040h,0f0h,080h	; 4699  ..E....pQp.GP@..
	defb 047h,080h,050h,0f0h,080h,065h,0b8h	; 46a9

; ----------------------------------------------------------------------
; DATOS guion_titulo_cola_1: Cola del guion anterior: 0x40DF vuelve a entrar
;   aqui con el destino ya en 0x2780, y repinta 0x2528-0x25AF y 0x2780-0x27CF
;   0x46b0..0x4703  (83 bytes)
DATA_guion_titulo_cola_1:
	defb 08bh,000h,01ch,022h,063h,063h,063h,022h,01ch,000h,018h,038h,004h,018h,0c1h,07eh	; 46b0  ..."ccc"...8...~
	defb 000h,03eh,063h,003h,00eh,03ch,070h,07fh,000h,03eh,063h,003h,00eh,003h,063h,03eh	; 46c0  .>c..<p..>c...c>
	defb 000h,00eh,01eh,036h,066h,066h,07fh,006h,000h,07fh,060h,07eh,063h,003h,063h,03eh	; 46d0  ...6ff....`~c.c>
	defb 000h,03eh,063h,060h,07eh,063h,063h,03eh,000h,07fh,063h,006h,00ch,018h,018h,018h	; 46e0  .>c`~cc>..c.....
	defb 000h,03eh,063h,063h,03eh,063h,063h,03eh,000h,03eh,063h,063h,03fh,003h,063h,03eh	; 46f0  .>cc>cc>.>cc?.c>
	defb 080h,065h,028h	; 4700

; ----------------------------------------------------------------------
; DATOS guion_titulo_cola_2: Cola de la cola: 0x40CB entra aqui con el destino
;   en 0x2680 y pinta 0x2680-0x2707
;   0x4703..0x4782  (127 bytes)
DATA_guion_titulo_cola_2:
	defb 081h,000h,001h,023h,07eh,063h,063h,084h,07eh,000h,07ch,066h,003h,063h,084h,066h	; 4703  ...#~cc.~.|f.c.f
	defb 07ch,000h,01fh,004h,006h,084h,066h,03ch,000h,03eh,005h,063h,083h,03eh,000h,07eh	; 4713  |.....f<.>.c.>.~
	defb 006h,018h,082h,000h,03ch,005h,018h,084h,03ch,000h,03eh,063h,003h,060h,08ch,063h	; 4723  ....<...<.>c.`.c
	defb 03eh,000h,063h,066h,06ch,078h,07ch,06eh,067h,000h,07eh,003h,063h,084h,07eh,060h	; 4733  >.cflx|ng.~.c.~`
	defb 060h,000h,006h,060h,08eh,07fh,000h,01ch,036h,063h,063h,07fh,063h,063h,000h,066h	; 4743  `..`....6cc.cc.f
	defb 066h,07eh,03ch,003h,018h,098h,000h,07fh,060h,060h,07eh,060h,060h,07fh,000h,07eh	; 4753  f~<.....``~``..~
	defb 063h,063h,062h,07ch,066h,063h,000h,03eh,063h,060h,03eh,003h,063h,03eh,08dh,000h	; 4763  ccb|fc.>c`>.c>..
	defb 063h,077h,07fh,07fh,06bh,063h,063h,000h,063h,063h,063h,07fh,003h,063h,000h	; 4773  cw..kcc.ccc..c.

; ----------------------------------------------------------------------
; DATOS guion_colores_del_titulo: Guion de VRAM: colores 0x0680-0x0747 y
;   patrones 0x26F8-0x273F. Va en linea tras el call de 0x40D4
;   0x4782..0x47d1  (79 bytes)
DATA_guion_colores_del_titulo:
	defb 066h,0f8h,089h,000h,03eh,063h,060h,067h,063h,063h,03fh,000h,003h,063h,081h,07fh	; 4782  f...>c`gcc?..c..
	defb 003h,063h,089h,000h,063h,077h,07fh,07fh,06bh,063h,063h,000h,004h,063h,094h,036h	; 4792  .c..cw..kcc..c.6
	defb 01ch,008h,000h,063h,063h,06bh,06bh,07fh,077h,022h,000h,07fh,060h,060h,07eh,060h	; 47a2  ...cckk.w"..``~`
	defb 060h,060h,000h,006h,063h,091h,03eh,000h,063h,073h,07bh,07fh,06fh,067h,063h,000h	; 47b2  ``..c.>.cs{.ogc.
	defb 07fh,007h,00eh,01ch,038h,070h,07fh,080h,046h,080h,07fh,0f0h,049h,0f0h,000h	; 47c2  ....8p..F...I..

; ----------------------------------------------------------------------
; DATOS guion_sprites_del_titulo: Guion de VRAM: patrones de sprite
;   0x1D00-0x1D7F y los atributos 0x3B00-0x3B03 y 0x3B40-0x3B4F. Va en linea
;   tras el call de 0x419C
;   0x47d1..0x4815  (68 bytes)
DATA_guion_sprites_del_titulo:
	defb 05dh,000h,005h,000h,003h,0ffh,00eh,000h,002h,0ffh,008h,000h,086h,080h,0c0h,0e0h	; 47d1  ]...............
	defb 090h,080h,080h,01ah,000h,006h,000h,002h,0ffh,00dh,000h,003h,0ffh,008h,000h,003h	; 47e1  ................
	defb 010h,081h,0feh,003h,010h,019h,000h,080h,07bh,040h,090h,0cfh,000h,0a4h,00bh,0cfh	; 47f1  ........{@......
	defb 000h,0a0h,00ch,0cfh,000h,0a4h,00bh,0cfh,000h,0a8h,00ch,080h,07bh,000h,084h,0cfh	; 4801  ............{...
	defb 000h,0ach,00fh,080h	; 4811

; ----------------------------------------------------------------------
; DATOS guion_borra_sprites: Cola del anterior: 128 bytes a los patrones de
;   sprite 0x1800-0x187F. El call de 0x5711 entra aqui por su cuenta, sin
;   pasar por el principio
;   0x4815..0x482e  (25 bytes)
DATA_guion_borra_sprites:
	defb 058h,000h,084h,018h,03ch,03ch,018h,01ch,000h,084h,018h,03ch,03ch,018h,01ch,000h	; 4815  X...<<.....<<...
	defb 002h,0c0h,01eh,000h,002h,0c0h,01eh,000h,000h	; 4825  .........

; ======================================================================
; CODIGO 0x482e..0x4844  (22 bytes)
; ======================================================================


empieza_la_partida:		; Sube a la VRAM todos los dibujos del campo (0x5E03) y pide la musica 0x87
	call carga_los_dibujos_del_campo		;482e
	ld a,087h		;4831   ; la ficha de sonido 0x87, la que suena al empezar
	call pide_un_sonido		;4833
turno_nuevo:		; Arranca el turno: si el jugador no lleva ya tres golpes de castigo se los pone
	ei			;4836
	ld hl,0e10bh		;4837
	call que_modo_es		;483a
	jr nz,pinta_la_chapa_1p		;483d
	ld (hl),003h		;483f   ; sin identificar: 0xE10B se pone a tres, y solo con un jugador; ningun otro sitio del listado lo nombra
pinta_la_chapa_1p:		; Pinta la chapa del jugador 1 con el guion de 0x4D27
	call lee_parametro		;4841   ; la etiqueta 1P del panel, guion de 0x4D27

; ----------------------------------------------------------------------
; DATOS parametro_4844: Parametro en linea del call de 0x4841: apunta a 0x4D27
;   0x4844..0x4846  (2 bytes)
DATA_parametro_4844:
	defw 04d27h	; 4844  -> DATA_guion_marca_jugador_1

; ======================================================================
; CODIGO 0x4846..0x484e  (8 bytes)
; ======================================================================


pinta_la_chapa_2p:		; Con dos jugadores pinta tambien la del 2 (guion de 0x4D33)
	call que_modo_es		;4846
	jr z,$+7		;4849   ; con un solo jugador se salta la del segundo
	call lee_parametro		;484b

; ----------------------------------------------------------------------
; DATOS parametro_484e: Parametro en linea del call de 0x484B: apunta a 0x4D33
;   0x484e..0x4850  (2 bytes)
DATA_parametro_484e:
	defw 04d33h	; 484e  -> DATA_guion_marca_jugador_2

; ======================================================================
; CODIGO 0x4850..0x498c  (316 bytes)
; ======================================================================


coloca_el_marcador_de_salida:		; Busca en 0x4D91 que ficha de 0x4D9A le toca al hoyo, la copia dos veces a 0xE1C0 -una por jugador- y saca los sprites del tee y de la bola
	ei			;4850
	ld hl,04d91h		;4851   ; 0x4D91 dice, hoyo a hoyo, cual de las cinco salidas se usa
	ld a,(0e100h)		;4854   ; 0xE100 todavia trae el hoyo anterior: la tabla queda 1-based desde 0x4D90
	call suma_a_a_hl		;4857
	ld a,(hl)			;485a
	ld hl,04d8ah		;485b   ; 0x4D8A: la ficha 0 cae encima de los tiles en blanco de 0x4D85 y no se usa nunca
	ld b,a			;485e
coloca_el_marcador_avanza:		; Suma dieciseis por cada ficha contada
	ld a,010h		;485f   ; cada ficha son dieciseis bytes: cuatro atributos de sprite
	call suma_a_a_hl		;4861
	djnz coloca_el_marcador_avanza		;4864

; ----------------------------------------------------------------------
; ----- Una copia de la ficha por jugador; la del segundo, en rojo -----
; ----------------------------------------------------------------------
	ld de,0e1c0h		;4866   ; la copia del jugador 1, en 0xE1C0
	ld bc,00010h		;4869
	push hl			;486c
	push bc			;486d
	ldir		;486e
	pop bc			;4870
	pop hl			;4871
	ldir		;4872   ; y la misma otra vez en 0xE1D0, para el jugador 2
	dec de			;4874
	ld a,008h		;4875   ; el color 8, rojo, en vez del 0x0F blanco
	ld (de),a			;4877   ; en el marcador de salida del segundo jugador
	ld (0e1d7h),a		;4878   ; y en su bola
	ld hl,0e1c0h		;487b   ; la ficha del que juega ahora se copia a 0xE0B0
	ld de,0e0b0h		;487e
	call de_quien_es_el_turno		;4881
	jr z,coloca_el_marcador_sprites		;4884
	ld l,0d0h		;4886   ; si le toca al segundo, la suya
coloca_el_marcador_sprites:		; Vuelca los atributos a la VRAM 0x3B50 y 0x3B38
	call copia_dieciseis_bytes		;4888
	ld de,07b50h		;488b   ; VRAM 0x3B50: el sprite 20, la capa negra del marcador del tee
	ld hl,0e0b8h		;488e   ; el tercer atributo de la ficha
	call vuelca_cuatro_bytes		;4891
	ld e,038h		;4894   ; el sprite 14 lleva la capa blanca, que por ser mas bajo va por delante
	call vuelca_cuatro_bytes		;4896
	call que_modo_es		;4899
	jr z,suma_los_golpes_al_total		;489c
	ld e,03ch		;489e   ; con dos jugadores, el sprite 15 es el marcador del segundo
	ld hl,0e1dch		;48a0   ; sacado de su propia ficha, la de 0xE1D0
	call vuelca_cuatro_bytes		;48a3
suma_los_golpes_al_total:		; Pasa los golpes del hoyo (0xE106) al total en BCD (0xE10D) de cada jugador
	call pinta_el_resultado_sobre_el_par		;48a6   ; primero, lo que se ha hecho sobre el par de este hoyo
	ld a,(0e012h)		;48a9
	cp 002h		;48ac   ; en el partido por hoyos no se lleva total de golpes
	jr z,hoyo_siguiente		;48ae
	ld hl,0e10dh		;48b0   ; 0xE10C y 0xE10D: el total del jugador 1, BCD de tres cifras
	ld de,07807h		;48b3   ; VRAM 0x3807: el total va en la fila 0, columna 7
	ld a,(0e106h)		;48b6   ; 0xE106 son los golpes de este hoyo, tambien en BCD
	ld c,a			;48b9
	ld b,001h		;48ba
	call que_modo_es		;48bc
	jr z,suma_los_golpes_de_uno		;48bf
	inc b			;48c1   ; con dos jugadores hay dos totales que sumar
suma_los_golpes_de_uno:		; Una suma BCD de dos cifras, y a pintar
	ld a,c			;48c2
	add a,(hl)			;48c3
	daa			;48c4   ; suma decimal: el marcador se lleva en BCD
	ld (hl),a			;48c5
	ld a,000h		;48c6
	dec hl			;48c8
	adc a,(hl)			;48c9   ; y el acarreo sube a la cifra de las centenas
	daa			;48ca
	ld (hl),a			;48cb
	call pinta_tres_cifras		;48cc   ; las tres cifras, a la VRAM
	ld e,011h		;48cf   ; el total del segundo jugador va en la columna 17
	ld a,(0e107h)		;48d1   ; 0xE107 son los golpes que ha dado el segundo en este hoyo
	ld c,a			;48d4
	inc hl			;48d5   ; y su total esta en 0xE10E y 0xE10F
	djnz suma_los_golpes_de_uno		;48d6
hoyo_siguiente:		; Pone los golpes a cero, sube 0xE100 y, si llega a diez, se acabo: los nueve hoyos. Si no, pinta el hoyo, copia su par y su longitud de 0x4D3F y sortea el viento con `ld a,r`
	ld hl,00000h		;48d8
	ld (0e106h),hl		;48db   ; de un tiron pone a cero los golpes de los dos jugadores
	call pinta_los_golpes_del_hoyo		;48de
	ld hl,0e100h		;48e1
	inc (hl)			;48e4   ; sube el numero de hoyo
	ld a,(hl)			;48e5
	cp 00ah		;48e6   ; pasado el noveno se acaba la partida
	jp z,fin_de_la_partida		;48e8
	call monta_el_hoyo		;48eb   ; desgrana el hoyo nuevo en la rejilla de 0xE200
	ld a,001h		;48ee
	ld (0e003h),a		;48f0   ; 0xE003: la interrupcion ya puede correr el juego
	ld (0e129h),a		;48f3   ; 0xE129 avisa de que el dibujo esta a medias
	ld a,010h		;48f6
	ld (0e122h),a		;48f8   ; el bit 4 de 0xE122 pone a la interrupcion a rehacer la vista

; ----------------------------------------------------------------------
; ----- El par y la longitud del hoyo, de su ficha de cuatro bytes -----
; ----------------------------------------------------------------------
	ld de,0e100h		;48fb   ; DE apunta a 0xE100 para leer el hoyo y quedarse en 0xE101, el destino de la copia
	ld a,(de)			;48fe
	inc de			;48ff
	rlca			;4900   ; por cuatro: cada hoyo son cuatro bytes de ficha
	rlca			;4901
	ld hl,04d3bh		;4902   ; 0x4D3B es 0x4D3F menos cuatro: la tabla se lee desde el hoyo 1
	call suma_a_a_hl		;4905
	ld bc,00004h		;4908
	ldir		;490b   ; par a 0xE101, longitud a 0xE102 y 0xE103, y un cero encima de la fuerza del viento
	ld hl,(0e102h)		;490d   ; la longitud viene con el byte alto delante
	ld e,h			;4910   ; y aqui le da la vuelta a los dos bytes
	ld d,l			;4911
	ex de,hl			;4912
	ld (0e14ch),hl		;4913   ; 0xE14C: lo que le queda al jugador 1, que al empezar es el hoyo entero
	call que_modo_es		;4916
	jr nz,hoyo_siguiente_marcador		;4919
	ld hl,00000h		;491b   ; con un jugador solo, al segundo se le deja a cero
hoyo_siguiente_marcador:		; Escribe el numero de hoyo en la VRAM 0x381D y los dos tiles del viento
	ld (0e14eh),hl		;491e   ; 0xE14E: lo que le queda al segundo jugador
	ld a,(0e100h)		;4921
	or 0f0h		;4924   ; 0xF0 mas la cifra da el tile del digito
	ld c,a			;4926
	ld b,001h		;4927
	ld de,0781dh		;4929   ; VRAM 0x381D: el numero de hoyo, fila 0 columna 29
	call rellena_vram_con_c_di		;492c
	ld hl,0e104h		;492f   ; 0xE104 la fuerza del viento y 0xE105 su direccion

; ----------------------------------------------------------------------
; ----- El viento se sortea con el registro de refresco de la memoria -----
; ----------------------------------------------------------------------
	ld a,r		;4932   ; el registro R hace de azar: es el unico sorteo del cartucho
	push af			;4934
	and 007h		;4935   ; tres bits mas uno: fuerza de 1 a 8
	inc a			;4937
	ld (hl),a			;4938
	pop af			;4939
	inc hl			;493a
	and 003h		;493b   ; y otros dos bits: direccion de 0 a 3
	ld (hl),a			;493d
	ld b,0cah		;493e   ; 0xCA es la primera de las cuatro flechas del viento
	add a,b			;4940
	ld e,07bh		;4941   ; VRAM 0x387B: fila 3, columna 27 del panel
	ld b,001h		;4943
	ld c,a			;4945
	call rellena_vram_con_c_di		;4946
	ld a,(0e104h)		;4949
	or 0f0h		;494c   ; la fuerza se pinta como cifra
	ld c,a			;494e
	inc b			;494f   ; el bucle de relleno deja B a cero: hay que volver a poner uno
	inc de			;4950   ; dos columnas mas a la derecha, la 29
	inc de			;4951
	call rellena_vram_con_c_di		;4952
hoyo_siguiente_espera:		; Espera a que el dibujo del hoyo termine (0xE129)
	ld a,(0e129h)		;4955   ; no sigue hasta que la vista del hoyo este dibujada
	or a			;4958
	jr nz,hoyo_siguiente_espera		;4959
	ld hl,0e130h		;495b   ; las veintiuna variables del hoyo recien montado
	push hl			;495e
	ld de,0e180h		;495f   ; se guardan como estado del jugador 1
	ld bc,00015h		;4962
	push bc			;4965
	ldir		;4966
	pop bc			;4968
	pop hl			;4969
	ld e,098h		;496a   ; y otra vez en 0xE198, como estado del 2
	ldir		;496c
	ld l,022h		;496e   ; HL quedo en 0xE145: baja a 0xE122
	ld (hl),008h		;4970   ; el bit 3: la interrupcion pasa a montar la vista
golpe_nuevo:		; Prepara un golpe: pone el monigote en su sitio y, si 0xE144 dice que hay que repintar, pasa por el guion de sprites de 0x7699
	ld a,001h		;4972
	ld (0e003h),a		;4974   ; 0xE003: el juego vuelve a correr
	ld hl,02c70h		;4977   ; la esquina del monigote: y 0x70 en 0xE162, x 0x2C en 0xE163
	ld (0e162h),hl		;497a
	ld hl,00403h		;497d   ; tres cuadros hasta el paso siguiente (0xE160) y el cuadro 4 del swing (0xE161)
	ld (0e160h),hl		;4980
	ld a,(0e144h)		;4983   ; 0xE144 dice si el monigote esta subido
	or a			;4986
	jr z,$+33		;4987   ; si no lo esta, se salta el guion de sprites
	call lee_parametro		;4989   ; el guion de 0x7699 sube los patrones del monigote

; ----------------------------------------------------------------------
; DATOS parametro_498c: Parametro en linea del call de 0x4989: apunta a 0x7699
;   0x498c..0x498e  (2 bytes)
DATA_parametro_498c:
	defw 07699h	; 498c  -> DATA_guion_sprites_del_juego

; ======================================================================
; CODIGO 0x498e..0x4b47  (441 bytes)
; ======================================================================


pinta_los_colores_del_golfista:		; Con el turno del segundo jugador, cambia los nueve colores de sus sprites por los de 0x4DEA
	call de_quien_es_el_turno		;498e
	jr z,golpe_espera_al_sonido		;4991
	ld de,07b07h		;4993   ; VRAM 0x3B07: el byte de color del sprite 1
	ld hl,04deah		;4996   ; los nueve colores del monigote del segundo jugador
	ld b,009h		;4999
pinta_los_colores_uno:		; Un color por vuelta, saltando de cuatro en cuatro por los atributos
	push bc			;499b   ; un sprite por vuelta: de su atributo solo se cambia el color
	ld b,001h		;499c
	call vuelca_b_bytes_en_vram_di		;499e
	inc de			;49a1
	inc de			;49a2
	inc de			;49a3
	inc de			;49a4
	pop bc			;49a5
	djnz pinta_los_colores_uno		;49a6
golpe_espera_al_sonido:		; No sigue hasta que se calle el canal 0xE663
	ld a,(0e663h)		;49a8   ; el canal 3 del sonido: 0 cuando ha terminado de sonar el golpe
	ei			;49ab   ; abre la interrupcion en cada vuelta, que es la que hace correr el sonido
	or a			;49ac
	jr nz,golpe_espera_al_sonido		;49ad
	ld (0e147h),a		;49af   ; A vale 0 al salir del bucle: de paso apaga 0xE147
	ld a,008h		;49b2   ; 0xE122 es la orden para el dibujante de la interrupcion: 8 = sigue la bola
	ld (0e122h),a		;49b4
golpe_en_marcha:		; El bucle que deja jugar: sale cuando 0xE110 dice que la bola ha parado, o cuando en el modo de exhibicion se pulsa algo
	ld a,(0e002h)		;49b7   ; 0xE002: 1 en el modo de exhibicion, que juega solo
	or a			;49ba
	jr z,golpe_mira_si_ha_parado		;49bb
	ld a,(0e005h)		;49bd   ; en exhibicion, cualquier tecla (0xE005) corta la partida
	or a			;49c0
	jr nz,golpe_terminado		;49c1
golpe_mira_si_ha_parado:		; Comprueba 0xE110 y, al parar, deja el palo a cero y refresca
	ei			;49c3
	ld a,(0e110h)		;49c4   ; 0xE110 lo pone a 1 el vuelo de la bola cuando esta ha parado
	or a			;49c7
	jr z,golpe_en_marcha		;49c8
	xor a			;49ca
	ld (0e110h),a		;49cb   ; consumido el aviso, se vuelve a poner a cero
	ld (0e121h),a		;49ce   ; y el palo elegido (0xE121) se olvida
	call esconde_al_golfista		;49d1
	ei			;49d4
	ld a,(0e002h)		;49d5
	or a			;49d8
golpe_terminado:		; En exhibicion, cualquier tecla corta la partida
	jp nz,fin_de_la_partida		;49d9
	ld a,(0e141h)		;49dc   ; 0xE141: hay castigo, o sea golpe de penalizacion
	or a			;49df
	ld a,004h		;49e0   ; 4 es el rotulo de castigo, y se usa si 0xE141 esta puesto
	jr nz,avisa_del_resultado		;49e2
	ld a,(0e140h)		;49e4   ; 0xE140 es el terreno donde ha caido: 0 calle, 1 bunker, 2-3 rough, 4 fuera, 5 green
	or a			;49e7
	jp z,cuenta_el_golpe		;49e8   ; en la calle no hay nada que anunciar: derecho a contar el golpe
	ld b,a			;49eb
	ld a,b			;49ec
	cp 005h		;49ed   ; 5 es el green: se limpia y a jugar
	jr z,avisa_del_resultado_limpia		;49ef
	cp 004h		;49f1   ; 4 es fuera de limites, el unico que no para el juego
	jr nz,avisa_del_resultado		;49f3
	ld hl,0e126h		;49f5   ; 0xE126 pide que se rehaga el dibujo
	ld (hl),001h		;49f8
	ld l,022h		;49fa   ; 0xE122 = 8: el dibujante vuelve a seguir la bola
	ld (hl),008h		;49fc
avisa_del_resultado:		; Borra la linea de la VRAM 0x384C y saca por 0x4D63 el rotulo que toca -en el agua, en el bunker, fuera de limites-
	ld de,0784ch		;49fe   ; VRAM 0x384C, la linea de rotulos de debajo del panel
	ld bc,00800h		;4a01   ; rellena 8 celdas con el tile 0 (borrar) - el 0x7800 es el bit de escritura
	push af			;4a04   ; se guarda el rotulo elegido, que la llamada machaca A
	call rellena_vram_con_c_di		;4a05
	pop af			;4a08
	rlca			;4a09   ; el indice se dobla porque la tabla son punteros de dos bytes
	ld hl,04d61h		;4a0a   ; 0x4D61 es la tabla de rotulos, indexada desde 1: la entrada 0 cae encima
	call suma_a_a_hl		;4a0d   ; suma A a HL, que el Z80 no sabe hacerlo de una vez
	ld e,(hl)			;4a10
	inc hl			;4a11
	ld d,(hl)			;4a12
	ex de,hl			;4a13
	ld b,(hl)			;4a14   ; el primer byte del rotulo es su longitud
	inc hl			;4a15
avisa_del_resultado_parpadeo:		; Lo enciende y lo apaga hasta que 0xE111 llega a nueve
	call espera_un_cuadro		;4a16   ; el parpadeo va a un cuadro por vuelta
	push hl			;4a19
	push bc			;4a1a
	call alterna_el_parpadeo		;4a1b   ; alterna entre pintar el rotulo y dejarlo en blanco
	ld de,0784dh		;4a1e   ; VRAM 0x384D, una celda a la derecha del borrado
	call vuelca_b_bytes_en_vram_di		;4a21
	pop bc			;4a24
	pop hl			;4a25
	ld a,(0e111h)		;4a26   ; 0xE111 cuenta los parpadeos, y la interrupcion lo sube
	cp 009h		;4a29   ; nueve parpadeos y basta
	jr nz,avisa_del_resultado_parpadeo		;4a2b
	ld a,(0e141h)		;4a2d
	or a			;4a30
	jr nz,avisa_del_resultado_espera		;4a31
	ld a,(0e140h)		;4a33   ; sin castigo, solo el fuera de limites (4) para el juego
	cp 004h		;4a36
	jr nz,avisa_del_resultado_limpia		;4a38
avisa_del_resultado_espera:		; Cuando hay castigo, para el juego, pide el dibujo otra vez y espera cuatro cuadros
	ld hl,0e122h		;4a3a   ; 0xE122 = 0x10: el dibujante deja la bola y rehace la vista
	ld (hl),010h		;4a3d
	ld l,025h		;4a3f   ; 0xE125 pide el dibujo y se queda a 1 hasta que este hecho
	ld (hl),001h		;4a41
avisa_del_resultado_espera_bucle:		; El bucle de la espera
	ld a,(hl)			;4a43   ; espera aqui a que el dibujante ponga 0xE125 a cero
	or a			;4a44
	jr nz,avisa_del_resultado_espera_bucle		;4a45
	inc hl			;4a47
	ld (hl),000h		;4a48   ; 0xE126 a cero: el dibujo ya no hace falta
	ld l,041h		;4a4a   ; 0xE141 a 1: queda constancia del castigo para la cuenta
	ld (hl),001h		;4a4c
	ld a,004h		;4a4e   ; cuatro cuadros de respiro antes de seguir
	call espera_al_reloj		;4a50
avisa_del_resultado_limpia:		; Deja 0xE110 y 0xE111 a cero
	xor a			;4a53
	ld (0e110h),a		;4a54   ; el aviso de bola parada, consumido
	ld (0e111h),a		;4a57   ; y la cuenta de parpadeos, a cero
cuenta_el_golpe:		; Sube en uno -o en dos si hubo castigo- los golpes BCD del jugador, con tope 99
	ld hl,0e106h		;4a5a   ; 0xE106 son los golpes del jugador 1, 0xE107 los del 2, en BCD
	call de_quien_es_el_turno		;4a5d   ; deja Z si le toca al jugador 1
	jr z,cuenta_el_golpe_suma		;4a60
	inc hl			;4a62   ; al 2 le corresponde el byte siguiente
cuenta_el_golpe_suma:		; La suma con su ajuste decimal
	inc (hl)			;4a63   ; un golpe mas
	ld a,(0e141h)		;4a64   ; con castigo van dos
	or a			;4a67
	jr z,cuenta_el_golpe_limpia		;4a68
	inc (hl)			;4a6a   ; el segundo golpe, el de penalizacion
cuenta_el_golpe_limpia:		; Borra el castigo antes de sumar
	xor a			;4a6b
	ld (0e141h),a		;4a6c   ; el castigo ya esta cobrado
	add a,(hl)			;4a6f   ; A vale 0, asi que esto es solo para meter (hl) en A y poder ajustarlo
	daa			;4a70   ; el ajuste decimal: los golpes se llevan en BCD
	jr nc,cuenta_el_golpe_guarda		;4a71
	ld a,099h		;4a73   ; tope 99: dos digitos y no caben mas
cuenta_el_golpe_guarda:		; Guarda el resultado y refresca el marcador
	ld (hl),a			;4a75
	call pinta_los_golpes_del_hoyo		;4a76   ; y a la VRAM, que el marcador lo lee de ahi
	xor a			;4a79
	ld (0e003h),a		;4a7a   ; 0xE003 a cero: la partida deja de estar en marcha mientras se decide
	ld hl,0e10ah		;4a7d   ; 0xE10A y 0xE10B son la ficha de estado de cada jugador
	ld de,0e106h		;4a80
	call de_quien_es_el_turno		;4a83
	jr z,decide_quien_sigue		;4a86
	inc de			;4a88
	inc hl			;4a89
decide_quien_sigue:		; Con dos jugadores mira quien esta mas lejos; en partido por hoyos se va a 0x4AFD
	ld a,(0e012h)		;4a8a   ; 0xE012 es el modo: 2 es el partido por hoyos
	cp 002h		;4a8d
	jp z,partido_por_hoyos		;4a8f
	bit 0,(hl)		;4a92   ; el bit 0 de la ficha dice que acaba de embocar
	jr z,decide_quien_sigue_mira		;4a94
	set 1,(hl)		;4a96   ; y el bit 1, que ya ha terminado el hoyo
	call anuncia_el_resultado_del_hoyo		;4a98
decide_quien_sigue_mira:		; Vuelve a mirar si los dos han embocado
	call cambia_de_jugador		;4a9b   ; se mira al otro jugador
	bit 1,(hl)		;4a9e   ; si el otro tampoco ha terminado, otro golpe
	jr z,decide_quien_sigue_repite		;4aa0
	call cambia_de_jugador		;4aa2
	bit 1,(hl)		;4aa5
decide_quien_sigue_repite:		; Si queda alguien por jugar, otro golpe
	jp z,golpe_nuevo		;4aa7   ; mientras quede alguien sin embocar, se vuelve a golpear
	ld hl,0e106h		;4aaa
	ld de,0e12dh		;4aad   ; 0xE12D y 0xE12E: el resultado de cada jugador sobre el par
	push de			;4ab0
	ld b,001h		;4ab1   ; un jugador por defecto
	call que_modo_es		;4ab3   ; deja Z en el modo de un jugador
	jr z,cuenta_sobre_el_par		;4ab6
	inc b			;4ab8   ; con dos jugadores hay que hacer la cuenta dos veces
cuenta_sobre_el_par:		; Resta el par (0xE101) a los golpes de cada jugador y deja el resultado en 0xE12D
	ld a,(0e101h)		;4ab9   ; 0xE101 es el par del hoyo que se acaba de jugar
	ld c,a			;4abc
	push hl			;4abd
	ld a,(hl)			;4abe
	sub c			;4abf   ; golpes menos par: negativo es birdie o mejor
	jp m,cuenta_sobre_el_par_guarda		;4ac0   ; si sale negativo NO se ajusta: el signo se guarda tal cual
	daa			;4ac3   ; y si no, ajuste decimal, que la resta era BCD
cuenta_sobre_el_par_guarda:		; Guarda la diferencia de un jugador
	ld (de),a			;4ac4
	inc de			;4ac5
	pop hl			;4ac6
	inc hl			;4ac7
	djnz cuenta_sobre_el_par		;4ac8
	pop hl			;4aca
	ld c,000h		;4acb
	call que_modo_es		;4acd
	jr z,hoyo_acabado		;4ad0
	ld a,(hl)			;4ad2
	add a,002h		;4ad3   ; se le suman 2 a cada uno para que la comparacion no cruce el cero
	ld b,a			;4ad5
	inc hl			;4ad6
	ld a,(hl)			;4ad7
	add a,002h		;4ad8
	cp b			;4ada
	jr nc,hoyo_acabado		;4adb   ; el que tenga menos manda
	inc c			;4add
hoyo_acabado:		; Decide de quien es el honor en el hoyo siguiente y refresca el marcador
	ld a,c			;4ade
	ld (0e013h),a		;4adf   ; 0xE013 dice de quien es el honor, o sea quien abre el hoyo siguiente
	call acumula_sobre_el_par		;4ae2   ; y de paso acumula lo que ha hecho sobre el par en el total
hoyo_acabado_espera:		; Suena el 0x86, borra los golpes del hoyo y vuelve a 0x4836
	ld a,004h		;4ae5
	call espera_al_reloj		;4ae7   ; cuatro cuadros antes de anunciar nada
	ld a,086h		;4aea   ; 0x86 es el sonido de hoyo terminado
	call pide_un_sonido		;4aec
	ld hl,00000h		;4aef   ; 0xE10A y 0xE10B de golpe: las fichas de los dos jugadores, a cero
	ld (0e10ah),hl		;4af2
	ld a,006h		;4af5   ; seis cuadros mas y al hoyo siguiente
	call espera_al_reloj		;4af7
	jp turno_nuevo		;4afa
partido_por_hoyos:		; La rama del tercer modo: quien gana el hoyo se apunta uno
	bit 0,(hl)		;4afd   ; el bit 0 dice que este jugador acaba de embocar
	jr z,partido_por_hoyos_mira		;4aff
	call anuncia_el_resultado_del_hoyo		;4b01   ; el que emboca primero se lleva el anuncio
partido_por_hoyos_mira:		; Refresca y compara los golpes de los dos
	call cambia_de_jugador		;4b04   ; y se mira lo que ha hecho el otro
	ld de,0e106h		;4b07   ; 0xE106: los golpes de los dos jugadores, seguidos
	ld hl,0e10ah		;4b0a   ; 0xE10A: sus dos fichas de estado, tambien seguidas
	bit 0,(hl)		;4b0d
	jr nz,partido_por_hoyos_gana_1		;4b0f
partido_por_hoyos_compara:		; Reparte el hoyo segun quien haya embocado antes y con cuantos golpes
	bit 0,(hl)		;4b11
	jr nz,partido_por_hoyos_gana_2		;4b13
	inc hl			;4b15
	bit 0,(hl)		;4b16
	jr z,partido_por_hoyos_sigue		;4b18
	ex de,hl			;4b1a
	inc hl			;4b1b
	ld a,(hl)			;4b1c
	dec hl			;4b1d
	dec a			;4b1e   ; un golpe menos: para ganar el hoyo hay que hacerlo con MENOS, no con los mismos
	cp (hl)			;4b1f
	jr c,$+43		;4b20   ; salta a 0x4B4B; sale como $+43 porque en medio hay un bloque de datos
	jr partido_por_hoyos_sigue		;4b22
partido_por_hoyos_gana_2:		; Gana el segundo
	ex de,hl			;4b24
	ld a,(hl)			;4b25
	dec a			;4b26   ; la misma resta, mirando desde el otro jugador
	inc hl			;4b27
	cp (hl)			;4b28
	jr c,partido_por_hoyos_empate		;4b29
partido_por_hoyos_sigue:		; Nadie ha acabado: otro golpe
	jp golpe_nuevo		;4b2b
partido_por_hoyos_gana_1:		; Gana el primero
	inc hl			;4b2e
	bit 0,(hl)		;4b2f
	dec hl			;4b31
	jr z,partido_por_hoyos_compara		;4b32
	ex de,hl			;4b34
	ld a,(hl)			;4b35
	inc hl			;4b36
	cp (hl)			;4b37
	jr z,$+35		;4b38   ; mismos golpes: el hoyo se reparte
	jr nc,$+17		;4b3a
partido_por_hoyos_empate:		; Reparte el hoyo y sube el contador de hoyos jugados
	xor a			;4b3c
	ld (0e013h),a		;4b3d   ; 0xE013 a cero: el honor vuelve al jugador 1
	ld hl,0e108h		;4b40   ; 0xE108 son los hoyos que lleva ganados el jugador 1
	inc (hl)			;4b43
	call lee_parametro		;4b44   ; el guion del aviso va detras del CALL, en linea

; ----------------------------------------------------------------------
; DATOS parametro_4b47: Parametro en linea del call de 0x4B44: apunta a 0x4ED8
;   0x4b47..0x4b49  (2 bytes)
DATA_parametro_4b47:
	defw 04ed8h	; 4b47  -> DATA_guion_aviso_1

; ======================================================================
; CODIGO 0x4b49..0x4b57  (14 bytes)
; ======================================================================


partido_por_hoyos_apunta_1:		; Sigue tras el guion del aviso: uno mas para el jugador 1 (0xE108)
	jr $+31		;4b49
partido_por_hoyos_apunta_2:		; Uno mas para el jugador 2 (0xE109)
	ld a,001h		;4b4b
	ld (0e013h),a		;4b4d   ; 0xE013 a 1: el honor pasa al jugador 2
	ld hl,0e109h		;4b50   ; 0xE109, los hoyos ganados por el jugador 2
	inc (hl)			;4b53
	call lee_parametro		;4b54

; ----------------------------------------------------------------------
; DATOS parametro_4b57: Parametro en linea del call de 0x4B54: apunta a 0x4EE6
;   0x4b57..0x4b59  (2 bytes)
DATA_parametro_4b57:
	defw 04ee6h	; 4b57  -> DATA_guion_aviso_2

; ======================================================================
; CODIGO 0x4b59..0x4b66  (13 bytes)
; ======================================================================


partido_por_hoyos_apunta_2_sigue:		; Sigue tras su guion
	jr $+15		;4b59
partido_por_hoyos_empatado:		; Sube 0xE112, los hoyos jugados, sin dar el hoyo a nadie
	xor a			;4b5b
	ld (0e013h),a		;4b5c
	ld hl,0e112h		;4b5f   ; 0xE112 son los hoyos repartidos, que no se apunta nadie
	inc (hl)			;4b62
	call lee_parametro		;4b63

; ----------------------------------------------------------------------
; DATOS parametro_4b66: Parametro en linea del call de 0x4B63: apunta a 0x4EF4
;   0x4b66..0x4b68  (2 bytes)
DATA_parametro_4b66:
	defw 04ef4h	; 4b66  -> DATA_guion_empate

; ======================================================================
; CODIGO 0x4b68..0x4be4  (124 bytes)
; ======================================================================


partido_por_hoyos_mira_el_final:		; Se acaba a los nueve hoyos, o antes si al que va ganando ya no le pueden alcanzar
	ei			;4b68
	ld hl,0e112h		;4b69
	ld a,(hl)			;4b6c
	cp 009h		;4b6d   ; nueve hoyos y se acabo
	jr z,fin_de_la_partida		;4b6f
	srl a		;4b71   ; la mitad de los hoyos repartidos
	ld b,a			;4b73
	ld a,005h		;4b74   ; de los nueve caben 5 victorias como mucho: 5 menos la mitad de los empatados
	sub b			;4b76
	ld hl,0e108h		;4b77
	cp (hl)			;4b7a   ; si al que va ganando ya no le pueden alcanzar, se acaba antes
	jr z,fin_de_la_partida		;4b7b
	inc hl			;4b7d
	cp (hl)			;4b7e
	jp nz,hoyo_acabado_espera		;4b7f
fin_de_la_partida:		; Para el juego, pide la musica 0x8A, esconde los sprites y monta la pantalla de la tarjeta
	xor a			;4b82
	ld (0e003h),a		;4b83   ; 0xE003 a cero: se para el juego
	ld a,08ah		;4b86   ; 0x8A es la musica del final
	call pide_un_sonido		;4b88
	call corta_la_lista_de_sprites		;4b8b
	ld a,(0e002h)		;4b8e   ; en exhibicion no se ensena la tarjeta
	or a			;4b91
	jr nz,$+128		;4b92
	ld hl,0e1e0h		;4b94   ; 0xE1E0 es donde 0x5CC1 arma la fila de resultados
	ld de,07801h		;4b97   ; VRAM 0x3801, la primera fila de la pantalla
fin_de_la_partida_tarjeta:		; Copia a la VRAM 0x3801 la fila de resultados que arma 0x5CC1
	call lee_un_byte_de_vram		;4b9a
	ld (hl),a			;4b9d
	inc de			;4b9e
	inc hl			;4b9f
	djnz fin_de_la_partida_tarjeta		;4ba0
	ei			;4ba2
	ld h,000h		;4ba3
	ld d,h			;4ba5
	ld a,(0e012h)		;4ba6   ; modo 2: partido por hoyos, que se decide por hoyos ganados
	cp 002h		;4ba9
	jr z,fin_de_la_partida_por_hoyos		;4bab
	call que_modo_es		;4bad
	scf			;4bb0
	jr z,fin_de_la_partida_rotulo		;4bb1
	ld hl,(0e10eh)		;4bb3   ; 0xE10E y 0xE10C: los totales de los dos jugadores, byte alto primero
	ld e,h			;4bb6   ; les da la vuelta, que la cuenta esta en BCD al reves
	ld d,l			;4bb7
	push de			;4bb8
	ld hl,(0e10ch)		;4bb9
	ld e,h			;4bbc
	ld d,l			;4bbd
	ex de,hl			;4bbe
	pop de			;4bbf
	jr fin_de_la_partida_compara		;4bc0
fin_de_la_partida_por_hoyos:		; En partido por hoyos compara los hoyos ganados en vez de los golpes
	ld a,(0e108h)		;4bc2
	ld e,a			;4bc5
	ld a,(0e109h)		;4bc6
	ld l,a			;4bc9
fin_de_la_partida_compara:		; La resta que dice quien gana
	or a			;4bca
	sbc hl,de		;4bcb   ; la resta que decide: con acarreo gana el primero
fin_de_la_partida_rotulo:		; Elige el guion del aviso ganador: 0x4ED8 o 0x4EE6
	ld hl,04ed8h		;4bcd   ; 0x4ED8 es el guion que dice que gana el jugador 1
	ld de,0e1e0h		;4bd0
	ld bc,07801h		;4bd3
	jr c,$+18		;4bd6
	ld hl,04ee6h		;4bd8   ; y 0x4EE6 el del jugador 2
	ld e,0eah		;4bdb
	ld c,00bh		;4bdd
	jr nz,$+9		;4bdf
	call lee_parametro		;4be1

; ----------------------------------------------------------------------
; DATOS parametro_4be4: Parametro en linea del call de 0x4BE1: apunta a 0x4EF4
;   0x4be4..0x4be6  (2 bytes)
DATA_parametro_4be4:
	defw 04ef4h	; 4be4  -> DATA_guion_empate

; ======================================================================
; CODIGO 0x4be6..0x4cfe  (280 bytes)
; ======================================================================


fin_de_la_partida_sin_rotulo:		; Cuando no hay nada que anunciar, directo a la espera
	jr fin_de_la_partida_espera		;4be6
fin_de_la_partida_anuncia:		; Pinta el guion del ganador y lo hace parpadear
	push de			;4be8
	push bc			;4be9
	call que_modo_es		;4bea   ; en el modo de un jugador no hay ganador que anunciar
	jr z,fin_de_la_partida_prepara		;4bed
	call pinta_guion		;4bef
fin_de_la_partida_prepara:		; Recupera los punteros del parpadeo
	pop de			;4bf2
	pop hl			;4bf3
	ei			;4bf4
fin_de_la_partida_parpadea:		; Enciende y apaga los diez tiles hasta que 0xE111 llega a diecisiete
	call espera_un_cuadro		;4bf5
	push hl			;4bf8
	push de			;4bf9
	call alterna_el_parpadeo		;4bfa
	ld b,00ah		;4bfd   ; el rotulo del ganador son diez tiles
	call vuelca_b_bytes_en_vram_di		;4bff   ; diez tiles: los que ocupa 1P WIN o 2P WIN
	pop de			;4c02
	pop hl			;4c03
	ld a,(0e111h)		;4c04
	cp 011h		;4c07   ; diecisiete parpadeos, casi el doble que los del hoyo
	jr nz,fin_de_la_partida_parpadea		;4c09
fin_de_la_partida_espera:		; Espera a que se acabe la musica
	ei			;4c0b
	ld a,(0e663h)		;4c0c   ; espera a que el canal 3 termine la musica del final
	or a			;4c0f
	jr nz,fin_de_la_partida_espera		;4c10
vuelve_al_arranque:		; Cierra las interrupciones y salta a INIT: la maquina vuelve al titulo
	di			;4c12   ; cierra la interrupcion antes de saltar a INIT
	jp init		;4c13   ; no hay vuelta al menu: se rearranca el cartucho entero
anuncia_el_resultado_del_hoyo:		; Resta el par a los golpes y suma tres: 1 es EAGLE, 2 BIRDIE, 3 PAR, 4 BOGEY y 5 el doble bogey. Fuera de ese rango no dice nada. Elige el rotulo en 0x4CFE y lo hace parpadear en la VRAM 0x384C
	ex de,hl			;4c16
	ld a,(hl)			;4c17
	ld hl,0e101h		;4c18   ; 0xE101, el par del hoyo
	sub (hl)			;4c1b
	add a,003h		;4c1c   ; golpes menos par mas tres: 1 EAGLE, 2 BIRDIE, 3 PAR, 4 BOGEY, 5 doble bogey
	or a			;4c1e
	ret z			;4c1f   ; un albatros o mejor se sale de la tabla y no se anuncia
	cp 006h		;4c20   ; y de triple bogey para arriba, tampoco
	ret nc			;4c22
	dec a			;4c23   ; la tabla se indexa desde 0
	push af			;4c24
	ld de,0784ch		;4c25   ; VRAM 0x384C, la linea de rotulos
	ld bc,008c9h		;4c28   ; ocho celdas del tile 0xC9
	call esta_en_el_green		;4c2b   ; en el green se borra con otro tile, que el fondo es verde
	jr nz,anuncia_el_resultado_borra		;4c2e
	ld c,034h		;4c30   ; en el green se borra con el 0x34, que es el verde
anuncia_el_resultado_borra:		; Limpia la linea antes de escribir
	call rellena_vram_con_c_di		;4c32
	pop af			;4c35
	ld hl,04cfeh		;4c36
	rlca			;4c39   ; el indice se dobla: la tabla son punteros de dos bytes
	call suma_a_a_hl		;4c3a
	ld e,(hl)			;4c3d
	inc hl			;4c3e
	ld d,(hl)			;4c3f
	ex de,hl			;4c40
	ld b,(hl)			;4c41   ; el primer byte del rotulo dice cuantos tiles ocupa
	inc hl			;4c42
anuncia_el_resultado_parpadeo:		; Enciende y apaga el rotulo hasta que 0xE111 llega a nueve
	call espera_un_cuadro		;4c43
	push hl			;4c46
	call alterna_el_parpadeo		;4c47   ; la misma llamada pinta en las vueltas impares y borra en las pares
	push bc			;4c4a
	ld de,0784ch		;4c4b
	call vuelca_b_bytes_en_vram_di		;4c4e
	pop bc			;4c51
	pop hl			;4c52
	ld a,(0e111h)		;4c53
	cp 009h		;4c56   ; nueve parpadeos, como los del resultado del golpe
	jr nz,anuncia_el_resultado_parpadeo		;4c58
	xor a			;4c5a
	ld (0e111h),a		;4c5b
	ld de,0784ch		;4c5e
	ld bc,00834h		;4c61   ; ocho celdas del tile 0x34, el verde del green
	ld a,(0e146h)		;4c64   ; 0xE146 dice si hay que dejar la linea limpia al salir
	or a			;4c67
	ret z			;4c68
	jp rellena_vram_con_c_di		;4c69
pinta_tres_cifras:		; Escribe en la VRAM el nibble bajo del primer byte y luego las dos cifras del siguiente
	di			;4c6c
	call abre_la_vram_para_escribir_2		;4c6d
	ld a,(hl)			;4c70
	call pinta_cifra		;4c71   ; la primera cifra sale del nibble bajo: son centenas de metro
	inc hl			;4c74
	inc de			;4c75
pinta_dos_cifras_di:		; 0x4C7C entre di y ei
	di			;4c76
	call pinta_dos_cifras		;4c77
	ei			;4c7a
	ret			;4c7b
pinta_dos_cifras:		; Las dos cifras BCD del byte de (HL) como tiles 0xF0 a 0xF9
	call abre_la_vram_para_escribir		;4c7c
	ld a,(hl)			;4c7f   ; el byte lleva las dos cifras BCD juntas
	ld c,a			;4c80   ; se guarda el byte, que pinta_cifra_alta lo machaca
	call pinta_cifra_alta		;4c81
	ld a,c			;4c84
	call pinta_cifra		;4c85
	inc hl			;4c88
	ret			;4c89
pinta_cifra_alta:		; Baja el nibble alto y sigue
	rrca			;4c8a   ; cuatro rotaciones bajan el nibble alto al bajo
	rrca			;4c8b
	rrca			;4c8c
	rrca			;4c8d
pinta_cifra:		; Escribe el nibble bajo de A como tile 0xF0 mas la cifra
	and 00fh		;4c8e   ; cada cifra es su propio tile: 0xF0 el cero, 0xF9 el nueve
	or 0f0h		;4c90
	push bc			;4c92
	push af			;4c93
	ld a,(00007h)		;4c94   ; el byte 7 de la ROM de la BIOS guarda el puerto de datos del VDP: se lee de ahi en vez de escribir 0x98, y asi vale en cualquier maquina
	ld c,a			;4c97
	pop af			;4c98
	out (c),a		;4c99   ; escribe el tile por el puerto que acaba de leer
	pop bc			;4c9b
	ret			;4c9c
cambia_de_jugador:		; Guarda las 21 variables del que jugaba (0xE130) y la ficha de sus sprites, decide con la distancia que falta a quien le toca y recupera las suyas
	ld hl,0e130h		;4c9d   ; 0xE130 son las 21 variables del jugador que esta jugando
	ld de,0e180h		;4ca0   ; 0xE180 el archivo del jugador 1, 0xE198 el del 2
	ld bc,00015h		;4ca3   ; 21 bytes por jugador
	call de_quien_es_el_turno		;4ca6
	jr z,cambia_de_jugador_guarda		;4ca9
	ld e,098h		;4cab   ; al jugador 2 le toca 0xE198
cambia_de_jugador_guarda:		; El ldir que guarda
	ldir		;4cad   ; las 21 variables del que sale, a su archivo
	ld hl,0e0b0h		;4caf   ; 0xE0B0 es la ficha de sprites del jugador que esta jugando
	ld e,0c0h		;4cb2   ; 0xE0C0 la del jugador 1, 0xE0D0 la del 2
	call de_quien_es_el_turno		;4cb4
	jr z,cambia_de_jugador_borra		;4cb7
	ld e,0d0h		;4cb9
cambia_de_jugador_borra:		; Limpia las variables de trabajo de 0xE030
	call copia_dieciseis_bytes		;4cbb   ; tambien se guardan los dieciseis bytes de sus sprites
	ld hl,0e030h		;4cbe
	ld c,0afh		;4cc1   ; 175 bytes de trabajo, de 0xE030 a 0xE0DE
	call borra_memoria		;4cc3   ; y se limpian las 175 de trabajo de 0xE030
	xor a			;4cc6
	ld hl,(0e14eh)		;4cc7   ; 0xE14E y 0xE14C: lo que le queda a cada uno para el hoyo
	ex de,hl			;4cca
	ld hl,(0e14ch)		;4ccb
	sbc hl,de		;4cce   ; juega el que este mas lejos, que es la regla del golf
	jr nc,cambia_de_jugador_apunta		;4cd0
	inc a			;4cd2
cambia_de_jugador_apunta:		; Anota el turno en 0xE013
	ld (0e013h),a		;4cd3   ; 0xE013 queda con el turno que acaba de salir
	ld de,0e130h		;4cd6
	ld hl,0e180h		;4cd9
	ld c,015h		;4cdc
	call de_quien_es_el_turno		;4cde
	jr z,cambia_de_jugador_recupera		;4ce1
	ld l,098h		;4ce3
cambia_de_jugador_recupera:		; El ldir que devuelve las del que entra
	ldir		;4ce5   ; y el mismo ldir al reves devuelve las del que entra
	ld de,0e0b0h		;4ce7
	ld l,0c0h		;4cea
	call de_quien_es_el_turno		;4cec
	jr z,cambia_de_jugador_sprites		;4cef
	ld l,0d0h		;4cf1
cambia_de_jugador_sprites:		; Recupera tambien los atributos de sus sprites y deja HL en su ficha de estado
	call copia_dieciseis_bytes		;4cf3
	ld l,00ah		;4cf6   ; al volver, HL apunta a la ficha de estado del jugador que juega
	call de_quien_es_el_turno		;4cf8
	ret z			;4cfb
	inc hl			;4cfc
	ret			;4cfd

; ----------------------------------------------------------------------
; DATOS punteros_de_los_avisos: Cinco punteros a los rotulos de 0x4D08. 0x4C36
;   elige con el resultado del golpe
;   0x4cfe..0x4d08  (10 bytes)
DATA_punteros_de_los_avisos:
	defw 04d13h,04d0ch,04d08h,04d19h,04d1fh	; 4cfe

; ----------------------------------------------------------------------
; DATOS avisos_del_golpe: Cinco rotulos, cada uno con su longitud delante y
;   luego los tiles. Leidos: PAR (0x4D08), BIRDIE (0x4D0C), EAGLE (0x4D13),
;   BOGEY (0x4D19) y D BOGEY (0x4D1F)
;   0x4d08..0x4d27  (31 bytes)
DATA_avisos_del_golpe:
	defb 003h,0d8h,0dah,0ddh,006h,0d0h,0d5h,0ddh,0d1h,0d5h,0dch,005h,0dch,0dah,0dfh,0d9h	; 4d08  ................
	defb 0dch,005h,0d0h,0d3h,0dfh,0dch,0dbh,007h,0d1h,000h,0d0h,0d3h,0dfh,0dch,0dbh	; 4d18  ...............

; ----------------------------------------------------------------------
; DATOS guion_marca_jugador_1: Guion de VRAM: 1P en la fila 0 columna 1 y otra
;   vez en la fila 4 columna 26. Va en linea tras el call de 0x4841
;   0x4d27..0x4d33  (12 bytes)
DATA_guion_marca_jugador_1:
	defb 078h,001h,082h,0f1h,0d8h,080h,078h,09ah,082h,0f1h,0d8h,000h	; 4d27  x.....x.....

; ----------------------------------------------------------------------
; DATOS guion_marca_jugador_2: Guion de VRAM: 2P en la fila 0 columna 11 y
;   otra vez en la fila 5 columna 26. Va en linea tras el call de 0x484B. Sus
;   dos ultimos bytes hacen ademas de entrada 0 de la tabla siguiente
;   0x4d33..0x4d3f  (12 bytes)
DATA_guion_marca_jugador_2:
	defb 078h,00bh,082h,0f2h,0d8h,080h,078h,0bah,082h,0f2h,0d8h,000h	; 4d33  x.....x.....

; ----------------------------------------------------------------------
; DATOS par_y_longitud_de_cada_hoyo: Nueve fichas de cuatro bytes que 0x4902
;   indexa con 0xE100 desde 0x4D3B y copia a 0xE101. El primer byte es EL PAR
;   y los dos siguientes LA LONGITUD en BCD, byte alto primero; el cuarto es
;   cero. Los nueve hoyos: par 4-4-4-5-3-4-4-4-4, que suma 36, y
;   4750-3600-3620-4750-1680-4770-4720-2440-4790, de los que 0x574A escribe en
;   pantalla solo los TRES primeros digitos. Como el rotulo del panel lleva
;   detras el tile de la M, son METROS: 475, 360, 362, 475, 168, 477, 472, 244
;   y 479, que suman 3512 para un par 36
;   0x4d3f..0x4d63  (36 bytes)
DATA_par_y_longitud_de_cada_hoyo:
	defb 004h,047h,050h,000h	; 4d3f
	defb 004h,036h,000h,000h	; 4d43
	defb 004h,036h,020h,000h	; 4d47
	defb 005h,047h,050h,000h	; 4d4b
	defb 003h,016h,080h,000h	; 4d4f
	defb 004h,047h,070h,000h	; 4d53
	defb 004h,047h,020h,000h	; 4d57
	defb 004h,024h,040h,000h	; 4d5b
	defb 004h,047h,090h,000h	; 4d5f

; ----------------------------------------------------------------------
; DATOS punteros_de_los_estados: Cinco punteros a los rotulos de 0x4D6D,
;   indexados desde 0x4D61 con 0xE141, o sea que la entrada 0 cae en el guion
;   de arriba
;   0x4d63..0x4d6d  (10 bytes)
DATA_punteros_de_los_estados:
	defw 04d6dh,04d74h,04d74h,04d7ah,04d7fh	; 4d63

; ----------------------------------------------------------------------
; DATOS rotulos_de_estado: Cuatro rotulos con su longitud delante: BUNKER
;   (0x4D6D), ROUGH (0x4D74), OB (0x4D7A, con sus espacios) y GREEN (0x4D7F).
;   0x4A16 los hace parpadear alternandolos con los ceros de 0x4D85, y 0x4D63
;   los reparte segun 0xE140: 1 bunker, 2 y 3 rough, 4 fuera de limites y 5
;   green
;   0x4d6d..0x4d85  (24 bytes)
DATA_rotulos_de_estado:
	defb 006h,0d0h,0e5h,0e6h,0d7h,0dch,0ddh,005h,0ddh,0d3h,0e5h,0dfh,0e0h,004h,000h,0d3h	; 4d6d  ................
	defb 0d0h,000h,005h,0dfh,0ddh,0dch,0dch,0e6h	; 4d7d  ........

; ----------------------------------------------------------------------
; DATOS tiles_en_blanco: Doce ceros. 0x4F2E devuelve esta direccion en los
;   cuadros pares para borrar el rotulo que esta parpadeando. Son a la vez los
;   siete primeros bytes de la ficha 0 de 0x4D8A, que no se usa nunca
;   0x4d85..0x4d91  (12 bytes)
DATA_tiles_en_blanco:
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; 4d85  ............

; ----------------------------------------------------------------------
; DATOS ficha_de_salida_por_hoyo: Nueve bytes, uno por hoyo: cual de las cinco
;   fichas de 0x4D9A lleva el marcador del tee. 0x4851 los indexa con 0xE100,
;   que en ese momento todavia tiene el hoyo ANTERIOR -se sube despues, en
;   0x48E4-, o sea que el hoyo N lee 0x4D90+N. COMPROBADO CASILLA A CASILLA:
;   leido asi, en los NUEVE hoyos el marcador cae justo encima del 0xEA de la
;   rejilla, que es la salida
;   0x4d91..0x4d9a  (9 bytes)
DATA_ficha_de_salida_por_hoyo:
	defb 001h,002h,002h,001h,003h,001h,001h,005h,004h	; 4d91  .........

; ----------------------------------------------------------------------
; DATOS marcadores_de_salida: Cinco fichas de 16 bytes que 0x485F alcanza
;   sumando 16 tantas veces como diga la tabla de arriba. Cada ficha son
;   cuatro atributos de sprite: los dos primeros son la BOLA -en 0,0 hasta que
;   se juega- y los dos ultimos el marcador del tee, en dos capas (el 0x0C
;   negro debajo y el 0x08 blanco encima). Las cinco salidas: (0xB3,0xD3),
;   (0x9B,0xCB), (0x73,0xDB), (0xB3,0xCB) y (0x83,0xCB)
;   0x4d9a..0x4dea  (80 bytes)
DATA_marcadores_de_salida:
	defb 000h,000h,004h,001h	; 4d9a
	defb 000h,000h,000h,00fh	; 4d9e
	defb 0b3h,0d3h,00ch,001h	; 4da2
	defb 0b3h,0d3h,008h,00fh	; 4da6
	defb 000h,000h,004h,001h	; 4daa
	defb 000h,000h,000h,00fh	; 4dae
	defb 09bh,0cbh,00ch,001h	; 4db2
	defb 09bh,0cbh,008h,00fh	; 4db6
	defb 000h,000h,004h,001h	; 4dba
	defb 000h,000h,000h,00fh	; 4dbe
	defb 073h,0dbh,00ch,001h	; 4dc2
	defb 073h,0dbh,008h,00fh	; 4dc6
	defb 000h,000h,004h,001h	; 4dca
	defb 000h,000h,000h,00fh	; 4dce
	defb 0b3h,0cbh,00ch,001h	; 4dd2
	defb 0b3h,0cbh,008h,00fh	; 4dd6
	defb 000h,000h,004h,001h	; 4dda
	defb 000h,000h,000h,00fh	; 4dde
	defb 083h,0cbh,00ch,001h	; 4de2
	defb 083h,0cbh,008h,00fh	; 4de6

; ----------------------------------------------------------------------
; DATOS colores_del_golfista: Nueve colores, uno por sprite del monigote.
;   0x4996 los escribe de uno en uno en el byte de color de los atributos, a
;   partir de la VRAM 0x3B07: 0x0A 0x01 0x0A 0x01 0x0A 0x0F 0x05 0x0A 0x07
;   0x4dea..0x4df3  (9 bytes)
DATA_colores_del_golfista:
	defb 00ah,001h,00ah,001h,00ah,00fh,005h,00ah,007h	; 4dea  .........

; ======================================================================
; CODIGO 0x4df3..0x4e3a  (71 bytes)
; ======================================================================


parpadea_la_marca_de_turno:		; Con el juego parado, enciende y apaga los dos tiles de 0x4E3A o 0x4E3E segun de quien sea el turno
	ld a,(0e002h)		;4df3   ; en exhibicion no hay turno que marcar
	or a			;4df6
	ret nz			;4df7
	ld hl,04e3ah		;4df8   ; la ficha del jugador 1: destino y sus dos tiles
	ld de,04e3eh		;4dfb   ; y 0x4E3E la del jugador 2
	call de_quien_es_el_turno		;4dfe
	jr z,parpadea_la_marca_encendida		;4e01
	ex de,hl			;4e03
parpadea_la_marca_encendida:		; Con el bit 4 del contador escribe los tiles o dos ceros
	call abre_la_vram_de_la_ficha		;4e04
	ld a,(0e000h)		;4e07   ; 0xE000 es el contador de cuadros que lleva la interrupcion
	bit 4,a		;4e0a   ; el bit 4 cambia cada dieciseis cuadros: de ahi sale el parpadeo
	jr z,parpadea_la_marca_apagada		;4e0c
	ld bc,00000h		;4e0e   ; apagado es escribir dos ceros
	jr escribe_la_pareja_de_tiles		;4e11
parpadea_la_marca_apagada:		; La rama que borra
	call lee_la_pareja_de_tiles		;4e13
	ex de,hl			;4e16
	call que_modo_es		;4e17   ; en el modo de un jugador solo hay una marca que atender
	ret z			;4e1a
	call abre_la_vram_de_la_ficha		;4e1b
lee_la_pareja_de_tiles:		; Coge los dos tiles de (HL)
	ld b,(hl)			;4e1e
	inc hl			;4e1f
	ld c,(hl)			;4e20
escribe_la_pareja_de_tiles:		; Los saca por el puerto de datos del VDP
	push bc			;4e21
	pop hl			;4e22
	ld a,(00007h)		;4e23   ; otra vez el puerto de datos del VDP leido del byte 7 de la BIOS
	ld c,a			;4e26
	ld a,h			;4e27
	out (c),a		;4e28
	push af			;4e2a   ; un push y un pop que no hacen nada: son el respiro que el VDP necesita entre dos escrituras seguidas
	pop af			;4e2b
	ld a,l			;4e2c
	out (c),a		;4e2d
	ret			;4e2f
abre_la_vram_de_la_ficha:		; Toma de (HL) el destino, byte alto primero, y abre la VRAM alli
	push de			;4e30
	ld d,(hl)			;4e31   ; el destino viene byte alto primero, como en los guiones
	inc hl			;4e32
	ld e,(hl)			;4e33
	inc hl			;4e34
	call abre_la_vram_para_escribir		;4e35
	pop de			;4e38
	ret			;4e39

; ----------------------------------------------------------------------
; DATOS marca_de_turno: Dos fichas de cuatro bytes, una por jugador: destino
;   en VRAM -0x389A y 0x38BA, la columna 26 de las filas 4 y 5- y los dos
;   tiles que se ponen alli (0xF1 0xD8 y 0xF2 0xD8). 0x4DF8 coge la primera o
;   la segunda segun 0xE013, y 0x4E04 los enciende y apaga con el bit 4 del
;   contador de cuadros: es la marca que parpadea en el jugador al que le toca
;   0x4e3a..0x4e42  (8 bytes)
DATA_marca_de_turno:
	defb 078h,09ah,0f1h,0d8h	; 4e3a
	defb 078h,0bah,0f2h,0d8h	; 4e3e

; ======================================================================
; CODIGO 0x4e42..0x4ed8  (150 bytes)
; ======================================================================


pinta_el_resultado_sobre_el_par:		; Escribe en la VRAM 0x3803 el signo -0xCE si es cero, 0xCF si no- y las cifras de 0xE12B, y lo mismo para el segundo jugador
	ld hl,0e108h		;4e42
	ld de,07803h		;4e45   ; VRAM 0x3803, al lado del nombre del jugador
	ld b,001h		;4e48   ; un jugador por defecto
	call que_modo_es		;4e4a
	jr z,pinta_el_resultado_signo		;4e4d
	inc b			;4e4f
	dec a			;4e50   ; con dos jugadores el indice baja uno
	jr nz,pinta_el_resultado_solo_cifras		;4e51
pinta_el_resultado_signo:		; Elige el tile del signo
	ld a,(0e12bh)		;4e53   ; 0xE12B es lo que este jugador hizo sobre el par en el hoyo
pinta_el_resultado_cifra:		; Escribe signo y cifras de un jugador
	push bc			;4e56
	ld c,0ceh		;4e57   ; 0xCE es el tile del cero raso, sin signo
	or a			;4e59
	jr z,pinta_el_resultado_numero		;4e5a
	inc c			;4e5c   ; y 0xCF el del signo, para todo lo que no sea cero
pinta_el_resultado_numero:		; El volcado del signo
	ld b,001h		;4e5d
	call rellena_vram_con_c_di		;4e5f   ; el signo ocupa una sola celda
	inc de			;4e62
	call pinta_dos_cifras_di		;4e63   ; y detras van sus dos cifras
	ld a,(0e12ch)		;4e66   ; 0xE12C, lo mismo del segundo jugador
	ld e,00dh		;4e69   ; VRAM 0x380D, donde va la cifra del jugador 2
	pop bc			;4e6b
	djnz pinta_el_resultado_cifra		;4e6c
	ret			;4e6e
pinta_el_resultado_solo_cifras:		; La rama sin signo
	inc de			;4e6f
pinta_el_resultado_bucle:		; Repite por jugador
	call pinta_dos_cifras_di		;4e70
	ld de,0780eh		;4e73
	djnz pinta_el_resultado_bucle		;4e76
	ret			;4e78
acumula_sobre_el_par:		; Suma en BCD a 0xE108 lo que el jugador acaba de hacer sobre el par (0xE12B), llevando aparte el signo: los valores de 0xF0 para arriba cuentan como negativos
	ld hl,0e108h		;4e79   ; 0xE108 y 0xE109 llevan el acumulado sobre el par de cada uno
	ld de,0e12bh		;4e7c   ; 0xE12B y 0xE12C, lo del hoyo que se acaba de jugar
	ld b,001h		;4e7f
	call que_modo_es		;4e81
	jr z,acumula_sobre_el_par_uno		;4e84
	inc b			;4e86
acumula_sobre_el_par_uno:		; Una suma por jugador
	push de			;4e87
	push bc			;4e88
	ld b,000h		;4e89   ; B llevara el signo del acumulado: 0 positivo, 1 negativo
	ld a,(de)			;4e8b   ; 0xE12B a cero quiere decir que el jugador ha hecho el par
	or a			;4e8c
	inc de			;4e8d
	inc de			;4e8e
	ld a,(de)			;4e8f   ; 0xE12D dice si lo del hoyo va en negativo
	dec de			;4e90
	dec de			;4e91
	jr z,acumula_sobre_el_par_signo		;4e92
	cp 0f0h		;4e94   ; los valores de 0xF0 para arriba son negativos disfrazados de BCD
	jr c,acumula_sobre_el_par_resta		;4e96
	neg		;4e98   ; se le da la vuelta para poder sumarlo como positivo
acumula_sobre_el_par_suma:		; La rama que suma
	add a,(hl)			;4e9a
	daa			;4e9b   ; la suma es decimal: todo el marcador va en BCD
	ld (hl),a			;4e9c
	jr acumula_sobre_el_par_tope		;4e9d
acumula_sobre_el_par_resta:		; La rama que resta, con su complemento a diez si se pasa
	ld c,a			;4e9f
	ld a,(hl)			;4ea0
	sub c			;4ea1   ; acumulado menos lo del hoyo
	jr nc,acumula_sobre_el_par_guarda		;4ea2
	ex de,hl			;4ea4
	ld (hl),b			;4ea5   ; al cruzar el cero se apunta el cambio de signo en la ficha
	ex de,hl			;4ea6
	daa			;4ea7
	ld c,a			;4ea8
	xor a			;4ea9
	sub c			;4eaa   ; el complemento a diez, que es como se niega un BCD
	daa			;4eab
	or a			;4eac
acumula_sobre_el_par_guarda:		; Ajusta y guarda
	daa			;4ead
	ld (hl),a			;4eae
	jr acumula_sobre_el_par_tope		;4eaf
acumula_sobre_el_par_signo:		; Cambia el signo cuando el acumulado cruza el cero
	cp 0f0h		;4eb1   ; con el acumulado a cero, el signo lo pone lo del hoyo
	jr c,acumula_sobre_el_par_suma		;4eb3
	ld b,001h		;4eb5
	neg		;4eb7
	jr acumula_sobre_el_par_resta		;4eb9
acumula_sobre_el_par_tope:		; Con desbordamiento deja 99 y pasa al jugador siguiente
	pop bc			;4ebb
	pop de			;4ebc
	jr nc,acumula_sobre_el_par_siguiente		;4ebd
	ld (hl),099h		;4ebf   ; desbordamiento: el marcador se queda en 99
acumula_sobre_el_par_siguiente:		; Avanza a la ficha del otro
	inc de			;4ec1
	inc hl			;4ec2
	djnz acumula_sobre_el_par_uno		;4ec3
	ret			;4ec5
pinta_los_golpes_del_hoyo:		; Las cifras BCD de 0xE106 en la VRAM 0x389D, y las del segundo en 0x38BD
	ld hl,0e106h		;4ec6
	ld de,0789dh		;4ec9   ; VRAM 0x389D, los golpes del hoyo del jugador 1
	call pinta_dos_cifras_di		;4ecc
	ld e,0bdh		;4ecf   ; y 0x38BD los del jugador 2, dos filas mas abajo
	call que_modo_es		;4ed1
	ret z			;4ed4   ; en el modo de un jugador no hay segunda cifra
	jp pinta_dos_cifras_di		;4ed5

; ----------------------------------------------------------------------
; DATOS guion_aviso_1: Guion de VRAM: 10 tiles en 0x3967 que dicen 1P WIN. Va
;   en linea tras los calls de 0x4B44 y 0x4B63
;   0x4ed8..0x4ee6  (14 bytes)
DATA_guion_aviso_1:
	defb 079h,067h,08ah,000h,000h,0f1h,0d8h,000h,0e3h,0d5h,0e6h,000h,000h,000h	; 4ed8  yg............

; ----------------------------------------------------------------------
; DATOS guion_aviso_2: Guion de VRAM: otros 10 tiles en el mismo sitio, 2P
;   WIN. Va en linea tras el call de 0x4B54
;   0x4ee6..0x4ef4  (14 bytes)
DATA_guion_aviso_2:
	defb 079h,067h,08ah,000h,000h,0f2h,0d8h,000h,0e3h,0d5h,0e6h,000h,000h,000h	; 4ee6  yg............

; ----------------------------------------------------------------------
; DATOS guion_empate: Guion de VRAM: 8 tiles en 0x3968 que dicen EVEN, el
;   empate. Va en linea tras los calls de 0x4B63 y 0x4BE1
;   0x4ef4..0x4f00  (12 bytes)
DATA_guion_empate:
	defb 079h,068h,088h,000h,000h,0dch,0e2h,0dch,0e6h,000h,000h,000h	; 4ef4  yh..........

; ======================================================================
; CODIGO 0x4f00..0x513a  (570 bytes)
; ======================================================================


que_modo_es:		; Devuelve 0xE012 -0 un jugador, 1 dos, 2 partido por hoyos- con Z si vale cero
	ld a,(0e012h)		;4f00
	or a			;4f03
	ret			;4f04
esconde_al_golfista:		; Pone 0xCF en la coordenada y de los nueve sprites del monigote, desde la VRAM 0x3B04
	ld de,07b04h		;4f05   ; VRAM 0x3B04, la y del primero de los nueve sprites del monigote
	ld b,009h		;4f08
esconde_al_golfista_uno:		; Un sprite por vuelta
	push bc			;4f0a
	ld bc,001cfh		;4f0b   ; 0xCF en la y esconde un sprite: es la coordenada que el VDP no dibuja
	call rellena_vram_con_c		;4f0e   ; 0xCF en la y, una sola celda
	inc de			;4f11   ; cuatro bytes por atributo, asi que de cuatro en cuatro
	inc de			;4f12
	inc de			;4f13
	inc de			;4f14
	pop bc			;4f15
	djnz esconde_al_golfista_uno		;4f16
	ret			;4f18
espera_un_cuadro:		; No vuelve hasta que la interrupcion enciende el bit 4 del contador 0xE000, y entonces lo pone a cero
	ld a,(0e000h)		;4f19   ; 0xE000 es el contador de cuadros de la interrupcion
	bit 4,a		;4f1c   ; el bit 4 se enciende cada dieciseis cuadros
	jr z,espera_un_cuadro		;4f1e
	xor a			;4f20
	ld (0e000h),a		;4f21   ; se consume: la espera siguiente vuelve a empezar de cero
	ret			;4f24
alterna_el_parpadeo:		; Sube 0xE111 y, en las vueltas pares, cambia HL por los ceros de 0x4D85: asi la misma llamada pinta y borra
	ld a,(0e111h)		;4f25
	inc a			;4f28   ; 0xE111 cuenta los parpadeos
	ld (0e111h),a		;4f29
	rrca			;4f2c   ; el bit 0 al acarreo: en las vueltas impares se pinta
	ret c			;4f2d
	ld hl,04d85h		;4f2e   ; y en las pares se apunta a doce ceros, que borran
	ret			;4f31
vuelca_cuatro_bytes:		; Un atributo de sprite entero de HL a la VRAM DE
	ld b,004h		;4f32   ; un atributo de sprite son cuatro bytes: y, x, patron y color
	jp vuelca_b_bytes_en_vram		;4f34   ; el volcado lo hace la rutina general
un_cuadro_del_juego:		; Lo que la interrupcion corre en cada cuadro. Los seis bits de 0xE122 dicen que toca: el 0 la bola (0x6C2F), el 1 la barra de fuerza (0x4FE4), el 2 la mira (0x5301), el 3 montar la vista (0x5501), el 4 el cierre del golpe (0x4F66) y el 5 el monigote (0x57F0). Al final siempre refresca los sprites y la marca de turno
	xor a			;4f37   ; la lista de lo pendiente se limpia segun se atiende
	ld (0e014h),a		;4f38
	ld a,(0e122h)		;4f3b   ; 0xE122: un bit por tarea pendiente de este cuadro
	rrca			;4f3e   ; el bit 0 al acarreo, y `call c` lo atiende solo si estaba puesto
	push af			;4f3f
	call c,mueve_la_bola		;4f40   ; bit 0: la bola en vuelo
	pop af			;4f43
	rrca			;4f44
	push af			;4f45
	call c,mueve_la_barra_de_fuerza		;4f46   ; bit 1: la barra de fuerza subiendo y bajando
	pop af			;4f49
	rrca			;4f4a
	push af			;4f4b
	call c,elige_el_golpe		;4f4c   ; bit 2: la mira del golpe
	pop af			;4f4f
	rrca			;4f50
	push af			;4f51
	call c,monta_la_vista		;4f52   ; bit 3: montar la vista en perspectiva
	pop af			;4f55
	rrca			;4f56
	push af			;4f57
	call c,cierra_el_golpe		;4f58   ; bit 4: el cierre del golpe
	pop af			;4f5b
	rrca			;4f5c
	call c,anima_el_swing		;4f5d   ; bit 5: los cuadros del swing
	call mira_si_ha_embocado		;4f60   ; embocar se mira siempre, este puesto el bit que este
	jp parpadea_la_marca_de_turno		;4f63   ; y la marca de turno parpadea en todos los cuadros
cierra_el_golpe:		; Rehace la vista y, si la bola acabo en el agua o fuera, la devuelve a donde estaba antes del golpe
	call rehace_la_vista		;4f66
	ld a,(0e141h)		;4f69   ; 0xE141: el golpe se ha llevado castigo
	or a			;4f6c
	jr nz,cierra_el_golpe_castigo		;4f6d
	ld a,(0e140h)		;4f6f   ; 0xE140, el terreno donde ha caido la bola
	or a			;4f72
	jr z,cierra_el_golpe_limpia		;4f73
	cp 004h		;4f75   ; 4 es fuera de limites, que tambien devuelve la bola
	jr nz,cierra_el_golpe_termina		;4f77
cierra_el_golpe_castigo:		; Recupera la ficha de sprites guardada en 0xE1C0 y vuelve a montar la vista
	ld a,(0e125h)		;4f79
	rrca			;4f7c   ; el bit 0 de 0xE125 dice que el dibujo ya esta hecho
	jr nc,cierra_el_golpe_termina		;4f7d
	xor a			;4f7f
	ld (0e141h),a		;4f80   ; el castigo, cobrado
	ld hl,0e1c0h		;4f83   ; 0xE1C0 guarda los sprites tal como estaban ANTES del golpe
	ld de,0e0b0h		;4f86
	call de_quien_es_el_turno		;4f89
	jr z,cierra_el_golpe_repinta		;4f8c
	ld l,0d0h		;4f8e
cierra_el_golpe_repinta:		; El segundo repintado
	call copia_dieciseis_bytes		;4f90
	call rehace_la_vista		;4f93
cierra_el_golpe_limpia:		; Deja 0xE125 a cero
	ld hl,0e125h		;4f96
	ld (hl),000h		;4f99
cierra_el_golpe_termina:		; Copia 0xE142 en 0xE143 y, si hay que redibujar el hoyo, lo pide; si no, da el golpe por terminado y enciende 0xE110
	ld hl,0e142h		;4f9b   ; 0xE142 en 0xE143: la vista de este cuadro pasa a ser la del anterior
	ld a,(hl)			;4f9e
	inc hl			;4f9f
	ld (hl),a			;4fa0
	ld hl,0e129h		;4fa1   ; 0xE129 dice que el hoyo hay que redibujarlo entero
	ld a,(hl)			;4fa4
	or a			;4fa5
	jr z,cierra_el_golpe_para		;4fa6
	xor a			;4fa8
	ld (hl),a			;4fa9
	inc a			;4faa
	ld (0e147h),a		;4fab   ; 0xE147 pide el repintado
	ld l,022h		;4fae   ; 0xE122 = 8: se vuelve a montar la vista
	ld (hl),008h		;4fb0
	ret			;4fb2
cierra_el_golpe_para:		; Apaga 0xE122 y avisa con 0xE110 de que la bola ha parado
	call calcula_lo_que_falta		;4fb3
	xor a			;4fb6
	ld (0e122h),a		;4fb7   ; nada pendiente: se apaga la lista de tareas
	inc a			;4fba
	ld (0e110h),a		;4fbb   ; y 0xE110 avisa al bucle de la partida de que la bola ha parado
	ret			;4fbe
esta_la_bola_cerca_del_tee:		; Con el segundo jugador, devuelve acarreo si la bola y el marcador estan a menos de tres pixeles
	call de_quien_es_el_turno		;4fbf   ; con un solo jugador no hay marcador de tee que estorbe
	ret z			;4fc2
	ld de,0e1c0h		;4fc3   ; 0xE1C0 el marcador del tee, 0xE0B0 la bola: se comparan sus dos coordenadas
	ld hl,0e0b0h		;4fc6
	ld a,(de)			;4fc9   ; el primer byte del atributo, que es la fila
	call diferencia_menor_de_tres		;4fca
	ret nc			;4fcd
	inc hl			;4fce   ; dos porque la comparacion de arriba deja los dos punteros uno por debajo: asi se acaba en el byte 1, la columna
	inc hl			;4fcf
	inc de			;4fd0
	inc de			;4fd1
	ld a,(de)			;4fd2
diferencia_menor_de_tres:		; El valor absoluto de la resta comparado con 3
	sub (hl)			;4fd3   ; la resta cruda entre las dos coordenadas; de paso DEJA los dos punteros retrasados un byte
	dec de			;4fd4
	dec hl			;4fd5
	jp p,diferencia_menor_de_tres_compara		;4fd6
	neg		;4fd9   ; el valor absoluto, que da igual por que lado se pase
diferencia_menor_de_tres_compara:		; La comparacion final con el 3
	cp 003h		;4fdb   ; tres pixeles de margen
	ret			;4fdd
rehace_la_vista:		; Recalcula la casilla de la bola y vuelve a montar el lienzo
	call donde_esta_la_bola		;4fde
	jp clasifica_el_terreno		;4fe1
mueve_la_barra_de_fuerza:		; Sube o baja 0xE1B0 -de 0 a 8- y, al llegar arriba, salta a la cuenta de 0xE1B1 y da la vuelta con 0xE1B2. Es la barra que decide la fuerza del golpe
	ld hl,0e1b2h		;4fe4   ; 0xE1B2: 0 mientras la barra sube, 1 cuando baja
	ld a,(hl)			;4fe7
	or a			;4fe8
	jr nz,mueve_la_barra_de_fuerza_baja		;4fe9
	dec hl			;4feb
	inc (hl)			;4fec   ; 0xE1B1 es el escalon de la barra, de 0 a 8
	ld a,(hl)			;4fed
	dec hl			;4fee
	cp 008h		;4fef   ; arriba del todo, en el 8
	jr nz,mueve_la_barra_de_fuerza_pinta		;4ff1
	inc hl			;4ff3
	ld (hl),000h		;4ff4   ; vuelve el escalon a cero
	dec hl			;4ff6
	inc (hl)			;4ff7   ; 0xE1B0 cuenta las pasadas enteras de la barra
	ld a,(hl)			;4ff8
	cp 00ah		;4ff9   ; a la decima pasada la barra se da la vuelta
	jr nz,mueve_la_barra_de_fuerza_pinta		;4ffb
	ld a,001h		;4ffd
	ld (0e1b2h),a		;4fff
	jr mueve_la_barra_de_fuerza_pinta		;5002
mueve_la_barra_de_fuerza_baja:		; La mitad que baja
	dec hl			;5004
	dec (hl)			;5005
	ld a,(hl)			;5006
	dec hl			;5007
	cp 0ffh		;5008   ; abajo del todo, cuando el escalon se pasa de cero
	jr nz,mueve_la_barra_de_fuerza_pinta		;500a
	inc hl			;500c
	ld (hl),007h		;500d   ; el escalon vuelve al 7
	dec hl			;500f
	dec (hl)			;5010
	ld a,(hl)			;5011
	inc a			;5012
	jr nz,mueve_la_barra_de_fuerza_pinta		;5013
	xor a			;5015
	ld (hl),a			;5016
	inc hl			;5017
	ld (hl),a			;5018
	dec hl			;5019
	ld (0e1b2h),a		;501a   ; y la barra vuelve a subir
mueve_la_barra_de_fuerza_pinta:		; Monta los tiles de la barra y los manda a la VRAM 0x3AE8
	ld de,0e1b4h		;501d   ; 0xE1B4 es donde se arma la fila de tiles de la barra antes de subirla
	ld a,(hl)			;5020   ; el escalon, que dice cuantos tiles llenos van
	ld b,(hl)			;5021
	ld c,(hl)			;5022
	or a			;5023
	jr z,pinta_la_barra_punta		;5024
pinta_la_barra_relleno:		; Rellena de 0xCF los tramos ya recorridos de la barra de fuerza
	ld a,0cfh		;5026   ; 0xCF es el tile lleno: la parte de la barra ya recorrida
	ld (de),a			;5028
	inc de			;5029
	djnz pinta_la_barra_relleno		;502a
	ld a,c			;502c
	cp 00ah		;502d   ; en la decima pasada la barra sale entera, sin punta
	jr z,pinta_la_barra_vuelca		;502f
pinta_la_barra_punta:		; Pone en la punta el tile 0xC8 mas lo que quede
	inc hl			;5031
	ld a,0c8h		;5032   ; la punta es el tile 0xC8 mas el escalon: nueve dibujos para el resto
	add a,(hl)			;5034
	ld (de),a			;5035
	inc c			;5036   ; la punta cuenta como un tile mas
pinta_la_barra_vuelca:		; Manda los tiles de 0xE1B4 a la VRAM 0x3AE8
	ld b,c			;5037
	ld de,07ae8h		;5038   ; VRAM 0x3AE8, la fila de abajo del todo
	ld hl,0e1b4h		;503b   ; los tiles armados en la RAM, listos para subir
	call vuelca_b_bytes_en_vram		;503e
	call mueve_la_mira		;5041   ; la mira se mueve en el mismo cuadro que la barra
	ld a,(0e002h)		;5044   ; en exhibicion el palo no se elige a mano
	or a			;5047
	jr z,elige_el_palo		;5048
	ld a,(0e1b0h)		;504a   ; la maquina suelta el golpe cuando la barra llega a la pasada 8
	cp 008h		;504d
	jr z,agrupa_el_palo		;504f
elige_el_palo:		; Con arriba y abajo cambia el palo (0xE121) dando la vuelta entre 0 y 11; en el green fuerza el 12, el putter
	call ficha_del_mando		;5051
	ld a,(hl)			;5054   ; la ficha del mando: los flancos del cursor y el disparo
	ld b,(hl)			;5055
	and 003h		;5056   ; solo los dos bits de arriba y abajo
	ld hl,0e123h		;5058   ; 0xE123 recuerda que el cursor sigue pulsado, para no repetir
	set 0,(hl)		;505b   ; se apunta que el cursor esta pulsado
	inc hl			;505d
	cp (hl)			;505e   ; comparado con lo que habia: si no ha cambiado, no es un flanco
	jr z,elige_el_palo_verde		;505f
	ld (hl),a			;5061
	dec hl			;5062
	res 0,(hl)		;5063   ; y se borra en cuanto cambia de posicion
elige_el_palo_verde:		; En el green no hay eleccion: putter
	ld hl,0e121h		;5065
	call esta_en_el_green		;5068   ; en el green no se elige palo
	jr nz,elige_el_palo_mando		;506b
	ld (hl),00ch		;506d   ; 0x0C es el putter, el treceavo y ultimo
	jr pinta_el_nombre_del_palo		;506f
elige_el_palo_mando:		; Lee los flancos del mando
	ld a,(0e123h)		;5071   ; el bit 0 dice que el cursor ya estaba pulsado antes
	rrca			;5074
	jr c,pinta_el_nombre_del_palo		;5075
	ld a,b			;5077
	rrca			;5078
	jr nc,elige_el_palo_baja		;5079
	inc (hl)			;507b

; ----------------------------------------------------------------------
; ----- El palo: la rueda de once y sus dos topes -----
; ----------------------------------------------------------------------
elige_el_palo_baja:		; La rama que baja de palo
	rrca			;507c   ; el bit 1 del mando es ABAJO: baja de palo
	jr nc,elige_el_palo_tope_alto		;507d
	dec (hl)			;507f   ; el numero de palo vive en 0xE121
elige_el_palo_tope_alto:		; Da la vuelta al pasar del 11
	ld a,(hl)			;5080
	cp 00ch		;5081   ; pasado el 0x0B se da la vuelta: el 12 es el putter y no entra en la rueda
	jr nz,elige_el_palo_tope_bajo		;5083
	ld (hl),000h		;5085   ; vuelve al 1W, el primero
elige_el_palo_tope_bajo:		; Y al bajar de cero
	inc a			;5087   ; al bajar de cero quedo en 0xFF
	jr nz,pinta_el_nombre_del_palo		;5088
	ld (hl),00bh		;508a   ; y se pega al 0x0B, el SW: son once los que se pueden elegir a mano
pinta_el_nombre_del_palo:		; Escribe en la VRAM 0x3852 los dos tiles de 0x57BA, y con el disparo pasa a calcular el golpe
	ld a,(hl)			;508c
	rlca			;508d   ; dos tiles por palo, asi que el indice va doblado
	ld hl,057bah		;508e   ; la tabla de nombres: 1W 3W 1I 3I 4I 5I 6I 7I 8I 9I PW SW PT
	call suma_a_a_hl		;5091
	ld de,07852h		;5094   ; VRAM 0x3852, el hueco del panel donde se lee el palo
	push bc			;5097
	ld b,002h		;5098   ; el nombre son dos tiles justos
	call vuelca_b_bytes_en_vram		;509a
	pop bc			;509d
	ld hl,0e123h		;509e
	bit 4,b		;50a1   ; bit 4 del mando: el disparo
	jp z,apaga_el_pestillo_del_palo		;50a3   ; sin disparo no hay golpe; de paso rearma el pestillo
	bit 1,(hl)		;50a6   ; el bit 1 de 0xE123 dice que el disparo viene pulsado desde que se confirmo el efecto: hay que soltarlo antes de poder parar la barra
	ret nz			;50a8

; ----------------------------------------------------------------------
; ----- La fisica del golpe -----
; ----------------------------------------------------------------------
agrupa_el_palo:		; Reparte los trece palos en seis grupos con los cortes 2, 4, 7, 10 y 12
	ld a,(0e121h)		;50a9   ; el palo elegido, de 0 a 12
	ld b,000h		;50ac   ; B sera el grupo de trayectoria, de 0 a 5
	cp 002h		;50ae   ; los cortes 2, 4, 7, 10 y 12 reparten los trece palos en seis grupos de vuelo
	jr c,calcula_el_golpe		;50b0
	inc b			;50b2
	cp 004h		;50b3
	jr c,calcula_el_golpe		;50b5
	inc b			;50b7
	cp 007h		;50b8
	jr c,calcula_el_golpe		;50ba
	inc b			;50bc
	cp 00ah		;50bd
	jr c,calcula_el_golpe		;50bf
	inc b			;50c1
	cp 00ch		;50c2
	jr c,calcula_el_golpe		;50c4
	inc b			;50c6   ; el grupo 5 es el del putter, el unico que pasa del corte 12
calcula_el_golpe:		; Copia a 0xE0A3 la ficha de vuelo del grupo (0x513A), coge el alcance del palo (0x5152), le resta lo que diga el punto de impacto (0x516C o 0x5177) y le suma el ajuste fino de 0xE1B1
	ld hl,0513ah		;50c7   ; las seis fichas de vuelo, cuatro bytes cada una
	ld a,b			;50ca
	rlca			;50cb   ; dos rlca: por cuatro, la anchura de la ficha
	rlca			;50cc
	call suma_a_a_hl		;50cd
	ld de,0e0a3h		;50d0   ; la ficha de vuelo en curso se copia a 0xE0A3
	ld bc,00004h		;50d3
	ldir		;50d6
	ld hl,05152h		;50d8   ; la tabla de alcances, una palabra por palo
	ld a,(0e121h)		;50db
	rlca			;50de   ; dos bytes por palo
	call suma_a_a_hl		;50df
	ld d,(hl)			;50e2   ; el alcance viene con el byte alto primero, al reves de como los guarda el Z80
	inc hl			;50e3
	ld e,(hl)			;50e4
	ex de,hl			;50e5
	push hl			;50e6
	ld hl,0516ch		;50e7   ; la resta que cobra el punto donde se ha parado la barra de fuerza
	ld a,(0e121h)		;50ea
	cp 00ch		;50ed   ; el palo 12 es el putter
	jr nz,calcula_el_golpe_resta		;50ef
	ld hl,05177h		;50f1   ; y tiene su propia tabla de restas, mucho mas suave
calcula_el_golpe_resta:		; La resta por el punto de impacto
	ld a,(0e1b0h)		;50f4   ; 0xE1B0 es el tramo entero de la barra, de 0 a 10
	call suma_a_a_hl		;50f7
	ld e,(hl)			;50fa
	pop hl			;50fb
	xor a			;50fc
	ld d,a			;50fd
	sbc hl,de		;50fe   ; alcance del palo menos el castigo del punto de impacto
	ld a,(0e1b1h)		;5100   ; 0xE1B1 son los octavos dentro del tramo en curso: el ajuste fino de la barra se suma tal cual a la distancia
	call suma_a_a_hl		;5103
	ld de,00030h		;5106   ; 48, lo que cuesta salir del rough malo
	ld a,(0e140h)		;5109   ; el terreno donde esta la bola: 1 bunker, 2 y 3 rough, 4 fuera de limites, 5 green
	dec a			;510c   ; terreno 1, el bunker
	jr nz,calcula_el_golpe_rough		;510d
calcula_el_golpe_mitad:		; En el bunker, la mitad de distancia
	srl h		;510f   ; en el bunker se va a la mitad de distancia
	rr l		;5111
	jr calcula_el_golpe_guarda		;5113
calcula_el_golpe_rough:		; En el rough, cuarenta y ocho menos si el palo no es de los dos primeros
	cp 002h		;5115   ; solo el terreno 3, el rough malo, cobra peaje
	jr nz,calcula_el_golpe_guarda		;5117
	ld a,(0e121h)		;5119   ; con las dos maderas desde ese rough tambien se va a la mitad
	cp 002h		;511c
	jr c,calcula_el_golpe_mitad		;511e
	or a			;5120
	sbc hl,de		;5121   ; con cualquier otro palo solo se pierden los 48
calcula_el_golpe_guarda:		; Deja la distancia en 0xE0A1, arma el sprite de la mira y pasa al estado 0x20
	ex de,hl			;5123
	ld l,d			;5124   ; le da la vuelta a los dos bytes: la distancia tambien se guarda con el byte alto primero
	ld h,e			;5125
	ld (0e0a1h),hl		;5126   ; 0xE0A1, la distancia que leera el vuelo de la bola
	ld hl,0e151h		;5129
	ld (hl),0cfh		;512c   ; 0xCF es la fila que esconde un sprite: la mira desaparece al soltar el golpe
	call pinta_el_sprite_de_la_mira		;512e
	ld a,020h		;5131   ; bit 5 de 0xE122: le pasa el turno al monigote de 0x57F0, que es quien da el golpe
	ld (0e122h),a		;5133
	ret			;5136
apaga_el_pestillo_del_palo:		; Baja el bit 1 de 0xE123 para que se pueda volver a pulsar
	res 1,(hl)		;5137   ; al soltar el disparo se rearma el pestillo, para que un toque no cuente por dos
	ret			;5139

; ----------------------------------------------------------------------
; DATOS vuelo_por_grupo_de_palo: Seis fichas de cuatro bytes que 0x50C7 copia
;   a 0xE0A3. La ficha se elige por el GRUPO del palo, no por el palo: 0x50A9
;   reparte los trece palos en seis grupos con los cortes 2, 4, 7, 10 y 12.
;   Cada ficha son dos palabras (0x00C3/0x00A4, 0x00B3/0x00B3, 0x00A4/0x00C3,
;   0x0080/0x00DD, 0x0057/0x00F0, 0x00B3/0x00B3) y las lee la trayectoria
;   desde 0xE0A3/0xE0A5
;   0x513a..0x5152  (24 bytes)
DATA_vuelo_por_grupo_de_palo:
	defb 000h,0c3h,000h,0a4h	; 513a
	defb 000h,0b3h,000h,0b3h	; 513e
	defb 000h,0a4h,000h,0c3h	; 5142
	defb 000h,080h,000h,0ddh	; 5146
	defb 000h,057h,000h,0f0h	; 514a
	defb 000h,0b3h,000h,0b3h	; 514e

; ----------------------------------------------------------------------
; DATOS alcance_de_cada_palo: Trece palabras de 16 bits CON EL BYTE ALTO
;   PRIMERO, una por palo, que 0x50D8 indexa con 0xE121: 0x0230 0x0210 0x0208
;   0x01F0 0x01D8 0x01C0 0x01BE 0x01C2 0x01AE 0x0190 0x01AE 0x0186 0x00E0. La
;   ultima -la mas corta con diferencia- es la del palo 12, el que 0x5065
;   fuerza cuando la bola esta en el green
;   0x5152..0x516c  (26 bytes)
DATA_alcance_de_cada_palo:
	defw 03002h,01002h	; 5152
	defw 00802h,0f001h	; 5156
	defw 0d801h,0c001h	; 515a
	defw 0be01h,0c201h	; 515e
	defw 0ae01h,09001h	; 5162
	defw 0ae01h,08601h	; 5166
	defw 0e000h	; 516a

; ----------------------------------------------------------------------
; DATOS resta_por_punto_de_impacto: Once bytes, 0xE0 a 0x10, que 0x50F4 indexa
;   con 0xE1B0 -donde se ha parado la barra de fuerza- y RESTA del alcance del
;   palo. Cuanto peor el golpe, mas grande la resta
;   0x516c..0x5177  (11 bytes)
DATA_resta_por_punto_de_impacto:
	defb 0d0h,0c0h,0b0h,0a0h,060h,050h,040h,030h,020h,010h,000h	; 516c  ....`P@0 ..

; ----------------------------------------------------------------------
; DATOS resta_por_impacto_del_putter: Los once valores equivalentes cuando el
;   palo es el 12: van de 0x90 a 0x00, o sea que el ultimo escalon no quita
;   nada. 0x50ED elige esta tabla y no la anterior
;   0x5177..0x5182  (11 bytes)
DATA_resta_por_impacto_del_putter:
	defb 090h,080h,070h,060h,050h,040h,030h,020h,010h,008h,000h	; 5177  ..p`P@0 ...

; ======================================================================
; CODIGO 0x5182..0x52bf  (317 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; ----- La mira: parpadeo, giro y topes -----
; ----------------------------------------------------------------------
mueve_la_mira:		; Gira el rumbo 0xE037 con el mando, lo hace dar la vuelta entre 0 y 0x40 con el signo de 0xE038, y luego lo topa segun 0xE142 para que no se pueda apuntar hacia atras
	ld hl,0e150h		;5182
	inc (hl)			;5185   ; 0xE150 cuenta cuadros para el parpadeo de la mira
	ld a,(hl)			;5186
	cp 005h		;5187   ; cada cinco cuadros se cambia el color
	jr nz,mueve_la_mira_lee		;5189
	ld (hl),000h		;518b
	ld b,00fh		;518d   ; 0x0F, blanco
	ld a,(0e000h)		;518f   ; el bit 0 del contador de cuadros de 0xE000 decide cual de los dos toca
	rrca			;5192
	jr nc,mueve_la_mira_parpadeo		;5193
	ld b,008h		;5195   ; 0x08, rojo
mueve_la_mira_parpadeo:		; Cada cinco cuadros alterna el color de la mira entre 0x0F y 0x08
	ld a,b			;5197
	ld (0e154h),a		;5198   ; 0xE154 es el byte de color del atributo del sprite de la mira
mueve_la_mira_lee:		; Coge del mando los bits de izquierda y derecha y suma o resta uno al rumbo
	call ficha_del_mando		;519b   ; la ficha de flancos del jugador que tiene el turno
	ld a,(hl)			;519e
	ld hl,0e037h		;519f   ; 0xE037 es el rumbo, de 0 a 0x40
	and 00ch		;51a2   ; bits 2 y 3 del mando: izquierda y derecha
	jr z,mueve_la_mira_da_la_vuelta		;51a4
	cp 00ch		;51a6   ; los dos a la vez no cuentan
	jr z,mueve_la_mira_da_la_vuelta		;51a8
	bit 2,a		;51aa   ; bit 2, izquierda: un paso menos de rumbo
	jr z,mueve_la_mira_derecha		;51ac
	dec (hl)			;51ae
	jr mueve_la_mira_da_la_vuelta		;51af
mueve_la_mira_derecha:		; La rama que suma
	inc (hl)			;51b1   ; derecha: un paso mas
mueve_la_mira_da_la_vuelta:		; El rumbo va de 0 a 0x40 con el signo en 0xE038; aqui se cruzan los topes
	inc hl			;51b2
	ld a,(hl)			;51b3   ; 0xE038 es el signo del rumbo: 0 a un lado, 0xFF al otro
	dec hl			;51b4
	or a			;51b5
	jr nz,mueve_la_mira_signo		;51b6
	ld a,(hl)			;51b8
	cp 041h		;51b9   ; pasado el 0x40 hay que cruzar al otro semicirculo
	jr nz,mueve_la_mira_cruza_por_abajo		;51bb
	ld (hl),001h		;51bd   ; queda en 1 con el signo puesto, que es el mismo sitio visto desde el otro lado
	inc hl			;51bf
	ld (hl),0ffh		;51c0
	jr topa_la_mira		;51c2
mueve_la_mira_cruza_por_abajo:		; Pasa de 0 a 0x3F cambiando de signo
	inc a			;51c4   ; si el rumbo bajo de cero quedo en 0xFF
	jp nz,topa_la_mira		;51c5
	ld (hl),03fh		;51c8   ; y cruza al 0x3F del otro signo
	inc hl			;51ca
	ld (hl),0ffh		;51cb
	jr topa_la_mira		;51cd
mueve_la_mira_signo:		; La misma vuelta con el signo puesto
	ld a,(hl)			;51cf
	or a			;51d0   ; la misma vuelta, pero saliendo del lado con signo
	jr nz,mueve_la_mira_cruza_por_arriba		;51d1
	ld (hl),040h		;51d3   ; del 0xFF con signo al 0x40 sin el
	inc hl			;51d5
	ld (hl),000h		;51d6
	jr topa_la_mira		;51d8
mueve_la_mira_cruza_por_arriba:		; Pasa de 0x40 a 0
	cp 040h		;51da   ; y del 0x40 con signo se pasa al 0
	jp nz,topa_la_mira		;51dc
	xor a			;51df   ; rumbo cero: apuntando justo al frente
	ld (hl),a			;51e0
	inc hl			;51e1
	ld (hl),a			;51e2
topa_la_mira:		; En el green no se topa; fuera, 0xE142 dice hacia donde mira el hoyo y recorta el rumbo a ese cuadrante
	call esta_en_el_green		;51e3   ; en el green la mira gira entera, sin topes
	jr z,topa_la_mira_sigue		;51e6
	ld hl,0e037h		;51e8
	ld a,(0e142h)		;51eb   ; 0xE142 dice con cual de las cuatro rejillas se ha montado la vista, o sea hacia donde mira el hoyo
	or a			;51ee
	jr nz,topa_la_mira_orientacion_1		;51ef
	inc hl			;51f1
	ld a,(hl)			;51f2
	or a			;51f3
	jr z,calcula_el_vector_de_la_mira		;51f4   ; sin signo no hay nada que topar
	xor a			;51f6
	ld (hl),a			;51f7   ; esta orientacion solo deja apuntar de 0 a 0x40: fuera el signo
	dec hl			;51f8
	ld b,a			;51f9
	ld a,(hl)			;51fa
	dec a			;51fb   ; el 1 con signo es justo el que acaba de cruzar el tope
	jr nz,topa_la_mira_guarda		;51fc
	ld b,040h		;51fe   ; se le devuelve al 0x40
topa_la_mira_guarda:		; Deja el rumbo recortado
	ld (hl),b			;5200   ; deja el rumbo ya recortado
topa_la_mira_sigue:		; Salta al calculo del vector
	jr calcula_el_vector_de_la_mira		;5201
topa_la_mira_orientacion_1:		; El tope cuando 0xE142 vale 1
	dec a			;5203
	jr nz,topa_la_mira_orientacion_2		;5204
	inc hl			;5206
	ld a,(hl)			;5207
	inc a			;5208
	jr z,calcula_el_vector_de_la_mira		;5209   ; con el signo ya puesto no hay nada que topar
	ld (hl),0ffh		;520b   ; la orientacion 1 solo deja apuntar por el lado del signo
	dec hl			;520d
	ld a,(hl)			;520e
	ld b,03fh		;520f
	or a			;5211
	jr z,topa_la_mira_orientacion_1_guarda		;5212   ; el 0 sin signo es el que acaba de cruzar: al 0x3F
	ld b,001h		;5214   ; los demas se pegan al 1, el otro extremo del arco
topa_la_mira_orientacion_1_guarda:		; Guarda el rumbo topado
	ld (hl),b			;5216
	jr calcula_el_vector_de_la_mira		;5217
topa_la_mira_orientacion_2:		; El tope cuando 0xE142 vale 2
	dec a			;5219
	jr nz,topa_la_mira_orientacion_3		;521a
	inc hl			;521c
	ld a,(hl)			;521d
	or a			;521e
	jr nz,topa_la_mira_orientacion_2_signo		;521f   ; la mitad con signo lleva su propio tope
	dec hl			;5221
	ld a,(hl)			;5222
	cp 01fh		;5223   ; con la orientacion 2 el 0x20 es el limite: al llegar al 0x1F se clava
	jr nz,calcula_el_vector_de_la_mira		;5225
	ld (hl),020h		;5227   ; y se queda ahi
	jr calcula_el_vector_de_la_mira		;5229
topa_la_mira_orientacion_2_signo:		; La otra mitad del mismo tope
	dec hl			;522b
	ld a,(hl)			;522c
	cp 021h		;522d   ; el mismo tope, pero acercandose por arriba
	jr nz,calcula_el_vector_de_la_mira		;522f
	ld (hl),020h		;5231   ; tambien se clava en el 0x20
	jr calcula_el_vector_de_la_mira		;5233
topa_la_mira_orientacion_3:		; El tope de las demas orientaciones
	ld a,(hl)			;5235
	cp 020h		;5236   ; con la orientacion 3 el 0x20 es justo lo unico que NO se puede apuntar
	jr nz,calcula_el_vector_de_la_mira		;5238
	inc hl			;523a
	ld a,(hl)			;523b
	ld b,021h		;523c   ; con signo se le empuja al 0x21
	or a			;523e
	jr nz,topa_la_mira_orientacion_3_guarda		;523f
	ld b,01fh		;5241   ; y sin signo, al 0x1F
topa_la_mira_orientacion_3_guarda:		; Guarda
	dec hl			;5243
	ld (hl),b			;5244   ; guarda el rumbo ya empujado fuera del 0x20

; ----------------------------------------------------------------------
; ----- El vector de la mira: una curva leida en dos sitios a la vez -----
; ----------------------------------------------------------------------
calcula_el_vector_de_la_mira:		; Saca de 0x52BF y 0x52E0 -la misma curva leida con 0x21 de separacion- las dos componentes del rumbo reducido a 0..31
	ld de,052bfh		;5245   ; la curva de 66 bytes, leida por el principio
	ld hl,052e0h		;5248   ; y la MISMA curva 0x21 mas alla: de ahi sale el otro componente
	ld a,(0e037h)		;524b
	cp 020h		;524e   ; el rumbo se pliega a 0..0x20; del cuadrante ya se encarga el signo
	jr c,calcula_el_vector_indexa		;5250
	sub 020h		;5252
calcula_el_vector_indexa:		; Las dos lecturas
	push af			;5254
	call suma_a_a_hl		;5255
	pop af			;5258
	ld c,(hl)			;5259   ; C, el componente que sale de 0x52E0
	ex de,hl			;525a
	call suma_a_a_hl		;525b
	ld b,(hl)			;525e   ; B, el que sale de 0x52BF; los dos van de 0 a -16, que es el radio del circulo que describe la mira
	ld hl,0e038h		;525f   ; el signo del rumbo dice en que cuarto de vuelta se esta
	ld a,(hl)			;5262
	dec hl			;5263
	or a			;5264
	jr nz,calcula_el_vector_cuadrante_2		;5265
	ld a,(hl)			;5267
	cp 020h		;5268   ; la primera mitad del cuadrante se queda tal cual
	jr c,coloca_el_sprite_de_la_mira		;526a
	ld a,b			;526c
	ld b,c			;526d   ; en la segunda se intercambian los dos componentes
	neg		;526e   ; y se le da la vuelta al que pasa a mandar
	ld c,a			;5270
	jr coloca_el_sprite_de_la_mira		;5271
calcula_el_vector_cuadrante_2:		; Cambia los signos segun en que cuarto de vuelta se este
	ld a,(hl)			;5273
	cp 020h		;5274   ; el rumbo con signo por debajo del 0x20
	jr nc,calcula_el_vector_cuadrante_3		;5276
	ld a,b			;5278
	neg		;5279   ; aqui hay que negar los dos componentes
	ld b,a			;527b
	ld a,c			;527c
	neg		;527d   ; el cuadrante opuesto al primero
	ld c,a			;527f
	jr coloca_el_sprite_de_la_mira		;5280
calcula_el_vector_cuadrante_3:		; El tercer cuarto
	ld a,c			;5282   ; y en el cuarto que queda se intercambian y se niega uno solo
	ld c,b			;5283
	neg		;5284
	ld b,a			;5286
coloca_el_sprite_de_la_mira:		; Suma el vector a la posicion de la bola -o a la del marcador si esta en el green- y arma el atributo del sprite 0xAC
	ld de,0e151h		;5287   ; 0xE151 es el atributo del sprite 0: el circulito de la mira
	ld a,(0e140h)		;528a   ; terreno 5, el green
	sub 005h		;528d
	ld l,001h		;528f   ; en el green el circulo sale de la bola; fuera, del marcador del plano
	jr z,coloca_el_sprite_de_la_mira_origen		;5291
	dec l			;5293
coloca_el_sprite_de_la_mira_origen:		; Toma como origen la bola o el marcador segun 0xE140
	ld a,(0e0bch)		;5294   ; 0xE0BC es la fila del marcador de la bola sobre el plano de la derecha
	sub 003h		;5297   ; tres pixeles para centrar el circulo, que es de 8x8, con la marca
	bit 0,l		;5299
	jr z,coloca_el_sprite_de_la_mira_y		;529b
	ld a,(0e0b0h)		;529d   ; en el green, el origen es el sprite de la bola de la vista
coloca_el_sprite_de_la_mira_y:		; La coordenada y: va al primer byte de 0xE151, que 0x52B5 vuelca al atributo del sprite 0, y un atributo lleva la FILA delante
	add a,b			;52a0   ; en el atributo del sprite la fila va primero: aqui se le suma el componente vertical
	ld (de),a			;52a1
	inc de			;52a2
	ld a,(0e0bdh)		;52a3   ; y esta es la columna del marcador
	sub 003h		;52a6
	bit 0,l		;52a8
	jr z,coloca_el_sprite_de_la_mira_x		;52aa
	ld a,(0e0b1h)		;52ac
coloca_el_sprite_de_la_mira_x:		; La coordenada x, al segundo byte
	add a,c			;52af   ; la columna del circulo
	ld (de),a			;52b0
	inc de			;52b1
	ld a,0ach		;52b2   ; 0xAC, el dibujo del circulito de la mira
	ld (de),a			;52b4
pinta_el_sprite_de_la_mira:		; Vuelca los cuatro bytes de 0xE151 al atributo del sprite 0 (VRAM 0x3B00)
	ld hl,0e151h		;52b5   ; los cuatro bytes del atributo: fila, columna, dibujo y color
	ld de,07b00h		;52b8   ; VRAM 0x3B00: el sprite 0, el primero de los treinta y dos
	call vuelca_cuatro_bytes		;52bb
	ret			;52be

; ----------------------------------------------------------------------
; DATOS curva_de_la_direccion: Una sola curva de 66 bytes que va de 0x00 a
;   0xF0 y vuelve -o sea de 0 a -16 y de vuelta a 0-, leida en DOS SITIOS A LA
;   VEZ, separados 0x21: 0x5245 saca de 0x52BF el primer termino y de 0x52E0
;   el segundo, indexando los dos con 0xE037 reducido a 0..31. Es el seno y el
;   coseno del rumbo
;   0x52bf..0x5301  (66 bytes)
DATA_curva_de_la_direccion:
	defb 000h,0ffh,0feh,0fdh,0fdh,0fch,0fbh,0fah,0fah,0f9h,0f8h,0f7h,0f7h,0f6h,0f6h,0f5h	; 52bf  ................
	defb 0f5h,0f4h,0f4h,0f3h,0f3h,0f2h,0f2h,0f2h,0f2h,0f1h,0f1h,0f1h,0f1h,0f0h,0f0h,0f0h	; 52cf  ................
	defb 0f0h,0f0h,0f0h,0f0h,0f0h,0f1h,0f1h,0f1h,0f1h,0f2h,0f2h,0f2h,0f2h,0f3h,0f3h,0f4h	; 52df  ................
	defb 0f4h,0f5h,0f5h,0f6h,0f6h,0f7h,0f7h,0f8h,0f9h,0fah,0fah,0fbh,0fch,0fdh,0fdh,0feh	; 52ef  ................
	defb 0ffh,000h	; 52ff

; ======================================================================
; CODIGO 0x5301..0x5471  (368 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; ----- Apuntar y elegir el efecto -----
; ----------------------------------------------------------------------
elige_el_golpe:		; En el green solo deja golpear; fuera, mueve la mira y deja elegir con arriba y abajo entre STRAIGHT, SLICE y HOOK (0xE120)
	call esta_en_el_green		;5301   ; en el green no se apunta ni se elige efecto
	jr nz,elige_el_golpe_mira		;5304
	xor a			;5306
	ld (0e120h),a		;5307   ; se fuerza el golpe recto
	jr elige_el_golpe_al_verde		;530a
elige_el_golpe_mira:		; Mueve la mira y, si no es exhibicion, atiende al mando
	call mueve_la_mira		;530c
	ld a,(0e002h)		;530f   ; 0xE002 marca la exhibicion: la maquina juega sola y no se toca el mando
	or a			;5312
	jr nz,elige_el_golpe_confirma		;5313
	call ficha_del_mando		;5315   ; los flancos del jugador que tiene el turno
	ld b,(hl)			;5318
	ld a,(hl)			;5319
	and 003h		;531a   ; bits 0 y 1: arriba y abajo
	ld hl,0e123h		;531c
	set 0,(hl)		;531f   ; el pestillo que impide que un empujon del mando cuente varios cuadros seguidos
	inc hl			;5321
	cp (hl)			;5322   ; 0xE124 guarda como estaba el mando en el cuadro anterior
	jr z,elige_el_golpe_cambia		;5323
	ld (hl),a			;5325
	dec hl			;5326
	res 0,(hl)		;5327   ; si ha cambiado, se suelta el pestillo y el empujon vale
elige_el_golpe_cambia:		; Sube o baja 0xE120 dando la vuelta entre 0 y 2
	ld a,(0e123h)		;5329
	rrca			;532c   ; con el pestillo puesto no se cambia de efecto
	ld hl,0e120h		;532d   ; 0xE120: 0 recto, 1 slice, 2 hook
	jr c,elige_el_golpe_pinta		;5330
	ld a,b			;5332
	rrca			;5333
	jr nc,elige_el_golpe_da_la_vuelta		;5334
	inc (hl)			;5336   ; arriba sube de efecto
elige_el_golpe_da_la_vuelta:		; El tope de arriba
	rrca			;5337
	jr nc,elige_el_golpe_tope		;5338
	dec (hl)			;533a   ; abajo lo baja
elige_el_golpe_tope:		; El de abajo
	ld a,(hl)			;533b
	cp 003h		;533c   ; son tres, del 0 al 2
	jr nz,elige_el_golpe_tope_bajo		;533e
	ld (hl),000h		;5340
elige_el_golpe_tope_bajo:		; Deja el 2 al bajar de cero
	inc a			;5342
	jr nz,elige_el_golpe_pinta		;5343
	ld (hl),002h		;5345   ; y por abajo se da la vuelta al hook
elige_el_golpe_pinta:		; Escribe en la VRAM 0x384C los ocho tiles del rotulo elegido
	ld a,(hl)			;5347
	rlca			;5348   ; tres rlca: ocho tiles por rotulo
	rlca			;5349
	rlca			;534a
	ld hl,057d4h		;534b   ; los tres rotulos: STRAIGHT, SLICE y HOOK
	call suma_a_a_hl		;534e
	ld de,0784ch		;5351   ; VRAM 0x384C, el renglon del efecto en el panel
	push bc			;5354
	ld b,008h		;5355
	call vuelca_b_bytes_en_vram		;5357
	pop bc			;535a
	bit 4,b		;535b   ; bit 4: el disparo confirma el efecto
	ret z			;535d
elige_el_golpe_confirma:		; Con el disparo borra el rotulo, marca 0xE123 y pasa al estado 2
	ld de,0784ch		;535e   ; borra el rotulo escribiendo ocho veces el tile 0xFB
	ld bc,008fbh		;5361
	call rellena_vram_con_c		;5364
	ld hl,0e123h		;5367
	set 1,(hl)		;536a   ; marca el disparo como ya pulsado, para que el mismo toque no pare tambien la barra
elige_el_golpe_al_verde:		; En el green se salta todo y pasa directo al estado 2
	ld a,002h		;536c   ; bit 1 de 0xE122: arranca la barra de fuerza
	ld (0e122h),a		;536e
	ret			;5371

; ----------------------------------------------------------------------
; ----- El rumbo de partida segun como se mire el hoyo -----
; ----------------------------------------------------------------------
pon_el_rumbo_inicial:		; Deja el rumbo en 0x20 y le pone el signo que pida la orientacion del hoyo (0xE142)
	ld hl,0e037h		;5372
	ld (hl),020h		;5375   ; 0x20, el centro del arco: apuntando de frente
	inc hl			;5377
	ld (hl),000h		;5378   ; y sin signo
	dec hl			;537a
	ld a,(0e142h)		;537b   ; la orientacion con la que se ha montado la vista
	dec a			;537e
	jr nz,pon_el_rumbo_inicial_lado		;537f
	inc hl			;5381
	ld (hl),0ffh		;5382   ; con la orientacion 1 el frente cae al otro lado del cero
	dec hl			;5384
pon_el_rumbo_inicial_lado:		; La orientacion 2
	dec a			;5385
	jr nz,pon_el_rumbo_inicial_frente		;5386
	ld (hl),040h		;5388   ; con la 2, en el 0x40
pon_el_rumbo_inicial_frente:		; Las demas
	dec a			;538a
	ret nz			;538b
	ld (hl),a			;538c   ; y con la 3, en el 0
	ret			;538d

; ----------------------------------------------------------------------
; ----- El hoyo: el mismo guion leido como plano y como rejilla -----
; ----------------------------------------------------------------------
monta_el_hoyo:		; Pinta el guion del hoyo por 0x79BC y luego desgrana su rejilla por 0x79CE en el buffer de 0xE200: doce columnas por dieciocho filas, con el relleno 0x31 alrededor
	ld a,(0e100h)		;538e   ; el hoyo en curso, de 1 a 9
	ld hl,079bah		;5391   ; la tabla de guiones es 1-based y su entrada 0 cae dos bytes antes, en 0x79BA
	rlca			;5394   ; dos bytes por puntero
	push af			;5395
	call suma_a_a_hl		;5396
	ld e,(hl)			;5399
	inc hl			;539a
	ld d,(hl)			;539b
	ex de,hl			;539c
	call pinta_guion		;539d   ; pinta el plano del hoyo en la VRAM 0x38F6: dieciseis filas de nueve tiles
	ei			;53a0
	pop af			;53a1
	ld hl,079cch		;53a2   ; la otra tabla, la que apunta al mismo hoyo pero leido como datos
	call suma_a_a_hl		;53a5
	ld e,(hl)			;53a8
	inc hl			;53a9
	ld d,(hl)			;53aa
	ex de,hl			;53ab
	ld de,0e200h		;53ac   ; la rejilla del hoyo: doce columnas por dieciocho filas
	ld bc,01a10h		;53af   ; B son los 26 rellenos de entrada -dos filas enteras y dos casillas mas-, C las dieciseis filas del hoyo
monta_el_hoyo_relleno:		; Escribe los tiles de relleno que van antes de cada fila
	ld a,031h		;53b2   ; 0x31 es la casilla de relleno que rodea al hoyo por los cuatro lados
	ld (de),a			;53b4
	inc de			;53b5
	djnz monta_el_hoyo_relleno		;53b6
	inc hl			;53b8   ; se salta la racha de 23 ceros con la que empieza cada fila del guion; en la primera vuelta lo que se salta es la cabecera de destino
	inc hl			;53b9
	ld a,(hl)			;53ba   ; el codigo de la orden del guion: 0x89 es literal de nueve, y con el nibble alto a cero es una racha
	inc hl			;53bb
	and 0f0h		;53bc
	jr nz,monta_el_hoyo_fila		;53be
	dec hl			;53c0
	ld b,(hl)			;53c1   ; la racha: el nibble bajo dice cuantas casillas iguales lleva la fila
	inc hl			;53c2
	ld a,(hl)			;53c3
	inc hl			;53c4
monta_el_hoyo_racha:		; La forma corta: un codigo repetido
	ld (de),a			;53c5   ; escupe la misma casilla toda la fila
	inc de			;53c6
	djnz monta_el_hoyo_racha		;53c7
	jr monta_el_hoyo_siguiente		;53c9
monta_el_hoyo_fila:		; La forma larga: los nueve codigos de la fila, tal cual
	push bc			;53cb
	ld bc,00009h		;53cc   ; nueve casillas, la anchura del hoyo
	ldir		;53cf
	pop bc			;53d1
monta_el_hoyo_siguiente:		; Prepara la fila siguiente
	ld b,003h		;53d2   ; tres rellenos entre fila y fila: la columna doce y las dos primeras de la siguiente
	dec c			;53d4
	jr nz,monta_el_hoyo_relleno		;53d5
	ld a,(0e100h)		;53d7   ; y ahora la bandera
	ld hl,05bdch		;53da   ; otra tabla 1-based con la entrada 0 encima de codigo: los datos empiezan en 0x5BDE
	rlca			;53dd
	call suma_a_a_hl		;53de
	ld de,0e13ah		;53e1
	ld a,(hl)			;53e4
	add a,0a0h		;53e5   ; 0xA0 corre la columna hasta el plano de la derecha
	ld (de),a			;53e7
	dec de			;53e8
	inc hl			;53e9
	ld a,(hl)			;53ea
	add a,020h		;53eb   ; 0x20 baja la fila hasta donde empieza el plano
	ld (de),a			;53ed
	ex de,hl			;53ee
	ld de,07b40h		;53ef   ; VRAM 0x3B40, el atributo del sprite 16: la banderita del plano
	ld b,002h		;53f2
	call vuelca_b_bytes_en_vram_di		;53f4
	ei			;53f7
	ld hl,0e284h		;53f8   ; 0xE284 es la fila once de la rejilla: el giro se lee de abajo arriba
	ld de,0e300h		;53fb
	ld bc,00c0ch		;53fe   ; doce por doce

; ----------------------------------------------------------------------
; ----- Las tres copias giradas de la rejilla -----
; ----------------------------------------------------------------------
gira_la_rejilla:		; Copia la rejilla de 0xE200 a 0xE300 leyendola por columnas: la gira noventa grados, y de paso traduce cada codigo con 0x5452
	push hl			;5401
gira_la_rejilla_celda:		; Una casilla
	call traduce_la_casilla_girada		;5402
	ld (de),a			;5405
	push de			;5406
	or a			;5407
	ld de,0000ch		;5408   ; sube una fila entera; leyendo hacia arriba y avanzando de columna en columna sale el giro de noventa grados
	sbc hl,de		;540b
	pop de			;540d
	inc de			;540e   ; las casillas van saliendo en el orden en que se escriben en 0xE300
	djnz gira_la_rejilla_celda		;540f
	pop hl			;5411
	inc hl			;5412   ; y la columna siguiente llena la fila siguiente del destino
	ld b,00ch		;5413
	dec c			;5415
	jr nz,gira_la_rejilla		;5416
	ld hl,0e125h		;5418
	inc (hl)			;541b   ; 0xE125 dice cual de las tres tablas de giro se aplica a cada codigo
	ld hl,0e20bh		;541c   ; el segundo giro arranca en la columna once
	ld de,0e3a0h		;541f   ; y va a parar a 0xE3A0
	ld bc,00c0ch		;5422
gira_la_rejilla_2:		; El segundo giro, de 0xE20B a 0xE3A0
	push hl			;5425
gira_la_rejilla_2_celda:		; Una casilla del segundo giro
	call traduce_la_casilla_girada		;5426
	ld (de),a			;5429
	ld a,00ch		;542a   ; aqui se BAJA una fila: es el giro contrario al de antes
	call suma_a_a_hl		;542c
	inc de			;542f
	djnz gira_la_rejilla_2_celda		;5430
	pop hl			;5432
	dec hl			;5433   ; y las columnas se recorren de derecha a izquierda
	ld b,00ch		;5434
	dec c			;5436
	jr nz,gira_la_rejilla_2		;5437
	ld hl,0e125h		;5439
	inc (hl)			;543c
	ld hl,0e26bh		;543d   ; el tercero: desde la fila ocho y hacia atras
	ld de,0e440h		;5440
	ld b,06ch		;5443   ; 108 casillas, o sea nueve filas de doce
da_la_vuelta_a_la_rejilla:		; El tercero: de 0xE26B a 0xE440 leyendo hacia atras, o sea media vuelta
	call traduce_la_casilla_girada		;5445
	ld (de),a			;5448
	dec hl			;5449   ; leyendo la rejilla al reves sale la media vuelta
	inc de			;544a
	djnz da_la_vuelta_a_la_rejilla		;544b
	xor a			;544d
	ld (0e125h),a		;544e   ; se acabaron los giros
	ret			;5451
traduce_la_casilla_girada:		; Los codigos de 0x31 para arriba se quedan como estan; los demas se cambian por su version girada, sacada de 0x5471, 0x54A1 o 0x54D1 segun 0xE125
	ld a,(hl)			;5452
	cp 031h		;5453   ; de 0x31 para arriba -relleno, borde y tee- el dibujo es igual se mire como se mire
	ret nc			;5455
	push hl			;5456
	push af			;5457
	ld hl,054a0h		;5458   ; la tabla del primer giro, ya corrida un byte porque los codigos empiezan en 1
	ld a,(0e125h)		;545b   ; el giro que se esta haciendo
	or a			;545e
	jr z,traduce_la_casilla_indexa		;545f
	ld hl,054d0h		;5461   ; la del segundo
	dec a			;5464
	jr z,traduce_la_casilla_indexa		;5465
	ld hl,traduce_la_casilla_fin		;5467   ; y la del tercero empieza en el ret de aqui abajo, para no gastar un byte
traduce_la_casilla_indexa:		; La lectura de la tabla
	pop af			;546a
	call suma_a_a_hl		;546b   ; los codigos de casilla van de 1 a 0x30
	ld a,(hl)			;546e
	pop hl			;546f
traduce_la_casilla_fin:		; El `ret` de la rutina, que ademas hace de base de la primera tabla de giro
	ret			;5470   ; este ret es tambien la entrada 0 de la tabla de 0x5471

; ----------------------------------------------------------------------
; DATOS giro_de_casillas_1: Cuarenta y ocho bytes, uno por codigo de casilla
;   del 1 al 0x30, con el codigo equivalente ya girado. 0x5467 la elige cuando
;   0xE125 vale 2 o mas, y APUNTA A 0x5470, que es el `ret` de la propia
;   rutina: el indice empieza en 1
;   0x5471..0x54a1  (48 bytes)
DATA_giro_de_casillas_1:
	defb 004h,003h,002h,001h	; 5471
	defb 008h,007h,006h,005h	; 5475
	defb 00ch,00bh,00ah,009h	; 5479
	defb 010h,00fh,00eh,00dh	; 547d
	defb 012h,011h,014h,013h	; 5481
	defb 018h,017h,016h,015h	; 5485
	defb 01ch,01bh,01ah,019h	; 5489
	defb 020h,01fh,01eh,01dh	; 548d
	defb 024h,023h,022h,021h	; 5491
	defb 026h,025h,028h,027h	; 5495
	defb 02ch,02bh,02ah,029h	; 5499
	defb 030h,02fh,02eh,02dh	; 549d

; ----------------------------------------------------------------------
; DATOS giro_de_casillas_2: La misma tabla para el giro que 0x5458 usa cuando
;   0xE125 vale 0
;   0x54a1..0x54d1  (48 bytes)
DATA_giro_de_casillas_2:
	defb 009h,00ah,00bh,00ch	; 54a1
	defb 00dh,00eh,00fh,010h	; 54a5
	defb 004h,003h,002h,001h	; 54a9
	defb 008h,007h,006h,005h	; 54ad
	defb 013h,014h,012h,011h	; 54b1
	defb 01dh,01eh,01fh,020h	; 54b5
	defb 021h,022h,023h,024h	; 54b9
	defb 018h,017h,016h,015h	; 54bd
	defb 01ch,01bh,01ah,019h	; 54c1
	defb 027h,028h,026h,025h	; 54c5
	defb 02ah,02ch,029h,02bh	; 54c9
	defb 02eh,030h,02dh,02fh	; 54cd

; ----------------------------------------------------------------------
; DATOS giro_de_casillas_3: La misma tabla para el giro que 0x5461 usa cuando
;   0xE125 vale 1. Las tres barajan los codigos dentro de cada grupo de
;   cuatro, que es lo que hace girar el dibujo de la casilla
;   0x54d1..0x5501  (48 bytes)
DATA_giro_de_casillas_3:
	defb 00ch,00bh,00ah,009h	; 54d1
	defb 010h,00fh,00eh,00dh	; 54d5
	defb 001h,002h,003h,004h	; 54d9
	defb 005h,006h,007h,008h	; 54dd
	defb 014h,013h,011h,012h	; 54e1
	defb 020h,01fh,01eh,01dh	; 54e5
	defb 024h,023h,022h,021h	; 54e9
	defb 015h,016h,017h,018h	; 54ed
	defb 019h,01ah,01bh,01ch	; 54f1
	defb 028h,027h,025h,026h	; 54f5
	defb 02bh,029h,02ch,02ah	; 54f9
	defb 02fh,02dh,030h,02eh	; 54fd

; ======================================================================
; CODIGO 0x5501..0x55f6  (245 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; ----- La vista: llenar el lienzo de 20x16 banda a banda -----
; ----------------------------------------------------------------------
monta_la_vista:		; Borra el lienzo de 0xE4C0 -veinte columnas por dieciseis filas- y lo llena banda a banda con los bloques de casilla; en el green se va por otro camino
	ld a,(0e129h)		;5501   ; 0xE129 avisa de que el lienzo ya esta montado: el trabajo se reparte en dos cuadros
	or a			;5504
	jp nz,monta_la_vista_pinta		;5505
	ld hl,0e4c0h		;5508   ; el lienzo de la vista: veinte columnas por dieciseis filas
	ld bc,00140h		;550b
	call borra_memoria		;550e
	xor a			;5511
	ld (0e128h),a		;5512   ; 0xE128 llevara la banda, de 1 a 5
	call esta_en_el_green		;5515   ; el green se monta por otro camino
	jr nz,monta_la_vista_prepara		;5518
	call esta_la_bola_cerca_del_tee		;551a   ; si la bola y la marca guardada se pisan hay que sacar las dos
	jr nc,monta_la_vista_al_verde		;551d
	push de			;551f
	ld de,07b30h		;5520   ; el atributo del sprite 12, en la VRAM 0x3B30
	call vuelca_cuatro_bytes		;5523   ; la bola (0xE0B0) al sprite 12
	pop hl			;5526
	call vuelca_cuatro_bytes		;5527   ; y el marcador del tee (0xE1C0) AL MISMO sprite: vuelca_cuatro_bytes no toca DE, asi que este segundo volcado pisa al primero. Ver PREGUNTAS-ABIERTAS
monta_la_vista_al_verde:		; Salta al montaje del green
	jp termina_la_vista_estado		;552a   ; en el green no hay lienzo que montar
monta_la_vista_prepara:		; Limpia los avisos y apunta a la rejilla que toque (0xE132)
	xor a			;552d
	ld (0e146h),a		;552e   ; 0xE145 se encendera si en la vista entra alguna casilla de green
	ld (0e145h),a		;5531
	ld de,0e4c0h		;5534
	ld hl,(0e132h)		;5537   ; el puntero a la rejilla que toca, ya corrido cincuenta bytes por delante de la bola
	ex de,hl			;553a
monta_la_vista_banda:		; Cada banda son cinco columnas de bloques; a la sexta se acaba. La banda va en 0xE128, de 1 a 5
	ld c,005h		;553b   ; cinco columnas de bloques por banda
	ld a,(0e128h)		;553d
	inc a			;5540
	cp 006h		;5541   ; pasada la quinta banda el lienzo esta lleno
	jp z,monta_la_vista_pinta		;5543
	ld (0e128h),a		;5546
monta_la_vista_columna:		; Una columna de la banda: bloques de dos filas en las bandas 1 y 2, de cuatro en las demas
	push de			;5549
	push hl			;554a
	ld a,(0e128h)		;554b
	ld b,002h		;554e
	cp 003h		;5550   ; las bandas 1 y 2, las del fondo, llevan bloques de dos filas; las tres de delante, de cuatro
	jr c,monta_la_vista_elige_bloque		;5552
	ld b,004h		;5554
monta_la_vista_elige_bloque:		; Busca el bloque del codigo de la casilla en las tablas de 0x79E0 o 0x7DF4 segun el codigo
	dec a			;5556
	rlca			;5557   ; dos bytes por banda
	push af			;5558
	ex af,af'			;5559   ; el push seguido del intercambio con el juego alterno copia A en A-prima: el mismo indice hara falta para la otra familia de tablas
	pop af			;555a
	ld hl,079e0h		;555b   ; la tabla de bloques de las casillas 1 a 0x28, con una entrada por banda
	call suma_a_a_hl		;555e
	ld a,(de)			;5561
	cp 0c4h		;5562   ; 0xC4 es el borde del campo, y lleva bloque fijo
	jr nz,monta_la_vista_codigo_alto		;5564
	ld hl,07deah		;5566
	jr monta_la_vista_dibuja		;5569
monta_la_vista_codigo_alto:		; Los codigos 0x29 y 0x2A marcan 0xE145; a partir de 0x2B se va a la segunda familia de tablas
	cp 029h		;556b   ; por debajo del 0x29 manda la primera familia
	jr c,monta_la_vista_puntero		;556d
	cp 02bh		;556f
	jr nc,monta_la_vista_segunda_tabla		;5571
	ld hl,0e145h		;5573   ; 0x29 y 0x2A son el green: hay que avisar de que se ve
	ld (hl),001h		;5576
monta_la_vista_segunda_tabla:		; La familia de las casillas 0x29 a 0x34
	ld hl,07df4h		;5578   ; la familia de las casillas 0x29 a 0x34
	ex af,af'			;557b
	call suma_a_a_hl		;557c
	ld a,(de)			;557f
	sub 028h		;5580   ; en esta familia los codigos se cuentan desde el 0x29
	cp 0c2h		;5582   ; 0xEA es el tee, y entra como la casilla once de la familia
	jr nz,monta_la_vista_puntero		;5584
	sub 0b7h		;5586
monta_la_vista_puntero:		; Saca el puntero del bloque de las dos tablas encadenadas
	ld e,(hl)			;5588   ; primero el puntero de la banda
	inc hl			;5589
	ld d,(hl)			;558a
	ex de,hl			;558b
	dec a			;558c
	rlca			;558d   ; y dentro, dos bytes por codigo de casilla
	call suma_a_a_hl		;558e
	ld e,(hl)			;5591   ; al final queda la direccion del bloque de tiles
	inc hl			;5592
	ld d,(hl)			;5593
	ex de,hl			;5594
monta_la_vista_dibuja:		; Copia el bloque al lienzo
	pop de			;5595   ; recupera el sitio del lienzo donde va el bloque
	push de			;5596
monta_la_vista_fila:		; Una fila de cuatro tiles del bloque
	push bc			;5597
	ld a,(hl)			;5598
	or a			;5599   ; un cero de entrada quiere decir que las dos filas siguientes son todas del mismo tile
	jr z,monta_la_vista_racha		;559a
	ld bc,00004h		;559c   ; cuatro tiles de ancho tiene el bloque
	ldir		;559f
	pop bc			;55a1
	call baja_una_fila		;55a2   ; y con los cuatro del ldir suman veinte, la anchura del lienzo
	djnz monta_la_vista_fila		;55a5
monta_la_vista_columna_siguiente:		; Avanza cuatro columnas del lienzo
	pop hl			;55a7
	ld a,004h		;55a8   ; el bloque siguiente va cuatro columnas a la derecha
	call suma_a_a_hl		;55aa
	pop de			;55ad
	inc de			;55ae   ; y la casilla siguiente de la rejilla
	dec c			;55af
	jr nz,monta_la_vista_columna		;55b0
	ld a,(0e128h)		;55b2
	dec a			;55b5
	ld hl,057ech		;55b6   ; la tabla dice en que fila del lienzo empieza cada banda
	call suma_a_a_hl		;55b9
	ld a,(hl)			;55bc
	ld hl,0e4c0h		;55bd
	call suma_a_a_hl		;55c0
	ld a,007h		;55c3
	call suma_a_a_de		;55c5   ; siete casillas mas: cinco leidas y siete de salto son las doce de la fila de la rejilla
	jp monta_la_vista_banda		;55c8
monta_la_vista_racha:		; El atajo del bloque: un solo tile repetido cuatro veces, dos filas seguidas
	inc hl			;55cb
	ld bc,00402h		;55cc   ; B cuatro tiles, C dos filas
	ld a,(hl)			;55cf
monta_la_vista_racha_fila:		; El bucle que lo escupe
	ld (de),a			;55d0
	inc de			;55d1
	djnz monta_la_vista_racha_fila		;55d2
	push af			;55d4
	call baja_una_fila		;55d5   ; baja al renglon de abajo del lienzo
	pop af			;55d8
	ld b,004h		;55d9
	dec c			;55db
	jr nz,monta_la_vista_racha_fila		;55dc
	inc hl			;55de
	pop bc			;55df
	dec b			;55e0   ; el atajo gasta dos filas del bloque de una sola vez
	djnz monta_la_vista_fila		;55e1
	jr monta_la_vista_columna_siguiente		;55e3
monta_la_vista_pinta:		; Con el lienzo lleno, lo vuelca a la pantalla
	call pon_el_rumbo_inicial		;55e5   ; la vista recien montada se mira siempre de frente
	ld a,(0e129h)		;55e8
	or a			;55eb
	jr nz,monta_la_vista_borra_arriba		;55ec
	inc a			;55ee
	ld (0e129h),a		;55ef   ; primer cuadro: el lienzo queda montado y se pintara en el siguiente
	ret			;55f2
monta_la_vista_borra_arriba:		; Borra las tres primeras filas con el guion de 0x7FEF
	call lee_parametro		;55f3   ; el guion de 0x7FEF borra las tres primeras filas de la pantalla

; ----------------------------------------------------------------------
; DATOS parametro_55f6: Parametro en linea del call de 0x55F3: apunta a 0x7FEF
;   0x55f6..0x55f8  (2 bytes)
DATA_parametro_55f6:
	defw 07fefh	; 55f6  -> DATA_guion_borra_tres_filas

; ======================================================================
; CODIGO 0x55f8..0x5714  (284 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; ----- El remate de arriba y el volcado del lienzo -----
; ----------------------------------------------------------------------
pinta_el_recuadro:		; Saca de 0x7F8A el dibujo del recuadro que le toca al hoyo y lo pinta en dos bloques de diez por tres, en las VRAM 0x3881 y 0x388B
	ld hl,07f8ah		;55f8   ; los siete punteros de los dibujos que rematan la vista por arriba
	ld a,(0e100h)		;55fb
	dec a			;55fe
	and 003h		;55ff   ; los nueve hoyos se reparten cuatro dibujos, de cuatro en cuatro
	rlca			;5601
	call suma_a_a_hl		;5602
	ld a,(0e142h)		;5605   ; y la orientacion corre el indice otro tanto
	rlca			;5608
	call suma_a_a_hl		;5609
	ld e,(hl)			;560c
	inc hl			;560d
	ld d,(hl)			;560e
	ex de,hl			;560f
	ld de,07881h		;5610   ; VRAM 0x3881: fila 4, columna 1, justo encima de la vista
	ld bc,00302h		;5613   ; B tres filas, C las dos mitades de diez tiles
pinta_el_recuadro_fila:		; Una fila de diez tiles
	push bc			;5616
	call abre_la_vram_para_escribir		;5617
	ld b,00ah		;561a   ; diez tiles por mitad
pinta_el_recuadro_orden:		; Reparte la orden: literal si el nibble alto no es cero, racha si lo es
	push bc			;561c
	ld a,(hl)			;561d
	and 0f0h		;561e   ; nibble alto a cero: racha
	jr z,pinta_el_recuadro_racha		;5620
	ld a,(hl)			;5622
	inc hl			;5623
	and 00fh		;5624   ; si no, el nibble bajo dice cuantos tiles vienen tal cual
	ld b,a			;5626
	push af			;5627
	call vuelca_b_bytes		;5628
	jr pinta_el_recuadro_cuenta		;562b
pinta_el_recuadro_racha:		; La racha
	ld a,(hl)			;562d
	ld b,(hl)			;562e   ; la cuenta y, detras, el tile que se repite
	inc hl			;562f
	ld c,(hl)			;5630
	inc hl			;5631
	push af			;5632
	call rellena_con_c		;5633
pinta_el_recuadro_cuenta:		; Descuenta lo escrito de los diez de la fila
	pop af			;5636
	pop bc			;5637
	push bc			;5638
	ld c,b			;5639
	ld b,a			;563a
	ld a,c			;563b
	sub b			;563c   ; descuenta de los diez lo que acaba de escribir
	pop bc			;563d
	ld b,a			;563e
	jr nz,pinta_el_recuadro_orden		;563f   ; y sigue con la orden siguiente hasta llenar la mitad
	ld a,020h		;5641   ; 0x20, lo que ocupa una fila entera de la pantalla
	call suma_a_a_de		;5643
	pop bc			;5646
	djnz pinta_el_recuadro_fila		;5647
	ld de,0788bh		;5649   ; VRAM 0x388B: la mitad derecha del remate
	ld b,003h		;564c
	dec c			;564e
	jr nz,pinta_el_recuadro_fila		;564f
	ld de,078e1h		;5651   ; VRAM 0x38E1: fila 7, columna 1, donde empieza la vista
	ld hl,0e4c0h		;5654
	ld b,010h		;5657   ; dieciseis filas de lienzo
vuelca_el_lienzo:		; Las dieciseis filas de veinte tiles de 0xE4C0 a la VRAM 0x38E1
	push bc			;5659
	ld b,014h		;565a   ; veinte tiles por fila
	call vuelca_b_bytes_en_vram		;565c
	ld a,020h		;565f   ; y de fila a fila de la pantalla van 0x20
	call suma_a_a_de		;5661
	pop bc			;5664
	djnz vuelca_el_lienzo		;5665
	ld de,0e135h		;5667   ; en 0xE135 y 0xE134 acabaran la columna y la fila de la bola, ya en pixeles
	ld hl,0e136h		;566a
	ld a,(0e142h)		;566d   ; la orientacion decide si hay que reflejar las casillas antes de convertirlas
	or a			;5670
	jr z,coloca_al_jugador_calcula		;5671   ; de frente no se toca nada
	dec a			;5673
	jr z,coloca_al_jugador		;5674
	inc hl			;5676
	dec a			;5677
	dec a			;5678
	jr z,coloca_al_jugador_refleja		;5679

; ----------------------------------------------------------------------
; ----- Donde cae la bola dentro de la vista -----
; ----------------------------------------------------------------------
coloca_al_jugador:		; Ajusta las casillas 0xE135 y 0xE136 segun la orientacion del hoyo -a veces hay que reflejarlas o cambiarlas de sitio- y de ahi saca donde va la bola en pantalla
	ld a,007h		;567b
	sub (hl)			;567d   ; refleja la casilla: 7 menos lo que valga
	ld (hl),a			;567e
	ld a,(0e142h)		;567f
	cp 002h		;5682   ; con la orientacion 2 basta con reflejar una
	jr z,coloca_al_jugador_calcula		;5684
	inc hl			;5686
coloca_al_jugador_refleja:		; La segunda reflexion
	ld a,007h		;5687
	sub (hl)			;5689   ; y aqui va la otra
	ld (hl),a			;568a
coloca_al_jugador_calcula:		; Pasa la casilla a pixeles: cuatro columnas por casilla mas 0x48
	ld l,036h		;568b
	ld b,(hl)			;568d   ; 0xE136 son los octavos de casilla en horizontal
	inc hl			;568e
	ld c,(hl)			;568f   ; y 0xE137 los de vertical
	ld a,(0e142h)		;5690
	cp 002h		;5693
	jr c,coloca_al_jugador_ajusta		;5695
	ld (hl),b			;5697   ; con el hoyo visto de lado, fila y columna se intercambian
	dec hl			;5698
	ld (hl),c			;5699
coloca_al_jugador_ajusta:		; Con el hoyo de lado hay que corregir con la tabla de 0x57AA
	ld l,036h		;569a
	ld a,(hl)			;569c
	rlca			;569d   ; por cuatro, aunque despues se le quite la mitad
	rlca			;569e
	add a,048h		;569f   ; 0x48 lleva la bola al centro del lienzo
	push af			;56a1
	ld a,(0e142h)		;56a2
	cp 002h		;56a5
	jr c,coloca_al_jugador_sin_desvio		;56a7
	ld a,(0e138h)		;56a9   ; la casilla que hay justo debajo de la bola
	cp 02dh		;56ac   ; solo los codigos 0x2D a 0x30 tienen sitio fijo en vez de calculado
	jr c,coloca_al_jugador_sin_desvio		;56ae
	cp 031h		;56b0
	jr nc,coloca_al_jugador_sin_desvio		;56b2
	sub 02dh		;56b4
	push af			;56b6
	ld a,(0e140h)		;56b7   ; el terreno donde ha caido
	ld hl,057aah		;56ba   ; la tabla de sitios normal
	dec a			;56bd
	jr nz,coloca_al_jugador_desvia		;56be
	ld hl,057b2h		;56c0   ; y esta otra si esta en el bunker
coloca_al_jugador_desvia:		; Aplica la pareja de la tabla
	pop af			;56c3
	rlca			;56c4   ; dos bytes por casilla
	call suma_a_a_hl		;56c5
	ld a,(hl)			;56c8
	ld (de),a			;56c9   ; el primero es la columna
	inc hl			;56ca
	dec de			;56cb
	ld a,(hl)			;56cc
	ld (de),a			;56cd   ; y el segundo la fila
	ld c,a			;56ce
	pop af			;56cf   ; se tira el calculo normal, que ya no vale
	ld a,c			;56d0
	jr coloca_al_jugador_sprites		;56d1
coloca_al_jugador_sin_desvio:		; El caso normal: dos pixeles por escalon
	pop af			;56d3
	push af			;56d4
	xor a			;56d5
	ld b,(hl)			;56d6   ; los octavos horizontales de la casilla
	ld c,a			;56d7
	cp b			;56d8
	jr z,coloca_al_jugador_resta		;56d9
coloca_al_jugador_escalones:		; El bucle que los suma
	add a,002h		;56db   ; dos pixeles por octavo, que luego se restan de los cuatro de antes
	djnz coloca_al_jugador_escalones		;56dd
	ld c,a			;56df
coloca_al_jugador_resta:		; Descuenta y calcula la fila
	pop af			;56e0
	sub c			;56e1   ; cuatro por octavo menos dos por octavo: la columna avanza DOS pixeles por octavo de casilla
	ld (de),a			;56e2
	dec de			;56e3
	inc hl			;56e4
	ld a,(hl)			;56e5
	rlca			;56e6   ; la fila, en cambio, cuatro pixeles por octavo
	rlca			;56e7
	add a,098h		;56e8   ; 0x98 baja la bola a la parte de abajo de la vista, que es donde se dibuja siempre
	ld (de),a			;56ea
coloca_al_jugador_sprites:		; Deja la posicion en 0xE0B0 y 0xE0B4, y el color 0x0F o 0x08 segun de quien sea el turno
	ld hl,0e0b0h		;56eb   ; la bola son dos sprites superpuestos: 0xE0B0 la silueta y 0xE0B4 el relleno
	ld (0e0b4h),a		;56ee   ; las dos capas comparten fila
	ld (hl),a			;56f1
	inc hl			;56f2
	inc de			;56f3
	ld a,(de)			;56f4
	ld (0e0b5h),a		;56f5   ; y columna
	ld (hl),a			;56f8
	inc hl			;56f9
	inc hl			;56fa
	ld a,001h		;56fb   ; color 1, negro, para la silueta
	ld (0e0bbh),a		;56fd
	ld (hl),a			;5700   ; la de la bola de la vista, y 0xE0BB la de la marca del plano
	ld b,00fh		;5701   ; 0x0F, blanco: la bola del primer jugador
	call de_quien_es_el_turno		;5703
	jr z,coloca_al_jugador_color		;5706
	ld b,008h		;5708   ; 0x08, rojo: la del segundo
coloca_al_jugador_color:		; Guarda el color de las dos capas de la bola
	ld a,b			;570a
	ld (0e0b7h),a		;570b   ; 0x0F blanco para el primer jugador y 0x08 rojo para el segundo: el color de la bola en la vista de cerca
	ld (0e0bfh),a		;570e   ; y el mismo color para la copia de la bola que va sobre el plano de la derecha
	call lee_parametro		;5711   ; detras va el puntero a 0x4815: el guion que rehace los patrones de sprite de 0x1800, la bola de cuatro pixeles y el punto de dos del plano

; ----------------------------------------------------------------------
; DATOS parametro_5714: Parametro en linea del call de 0x5711: apunta a 0x4815
;   0x5714..0x5716  (2 bytes)
DATA_parametro_5714:
	defw 04815h	; 5714  -> DATA_guion_borra_sprites

; ======================================================================
; CODIGO 0x5716..0x579b  (133 bytes)
; ======================================================================


termina_la_vista:		; Esconde los sprites que sobran, pone los de la bola y limpia la barra de fuerza
	ld bc,001cfh		;5716   ; 0xCF baja el sprite por debajo de la pantalla; con 0xD0 se cortaria la lista y desaparecerian tambien los de detras
	ld de,07b30h		;5719   ; VRAM 0x3B30: el atributo del sprite 12, la bola del primer jugador
	call de_quien_es_el_turno		;571c
	jr nz,termina_la_vista_bola		;571f
	ld e,034h		;5721   ; si juega el primero, el que sobra es el sprite 13, la bola del segundo
termina_la_vista_bola:		; Vuelca los dos atributos de la bola
	call rellena_vram_con_c		;5723   ; esconde la bola del jugador que NO tiene el turno
	ld hl,0e0b4h		;5726   ; 0xE0B4, la capa de color de la bola en la vista de cerca
	ld e,030h		;5729   ; el primer jugador pinta en los sprites 12 y 14
	ld bc,07b38h		;572b   ; BC lleva de paso el destino de la sombra
	call de_quien_es_el_turno		;572e
	jr z,termina_la_vista_sombra		;5731
	ld c,03ch		;5733   ; y el segundo en los sprites 13 y 15
	ld e,034h		;5735
termina_la_vista_sombra:		; Y los de su sombra
	push bc			;5737
	call vuelca_cuatro_bytes		;5738   ; los cuatro bytes del atributo: y, x, numero de patron y color
	pop de			;573b
	ld hl,0e0bch		;573c   ; 0xE0BC es la misma bola pero dibujada sobre el plano de la derecha
	call vuelca_cuatro_bytes		;573f
	ld e,050h		;5742   ; VRAM 0x3B50: los sprites 20 y 21, las capas negras de debajo de las dos bolas
	ld bc,008cfh		;5744   ; ocho bytes a 0xCF, las dos fichas enteras: esas capas solo se ven mientras la bola vuela
	call rellena_vram_con_c		;5747
	ld hl,0e14dh		;574a   ; 0xE14D lleva los millares y las centenas de lo que le falta al primer jugador
	call de_quien_es_el_turno		;574d
	jr z,pinta_la_distancia		;5750
	ld l,04fh		;5752   ; y 0xE14F lo mismo para el segundo
pinta_la_distancia:		; Escribe las tres cifras de 0xE14D y 0xE14C en la VRAM 0x3890: los metros que faltan
	ld de,07890h		;5754   ; VRAM 0x3890: fila 4, columna 16, dentro del panel de la derecha
	call pinta_dos_cifras		;5757   ; pinta los dos digitos BCD del byte alto: millares y centenas
	dec hl			;575a   ; atras dos bytes, al que lleva decenas y unidades
	dec hl			;575b
	inc de			;575c   ; y dos tiles adelante en la VRAM
	inc de			;575d
	call abre_la_vram_para_escribir		;575e
	ld a,(hl)			;5761
	call pinta_cifra_alta		;5762   ; solo el nibble alto: la cifra baja -las decimas- no llega a pintarse nunca
	inc de			;5765
	ld bc,001e1h		;5766   ; y detras un tile 0xE1, el que cierra la cifra
	call rellena_vram_con_c		;5769
termina_la_vista_estado:		; Borra la barra de la VRAM 0x3AE8, pone 0xE1B0 a cero y decide el estado siguiente: 0x10 si hay que esperar, 0x04 para dejar apuntar
	call pinta_la_bandera		;576c
	ld de,07ae8h		;576f   ; VRAM 0x3AE8: la fila 23, donde vive la barra de fuerza
	ld bc,00a00h		;5772   ; diez tiles a cero: la barra se borra entera
	call rellena_vram_con_c		;5775
	ld l,b			;5778
	ld h,l			;5779
	ld (0e1b0h),hl		;577a   ; 0xE1B0 y 0xE1B1 a cero: la barra vuelve abajo y sin ajuste fino
	xor a			;577d
	ld (0e129h),a		;577e   ; 0xE129 a cero: ya no se esta dibujando
	ld hl,0e122h		;5781   ; 0xE122 es el reparto de tareas del cuadro, un bit por tarea
	ld a,(0e147h)		;5784   ; 0xE147 esta puesto cuando la vista se ha vuelto a montar en mitad de un golpe
	or a			;5787
	jr z,termina_la_vista_a_apuntar		;5788
	ld (hl),b			;578a   ; y entonces el cuadro se queda quieto: manda el bucle de fuera
	ret			;578b
termina_la_vista_a_apuntar:		; Pasa a apuntar si no queda nada pendiente
	ld (hl),010h		;578c   ; 0x10 es el bit 4: el cuadro pasa al cierre del golpe (0x4F66)
	ld a,(0e125h)		;578e   ; 0xE125 y 0xE126 avisan de que queda dibujo pendiente
	or a			;5791
	ret nz			;5792
	ld a,(0e126h)		;5793   ; hasta que los dos esten a cero no se devuelve el mando
	or a			;5796
	ret nz			;5797
	ld (hl),004h		;5798   ; 0x04 es el bit 2: entra la mira y ya se puede apuntar
	ret			;579a

; ----------------------------------------------------------------------
; DATOS equis_por_diferencia_de_columna: Cinco coordenadas X, de 32 en 32
;   pixeles: 0x08 0x28 0x48 0x68 0x88. 0x59CB entra por 0x579D con la
;   diferencia entre la columna de la bandera y la de la bola, y baja hasta
;   0x579B si la diferencia es -1 o -2. La sexta -0xA8, la de diferencia 3- es
;   el primer byte de la tabla siguiente
;   0x579b..0x57a0  (5 bytes)
DATA_equis_por_diferencia_de_columna:
	defb 008h,028h,048h,068h,088h	; 579b

; ----------------------------------------------------------------------
; DATOS columna_de_la_bandera: Nueve bytes, uno por hoyo, indexados con 0xE100
;   desde 0x57A0, o sea que su entrada 0 es el 0xA8 que le hace falta a la
;   tabla de arriba. Valen 6, 5, 8, 8, 6, 4, 7, 6 y 4: COMPROBADO, es la
;   columna de la bandera dentro de la rejilla de doce (dos columnas mas que
;   en el plano, que empieza corrido)
;   0x57a0..0x57aa  (10 bytes)
DATA_columna_de_la_bandera:
	defb 0a8h,006h,005h,008h,008h,006h,004h,007h,006h,004h	; 57a0  ..........

; ----------------------------------------------------------------------
; DATOS sitio_de_la_bola_1: Cuatro parejas (x, y) para los codigos de casilla
;   0x2D a 0x30: (0x50,0xA0), (0x58,0xA0), (0x58,0xA0) y (0x58,0xA0). Las lee
;   0x56BA cuando 0xE140 no vale 1. OJO AL ORDEN: 0x56C8 escribe el PRIMER
;   byte en DE y el segundo en DE-1, y 0x56EB se lleva ese segundo a 0xE0B0,
;   que es la FILA del sprite; o sea que el primero es la columna. Leidas al
;   reves caerian sobre el panel de la derecha
;   0x57aa..0x57b2  (8 bytes)
DATA_sitio_de_la_bola_1:
	defw 0a050h,0a058h,0a058h,0a058h	; 57aa

; ----------------------------------------------------------------------
; DATOS sitio_de_la_bola_2: Las mismas cuatro parejas para cuando 0xE140 vale
;   1: (0x60,0xB0), (0x50,0xB0), (0x60,0x9C) y (0x54,0x9C). Las elige 0x56C0
;   0x57b2..0x57ba  (8 bytes)
DATA_sitio_de_la_bola_2:
	defw 0b060h,0b050h,09c60h,09c54h	; 57b2

; ----------------------------------------------------------------------
; DATOS nombres_de_los_palos: Trece parejas de tiles, una por palo, que 0x508E
;   indexa con 0xE121 y 0x5094 escribe en la VRAM 0x3852. Leidas: 1W 3W 1I 3I
;   4I 5I 6I 7I 8I 9I PW SW PT, o sea dos maderas, ocho hierros, el wedge, el
;   de arena y el putter
;   0x57ba..0x57d4  (26 bytes)
DATA_nombres_de_los_palos:
	defw 0e3f1h,0e3f3h,0d5f1h,0d5f3h,0d5f4h,0d5f5h,0d5f6h,0d5f7h	; 57ba
	defw 0d5f8h,0d5f9h,0e3d8h,0e3deh,0d4d8h	; 57ca

; ----------------------------------------------------------------------
; DATOS tipo_de_golpe: Tres rotulos de ocho tiles -STRAIGHT, SLICE y HOOK- que
;   0x534B indexa por ocho con 0xE120 y 0x5351 escribe en la VRAM 0x384C: la
;   forma que se le quiere dar al golpe
;   0x57d4..0x57ec  (24 bytes)
DATA_tipo_de_golpe:
	defb 0deh,0d4h,0ddh,0dah,0d5h,0dfh,0e0h,0d4h	; 57d4  ........
	defb 000h,0deh,0d9h,0d5h,0d6h,0dch,000h,000h	; 57dc  ........
	defb 000h,000h,0e0h,0d3h,0d3h,0d7h,000h,000h	; 57e4  ........

; ----------------------------------------------------------------------
; DATOS saltos_dentro_del_lienzo: Cuatro desplazamientos -0x28, 0x50, 0xA0 y
;   0xF0, o sea las filas 2, 4, 8 y 12 del lienzo de veinte columnas de
;   0xE4C0- que 0x55B6 indexa con 0xE128 menos uno. OJO: 0xE128 llega a valer
;   5, y entonces el indice 4 se sale de la tabla y lee el 0x3A que ya es la
;   instruccion de 0x57F0. No lo he comprobado en el emulador
;   0x57ec..0x57f0  (4 bytes)
DATA_saltos_dentro_del_lienzo:
	defb 028h,050h,0a0h,0f0h	; 57ec

; ======================================================================
; CODIGO 0x57f0..0x5909  (281 bytes)
; ======================================================================


anima_el_swing:		; Si aun no se ha soltado el golpe, suena el 3 y pasa al estado 1; si ya, avanza un cuadro del monigote cada seis
	ld a,(0e144h)		;57f0   ; 0xE144 solo se enciende cuando la bola pisa el tee (casilla 0xEA): fuera del tee no hay monigote y la bola sale sin animacion
	or a			;57f3
	jr nz,anima_el_swing_cuadro		;57f4
	ld a,003h		;57f6
	call pide_un_sonido		;57f8
	call esta_en_el_green		;57fb   ; en el green el golpe suena distinto: se queda solo con el sonido 3
	jr z,anima_el_swing_arranca		;57fe
	xor a			;5800
	ld (0e650h),a		;5801   ; reinicia el barrido del sonido antes de pedir el 1
	inc a			;5804
	call pide_un_sonido		;5805
anima_el_swing_arranca:		; Marca 0xE039 y deja el estado en 1
	ld a,001h		;5808
	ld hl,0e039h		;580a   ; 0xE039 enciende el movimiento de la bola
	ld (hl),a			;580d
	ld hl,0e122h		;580e
	ld (hl),a			;5811   ; y 0xE122 se queda con el bit 0 solo: el cuadro pasa a mover la bola
	ret			;5812
anima_el_swing_cuadro:		; Baja el reloj de 0xE160 y, cuando llega a cero, cambia de cuadro
	ld hl,0e160h		;5813   ; 0xE160 es el reloj del monigote: un cuadro nuevo cada seis interrupciones
	dec (hl)			;5816
	ret nz			;5817
	ld (hl),006h		;5818   ; recarga los seis
	inc hl			;581a
	ld a,(hl)			;581b   ; 0xE161 es el numero de cuadro; sale valiendo 4 y va bajando
	dec a			;581c
	cp 0f8h		;581d   ; 0xF8 es el final: siete cuadros por debajo del cero
	jr nz,anima_el_swing_avanza		;581f
	ld hl,0e1b0h		;5821   ; borra los quince bytes de 0xE1B0 a 0xE1BE: la barra de fuerza y sus tiles
	ld bc,0000fh		;5824
	jp borra_memoria		;5827
anima_el_swing_avanza:		; Elige el cuadro segun donde se paro la barra de fuerza (0xE1B0)
	ld (hl),a			;582a
	ld a,(0e1b0h)		;582b   ; donde se ha parado la barra de fuerza, de 0 a 8
	ld bc,002fdh		;582e   ; con menos de 3 el swing se corta en el cuadro 2 y salta al 0xFD: el palo no llega a subir del todo
	cp 003h		;5831
	jr c,anima_el_swing_ajusta		;5833
	inc c			;5835   ; de 3 a 6 se corta un cuadro mas tarde, en el 1
	dec b			;5836
	cp 007h		;5837   ; de 7 para arriba el monigote hace el swing entero
	jr nc,anima_el_swing_pega		;5839
anima_el_swing_ajusta:		; Corrige el cuadro con el tope
	ld a,(hl)			;583b
	ld (hl),c			;583c   ; adelanta el cuadro al de la bajada
	cp b			;583d   ; pero solo si el swing esta justo en el cuadro del tope
	jr z,anima_el_swing_pega		;583e
	ld (hl),a			;5840   ; si no, lo deja como estaba
anima_el_swing_pega:		; En el cuadro 0xFC suena el 3, se pone 0xE039 y se enciende el bit 0 de 0xE122: la bola echa a volar
	ld a,(hl)			;5841
	cp 0fch		;5842   ; 0xFC es el cuadro del impacto
	jr nz,anima_el_swing_indice		;5844
	push af			;5846
	ld a,003h		;5847
	call pide_un_sonido		;5849
	xor a			;584c
	ld (0e650h),a		;584d   ; reinicia el barrido del sonido
	inc a			;5850
	ld (0e039h),a		;5851   ; 0xE039: a partir de aqui la bola esta en el aire
	call pide_un_sonido		;5854
	pop af			;5857
	ld hl,0e122h		;5858
	set 0,(hl)		;585b   ; bit 0 de 0xE122: el cuadro empieza a mover la bola sin dejar de animar al monigote
anima_el_swing_indice:		; Con los cuadros negativos usa el complemento
	or a			;585d
	jp p,pinta_al_golfista		;585e   ; los cuadros de la bajada se cuentan en negativo
	cpl			;5861   ; el complemento los devuelve a 0..7, que es el cuadro de verdad
pinta_al_golfista:		; Coge el cuadro de 0x78FF -veintisiete bytes cada uno-, le suma la posicion de 0xE162 y lo vuelca a los atributos de sprite desde la VRAM 0x3B04
	ld hl,078ffh		;5862   ; 0x78FF, el primero de los siete cuadros del golfista
	or a			;5865
	jr z,pinta_al_golfista_monta		;5866   ; el cuadro 0 ya esta donde toca
	ld b,a			;5868
pinta_al_golfista_avanza:		; Suma veintisiete por cada cuadro contado
	ld a,01bh		;5869   ; veintisiete bytes por cuadro: nueve sprites de tres
	call suma_a_a_hl		;586b
	djnz pinta_al_golfista_avanza		;586e
pinta_al_golfista_monta:		; Arma en 0xE164 los nueve sprites de tres bytes
	ld de,0e164h		;5870   ; 0xE164: los nueve sprites ya colocados en pantalla
	ld b,009h		;5873
pinta_al_golfista_sprite:		; Un sprite: y con su base, x con la suya y el numero de patron
	push bc			;5875
	ld a,(0e162h)		;5876   ; 0xE162, la y del monigote en pantalla; el hoyo la deja en 0x70
	ld b,a			;5879
	ld a,(0e163h)		;587a   ; 0xE163, su x, que sale valiendo 0x2C
	ld c,a			;587d
	ld a,(hl)			;587e
	cp 0cfh		;587f   ; 0xCF marca un sprite escondido, y a ese no se le suma la posicion
	jr z,pinta_al_golfista_guarda		;5881
	add a,b			;5883
pinta_al_golfista_guarda:		; Guarda los tres bytes
	ld (de),a			;5884
	inc de			;5885
	inc hl			;5886
	ld a,(hl)			;5887
	add a,c			;5888   ; la x sale igual, con su propia base
	ld (de),a			;5889
	inc de			;588a
	inc hl			;588b
	ld a,(hl)			;588c   ; el numero de patron va tal cual
	ld (de),a			;588d
	inc de			;588e
	inc hl			;588f
	pop bc			;5890
	djnz pinta_al_golfista_sprite		;5891
	ld hl,0e164h		;5893   ; los veintisiete bytes ya montados
	ld de,07b04h		;5896   ; a la VRAM 0x3B04, o sea a partir del sprite 1
	ld bc,00309h		;5899   ; tres bytes utiles por sprite, nueve sprites
pinta_al_golfista_vuelca:		; Los escribe de tres en tres en la VRAM, saltandose el byte de color
	call abre_la_vram_para_escribir		;589c   ; hay que reabrir la VRAM en cada sprite porque el cuarto byte -el color- no se toca
pinta_al_golfista_byte:		; Un byte por vuelta
	ld a,(00007h)		;589f   ; 0x0007 de la BIOS: el puerto de datos del VDP
	push bc			;58a2
	ld c,a			;58a3
	ld a,(hl)			;58a4
	out (c),a		;58a5
	pop bc			;58a7
	inc hl			;58a8
	djnz pinta_al_golfista_byte		;58a9
	ld b,003h		;58ab   ; tres bytes otra vez
	inc de			;58ad   ; cuatro adelante en la VRAM: se salta el byte de color del sprite recien escrito
	inc de			;58ae
	inc de			;58af
	inc de			;58b0
	dec c			;58b1   ; y asi los nueve
	jr nz,pinta_al_golfista_vuelca		;58b2
	ret			;58b4
pon_la_bola_en_el_green:		; Convierte la casilla que llega en DE a la posicion en pantalla, tomando como origen la bandera del hoyo (0x5BDC): SIETE PIXELES Y MEDIO por unidad -`srl a` y siete `add a,c` dan C/2 mas 7C-, mas 0x18 en la columna y 0x28 en la fila. NO es el plano de la derecha: sus DOS unicas llamadas, 0x5943 y 0x5973, salen de monta_el_green, o sea de la pantalla del putt
	ld a,(0e100h)		;58b5   ; el hoyo que se juega, contado desde 1
	rlca			;58b8   ; por dos: la tabla de 0x5BDE lleva parejas
	ld hl,05bdch		;58b9   ; 0x5BDC, dos bytes antes de la tabla, para que el hoyo 1 caiga en la primera pareja
	call suma_a_a_hl		;58bc
	ld a,(hl)			;58bf   ; el primer byte del par: la columna de la bandera, en octavos de casilla
	sub 008h		;58c0   ; el origen queda una casilla entera antes de la bandera, o sea ocho octavos
	ld b,a			;58c2
	ld a,(de)			;58c3   ; la posicion fina de la bola, tambien en octavos de casilla
	sub b			;58c4
	ld c,a			;58c5
	srl a		;58c6   ; la mitad, y luego siete veces mas
	ld b,007h		;58c8
pon_la_bola_en_el_green_x:		; El bucle de la COLUMNA: lo que sale va a 0xE0B1, el segundo byte del atributo de sprite
	add a,c			;58ca   ; siete veces y media el octavo: sesenta pixeles por casilla en la pantalla del putt
	djnz pon_la_bola_en_el_green_x		;58cb
	add a,018h		;58cd   ; 0x18, el margen izquierdo
	ld (0e0b1h),a		;58cf   ; la x de la bola
	ld (0e0b5h),a		;58d2   ; y la de su segunda capa, encima
	inc de			;58d5
	inc hl			;58d6   ; y ahora el segundo byte del par: la fila de la bandera
	ld a,(hl)			;58d7
	sub 008h		;58d8   ; el mismo origen, una casilla antes
	ld b,a			;58da
	ld a,(de)			;58db
	sub b			;58dc
	ld c,a			;58dd
	srl a		;58de
	ld b,007h		;58e0
pon_la_bola_en_el_green_y:		; El mismo para la FILA, que va a 0xE0B0, el primer byte del atributo
	add a,c			;58e2
	djnz pon_la_bola_en_el_green_y		;58e3
	add a,028h		;58e5   ; 0x28, el margen de arriba
	ld (0e0b0h),a		;58e7   ; la y de la bola y la de su segunda capa
	ld (0e0b4h),a		;58ea
	ret			;58ed
monta_el_green:		; Limpia las banderas de orientacion y, si no venia ya del green, pinta la pantalla del putt con el guion de 0x6B3D
	xor a			;58ee
	ld hl,0e142h		;58ef   ; 0xE142 y 0xE143: desde donde se mira el hoyo. En el green no hay orientacion que valga
	ld (hl),a			;58f2
	inc hl			;58f3
	ld (hl),a			;58f4
	ld l,092h		;58f5   ; 0xE192 y 0xE193, la copia guardada de esos dos bytes del primer jugador
	ld (hl),a			;58f7
	inc hl			;58f8
	ld (hl),a			;58f9
	ld l,0aah		;58fa   ; 0xE1AA y 0xE1AB, la del segundo
	ld (hl),a			;58fc
	inc hl			;58fd
	ld (hl),a			;58fe
	ld a,(0e146h)		;58ff   ; 0xE146 dice que ya se estaba en la pantalla del putt
	or a			;5902
	jp nz,monta_el_green_termina		;5903   ; y entonces no hay que volver a pintarla
	call lee_parametro		;5906   ; detras va el guion de 0x6B3D: 22 filas de 20 tiles, la pantalla entera menos el marco

; ----------------------------------------------------------------------
; DATOS parametro_5909: Parametro en linea del call de 0x5906: apunta a 0x6B3D
;   0x5909..0x590b  (2 bytes)
DATA_parametro_5909:
	defw 06b3dh	; 5909  -> DATA_guion_pantalla_de_tarjeta

; ======================================================================
; CODIGO 0x590b..0x5b1d  (530 bytes)
; ======================================================================


monta_el_green_pinta:		; Dibuja el rombo de flechas de la caida, coloca las dos bolas y ajusta sus colores
	di			;590b
	call pinta_la_pendiente		;590c   ; el rombo de flechas de la caida del green
	ld bc,0000fh		;590f   ; 0x0F blanco para el que juega
	ld de,00008h		;5912   ; y 0x08 rojo para el que espera
	ld hl,0e1d3h		;5915   ; 0xE1D3, el color dentro de la ficha de sprites guardada del segundo jugador
	call de_quien_es_el_turno		;5918
	jr z,monta_el_green_colores		;591b
	ld l,0c3h		;591d   ; con el turno del segundo se cambian los papeles: el retocado es 0xE1C3, el del primero
	ld e,00fh		;591f
	ld c,008h		;5921
monta_el_green_colores:		; Reparte los colores de las cuatro capas
	push hl			;5923
	ld hl,0e0b3h		;5924
	ld (hl),c			;5927   ; 0xE0B3: la bola del que juega toma su color
	ld l,0b7h		;5928
	ld (hl),b			;592a   ; 0xE0B7 a cero: en esta pantalla la segunda capa va transparente
	ld l,0bbh		;592b
	ld (hl),c			;592d   ; 0xE0BB, el mismo color para la tercera
	ld l,0bfh		;592e
	ld (hl),b			;5930   ; y la cuarta tambien apagada
	pop hl			;5931
	ld b,002h		;5932   ; dos parejas de capas
monta_el_green_bucle:		; Deja los patrones de las dos bolas
	ld (hl),e			;5934   ; el color del otro jugador, dentro de su propia ficha guardada
	inc hl			;5935   ; cuatro adelante: el color del atributo siguiente
	inc hl			;5936
	inc hl			;5937
	inc hl			;5938
	ld (hl),d			;5939   ; y ese va transparente, igual que en la ficha de trabajo
	inc hl			;593a
	inc hl			;593b
	inc hl			;593c
	inc hl			;593d
	djnz monta_el_green_bucle		;593e
	ld de,0e134h		;5940   ; 0xE134, la posicion fina de la bola del que juega
	call pon_la_bola_en_el_green		;5943   ; de ahi salen la x y la y de sus cuatro capas en 0xE0B0
	ld hl,0e0b0h		;5946
	ld e,0c0h		;5949   ; 0xE1C0 es la ficha de sprites del primer jugador
	ld bc,0e1d0h		;594b   ; y 0xE1D0 la del segundo
	call de_quien_es_el_turno		;594e
	jr z,monta_el_green_bolas		;5951
	ld e,0d0h		;5953   ; con el turno del segundo se intercambian
	ld c,0c0h		;5955
monta_el_green_bolas:		; Copia las fichas de sprites de cada jugador
	push de			;5957
	push bc			;5958
	push hl			;5959
	call copia_dieciseis_bytes		;595a   ; los dieciseis bytes de las cuatro capas van a la ficha del que juega
	pop de			;595d
	pop hl			;595e
	call que_modo_es		;595f   ; con un solo jugador ya no hay mas bolas que poner
	jr z,monta_el_green_vuelca		;5962
	push de			;5964
	push hl			;5965
	call copia_dieciseis_bytes		;5966   ; recupera la ficha del otro sobre el buffer de trabajo
	ld a,l			;5969   ; el ldir ha dejado HL detras de la ficha: por su byte bajo se sabe cual era
	ld de,0e184h		;596a   ; 0xE184 es la posicion guardada de la bola del primer jugador
	cp 0d0h		;596d
	jr z,monta_el_green_segunda		;596f
	ld e,09ch		;5971   ; y 0xE19C la del segundo
monta_el_green_segunda:		; La bola del otro jugador
	call pon_la_bola_en_el_green		;5973   ; y con ella se coloca la bola del otro en la misma pantalla
	pop de			;5976
	pop hl			;5977
	call copia_dieciseis_bytes		;5978   ; que vuelve a su ficha
monta_el_green_vuelca:		; Manda los atributos a la VRAM 0x3B30
	pop hl			;597b   ; recupera la ficha del que juega
	ld de,0e0b0h		;597c
	call copia_dieciseis_bytes		;597f   ; y la deja otra vez en el buffer de trabajo
	ld hl,0e1c0h		;5982   ; la primera capa del primer jugador
	ld de,07b30h		;5985   ; a la VRAM 0x3B30, el sprite 12
	call vuelca_cuatro_bytes		;5988
	call que_modo_es		;598b   ; con un solo jugador no hay segunda bola
	jr z,monta_el_green_termina		;598e
	ld l,0d0h		;5990   ; la del segundo jugador
	ld e,034h		;5992   ; al sprite 13
	call vuelca_cuatro_bytes		;5994
monta_el_green_termina:		; Esconde los sprites de la mira, pinta la bola pequena y marca 0xE146 y 0xE145
	ld de,07b50h		;5997   ; VRAM 0x3B50: los sprites 20 y 21, las capas negras de debajo de las dos bolas
	ld bc,008cfh		;599a   ; ocho bytes a 0xCF: en la pantalla del putt no hacen falta
	call rellena_vram_con_c		;599d
	ld hl,07290h		;59a0   ; el guion de 0x7290, cuatro filas 08 1C 1C 08
	ld de,05820h		;59a3   ; a la VRAM 0x1820: la bola pequena, la del medio de los seis tamanos de 0x725B
	call pinta_guion_de		;59a6
	ld a,001h		;59a9
	ld (0e146h),a		;59ab   ; 0xE146: ya se esta en la pantalla del putt
	ld (0e145h),a		;59ae   ; y 0xE145: el green trae su bandera dibujada, la de sprite sobra
pinta_la_bandera:		; Coloca el sprite de la bandera en el plano: mira 0x57A0 para saber en que columna esta el hoyo y 0x579D para el desvio segun la columna de la bola
	ld bc,0cfcfh		;59b1   ; 0xCF en las dos y: la bandera escondida de entrada
	ld a,(0e145h)		;59b4   ; 0xE145 se enciende cuando la vista ya trae dibujada la casilla del green (codigos 0x29 y 0x2A)
	or a			;59b7
	jr nz,pinta_la_bandera_monta		;59b8
	ld bc,03030h		;59ba   ; si no, las tres capas van a la fila 0x30
	ld hl,057a0h		;59bd   ; 0x57A0 es la columna de la bandera de cada hoyo dentro de la rejilla de doce
	ld a,(0e100h)		;59c0   ; indexada con el numero de hoyo, que empieza en 1
	call suma_a_a_hl		;59c3
	ld a,(hl)			;59c6
	ld hl,0e130h		;59c7
	sub (hl)			;59ca   ; menos la columna de la bola: la bandera se dibuja en relativo a ella
	ld hl,0579dh		;59cb   ; 0x579D es la tabla de las equis colocada para que la diferencia 0 caiga en la tercera entrada
	cp 0feh		;59ce   ; 0xFE y 0xFF son la bandera una o dos columnas por detras de la bola
	jr nc,pinta_la_bandera_detras		;59d0
	cp 004h		;59d2   ; de cuatro columnas por delante ya no cabe en la vista
	jr c,pinta_la_bandera_cerca		;59d4
	xor a			;59d6
	ld bc,0cfcfh		;59d7   ; y entonces se esconde entera
	jr pinta_la_bandera_monta		;59da
pinta_la_bandera_cerca:		; Cuando la diferencia es 3, esconde una de las dos capas
	cp 003h		;59dc   ; justo a tres columnas
	jr nz,pinta_la_bandera_indexa		;59de
	ld b,0cfh		;59e0   ; y ahi se apaga la primera capa: la bandera asoma solo por la de la izquierda
	jr pinta_la_bandera_indexa		;59e2
pinta_la_bandera_detras:		; Cuando la bola esta pasada, entra por debajo de la tabla
	cp 0feh		;59e4   ; a dos columnas por detras
	jr nz,pinta_la_bandera_lee		;59e6
	ld c,0cfh		;59e8   ; se apaga la tercera capa
	dec hl			;59ea   ; y se retrocede una entrada mas en la tabla
pinta_la_bandera_lee:		; La lectura de la tabla hacia atras
	dec hl			;59eb   ; la tabla se lee hacia atras: 0x28 para una columna de retraso y 0x08 para dos
	ld a,(hl)			;59ec
	jr pinta_la_bandera_monta		;59ed
pinta_la_bandera_indexa:		; La lectura hacia delante
	call suma_a_a_hl		;59ef   ; hacia delante salen 0x48, 0x68, 0x88 y 0xA8: de 32 en 32 pixeles, el ancho de un bloque de cuatro tiles
	ld a,(hl)			;59f2
pinta_la_bandera_monta:		; Arma los tres atributos de la bandera en 0xE139
	ld hl,0e139h		;59f3   ; 0xE139: tres parejas de y y x
	ld (hl),b			;59f6   ; las dos primeras van en el mismo sitio: la bandera se dibuja con dos sprites superpuestos para llevar dos colores
	inc hl			;59f7
	ld (hl),a			;59f8
	inc hl			;59f9
	ld (hl),b			;59fa
	inc hl			;59fb
	ld (hl),a			;59fc
	inc hl			;59fd
	ld (hl),c			;59fe
	inc hl			;59ff
	sub 010h		;5a00   ; la tercera, dieciseis pixeles a la izquierda
	ld (hl),a			;5a02
	ld l,039h		;5a03
	ld de,07b44h		;5a05   ; VRAM 0x3B44: los sprites 17, 18 y 19
	ld b,003h		;5a08   ; tres
pinta_la_bandera_vuelca:		; Los manda de dos en dos a la VRAM 0x3B44
	push bc			;5a0a
	ld b,002h		;5a0b   ; solo y y x; el patron y el color de cada sprite se quedan como estaban
	call vuelca_b_bytes_en_vram		;5a0d
	pop bc			;5a10
	inc de			;5a11   ; cuatro adelante, al atributo siguiente
	inc de			;5a12
	inc de			;5a13
	inc de			;5a14
	djnz pinta_la_bandera_vuelca		;5a15
	ret			;5a17
baja_una_fila:		; DE += 0x10, la anchura de una fila del plano
	ld a,010h		;5a18
suma_a_a_de:		; DE += A
	ex de,hl			;5a1a   ; cruza DE y HL para poder reusar suma_a_a_hl, la rutina mas llamada del cartucho
	call suma_a_a_hl		;5a1b
	ex de,hl			;5a1e
	ret			;5a1f
ficha_del_mando:		; Devuelve en HL la ficha de flancos del jugador con el turno: 0xE00E o 0xE011
	ld hl,0e00eh		;5a20   ; 0xE00E es la ficha del primer mando; son tres bytes por mando, asi que la del segundo empieza en 0xE011
	call de_quien_es_el_turno		;5a23
	ret z			;5a26
	ld l,011h		;5a27
	ret			;5a29
donde_esta_la_bola:		; Pasa la posicion en pantalla (0xE0BC y 0xE0BD) a casilla del mapa: la columna en 0xE130, la fila en 0xE131, la parte fina en 0xE134 y 0xE136. Si se sale del rectangulo bueno, pone 0xE141 a uno, que es FUERA DE LIMITES
	ld hl,0e130h		;5a2a   ; 0xE130 y 0xE131 recogen la casilla, 0xE134 y 0xE135 la posicion fina
	ld de,0e134h		;5a2d
	ld a,(0e0bdh)		;5a30   ; la x de la bola sobre el plano de la derecha
	sub 0a0h		;5a33   ; 0xA0 es la columna 20, dos casillas antes de que empiece el plano: la rejilla lleva justo dos columnas de relleno a la izquierda
	cp 010h		;5a35   ; por debajo de la columna 2 no hay mapa
	jr nc,donde_esta_la_bola_fila		;5a37
donde_esta_la_bola_fuera:		; El aviso de fuera de limites
	ld a,001h		;5a39
	ld (0e141h),a		;5a3b   ; 0xE141 a uno: OUT OF BOUNDS
	ret			;5a3e
donde_esta_la_bola_fila:		; La cuenta de la fila
	cp 055h		;5a3f   ; 0x55 es el borde derecho: de la columna 10 no se pasa
	jr nc,donde_esta_la_bola_fuera		;5a41
	inc a			;5a43   ; el mas uno centra el pixel dentro de la casilla
	ld (de),a			;5a44
	and 007h		;5a45   ; los tres bits bajos: en que octavo de la casilla cae
	ld (0e136h),a		;5a47   ; 0xE136, que luego elige el bit del dibujo en 0x5C6D
	ld a,(de)			;5a4a
	srl a		;5a4b   ; entre ocho: la columna, de 2 a 10
	srl a		;5a4d
	srl a		;5a4f
	ld (hl),a			;5a51
	inc de			;5a52
	inc hl			;5a53

; ----------------------------------------------------------------------
; ----- Y ahora lo mismo con la otra coordenada -----
; ----------------------------------------------------------------------
	ld a,(0e0bch)		;5a54   ; la y de la bola sobre el plano
	sub 028h		;5a57   ; 0x28 es la fila 5, dos filas antes del plano: las dos primeras filas de la rejilla van en blanco
	cp 010h		;5a59   ; por debajo de la fila 2 no hay mapa
	jr c,donde_esta_la_bola_fuera		;5a5b
	cp 08ch		;5a5d   ; ni por encima de la 17
	jr nc,donde_esta_la_bola_fuera		;5a5f
	inc a			;5a61
	ld (de),a			;5a62
	and 007h		;5a63
	ld (0e137h),a		;5a65   ; 0xE137, el octavo dentro de la fila, que luego elige la linea del dibujo en 0x5C41
	ld a,(de)			;5a68
	srl a		;5a69   ; entre ocho: la fila
	srl a		;5a6b
	srl a		;5a6d
	ld (hl),a			;5a6f
	ld hl,0e200h		;5a70   ; de entrada se lee la rejilla sin girar
	ld (0e132h),hl		;5a73   ; 0xE132 apunta siempre a la rejilla que toca mirar
	call lee_la_casilla		;5a76   ; el codigo de la casilla donde ha caido la bola
	ld (0e12ah),a		;5a79   ; guardado en 0xE12A, que es lo que luego clasifica 0x5BF0
	xor a			;5a7c
	ld (0e142h),a		;5a7d   ; 0xE142, la orientacion, de momento sin girar
	ld a,(0e131h)		;5a80   ; con la bola de la fila 7 para abajo el hoyo se ve de frente y no hay nada que girar
	cp 007h		;5a83
	jp nc,elige_la_rejilla_lee		;5a85
	cp 002h		;5a88   ; la fila 2 es la del fondo del plano: desde ahi se mira de costado
	jr nz,elige_la_rejilla		;5a8a
elige_la_rejilla_de_lado:		; Vista de costado: usa el buffer de 0xE440 y marca 0xE142 con 1
	ld a,001h		;5a8c
	ld (0e142h),a		;5a8e   ; 0xE142 = 1: el hoyo se mira de costado
	ld hl,0e440h		;5a91   ; 0xE440 es la rejilla a la que 0x5445 le ha dado media vuelta
	ld (0e132h),hl		;5a94
	ld hl,0e130h		;5a97
	ld a,00bh		;5a9a   ; once menos la columna
	sub (hl)			;5a9c
	ld (hl),a			;5a9d
	inc hl			;5a9e
	ld a,008h		;5a9f   ; y ocho menos la fila: la rejilla de 0xE440 se leyo hacia atras y solo llega a nueve filas
	sub (hl)			;5aa1
	ld (hl),a			;5aa2
	jr elige_la_rejilla_lee		;5aa3
elige_la_rejilla:		; Segun donde este la bola y la franja recta del hoyo (0x5B1D), decide con cual de las cuatro rejillas se dibuja la vista: 0xE200 sin girar, 0xE300 y 0xE3A0 giradas, 0xE440 al reves
	ld a,(0e100h)		;5aa5   ; el hoyo que se juega
	rlca			;5aa8   ; por dos: la tabla de 0x5B1D lleva parejas
	ld hl,lee_la_casilla_valor		;5aa9   ; apunta a 0x5B1B, dos bytes antes, porque el hoyo 1 es la primera pareja
	call suma_a_a_hl		;5aac
	ld de,0e130h		;5aaf
	ld a,(de)			;5ab2
	cp (hl)			;5ab3   ; la columna de la bola contra el minimo de la franja recta del hoyo
	jr c,elige_la_rejilla_giro_2		;5ab4   ; a la izquierda de la franja se gira hacia un lado
	inc hl			;5ab6
	cp (hl)			;5ab7   ; a la derecha del maximo, hacia el otro
	jr nc,elige_la_rejilla_giro_3		;5ab8
	xor a			;5aba   ; dentro de la franja no hay giro
	ld (0e142h),a		;5abb
	ld hl,0e200h		;5abe   ; y se lee la rejilla tal cual, la de 0xE200
	ld (0e132h),hl		;5ac1
	inc de			;5ac4
	ld a,(de)			;5ac5
	cp 005h		;5ac6   ; pero en las filas 3 y 4, las del fondo, aun asi se mira de costado
	jr nc,elige_la_rejilla_lee		;5ac8
	jr elige_la_rejilla_de_lado		;5aca
elige_la_rejilla_giro_2:		; El giro que usa 0xE3A0
	ld a,002h		;5acc
	ld (0e142h),a		;5ace   ; 0xE142 = 2
	ex de,hl			;5ad1
	ld a,00bh		;5ad2   ; once menos la columna
	sub (hl)			;5ad4
	inc hl			;5ad5
	ld b,(hl)			;5ad6   ; y luego fila y columna cambian de sitio: el giro de noventa grados
	ld (hl),a			;5ad7
	dec hl			;5ad8
	ld (hl),b			;5ad9
	ld hl,0e3a0h		;5ada   ; 0xE3A0, la rejilla que 0x5425 dejo girada
	ld (0e132h),hl		;5add
	jr elige_la_rejilla_lee		;5ae0
elige_la_rejilla_giro_3:		; El que usa 0xE300
	ld a,003h		;5ae2
	ld (0e142h),a		;5ae4   ; 0xE142 = 3
	ex de,hl			;5ae7
	ld b,(hl)			;5ae8
	inc hl			;5ae9
	ld a,00bh		;5aea   ; el mismo cambio de sitio, pero reflejando la fila en vez de la columna: el giro hacia el otro lado
	sub (hl)			;5aec
	ld (hl),b			;5aed
	dec hl			;5aee
	ld (hl),a			;5aef
	ld hl,0e300h		;5af0   ; 0xE300, la rejilla que giro 0x5401
	ld (0e132h),hl		;5af3
elige_la_rejilla_lee:		; Lee la casilla que queda debajo de la bola y deja el puntero corrido cincuenta bytes hacia atras, que es donde empieza la vista
	call lee_la_casilla		;5af6   ; el codigo de la casilla, ya leido de la rejilla elegida
	ld (0e138h),a		;5af9   ; guardado en 0xE138
	or a			;5afc
	ld de,00032h		;5afd   ; 0x32 = cuatro filas de doce mas dos: la vista de cerca arranca cuatro casillas por delante de la bola y dos a su izquierda
	sbc hl,de		;5b00
	ld (0e132h),hl		;5b02   ; y 0xE132 queda apuntando ahi
	ret			;5b05
lee_la_casilla:		; Devuelve el codigo de la casilla (0xE130, 0xE131) de la rejilla a la que apunta 0xE132: doce bytes por fila
	ld hl,0e131h		;5b06   ; 0xE131, la fila
	ld a,(hl)			;5b09
	or a			;5b0a   ; con la fila 0 no hay nada que sumar
	jr z,lee_la_casilla_columna		;5b0b
	ld b,a			;5b0d
	xor a			;5b0e
lee_la_casilla_fila:		; Suma doce por cada fila
	add a,00ch		;5b0f   ; doce bytes por fila de la rejilla
	djnz lee_la_casilla_fila		;5b11
lee_la_casilla_columna:		; Suma la columna
	dec hl			;5b13
	add a,(hl)			;5b14   ; mas la columna de 0xE130
	ld hl,(0e132h)		;5b15   ; 0xE132 dice cual de las cuatro rejillas se esta leyendo
	call suma_a_a_hl		;5b18
lee_la_casilla_valor:		; El `ld a,(hl)` final, que ademas hace de entrada 0 de la tabla de 0x5B1D
	ld a,(hl)			;5b1b   ; este `ld a,(hl)` es ademas la entrada 0 de la tabla de 0x5B1D, la que no se usa
	ret			;5b1c

; ----------------------------------------------------------------------
; DATOS franja_recta_por_hoyo: Nueve parejas (minimo, maximo), una por hoyo,
;   que 0x5AA9 indexa con 0xE100 apuntando a 0x5B1B -o sea que la entrada 0
;   cae sobre el `ld a,(hl)` de 0x5B1B y no se usa-. Si la columna de la bola
;   0xE130 cae dentro, 0x5ABA pone a cero 0xE142 y hace que la vista se tome
;   de la rejilla sin girar (0xE200)
;   0x5b1d..0x5b2f  (18 bytes)
DATA_franja_recta_por_hoyo:
	defw 00705h,00604h,00907h,00907h,00705h,00503h,00806h,00705h	; 5b1d
	defw 00503h	; 5b2d

; ======================================================================
; CODIGO 0x5b2f..0x5bde  (175 bytes)
; ======================================================================


calcula_lo_que_falta:		; Fuera del green mide la distancia a la bandera; en el green se va a 0x5D86
	call esta_en_el_green		;5b2f   ; 0xE140 vale 5 cuando la bola esta en el green
	jr nz,mide_hasta_la_bandera		;5b32
	call que_modo_es		;5b34   ; con un solo jugador se mide directamente dentro del green
	jp z,mide_en_el_green		;5b37
	ld hl,0e190h		;5b3a   ; 0xE190 es el terreno guardado del primer jugador
	call de_quien_es_el_turno		;5b3d
	jr nz,calcula_lo_que_falta_verde		;5b40
	ld l,0a8h		;5b42   ; y 0xE1A8 el del segundo
calcula_lo_que_falta_verde:		; Mira la casilla guardada del jugador y decide
	ld a,(hl)			;5b44
	cp 005h		;5b45   ; si el otro tambien esta en el green, se miden los dos juntos
	jp z,mide_en_el_green		;5b47
	jp guarda_lo_que_falta		;5b4a   ; y si no, lo que se acaba de medir se guarda tal cual
mide_hasta_la_bandera:		; Resta la casilla de la bola a la de la bandera (0x5BDE) por el eje que toque segun la orientacion, multiplica la diferencia por 48 y pasa el resultado a BCD
	ld a,(0e100h)		;5b4d   ; el hoyo, por dos
	rlca			;5b50
	ld hl,divide_restando_repite		;5b51   ; 0x5BDC, la tabla de banderas menos dos bytes
	call suma_a_a_hl		;5b54
	ld de,0e134h		;5b57   ; 0xE134 y 0xE135, la bola en octavos de casilla
	ld a,(0e142h)		;5b5a   ; 0xE142 decide por que eje se mide y en que sentido, porque la vista puede estar girada
	cp 002h		;5b5d
	jr c,mide_hasta_la_bandera_eje		;5b5f
	jr z,mide_hasta_la_bandera_cruza		;5b61
	jr mide_hasta_la_bandera_resta		;5b63
mide_hasta_la_bandera_eje:		; Elige el eje segun 0xE142
	inc hl			;5b65   ; con 0 y 1 lo que cuenta es la fila, no la columna
	inc de			;5b66
	or a			;5b67
	jr z,mide_hasta_la_bandera_resta		;5b68
mide_hasta_la_bandera_cruza:		; Cruza los dos punteros
	ex de,hl			;5b6a   ; con 1 y 2 la resta va del reves: la bandera queda por detras de la bola
mide_hasta_la_bandera_resta:		; La resta y la multiplicacion por 48
	ld a,(de)			;5b6b   ; la diferencia, en octavos de casilla
	sub (hl)			;5b6c
	ld hl,0e060h		;5b6d   ; 0xE060 es el buffer de la multiplicacion de 0x7175: cuatro bytes, el alto primero
	ld (hl),000h		;5b70
	inc hl			;5b72
	ld (hl),a			;5b73   ; la diferencia va de multiplicando
	inc hl			;5b74
	ld (hl),000h		;5b75
	inc hl			;5b77
	ld (hl),030h		;5b78   ; por 48, o sea 384 por casilla entera
	call multiplica		;5b7a
	ld hl,(0e061h)		;5b7d   ; el producto sale con el byte alto en 0xE061
	ex de,hl			;5b80
	ld h,e			;5b81   ; y hay que darle la vuelta para tenerlo en HL
	ld l,d			;5b82
	ld (0e148h),hl		;5b83   ; 0xE148: el numero que se va a desgranar en cifras BCD
	ld de,003e8h		;5b86   ; los millares
	ld b,010h		;5b89   ; que suman 0x10 al nibble alto de 0xE14B
	call divide_restando		;5b8b
	ld hl,(0e148h)		;5b8e
	ld de,00064h		;5b91   ; las centenas
	ld b,001h		;5b94   ; al nibble bajo del mismo byte
	call divide_restando		;5b96
	ld a,(0e148h)		;5b99   ; lo que sobra, siempre menos de 100
	ld b,00ah		;5b9c   ; y ahora las decenas, de diez en diez
mide_hasta_la_bandera_decenas:		; El ultimo paso de la conversion a BCD, el de las decenas
	sub b			;5b9e
	jr c,mide_hasta_la_bandera_unidades		;5b9f   ; cuando la resta se pasa, lo que quedaba eran las unidades
	ld (0e148h),a		;5ba1
	push af			;5ba4
	ld a,(0e14ah)		;5ba5   ; cada decena suma 0x10 al nibble alto de 0xE14A
	add a,010h		;5ba8
	ld (0e14ah),a		;5baa
	pop af			;5bad
	jr mide_hasta_la_bandera_decenas		;5bae
mide_hasta_la_bandera_unidades:		; Junta decenas y unidades
	ld a,(0e148h)		;5bb0   ; el resto son las unidades
	ld hl,0e14ah		;5bb3
	or (hl)			;5bb6   ; y se meten en el nibble bajo, junto a las decenas
	ld (hl),a			;5bb7
guarda_lo_que_falta:		; Deja la distancia BCD en 0xE14C o en 0xE14E, segun el jugador
	ld de,0e14ch		;5bb8   ; 0xE14C para el primer jugador
	call de_quien_es_el_turno		;5bbb
	jr z,guarda_lo_que_falta_copia		;5bbe
	inc de			;5bc0   ; 0xE14E para el segundo
	inc de			;5bc1
guarda_lo_que_falta_copia:		; El ldir de dos bytes
	ld bc,00002h		;5bc2   ; los dos bytes BCD: decenas y unidades primero, millares y centenas despues
	ldir		;5bc5
	push bc			;5bc7   ; el ldir deja BC a cero
	pop hl			;5bc8
	ld (0e14ah),hl		;5bc9   ; y con eso se limpian 0xE14A y 0xE14B para la medida siguiente
	ret			;5bcc
divide_restando:		; Resta DE de HL tantas veces como pueda, sumando B a 0xE14B por cada resta: es la division que saca cada cifra decimal
	or a			;5bcd   ; limpia el acarreo antes del sbc
divide_restando_bucle:		; Una resta
	sbc hl,de		;5bce
	ret c			;5bd0   ; cuando la resta se pasa, se acabo esta cifra
	ld (0e148h),hl		;5bd1   ; cada resta buena deja el resto en 0xE148
	ld a,(0e14bh)		;5bd4   ; y suma B a 0xE14B: 0x10 para los millares, 1 para las centenas
	add a,b			;5bd7
	ld (0e14bh),a		;5bd8
	or a			;5bdb
divide_restando_repite:		; El `jr` que cierra el bucle, y de paso la entrada 0 de la tabla de 0x5BDE
	jr divide_restando_bucle		;5bdc   ; este `jr` es ademas la entrada 0 de la tabla de banderas de 0x5BDE, la que no se usa

; ----------------------------------------------------------------------
; DATOS bandera_de_cada_hoyo: Nueve parejas (x, y) en casillas, una por hoyo,
;   indexadas con 0xE100 desde 0x5BDC -otra vez la entrada 0 cae sobre codigo,
;   el `jr` de 0x5BDC-. 0x53DA les suma 0xA0 y 0x20 y las escribe en el
;   atributo del sprite 16 (VRAM 0x3B40): es la bandera sobre el plano de la
;   derecha. 0x5B51 usa la misma pareja para medir lo que falta
;   0x5bde..0x5bf0  (18 bytes)
DATA_bandera_de_cada_hoyo:
	defw 02830h,02828h,02840h,02840h,02830h,02820h,02838h,02830h	; 5bde
	defw 02820h	; 5bee

; ======================================================================
; CODIGO 0x5bf0..0x5ca3  (179 bytes)
; ======================================================================


clasifica_el_terreno:		; Mira el codigo de la casilla de debajo de la bola: 0xC4 no cuenta, 0xEA enciende 0xE144 y los demas se buscan en los umbrales de 0x5CA3 para dejar el tipo en 0xE140
	ld hl,00000h		;5bf0   ; 0xE13F y 0xE140 a cero: la clase del terreno todavia sin decidir
	ld (0e13fh),hl		;5bf3
	ld a,(0e141h)		;5bf6   ; 0xE141 avisa de que la bola se ha salido del mapa
	or a			;5bf9
	ret nz			;5bfa   ; y entonces no hay terreno que clasificar
	ld (0e144h),a		;5bfb
	ld a,(0e12ah)		;5bfe   ; 0xE12A, el codigo de la casilla que hay debajo de la bola
	cp 0c4h		;5c01   ; 0xC4 es el borde del plano: no cuenta como terreno
	ret z			;5c03
	cp 0eah		;5c04   ; 0xEA es el tee
	jr nz,clasifica_el_terreno_busca		;5c06
	ld a,001h		;5c08   ; y solo ahi se enciende 0xE144, que es lo que hace salir al monigote y animar el swing
	ld (0e144h),a		;5c0a
	ret			;5c0d
clasifica_el_terreno_busca:		; Empieza a recorrer los umbrales
	ld hl,05ca3h		;5c0e   ; los once pares de umbrales de 0x5CA3
clasifica_el_terreno_par:		; Compara el codigo con la pareja de turno
	cp (hl)			;5c11   ; el codigo tiene que llegar al primer byte del par
	inc hl			;5c12
	jr c,clasifica_el_terreno_avanza		;5c13
	cp (hl)			;5c15   ; y quedarse por debajo del segundo
	jr c,clasifica_el_terreno_afina		;5c16
clasifica_el_terreno_avanza:		; No cae aqui: cuenta uno mas y prueba con la siguiente
	push hl			;5c18
	ld hl,0e13fh		;5c19   ; una vuelta mas: 0xE13F y 0xE140 llevan la cuenta de los pares probados
	inc (hl)			;5c1c
	inc hl			;5c1d
	inc (hl)			;5c1e
	pop hl			;5c1f
	inc hl			;5c20   ; y otro `inc hl`: con el de 0x5C12 son dos, o sea que los pares NO se solapan
	jr clasifica_el_terreno_par		;5c21
clasifica_el_terreno_afina:		; Con la clase ya sacada, mira el dibujo real del tile en la VRAM para afinar si la bola cae justo en el borde
	ld hl,0e140h		;5c23
	ld a,(hl)			;5c26   ; los pares del 0 al 5 se dan por buenos tal cual
	sub 006h		;5c27
	ret c			;5c29
	inc a			;5c2a   ; del 6 en adelante se renumeran a 1..5: 1 el bunker (codigos 0x2D-0x30) y 5 el green (0x29-0x2C)
	ld (hl),a			;5c2b
	dec hl			;5c2c
	ld (hl),a			;5c2d   ; y la misma clase se guarda tambien en 0xE13F

; ----------------------------------------------------------------------
; ----- Y ahora se mira el DIBUJO del tile para afinar pixel a pixel -----
; ----------------------------------------------------------------------
	ld hl,0e060h		;5c2e   ; 0xE060, el buffer de la multiplicacion
	ld (hl),000h		;5c31
	ld a,(0e12ah)		;5c33
	inc hl			;5c36
	ld (hl),a			;5c37   ; el codigo de la casilla
	inc hl			;5c38
	ld (hl),000h		;5c39
	inc hl			;5c3b
	ld (hl),008h		;5c3c   ; por ocho: cada patron de tile ocupa ocho bytes
	call multiplica		;5c3e
	ld a,(0e137h)		;5c41   ; 0xE137, la linea dentro del tile en la que esta la bola
	ld hl,(0e061h)		;5c44   ; el producto, con el byte alto en 0xE061
	ex de,hl			;5c47
	ld h,e			;5c48
	ld l,d			;5c49
	call suma_a_a_hl		;5c4a
	ld de,02800h		;5c4d   ; VRAM 0x2800: el segundo tercio de los patrones. Vale para cualquier fila porque 0x5E2A dejo los tres tercios iguales
	add hl,de			;5c50
	ex de,hl			;5c51
	call lee_un_byte_de_vram		;5c52   ; y se lee de la VRAM el byte de esa linea del dibujo
	ex af,af'			;5c55   ; se aparta en A'
	ld e,000h		;5c56
	ld a,(0e12ah)		;5c58   ; el codigo otra vez
	cp 029h		;5c5b   ; los codigos 0x29 a 0x30 -green y bunker- llevan el dibujo con el sentido cambiado
	jr c,clasifica_el_terreno_normal		;5c5d
	cp 031h		;5c5f
	jr nc,clasifica_el_terreno_normal		;5c61
	ld e,001h		;5c63   ; y se marca en E para que 0x5C7C lo tenga en cuenta
	ex af,af'			;5c65
	or a			;5c66
	jr z,clasifica_el_terreno_guarda		;5c67   ; con la linea del dibujo en blanco no hay borde: terreno normal
	jr clasifica_el_terreno_mascara		;5c69
clasifica_el_terreno_normal:		; El caso sin borde
	ex af,af'			;5c6b   ; recupera el byte del dibujo
clasifica_el_terreno_mascara:		; Prueba el bit que le toca a la columna con la mascara de 0x5CB9
	push af			;5c6c
	ld hl,05cb9h		;5c6d   ; 0x5CB9 da el bit suelto que le toca a la columna
	ld a,(0e136h)		;5c70   ; 0xE136, el octavo de casilla en el que esta la bola: es la columna del pixel dentro del tile
	call suma_a_a_hl		;5c73
	ld b,(hl)			;5c76
	ld a,(0e12ah)		;5c77   ; el codigo de la casilla, que hace falta abajo
	ld c,a			;5c7a
	pop af			;5c7b
	bit 0,e		;5c7c   ; green y bunker se leen por el otro lado
	jr nz,clasifica_el_terreno_borde		;5c7e
	bit 0,c		;5c80   ; y los codigos impares tambien
	jr nz,clasifica_el_terreno_borde		;5c82
	and b			;5c84   ; el pixel encendido quiere decir que la bola NO pisa el trozo especial de la casilla
	jr nz,clasifica_el_terreno_guarda		;5c85
	ret			;5c87
clasifica_el_terreno_borde:		; La casilla 0x2C se mira por el otro lado
	push af			;5c88
	ld a,c			;5c89
	cp 02ch		;5c8a   ; la casilla 0x2C es un caso aparte
	jr nz,clasifica_el_terreno_prueba		;5c8c
	pop af			;5c8e
	bit 7,a		;5c8f   ; y ahi manda el bit 7, el pixel del borde izquierdo
	ret z			;5c91
	push af			;5c92
clasifica_el_terreno_prueba:		; La prueba del bit
	pop af			;5c93
	and b			;5c94   ; por este lado el pixel encendido SI vale: la clase se queda como estaba
	ret nz			;5c95
clasifica_el_terreno_guarda:		; Guarda la clase, y la 4 se convierte en 3
	ld hl,0e13fh		;5c96   ; 0xE13F guardaba la clase
	ld a,(hl)			;5c99
	inc hl			;5c9a
	ld (hl),000h		;5c9b   ; y el terreno pasa a cero, o sea calle
	cp 004h		;5c9d   ; menos la clase 4 -las casillas de codigo 0x15 a 0x28-
	ret nz			;5c9f
	ld (hl),003h		;5ca0   ; que baja a 3, rough
	ret			;5ca2

; ----------------------------------------------------------------------
; DATOS umbrales_del_terreno: ONCE PAREJAS de bytes -no veintidos umbrales
;   sueltos- que 0x5C0E recorre DE DOS EN DOS: gasta un byte en el `inc hl` de
;   0x5C12 y el otro en el de 0x5C20. Para en la primera pareja que contiene
;   el codigo de la casilla, y las vueltas dadas quedan en 0xE13F y 0xE140.
;   0xE140 es lo que luego castiga el golpe en 0x5109 -a la mitad si vale 1,
;   treinta menos si vale 2-, o sea el tipo de terreno bajo la bola
;   0x5ca3..0x5cb9  (22 bytes)
DATA_umbrales_del_terreno:
	defb 034h,035h	; 5ca3
	defb 000h,000h	; 5ca5
	defb 000h,000h	; 5ca7
	defb 033h,034h	; 5ca9
	defb 031h,033h	; 5cab
	defb 000h,000h	; 5cad
	defb 02dh,031h	; 5caf
	defb 0fch,0ffh	; 5cb1
	defb 001h,015h	; 5cb3
	defb 015h,029h	; 5cb5
	defb 029h,02dh	; 5cb7

; ----------------------------------------------------------------------
; DATOS mascaras_de_un_bit: 0x80 0x40 0x20 0x10 0x08 0x04 0x02 0x01: el bit
;   numero N. La indexa 0x5C6D con 0xE136
;   0x5cb9..0x5cc1  (8 bytes)
DATA_mascaras_de_un_bit:
	defb 080h,040h,020h,010h,008h,004h,002h,001h	; 5cb9  .@ .....

; ======================================================================
; CODIGO 0x5cc1..0x5d50  (143 bytes)
; ======================================================================


lee_un_byte_de_vram:		; Abre la VRAM en DE para leer y devuelve el byte
	call abre_la_vram_para_leer		;5cc1   ; SETRD con la direccion que trae DE
	di			;5cc4
	ld a,(00006h)		;5cc5   ; 0x0006 de la BIOS: el puerto de lectura del VDP
	ld c,a			;5cc8
	in a,(c)		;5cc9
	ret			;5ccb
mira_si_ha_embocado:		; Fuera del green compara la casilla de la bola con la de la bandera; en el green usa la caja de 0x5D50
	call esta_en_el_green		;5ccc   ; en el green se mira por pixeles; fuera, por casillas
	jr z,mira_si_ha_embocado_verde		;5ccf
	ld a,(0e031h)		;5cd1   ; 0xE031 solo esta puesto cuando la bola ya ha tocado suelo
	or a			;5cd4
	ret z			;5cd5
	ld de,0e134h		;5cd6   ; la posicion fina de la bola
	ld hl,05bdch		;5cd9   ; y la de la bandera del hoyo, en la tabla de 0x5BDC
	ld a,(0e100h)		;5cdc
	rlca			;5cdf   ; por dos, que son parejas
	call suma_a_a_hl		;5ce0
	ld a,(de)			;5ce3
	cp (hl)			;5ce4   ; las dos coordenadas tienen que coincidir EXACTAMENTE, hasta el octavo de casilla
	ret nz			;5ce5
	inc hl			;5ce6
	inc de			;5ce7
	ld a,(de)			;5ce8
	cp (hl)			;5ce9   ; la segunda
	jr z,emboca		;5cea
	ret			;5cec
mira_si_ha_embocado_verde:		; Con la bola ya baja, mira si cae dentro de la caja del hoyo
	ld a,(0e0a2h)		;5ced   ; 0xE0A2 es el byte alto de lo que le queda a la bola por recorrer (0xE0A1)
	cp 0c0h		;5cf0   ; con 0xC0 o mas ni se mira el hoyo
	ret nc			;5cf2
	ld hl,05d50h		;5cf3   ; la caja del hoyo: dos parejas de minimo y maximo
	ld de,0e0b0h		;5cf6   ; contra la y y la x del sprite de la bola
	ld b,002h		;5cf9
mira_si_ha_embocado_caja:		; Las dos comparaciones de la caja
	ld a,(de)			;5cfb
	cp (hl)			;5cfc   ; por debajo del minimo, fuera
	ret c			;5cfd
	inc hl			;5cfe
	cp (hl)			;5cff   ; y por encima del maximo, tambien
	ret nc			;5d00
	inc hl			;5d01
	inc de			;5d02
	djnz mira_si_ha_embocado_caja		;5d03   ; las dos coordenadas
emboca:		; Marca el hoyo hecho: pone 0xE110, apaga 0xE122, suena el 4 y esconde los sprites de la bola
	ld hl,0e10ah		;5d05   ; 0xE10A es la ficha de estado del primer jugador
	ld de,0e14ch		;5d08   ; y 0xE14C su distancia
	call de_quien_es_el_turno		;5d0b
	jr z,emboca_marca		;5d0e
	inc de			;5d10   ; 0xE10B y 0xE14E para el segundo
	inc de			;5d11
	inc hl			;5d12
emboca_marca:		; Deja las banderas del jugador
	set 0,(hl)		;5d13   ; bit 0: este jugador ya ha embocado
	ex de,hl			;5d15
	xor a			;5d16   ; y no le queda distancia ninguna
	ld (hl),a			;5d17
	inc hl			;5d18
	ld (hl),a			;5d19
	ld (0e122h),a		;5d1a   ; 0xE122 a cero: el cuadro deja de repartir tareas
	inc a			;5d1d
	ld (0e110h),a		;5d1e   ; 0xE110 avisa al bucle de la partida de que la bola ha parado
	ld de,07b30h		;5d21   ; VRAM 0x3B30, la bola del primer jugador
	call de_quien_es_el_turno		;5d24
	jr z,emboca_borra		;5d27
	ld e,034h		;5d29
emboca_borra:		; Limpia los sprites del plano
	ld bc,001cfh		;5d2b   ; un solo 0xCF: la bola se va debajo de la pantalla
	call rellena_vram_con_c		;5d2e
	inc b			;5d31
	ld a,008h		;5d32   ; ocho bytes mas alla, los sprites 14 y 15: la bola sobre el plano
	call suma_a_a_de		;5d34
	call rellena_vram_con_c		;5d37
	ld e,050h		;5d3a   ; VRAM 0x3B50, la capa negra de esa bola
	inc b			;5d3c
	call rellena_vram_con_c		;5d3d
	ld a,004h		;5d40   ; el sonido 4, el de la bola entrando
	call pide_un_sonido		;5d42
	ld hl,0e0b0h		;5d45   ; y de paso los dieciseis bytes del buffer de sprites
	ld b,010h		;5d48
emboca_esconde:		; Rellena de 0xCF los dieciseis bytes de la ficha de sprites
	ld (hl),0cfh		;5d4a   ; 0xCF en los dieciseis: las cuatro capas fuera de la pantalla
	inc hl			;5d4c
	djnz emboca_esconde		;5d4d
	ret			;5d4f

; ----------------------------------------------------------------------
; DATOS caja_del_hoyo: Dos parejas (minimo, maximo): 0x5F..0x63 para 0xE0B0 y
;   0x4E..0x53 para 0xE0B1. 0x5CF3 mira si la bola cae dentro de las dos, y si
;   cae, 0x5D05 la da por embocada: pone 0xE110 a 1, suena el 4 y esconde los
;   sprites
;   0x5d50..0x5d54  (4 bytes)
DATA_caja_del_hoyo:
	defb 05fh,063h	; 5d50
	defb 04eh,053h	; 5d52

; ======================================================================
; CODIGO 0x5d54..0x5d77  (35 bytes)
; ======================================================================


pinta_la_pendiente:		; Pinta el rombo de cinco filas de 0x5D77 con el tile 0xEB mas la direccion 0xE105: las flechas de la caida del green
	ld a,(0e105h)		;5d54   ; 0xE105, la direccion del viento: en el green marca ademas hacia donde cae
	add a,0ebh		;5d57   ; 0xEB es el primero de los cuatro tiles de flecha
	ld c,a			;5d59
	ld hl,05d77h		;5d5a   ; 0x5D77: cinco fichas de tres bytes, destino en VRAM y cuantos tiles
	ld b,005h		;5d5d   ; las cinco filas del rombo
pinta_la_pendiente_fila:		; Una fila del rombo de flechas
	push bc			;5d5f
	ld d,(hl)			;5d60   ; el destino en la VRAM, byte alto primero
	inc hl			;5d61
	ld e,(hl)			;5d62
	inc hl			;5d63
	ld b,(hl)			;5d64   ; cuantos tiles lleva esta fila del rombo
	inc hl			;5d65
pinta_la_pendiente_tile:		; Un tile de la fila, cada cuatro columnas
	push bc			;5d66
	ld b,001h		;5d67   ; una flecha por vuelta
	call rellena_vram_con_c		;5d69   ; C es el tile: 0xEB mas la direccion de la caida (0xE105)
	pop bc			;5d6c
	inc de			;5d6d   ; de cuatro en cuatro columnas: entre flecha y flecha quedan tres tiles
	inc de			;5d6e
	inc de			;5d6f
	inc de			;5d70
	djnz pinta_la_pendiente_tile		;5d71
	pop bc			;5d73
	djnz pinta_la_pendiente_fila		;5d74   ; las cinco filas del rombo, tal como las lista 0x5D77
	ret			;5d76

; ----------------------------------------------------------------------
; DATOS rombo_de_la_pendiente: Cinco fichas de tres bytes: destino en VRAM con
;   el byte alto primero (0x3908, 0x3946, 0x3984, 0x39C6, 0x3A08) y cuantos
;   tiles poner (2, 3, 4, 3, 2), separados cuatro columnas. 0x5D54 los pinta
;   con el tile 0xEB mas 0xE105: las flechas de la caida del green, en rombo
;   0x5d77..0x5d86  (15 bytes)
DATA_rombo_de_la_pendiente:
	defb 079h,008h,002h	; 5d77
	defb 079h,046h,003h	; 5d7a
	defb 079h,084h,004h	; 5d7d
	defb 079h,0c6h,003h	; 5d80
	defb 07ah,008h,002h	; 5d83

; ======================================================================
; CODIGO 0x5d86..0x603b  (693 bytes)
; ======================================================================


mide_en_el_green:		; Con las dos bolas en el green, pasa sus posiciones a distancia y deja la de cada jugador en 0xE14C y 0xE14E
	call monta_el_green		;5d86
	call esconde_al_golfista		;5d89
	ld hl,0e0b0h		;5d8c   ; la ficha de sprites de la bola: 0xE0B0 la y y 0xE0B1 la x
	ld de,0e1c0h		;5d8f   ; el sitio donde se copia la bola del primer jugador
	call de_quien_es_el_turno		;5d92
	jr z,mide_en_el_green_copia		;5d95
	ld e,0d0h		;5d97   ; la del segundo va 0x10 mas alla, en 0xE1D0
mide_en_el_green_copia:		; Copia la ficha de sprites del jugador
	call copia_dieciseis_bytes		;5d99
	ld hl,0e118h		;5d9c   ; aqui caen las cuatro medidas: dos ejes por cada bola
	ld e,0c0h		;5d9f   ; vuelve a apuntar a la bola del primer jugador
	inc b			;5da1
	call que_modo_es		;5da2   ; con un solo jugador hay una bola que medir; con dos o en partido por hoyos, dos
	jr z,mide_en_el_green_guarda		;5da5
	inc b			;5da7
mide_en_el_green_guarda:		; Guarda el par de medidas
	push bc			;5da8
mide_en_el_green_ejes:		; Las dos coordenadas de una bola
	ld a,(de)			;5da9
	sub 024h		;5daa   ; quita el margen para que el hoyo caiga justo en el 0x3E
	call distancia_al_centro		;5dac   ; lo lejos que esta la bola del hoyo en ese eje
	ld a,(de)			;5daf
	sub 014h		;5db0   ; el otro eje lleva su propio margen, 0x14
	call distancia_al_centro		;5db2
	ld de,0e1d0h		;5db5   ; y ahora la bola del otro jugador
	djnz mide_en_el_green_ejes		;5db8
	pop bc			;5dba
	ld hl,00000h		;5dbb
	ld (0e14ch),hl		;5dbe   ; la distancia a bandera del primer jugador, a cero
	ld (0e14eh),hl		;5dc1   ; y la del segundo
	ld de,0e14ch		;5dc4
	ld hl,0e118h		;5dc7   ; las cuatro medidas recien tomadas
mide_en_el_green_compara:		; Se queda con la mayor de las dos
	ld a,(hl)			;5dca   ; la distancia en uno de los dos ejes
	inc hl			;5dcb
	ld c,(hl)			;5dcc
	inc hl			;5dcd
	cp c			;5dce   ; se queda con la mayor de las dos: la distancia a la bandera se mide por el eje que mas se aleja
	jr nc,mide_en_el_green_apunta		;5dcf
	ld a,c			;5dd1
mide_en_el_green_apunta:		; La escribe en su hueco
	ld (de),a			;5dd2   ; la mayor va al hueco del jugador que toque
	inc de			;5dd3
	inc de			;5dd4
	djnz mide_en_el_green_compara		;5dd5
	ld e,b			;5dd7   ; con B ya agotado, DE queda en cero
	ld d,e			;5dd8
	ld hl,0e10ah		;5dd9   ; el bit 0 de 0xE10A y 0xE10B: ese jugador ya ha embocado
	bit 0,(hl)		;5ddc
	inc hl			;5dde
	jr z,mide_en_el_green_segundo		;5ddf
	ld (0e14ch),de		;5de1   ; quien ya esta dentro del hoyo cuenta como distancia cero
mide_en_el_green_segundo:		; Y lo mismo para el otro jugador
	bit 0,(hl)		;5de5
	ret z			;5de7
	ld (0e14eh),de		;5de8   ; lo mismo para el segundo jugador
	ret			;5dec
distancia_al_centro:		; La distancia del valor de A al centro 0x3E, siempre positiva
	cp 03eh		;5ded   ; 0x3E es donde cae el hoyo una vez quitado el margen
	jr c,distancia_al_centro_baja		;5def
	sub 03eh		;5df1
	jr distancia_al_centro_guarda		;5df3
distancia_al_centro_baja:		; La rama de los valores por debajo del centro
	ld c,a			;5df5
	ld a,03eh		;5df6   ; al otro lado del hoyo se resta al reves, para que la medida salga siempre positiva
	sub c			;5df8
distancia_al_centro_guarda:		; Guarda y avanza
	ld (hl),a			;5df9   ; la medida de este eje
	inc hl			;5dfa
	inc de			;5dfb   ; y a la coordenada siguiente de la ficha de sprites
	ret			;5dfc
copia_dieciseis_bytes:		; Un ldir de 0x10 bytes, la ficha de sprites de un jugador
	ld bc,00010h		;5dfd   ; 0x10 bytes: las cuatro fichas de sprite -bola, sombra y marcas- de un jugador
	ldir		;5e00
	ret			;5e02

; ----------------------------------------------------------------------
; ----- Todos los dibujos del campo a la VRAM. Los destinos llevan puesto el bit 0x4000 de escritura, asi que 0x6008 es la VRAM 0x2008 y no la etiqueta de codigo que el desensamblador cree ver -----
; ----------------------------------------------------------------------
carga_los_dibujos_del_campo:		; Sube a la VRAM todo lo que hace falta para jugar: los patrones de las casillas desde 0x603B, los colores, el marco y, al final, el guion de 0x635B
	ld de,espeja_el_tile_bit		;5e03   ; VRAM 0x2008: los patrones, desde el segundo tile
	call abre_la_vram_para_escribir_2		;5e06
	ld hl,0603bh		;5e09   ; los diez patrones sueltos de 0x603B
	push hl			;5e0c
	ld b,00ah		;5e0d   ; diez patrones
carga_los_dibujos_tanda_1:		; Los diez primeros patrones, dos veces cada uno
	ld c,002h		;5e0f   ; cada uno va dos veces seguidas
	call pinta_el_guion_c_veces		;5e11
	djnz carga_los_dibujos_tanda_1		;5e14
	pop hl			;5e16
	ld b,00ah		;5e17
carga_los_dibujos_tanda_2:		; Y otra vez la misma tanda
	ld c,002h		;5e19   ; y la tanda entera otra vez: cuarenta tiles con solo diez dibujos
	call pinta_el_guion_c_veces		;5e1b
	djnz carga_los_dibujos_tanda_2		;5e1e
	call pinta_guion_aqui		;5e20   ; detras, el guion de 0x6091 con doce patrones mas
	push hl			;5e23
	ld de,02000h		;5e24   ; replica el primer tercio de patrones en los otros dos: los tres tercios de la pantalla comparten dibujos
	ld hl,06800h		;5e27
	call replica_los_tercios		;5e2a
	pop hl			;5e2d
	push hl			;5e2e
	ld de,061a8h		;5e2f   ; VRAM 0x21A8
	call abre_la_vram_para_escribir_2		;5e32
	ld bc,00404h		;5e35   ; cuatro patrones, cuatro copias de cada uno y otras cuatro espejadas
	call pinta_el_tile_y_su_espejo		;5e38
	pop hl			;5e3b
	ld de,069a8h		;5e3c   ; los mismos en el segundo tercio, VRAM 0x29A8
	call abre_la_vram_para_escribir_2		;5e3f
	ld bc,00404h		;5e42
	call pinta_el_tile_y_su_espejo		;5e45
	ld de,062a8h		;5e48   ; los que vienen ahora, a la VRAM 0x22A8
	ld b,002h		;5e4b
carga_los_dibujos_tanda_3:		; Los de 0x60EF, a 0x22A8 y 0x2AA8
	push bc			;5e4d
	call abre_la_vram_para_escribir_2		;5e4e
	ld hl,060efh		;5e51   ; los seis guiones de 0x60EF
	ld bc,00201h		;5e54   ; dos patrones, cada uno con su espejo detras
	call pinta_el_tile_y_su_espejo		;5e57
	call pinta_guion_aqui		;5e5a   ; el guion siguiente se pinta solo, sin espejo
	ld bc,00201h		;5e5d
	call pinta_el_tile_y_su_espejo		;5e60
	call pinta_guion_aqui		;5e63
	pop bc			;5e66
	ld de,06aa8h		;5e67   ; la segunda vuelta va a la VRAM 0x2AA8
	djnz carga_los_dibujos_tanda_3		;5e6a
	ld b,002h		;5e6c
carga_los_dibujos_tanda_4:		; Los de 0x613E
	push bc			;5e6e
	ld hl,0613eh		;5e6f   ; los diecisiete guiones de 0x613E
	ld bc,00801h		;5e72   ; ocho patrones seguidos, cada uno con su espejo
	call pinta_el_tile_y_su_espejo		;5e75
	call pinta_guion_aqui		;5e78
	ld bc,00801h		;5e7b
	call pinta_el_tile_y_su_espejo		;5e7e
	ld de,07328h		;5e81   ; la segunda vuelta remata en la VRAM 0x3328
	call abre_la_vram_para_escribir_2		;5e84
	pop bc			;5e87
	djnz carga_los_dibujos_tanda_4		;5e88
	ld de,06470h		;5e8a
	ld b,002h		;5e8d
carga_los_dibujos_tanda_5:		; Los de 0x61CD, a 0x2470 y 0x2C70
	push bc			;5e8f
	call abre_la_vram_para_escribir_2		;5e90
	ld hl,061cdh		;5e93   ; los siete guiones de 0x61CD
	ld bc,00301h		;5e96
	call pinta_el_tile_y_su_espejo		;5e99
	call pinta_guion_aqui		;5e9c
	ld bc,00201h		;5e9f
	call pinta_el_tile_y_su_espejo		;5ea2
	call pinta_guion_aqui		;5ea5
	pop bc			;5ea8
	ld de,06c70h		;5ea9   ; y otra vez a la VRAM 0x2C70
	djnz carga_los_dibujos_tanda_5		;5eac
	ld b,002h		;5eae
carga_los_dibujos_tanda_6:		; Los de 0x621B, a 0x34F0
	ld hl,0621bh		;5eb0   ; los once guiones de 0x621B
	push bc			;5eb3
	ld bc,00701h		;5eb4
	call pinta_el_tile_y_su_espejo		;5eb7
	call pinta_guion_aqui		;5eba
	ld de,074f0h		;5ebd   ; la segunda vuelta, a la VRAM 0x34F0
	call abre_la_vram_para_escribir_2		;5ec0
	pop bc			;5ec3
	djnz carga_los_dibujos_tanda_6		;5ec4
	push hl			;5ec6
	ld de,06e00h		;5ec7   ; los dos guiones gordos del final, a la VRAM 0x2E00...
	call pinta_guion_de		;5eca
	ld bc,00101h		;5ecd
	call pinta_el_tile_y_su_espejo		;5ed0
	pop hl			;5ed3
	ld de,07600h		;5ed4   ; ...y los mismos al tercer tercio, VRAM 0x3600
	call pinta_guion_de		;5ed7
	ld bc,00101h		;5eda
	call pinta_el_tile_y_su_espejo		;5edd
	call pinta_guion		;5ee0   ; el guion que sigue trae su destino en los dos primeros bytes

; ----------------------------------------------------------------------
; ----- Y ahora los COLORES, que en este cartucho van al principio de la VRAM y no detras de los patrones -----
; ----------------------------------------------------------------------
	ld de,04008h		;5ee3   ; VRAM 0x0008: la tabla de colores
	ld b,003h		;5ee6   ; los tres tercios de la pantalla
carga_los_colores:		; Los tres tercios de la tabla de colores a partir de 0x0008
	ld hl,062cdh		;5ee8   ; el guion de colores de 0x62CD
	call abre_la_vram_para_escribir_2		;5eeb
	push bc			;5eee
	push de			;5eef
	ld c,002h		;5ef0   ; dos tramos de diez vueltas cada uno
carga_los_colores_fila:		; Diez vueltas por tramo
	ld b,00ah		;5ef2
carga_los_colores_vuelta:		; Una vuelta
	push bc			;5ef4
	push hl			;5ef5   ; el mismo guion diez veces, cada una detras de la anterior
	call pinta_guion_aqui		;5ef6
	pop hl			;5ef9
	pop bc			;5efa
	djnz carga_los_colores_vuelta		;5efb
	ld hl,062d2h		;5efd   ; el segundo tramo usa el guion de 0x62D2
	dec c			;5f00
	jr nz,carga_los_colores_fila		;5f01
	ld hl,062d7h		;5f03   ; y 0x62D7 cierra el tercio
	call pinta_guion_aqui		;5f06
	pop hl			;5f09
	ld de,00800h		;5f0a   ; el tercio siguiente esta 0x800 mas alla
	add hl,de			;5f0d
	ex de,hl			;5f0e
	pop bc			;5f0f
	djnz carga_los_colores		;5f10
	ld de,041a8h		;5f12   ; VRAM de color 0x01A8
	call abre_la_vram_para_escribir_2		;5f15
	ld b,008h		;5f18   ; ocho vueltas
carga_los_colores_1a8:		; Ocho vueltas del guion de 0x62EA en 0x01A8
	ld hl,062eah		;5f1a   ; siempre el mismo guion, que se repinta ocho veces
	push bc			;5f1d
	call pinta_guion_aqui		;5f1e
	pop bc			;5f21
	djnz carga_los_colores_1a8		;5f22
	ld de,049a8h		;5f24   ; y otras ocho en el segundo tercio, color 0x09A8
	call abre_la_vram_para_escribir_2		;5f27
	ld b,008h		;5f2a
carga_los_colores_9a8:		; Y otras ocho en 0x09A8
	ld hl,062eah		;5f2c
	push bc			;5f2f
	call pinta_guion_aqui		;5f30
	pop bc			;5f33
	djnz carga_los_colores_9a8		;5f34
	call pinta_guion_aqui		;5f36   ; detras del guion de 0x62EA hay otro, y ese va una sola vez
	ld de,042a8h		;5f39   ; color 0x02A8
	ld hl,062f3h		;5f3c
	call pinta_guion_de		;5f3f
	ld de,04af0h		;5f42   ; el mismo guion en el color 0x0AF0
	call pinta_guion_de		;5f45
	ld de,052f0h		;5f48   ; color 0x12F0, ya en el tercer tercio
	ld hl,062feh		;5f4b
	call pinta_guion_de		;5f4e
	ld de,04470h		;5f51   ; el guion de 0x631D en el color 0x0470...
	ld hl,0631dh		;5f54
	push hl			;5f57
	call pinta_guion_de		;5f58
	ld de,04c70h		;5f5b   ; ...y el mismo en el 0x0C70
	pop hl			;5f5e
	call pinta_guion_de		;5f5f
	call pinta_guion_aqui		;5f62
	ld de,03fd0h		;5f65   ; 0x3FD0 mas los 0x800 que suma el bucle da el color 0x07D0
	ld b,003h		;5f68   ; los tres tercios
carga_los_colores_tercios:		; El mismo guion en los tres tercios, de 0x07D0 en 0x07D0
	ld hl,00800h		;5f6a   ; el tercio siguiente
	add hl,de			;5f6d
	ex de,hl			;5f6e
	ld hl,06354h		;5f6f   ; el guion de 0x6354
	push bc			;5f72
	call pinta_guion_de		;5f73
	pop bc			;5f76
	djnz carga_los_colores_tercios		;5f77
	call pinta_guion		;5f79   ; el que viene detras trae su propio destino
	ld de,05f50h		;5f7c   ; 0x5F50 mas 0x800 da la VRAM 0x2750: aqui empieza el marco
	ld b,003h		;5f7f   ; el marco en los tres tercios
carga_el_marco:		; El dibujo del marco en los tres tercios, de 0x2750 en adelante
	ld hl,00800h		;5f81
	add hl,de			;5f84
	ex de,hl			;5f85
	ld hl,06a45h		;5f86   ; el dibujo del marco, en 0x6A45
	push bc			;5f89
	call pinta_guion_de		;5f8a
	pop bc			;5f8d
	djnz carga_el_marco		;5f8e
	ld de,06580h		;5f90   ; VRAM 0x2580
	call abre_la_vram_para_escribir_2		;5f93
	ld bc,00701h		;5f96   ; siete patrones, uno de cada, con su espejo detras
	call pinta_el_tile_y_su_espejo		;5f99
	ld de,06380h		;5f9c   ; VRAM 0x2380
	call abre_la_vram_para_escribir_2		;5f9f
	ld hl,06a71h		;5fa2   ; los patrones de 0x6A71, que se usan dos veces
	push hl			;5fa5
	ld bc,00701h		;5fa6
	call pinta_el_tile_y_su_espejo		;5fa9
	ld de,06400h		;5fac   ; los mismos otra vez, en la VRAM 0x2400
	call abre_la_vram_para_escribir_2		;5faf
	pop hl			;5fb2
	ld bc,00701h		;5fb3
	call pinta_el_tile_y_su_espejo		;5fb6
	ld de,06d80h		;5fb9   ; VRAM 0x2D80, el segundo tercio
	call abre_la_vram_para_escribir_2		;5fbc
	ld bc,00701h		;5fbf
	call pinta_el_tile_y_su_espejo		;5fc2
	ld de,07580h		;5fc5   ; y la 0x3580, el tercero
	call abre_la_vram_para_escribir_2		;5fc8
	ld bc,00801h		;5fcb   ; aqui son ocho patrones
	call pinta_el_tile_y_su_espejo		;5fce
	jp pinta_guion		;5fd1   ; el ultimo guion trae el destino delante
pinta_el_guion_c_veces:		; Pinta el guion de HL C veces seguidas, cada una detras de la anterior, y deja HL detras del guion
	push hl			;5fd4   ; se guarda el principio del guion para poder volver a el
	pop de			;5fd5
pinta_el_guion_c_veces_vuelta:		; Una vuelta
	ex de,hl			;5fd6   ; recupera el principio
	push bc			;5fd7
	push hl			;5fd8
	call pinta_guion_aqui		;5fd9   ; pinta donde quedo el puntero de la VRAM, sin volver a abrirla: por eso las copias salen pegadas
	pop de			;5fdc   ; al volver, HL apunta detras del guion y DE otra vez a su principio
	pop bc			;5fdd
	dec c			;5fde
	jr nz,pinta_el_guion_c_veces_vuelta		;5fdf
	ret			;5fe1
pinta_el_tile_y_su_espejo:		; Pinta C veces el trozo de HL y luego otras C veces ESE MISMO TROZO ESPEJADO de izquierda a derecha: lo descomprime a 0xE060 con 0x601E, le da la vuelta a los bits con 0x5FFD y pinta el resultado, que 0x5FFD deja preparado como un guion en 0xE067. Da B vueltas
	push hl			;5fe2
	push bc			;5fe3
	call pinta_el_guion_c_veces		;5fe4   ; primero el tile tal cual, C veces
	pop bc			;5fe7
	pop hl			;5fe8
	push bc			;5fe9
	call descomprime_en_ram		;5fea   ; el mismo guion, ahora descomprimido a la RAM
	push hl			;5fed
	call espeja_el_tile		;5fee   ; lo espeja de izquierda a derecha y lo deja hecho un guion en 0xE067
	pop de			;5ff1
	pop bc			;5ff2
	push bc			;5ff3
	push de			;5ff4
	call pinta_el_guion_c_veces		;5ff5   ; y pinta C veces el tile espejado: HL viene valiendo 0xE067
	pop hl			;5ff8   ; recupera el puntero de detras del guion original
	pop bc			;5ff9
	djnz pinta_el_tile_y_su_espejo		;5ffa   ; el tile siguiente
	ret			;5ffc
espeja_el_tile:		; Le da la vuelta a los ocho bits de cada una de las ocho filas de 0xE060, sobre 0xE068, y le pone delante el 0x88 y detras el 0x00, o sea que la deja hecha un guion de VRAM. NO traspone: el `inc hl` de 0x600E esta FUERA del bucle de bits, asi que las ocho vueltas de `rl (hl)` machacan siempre el MISMO byte y lo que sale es ese byte con los bits del reves. Medido: el guion de 0x60D6 rinde F0 en su penultima fila y el cartucho deja 0F en la VRAM 0x21C6
	ld hl,0e060h		;5ffd   ; las ocho filas del tile, tal como las acaba de dejar 0x601E
	ld de,0e068h		;6000   ; el resultado va detras, dejando un hueco delante para la cabecera del guion
	ld c,008h		;6003
espeja_el_tile_fila:		; Una columna de la matriz
	xor a			;6005
	ld b,008h		;6006   ; los ocho bits de una fila

; ----------------------------------------------------------------------
; ----- Aqui NO se traspone: el inc hl de 0x600E esta FUERA de este bucle, asi que las ocho vueltas machacan siempre la MISMA fila y lo que sale es esa fila con los bits del reves. El tile queda espejado de izquierda a derecha, no girado -----
; ----------------------------------------------------------------------
espeja_el_tile_bit:		; Un bit
	rl (hl)		;6008   ; saca por arriba el bit de mas peso de la fila
	rra			;600a   ; y lo mete por arriba en A: ocho vueltas y A es la fila leida al reves
	djnz espeja_el_tile_bit		;600b
	ld (de),a			;600d   ; la fila espejada, ya en su sitio
	inc hl			;600e   ; la fila siguiente; el inc esta fuera del bucle de ocho, y ahi esta la clave
	inc de			;600f
	dec c			;6010
	jr nz,espeja_el_tile_fila		;6011
	ld hl,0e070h		;6013   ; el 0x00 del final, detras de las ocho filas
	ld (hl),000h		;6016
	ld hl,0e067h		;6018
	ld (hl),088h		;601b   ; y un 0x88 delante: la orden de copiar ocho bytes tal cual. El guion arranca en 0xE067
	ret			;601d
descomprime_en_ram:		; El mismo formato de rachas de los guiones, pero volcado a 0xE060 en vez de a la VRAM. No entiende ni el 0x01 ni el 0x80: para en el primer byte cuyos seis bits bajos sean cero
	ld de,0e060h		;601e   ; el mismo formato de los guiones de VRAM, pero volcado a la RAM
descomprime_en_ram_orden:		; Lee la orden
	ld a,(hl)			;6021
	inc hl			;6022
	ld c,a			;6023
	and 07fh		;6024   ; se queda con la cuenta y tira el bit 7
	ret z			;6026   ; el 0x00 acaba; aqui el 0x01 y el 0x80 del interprete de VRAM no se entienden
	ld b,a			;6027
	cp c			;6028   ; si el bit 7 estaba puesto es un literal; si no, una racha
	jr nz,descomprime_en_ram_literal		;6029
	ld a,(hl)			;602b   ; el byte que se repite
	inc hl			;602c
descomprime_en_ram_racha:		; La racha
	ld (de),a			;602d   ; el mismo byte B veces
	inc de			;602e
	djnz descomprime_en_ram_racha		;602f
	jr descomprime_en_ram_orden		;6031
descomprime_en_ram_literal:		; Los bytes tal cual
	ld a,(hl)			;6033   ; B bytes tal cual
	ld (de),a			;6034
	inc hl			;6035
	inc de			;6036
	djnz descomprime_en_ram_literal		;6037
	jr descomprime_en_ram_orden		;6039

; ----------------------------------------------------------------------
; DATOS tiles_del_campo_1: Diez patrones sueltos. 0x5E0D los pinta dos veces
;   cada uno, y luego 0x5E17 repite la tanda entera: cuarenta tiles seguidos a
;   partir de la VRAM 0x2008
;   0x603b..0x6091  (86 bytes)
DATA_tiles_del_campo_1:
	defb 004h,0ffh,084h,0fch,0f0h,0c0h,000h,000h,083h,0fch,0f0h,0c0h,005h,000h,000h,083h	; 603b  ................
	defb 0c0h,0f0h,0fch,005h,0ffh,000h,004h,000h,084h,0c0h,0f0h,0fch,0ffh,000h,002h,07fh	; 604b  ................
	defb 002h,03fh,002h,01fh,002h,00fh,000h,002h,007h,002h,003h,002h,001h,002h,000h,000h	; 605b  .?..............
	defb 002h,0feh,002h,0fch,002h,0f8h,002h,0f0h,000h,002h,0e0h,002h,0c0h,002h,080h,002h	; 606b  ................
	defb 000h,000h,088h,0feh,0fch,0f8h,0f0h,0e0h,0c0h,080h,000h,000h,088h,07fh,03fh,01fh	; 607b  ..............?.
	defb 00fh,007h,003h,001h,000h,000h	; 608b

; ----------------------------------------------------------------------
; DATOS tiles_del_campo_2: Un solo guion de 96 bytes -doce patrones- que
;   0x5E20 pinta detras de los anteriores
;   0x6091..0x60d6  (69 bytes)
DATA_tiles_del_campo_2:
	defb 0a0h,003h,00fh,01fh,03fh,07fh,07fh,0ffh,0ffh,0c0h,0f0h,0f8h,0fch,0feh,0feh,0ffh	; 6091  ....?...........
	defb 0ffh,0ffh,0ffh,07fh,07fh,03fh,01fh,00fh,003h,07fh,0ffh,0feh,0feh,0fch,0f8h,0f0h	; 60a1  .....?..........
	defb 0c0h,005h,000h,083h,001h,007h,01fh,005h,000h,083h,080h,0e0h,0f8h,083h,01fh,007h	; 60b1  ................
	defb 001h,005h,000h,083h,0f8h,0e0h,080h,005h,000h,088h,0ffh,0efh,0cfh,0cfh,087h,087h	; 60c1  ................
	defb 003h,0efh,018h,0ffh,000h	; 60d1

; ----------------------------------------------------------------------
; DATOS tiles_girables_1: Cuatro patrones que 0x5E35 y 0x5E45 pintan cuatro
;   veces cada uno y otras cuatro girados, a las VRAM 0x21A8 y 0x29A8
;   0x60d6..0x60ef  (25 bytes)
DATA_tiles_girables_1:
	defb 006h,0ffh,082h,0f0h,000h,000h,004h,0ffh,081h,0f0h,003h,000h,000h,083h,0ffh,0ffh	; 60d6  ................
	defb 0f0h,005h,000h,000h,081h,0f0h,007h,000h,000h	; 60e6  .........

; ----------------------------------------------------------------------
; DATOS tiles_girables_2: Seis guiones que 0x5E51 lleva a las VRAM 0x22A8 y
;   0x2AA8, mezclando los girados con los que no
;   0x60ef..0x613e  (79 bytes)
DATA_tiles_girables_2:
	defb 003h,000h,085h,000h,001h,007h,00fh,01fh,000h,085h,01fh,01fh,00fh,007h,001h,003h	; 60ef  ................
	defb 000h,000h,004h,000h,004h,0ffh,005h,0ffh,003h,000h,004h,000h,004h,001h,007h,001h	; 60ff  ................
	defb 081h,0feh,004h,000h,084h,080h,0c0h,0e0h,0f0h,000h,088h,000h,000h,001h,007h,00fh	; 610f  ................
	defb 01fh,03fh,03fh,000h,088h,03fh,03fh,01fh,01fh,00fh,003h,000h,000h,000h,003h,000h	; 611f  .??..??.........
	defb 005h,001h,007h,001h,081h,0feh,003h,000h,085h,080h,0c0h,0e0h,0f0h,0f8h,000h	; 612f  ...............

; ----------------------------------------------------------------------
; DATOS tiles_girables_3: Diecisiete guiones que 0x5E6F lleva a la VRAM y
;   remata en 0x3328
;   0x613e..0x61cd  (143 bytes)
DATA_tiles_girables_3:
	defb 088h,003h,00fh,01fh,03fh,07fh,07fh,0ffh,0ffh,000h,003h,0ffh,002h,07fh,002h,03fh	; 613e  ....?..........?
	defb 081h,01fh,000h,084h,01fh,00fh,007h,003h,004h,000h,000h,005h,000h,083h,003h,01fh	; 614e  ................
	defb 0ffh,000h,005h,0ffh,083h,03fh,007h,000h,000h,004h,000h,081h,03fh,003h,0ffh,000h	; 615e  .....?......?...
	defb 081h,00fh,007h,000h,000h,083h,0ffh,0ffh,00fh,005h,000h,000h,010h,003h,006h,003h	; 616e  ................
	defb 082h,0fch,0f8h,003h,000h,005h,0ffh,007h,0ffh,081h,07fh,088h,080h,0c0h,0e0h,0f0h	; 617e  ................
	defb 0f8h,0fch,0feh,0ffh,008h,000h,000h,088h,000h,000h,001h,003h,007h,007h,00fh,00fh	; 618e  ................
	defb 000h,088h,00fh,00fh,007h,007h,003h,001h,000h,000h,000h,006h,000h,082h,003h,00fh	; 619e  ................
	defb 000h,081h,03fh,007h,0ffh,000h,007h,0ffh,081h,03fh,000h,082h,00fh,003h,006h,000h	; 61ae  ..?......?......
	defb 000h,004h,000h,081h,03fh,003h,0ffh,000h,003h,0ffh,081h,03fh,004h,000h,000h	; 61be  ....?......?...

; ----------------------------------------------------------------------
; DATOS tiles_girables_4: Siete guiones que 0x5E93 lleva a las VRAM 0x2470 y
;   0x2C70
;   0x61cd..0x621b  (78 bytes)
DATA_tiles_girables_4:
	defb 084h,0ffh,03fh,00fh,003h,004h,000h,000h,003h,000h,085h,003h,00fh,03fh,07fh,0ffh	; 61cd  ..?..........?..
	defb 000h,085h,0ffh,07fh,03fh,00fh,003h,003h,000h,000h,004h,000h,004h,0ffh,004h,0ffh	; 61dd  ....?...........
	defb 004h,000h,003h,000h,005h,0ffh,005h,0ffh,003h,000h,000h,004h,0ffh,084h,0fch,0f8h	; 61ed  ................
	defb 0f0h,0e0h,000h,085h,0e0h,0e0h,0f0h,0f8h,0feh,003h,0ffh,000h,090h,0c3h,081h,081h	; 61fd  ................
	defb 000h,000h,0efh,0e7h,0a5h,0c3h,0e7h,0e7h,0c3h,0c3h,0c3h,0c3h,081h,000h	; 620d  ..............

; ----------------------------------------------------------------------
; DATOS tiles_girables_5: Once guiones que 0x5EB0 lleva a la VRAM 0x34F0, y
;   los dos ultimos -0x627A, de 230 bytes- a 0x2E00 y 0x3600
;   0x621b..0x62cd  (178 bytes)
DATA_tiles_girables_5:
	defb 085h,0feh,0f8h,0f0h,0e0h,0e0h,003h,0c0h,000h,005h,0c0h,083h,0e0h,0e0h,0f0h,000h	; 621b  ................
	defb 083h,0f0h,0f8h,0feh,005h,0ffh,000h,088h,0fch,0f8h,0f0h,0e0h,0c0h,080h,080h,000h	; 622b  ................
	defb 000h,003h,0ffh,003h,0feh,082h,0deh,0eeh,000h,085h,0f6h,0f8h,0fch,0feh,0feh,003h	; 623b  ................
	defb 0fch,000h,081h,0fch,006h,0f8h,081h,0f0h,000h,002h,000h,006h,0ffh,007h,0ffh,081h	; 624b  ................
	defb 000h,000h,088h,0c3h,0b1h,060h,000h,000h,000h,081h,0c3h,018h,000h,088h,0ffh,0ffh	; 625b  .....`..........
	defb 0e7h,0f3h,0c3h,0e7h,0ffh,0ffh,000h,004h,000h,084h,003h,00fh,03fh,0ffh,000h,066h	; 626b  ............?..f
	defb 048h,008h,077h,0a0h,000h,010h,030h,07eh,0feh,07eh,030h,010h,000h,008h,00ch,07eh	; 627b  H.w...0~.~0....~
	defb 07fh,07eh,00ch,008h,000h,010h,038h,07ch,0feh,038h,038h,038h,000h,038h,038h,038h	; 628b  .~....8|.888.888
	defb 0feh,07ch,038h,010h,081h,000h,003h,008h,081h,07fh,003h,008h,003h,000h,081h,07eh	; 629b  .|8............~
	defb 004h,000h,080h,076h,040h,008h,000h,008h,040h,008h,060h,008h,070h,008h,078h,008h	; 62ab  ...v@...@.`.p.x.
	defb 07ch,008h,07eh,008h,07fh,080h,065h,030h,088h,0ffh,0efh,0cfh,0cfh,087h,087h,003h	; 62bb  |.~...e0........
	defb 0efh,000h	; 62cb

; ----------------------------------------------------------------------
; DATOS colores_del_campo_1: Un guion de cinco bytes que rinde 16 bytes;
;   0x5EE8 lo pinta diez veces por vuelta, dos vueltas, en cada uno de los
;   tres tercios de la tabla de colores a partir de 0x0008
;   0x62cd..0x62d2  (5 bytes)
DATA_colores_del_campo_1:
	defb 008h,0c3h,008h,03ch,000h	; 62cd

; ----------------------------------------------------------------------
; DATOS colores_del_campo_2: El gemelo del anterior: la segunda vuelta de las
;   diez
;   0x62d2..0x62d7  (5 bytes)
DATA_colores_del_campo_2:
	defb 008h,0ech,008h,0ceh,000h	; 62d2

; ----------------------------------------------------------------------
; DATOS colores_del_campo_3: Diecinueve bytes que rinden 96: el cierre de cada
;   tercio
;   0x62d7..0x62ea  (19 bytes)
DATA_colores_del_campo_3:
	defb 018h,0c3h,081h,0c1h,007h,0c3h,020h,0a3h,007h,0ech,081h,0e1h,008h,0e0h,008h,0c0h	; 62d7  ...... .........
	defb 008h,030h,000h	; 62e7

; ----------------------------------------------------------------------
; DATOS colores_del_campo_4: Nueve bytes que rinden 32; 0x5F1A y 0x5F2C lo
;   pintan ocho veces en 0x01A8 y otras ocho en 0x09A8
;   0x62ea..0x62f3  (9 bytes)
DATA_colores_del_campo_4:
	defb 008h,0c3h,008h,03ch,008h,0ech,008h,0ceh,000h	; 62ea  ...<.....

; ----------------------------------------------------------------------
; DATOS colores_del_campo_5: Once bytes que rinden 72, para la VRAM 0x02A8
;   0x62f3..0x62fe  (11 bytes)
DATA_colores_del_campo_5:
	defb 030h,0c3h,00ch,0f3h,003h,0fch,081h,0c1h,008h,0b3h,000h	; 62f3  0..........

; ----------------------------------------------------------------------
; DATOS colores_del_campo_6: Treinta y un bytes que rinden 368, para las VRAM
;   0x0AF0 y 0x12F0
;   0x62fe..0x631d  (31 bytes)
DATA_colores_del_campo_6:
	defb 020h,0c3h,00ah,0f3h,005h,0fch,081h,0c1h,008h,0b3h,07fh,0c3h,081h,0c3h,00bh,0f3h	; 62fe   ...............
	defb 00bh,0fch,002h,0c1h,008h,0c3h,008h,0c1h,010h,0b3h,07fh,0a3h,081h,0a3h,000h	; 630e  ...............

; ----------------------------------------------------------------------
; DATOS colores_del_campo_7: Nueve bytes que rinden 128, para las VRAM 0x0470
;   y 0x0C70
;   0x631d..0x6326  (9 bytes)
DATA_colores_del_campo_7:
	defb 050h,0a3h,025h,0ech,008h,0c6h,003h,0e6h,000h	; 631d  P.%......

; ----------------------------------------------------------------------
; DATOS colores_del_campo_8: Cuarenta y seis bytes que rinden 368, pintados
;   detras de los anteriores
;   0x6326..0x6354  (46 bytes)
DATA_colores_del_campo_8:
	defb 040h,0ech,020h,0c6h,003h,0c6h,005h,0e6h,003h,0c6h,005h,0e6h,010h,0c3h,080h,04eh	; 6326  @. ............N
	defb 000h,028h,0c1h,010h,0a3h,080h,054h,0f0h,040h,0ech,020h,0c6h,003h,0c6h,005h,0e6h	; 6336  .(....T.@. .....
	defb 003h,0c6h,005h,0e6h,010h,0c3h,080h,056h,000h,028h,0c1h,010h,0a3h,000h	; 6346  .......V.(....

; ----------------------------------------------------------------------
; DATOS colores_del_campo_9: Siete bytes que rinden 40; 0x5F6A los pinta en
;   los tres tercios de la tabla de colores, en 0x07D0, 0x0FD0 y 0x17D0
;   0x6354..0x635b  (7 bytes)
DATA_colores_del_campo_9:
	defb 008h,0aah,008h,077h,020h,073h,000h	; 6354

; ----------------------------------------------------------------------
; DATOS colores_del_campo_10: El ultimo guion de 0x5E03, con cabecera propia:
;   cuatro tramos de color en 0x0648, 0x1640, 0x0380 y 0x0530
;   0x635b..0x6379  (30 bytes)
DATA_colores_del_campo_10:
	defb 046h,048h,008h,077h,030h,0f0h,080h,056h,040h,040h,0a1h,080h,043h,080h,070h,067h	; 635b  FH.w0..V@@..C.pg
	defb 008h,066h,008h,099h,070h,097h,080h,045h,030h,007h,072h,081h,071h,000h	; 636b  .f..p..E0.r.q.

; ----------------------------------------------------------------------
; DATOS hoyo_1_cabecera: Guion de VRAM del hoyo 1, el unico largo: pinta el
;   panel de la derecha entero -HOLE, PAR, la longitud con su M de metros,
;   WIND y SHOT, de 0x3816 a 0x3899-. Los otros ocho solo cambian el numero
;   del hoyo
;   0x6379..0x63a4  (43 bytes)
DATA_hoyo_1_cabecera:
	defb 078h,016h,084h,0e0h,0d3h,0d9h,0dch,01ch,000h,083h,0d8h,0dah,0ddh,004h,000h,081h	; 6379  x...............
	defb 0f4h,01dh,000h,084h,0f4h,0f7h,0f5h,0e1h,017h,000h,084h,0e3h,0d5h,0e6h,0d1h,004h	; 6389  ................
	defb 000h,081h,0e1h,017h,000h,084h,0deh,0e0h,0d3h,0d4h,080h	; 6399  ...........

; ----------------------------------------------------------------------
; DATOS hoyo_1_rejilla: Las dieciseis filas del hoyo 1: nueve casillas por
;   fila a partir de la VRAM 0x38F6, y detras 23 ceros para completar la fila
;   de nombres. 0x53B2 las relee como codigos de terreno para el buffer de
;   0xE200
;   0x63a4..0x6465  (193 bytes)
DATA_hoyo_1_rejilla:
	defb 078h,0f6h,089h,031h,015h,017h,033h,01ah,01ch,031h,031h,031h,017h,000h,089h,025h	; 63a4  x..1..3..111...%
	defb 001h,003h,034h,006h,008h,027h,031h,031h,017h,000h,089h,033h,034h,034h,029h,02ah	; 63b4  ..4..'11...344)*
	defb 034h,013h,027h,031h,017h,000h,089h,028h,014h,034h,02bh,02ch,02dh,02eh,009h,01dh	; 63c4  4.'1...(.4+,-...
	defb 017h,000h,089h,031h,028h,014h,034h,034h,02fh,030h,00bh,01fh,017h,000h,089h,031h	; 63d4  ...1(.44/0.....1
	defb 031h,028h,014h,034h,034h,034h,034h,033h,017h,000h,089h,031h,031h,031h,01eh,00ah	; 63e4  1(.44443...111..
	defb 034h,034h,034h,033h,017h,000h,089h,031h,031h,031h,020h,00ch,02dh,02eh,034h,033h	; 63f4  4443...111 .-.43
	defb 017h,000h,089h,031h,031h,031h,031h,033h,02fh,030h,034h,033h,017h,000h,089h,031h	; 6404  ...11113/043...1
	defb 031h,031h,021h,00dh,034h,034h,034h,033h,017h,000h,089h,031h,031h,031h,023h,00fh	; 6414  11!.4443...111#.
	defb 034h,034h,034h,033h,017h,000h,089h,031h,031h,025h,011h,034h,034h,034h,00eh,033h	; 6424  4443...11%.444.3
	defb 017h,000h,089h,015h,017h,00dh,034h,034h,034h,034h,010h,033h,017h,000h,089h,033h	; 6434  ......4444.3...3
	defb 033h,00fh,034h,034h,034h,034h,033h,033h,017h,000h,089h,033h,00dh,034h,034h,034h	; 6444  3.444433...3.444
	defb 034h,034h,009h,033h,017h,000h,089h,033h,00fh,00eh,0c4h,0eah,0c4h,00ah,00bh,033h	; 6454  44.3...3.......3
	defb 000h	; 6464

; ----------------------------------------------------------------------
; DATOS hoyo_2_cabecera: Guion de VRAM: el numero del hoyo en 0x383D y tres
;   tiles en 0x385B
;   0x6465..0x6471  (12 bytes)
DATA_hoyo_2_cabecera:
	defb 078h,03dh,081h,0f4h,080h,078h,05bh,083h,0f3h,0f6h,0f0h,080h	; 6465  x=...x[.....

; ----------------------------------------------------------------------
; DATOS hoyo_2_rejilla: Las dieciseis filas del hoyo 2
;   0x6471..0x6512  (161 bytes)
DATA_hoyo_2_rejilla:
	defb 078h,0f6h,089h,031h,015h,017h,033h,033h,027h,031h,032h,031h,017h,000h,089h,025h	; 6471  x..1..33'121...%
	defb 001h,003h,034h,034h,013h,01ah,01ch,031h,017h,000h,089h,033h,034h,029h,02ah,034h	; 6481  ..44...1...34)*4
	defb 034h,006h,008h,027h,017h,000h,089h,028h,014h,02bh,02ch,02dh,02eh,034h,034h,033h	; 6491  4..'...(.+,-.443
	defb 017h,000h,089h,031h,028h,005h,007h,02fh,030h,034h,034h,033h,017h,000h,089h,032h	; 64a1  ...1(../0443...2
	defb 032h,019h,01bh,014h,034h,034h,012h,026h,017h,000h,089h,031h,031h,031h,031h,028h	; 64b1  2...44.&...1111(
	defb 033h,033h,026h,031h,017h,000h,009h,031h,017h,000h,009h,031h,017h,000h,009h,031h	; 64c1  33&1...1...1...1
	defb 017h,000h,089h,015h,017h,033h,033h,033h,033h,033h,033h,027h,017h,000h,089h,033h	; 64d1  .....333333'...3
	defb 011h,034h,034h,034h,034h,034h,012h,026h,017h,000h,089h,033h,00eh,0c4h,0eah,0c4h	; 64e1  .44444.&...3....
	defb 00ah,012h,026h,031h,017h,000h,089h,033h,014h,034h,034h,034h,012h,026h,031h,031h	; 64f1  ..&1...3.444.&11
	defb 017h,000h,089h,019h,01bh,033h,033h,033h,026h,031h,031h,031h,017h,000h,009h,031h	; 6501  .....333&111...1
	defb 000h	; 6511

; ----------------------------------------------------------------------
; DATOS hoyo_3_cabecera: Guion de VRAM: el numero del hoyo en 0x383D y tres
;   tiles en 0x385B
;   0x6512..0x651e  (12 bytes)
DATA_hoyo_3_cabecera:
	defb 078h,03dh,081h,0f4h,080h,078h,05bh,083h,0f3h,0f6h,0f2h,080h	; 6512  x=...x[.....

; ----------------------------------------------------------------------
; DATOS hoyo_3_rejilla: Las dieciseis filas del hoyo 3
;   0x651e..0x65d7  (185 bytes)
DATA_hoyo_3_rejilla:
	defb 078h,0f6h,089h,031h,031h,015h,017h,033h,01ah,01ch,031h,031h,017h,000h,089h,031h	; 651e  x..11..3..11...1
	defb 025h,033h,033h,033h,033h,033h,027h,031h,017h,000h,089h,025h,011h,02dh,02eh,034h	; 652e  %33333'1...%.-.4
	defb 029h,02ah,013h,027h,017h,000h,089h,033h,034h,02fh,030h,034h,02bh,02ch,034h,033h	; 653e  )*.'...34/04+,43
	defb 017h,000h,089h,033h,034h,034h,012h,033h,033h,033h,033h,026h,017h,000h,089h,033h	; 654e  ...344.3333&...3
	defb 034h,034h,033h,031h,031h,032h,031h,031h,017h,000h,089h,033h,034h,034h,013h,027h	; 655e  44311211...344.'
	defb 031h,031h,031h,032h,017h,000h,089h,033h,034h,034h,034h,013h,027h,031h,031h,032h	; 656e  1112...3444.'112
	defb 017h,000h,089h,033h,034h,034h,034h,034h,013h,027h,031h,032h,017h,000h,089h,033h	; 657e  ...34444.'12...3
	defb 034h,034h,034h,034h,034h,033h,031h,032h,017h,000h,089h,033h,034h,034h,034h,034h	; 658e  44444312...34444
	defb 034h,033h,031h,032h,017h,000h,089h,033h,034h,034h,034h,034h,034h,033h,031h,032h	; 659e  4312...344444312
	defb 017h,000h,089h,033h,00eh,0c4h,0eah,0c4h,00ah,033h,031h,032h,017h,000h,089h,033h	; 65ae  ...3.....312...3
	defb 014h,034h,034h,034h,012h,033h,031h,032h,017h,000h,089h,028h,033h,033h,033h,033h	; 65be  .444.312...(3333
	defb 033h,026h,031h,032h,017h,000h,009h,031h,000h	; 65ce  3&12...1.

; ----------------------------------------------------------------------
; DATOS hoyo_4_cabecera: Guion de VRAM: el numero del hoyo en 0x383D y tres
;   tiles en 0x385B
;   0x65d7..0x65e3  (12 bytes)
DATA_hoyo_4_cabecera:
	defb 078h,03dh,081h,0f5h,080h,078h,05bh,083h,0f4h,0f7h,0f5h,080h	; 65d7  x=...x[.....

; ----------------------------------------------------------------------
; DATOS hoyo_4_rejilla: Las dieciseis filas del hoyo 4
;   0x65e3..0x669c  (185 bytes)
DATA_hoyo_4_rejilla:
	defb 078h,0f6h,089h,031h,031h,025h,033h,033h,01ah,01ch,031h,031h,017h,000h,089h,031h	; 65e3  x..11%33..11...1
	defb 025h,011h,034h,034h,006h,008h,027h,031h,017h,000h,089h,031h,01eh,00ah,02dh,02eh	; 65f3  %.44..'1...1..-.
	defb 029h,02ah,009h,01dh,017h,000h,089h,031h,020h,00ch,02fh,030h,02bh,02ch,00bh,01fh	; 6603  )*.....1 ./0+,..
	defb 017h,000h,089h,031h,031h,028h,033h,014h,034h,034h,034h,033h,017h,000h,089h,031h	; 6613  ...11(3.4443...1
	defb 031h,031h,031h,028h,033h,033h,033h,026h,017h,000h,009h,031h,017h,000h,089h,025h	; 6623  111(333&...1...%
	defb 033h,033h,027h,031h,031h,031h,031h,031h,017h,000h,089h,033h,00fh,034h,033h,031h	; 6633  33'11111...3.431
	defb 031h,031h,031h,031h,017h,000h,089h,028h,033h,033h,026h,031h,031h,031h,031h,031h	; 6643  1111...(33&11111
	defb 017h,000h,089h,031h,031h,031h,025h,033h,033h,027h,031h,031h,017h,000h,089h,031h	; 6653  ...111%33'11...1
	defb 031h,025h,011h,034h,034h,013h,027h,031h,017h,000h,089h,031h,021h,00dh,034h,034h	; 6663  1%.44.'1...1!.44
	defb 034h,034h,009h,01dh,017h,000h,089h,031h,023h,00fh,034h,034h,034h,034h,00bh,01fh	; 6673  44.....1#.4444..
	defb 017h,000h,089h,021h,00dh,034h,034h,034h,034h,034h,034h,033h,017h,000h,089h,023h	; 6683  ...!.4444443...#
	defb 00fh,00eh,0c4h,0eah,0c4h,00ah,034h,033h,000h	; 6693  ......43.

; ----------------------------------------------------------------------
; DATOS hoyo_5_cabecera: Guion de VRAM: el numero del hoyo en 0x383D y tres
;   tiles en 0x385B
;   0x669c..0x66a8  (12 bytes)
DATA_hoyo_5_cabecera:
	defb 078h,03dh,081h,0f3h,080h,078h,05bh,083h,0f1h,0f6h,0f8h,080h	; 669c  x=...x[.....

; ----------------------------------------------------------------------
; DATOS hoyo_5_rejilla: Las dieciseis filas del hoyo 5
;   0x66a8..0x6739  (145 bytes)
DATA_hoyo_5_rejilla:
	defb 078h,0f6h,089h,031h,031h,015h,017h,033h,033h,033h,027h,031h,017h,000h,089h,031h	; 66a8  x..11..333'1...1
	defb 025h,001h,003h,034h,02dh,02eh,009h,01dh,017h,000h,089h,031h,033h,034h,029h,02ah	; 66b8  %..4-......134)*
	defb 02fh,030h,00bh,01fh,017h,000h,089h,031h,01eh,00ah,02bh,02ch,02dh,02eh,034h,033h	; 66c8  /0.....1..+,-.43
	defb 017h,000h,089h,031h,020h,00ch,02dh,02eh,02fh,030h,034h,033h,017h,000h,089h,031h	; 66d8  ...1 .-./043...1
	defb 031h,033h,02fh,030h,034h,034h,034h,033h,017h,000h,089h,031h,031h,033h,034h,034h	; 66e8  13/04443...11344
	defb 034h,034h,034h,033h,017h,000h,089h,031h,021h,00dh,00eh,0c4h,0eah,0c4h,00ah,033h	; 66f8  4443...1!......3
	defb 017h,000h,089h,031h,023h,00fh,034h,034h,034h,034h,034h,033h,017h,000h,089h,031h	; 6708  ...1#.444443...1
	defb 033h,033h,033h,033h,033h,033h,033h,026h,017h,000h,009h,031h,017h,000h,009h,032h	; 6718  3333333&...1...2
	defb 017h,000h,009h,032h,017h,000h,009h,032h,017h,000h,009h,032h,017h,000h,009h,032h	; 6728  ...2...2...2...2
	defb 000h	; 6738

; ----------------------------------------------------------------------
; DATOS hoyo_6_cabecera: Guion de VRAM: el numero del hoyo en 0x383D y tres
;   tiles en 0x385B
;   0x6739..0x6745  (12 bytes)
DATA_hoyo_6_cabecera:
	defb 078h,03dh,081h,0f4h,080h,078h,05bh,083h,0f4h,0f7h,0f7h,080h	; 6739  x=...x[.....

; ----------------------------------------------------------------------
; DATOS hoyo_6_rejilla: Las dieciseis filas del hoyo 6
;   0x6745..0x6806  (193 bytes)
DATA_hoyo_6_rejilla:
	defb 078h,0f6h,089h,031h,025h,033h,01ah,01ch,031h,031h,032h,031h,017h,000h,089h,025h	; 6745  x..1%3..1121...%
	defb 011h,034h,006h,008h,027h,031h,031h,031h,017h,000h,089h,033h,029h,02ah,034h,034h	; 6755  .4..'111...3)*44
	defb 033h,031h,031h,031h,017h,000h,089h,033h,02bh,02ch,02dh,02eh,033h,031h,032h,031h	; 6765  3111...3+,-.3121
	defb 017h,000h,089h,033h,02dh,02eh,02fh,030h,033h,031h,032h,031h,017h,000h,089h,033h	; 6775  ...3-./03121...3
	defb 02fh,030h,034h,034h,033h,031h,031h,031h,017h,000h,089h,028h,014h,034h,02dh,02eh	; 6785  /0443111...(.4-.
	defb 033h,031h,031h,031h,017h,000h,089h,031h,028h,014h,02fh,030h,013h,027h,031h,031h	; 6795  3111...1(./0.'11
	defb 017h,000h,089h,031h,031h,028h,014h,02dh,02eh,033h,031h,031h,017h,000h,089h,031h	; 67a5  ...11(.-.311...1
	defb 031h,031h,033h,02fh,030h,033h,031h,032h,017h,000h,089h,031h,032h,031h,033h,034h	; 67b5  113/0312...12134
	defb 034h,013h,027h,031h,017h,000h,089h,031h,031h,031h,033h,034h,034h,034h,033h,031h	; 67c5  4.'1...111344431
	defb 017h,000h,089h,032h,031h,021h,00dh,034h,034h,034h,033h,031h,017h,000h,089h,031h	; 67d5  ...21!.44431...1
	defb 031h,023h,00fh,034h,034h,034h,033h,031h,017h,000h,089h,031h,025h,011h,034h,034h	; 67e5  1#.44431...1%.44
	defb 034h,034h,033h,031h,017h,000h,089h,031h,033h,00eh,0c4h,0eah,0c4h,00ah,033h,031h	; 67f5  4431...13.....31
	defb 000h	; 6805

; ----------------------------------------------------------------------
; DATOS hoyo_7_cabecera: Guion de VRAM: el numero del hoyo en 0x383D y tres
;   tiles en 0x385B
;   0x6806..0x6812  (12 bytes)
DATA_hoyo_7_cabecera:
	defb 078h,03dh,081h,0f4h,080h,078h,05bh,083h,0f4h,0f7h,0f2h,080h	; 6806  x=...x[.....

; ----------------------------------------------------------------------
; DATOS hoyo_7_rejilla: Las dieciseis filas del hoyo 7
;   0x6812..0x68d3  (193 bytes)
DATA_hoyo_7_rejilla:
	defb 078h,0f6h,089h,031h,025h,033h,033h,033h,033h,01ah,01ch,031h,017h,000h,089h,025h	; 6812  x..1%3333..1...%
	defb 033h,033h,033h,033h,033h,033h,033h,01dh,017h,000h,089h,033h,011h,034h,034h,029h	; 6822  3333333....3.44)
	defb 02ah,034h,013h,01fh,017h,000h,089h,033h,034h,02dh,02eh,02bh,02ch,034h,034h,033h	; 6832  *4.....34-.+,443
	defb 017h,000h,089h,028h,014h,02fh,030h,02dh,02eh,034h,00eh,022h,017h,000h,089h,031h	; 6842  ...(./0-.4."...1
	defb 028h,014h,034h,02fh,030h,034h,010h,024h,017h,000h,089h,031h,031h,01eh,00ah,034h	; 6852  (.4/04.$...11..4
	defb 034h,00eh,022h,031h,017h,000h,089h,031h,031h,020h,00ch,02dh,02eh,010h,024h,031h	; 6862  4."1...11 .-..$1
	defb 017h,000h,089h,031h,031h,031h,033h,02fh,030h,033h,031h,031h,017h,000h,089h,031h	; 6872  ...1113/0311...1
	defb 031h,031h,033h,034h,034h,033h,031h,031h,017h,000h,089h,031h,031h,021h,00dh,034h	; 6882  11344311...11!.4
	defb 034h,009h,01dh,031h,017h,000h,089h,031h,031h,023h,00fh,034h,034h,00bh,01fh,031h	; 6892  4..1...11#.44..1
	defb 017h,000h,089h,031h,021h,00dh,034h,034h,034h,034h,009h,01dh,017h,000h,089h,031h	; 68a2  ...1!.4444.....1
	defb 023h,00fh,034h,034h,034h,034h,00bh,01fh,017h,000h,089h,021h,00dh,034h,034h,034h	; 68b2  #.4444.....!.444
	defb 034h,034h,034h,033h,017h,000h,089h,023h,00fh,00eh,0c4h,0eah,0c4h,00ah,034h,033h	; 68c2  4443...#......43
	defb 000h	; 68d2

; ----------------------------------------------------------------------
; DATOS hoyo_8_cabecera: Guion de VRAM: el numero del hoyo en 0x383D y tres
;   tiles en 0x385B
;   0x68d3..0x68df  (12 bytes)
DATA_hoyo_8_cabecera:
	defb 078h,03dh,081h,0f4h,080h,078h,05bh,083h,0f2h,0f4h,0f4h,080h	; 68d3  x=...x[.....

; ----------------------------------------------------------------------
; DATOS hoyo_8_rejilla: Las dieciseis filas del hoyo 8
;   0x68df..0x6988  (169 bytes)
DATA_hoyo_8_rejilla:
	defb 078h,0f6h,089h,031h,015h,017h,033h,033h,033h,033h,027h,031h,017h,000h,089h,025h	; 68df  x..1..3333'1...%
	defb 001h,003h,034h,034h,02dh,02eh,013h,027h,017h,000h,089h,033h,02dh,02eh,029h,02ah	; 68ef  ..44-..'...3-.)*
	defb 02fh,030h,034h,033h,017h,000h,089h,033h,02fh,030h,02bh,02ch,034h,034h,034h,033h	; 68ff  /043...3/0+,4443
	defb 017h,000h,089h,01eh,00ah,034h,02dh,02eh,034h,034h,00eh,022h,017h,000h,089h,020h	; 690f  .....4-.44."... 
	defb 00ch,034h,02fh,030h,034h,034h,010h,024h,017h,000h,089h,031h,033h,034h,034h,034h	; 691f  .4/044.$...13444
	defb 034h,034h,033h,031h,017h,000h,089h,021h,00dh,034h,034h,034h,034h,034h,033h,031h	; 692f  4431...!.4444431
	defb 017h,000h,089h,023h,00fh,034h,034h,034h,034h,00eh,022h,031h,017h,000h,089h,033h	; 693f  ...#.4444."1...3
	defb 00eh,0c4h,0eah,0c4h,00ah,010h,024h,031h,017h,000h,089h,033h,034h,034h,034h,034h	; 694f  ......$1...34444
	defb 012h,026h,031h,031h,017h,000h,089h,033h,034h,034h,002h,004h,026h,031h,031h,031h	; 695f  .&11...344..&111
	defb 017h,000h,089h,028h,033h,033h,016h,018h,031h,031h,031h,032h,017h,000h,009h,031h	; 696f  ...(33..1112...1
	defb 017h,000h,009h,032h,017h,000h,009h,032h,000h	; 697f  ...2...2.

; ----------------------------------------------------------------------
; DATOS hoyo_9_cabecera: Guion de VRAM: el numero del hoyo en 0x383D y tres
;   tiles en 0x385B
;   0x6988..0x6994  (12 bytes)
DATA_hoyo_9_cabecera:
	defb 078h,03dh,081h,0f4h,080h,078h,05bh,083h,0f4h,0f7h,0f9h,080h	; 6988  x=...x[.....

; ----------------------------------------------------------------------
; DATOS hoyo_9_rejilla: Las dieciseis filas del hoyo 9
;   0x6994..0x6a45  (177 bytes)
DATA_hoyo_9_rejilla:
	defb 078h,0f6h,089h,031h,025h,033h,033h,033h,027h,031h,032h,031h,017h,000h,089h,025h	; 6994  x..1%333'121...%
	defb 011h,034h,02dh,02eh,013h,027h,031h,032h,017h,000h,089h,033h,029h,02ah,02fh,030h	; 69a4  .4-..'12...3)*/0
	defb 034h,033h,031h,031h,017h,000h,089h,033h,02bh,02ch,02dh,02eh,034h,033h,032h,031h	; 69b4  4311...3+,-.4321
	defb 017h,000h,089h,033h,02dh,02eh,02fh,030h,012h,026h,031h,031h,017h,000h,089h,033h	; 69c4  ...3-./0.&11...3
	defb 02fh,030h,034h,012h,026h,031h,031h,031h,017h,000h,089h,028h,033h,033h,033h,026h	; 69d4  /04.&111...(333&
	defb 031h,031h,032h,031h,017h,000h,089h,031h,031h,031h,031h,015h,017h,033h,033h,027h	; 69e4  1121...1111..33'
	defb 017h,000h,089h,031h,032h,031h,025h,001h,003h,034h,034h,033h,017h,000h,089h,031h	; 69f4  ...121%..443...1
	defb 031h,031h,033h,002h,004h,033h,033h,026h,017h,000h,089h,031h,031h,032h,028h,016h	; 6a04  113..33&...112(.
	defb 018h,031h,031h,031h,017h,000h,009h,031h,017h,000h,009h,031h,017h,000h,089h,031h	; 6a14  .111...1...1...1
	defb 025h,033h,033h,033h,027h,031h,031h,032h,017h,000h,089h,025h,011h,034h,034h,034h	; 6a24  %333'112...%.444
	defb 013h,027h,031h,031h,017h,000h,089h,033h,00eh,0c4h,0eah,0c4h,00ah,033h,031h,031h	; 6a34  .'11...3.....311
	defb 000h	; 6a44

; ----------------------------------------------------------------------
; DATOS tiles_del_marco: Un guion de 44 bytes que rinde 48; 0x5F81 lo pinta en
;   0x2750, 0x2F50 y 0x3750, o sea el mismo dibujo en los tres tercios
;   0x6a45..0x6a71  (44 bytes)
DATA_tiles_del_marco:
	defb 008h,000h,0a8h,008h,010h,020h,040h,020h,010h,008h,000h,010h,008h,004h,002h,004h	; 6a45  ..... @ ........
	defb 008h,010h,000h,000h,000h,010h,028h,044h,082h,000h,000h,000h,000h,041h,022h,014h	; 6a55  ......(D.....A".
	defb 008h,000h,000h,0ffh,0ffh,0e7h,0c3h,0c3h,0f7h,0ffh,0ffh,000h	; 6a65  ............

; ----------------------------------------------------------------------
; DATOS tiles_girables_6: Veintitres guiones de ocho bytes que 0x5F96, 0x5FA6,
;   0x5FB3, 0x5FBF y 0x5FCB reparten -tal cual y girados- por las VRAM 0x2580,
;   0x2380, 0x2400, 0x2D80 y 0x3580
;   0x6a71..0x6b17  (166 bytes)
DATA_tiles_girables_6:
	defb 004h,000h,084h,001h,00fh,03fh,0ffh,000h,084h,000h,001h,00fh,07fh,004h,0ffh,000h	; 6a71  .....?..........
	defb 081h,00fh,007h,0ffh,000h,006h,000h,082h,001h,007h,000h,085h,001h,007h,00fh,03fh	; 6a81  ...............?
	defb 07fh,003h,0ffh,000h,005h,000h,083h,001h,003h,003h,000h,084h,00fh,01fh,03fh,07fh	; 6a91  ..............?.
	defb 004h,0ffh,000h,088h,007h,00fh,01fh,01fh,03fh,07fh,07fh,0ffh,000h,088h,000h,001h	; 6aa1  ........?.......
	defb 001h,003h,003h,007h,007h,00fh,000h,081h,00fh,003h,01fh,004h,03fh,000h,004h,07fh	; 6ab1  ............?...
	defb 004h,0ffh,000h,004h,0ffh,004h,07fh,000h,004h,03fh,003h,01fh,081h,00fh,000h,088h	; 6ac1  .........?......
	defb 00fh,007h,007h,003h,003h,001h,001h,000h,000h,084h,0ffh,03fh,00fh,001h,004h,000h	; 6ad1  ...........?....
	defb 000h,004h,0ffh,084h,07fh,00fh,001h,000h,000h,007h,0ffh,081h,00fh,000h,082h,007h	; 6ae1  ................
	defb 001h,006h,000h,000h,003h,0ffh,085h,07fh,03fh,00fh,007h,001h,000h,083h,003h,003h	; 6af1  ........?.......
	defb 001h,005h,000h,000h,004h,0ffh,084h,07fh,03fh,01fh,00fh,000h,088h,0ffh,07fh,07fh	; 6b01  ........?.......
	defb 03fh,01fh,01fh,00fh,007h,000h	; 6b11

; ----------------------------------------------------------------------
; DATOS tiles_del_marcador: Treinta y ocho bytes que rinden 567: el ultimo
;   guion de 0x5E03, con cabecera propia
;   0x6b17..0x6b3d  (38 bytes)
DATA_tiles_del_marcador:
	defb 047h,050h,028h,0fch,008h,0c1h,080h,045h,080h,070h,0c3h,080h,04fh,050h,028h,0fch	; 6b17  GP(....E.p..OP(.
	defb 008h,0c1h,080h,04dh,080h,070h,0c3h,080h,057h,050h,028h,0fch,008h,0c1h,080h,055h	; 6b27  ...M.p..WP(....U
	defb 080h,07fh,0c3h,081h,0c3h,000h	; 6b37

; ----------------------------------------------------------------------
; DATOS guion_pantalla_de_tarjeta: Guion de VRAM: llena 22 filas de 20 tiles,
;   de la 0x3821 a la 0x3AD4, o sea la pantalla entera menos el marco. Va en
;   linea tras el call de 0x5906
;   0x6b3d..0x6c2f  (242 bytes)
DATA_guion_pantalla_de_tarjeta:
	defb 078h,021h,014h,034h,080h,078h,041h,014h,034h,080h,078h,061h,014h,034h,080h,078h	; 6b3d  x!.4.xA.4.xa.4.x
	defb 081h,014h,034h,080h,078h,0a1h,006h,034h,087h,0b0h,0b2h,0b4h,033h,0b5h,0b3h,0b1h	; 6b4d  ..4.x..4....3...
	defb 007h,034h,080h,078h,0c1h,004h,034h,082h,0b6h,0b8h,007h,033h,082h,0b9h,0b7h,005h	; 6b5d  .4.x..4....3....
	defb 034h,080h,078h,0e1h,003h,034h,082h,0bah,0bch,009h,033h,082h,0bdh,0bbh,004h,034h	; 6b6d  4.x..4....3....4
	defb 080h,079h,001h,003h,034h,081h,0b0h,00bh,033h,081h,0b1h,004h,034h,080h,079h,021h	; 6b7d  .y..4...3...4.y!
	defb 083h,034h,034h,0b2h,00dh,033h,081h,0b3h,003h,034h,080h,079h,041h,083h,034h,034h	; 6b8d  .44..3...4.yA.44
	defb 0b4h,00dh,033h,081h,0b5h,003h,034h,080h,079h,061h,083h,034h,034h,0b6h,00dh,033h	; 6b9d  ..3...4.ya.44..3
	defb 081h,0b7h,003h,034h,080h,079h,081h,002h,034h,007h,033h,081h,0efh,007h,033h,003h	; 6bad  ...4.y..4.3...3.
	defb 034h,080h,079h,0a1h,083h,034h,034h,0b8h,00dh,033h,081h,0b9h,003h,034h,080h,079h	; 6bbd  4.y..44..3...4.y
	defb 0c1h,083h,034h,034h,0bah,00dh,033h,081h,0bbh,003h,034h,080h,079h,0e1h,083h,034h	; 6bcd  ..44..3...4.y..4
	defb 034h,0bch,00dh,033h,081h,0bdh,003h,034h,080h,07ah,001h,003h,034h,081h,0beh,00bh	; 6bdd  4..3...4.z..4...
	defb 033h,081h,0bfh,004h,034h,080h,07ah,021h,003h,034h,082h,0bah,0bch,009h,033h,082h	; 6bed  3...4.z!.4....3.
	defb 0bdh,0bbh,004h,034h,080h,07ah,041h,004h,034h,082h,0b6h,0b8h,007h,033h,082h,0b9h	; 6bfd  ...4.zA.4....3..
	defb 0b7h,005h,034h,080h,07ah,061h,006h,034h,087h,0b0h,0b2h,0b4h,033h,0b5h,0b3h,0b1h	; 6c0d  ..4.za.4....3...
	defb 007h,034h,080h,07ah,081h,014h,034h,080h,07ah,0a1h,014h,034h,080h,07ah,0c1h,014h	; 6c1d  .4.z..4.z..4.z..
	defb 034h,000h	; 6c2d

; ======================================================================
; CODIGO 0x6c2f..0x6e70  (577 bytes)
; ======================================================================


mueve_la_bola:		; Un paso de la bola, uno de cada cuatro cuadros. Aqui es donde pega el viento: 0xE03C cuenta atras desde 10 o 20 -segun el palo- MENOS la fuerza del viento (0xE104), y cada vez que llega a cero enciende 0xE03D, que es el empujon
	ld a,(0e039h)		;6c2f   ; solo con el golpe en marcha
	or a			;6c32
	ret z			;6c33
	ld a,(0e122h)		;6c34
	rrca			;6c37   ; el bit 0 de 0xE122: la bola esta volando
	ret nc			;6c38
	ld a,(0e000h)		;6c39   ; un paso de cada cuatro cuadros
	and 003h		;6c3c
	ret nz			;6c3e
	ld a,(0e104h)		;6c3f   ; sin viento no hay reloj que bajar
	ld c,a			;6c42
	or a			;6c43
	jr z,mueve_la_bola_apaga_el_swing		;6c44
	ld a,(0e03ch)		;6c46   ; el reloj del viento, si todavia esta corriendo
	or a			;6c49
	jr nz,mueve_la_bola_empuja		;6c4a
	ld b,00ah		;6c4c   ; diez cuadros entre empujon y empujon...
	ld a,(0e121h)		;6c4e   ; el palo elegido, de 0 a 12
	cp 002h		;6c51   ; ...pero veinte con los dos maderas, que son los golpes largos
	jr nc,mueve_la_bola_reloj_del_viento		;6c53
	ld b,014h		;6c55
mueve_la_bola_reloj_del_viento:		; Recarga la cuenta del viento
	ld a,b			;6c57
	sub c			;6c58   ; cuanta mas fuerza tenga el viento, menos cuadros de espera
mueve_la_bola_empuja:		; Al llegar a cero, marca el empujon en 0xE03D
	dec a			;6c59
	ld (0e03ch),a		;6c5a
	jr nz,mueve_la_bola_apaga_el_swing		;6c5d
	inc a			;6c5f
	ld (0e03dh),a		;6c60   ; al llegar a cero enciende 0xE03D: el cuadro que viene lleva empujon
mueve_la_bola_apaga_el_swing:		; Con el monigote en su ultimo cuadro, apaga el bit 5 de 0xE122
	ld a,(0e161h)		;6c63   ; el cuadro en que va el monigote
	cp 0f8h		;6c66   ; 0xF8 es el ultimo del swing
	jr nz,arranca_el_vuelo		;6c68
	ld hl,0e122h		;6c6a
	res 5,(hl)		;6c6d   ; ya no hace falta seguir animandolo
arranca_el_vuelo:		; La primera vez del golpe: saca de 0x72A6 hacia donde tira el viento (0xE043), guarda el rumbo y prepara la trayectoria
	ld hl,0e03bh		;6c6f   ; 0xE03B dice si el vuelo ya habia arrancado
	xor a			;6c72
	cp (hl)			;6c73
	jp nz,sigue_el_vuelo		;6c74
	inc a			;6c77
	ld (hl),a			;6c78   ; y queda puesto para los cuadros siguientes
	ld a,(0e143h)		;6c79   ; la orientacion del hoyo, de 0 a 3
	ld hl,0e105h		;6c7c
	rlca			;6c7f   ; cuatro entradas por fila
	rlca			;6c80
	add a,(hl)			;6c81   ; mas la direccion del viento, de 0 a 3
	ld hl,072a6h		;6c82   ; la tabla 4x4 de 0x72A6: hacia donde tira el viento visto desde este hoyo
	call suma_a_a_hl		;6c85
	ld a,(hl)			;6c88
	ld (0e043h),a		;6c89   ; y ahi se queda para todo el vuelo
	ld hl,(0e037h)		;6c8c   ; el rumbo con que se ha apuntado
	ld (0e044h),hl		;6c8f   ; guardado aparte, para poder rehacerlo cuando la bola ruede en el green
	call es_la_pantalla_del_green		;6c92
	jr z,arranca_el_vuelo_orienta		;6c95
arranca_el_vuelo_refleja:		; Con el rumbo del otro lado, lo refleja sobre 0x40
	ld a,(0e038h)		;6c97   ; 0xE038 dice si el rumbo esta en la otra media vuelta
	or a			;6c9a
	jr z,arranca_el_vuelo_componentes		;6c9b
	ld a,(0e037h)		;6c9d
	ld b,a			;6ca0
	ld a,040h		;6ca1   ; lo refleja: 0x40 menos el rumbo
	sub b			;6ca3
	ld (0e037h),a		;6ca4
arranca_el_vuelo_orienta:		; Corrige el rumbo segun la orientacion del hoyo (0xE143)
	ld a,(0e031h)		;6ca7   ; con la bola ya en el suelo no hay rumbo que corregir
	or a			;6caa
	jr nz,recalcula_la_trayectoria		;6cab
	ld a,(0e143h)		;6cad   ; la orientacion del hoyo; la 0 deja el rumbo tal cual
	or a			;6cb0
	jr z,arranca_el_vuelo_componentes		;6cb1
	ld hl,0e038h		;6cb3
	dec a			;6cb6
	jr nz,arranca_el_vuelo_orienta_2		;6cb7
	ld (hl),a			;6cb9   ; con la orientacion 1 basta con borrar la media vuelta
	jr arranca_el_vuelo_componentes		;6cba
arranca_el_vuelo_orienta_2:		; El caso de la orientacion 2
	dec a			;6cbc
	jr nz,arranca_el_vuelo_orienta_3		;6cbd
	ld b,0e0h		;6cbf   ; media vuelta a un lado (0x20) o al otro (0xE0), segun de donde venga
	cp (hl)			;6cc1   ; mira si la media vuelta ya estaba puesta
	jr z,arranca_el_vuelo_suma		;6cc2
	ld b,020h		;6cc4
	jr arranca_el_vuelo_suma		;6cc6
arranca_el_vuelo_orienta_3:		; El de la 3
	dec a			;6cc8
	ld b,020h		;6cc9   ; la orientacion 3 gira justo al reves que la 2
	cp (hl)			;6ccb
	jr z,arranca_el_vuelo_suma		;6ccc
	ld b,0e0h		;6cce
arranca_el_vuelo_suma:		; Suma el desvio al rumbo
	xor a			;6cd0
	ld (hl),a			;6cd1   ; la media vuelta se mete ya dentro del rumbo
	ld a,(0e037h)		;6cd2
	add a,b			;6cd5   ; suma o resta 0x20 al rumbo: media vuelta de las de 0x40
	ld (0e037h),a		;6cd6
arranca_el_vuelo_componentes:		; Del rumbo saca el octante (0xE056) y el angulo dentro de el, y lo multiplica por 16
	ld a,(0e037h)		;6cd9
	rrca			;6cdc   ; cuatro rotaciones: los bits 4 y 5 del rumbo bajan a las posiciones 0 y 1
	rrca			;6cdd
	rrca			;6cde
	rrca			;6cdf
	and 003h		;6ce0
	srl a		;6ce2
	ld b,a			;6ce4
	ld a,000h		;6ce5
	rla			;6ce7
	xor b			;6ce8   ; 0xE056 es el bit 4 contra el bit 5: dice si las dos componentes van cruzadas
	ld (0e056h),a		;6ce9
	ld a,(0e037h)		;6cec
	ld b,01fh		;6cef   ; el rumbo se pliega a 0..31
	bit 4,a		;6cf1   ; en la mitad alta se cuenta al reves, que es la simetria del octante
	jr z,arranca_el_vuelo_multiplica		;6cf3
	neg		;6cf5
arranca_el_vuelo_multiplica:		; La multiplicacion
	and b			;6cf7
	ld hl,0e060h		;6cf8   ; 0xE060 es el papel de borrador de la multiplicacion
	ld (hl),000h		;6cfb
	inc hl			;6cfd
	ld (hl),a			;6cfe
	inc hl			;6cff
	ld (hl),000h		;6d00
	inc hl			;6d02
	ld (hl),010h		;6d03   ; el multiplicador es 16
	call multiplica		;6d05
	ld a,(0e062h)		;6d08   ; el producto, byte bajo primero, a 0xE066: la pendiente del rumbo
	ld (0e066h),a		;6d0b
	ld a,(0e061h)		;6d0e
	ld (0e067h),a		;6d11
	ld hl,00000h		;6d14
	ld (0e068h),hl		;6d17   ; y el acumulador del avance fino, a cero
recalcula_la_trayectoria:		; Con la distancia de 0xE0A1 y la ficha de vuelo de 0xE0A3, saca las dos componentes del recorrido y las deja en 0xE0A7 y 0xE0A9
	ld hl,0e0a1h		;6d1a   ; la distancia del golpe y la ficha de vuelo del grupo de palo
	ld de,0e060h		;6d1d
	ld bc,00004h		;6d20   ; cuatro bytes: la distancia y la primera de las dos palabras de la ficha
	ldir		;6d23
	call multiplica		;6d25
	ld hl,(0e060h)		;6d28
	ld (0e0a7h),hl		;6d2b   ; lo que la bola recorre por el suelo
	ld hl,(0e0a1h)		;6d2e   ; otra vez la distancia...
	ld (0e060h),hl		;6d31
	ld hl,(0e0a5h)		;6d34   ; ...ahora contra la segunda palabra de la ficha
	ld (0e062h),hl		;6d37
	call multiplica		;6d3a
	ld hl,(0e060h)		;6d3d
	ld (0e0a9h),hl		;6d40   ; y eso es lo alto que va a subir el vuelo
	ld hl,00000h		;6d43
	ld (0e034h),hl		;6d46   ; el reloj del vuelo, a cero
	jp avanza_el_vuelo		;6d49
la_bola_ha_parado:		; Suena el 0x8D, marca el estado 1 y decide: en el agua, quitar 0x50 y volver a tirar la cuenta; si no, seguir
	ld a,08dh		;6d4c   ; el 0x8D es el golpe de la bola contra el suelo
	call pide_un_sonido		;6d4e
	call corre_el_sonido		;6d51
	di			;6d54
	ld a,001h		;6d55
	ld (0e122h),a		;6d57   ; estado 1: la bola ya no vuela
	pop hl			;6d5a   ; mete la mano por debajo de la direccion de retorno para poner a cero el A que dejo guardado quien llamo
	pop af			;6d5b
	xor a			;6d5c
	push af			;6d5d
	push hl			;6d5e
	ld hl,0e031h		;6d5f
	ld (hl),000h		;6d62   ; apaga la marca de "ya ha tocado suelo"
	ld l,033h		;6d64   ; y sube el contador de botes de 0xE033
	inc (hl)			;6d66
	ld a,(0e146h)		;6d67   ; en el campo se sigue por 0x6D8F; en la pantalla del putt, por aqui
	or a			;6d6a
	jr z,la_bola_rueda		;6d6b
	call rehace_la_vista		;6d6d
	ld de,00050h		;6d70   ; 0x50 es lo que se descuenta de la distancia en cada rodada del green
	ld a,(0e140h)		;6d73   ; el terreno donde ha caido
	cp 005h		;6d76   ; el 5 es el green: solo ahi se sigue rodando
	jp nz,la_bola_se_para		;6d78
	ld hl,(0e0a1h)		;6d7b   ; la distancia que queda, guardada con el byte alto primero
	ld a,l			;6d7e
	ld l,h			;6d7f
	ld h,a			;6d80
	xor a			;6d81
	sbc hl,de		;6d82
	ld a,l			;6d84
	ld l,h			;6d85
	ld h,a			;6d86
	ld (0e0a1h),hl		;6d87   ; y se vuelve a dejar del reves, como estaba
	jp nc,recalcula_la_trayectoria		;6d8a   ; si aun sobra distancia, otro tramo de rodada
	jr la_bola_se_para		;6d8d
la_bola_rueda:		; Cada bote parte la distancia que queda por cuatro y vuelve a lanzar el trozo, hasta que no queda nada
	ld a,(hl)			;6d8f
	dec a			;6d90   ; el numero de bote, descontando uno
	jr nz,la_bola_rueda_mira		;6d91
	ld a,005h		;6d93   ; el sonido 5 solo suena en el primer bote
	call pide_un_sonido		;6d95
la_bola_rueda_mira:		; Con la cuenta agotada, para
	cp 002h		;6d98   ; al tercer bote se acabo: la bola no bota mas
	jr z,la_bola_se_para		;6d9a
	call rehace_la_vista		;6d9c
	ld hl,0e0a1h		;6d9f
	srl (hl)		;6da2   ; parte por cuatro lo que queda de distancia: cada bote llega la cuarta parte que el anterior
	inc hl			;6da4
	rr (hl)		;6da5
	dec hl			;6da7
	srl (hl)		;6da8
	inc hl			;6daa
	rr (hl)		;6dab
	jr z,la_bola_se_para		;6dad   ; si no queda nada, la bola se para
	inc hl			;6daf
	inc hl			;6db0
	ld (hl),0ffh		;6db1   ; la ficha del bote: recorrido entero por el suelo y casi nada de altura
	inc hl			;6db3
	inc hl			;6db4
	ld (hl),004h		;6db5
	call esta_en_el_green		;6db7   ; mira si ha caido en el green
	jr z,la_bola_rueda_en_el_verde		;6dba
	or a			;6dbc
	jr z,la_bola_rueda_otra_vez		;6dbd
	dec a			;6dbf   ; el terreno 0, la calle: sigue rodando
	jr z,la_bola_se_para		;6dc0   ; el 1, el bunker, la clava en seco
	rrca			;6dc2   ; de los dos roughs, el 2 la para y el 3 la deja rodar; el 4 es fuera de limites y tambien para
	jr c,la_bola_se_para		;6dc3
la_bola_rueda_otra_vez:		; Limpia el terreno y vuelve a 0x6D1A con lo que queda
	xor a			;6dc5
	ld (0e140h),a		;6dc6   ; borra el terreno para volver a clasificarlo donde caiga
	jp recalcula_la_trayectoria		;6dc9   ; y otro tramo con lo que queda
la_bola_rueda_en_el_verde:		; En el green recalcula lo que falta y sigue rodando
	call calcula_lo_que_falta		;6dcc   ; recalcula lo que falta hasta la bandera
	ld a,(0e146h)		;6dcf
	or a			;6dd2
	jr z,la_bola_rueda_otra_vez		;6dd3
	ld hl,(0e044h)		;6dd5   ; recupera el rumbo con que se golpeo
	ld (0e037h),hl		;6dd8
	jp arranca_el_vuelo_refleja		;6ddb   ; en la pantalla del putt el rumbo se refleja
la_bola_se_para:		; Apaga 0xE039 y deja el estado en 0x10
	xor a			;6dde
	ld (0e039h),a		;6ddf   ; se acabo el golpe
	ld a,010h		;6de2
	ld (0e122h),a		;6de4   ; estado 0x10: la bola quieta, esperando
	ret			;6de7
sigue_el_vuelo:		; Si ya toco suelo se va al cierre; si no, avanza un paso
	ld a,(0e031h)		;6de8   ; 0xE031 se enciende cuando la bola toca el suelo
	or a			;6deb
	jp nz,la_bola_ha_parado		;6dec
avanza_el_vuelo:		; Un paso del recorrido: suma el avance a la componente larga, la divide y reparte el resto entre las dos coordenadas
	ld hl,0e0a7h		;6def   ; el recorrido por el suelo, byte alto primero
	ld d,(hl)			;6df2
	inc hl			;6df3
	ld e,(hl)			;6df4
	ex de,hl			;6df5
	ld a,(0e054h)		;6df6   ; mas el resto que sobro del cuadro anterior
	call suma_a_a_hl		;6df9
	ld a,h			;6dfc   ; le da la vuelta a los dos bytes para dejar el dividendo como lo quiere 0x7155
	ld h,l			;6dfd
	ld l,a			;6dfe
	ld (0e060h),hl		;6dff
	ld hl,0e062h		;6e02
	ld (hl),000h		;6e05
	inc hl			;6e07
	ld (hl),080h		;6e08   ; divide entre 0x80: el recorrido viene en ciento veintiochoavos
	call divide		;6e0a
	ld a,(0e060h)		;6e0d   ; el resto se guarda para el cuadro que viene
	ld (0e054h),a		;6e10
	ld a,(0e062h)		;6e13   ; y el cociente es lo que avanza este cuadro
	ld b,a			;6e16
	or a			;6e17
	jr z,avanza_el_vuelo_verde		;6e18
	ld (0e040h),a		;6e1a   ; deja anotado que en este cuadro ha habido avance de verdad
avanza_el_vuelo_verde:		; En el green y con la bola a la izquierda, redondea el avance hacia arriba
	call es_la_pantalla_del_green		;6e1d   ; 0xE146 distinto de cero es la pantalla del putt; ahi no se toca el avance
	jr nz,avanza_el_vuelo_acumula		;6e20
	ld a,(0e0b0h)		;6e22   ; la y de la bola en pantalla
	cp 055h		;6e25
	jr nc,avanza_el_vuelo_acumula		;6e27
	ld a,b			;6e29
	srl a		;6e2a   ; por encima de la fila 0x55 el avance va a la mitad: es la parte lejana del campo
	ld b,a			;6e2c
	jr nc,avanza_el_vuelo_acumula		;6e2d
	ld a,(0e054h)		;6e2f   ; el bit que se pierde al partir por dos se devuelve al resto
	add a,080h		;6e32
	ld (0e054h),a		;6e34
avanza_el_vuelo_acumula:		; Acumula el avance fino en 0xE068
	ld hl,(0e066h)		;6e37   ; el rumbo por dieciseis, que hace de pendiente
	ex de,hl			;6e3a
	ld hl,(0e068h)		;6e3b   ; el acumulador de la componente corta
	ld a,b			;6e3e
avanza_el_vuelo_suma:		; El bucle de sumas que hace de multiplicacion
	sub 001h		;6e3f   ; suma la pendiente tantas veces como avance haya: una multiplicacion a base de sumas
	jr c,avanza_el_vuelo_parte		;6e41
	add hl,de			;6e43
	jr avanza_el_vuelo_suma		;6e44
avanza_el_vuelo_parte:		; Se queda con la parte entera y guarda el resto
	ld a,l			;6e46
	ld (0e068h),a		;6e47   ; el byte bajo se queda de resto
	ld c,h			;6e4a   ; y el alto es lo que se desvia de lado este cuadro
	ld a,h			;6e4b
	or a			;6e4c
	jr z,avanza_el_vuelo_signos		;6e4d
	ld (0e040h),a		;6e4f
avanza_el_vuelo_signos:		; Cruza y cambia de signo las dos componentes segun el octante
	ld hl,0e037h		;6e52
	ld a,(0e056h)		;6e55   ; 0xE056 dice si en este octante los dos ejes van cruzados
	or a			;6e58
	jr z,avanza_el_vuelo_octante		;6e59
	ld a,b			;6e5b   ; cruza las dos componentes
	ld b,c			;6e5c
	ld c,a			;6e5d
	bit 4,(hl)		;6e5e   ; el bit 4 del rumbo decide el signo
	jr z,$+22		;6e60
	jr avanza_el_vuelo_niega_b		;6e62
avanza_el_vuelo_octante:		; El caso sin cruce
	ld a,(hl)			;6e64
	and 0f0h		;6e65   ; con el rumbo por debajo de 0x10 la componente larga cambia de signo
	or a			;6e67
	jr nz,$+14		;6e68
avanza_el_vuelo_niega_b:		; Cambia el signo de la componente B
	ld a,b			;6e6a
	neg		;6e6b   ; le cambia el signo
	ld b,a			;6e6d
	jr $+8		;6e6e   ; los tres saltos de aqui al lado van todos al 0x6E76: los seis bytes de en medio no los ejecuta nadie

; ----------------------------------------------------------------------
; DATOS codigo_muerto_6e70: Seis bytes que son codigo bueno -niega C y vuelve
;   a 0x6E64-, gemelos de los de 0x6E6A, que niegan B. No salta nadie aqui:
;   los tres `jr` de alrededor apuntan a 0x6E76
;   0x6e70..0x6e76  (6 bytes)
DATA_codigo_muerto_6e70:
	defb 079h,0edh,044h,04fh,018h,0eeh	; 6e70

; ======================================================================
; CODIGO 0x6e76..0x7151  (731 bytes)
; ======================================================================


reparte_el_avance:		; Lleva el avance a la posicion en pantalla de la bola y de su sombra, y aplica el efecto del golpe -SLICE o HOOK- y el empujon del viento
	ld a,(0e038h)		;6e76   ; la media vuelta del rumbo decide el sentido del avance
	or a			;6e79
	ld a,c			;6e7a
	ld d,000h		;6e7b   ; DE lleva la componente con el signo ya extendido a 16 bits
	ld e,a			;6e7d
	jr nz,reparte_el_avance_signo		;6e7e
	neg		;6e80   ; en la otra media vuelta el avance va al reves
	ld d,0ffh		;6e82
	ld e,a			;6e84
reparte_el_avance_signo:		; Prepara el signo de la componente
	or a			;6e85
	jr nz,reparte_el_avance_efecto		;6e86
	ld d,a			;6e88   ; sin avance no hay signo que poner
reparte_el_avance_efecto:		; Con 0xE041 puesto, mira si toca desviar
	push bc			;6e89
	ld b,a			;6e8a
	ld a,(0e041h)		;6e8b   ; el efecto solo tuerce con 0xE041 puesto, o sea cuando la bola ya va de bajada
	or a			;6e8e
	jr z,reparte_el_avance_x		;6e8f
	xor a			;6e91
	ld hl,0e040h		;6e92   ; y solo en los cuadros en que ha habido avance entero
	cp (hl)			;6e95
	jr z,reparte_el_avance_x		;6e96
	ld hl,0e120h		;6e98   ; el efecto del golpe: 0 recto, y 1 y 2 los dos lados
	cp (hl)			;6e9b
	jr z,reparte_el_avance_viento		;6e9c
	ld a,(0e037h)		;6e9e   ; el rumbo decide si el desvio entra en este eje
	ld c,0ffh		;6ea1
	cp 010h		;6ea3   ; por debajo de 0x10 tuerce con signo menos...
	jr c,reparte_el_avance_desvia		;6ea5
	cp 030h		;6ea7   ; ...de 0x30 en adelante con signo mas, y en la franja de en medio no tuerce
	ld c,001h		;6ea9
	jr c,reparte_el_avance_viento		;6eab
reparte_el_avance_desvia:		; Aplica el desvio del efecto segun 0xE120: a un lado con SLICE y al otro con HOOK
	ld a,c			;6ead
	ld (0e046h),a		;6eae   ; deja anotado que este cuadro lleva desvio
	ld a,(hl)			;6eb1   ; el efecto 1 tuerce a un lado...
	dec a			;6eb2
	jr z,reparte_el_avance_desvio_hecho		;6eb3
	ld a,c			;6eb5
	neg		;6eb6   ; ...y el 2 al contrario, con el desvio cambiado de signo
	ld c,a			;6eb8
reparte_el_avance_desvio_hecho:		; Ya desviado
	call suma_con_signo		;6eb9   ; un paso a un lado o al otro, sumado a la componente
reparte_el_avance_viento:		; Si el reloj del viento ha saltado (0xE03D), lo empuja hacia donde diga 0xE043
	call es_la_pantalla_del_green		;6ebc   ; en la pantalla del putt el viento empuja siempre
	jr nz,reparte_el_avance_viento_lado		;6ebf
	ld a,(0e033h)		;6ec1   ; en el campo, en cuanto la bola ha botado el viento deja de empujar
	or a			;6ec4
	jr nz,reparte_el_avance_x		;6ec5
reparte_el_avance_viento_lado:		; Elige el lado del empujon
	xor a			;6ec7
	ld hl,0e03dh		;6ec8   ; 0xE03D es el empujon que dejo pendiente el reloj del viento
	cp (hl)			;6ecb
	jr z,reparte_el_avance_x		;6ecc
	ld c,0ffh		;6ece
	ld a,(0e043h)		;6ed0   ; hacia donde tira el viento en este hoyo
	cp 002h		;6ed3   ; el rumbo de viento 2 empuja a un lado...
	jr z,reparte_el_avance_viento_aplica		;6ed5
	ld c,001h		;6ed7
	cp 003h		;6ed9   ; ...el 3 al otro, y el 0 y el 1 son los que mueven el otro eje
	jr nz,reparte_el_avance_x		;6edb
reparte_el_avance_viento_aplica:		; Y lo aplica
	ld (0e046h),a		;6edd   ; anota el desvio del viento
	xor a			;6ee0
	ld (hl),a			;6ee1   ; y consume el empujon: no vuelve hasta que el reloj llegue otra vez a cero
	call suma_con_signo		;6ee2
reparte_el_avance_x:		; Mueve la coordenada x de la bola con 0x719B
	push de			;6ee5
	ld hl,0e0b8h		;6ee6   ; la casilla de la bola en el plano
	call de_quien_es_el_turno		;6ee9   ; cada jugador lleva su propia parte fina
	ld de,0e058h		;6eec
	jr z,reparte_el_avance_sombra		;6eef
	inc e			;6ef1
reparte_el_avance_sombra:		; Y la de la sombra
	call mueve_la_x_de_la_bola		;6ef2   ; suma el avance a la parte fina y pasa lo que desborda a la casilla; segun la orientacion del hoyo (0xE143) toca una coordenada de pantalla o la otra
	pop de			;6ef5
	call es_la_pantalla_del_green		;6ef6
	jr nz,reparte_el_avance_sube		;6ef9
	ld a,(0e0b0h)		;6efb   ; la y de la bola en pantalla
	cp 038h		;6efe   ; por encima de la fila 0x38 se deja de subir y lo que avanza pasa a la altura
	jr c,reparte_el_avance_baja		;6f00
reparte_el_avance_sube:		; La bola sube: suma el avance a la y
	ld a,e			;6f02
	ld hl,0e0b0h		;6f03   ; la bola sube por la pantalla segun se aleja
	add a,(hl)			;6f06
	ld (hl),a			;6f07
	ld a,(0e0b4h)		;6f08   ; y la altura sigue el mismo camino
	jr reparte_el_avance_altura		;6f0b
reparte_el_avance_baja:		; La bola baja
	ld a,(0e0b4h)		;6f0d   ; la altura de la bola
	sub e			;6f10
	jp m,reparte_el_avance_altura		;6f11
	ld hl,0e042h		;6f14
	ld (hl),000h		;6f17   ; si al restar se pasa por abajo, se tira el byte alto
reparte_el_avance_altura:		; Guarda la altura y su parte fina en 0xE042
	ld l,a			;6f19
	ld a,(0e042h)		;6f1a   ; 0xE042 es el byte alto de la misma cuenta de 16 bits
	ld h,a			;6f1d
	ld b,e			;6f1e
	add hl,de			;6f1f
	ld a,l			;6f20
	ld (0e0b4h),a		;6f21   ; el byte bajo hace de coordenada en pantalla
	ld a,h			;6f24
	ld (0e042h),a		;6f25
	call de_quien_es_el_turno		;6f28   ; cada jugador lleva su parte fina tambien en este eje
	ld de,0e05ah		;6f2b
	jr z,reparte_el_avance_y		;6f2e
	inc e			;6f30
reparte_el_avance_y:		; Mueve la coordenada y con 0x719B
	ld hl,0e0bch		;6f31   ; la otra casilla de la bola en el plano
	call mueve_la_x_de_la_bola		;6f34
	pop bc			;6f37   ; recupera la componente larga del avance
	ld a,(0e041h)		;6f38   ; el efecto tambien tuerce en este eje, y tambien solo de bajada
	or a			;6f3b
	jr z,reparte_el_avance_limpia		;6f3c
	xor a			;6f3e
	ld hl,0e040h		;6f3f
	cp (hl)			;6f42
	jr z,reparte_el_avance_limpia		;6f43
	ld (hl),a			;6f45   ; aqui se apaga la marca del avance, para que el desvio entre una sola vez
	ld hl,0e120h		;6f46   ; el efecto del golpe
	cp (hl)			;6f49
	jr z,reparte_el_avance_viento_y		;6f4a
	ld a,(0e037h)		;6f4c   ; en este eje el desvio entra en la franja CONTRARIA a la del otro...
	cp 011h		;6f4f
	jr c,reparte_el_avance_viento_y		;6f51
	cp 030h		;6f53   ; ...solo entre 0x11 y 0x2F
	jr nc,reparte_el_avance_viento_y		;6f55
	ld a,(hl)			;6f57
	dec a			;6f58
	ld a,001h		;6f59   ; un paso a un lado con un efecto...
	jr z,reparte_el_avance_efecto_y		;6f5b
	ld a,0ffh		;6f5d   ; ...y al otro con el contrario
reparte_el_avance_efecto_y:		; El efecto tambien tuerce el eje y
	add a,b			;6f5f   ; el desvio se suma a la componente larga
	ld b,a			;6f60
reparte_el_avance_viento_y:		; Y el viento
	call es_la_pantalla_del_green		;6f61
	jr nz,reparte_el_avance_viento_y_lado		;6f64
	ld a,(0e033h)		;6f66   ; en el campo, con la bola ya botando, el viento tampoco empuja aqui
	or a			;6f69
	jr nz,reparte_el_avance_limpia		;6f6a
reparte_el_avance_viento_y_lado:		; El lado del empujon en y
	ld hl,0e03dh		;6f6c   ; el empujon pendiente del reloj del viento
	xor a			;6f6f
	cp (hl)			;6f70
	jr z,reparte_el_avance_limpia		;6f71
	ld a,(0e043h)		;6f73   ; hacia donde tira el viento
	or a			;6f76
	ld c,0ffh		;6f77   ; el rumbo de viento 0 empuja a un lado...
	jr z,reparte_el_avance_viento_y_aplica		;6f79
	dec a			;6f7b   ; ...el 1 al otro, y el 2 y el 3 son los del otro eje
	jr nz,reparte_el_avance_limpia		;6f7c
	ld c,001h		;6f7e
reparte_el_avance_viento_y_aplica:		; Lo aplica
	ld (hl),a			;6f80   ; gasta el aviso del viento: 0xE03D vuelve a cero hasta la proxima cuenta de 0xE03C
	ld a,c			;6f81
	add a,b			;6f82   ; el viento suma o resta UN punto al desvio lateral de este cuadro
	ld b,a			;6f83
reparte_el_avance_limpia:		; Apaga la marca de desvio
	ld a,(0e046h)		;6f84   ; 0xE046 lo dejan puestos 0x6EAE y 0x6EDD: el desvio o el viento ya han empujado un eje
	or a			;6f87
	jr z,reparte_el_avance_guarda		;6f88
	xor a			;6f8a
	ld (0e040h),a		;6f8b   ; y entonces se gasta el vale de 0xE040, que solo da derecho a UN empujon por cuadro
reparte_el_avance_guarda:		; Deja la y y mueve la sombra con 0x71F1
	ld a,b			;6f8e
	ld hl,0e0b1h		;6f8f   ; 0xE0B1 es la x de la capa negra de la bola, la que va pegada al suelo
	add a,(hl)			;6f92
	ld (hl),a			;6f93
	ld (0e0b5h),a		;6f94   ; y 0xE0B5 la de la capa blanca, la que se levanta con la parabola
	call mueve_la_y_de_la_bola		;6f97   ; a las dos marcas del plano del hoyo les toca solo la parte dividida: van a otra escala

; ----------------------------------------------------------------------
; ----- El reloj del vuelo contra la cima de la trayectoria -----
; ----------------------------------------------------------------------
	ld hl,(0e034h)		;6f9a
	ld a,00eh		;6f9d   ; el reloj del vuelo, 0xE034, sube catorce por cuadro
	call suma_a_a_hl		;6f9f
	ld (0e034h),hl		;6fa2
	ex de,hl			;6fa5
	ld hl,(0e0a9h)		;6fa6   ; 0xE0A9 guarda la cima de la trayectoria con los bytes al reves; aqui se le da la vuelta
	ld a,l			;6fa9
	ld l,h			;6faa
	ld h,a			;6fab
	ld a,(0e036h)		;6fac   ; y se le suma el resto que dejo la division de 0x6FDA
	call suma_a_a_hl		;6faf
	xor a			;6fb2
	ld (0e032h),a		;6fb3   ; 0xE032 a cero: de momento la bola sigue subiendo
	ld b,h			;6fb6
	ld c,l			;6fb7
	sbc hl,de		;6fb8   ; compara la cima con lo que se lleva volado
	jr nc,baja_la_altura		;6fba
	ld h,b			;6fbc
	ld l,c			;6fbd
	ex de,hl			;6fbe
	xor a			;6fbf
	sbc hl,de		;6fc0   ; pasada la cima la resta se hace al reves, para que quede positiva
	inc a			;6fc2
	ld (0e032h),a		;6fc3   ; 0xE032 y 0xE041 a uno: la bola ya BAJA
	ld (0e041h),a		;6fc6
	inc a			;6fc9
	ld (0e650h),a		;6fca   ; y el silbido de 0x74BE pasa al modo 2, el que hace CAER el tono
baja_la_altura:		; Divide la altura que queda por 128 y se la resta a la bola: es la caida
	ex de,hl			;6fcd
	ld hl,0e060h		;6fce
	ld (hl),d			;6fd1   ; 0xE060 y 0xE061 son la altura que queda, byte alto primero
	inc hl			;6fd2
	ld (hl),e			;6fd3
	inc hl			;6fd4
	ld (hl),000h		;6fd5   ; 0xE062 a cero: es el byte bajo del dividendo y por ahi sale luego el cociente
	inc hl			;6fd7
	ld (hl),080h		;6fd8   ; 0xE063 es el divisor, 128: cada cuadro se recorre 1/128 de lo que falta
	call divide		;6fda
	ld a,(0e060h)		;6fdd   ; el resto se guarda en 0xE036 y vuelve al reparto del cuadro siguiente
	ld (0e036h),a		;6fe0
	ld a,(0e062h)		;6fe3   ; el cociente son los puntos que sube o baja la bola en este cuadro
	ld d,000h		;6fe6
	ld e,a			;6fe8
	or a			;6fe9
	jr z,baja_la_altura_aplica		;6fea
	ld hl,0e032h		;6fec
	bit 0,(hl)		;6fef   ; con 0xE032 puesto la bola cae y el salto va sumado
	jr nz,baja_la_altura_aplica		;6ff1
	neg		;6ff3   ; subiendo, el salto se pasa a negativo con el signo extendido en D
	ld d,0ffh		;6ff5
	ld e,a			;6ff7
baja_la_altura_aplica:		; Se la suma a la coordenada de la bola
	ld hl,0e0bch		;6ff8   ; 0xE0BC es la y de la marca blanca del plano: se levanta con la misma altura
	add a,(hl)			;6ffb
	ld (hl),a			;6ffc
	ld a,(0e0b0h)		;6ffd   ; 0xE0B0 es la y del suelo por el que pasa la bola, y el tope de la caida
	ld b,a			;7000
	ld a,(0e0b4h)		;7001
	ld l,a			;7004
	ld a,(0e042h)		;7005   ; 0xE042 y 0xE0B4 son la y de la bola en 16 bits, con 0xE042 de byte alto
	ld h,a			;7008
	add hl,de			;7009   ; le suma el salto con signo
	ld a,l			;700a
	ld (0e0b4h),a		;700b
	ld a,h			;700e
	ld (0e042h),a		;700f
	or a			;7012   ; con el byte alto puesto la bola se sale de la pantalla por arriba: sigue en el aire
	jr nz,mira_donde_cae		;7013
	ld a,l			;7015
	cp b			;7016   ; en cuanto la y de la bola pasa de la del suelo, se ha posado
	jr z,mira_donde_cae		;7017
	jr c,mira_donde_cae		;7019
	ld a,(0e0b9h)		;701b   ; al posarse, las dos marcas del plano vuelven a juntarse
	ld (0e0bdh),a		;701e
	ld a,001h		;7021
	ld (0e031h),a		;7023   ; 0xE031 avisa de que la bola ya toca el suelo
	ld a,b			;7026
	ld (0e0b4h),a		;7027   ; y la y se recorta al suelo, para que no lo atraviese
	ld a,(0e0b8h)		;702a
	ld (0e0bch),a		;702d
mira_donde_cae:		; Si la bola se sale del rectangulo bueno la esconde; si no, elige el tamano con que se dibuja segun lo alta que vaya
	ld a,(0e0b3h)		;7030   ; 0xE0B3 es el color de la bola: a cero esta apagada y no hay nada que mirar
	or a			;7033
	jp z,pinta_los_sprites_de_la_bola		;7034
	call es_la_pantalla_del_green		;7037   ; devuelve Z fuera del putt, y entonces este margen ni se mira
	jr z,mira_donde_cae_y		;703a
	ld a,(0e0b0h)		;703c   ; solo en la pantalla del putt se le pide a la y caer entre 8 y 0xB5
	cp 008h		;703f
	jp c,pinta_los_sprites_de_la_bola		;7041
	cp 0b6h		;7044
	jr nc,mira_donde_cae_fuera		;7046
mira_donde_cae_y:		; El margen por arriba y por abajo
	ld a,(0e0b1h)		;7048   ; la x, esa siempre, entre 8 y 0xA5: mas a la derecha empieza el plano del hoyo
	cp 008h		;704b
	jr c,mira_donde_cae_fuera		;704d
	cp 0a6h		;704f
	jr c,mira_donde_cae_tamano		;7051
mira_donde_cae_fuera:		; Fuera: apaga la bola
	xor a			;7053   ; color cero en las dos capas: la bola desaparece de la vista
	ld (0e0b3h),a		;7054
	ld (0e0b7h),a		;7057
	jr pinta_los_sprites_de_la_bola		;705a
mira_donde_cae_tamano:		; Con la altura, saca el escalon del tamano
	ld a,(0e042h)		;705c   ; con el byte alto de la altura puesto la bola va altisima: escalon 0, el punto mas pequeno
	or a			;705f
	ld a,000h		;7060
	jr nz,mira_donde_cae_dibuja		;7062
	ld a,(0e0b0h)		;7064
	ld b,005h		;7067   ; cinco es el escalon mayor, el circulo de siete pixeles de 0x7273
	ld c,a			;7069
	cp 0d0h		;706a   ; 0xD0 es la marca de sprite escondido: no hay nada que medir
	ret z			;706c
	ld a,(0e0b4h)		;706d   ; y la capa blanca tampoco puede estar escondida
	cp 0d0h		;7070
	ret z			;7072
	ld d,a			;7073
	ld a,(0e0b0h)		;7074   ; la altura sobre el suelo es lo que separa la capa blanca de la negra
	sub d			;7077
	cp 021h		;7078   ; los cortes del tamano: 0x21, 0x0F y 0x06 pixeles de separacion
	jr nc,mira_donde_cae_ajusta		;707a
	dec b			;707c   ; cada corte que se pasa baja un escalon
	cp 00fh		;707d
	jr nc,mira_donde_cae_ajusta		;707f
	dec b			;7081
	cp 006h		;7082
	jr nc,mira_donde_cae_ajusta		;7084
	dec b			;7086
mira_donde_cae_ajusta:		; Ajusta el escalon con la altura de la bola
	ld a,c			;7087
	cp 038h		;7088   ; por encima de la fila 0x38 de la pantalla la bola esta ya lejisimos: escalon 0
	jr nc,mira_donde_cae_nibble		;708a
	xor a			;708c
	jr mira_donde_cae_dibuja		;708d
mira_donde_cae_nibble:		; Se queda con el nibble alto
	and 0f0h		;708f   ; de la fila de la bola se queda con el nibble alto: un escalon cada dieciseis filas
	cp 020h		;7091   ; este corte no llega a saltar NUNCA: 0x7088 ya ha apartado todo lo que baja de la fila 0x38
	jr c,mira_donde_cae_tope		;7093
	rrca			;7095
	rrca			;7096
	rrca			;7097
	rrca			;7098
	dec a			;7099   ; dos menos, para que la fila 0x20 salga escalon cero
	dec a			;709a
	cp b			;709b   ; y se queda con el menor de los dos, el de la altura o el de la lejania
	jr c,mira_donde_cae_dibuja		;709c
mira_donde_cae_tope:		; Topa el escalon
	ld a,b			;709e
mira_donde_cae_dibuja:		; Pide los dos guiones de 0x725B y los pinta en los patrones de sprite 0x1800 y 0x1820
	ld b,a			;709f
	ld a,(0e146h)		;70a0   ; en la pantalla del putt (0xE146) la bola va siempre en el escalon 3
	or a			;70a3
	jr z,mira_donde_cae_indexa		;70a4
	ld b,003h		;70a6
	xor a			;70a8
	ld (0e0b7h),a		;70a9   ; y sin capa blanca ni marca blanca en el plano: los colores 0xE0B7 y 0xE0BF a cero
	ld (0e0bfh),a		;70ac
mira_donde_cae_indexa:		; La entrada de la tabla
	ld a,b			;70af
	ld hl,0725bh		;70b0   ; la tabla de 0x725B lleva cuatro bytes por escalon: dos punteros a guion
	rlca			;70b3   ; por cuatro, que es lo que ocupa una entrada
	rlca			;70b4
	call suma_a_a_hl		;70b5
	ld e,(hl)			;70b8   ; el primero de la pareja de punteros es el dibujo de la bola
	inc hl			;70b9
	ld d,(hl)			;70ba
	inc hl			;70bb
	push hl			;70bc
	ex de,hl			;70bd
	ld de,05800h		;70be   ; 0x5800 es la VRAM 0x1800 con el bit de escritura: el patron 0, la bola blanca
	call pinta_guion_de		;70c1
	pop hl			;70c4   ; recupera la tabla, guardada antes de pintar el primer guion, y coge el segundo puntero
	ld e,(hl)			;70c5
	inc hl			;70c6
	ld d,(hl)			;70c7
	ex de,hl			;70c8
	ld de,05820h		;70c9   ; y 0x5820 el patron 4, el circulo negro que va debajo
	call pinta_guion_de		;70cc
pinta_los_sprites_de_la_bola:		; Vuelca los atributos de la bola, su sombra y las dos capas a las VRAM 0x3B54, 0x3B30, 0x3B38 y 0x3B50
	ld a,(0e0b8h)		;70cf   ; la marca del plano solo vale si su y cae en las dieciseis filas del plano, de 0x38 a 0xB5
	cp 038h		;70d2
	jr c,pinta_los_sprites_apaga		;70d4
	cp 0b6h		;70d6
	jr nc,pinta_los_sprites_apaga		;70d8
	ld a,(0e0b9h)		;70da   ; y su x en las nueve columnas, de 0xB0 a 0xF5
	cp 0b0h		;70dd
	jr c,pinta_los_sprites_apaga		;70df
	cp 0f6h		;70e1
	jr c,pinta_los_sprites_vuelca		;70e3
pinta_los_sprites_apaga:		; Esconde la sombra cuando se sale de la vista
	xor a			;70e5
	ld (0e0bbh),a		;70e6   ; fuera del plano las dos marcas se apagan por el color
	ld (0e0bfh),a		;70e9
pinta_los_sprites_vuelca:		; Los cuatro volcados; con la bola en el aire usa el relleno de 0x7151 para la capa que no se ve
	ld hl,0e0b0h		;70ec
	ld de,07b54h		;70ef   ; 0x7B54 es la VRAM 0x3B54, el sprite 21: la capa negra de la bola
	ld a,(0e146h)		;70f2   ; en la pantalla del putt el reparto de sprites es otro
	or a			;70f5
	jr nz,pinta_los_sprites_en_el_verde		;70f6
	call vuelca_cuatro_bytes		;70f8   ; al volcar los cuatro bytes HL queda ya en 0xE0B4, la capa blanca
	ld a,(0e042h)		;70fb   ; con el byte alto de la altura puesto la bola se sale por arriba de la pantalla
	or a			;70fe
	jr z,pinta_los_sprites_capa_1		;70ff
	ld hl,07151h		;7101   ; y entonces se vuelca el relleno de 0x7151, que la esconde en la fila 0xCF
pinta_los_sprites_capa_1:		; La primera capa
	ld de,07b30h		;7104   ; el sprite 12 es la bola del primer jugador y el 13 la del segundo
	call de_quien_es_el_turno		;7107
	jr z,pinta_los_sprites_capa_2		;710a
	ld e,034h		;710c
pinta_los_sprites_capa_2:		; La segunda
	call vuelca_cuatro_bytes		;710e
	ld hl,0e0bch		;7111   ; 0xE0BC es la marca blanca del plano, la que se levanta con la altura
	ld de,07b38h		;7114   ; sprite 14 para el primer jugador y sprite 15 para el segundo
	call de_quien_es_el_turno		;7117
	jr z,pinta_los_sprites_capa_3		;711a
	ld e,03ch		;711c
pinta_los_sprites_capa_3:		; La tercera
	call vuelca_cuatro_bytes		;711e
	ld hl,0e0b8h		;7121   ; la marca negra del plano va siempre al sprite 20, sin repartir por jugador
	ld de,07b50h		;7124
	jp vuelca_cuatro_bytes		;7127
pinta_los_sprites_en_el_verde:		; En la pantalla del green solo hay una capa
	ld e,030h		;712a   ; en el putt la capa negra ocupa el sprite 12 o el 13, que es el sitio de la bola
	call de_quien_es_el_turno		;712c
	jr z,pinta_los_sprites_en_el_verde_2		;712f
	ld e,034h		;7131
pinta_los_sprites_en_el_verde_2:		; Y la de la sombra
	call vuelca_cuatro_bytes		;7133
	ld hl,0e0b8h		;7136   ; y la marca negra del plano el sprite 14 o el 15
	ld e,038h		;7139
	call de_quien_es_el_turno		;713b
	jr z,pinta_los_sprites_en_el_verde_3		;713e
	ld e,03ch		;7140
pinta_los_sprites_en_el_verde_3:		; Y la de la mira, si toca
	call vuelca_cuatro_bytes		;7142
	call de_quien_es_el_turno		;7145   ; al primer jugador ya no le queda nada; el segundo pinta ademas la bola del otro
	ret z			;7148
	ld hl,0e1c0h		;7149   ; 0xE1C0 guarda la ficha de sprites del primer jugador
	ld e,030h		;714c
	jp vuelca_cuatro_bytes		;714e

; ----------------------------------------------------------------------
; DATOS relleno_7151: 0xCF 0xCF 0x00 0x00 detras del `jp` de 0x714E, que es el
;   final de la rutina. Nadie lo lee
;   0x7151..0x7155  (4 bytes)
DATA_relleno_7151:
	defb 0cfh,0cfh,000h,000h	; 7151

; ======================================================================
; CODIGO 0x7155..0x725b  (262 bytes)
; ======================================================================


divide:		; Division sin signo sobre el buffer de 0xE060: ocho vueltas de desplazar tres bytes y restar
	exx			;7155
	ld c,008h		;7156   ; ocho vueltas: el cociente sale de ocho bits
divide_vuelta:		; Una vuelta
	ld hl,0e062h		;7158
	or a			;715b   ; limpia el acarreo que entra por abajo en el desplazamiento
	ld b,003h		;715c
divide_desplaza:		; El desplazamiento de tres bytes
	rl (hl)		;715e   ; desplaza a la izquierda 0xE062, 0xE061 y 0xE060, del byte bajo al alto
	dec hl			;7160
	djnz divide_desplaza		;7161
	inc hl			;7163
	ex de,hl			;7164   ; DE se queda apuntando a 0xE060, el byte de mas peso
	ld hl,0e063h		;7165   ; 0xE063 es el divisor y 0xE060 hace de resto
	ld a,(de)			;7168
	sub (hl)			;7169
	jr c,divide_cuenta		;716a
	ld (de),a			;716c
	dec hl			;716d
	set 0,(hl)		;716e   ; el bit del cociente entra por el byte bajo, que es 0xE062
divide_cuenta:		; Descuenta la vuelta
	dec c			;7170
	jr nz,divide_vuelta		;7171
	exx			;7173   ; el juego alternativo de registros: la division no le toca nada al que llama
	ret			;7174
multiplica:		; Multiplicacion de 16 por 16 bits sobre el buffer de 0xE060: dieciseis vueltas de desplazar y sumar
	exx			;7175
	ld b,010h		;7176   ; dieciseis vueltas: multiplicacion de 16 por 16 bits
multiplica_vuelta:		; Una vuelta
	ld hl,0e062h		;7178
	or a			;717b
	rl (hl)		;717c   ; desplaza a la izquierda los tres bytes, de 0xE062 a 0xE060
	dec hl			;717e
	rl (hl)		;717f
	dec hl			;7181
	rl (hl)		;7182
	jr nc,multiplica_cuenta		;7184   ; el bit que sale por arriba dice si toca sumar
	ld hl,0e063h		;7186   ; suma el multiplicando de 0xE063 al acumulador de tres bytes
	ld a,(hl)			;7189
	dec hl			;718a
	add a,(hl)			;718b
	ld (hl),a			;718c
	dec hl			;718d
	ld a,(hl)			;718e
	adc a,000h		;718f   ; y arrastra el acarreo a los dos bytes de mas peso
	ld (hl),a			;7191
	dec hl			;7192
	ld a,(hl)			;7193
	adc a,000h		;7194
	ld (hl),a			;7196
multiplica_cuenta:		; Descuenta la vuelta
	djnz multiplica_vuelta		;7197
	exx			;7199   ; devuelve los registros del que llama
	ret			;719a
mueve_la_x_de_la_bola:		; Suma B a la coordenada fina de (DE) y pasa el desbordamiento a la casilla de (HL), con un divisor distinto -7, 4 o 2- segun se este en el campo, en el green o cerca
	ld a,(0e0bbh)		;719b   ; 0xE0BB es el color de la marca del plano: apagada, no hay nada que mover
	or a			;719e
	ret z			;719f
	xor a			;71a0
	ld (0e057h),a		;71a1   ; 0xE057 guarda si al avance hubo que quitarle el signo
	ld a,b			;71a4
	bit 7,a		;71a5
	jr z,mueve_la_x_divisor		;71a7
	neg		;71a9   ; se trabaja siempre en positivo y el signo se devuelve al final
	ld (0e057h),a		;71ab
	ld b,a			;71ae
mueve_la_x_divisor:		; Elige el divisor
	ld c,007h		;71af   ; en la pantalla del putt, cada siete puntos de la vista es uno del plano
	call es_la_pantalla_del_green		;71b1
	jr nz,mueve_la_x_suma		;71b4
	ld c,004h		;71b6   ; en el campo, cada cuatro
	ld a,(0e0b0h)		;71b8   ; y por encima de la fila 0x55, donde la perspectiva aprieta, cada dos
	cp 055h		;71bb
	jr nc,mueve_la_x_suma		;71bd
	ld c,002h		;71bf
mueve_la_x_suma:		; La suma y el reparto
	ld a,(de)			;71c1   ; (DE) es el resto fino del jugador, donde se acumula lo que no llega a punto
	add a,b			;71c2
	ld b,0ffh		;71c3   ; B arranca en -1 porque el bucle cuenta una resta de mas
mueve_la_x_bucle:		; El bucle que saca el cociente restando
	ld (de),a			;71c5   ; guarda el resto ANTES de restar: al salir queda el ultimo que no se paso de la raya
	sub c			;71c6   ; el cociente sale a base de restar el divisor y contar vueltas
	inc b			;71c7
	jr nc,mueve_la_x_bucle		;71c8
	call es_la_pantalla_del_green		;71ca
	jr z,mueve_la_x_signo		;71cd
	ld a,(de)			;71cf   ; en la pantalla del putt el cociente vuelve tambien al resto fino; en el campo no
	add a,b			;71d0
	ld (de),a			;71d1
mueve_la_x_signo:		; Devuelve el signo que se le habia quitado
	ld a,(0e057h)		;71d2   ; si el avance venia negativo, el cociente se devuelve negativo
	or a			;71d5
	ld a,b			;71d6
	jr z,mueve_la_x_orienta		;71d7
	neg		;71d9
	ld b,a			;71db
mueve_la_x_orienta:		; Con las orientaciones 1 y 2 el sentido se invierte
	ld a,(0e143h)		;71dc   ; 0xE143 es la orientacion del hoyo, de 0 a 3
	or a			;71df
	jr z,mueve_la_x_guarda		;71e0
	dec a			;71e2
	jr z,mueve_la_x_niega		;71e3
	inc hl			;71e5   ; con las orientaciones 2 y 3 se mueve el byte de al lado de la ficha
	dec a			;71e6
	jr nz,mueve_la_x_guarda		;71e7
mueve_la_x_niega:		; El cambio de signo
	ld a,b			;71e9   ; y con las orientaciones 1 y 2 el sentido se da la vuelta
	neg		;71ea
	ld b,a			;71ec
mueve_la_x_guarda:		; Suma el cociente a la casilla
	ld a,b			;71ed
	add a,(hl)			;71ee   ; el cociente es lo que avanza la marca dentro del plano
	ld (hl),a			;71ef
	ret			;71f0
mueve_la_y_de_la_bola:		; Lo mismo para el eje y, con divisor 4 en el green y 7 fuera, y ademas mueve la ficha de sprites de la sombra
	ld a,(0e0bbh)		;71f1
	or a			;71f4
	ret z			;71f5
	ld hl,0e0b9h		;71f6   ; 0xE0B9 es la x de la marca negra del plano
	ld a,(0e143h)		;71f9   ; la orientacion del hoyo decide otra vez que byte se mueve y con que signo
	or a			;71fc
	jr z,mueve_la_y_signo		;71fd
	dec a			;71ff
	jr z,mueve_la_y_niega		;7200
	dec hl			;7202   ; con las orientaciones 2 y 3 baja a 0xE0B8, que es la y
	dec a			;7203
	jr z,mueve_la_y_signo		;7204
mueve_la_y_niega:		; El cambio de signo por orientacion
	ld a,b			;7206
	neg		;7207   ; y con las orientaciones 1 y 3 el avance va al reves
	ld b,a			;7209
mueve_la_y_signo:		; Se guarda el signo
	xor a			;720a
	ld (0e057h),a		;720b   ; 0xE057 se queda con el signo mientras se divide en positivo
	ld a,b			;720e
	bit 7,a		;720f
	jr z,mueve_la_y_divisor		;7211
	ld (0e057h),a		;7213
	neg		;7216   ; el bucle de abajo solo sabe restar: le hace falta el valor absoluto
	ld b,a			;7218
mueve_la_y_divisor:		; Elige el divisor
	call es_la_pantalla_del_green		;7219
	ld c,004h		;721c   ; escala 4 en el campo y 7 en la pantalla del putt, como en 0x71AF
	jr z,mueve_la_y_ficha		;721e
	ld c,007h		;7220
mueve_la_y_ficha:		; Elige la ficha del jugador
	call de_quien_es_el_turno		;7222
	ld de,0e05ch		;7225   ; cada jugador tiene su resto fino: 0xE05C el primero y 0xE05D el segundo
	jr z,mueve_la_y_suma		;7228
	inc e			;722a
mueve_la_y_suma:		; La suma
	ld a,(de)			;722b
	add a,b			;722c
	ld b,0ffh		;722d   ; B arranca en -1: el bucle cuenta una resta de mas
mueve_la_y_bucle:		; El bucle del cociente
	ld (de),a			;722f   ; igual que en 0x71C5: el resto se guarda antes de cada resta
	sub c			;7230   ; el cociente sale restando el divisor y contando vueltas
	inc b			;7231
	jr nc,mueve_la_y_bucle		;7232
	call es_la_pantalla_del_green		;7234
	jr z,mueve_la_y_guarda		;7237
	ld a,(de)			;7239   ; y otra vez, solo en la pantalla del putt el cociente vuelve al resto fino
	add a,b			;723a
	ld (de),a			;723b
mueve_la_y_guarda:		; Devuelve el signo y lo suma a las dos capas
	ld a,(0e057h)		;723c   ; le devuelve el signo que se le habia quitado en 0x720B
	or a			;723f
	ld a,b			;7240
	jr z,mueve_la_y_capas		;7241
	neg		;7243
mueve_la_y_capas:		; La segunda capa
	ld b,a			;7245
	add a,(hl)			;7246   ; mueve la marca negra del plano
	ld (hl),a			;7247
	inc hl			;7248   ; y cuatro bytes mas alla esta la blanca, que se mueve igual
	inc hl			;7249
	inc hl			;724a
	inc hl			;724b
	ld a,b			;724c
	add a,(hl)			;724d
	ld (hl),a			;724e
	ret			;724f
esta_en_el_green:		; Devuelve Z si 0xE140 vale 5
	ld a,(0e140h)		;7250
	cp 005h		;7253   ; 5 es el codigo de green en 0xE140, la clasificacion del terreno de 0x5BF0
	ret			;7255
es_la_pantalla_del_green:		; Devuelve Z si 0xE146 vale cero, o sea si NO se esta en la pantalla del putt
	ld a,(0e146h)		;7256   ; 0xE146 puesto es la pantalla de cerca, la del putt
	or a			;7259
	ret			;725a

; ----------------------------------------------------------------------
; DATOS tamanos_de_la_bola: Seis parejas de punteros. 0x70B0 indexa con la
;   altura de la bola reducida a 0..5 y pinta los dos guiones en los patrones
;   de sprite 0x1800 y 0x1820: la bola se dibuja mas grande cuanto mas alta va
;   0x725b..0x7273  (24 bytes)
DATA_tamanos_de_la_bola:
	defw 07298h,0729dh	; 725b
	defw 07298h,07298h	; 725f
	defw 07290h,07290h	; 7263
	defw 07288h,07290h	; 7267
	defw 0727eh,07288h	; 726b
	defw 07273h,07288h	; 726f  -> DATA_dibujos_de_la_bola 0x7288

; ----------------------------------------------------------------------
; DATOS dibujos_de_la_bola: Los siete guiones de ocho filas a los que apunta
;   la tabla de arriba, del circulo de siete pixeles (0x7273) al vacio
;   (0x729D), mas el de dos pixeles de 0x72A0
;   0x7273..0x72a6  (51 bytes)
DATA_dibujos_de_la_bola:
	defb 087h,038h,07ch,0feh,0feh,0feh,07ch,038h,019h,000h,000h,086h,018h,03ch,07eh,07eh	; 7273  .8|...|8.....<~~
	defb 03ch,018h,01ah,000h,000h,084h,018h,03ch,03ch,018h,01ch,000h,000h,084h,008h,01ch	; 7283  <......<<.......
	defb 01ch,008h,01ch,000h,000h,002h,018h,01eh,000h,000h,020h,000h,000h,082h,0c0h,0c0h	; 7293  .......... .....
	defb 01eh,000h,000h	; 72a3

; ----------------------------------------------------------------------
; DATOS mezcla_de_rumbos: Cuatro filas de cuatro. 0x6C82 entra con 4 por
;   0xE143 mas 0xE105 y guarda el resultado en 0xE043. Las filas son 0-1-2-3,
;   1-0-3-2, 3-2-0-1 y 2-3-1-0
;   0x72a6..0x72b6  (16 bytes)
DATA_mezcla_de_rumbos:
	defb 000h,001h,002h,003h	; 72a6
	defb 001h,000h,003h,002h	; 72aa
	defb 003h,002h,000h,001h	; 72ae
	defb 002h,003h,001h,000h	; 72b2

; ======================================================================
; CODIGO 0x72b6..0x751e  (616 bytes)
; ======================================================================


suma_con_signo:		; B += C, y deja en DE el resultado con el signo extendido
	ld a,c			;72b6   ; le suma a B lo que traiga C: el desvio del efecto o el empujon del viento
	add a,b			;72b7
	ld b,a			;72b8
	ld e,a			;72b9   ; deja el resultado en DE con el byte alto a 0 o a 0xFF segun el signo
	ld d,000h		;72ba
	ret p			;72bc
	ld d,0ffh		;72bd   ; negativo: el byte alto de DE va a 0xFF
	ret			;72bf
pide_un_sonido:		; No hace nada en el modo de exhibicion; si no, arranca el sonido A
	push af			;72c0   ; en A viene el codigo del sonido: 1 el silbido de la bola, 3 el golpe, 4 la bola en el hoyo, 5 el rodar, 0x86 0x87 y 0x8A las melodias y 0x8D callarse
	ld a,(0e002h)		;72c1   ; 0xE002 marca el modo de exhibicion: la demo se juega en silencio
	or a			;72c4
	jr z,pide_un_sonido_arranca		;72c5
	pop af			;72c7
	ret			;72c8
pide_un_sonido_arranca:		; Cambia al juego de registros alternativo y llama al arranque
	pop af			;72c9
	exx			;72ca   ; el reproductor trabaja con el juego alternativo de registros para no pisar al juego
	call arranca_el_sonido		;72cb
	exx			;72ce
	ret			;72cf
arranca_el_sonido:		; Compara la prioridad -los seis bits bajos del codigo- con la del que suena y, si gana, monta una ficha por canal en 0xE663 o en 0xE679 con el puntero de 0x7538. Tres canales para los codigos 0x87 y superiores, dos para el 1 y uno para los demas
	ld hl,0e663h		;72d0   ; 0xE663 es el byte 2 de la primera ficha: el codigo que suena en el canal A
	ld b,003h		;72d3
	ld c,a			;72d5
	cp 087h		;72d6   ; de 0x87 para arriba son las melodias y ocupan los tres canales
	jr nc,arranca_el_sonido_prioridad		;72d8
	dec b			;72da
	cp 001h		;72db   ; el codigo 1, el silbido de la bola, ocupa dos
	jr z,arranca_el_sonido_prioridad		;72dd
	ld b,001h		;72df
	cp 086h		;72e1   ; el 0x86 es una melodia de un solo canal, y tambien empieza por el primero
	jr z,arranca_el_sonido_prioridad		;72e3
	ld l,079h		;72e5   ; los demas -3, 4 y 5, los efectos- van al TERCER canal, 0xE679, y no pisan la musica
arranca_el_sonido_prioridad:		; La comparacion de prioridades
	ld e,(hl)			;72e7   ; el codigo que hay puesto ahora mismo en ese canal
	ld a,e			;72e8
	and 03fh		;72e9   ; la prioridad son los seis bits bajos del codigo
	ld (hl),a			;72eb
	ld a,c			;72ec
	and 03fh		;72ed
	cp (hl)			;72ef   ; si el que ya suena tiene mas prioridad, la peticion se tira
	ld (hl),e			;72f0
	ret c			;72f1
	add a,a			;72f2   ; por dos, que es lo que ocupa cada puntero de la tabla
	ld de,07538h		;72f3   ; 0x7538 es la tabla de partituras corrida dos bytes: su entrada 0 cae dentro de los periodos de 0x752E
	ex de,hl			;72f6
	call suma_a_a_hl		;72f7
	ex de,hl			;72fa
	dec hl			;72fb   ; de 0xE663 baja a 0xE661, el principio de la ficha
	dec hl			;72fc
arranca_el_sonido_ficha:		; Monta la ficha de un canal
	ld (hl),001h		;72fd   ; cuenta 1: en el proximo cuadro ya se lee la primera orden
	inc hl			;72ff
	ld (hl),001h		;7300   ; y la duracion base tambien a 1
	inc hl			;7302
	ld (hl),c			;7303   ; el byte 2 es el codigo que suena; a cero el canal esta libre
	inc hl			;7304
	ld a,(de)			;7305   ; los bytes 3 y 4 son el puntero a la partitura
	ld (hl),a			;7306
	inc hl			;7307
	inc de			;7308
	ld a,(de)			;7309
	ld (hl),a			;730a
	ld a,005h		;730b
	call suma_a_a_hl		;730d   ; cinco mas: se salta la octava, el volumen y lo que queda de volumen
	ld (hl),000h		;7310   ; el byte 9, la cuenta de vueltas de la orden 0xFE, arranca a cero
	inc hl			;7312
	inc hl			;7313   ; y dos mas para plantarse en la ficha del canal siguiente
	inc de			;7314   ; las melodias de varios canales cogen punteros SEGUIDOS de la tabla
	djnz arranca_el_sonido_ficha		;7315
	ret			;7317
arranca_el_sonido_repite:		; La orden 0xFE de la partitura: vuelve a empezar por donde diga
	inc hl			;7318   ; detras del 0xFE va cuantas vueltas hay que dar
	ld a,(ix+009h)		;7319   ; el byte 9 lleva la cuenta de vueltas ya dadas
	inc a			;731c
	cp (hl)			;731d   ; con la cuenta agotada, el canal se calla
	jp z,corre_el_canal_calla		;731e
	jp m,arranca_el_sonido_encadena		;7321
	dec a			;7324   ; si no, deshace la subida: con el operando a cero la partitura se repite para siempre
arranca_el_sonido_encadena:		; Encadena con el sonido que diga (IX+2)
	ex af,af'			;7325
	ld a,(ix+002h)		;7326   ; arranca otra vez el mismo codigo, o sea que la partitura vuelve a empezar por arriba
	push bc			;7329
	call arranca_el_sonido		;732a
	pop bc			;732d
	ex af,af'			;732e
	ld (ix+009h),a		;732f   ; y le devuelve la cuenta de vueltas, que el arranque acaba de poner a cero
	ret			;7332
toca_el_mezclador:		; Enciende o apaga en el registro 7 del PSG el tono y el ruido del canal C
	ld a,(0e660h)		;7333   ; 0xE660 es la copia en RAM del registro 7 del PSG, que no se puede leer
	ld e,a			;7336
	ld a,c			;7337   ; C vale 1, 3 o 5 segun el canal; aqui queda en 1, 2 o 4
	cp 001h		;7338
	jr z,toca_el_mezclador_apaga		;733a
	dec a			;733c
toca_el_mezclador_apaga:		; Apaga el bit
	rlca			;733d   ; tres desplazamientos: la mascara cae en los bits 3, 4 y 5, que son el ruido de A, B y C
	rlca			;733e
	rlca			;733f
	dec d			;7340   ; con D a uno se apaga el ruido del canal y con D a cero se enciende
	jr z,toca_el_mezclador_enciende		;7341
	cpl			;7343   ; en el registro 7 un bit A UNO es apagar, asi que encender es limpiarlo
	and e			;7344
	jr toca_el_mezclador_escribe		;7345
toca_el_mezclador_enciende:		; Lo enciende
	or e			;7347   ; poner el bit es APAGAR el ruido de ese canal
toca_el_mezclador_escribe:		; Escribe el registro 7
	set 2,a		;7348   ; el bit 2 es el tono del canal C: se apaga de entrada
	bit 5,a		;734a   ; y solo se vuelve a encender si el ruido de C esta apagado: en ese canal o una cosa o la otra
	jr z,escribe_el_mezclador		;734c
	res 2,a		;734e
escribe_el_mezclador:		; Guarda A en 0xE660 y lo manda al registro 7 del PSG
	ld (0e660h),a		;7350
	ld e,a			;7353
	ld a,007h		;7354   ; el 7 es el registro del mezclador del PSG
	jp 00093h		;7356   ; BIOS WRTPSG - Writes data to PSG-register
corre_el_sonido:		; Un paso del reproductor: tres canales, cada uno con su ficha de once bytes a partir de 0xE661
	ld a,(0e660h)		;7359   ; cada paso empieza reponiendo el mezclador desde la copia de 0xE660
	call escribe_el_mezclador		;735c
	di			;735f
	ld c,001h		;7360   ; C empieza en 1, que es el registro del byte alto del tono del canal A
	ld ix,0e661h		;7362   ; la primera ficha, la del canal A
	exx			;7366
	ld b,003h		;7367
	ld de,0000bh		;7369   ; once bytes por ficha: 0xE661, 0xE66C y 0xE677
corre_el_sonido_canal:		; Un canal
	exx			;736c
	ld a,(ix+002h)		;736d   ; el byte 2 de la ficha: a cero el canal esta callado
	push af			;7370
	dec a			;7371   ; el codigo 1, el silbido de la bola, no lee partitura: lo lleva 0x74BE moviendo el periodo
	call z,mueve_el_barrido		;7372
	pop af			;7375
	or a			;7376
	call nz,corre_el_canal		;7377
	di			;737a
	inc c			;737b   ; C sube de dos en dos: 1, 3 y 5, los tres registros de tono grueso
	inc c			;737c
	exx			;737d
	add ix,de		;737e   ; y IX salta a la ficha siguiente, once bytes mas alla
	djnz corre_el_sonido_canal		;7380
	ret			;7382
corre_el_canal:		; Descuenta la duracion de la nota y, cuando se acaba, lee la orden siguiente de la partitura
	di			;7383
	bit 6,a		;7384   ; el bit 6 del codigo dice si el sonido usa ruido; si no lo usa, se apaga el del canal
	ld d,001h		;7386   ; D a uno, o sea que la orden al mezclador es apagar
	call z,toca_el_mezclador		;7388
	di			;738b
	ld a,(ix+002h)		;738c
	or a			;738f   ; con el bit 7 puesto -las melodias- el volumen va cayendo cuadro a cuadro
	jp m,corre_el_canal_apaga		;7390
	dec (ix+000h)		;7393   ; baja la cuenta de la nota: mientras no llegue a cero no hay orden que leer
	ret nz			;7396
corre_el_canal_orden:		; Lee la orden: 0xFE repite, 0xFF corta, 0x2n cambia la duracion base, 0x1n el ruido, y lo demas es una nota
	ld l,(ix+003h)		;7397   ; los bytes 3 y 4 dicen por donde va la partitura
	ld h,(ix+004h)		;739a
	ld a,(hl)			;739d
	cp 0feh		;739e   ; 0xFE repite la partitura y 0xFF calla el canal
	jp z,arranca_el_sonido_repite		;73a0
	jr nc,corre_el_canal_calla		;73a3
	bit 7,(ix+002h)		;73a5   ; con el bit 7 del codigo, la partitura va en el formato largo de las melodias
	jp nz,corre_el_canal_nota_larga		;73a9
	and 0f0h		;73ac
	cp 020h		;73ae   ; una orden 0x2n pone la duracion base de las notas que vienen
	jr nz,corre_el_canal_ruido		;73b0
	ld a,(hl)			;73b2
	and 00fh		;73b3
	ld (ix+001h),a		;73b5
	inc hl			;73b8
corre_el_canal_ruido:		; La orden del ruido
	ld a,(hl)			;73b9   ; una orden 0x1n arma el ruido
	and 0f0h		;73ba
	cp 010h		;73bc
	jr nz,corre_el_canal_salta		;73be
	ld a,(hl)			;73c0
	and 01fh		;73c1   ; se queda con cinco bits, asi que el periodo del ruido sale siempre entre 16 y 31
	ld e,a			;73c3
	ld a,006h		;73c4   ; el 6 es el registro del periodo del ruido
	call 00093h		;73c6   ; BIOS WRTPSG - Writes data to PSG-register
	di			;73c9   ; la BIOS vuelve con las interrupciones abiertas: hay que cerrarlas otra vez
	ld d,000h		;73ca
	call toca_el_mezclador		;73cc   ; y con D a cero se enciende el ruido de este canal en el mezclador
	di			;73cf
	inc hl			;73d0
	ld a,(hl)			;73d1
corre_el_canal_salta:		; El salto de la partitura del canal C
	bit 6,(ix+002h)		;73d2   ; con el bit 6 del codigo y estando en el tercer canal, la orden no lleva nota
	jr z,corre_el_canal_nota		;73d6
	ld a,c			;73d8
	cp 005h		;73d9   ; C vale 5 en el canal C del PSG, el que hace de percusion
	ld a,(hl)			;73db   ; el byte que sigue al ruido es entonces solo el volumen
	jr nz,corre_el_canal_nota		;73dc
	inc hl			;73de
	ld (ix+003h),l		;73df
	ld (ix+004h),h		;73e2
	call corre_el_canal_duracion		;73e5   ; de aqui en adelante, igual que una nota: duracion y volumen
	ret			;73e8
corre_el_canal_nota:		; Toca la nota: el nibble alto es el volumen y detras va el periodo
	and 0f0h		;73e9   ; el nibble alto del primer byte de la nota es el volumen
	ld b,a			;73eb
	xor (hl)			;73ec   ; y el bajo, el nibble alto del periodo
	ld d,a			;73ed
	inc hl			;73ee
	ld e,(hl)			;73ef   ; el segundo byte es el byte bajo del periodo: la nota corta ocupa DOS bytes
	inc hl			;73f0
	ld (ix+003h),l		;73f1
	ld (ix+004h),h		;73f4
	ex de,hl			;73f7
	call escribe_el_periodo		;73f8   ; manda el periodo de doce bits a los dos registros de tono del canal
	ld a,b			;73fb
	rrca			;73fc   ; y baja el volumen a los cuatro bits de menos peso
	rrca			;73fd
	rrca			;73fe
	rrca			;73ff
corre_el_canal_duracion:		; Carga la duracion y el punto en que empieza a bajar el volumen
	ld h,a			;7400
	ld a,(ix+001h)		;7401   ; el byte 1 es la duracion base, la que dejo puesta la orden 0x2n
	ld (ix+000h),a		;7404
	add a,003h		;7407   ; el byte 8 arranca tres por encima: es lo que tarda en empezar a caer el volumen
	ld (ix+008h),a		;7409
	jr corre_el_canal_escribe		;740c
corre_el_canal_calla:		; La orden 0xFF: apaga el canal
	xor a			;740e   ; la orden 0xFF: la cuenta de vueltas se pone a cero
	ld (ix+009h),a		;740f
	ld d,001h		;7412   ; apaga el ruido del canal en el mezclador
	call toca_el_mezclador		;7414
	di			;7417
	xor a			;7418
	ld (ix+002h),a		;7419   ; el byte 2 a cero: la ficha queda libre para el siguiente sonido
	ld h,a			;741c   ; y volumen cero, o sea que el canal se calla
	jr corre_el_canal_escribe		;741d
corre_el_canal_apaga:		; Va bajando el volumen hasta que se acaba la nota
	dec (ix+000h)		;741f   ; baja la cuenta de la nota; al llegar a cero toca leer la orden siguiente
	jp z,corre_el_canal_orden		;7422
	dec (ix+008h)		;7425   ; el byte 8 baja DOS por cuadro hasta alcanzar al 0: son los escalones del ataque
	ld a,(ix+008h)		;7428
	cp (ix+000h)		;742b   ; alcanzado el 0, los dos bajan ya a la par
	jr nz,corre_el_canal_baja		;742e
	cp 003h		;7430   ; y el volumen no se vuelve a mover hasta los tres ultimos cuadros de la nota
	jr c,corre_el_canal_volumen		;7432
	ret			;7434
corre_el_canal_baja:		; Un escalon del volumen
	dec (ix+008h)		;7435
corre_el_canal_volumen:		; Escribe el volumen que queda
	ld a,(ix+007h)		;7438   ; el byte 7 es el volumen que le queda a la nota
	dec a			;743b
	ret m			;743c   ; a cero ya no baja mas
	ld (ix+007h),a		;743d
	ld h,a			;7440
corre_el_canal_escribe:		; Manda el volumen al registro del PSG del canal
	ld a,c			;7441   ; de C -1, 3 o 5- salen los registros 8, 9 y 10, los volumenes de A, B y C
	rrca			;7442
	add a,088h		;7443
	ld e,h			;7445
	jp 00093h		;7446   ; BIOS WRTPSG - Writes data to PSG-register
corre_el_canal_nota_larga:		; La forma larga de la nota: 0xDn cambia el paso, 0xFn la caida, 0xEn el barrido
	and 0f0h		;7449   ; el formato largo lleva hasta tres prefijos, y siempre en este orden: 0xDn, 0xFn y 0xEn
	cp 0d0h		;744b   ; 0xDn pone el paso, la unidad con que se miden las duraciones
	ld a,(hl)			;744d
	jr nz,corre_el_canal_caida		;744e
	and 00fh		;7450
	ld (ix+00ah),a		;7452   ; y se guarda en el byte 10 de la ficha
	inc hl			;7455
	ld a,(hl)			;7456
corre_el_canal_caida:		; La caida
	cp 0f0h		;7457   ; 0xFn pone el volumen de las notas que vienen, en el byte 6
	jr c,corre_el_canal_barrido		;7459
	and 00fh		;745b
	ld (ix+006h),a		;745d   ; de 0xF0 a 0xFD: el 0xFE y el 0xFF ya se han apartado antes
	inc hl			;7460
	ld a,(hl)			;7461
corre_el_canal_barrido:		; El barrido
	cp 0e0h		;7462   ; 0xEn pone la octava en el byte 5: cuantas veces se dobla el periodo
	jr c,corre_el_canal_duracion_nota		;7464
	and 00fh		;7466
	ld (ix+005h),a		;7468   ; doblar el periodo es bajar una octava, asi que 0xE0 es la mas aguda
	inc hl			;746b
	ld a,(hl)			;746c
corre_el_canal_duracion_nota:		; Calcula la duracion multiplicando el paso
	and 00fh		;746d   ; el nibble bajo de la nota larga es el multiplicador de la duracion
	ld b,a			;746f
	ld a,(ix+00ah)		;7470   ; el paso lo dejo puesto el prefijo 0xDn
	jr z,corre_el_canal_periodo		;7473   ; con el multiplicador a cero, la nota dura un paso pelado
corre_el_canal_duracion_bucle:		; El bucle de la multiplicacion
	add a,(ix+00ah)		;7475   ; la duracion es el paso por el multiplicador mas uno
	djnz corre_el_canal_duracion_bucle		;7478
corre_el_canal_periodo:		; Guarda la duracion y saca el periodo de la nota
	ld (ix+001h),a		;747a   ; y esa es la duracion base de la nota
	ld a,(hl)			;747d   ; y ahora si, el byte de la nota larga
	inc hl			;747e
	ld (ix+003h),l		;747f
	ld (ix+004h),h		;7482
	and 0f0h		;7485   ; el nibble alto de la nota larga es el semitono, de 0 a 12
	rrca			;7487
	rrca			;7488
	rrca			;7489
	rrca			;748a
	ld b,a			;748b
	sub 00ch		;748c   ; el semitono 12 no es nota: es un silencio, con el volumen a cero
	ld (ix+007h),a		;748e
	jr z,corre_el_canal_afina		;7491
	ld a,(ix+006h)		;7493   ; los demas suenan al volumen que dejo el prefijo 0xFn
	ld (ix+007h),a		;7496
corre_el_canal_afina:		; Coge de 0x752E el periodo del semitono
	call corre_el_canal_duracion		;7499
	ld a,b			;749c
	ld hl,0752eh		;749d   ; 0x752E son los doce periodos de una octava cromatica
	call suma_a_a_hl		;74a0
	ld l,(hl)			;74a3   ; el periodo de un semitono cabe en un solo byte
	ld h,000h		;74a4
	ld a,(ix+005h)		;74a6   ; el byte 5 dice cuantas octavas hay que bajar
	or a			;74a9
	jr z,escribe_el_periodo		;74aa
	ld b,a			;74ac
corre_el_canal_octava:		; Lo dobla tantas veces como diga la octava
	add hl,hl			;74ad   ; cada doblez es una octava mas grave
	djnz corre_el_canal_octava		;74ae
escribe_el_periodo:		; Manda HL a los dos registros de periodo del canal C
	ld a,c			;74b0   ; C -1, 3 o 5- es el registro del byte alto del periodo del canal
	ld e,h			;74b1
	call 00093h		;74b2   ; BIOS WRTPSG - Writes data to PSG-register
	di			;74b5   ; y otra vez a cerrarlas, que WRTPSG las deja abiertas
	ld a,c			;74b6
	dec a			;74b7   ; y uno menos -0, 2 o 4- el del byte bajo
	ld e,l			;74b8
	call 00093h		;74b9   ; BIOS WRTPSG - Writes data to PSG-register
	di			;74bc
	ret			;74bd
mueve_el_barrido:		; Sube o baja el periodo del canal con el paso de la ficha; al llegar al tope carga otra ficha de 0x751E
	ld hl,0e653h		;74be   ; el silbido de la bola no tiene partitura en la ROM: usa una ficha de cuatro bytes en RAM, 0xE650 para el canal B
	ld de,07521h		;74c1   ; 0x7521 es el ULTIMO byte de la ficha de 0x751E, porque la copia va con lddr
	ld a,c			;74c4
	cp 003h		;74c5
	jr z,mueve_el_barrido_sentido		;74c7
	ld hl,0e657h		;74c9   ; y 0xE654 para el canal A, con la ficha de 0x7522: ocho de diferencia en el periodo, y de ahi el batido
	ld de,07525h		;74cc
mueve_el_barrido_sentido:		; Elige si sube o baja
	ld a,(0e650h)		;74cf   ; 0xE650 lleva el sentido: 0 cargar de nuevo, 1 el tono sube y 2 el tono cae
	cp 001h		;74d2
	jr z,mueve_el_barrido_tope		;74d4   ; lo pone a cero 0x5800 al golpear la bola, y a dos 0x6FCA cuando la bola empieza a caer
	jr c,mueve_el_barrido_carga		;74d6
	dec hl			;74d8   ; 0xE652 lleva empaquetados el volumen -nibble alto- y el byte alto del periodo
	ld a,(hl)			;74d9
	or a			;74da
	jr nz,mueve_el_barrido_sube		;74db
	inc hl			;74dd
	ld de,07529h		;74de   ; agotado el recorrido, carga la ficha de bajada: 0x7526 para el canal B
	ld a,c			;74e1
	cp 003h		;74e2
	jr z,mueve_el_barrido_carga		;74e4
	ld de,0752dh		;74e6   ; y 0x752A para el canal A
	jr mueve_el_barrido_carga		;74e9
mueve_el_barrido_sube:		; Suma ocho al periodo
	inc hl			;74eb
	ld a,(hl)			;74ec   ; ocho mas de periodo por cuadro, que es tono mas GRAVE
	add a,008h		;74ed
	ld (hl),a			;74ef
	dec hl			;74f0
	jr nz,mueve_el_barrido_guarda		;74f1   ; y si desborda, el acarreo sube al byte donde tambien esta el volumen
	inc (hl)			;74f3
mueve_el_barrido_guarda:		; Guarda el puntero en la ficha
	dec hl			;74f4
	ld (ix+003h),l		;74f5   ; la ficha de RAM se le encaja al reproductor como si fuera la partitura del canal
	ld (ix+004h),h		;74f8
	ret			;74fb
mueve_el_barrido_tope:		; Al llegar a 0x8F, corta
	dec hl			;74fc
	ld a,08fh		;74fd   ; 0x8F es el tope: con el volumen 9 y el periodo pasado de cero, ya no sube mas
	cp (hl)			;74ff   ; mientras el byte empaquetado siga por encima de 0x8F, el tono sigue subiendo
	jr c,mueve_el_barrido_baja		;7500
	xor a			;7502
	ld (hl),a			;7503   ; y ahi el byte se queda a cero, o sea volumen cero: se calla
	jr mueve_el_barrido_guarda		;7504
mueve_el_barrido_baja:		; Resta ocho al periodo
	inc hl			;7506
	ld a,(hl)			;7507   ; ocho menos de periodo por cuadro: el tono SUBE
	sub 008h		;7508
	ld (hl),a			;750a
	dec hl			;750b
	jr nz,mueve_el_barrido_guarda		;750c   ; y el prestamo baja del byte de arriba
	dec (hl)			;750e
	jr mueve_el_barrido_guarda		;750f
mueve_el_barrido_carga:		; Copia AL REVES, con lddr, la ficha de cuatro bytes de 0x751E
	push bc			;7511   ; la ficha se copia AL REVES: DE apunta al ULTIMO de sus cuatro bytes
	ex de,hl			;7512
	ld bc,00004h		;7513
	lddr		;7516
	ex de,hl			;7518
	pop bc			;7519
	inc hl			;751a
	inc hl			;751b
	jr mueve_el_barrido_guarda		;751c

; ----------------------------------------------------------------------
; DATOS fichas_del_barrido: Cuatro fichas de cuatro bytes que 0x7511 copia AL
;   REVES -con lddr, o sea que el puntero apunta al ULTIMO byte de cada una- a
;   0xE653 o 0xE657: 0x751E, 0x7522, 0x7526 y 0x752A. 0x74BE las usa para el
;   barrido de tono de los efectos
;   0x751e..0x752e  (16 bytes)
DATA_fichas_del_barrido:
	defb 001h,021h,092h,0c0h	; 751e
	defb 001h,021h,092h,0c8h	; 7522
	defb 002h,021h,090h,000h	; 7526
	defb 002h,021h,090h,008h	; 752a

; ----------------------------------------------------------------------
; DATOS periodos_de_las_notas: Doce bytes, un octava cromatica: 0x6A 0x64 0x5F
;   0x59 0x54 0x50 0x4B 0x47 0x43 0x3F 0x3C 0x38. 0x749D coge el que toca y
;   0x74AD lo dobla tantas veces como diga (IX+5), o sea que baja de octava
;   0x752e..0x753a  (12 bytes)
DATA_periodos_de_las_notas:
	defb 06ah,064h,05fh,059h,054h,050h,04bh,047h,043h,03fh,03ch,038h	; 752e  jd_YTPKGC?<8

; ----------------------------------------------------------------------
; DATOS punteros_de_las_partituras: Quince punteros a las partituras de
;   0x7558, que 0x72F3 indexa desde 0x7538 con el codigo del sonido; las
;   entradas 0 y 1 de esa cuenta caen sobre los dos ultimos periodos de la
;   tabla de arriba. Los sonidos de tres canales cogen tres entradas seguidas:
;   el 0x87 las 7, 8 y 9, el 0x8A las 10, 11 y 12
;   0x753a..0x7558  (30 bytes)
DATA_punteros_de_las_partituras:
	defw 07698h,07698h,0757fh,07558h,07577h,07595h,075b4h,075d0h	; 753a
	defw 075edh,07623h,07649h,07671h,07698h,07698h,07698h	; 754a

; ----------------------------------------------------------------------
; DATOS partituras: Las once partituras a las que apunta la tabla: 0x7558,
;   0x7577, 0x757F, 0x7595, 0x75B4, 0x75D0, 0x75ED, 0x7623, 0x7649, 0x7671 y
;   0x7698. La ultima es un solo byte, 0xFF, o sea callarse
;   0x7558..0x7699  (321 bytes)
DATA_partituras:
	defb 02ah,000h,000h,021h,0f0h,0a0h,0d0h,0a0h,0b0h,0a0h,090h,0a0h,070h,0a0h,050h,0a0h	; 7558  *..!........p.P.
	defb 0d0h,0a0h,0c0h,0a0h,0b0h,0a0h,0a0h,0a0h,090h,0a0h,080h,0a0h,070h,0a0h,0ffh,021h	; 7568  ............p..!
	defb 0a2h,050h,0a1h,0c0h,0a2h,030h,0ffh,021h,011h,0c2h,080h,011h,0d0h,096h,011h,0a0h	; 7578  .P...0.!........
	defb 09dh,011h,080h,090h,000h,000h,011h,0b0h,096h,011h,090h,09dh,0ffh,0d6h,0fch,0e2h	; 7588  ................
	defb 020h,0b0h,0e1h,000h,020h,000h,0e2h,0b0h,020h,0b0h,0e1h,000h,020h,000h,0e2h,0b0h	; 7598   ... ... ... ...
	defb 0d5h,0e1h,070h,090h,070h,090h,070h,090h,070h,090h,073h,0ffh,0d7h,0fch,0e2h,002h	; 75a8  ..p.p.p.p.s.....
	defb 040h,0c1h,070h,0c1h,040h,0c1h,051h,000h,050h,0c0h,090h,0e1h,000h,0c1h,0e2h,092h	; 75b8  @.p.@.Q.P.......
	defb 074h,060h,054h,060h,070h,0c1h,070h,0ffh,0d7h,0fbh,0e2h,072h,0e1h,000h,0c1h,040h	; 75c8  t`T`p.p....r...@
	defb 0c1h,000h,0c1h,021h,0e2h,090h,0e1h,021h,040h,051h,040h,021h,000h,074h,060h,054h	; 75d8  ...!...!@Q@!.t`T
	defb 060h,070h,0c1h,070h,0ffh,0d7h,0fbh,0e2h,072h,0e1h,000h,0c1h,040h,0c1h,000h,0c1h	; 75e8  `p.p....r...@...
	defb 021h,0e2h,090h,0e1h,021h,040h,051h,040h,021h,000h,074h,060h,054h,060h,070h,0c1h	; 75f8  !...!@Q@!.t`T`p.
	defb 070h,0ffh,0d7h,0fah,0e3h,002h,040h,0c1h,040h,0c1h,040h,0c1h,052h,090h,0c1h,090h	; 7608  p.....@.@.@.R...
	defb 0c1h,090h,0c1h,0b4h,0a0h,094h,0a0h,0b0h,0c1h,0b0h,0ffh,0d7h,0fch,0e1h,000h,020h	; 7618  ............... 
	defb 0c0h,040h,050h,0c1h,090h,0c1h,000h,0c1h,091h,0c0h,071h,090h,070h,0c0h,050h,040h	; 7628  .@P.......q.p.P@
	defb 0c1h,070h,0c1h,050h,0c1h,090h,0c1h,000h,0c1h,092h,070h,0c0h,050h,040h,0c1h,050h	; 7638  .p.P......p.P@.P
	defb 0ffh,0d7h,0fbh,0e2h,000h,0e3h,0b1h,0a0h,090h,0c1h,0e2h,000h,0c1h,050h,0c1h,000h	; 7648  .............P..
	defb 0c1h,041h,000h,041h,050h,070h,0c1h,040h,0c1h,050h,0c1h,0e1h,000h,0c1h,0e2h,000h	; 7658  .A.APp.@.P......
	defb 0c1h,0e1h,002h,0e2h,0a1h,0a0h,0a2h,090h,0ffh,0d7h,0fah,0e2h,090h,0b1h,0e1h,000h	; 7668  ................
	defb 0e3h,051h,0c0h,001h,0c0h,091h,0c0h,001h,0c0h,041h,0c0h,001h,0c0h,071h,0c0h,001h	; 7678  .Q.......A...q..
	defb 0c0h,051h,0c0h,001h,0c0h,091h,0c0h,001h,0c0h,040h,020h,000h,001h,040h,050h,0ffh	; 7688  .Q.......@ ..@P.
	defb 0ffh	; 7698

; ----------------------------------------------------------------------
; DATOS guion_sprites_del_juego: Guion de VRAM: 1024 bytes de patrones de
;   sprite (0x18C0-0x1CBF, 32 sprites de 16x16) y sus atributos 0x3B04-0x3B27.
;   Va en linea tras el call de 0x4989
;   0x7699..0x78ff  (614 bytes)
DATA_guion_sprites_del_juego:
	defb 058h,0c0h,084h,0f8h,0f8h,0b0h,080h,01ch,000h,002h,018h,081h,01ch,002h,016h,002h	; 7699  X...............
	defb 033h,086h,071h,067h,0efh,0feh,0fch,0f8h,009h,000h,08ah,080h,0c0h,0e0h,0f0h,07ch	; 76a9  3.qg...........|
	defb 03fh,01fh,00fh,006h,000h,086h,070h,0f8h,0c8h,0c8h,090h,060h,01ah,000h,081h,060h	; 76b9  ?.....p....`...`
	defb 004h,0f0h,087h,0e0h,061h,0f1h,071h,031h,01fh,006h,006h,000h,088h,030h,078h,078h	; 76c9  ....a.q1.....0xx
	defb 0f8h,0f0h,0e0h,0c0h,080h,006h,000h,086h,006h,004h,0cch,0d0h,070h,030h,01ah,000h	; 76d9  ............p0..
	defb 093h,060h,0e0h,0f0h,0f0h,0f0h,070h,078h,038h,03ch,01ch,00eh,007h,003h,001h,001h	; 76e9  .`....px8<......
	defb 000h,080h,0c0h,0c0h,004h,0e0h,004h,0c0h,002h,040h,083h,0c0h,0c0h,080h,082h,01ch	; 76f9  .........@......
	defb 03eh,004h,07fh,006h,0ffh,081h,007h,004h,000h,081h,070h,005h,0f0h,082h,0e0h,0c0h	; 7709  >.........p.....
	defb 004h,080h,003h,000h,084h,03eh,03fh,07fh,07fh,005h,0ffh,082h,01fh,007h,006h,000h	; 7719  .....>?.........
	defb 004h,0e0h,003h,0f0h,082h,0f8h,0f0h,006h,000h,088h,080h,040h,020h,010h,008h,004h	; 7729  ...........@ ...
	defb 002h,001h,010h,000h,088h,080h,040h,020h,010h,008h,004h,002h,001h,085h,038h,04ch	; 7739  ......@ ......8L
	defb 08ch,0bch,078h,01bh,000h,090h,064h,0f4h,0f6h,0f6h,0feh,07eh,03eh,01fh,01fh,00fh	; 7749  ..x...d....~>...
	defb 007h,003h,003h,001h,001h,000h,00dh,000h,083h,080h,0c0h,0c0h,007h,000h,089h,00eh	; 7759  ................
	defb 01fh,03fh,07fh,07fh,0f0h,0f1h,0e0h,060h,008h,000h,088h,080h,0c0h,0e0h,0f0h,060h	; 7769  .?.....`.......`
	defb 080h,000h,000h,00ah,000h,086h,03eh,038h,07eh,07eh,0f8h,060h,010h,000h,085h,00ch	; 7779  ......>8~~.`....
	defb 01eh,03fh,07fh,079h,004h,070h,084h,0f8h,0fch,0feh,01eh,005h,000h,005h,080h,009h	; 7789  .?.y.p..........
	defb 000h,083h,01ch,03fh,03fh,003h,07fh,004h,0ffh,007h,000h,002h,0c0h,005h,0e0h,081h	; 7799  ...??...........
	defb 0c0h,007h,000h,092h,0ffh,0ffh,0feh,07eh,03eh,01eh,00fh,00fh,00fh,01eh,01dh,01dh	; 77a9  .......~>.......
	defb 01dh,039h,038h,030h,080h,080h,004h,0c0h,003h,060h,004h,0c0h,083h,080h,000h,000h	; 77b9  .980.....`......
	defb 085h,007h,007h,0f1h,0fch,07eh,00bh,000h,083h,080h,0e0h,0f0h,00dh,000h,08dh,0c0h	; 77c9  .....~..........
	defb 060h,020h,000h,000h,00ch,01ch,038h,038h,070h,070h,060h,0c0h,013h,000h,089h,01eh	; 77d9  ` ....88pp`.....
	defb 03fh,07fh,07fh,0ffh,0ffh,0ffh,07eh,038h,009h,000h,004h,080h,00ah,000h,084h,00ch	; 77e9  ?.....~8........
	defb 00eh,01fh,03fh,004h,07fh,005h,0ffh,081h,0feh,005h,000h,087h,080h,0e0h,0f0h,0e0h	; 77f9  ..?.............
	defb 0c0h,080h,080h,006h,000h,081h,03fh,003h,07fh,004h,0ffh,081h,03fh,007h,000h,081h	; 7809  ......?.....?...
	defb 080h,004h,0c0h,004h,0e0h,007h,000h,08eh,0dfh,05fh,06fh,037h,017h,01bh,037h,02fh	; 7819  ........._o7..7/
	defb 02ch,038h,076h,07eh,0e0h,0c0h,004h,000h,005h,080h,009h,000h,085h,007h,087h,0f1h	; 7829  ,8v~............
	defb 07ch,01eh,00bh,000h,083h,0c0h,0e0h,0f0h,00dh,000h,010h,080h,010h,000h,085h,01ch	; 7839  |...............
	defb 03ch,07ch,0f8h,0f0h,005h,080h,016h,000h,089h,070h,07ch,07eh,0efh,0e7h,0e3h,0f9h	; 7849  <|.......p|~....
	defb 070h,060h,00ah,000h,003h,080h,081h,0c0h,009h,000h,083h,00ch,01fh,03fh,005h,07fh	; 7859  p`...........?..
	defb 005h,0ffh,081h,00fh,003h,000h,08fh,0c0h,0f0h,0f8h,0f8h,0f0h,0f0h,0e0h,0c0h,0c0h	; 7869  ................
	defb 080h,080h,080h,000h,000h,000h,085h,03ch,03fh,03fh,07fh,07fh,004h,0ffh,081h,0efh	; 7879  .......<??......
	defb 007h,000h,084h,0e0h,0e0h,0f0h,0f0h,005h,0f8h,006h,000h,002h,0f7h,003h,077h,088h	; 7889  ..............w.
	defb 06eh,05eh,03ch,038h,03ch,074h,070h,020h,003h,000h,083h,0c0h,0c0h,080h,00dh,000h	; 7899  n^<8<tp ........
	defb 086h,006h,0e7h,017h,068h,004h,01eh,00ch,000h,081h,080h,00dh,000h,086h,030h,048h	; 78a9  ....h.........0H
	defb 098h,098h,0f8h,070h,01ah,000h,08ch,018h,018h,032h,035h,026h,063h,0e1h,0f1h,07ch	; 78b9  ...p.....25&c..|
	defb 03eh,03ch,018h,009h,000h,085h,060h,0a0h,0c0h,0e0h,070h,006h,000h,080h,07bh,004h	; 78c9  ><....`...p...{.
	defb 0a4h,09dh,042h,038h,00fh,0a9h,051h,03ch,001h,08dh,038h,040h,00ah,079h,038h,044h	; 78d9  ..B8..Q<..8@.y8D
	defb 001h,07bh,03ah,048h,00ah,089h,034h,04ch,00fh,095h,031h,050h,008h,09dh,033h,054h	; 78e9  .{:H..4L..1P..3T
	defb 00ah,0abh,034h,058h,00fh,000h	; 78f9

; ----------------------------------------------------------------------
; DATOS cuadros_del_golfista: Siete cuadros de veintisiete bytes, o sea nueve
;   sprites de tres bytes (y, x, patron) cada uno. 0x5862 elige el cuadro
;   sumando 27 tantas veces como diga el numero de cuadro, 0x5875 le suma la
;   posicion de 0xE162/0xE163 -salvo a los que valen 0xCF, que son los sprites
;   escondidos- y 0x589C los escribe de tres en tres a partir de la VRAM
;   0x3B04. Los dos ultimos bytes del septimo cuadro son ademas la entrada 0
;   de la tabla siguiente
;   0x78ff..0x79bc  (189 bytes)
DATA_cuadros_del_golfista:
	defb 00ch,008h,018h	; 78ff
	defb 0cfh,000h,000h	; 7902
	defb 010h,005h,01ch	; 7905
	defb 009h,00ch,044h	; 7908
	defb 00bh,00eh,048h	; 790b
	defb 019h,008h,030h	; 790e
	defb 025h,006h,034h	; 7911
	defb 02dh,007h,054h	; 7914
	defb 03bh,008h,058h	; 7917
	defb 013h,0fdh,038h	; 791a
	defb 00dh,0fbh,020h	; 791d
	defb 019h,009h,024h	; 7920
	defb 009h,00ch,044h	; 7923
	defb 00bh,00eh,048h	; 7926
	defb 019h,008h,030h	; 7929
	defb 025h,006h,034h	; 792c
	defb 02dh,007h,054h	; 792f
	defb 03bh,008h,058h	; 7932
	defb 029h,00ch,028h	; 7935
	defb 0cfh,000h,000h	; 7938
	defb 01ah,00bh,02ch	; 793b
	defb 009h,00ch,044h	; 793e
	defb 00bh,00eh,048h	; 7941
	defb 019h,008h,030h	; 7944
	defb 025h,006h,034h	; 7947
	defb 02dh,007h,054h	; 794a
	defb 03bh,008h,058h	; 794d
	defb 02dh,016h,038h	; 7950
	defb 039h,025h,03ch	; 7953
	defb 01dh,00ch,040h	; 7956
	defb 009h,00ch,044h	; 7959
	defb 00bh,00eh,048h	; 795c
	defb 019h,008h,04ch	; 795f
	defb 025h,005h,050h	; 7962
	defb 02dh,007h,054h	; 7965
	defb 03bh,008h,058h	; 7968
	defb 0cfh,000h,000h	; 796b
	defb 0cfh,000h,000h	; 796e
	defb 019h,010h,05ch	; 7971
	defb 012h,011h,060h	; 7974
	defb 0cfh,000h,000h	; 7977
	defb 018h,009h,064h	; 797a
	defb 026h,007h,068h	; 797d
	defb 02fh,009h,06ch	; 7980
	defb 03bh,008h,070h	; 7983
	defb 002h,009h,074h	; 7986
	defb 0f8h,009h,078h	; 7989
	defb 012h,008h,07ch	; 798c
	defb 011h,011h,060h	; 798f
	defb 0cfh,000h,000h	; 7992
	defb 018h,00ah,080h	; 7995
	defb 025h,007h,084h	; 7998
	defb 02fh,009h,088h	; 799b
	defb 03ah,008h,08ch	; 799e
	defb 011h,00bh,038h	; 79a1
	defb 020h,017h,090h	; 79a4
	defb 00fh,006h,094h	; 79a7
	defb 011h,011h,060h	; 79aa
	defb 0cfh,000h,000h	; 79ad
	defb 018h,00ah,080h	; 79b0
	defb 025h,007h,084h	; 79b3
	defb 02fh,009h,088h	; 79b6
	defb 03ah,008h,08ch	; 79b9

; ----------------------------------------------------------------------
; DATOS punteros_cabecera_del_hoyo: Nueve punteros al guion de la cabecera de
;   cada hoyo, que 0x5391 indexa con 0xE100 desde 0x79BA
;   0x79bc..0x79ce  (18 bytes)
DATA_punteros_cabecera_del_hoyo:
	defw 06379h,06465h,06512h,065d7h,0669ch,06739h,06806h,068d3h	; 79bc
	defw 06988h	; 79cc  -> DATA_hoyo_9_cabecera

; ----------------------------------------------------------------------
; DATOS punteros_rejilla_del_hoyo: Nueve punteros a la rejilla de cada hoyo,
;   que 0x53A2 indexa con 0xE100 desde 0x79CC. Cada uno cae justo detras del
;   0x80 con que acaba la cabecera del mismo hoyo
;   0x79ce..0x79e0  (18 bytes)
DATA_punteros_rejilla_del_hoyo:
	defw 063a4h,06471h,0651eh,065e3h,066a8h,06745h,06812h,068dfh	; 79ce
	defw 06994h	; 79de  -> DATA_hoyo_9_rejilla

; ----------------------------------------------------------------------
; DATOS acercamientos_bajos: Cinco punteros, uno por banda de la vista de
;   cerca (0xE128 de 1 a 5), a la tabla de las casillas de codigo 0x01 a 0x28.
;   Las bandas 1 y 2 comparten la de 0x79EA y las 3, 4 y 5 la de 0x7A3A
;   0x79e0..0x79ea  (10 bytes)
DATA_acercamientos_bajos:
	defw 079eah,079eah,07a3ah,07a3ah,07a3ah	; 79e0

; ----------------------------------------------------------------------
; DATOS casillas_bajas_cerca: Cuarenta punteros -uno por codigo, del 0x01 al
;   0x28- a los bloques de 0x7A8A. Los usan las bandas 1 y 2, las de bloques
;   de 4x2 tiles
;   0x79ea..0x7a3a  (80 bytes)
DATA_casillas_bajas_cerca:
	defw 07a8ah,07a92h,07a9ah,07aa2h,07aaah,07ab2h,07abah,07ac2h	; 79ea
	defw 07acah,07ad2h,07adah,07ae2h,07aeah,07af2h,07afah,07b02h	; 79fa
	defw 07b0ah,07b12h,07b1ah,07b22h,07b2ah,07b32h,07b3ah,07b42h	; 7a0a
	defw 07b4ah,07b52h,07b5ah,07b62h,07b6ah,07b72h,07b7ah,07b82h	; 7a1a
	defw 07b8ah,07b92h,07b9ah,07ba2h,07baah,07bb2h,07bbah,07bc2h	; 7a2a

; ----------------------------------------------------------------------
; DATOS casillas_bajas_lejos: Los mismos cuarenta codigos para las bandas 3, 4
;   y 5, que dibujan bloques de 4x4 tiles
;   0x7a3a..0x7a8a  (80 bytes)
DATA_casillas_bajas_lejos:
	defw 07bcah,07bd4h,07bdeh,07be8h,07bf2h,07bfch,07c06h,07c10h	; 7a3a
	defw 07c1ah,07c2ah,07c3ah,07c4ah,07c5ah,07c6ah,07c7ah,07c8ah	; 7a4a
	defw 07c9ah,07caah,07cbah,07ccah,07cdah,07ce4h,07ceeh,07cf8h	; 7a5a
	defw 07d02h,07d0ch,07d16h,07d20h,07d2ah,07d3ah,07d4ah,07d5ah	; 7a6a
	defw 07d6ah,07d7ah,07d8ah,07d9ah,07daah,07dbah,07dcah,07ddah	; 7a7a

; ----------------------------------------------------------------------
; DATOS bloques_de_casillas_bajas: Los dibujos de las casillas 0x01 a 0x28.
;   0x5597 los lee en grupos de CUATRO tiles -una fila del bloque, que es de
;   cuatro de ancho- hasta juntar dos filas (bandas 1 y 2) o cuatro (bandas 3,
;   4 y 5). Un grupo que empieza por 0x00 es un atajo: el byte siguiente,
;   repetido cuatro veces, dos filas seguidas
;   0x7a8a..0x7dea  (864 bytes)
DATA_bloques_de_casillas_bajas:
	defb 033h,033h,033h,033h	; 7a8a
	defb 035h,03dh,045h,04dh	; 7a8e
	defb 034h,034h,034h,034h	; 7a92
	defb 036h,03eh,046h,04eh	; 7a96
	defb 035h,03dh,045h,04dh	; 7a9a
	defb 034h,034h,034h,034h	; 7a9e
	defb 036h,03eh,046h,04eh	; 7aa2
	defb 033h,033h,033h,033h	; 7aa6
	defb 052h,04ah,042h,03ah	; 7aaa
	defb 033h,033h,033h,033h	; 7aae
	defb 051h,049h,041h,039h	; 7ab2
	defb 034h,034h,034h,034h	; 7ab6
	defb 034h,034h,034h,034h	; 7aba
	defb 052h,04ah,042h,03ah	; 7abe
	defb 033h,033h,033h,033h	; 7ac2
	defb 051h,049h,041h,039h	; 7ac6
	defb 013h,033h,033h,033h	; 7aca
	defb 034h,013h,033h,033h	; 7ace
	defb 014h,034h,034h,034h	; 7ad2
	defb 033h,014h,034h,034h	; 7ad6
	defb 034h,034h,013h,033h	; 7ada
	defb 034h,034h,034h,013h	; 7ade
	defb 033h,033h,014h,034h	; 7ae2
	defb 033h,033h,033h,014h	; 7ae6
	defb 033h,033h,033h,011h	; 7aea
	defb 033h,033h,011h,034h	; 7aee
	defb 034h,034h,034h,012h	; 7af2
	defb 034h,034h,012h,033h	; 7af6
	defb 033h,011h,034h,034h	; 7afa
	defb 011h,034h,034h,034h	; 7afe
	defb 034h,012h,033h,033h	; 7b02
	defb 012h,033h,033h,033h	; 7b06
	defb 033h,033h,001h,003h	; 7b0a
	defb 001h,003h,034h,034h	; 7b0e
	defb 034h,034h,002h,004h	; 7b12
	defb 002h,004h,033h,033h	; 7b16
	defb 006h,008h,033h,033h	; 7b1a
	defb 034h,034h,006h,008h	; 7b1e
	defb 005h,007h,034h,034h	; 7b22
	defb 033h,033h,005h,007h	; 7b26
	defb 032h,032h,032h,032h	; 7b2a
	defb 037h,03fh,047h,04fh	; 7b2e
	defb 033h,033h,033h,033h	; 7b32
	defb 038h,040h,048h,050h	; 7b36
	defb 037h,03fh,047h,04fh	; 7b3a
	defb 033h,033h,033h,033h	; 7b3e
	defb 038h,040h,048h,050h	; 7b42
	defb 032h,032h,032h,032h	; 7b46
	defb 054h,04ch,044h,03ch	; 7b4a
	defb 032h,032h,032h,032h	; 7b4e
	defb 053h,04bh,043h,03bh	; 7b52
	defb 033h,033h,033h,033h	; 7b56
	defb 033h,033h,033h,033h	; 7b5a
	defb 054h,04ch,044h,03ch	; 7b5e
	defb 032h,032h,032h,032h	; 7b62
	defb 053h,04bh,043h,03bh	; 7b66
	defb 027h,032h,032h,032h	; 7b6a
	defb 033h,027h,032h,032h	; 7b6e
	defb 028h,033h,033h,033h	; 7b72
	defb 032h,028h,033h,033h	; 7b76
	defb 033h,033h,027h,032h	; 7b7a
	defb 033h,033h,033h,027h	; 7b7e
	defb 032h,032h,028h,033h	; 7b82
	defb 032h,032h,032h,028h	; 7b86
	defb 032h,032h,032h,025h	; 7b8a
	defb 032h,032h,025h,033h	; 7b8e
	defb 033h,033h,033h,026h	; 7b92
	defb 033h,033h,026h,032h	; 7b96
	defb 032h,025h,033h,033h	; 7b9a
	defb 025h,033h,033h,033h	; 7b9e
	defb 033h,026h,032h,032h	; 7ba2
	defb 026h,032h,032h,032h	; 7ba6
	defb 032h,032h,015h,017h	; 7baa
	defb 015h,017h,033h,033h	; 7bae
	defb 033h,033h,016h,018h	; 7bb2
	defb 016h,018h,032h,032h	; 7bb6
	defb 01ah,01ch,032h,032h	; 7bba
	defb 033h,033h,01ah,01ch	; 7bbe
	defb 019h,01bh,033h,033h	; 7bc2
	defb 032h,032h,019h,01bh	; 7bc6
	defb 000h,033h,033h,033h	; 7bca
	defb 001h,003h,001h,003h	; 7bce
	defb 034h,034h,000h,034h	; 7bd2
	defb 034h,034h,002h,004h	; 7bd6
	defb 002h,004h,033h,033h	; 7bda
	defb 033h,033h,001h,003h	; 7bde
	defb 001h,003h,034h,034h	; 7be2
	defb 000h,034h,034h,034h	; 7be6
	defb 002h,004h,002h,004h	; 7bea
	defb 033h,033h,000h,033h	; 7bee
	defb 005h,007h,034h,034h	; 7bf2
	defb 033h,033h,005h,007h	; 7bf6
	defb 000h,033h,006h,008h	; 7bfa
	defb 033h,033h,034h,034h	; 7bfe
	defb 006h,008h,000h,034h	; 7c02
	defb 000h,034h,005h,007h	; 7c06
	defb 034h,034h,033h,033h	; 7c0a
	defb 005h,007h,000h,033h	; 7c0e
	defb 006h,008h,033h,033h	; 7c12
	defb 034h,034h,006h,008h	; 7c16
	defb 009h,033h,033h,033h	; 7c1a
	defb 00bh,033h,033h,033h	; 7c1e
	defb 034h,009h,033h,033h	; 7c22
	defb 034h,00bh,033h,033h	; 7c26
	defb 00ah,034h,034h,034h	; 7c2a
	defb 00ch,034h,034h,034h	; 7c2e
	defb 033h,00ah,034h,034h	; 7c32
	defb 033h,00ch,034h,034h	; 7c36
	defb 034h,034h,009h,033h	; 7c3a
	defb 034h,034h,00bh,033h	; 7c3e
	defb 034h,034h,034h,009h	; 7c42
	defb 034h,034h,034h,00bh	; 7c46
	defb 033h,033h,00ah,034h	; 7c4a
	defb 033h,033h,00ch,034h	; 7c4e
	defb 033h,033h,033h,00ah	; 7c52
	defb 033h,033h,033h,00ch	; 7c56
	defb 033h,033h,033h,00dh	; 7c5a
	defb 033h,033h,033h,00fh	; 7c5e
	defb 033h,033h,00dh,034h	; 7c62
	defb 033h,033h,00fh,034h	; 7c66
	defb 034h,034h,034h,00eh	; 7c6a
	defb 034h,034h,034h,010h	; 7c6e
	defb 034h,034h,00eh,033h	; 7c72
	defb 034h,034h,010h,033h	; 7c76
	defb 033h,00dh,034h,034h	; 7c7a
	defb 033h,00fh,034h,034h	; 7c7e
	defb 00dh,034h,034h,034h	; 7c82
	defb 00fh,034h,034h,034h	; 7c86
	defb 034h,00eh,033h,033h	; 7c8a
	defb 034h,010h,033h,033h	; 7c8e
	defb 00eh,033h,033h,033h	; 7c92
	defb 010h,033h,033h,033h	; 7c96
	defb 033h,033h,033h,011h	; 7c9a
	defb 033h,033h,011h,034h	; 7c9e
	defb 033h,011h,034h,034h	; 7ca2
	defb 011h,034h,034h,034h	; 7ca6
	defb 034h,034h,034h,012h	; 7caa
	defb 034h,034h,012h,033h	; 7cae
	defb 034h,012h,033h,033h	; 7cb2
	defb 012h,033h,033h,033h	; 7cb6
	defb 013h,033h,033h,033h	; 7cba
	defb 034h,013h,033h,033h	; 7cbe
	defb 034h,034h,013h,033h	; 7cc2
	defb 034h,034h,034h,013h	; 7cc6
	defb 014h,034h,034h,034h	; 7cca
	defb 033h,014h,034h,034h	; 7cce
	defb 033h,033h,014h,034h	; 7cd2
	defb 033h,033h,033h,014h	; 7cd6
	defb 000h,032h,032h,032h	; 7cda
	defb 015h,017h,015h,017h	; 7cde
	defb 033h,033h,000h,033h	; 7ce2
	defb 033h,033h,016h,018h	; 7ce6
	defb 016h,018h,032h,032h	; 7cea
	defb 032h,032h,015h,017h	; 7cee
	defb 015h,017h,033h,033h	; 7cf2
	defb 000h,033h,033h,033h	; 7cf6
	defb 016h,018h,016h,018h	; 7cfa
	defb 032h,032h,000h,032h	; 7cfe
	defb 019h,01bh,033h,033h	; 7d02
	defb 032h,032h,019h,01bh	; 7d06
	defb 000h,032h,01ah,01ch	; 7d0a
	defb 032h,032h,033h,033h	; 7d0e
	defb 01ah,01ch,000h,033h	; 7d12
	defb 000h,033h,019h,01bh	; 7d16
	defb 033h,033h,032h,032h	; 7d1a
	defb 019h,01bh,000h,032h	; 7d1e
	defb 01ah,01ch,032h,032h	; 7d22
	defb 033h,033h,01ah,01ch	; 7d26
	defb 01dh,032h,032h,032h	; 7d2a
	defb 01fh,032h,032h,032h	; 7d2e
	defb 033h,01dh,032h,032h	; 7d32
	defb 033h,01fh,032h,032h	; 7d36
	defb 01eh,033h,033h,033h	; 7d3a
	defb 020h,033h,033h,033h	; 7d3e
	defb 032h,01eh,033h,033h	; 7d42
	defb 032h,020h,033h,033h	; 7d46
	defb 033h,033h,01dh,032h	; 7d4a
	defb 033h,033h,01fh,032h	; 7d4e
	defb 033h,033h,033h,01dh	; 7d52
	defb 033h,033h,033h,01fh	; 7d56
	defb 032h,032h,01eh,033h	; 7d5a
	defb 032h,032h,020h,033h	; 7d5e
	defb 032h,032h,032h,01eh	; 7d62
	defb 032h,032h,032h,020h	; 7d66
	defb 032h,032h,032h,021h	; 7d6a
	defb 032h,032h,032h,023h	; 7d6e
	defb 032h,032h,021h,033h	; 7d72
	defb 032h,032h,023h,033h	; 7d76
	defb 033h,033h,033h,022h	; 7d7a
	defb 033h,033h,033h,024h	; 7d7e
	defb 033h,033h,022h,032h	; 7d82
	defb 033h,033h,024h,032h	; 7d86
	defb 032h,021h,033h,033h	; 7d8a
	defb 032h,023h,033h,033h	; 7d8e
	defb 021h,033h,033h,033h	; 7d92
	defb 023h,033h,033h,033h	; 7d96
	defb 033h,022h,032h,032h	; 7d9a
	defb 033h,024h,032h,032h	; 7d9e
	defb 022h,032h,032h,032h	; 7da2
	defb 024h,032h,032h,032h	; 7da6
	defb 032h,032h,032h,025h	; 7daa
	defb 032h,032h,025h,033h	; 7dae
	defb 032h,025h,033h,033h	; 7db2
	defb 025h,033h,033h,033h	; 7db6
	defb 033h,033h,033h,026h	; 7dba
	defb 033h,033h,026h,032h	; 7dbe
	defb 033h,026h,032h,032h	; 7dc2
	defb 026h,032h,032h,032h	; 7dc6
	defb 027h,032h,032h,032h	; 7dca
	defb 033h,027h,032h,032h	; 7dce
	defb 033h,033h,027h,032h	; 7dd2
	defb 033h,033h,033h,027h	; 7dd6
	defb 028h,033h,033h,033h	; 7dda
	defb 032h,028h,033h,033h	; 7dde
	defb 032h,032h,028h,033h	; 7de2
	defb 032h,032h,032h,028h	; 7de6

; ----------------------------------------------------------------------
; DATOS bloque_de_la_casilla_c4: Diez bytes: el bloque que 0x5566 usa
;   directamente cuando el codigo de la casilla es 0xC4, sin pasar por ninguna
;   tabla. Son dos filas de cuatro tiles 0x33 y una tercera con 0x33 0x33 0xC0
;   0x33, y luego el 0x00 que corta
;   0x7dea..0x7df4  (10 bytes)
DATA_bloque_de_la_casilla_c4:
	defb 033h,033h,033h,033h	; 7dea
	defb 033h,033h,0c0h,033h	; 7dee
	defb 000h,033h	; 7df2

; ----------------------------------------------------------------------
; DATOS acercamientos_altos: Cinco punteros, uno por banda, a la tabla de las
;   casillas de codigo 0x29 a 0x34. Los indexa 0x5578, y cada uno apunta
;   dentro de la propia tabla de punteros que sigue
;   0x7df4..0x7dfe  (10 bytes)
DATA_acercamientos_altos:
	defw 07dfeh,07e16h,07e2eh,07e46h,07e5eh	; 7df4

; ----------------------------------------------------------------------
; DATOS casillas_altas: Doce punteros por banda y cinco bandas: sesenta en
;   total, uno por cada codigo del 0x29 al 0x34 en cada nivel de acercamiento.
;   0x5588 los indexa con el codigo menos 0x28
;   0x7dfe..0x7e76  (120 bytes)
DATA_casillas_altas:
	defw 07e9ah,07ea2h,07eaah,07eb2h,07f1eh,07f26h,07f2eh,07f36h	; 7dfe
	defw 07e82h,07e78h,07e7ch,07e80h,07ebah,07ec2h,07eaah,07eb2h	; 7e0e
	defw 07f3eh,07f46h,07f2eh,07f36h,07e82h,07e78h,07e7ch,07e80h	; 7e1e
	defw 07edeh,07eeeh,07ecah,07ed4h,07f62h,07f6ch,07f4eh,07f58h	; 7e2e
	defw 07e8ah,07e76h,07e7ah,07e7eh,07edeh,07eeeh,07efeh,07f0eh	; 7e3e
	defw 07f62h,07f6ch,07f76h,07f80h,07e8ah,07e76h,07e7ah,07e7eh	; 7e4e
	defw 07edeh,07eeeh,07efeh,07f0eh,07f62h,07f6ch,07f76h,07f80h	; 7e5e
	defw 07e8ah,07e76h,07e7ah,07e7eh	; 7e6e  -> 0x7e8a DATA_bloques_de_casillas_altas 0x7e7a 0x7e7e

; ----------------------------------------------------------------------
; DATOS bloques_de_casillas_altas: Los dibujos de las casillas 0x29 a 0x34,
;   con el mismo formato de grupos de cuatro tiles que los de 0x7A8A. Aqui
;   estan el green y la bandera: los codigos 0x29 y 0x2A son los que 0x5573
;   marca en 0xE145
;   0x7e76..0x7f8a  (276 bytes)
DATA_bloques_de_casillas_altas:
	defb 000h,032h,000h,032h	; 7e76
	defb 000h,033h,000h,033h	; 7e7a
	defb 000h,034h,000h,034h	; 7e7e
	defb 032h,098h,09ch,099h	; 7e82
	defb 032h,09ah,09dh,09bh	; 7e86
	defb 032h,0a4h,0a5h,032h	; 7e8a
	defb 09eh,0a6h,0a7h,09fh	; 7e8e
	defb 0a0h,0a8h,0a9h,0a1h	; 7e92
	defb 0a2h,0aah,0abh,0a3h	; 7e96
	defb 034h,034h,034h,05bh	; 7e9a
	defb 034h,055h,059h,05ch	; 7e9e
	defb 05dh,034h,034h,034h	; 7ea2
	defb 059h,059h,056h,034h	; 7ea6
	defb 034h,057h,05ah,05ah	; 7eaa
	defb 034h,034h,034h,034h	; 7eae
	defb 05ah,05ah,058h,034h	; 7eb2
	defb 034h,034h,034h,034h	; 7eb6
	defb 034h,034h,034h,062h	; 7eba
	defb 05eh,0ach,0ach,063h	; 7ebe
	defb 064h,034h,034h,034h	; 7ec2
	defb 0ach,0ach,0ach,05fh	; 7ec6
	defb 060h,0adh,0adh,0adh	; 7eca
	defb 034h,034h,034h,034h	; 7ece
	defb 000h,034h,0adh,0adh	; 7ed2
	defb 0adh,061h,034h,034h	; 7ed6
	defb 034h,034h,000h,034h	; 7eda
	defb 034h,034h,034h,075h	; 7ede
	defb 034h,034h,034h,075h	; 7ee2
	defb 034h,06bh,06fh,076h	; 7ee6
	defb 065h,033h,033h,077h	; 7eea
	defb 07ah,034h,034h,034h	; 7eee
	defb 034h,034h,034h,034h	; 7ef2
	defb 078h,070h,06ch,034h	; 7ef6
	defb 079h,033h,033h,066h	; 7efa
	defb 067h,033h,033h,033h	; 7efe
	defb 069h,06dh,033h,033h	; 7f02
	defb 034h,034h,071h,073h	; 7f06
	defb 034h,034h,034h,034h	; 7f0a
	defb 033h,033h,033h,068h	; 7f0e
	defb 033h,033h,06eh,06ah	; 7f12
	defb 074h,072h,034h,034h	; 7f16
	defb 034h,034h,034h,034h	; 7f1a
	defb 034h,034h,034h,034h	; 7f1e
	defb 034h,034h,0c5h,094h	; 7f22
	defb 034h,034h,034h,034h	; 7f26
	defb 094h,0c6h,034h,034h	; 7f2a
	defb 034h,034h,08eh,095h	; 7f2e
	defb 034h,034h,034h,034h	; 7f32
	defb 095h,08fh,034h,034h	; 7f36
	defb 034h,034h,034h,034h	; 7f3a
	defb 034h,034h,034h,034h	; 7f3e
	defb 034h,034h,090h,096h	; 7f42
	defb 034h,034h,034h,034h	; 7f46
	defb 096h,091h,034h,034h	; 7f4a
	defb 034h,034h,092h,097h	; 7f4e
	defb 034h,034h,034h,034h	; 7f52
	defb 000h,034h,097h,093h	; 7f56
	defb 034h,034h,034h,034h	; 7f5a
	defb 034h,034h,000h,034h	; 7f5e
	defb 000h,034h,034h,034h	; 7f62
	defb 080h,088h,034h,07ch	; 7f66
	defb 082h,0fah,000h,034h	; 7f6a
	defb 089h,081h,034h,034h	; 7f6e
	defb 0fah,083h,07dh,034h	; 7f72
	defb 034h,07eh,084h,0fah	; 7f76
	defb 034h,034h,086h,08ah	; 7f7a
	defb 000h,034h,0fah,085h	; 7f7e
	defb 07fh,034h,08bh,087h	; 7f82
	defb 034h,034h,000h,034h	; 7f86

; ----------------------------------------------------------------------
; DATOS punteros_del_recuadro: Siete punteros que 0x55F8 indexa con dos veces
;   el numero de hoyo reducido a 0..3 mas dos veces 0xE142. Solo hay cuatro
;   destinos distintos: 0x7F98, 0x7FAC, 0x7FC4 y 0x7FD9
;   0x7f8a..0x7f98  (14 bytes)
DATA_punteros_del_recuadro:
	defw 07fach,07fd9h,07fc4h,07f98h,07fach,07fd9h,07fc4h	; 7f8a

; ----------------------------------------------------------------------
; DATOS dibujos_del_recuadro: Los cuatro dibujos: filas de diez tiles,
;   codificadas con un byte de mando -si el nibble alto no es cero, los (n y
;   0x0F) tiles que siguen tal cual; si es cero, el segundo byte repetido n
;   veces-. 0x5616 pinta tres filas en la VRAM 0x3881 y otras tres en 0x388B
;   0x7f98..0x7fef  (87 bytes)
DATA_dibujos_del_recuadro:
	defb 007h,0c9h,013h,070h,072h,074h,005h,0c9h,012h,076h,078h,003h,07eh,004h,0a6h,012h	; 7f98  ...prt...vx.~...
	defb 07ah,07ch,004h,07eh,014h,07eh,075h,073h,071h,006h,0c9h,004h,07eh,016h,079h,077h	; 7fa8  z|.~.~usq...~.yw
	defb 0c9h,0c9h,086h,088h,005h,07eh,015h,07dh,07bh,08ah,08ch,07fh,017h,080h,082h,084h	; 7fb8  .....~.}{.......
	defb 07fh,085h,083h,081h,003h,0c9h,007h,07fh,013h,089h,087h,0c9h,008h,07fh,012h,08dh	; 7fc8  ................
	defb 08bh,00ah,0c9h,00ah,0c9h,005h,0a6h,003h,0c9h,002h,0a6h,00ah,0c9h,00ah,0c9h,011h	; 7fd8  ................
	defb 0a6h,005h,0c9h,003h,0a6h,011h,0c9h	; 7fe8

; ----------------------------------------------------------------------
; DATOS guion_borra_tres_filas: Guion de VRAM: pone a cero las filas 1, 2 y 3
;   (0x3821, 0x3841 y 0x3861), 20 tiles cada una. Va en linea tras el call de
;   0x55F3
;   0x7fef..0x7ffe  (15 bytes)
DATA_guion_borra_tres_filas:
	defb 078h,021h,014h,0c9h,080h,078h,041h,014h,0c9h,080h,078h,061h,014h,0c9h,000h	; 7fef  x!...xA...xa...

; ----------------------------------------------------------------------
; DATOS relleno_final: Los dos ultimos bytes del cartucho, que no lee nadie
;   0x7ffe..0x8000  (2 bytes)
DATA_relleno_final:
	defb 0ffh,0ffh	; 7ffe
