; ************************************************************************* ;
; Organizacion del Computador II                                            ;
;                                                                           ;
;   Implementacion de la funcion Merge 2                                    ;
;                                                                           ;
; ************************************************************************* ;

section .data

_1: dd 1.0
_muchos256: dd 256.0, 256.0, 256.0, 256.0
_muchos257ints: dw 257, 257, 257, 257, 257, 257, 257, 257
_11111111: dw 1, 1, 1, 1, 1, 1, 1, 1
_floor: dd 0x7F80


section .text

; void ASM_merge2(uint32_t w, uint32_t h, uint8_t* data1, uint8_t* data2, float value)
global ASM_merge2
ASM_merge2:
  push rbp
  mov rbp, rsp
  push r12
  push r13
  push r14
  push r15


                ; xmm0 = value
  mov r12d, edi ; r12 = w
  mov r13d, esi ; r13 = h
  mov r14, rdx  ; r14 = data1
  mov r15, rcx  ; r15 = data2

  mov rax, r12 
  mul r13      ; rax = h*w (suponiendo que no hay overflow)
  
  mov rcx, 0   ; iterador
  mov rbx, 0   ; posicion actual 


  ;;;;;; Precalculo los vectores que voy a usar todos los loops
  pxor xmm5, xmm5
  movss xmm5, [_1]

  movups xmm1, [_muchos256]
  
  pxor xmm3, xmm3      ; xmm3 =  0 | 0 | 0 | 0
  addss xmm3, xmm0     ; xmm3 =  0 | 0 | 0 | value
  pslldq xmm3, 4       ; xmm3 =  0 | 0 | value | 0
  addss xmm3, xmm0     ; xmm3 =  0 | 0 | value | value
  pslldq xmm3, 4       ; xmm3 =  0 | value | value | 0
  addss xmm3, xmm0     ; xmm3 =  0 | value | value | value
  pslldq xmm3, 4       ; xmm3 =  value | value | value | 0
  addss xmm3, xmm5     ; xmm3 =  value | value | value | 1.0
  mulps xmm3, xmm1     ; xmm3 = 256*value | 256*value | 256*value | 256.0
  
  cvtps2dq xmm3, xmm3  ; (int32) xmm3 = 256*value | 256*value | 256*value | 256
  packuswb xmm3, xmm3  ; (int16) xmm3 = 256*value | 256*value | 256*value | 256 | 256*value | 256*value | 256*value | 256
  ; la instruccion de arriba es exactamente lo que quiero

  

  movdqu xmm4, [_muchos257ints]  ; (int16) xmm4 =  257 | 257 | 257 | 257 | 257 | 257 | 257 | 257
  psubw xmm4, xmm3

  pxor xmm6, xmm6      ; xmm6 = 0
  ;;;;;;;;

.loop:
  cmp rcx, rax   ; si iterador = h*w, listo, terminamos
  je .fin

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;; tengo que hacer xmm1*xmm3 + xmm2*xmm4 ;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  
  movq xmm1, [r14 + rbx] ; xmm1 = [x|x|x|x|x|x|x|x | B|G|R|A|B|G|R|A]
  movq xmm2, [r15 + rbx] ; xmm2 = [x|x|x|x|x|x|x|x | B|G|R|A|B|G|R|A]

  punpcklbw xmm1, xmm6     ; xmm1 =  [0|B|0|G|0|R|0|A | 0|B|0|G|0|R|0|A] 
  punpcklbw xmm2, xmm6     ; xmm2 =  [0|B|0|G|0|R|0|A | 0|B|0|G|0|R|0|A] 

  pmullw xmm1, xmm3         ; xmm1  = [B*v|G*v|R*v|A*1 | lo mismo aca ] 
  ;no me importa la parte alta
  pmullw xmm2, xmm4         ; xmm2  = [B*(1-v)|G*(1-v)|R*(1-v)|A*1 | lo mismo aca ]
  ;no me importa la parte alta
   

  psrlw xmm1, 8            ; divido por 256;
  psrlw xmm2, 8            ; divido por 256;
  

  paddw xmm1, xmm2       ; (uint32_t) xmm1 = [B1+B2|G1+G2|R1+R2|A]
  
  packuswb xmm1, xmm1      ; xmm1 = [0|0|0|0|0|0|0|0 | B|G|R|A~|B|G|R|A~]
  
  movsd [r14 + rbx], xmm1  ; lo guardo de nuevo en memoria

  add rbx, 8
  inc rcx
  inc rcx

  jmp .loop

.fin:
  pop r15
  pop r14
  pop r13
  pop r12
  pop rbp
  ret

