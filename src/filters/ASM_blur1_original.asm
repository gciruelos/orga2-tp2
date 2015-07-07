; ************************************************************************* ;
; Organizacion del Computador II                                            ;
;                                                                           ;
;   Implementacion de la funcion Blur 1                                     ;
;                                                                           ;
; ************************************************************************* ;

%define SIZE_PIXEL 4

section .data
align 16
_9: dd 9.0, 9.0, 9.0, 9.0
_floor: dd 0x7F80

section .text
extern malloc
extern free

; void ASM_blur1( uint32_t w, uint32_t h, uint8_t* data )
global ASM_blur1
ASM_blur1:

  push rbp
  mov rbp, rsp
  push rbx
  push r12
  push r13
  push r14
  push r15

  mov rbx, rdi ; rbx: w (in pixels), pixeles por fila
  mov r12, rsi ; r12: h (in pixels)
  mov r13, rdx ; r13: pointer to data

  ; reservar espacio para dos filas
  shl rdi, 2   ; rdi*4
  call malloc  ; rax: pointer to temp row 1
  mov r14, rax ; r14: temp row 1

  mov rdi, rbx
  shl rdi, 2   ; rdi*4, cada pixel tiene 4 bytes
  call malloc  ; rax: pointer to temp row 0
  mov r15, rax ; r15: temp row 0

  ; control reg MXCSR (10.2.3.1, vol 1)
  ; controla el comportamiento de muchas instrucciones de SSE.
  ; las conversiones de float a entero dependen de este registro,
  ; para hacer round up o down.
  ; The default MXCSR value at reset is 1F80H.
  ; 0x7F80 para que rendondee hacia abajo.
  ldmxcsr [_floor]

  ; armar registro para dividir
  movdqa xmm7, [_9]

  pxor xmm6, xmm6  ; para desempaquetar

  ; variables
  xor rdi, rdi ; contador pixeles recorridos
  mov rax, r12 ; pixeles totales a recorrer (todos menos una fila)
  dec rax
  mul rbx      ; w*(h-1)

  mov rdx, rbx ; limite columnas (w-2)
  dec rdx
  dec rdx

  ; copiar primera fila
.copy_row:
  xor r8, r8   ; columnas recorridas

.loop:
  movdqu xmm1, [r13 + rdi*SIZE_PIXEL] ; en req a memoria recorro con offset
  movdqu [r14 + r8*SIZE_PIXEL], xmm1 ; en write a temp row recorro con columnas
  add r8, 4    ; copio de a 4 pixeles
  add rdi, 4   ; recorri 4 pixeles
  cmp r8, rbx  ; r8 = w?
  jne .loop    ; si son iguales, ya recorri todos

  cmp rdi, rbx ; caso borde, donde al principio cargo la primera fila
  jne .clean_counter

.loop_rows:

  cmp rdi, rax ; recorri todos los pixeles
  je .fin

  mov rsi, r14 ; m_tmp, copio puntero a la fila que recien copie
  mov r14, r15 ; m_row_0 points to m_row_1 (la vieja que copie)
  mov r15, rsi ; copiar nueva fila y mantener la anterior
               ; puntero a fila anterior: r15, puntero a fila actual: r14

  jmp .copy_row

.clean_counter:
  sub rdi, rbx ; rdi subio cuando copie la fila, ahora se lo resto
  xor r8, r8   ; contador de columnas (lo reutilizo)

.loop_columns:

  ; sumo la primera fila de pixeles (res: xmm1)
  movq xmm1, [r15 + r8*SIZE_PIXEL] ; xmm1 = [x|x|x|x B|G|R|A B|G|R|A B|G|R|A]
  movd xmm2, [r15 + r8*SIZE_PIXEL+8] ; xmm1 = [x|x|x|x B|G|R|A B|G|R|A B|G|R|A]
  pslldq xmm2, 8
  por xmm2, xmm1
  movaps xmm1, xmm2



  pslldq xmm1, 4
  psrldq xmm1, 4

  movdqu xmm2, xmm1    ; xmm2 = xmm1
  punpcklbw xmm1, xmm6 ; xmm1 = [0|B2|0|G2|0|R2|0|A2 0|B1|0|G1|0|R1|0|A1]

  punpckhbw xmm2, xmm6 ; xmm2 = [0|0|0|0|0|0|0|0 0|B3|0|G3|0|R3|0|A3]

  paddw xmm1, xmm2     ; xmm1 = [B2|G2|R2|A2 B1+B3|G1+G3|R1+R3|A1+A3]

  ; sumo la segunda fila de pixeles (res: xmm2)
  movq xmm2, [r14 + r8*SIZE_PIXEL] ; xmm2 = [x|x|x|x B|G|R|A B|G|R|A B|G|R|A]
  movd xmm3, [r14 + r8*SIZE_PIXEL+8]
  pslldq xmm3, 8
  por xmm3, xmm2
  movaps xmm2, xmm3

  pslldq xmm2, 4
  psrldq xmm2, 4

  movdqu xmm3, xmm2    ; xmm3 = xmm2
  punpcklbw xmm2, xmm6 ; xmm2 = [0|B2|0|G2|0|R2|0|A2 0|B1|0|G1|0|R1|0|A1]

  punpckhbw xmm3, xmm6 ; xmm3 = [0|0|0|0|0|0|0|0 0|B3|0|G3|0|R3|0|A3]

  paddw xmm2, xmm3     ; xmm1 = [B2|G2|R2|A2 B1+B3|G1+G3|R1+R3|A1+A3]

  ; sumo la tercera fila de pixeles (res: xmm3)
  ; mov r9, rdi
  ; add r9, rbx          ; agrego una fila al contador de pixeles
  ; dec r9               ; arranco un pixel antes en xmm3 para evitar el segfault al final
  ;                      ; e.g. XAAA   xmm1 = ZAAA
  ;                      ;      ZBOB   xmm2 = ZBOB
  ;                      ;      ZCCCS  xmm3 = SCCC
  ;                      ; entonces lo que hago es:
  ;                      ;             xmm1 = ZAAA
  ;                      ;             xmm2 = ZBOB
  ;                      ;             xmm3 = CCCZ y limpio con bitshift.
  ; movdqu xmm3, [r13 + r9*SIZE_PIXEL] ; xmm3 = [D|C|B|A], A es basura
  ; psrldq xmm3, 4       ; xmm3 = [0|0|0|0 B3|G3|R3|A3 B2|G2|R2|A2 B1|G1|R1|A1]
  ;                      ; tiro pixel basura

  ; movdqu xmm4, xmm3    ; xmm4 = xmm3
  ; punpcklbw xmm3, xmm6 ; xmm3 = [0|B2|0|G2|0|R2|0|A2 0|B1|0|G1|0|R1|0|A1]
  ; punpckhbw xmm4, xmm6 ; xmm4 = [0|0|0|0|0|0|0|0 0|B3|0|G3|0|R3|0|A3]
  ; paddw xmm3, xmm4     ; xmm3 = [B2|G2|R2|A2 B1+B3|G1+G3|R1+R3|A1+A3]

  ; sumo la tercera fila (sin 'hack', da igual)
  mov r9, rdi
  add r9, rbx
  
  movq xmm3, [r13 + r9*SIZE_PIXEL] ; [D|C|B|A]
  movd xmm4, [r13 + r9*SIZE_PIXEL+8] ; [D|C|B|A]
  pslldq xmm4, 8
  por xmm4, xmm3
  movaps xmm3, xmm4

  pslldq xmm3, 4
  psrldq xmm3, 4 ; xmm3 = [0|C|B|A]

  movdqu xmm4, xmm3
  punpcklbw xmm3, xmm6 ; [B|A]
  punpckhbw xmm4, xmm6 ; [0|C]

  paddw xmm3, xmm4 ; [B|A+C]

  ; sumo todos los resultados (res: xmm1)
  paddw xmm1, xmm2     ; xmm1 = [2B|2G|2R|2A 4B|4G|4R|4A]
  paddw xmm1, xmm3     ; xmm1 = [3B|3G|3R|3A 6B|6G|6R|6A]
  movdqu xmm2, xmm1    ; xmm2 = [3B|3G|3R|3A 6B|6G|6R|6A]
  psrldq xmm2, 8       ; xmm2 = [0|0|0|0     3B|3G|3R|3A]
  paddw xmm1, xmm2     ; xmm1 = [3B|3G|3R|3A 9B|9G|9R|9A]

  ; asigno mas espacio tirando lo de arriba, convierto a float y divido
  punpcklwd xmm1, xmm6 ; xmm1 = [9B|9G|9R|9A] (dwords)
  cvtdq2ps xmm1, xmm1
  divps xmm1, xmm7     ; xmm1 / 9

  ; convierto a entero, empaqueto y escribo en memoria
  cvtps2dq xmm1, xmm1 ; xmm1 = [9B|9G|9R|9A] (int32), x[31:8] = 0, no hay overflow
  packusdw xmm1, xmm6 ; pack from dword to word
  packuswb xmm1, xmm6 ; pack from word to byte, (res: lower dword)

  movd [r13 + rdi*SIZE_PIXEL + SIZE_PIXEL], xmm1

  inc rdi  ; recorri un pixel
  inc r8   ; avanzo de a 1 pixel

  cmp r8, rdx ; paro cuando llego a la anteultima columna
  jne .loop_columns

  inc rdi         ; lo tengo que incrementar porque corto en w-1, para que avance de fila
  inc rdi

  jmp .loop_rows  ; si llegamos aca, terminamos de iterar las columnas

.fin:
  mov rdi, r14
  call free
  mov rdi, r15
  call free

  pop r15
  pop r14
  pop r13
  pop r12
  pop rbx
  pop rbp
  ret
