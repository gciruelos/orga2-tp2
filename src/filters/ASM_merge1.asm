; ************************************************************************* ;
; Organizacion del Computador II                                            ;
;                                                                           ;
;   Implementacion de la funcion Merge 1                                    ;
;                                                                           ;
; ************************************************************************* ;

; void ASM_merge1(uint32_t w, uint32_t h, uint8_t* data1, uint8_t* data2, float value)
global ASM_merge1
ASM_merge1:
  push rbp
  mov rbp, rsp
  push r12
  push r13
  push r14
  push r15

 
               ; xmm0 = value
  mov r12d, edi ; r12 = w
  mov r13d, esi ; r13 = h
  mov r14, rdx ; r14 = data1
  mov r15, rcx ; r15 = data2

  mov rax, r12 
  mul r13      ; rax = h*w (suponiendo que no hay overflow
  
  mov rcx, 0   ; iterador
  mov rbx, 0   ; posicion actual
  
  
.loop:
  cmp rcx, rax
  je .fin
  ; BGRA

  movdqu xmm1, [r14 + rbx] ; xmm1 = [x|x|x|x|x|x|x|x | x|x|x|x|B|G|R|A]
  movdqu xmm2, [r15 + rbx] ; xmm2 = [x|x|x|x|x|x|x|x | x|x|x|x|B|G|R|A]
  pxor xmm3, xmm3

  punpcklbw xmm1, xmm3     ; xmm1 =  [x|x|x|x|x|x|x|x | 0|B|0|G|0|R|0|A] 
  punpcklbw xmm2, xmm3     ; xmm2 =  [x|x|x|x|x|x|x|x | 0|B|0|G|0|R|0|A] 

  punpcklwd xmm1, xmm3     ; xmm1 =  [0|0|0|B|0|0|0|G | 0|0|0|R|0|0|0|A] 
  punpcklwd xmm2, xmm3     ; xmm2 =  [0|0|0|B|0|0|0|G | 0|0|0|R|0|0|0|A] 

  cvtdq2ps xmm1, xmm1      ; (float) xmm1
  cvtdq2ps xmm2, xmm2      ; (float) xmm2

  pxor xmm5, xmm5
  movss xmm5, [_1]


  pxor xmm3, xmm3          ; xmm3 =  0 | 0 | 0 | 0
  movss xmm3, xmm0         ; xmm3 =  0 | 0 | 0 | value
  pslldq xmm3, 4           ; xmm3 =  0 | 0 | value | 0
  movss xmm3, xmm0         ; xmm3 =  0 | 0 | value | value
  pslldq xmm3, 4           ; xmm3 =  0 | value | value | 0
  movss xmm3, xmm0         ; xmm3 =  0 | value | value | value
  pslldq xmm3, 4           ; xmm3 =  value | value | value | 0
  addss xmm3, xmm5         ; xmm3 =  value | value | value | 1.0
  
  pxor xmm4, xmm4
  addps xmm4, xmm5
  pslldq xmm4, 4
  addps xmm4, xmm5
  pslldq xmm4, 4
  addps xmm4, xmm5
  pslldq xmm4, 4
  addps xmm4, xmm5
  pslldq xmm4, 4           ; xmm4 = 1.0 | 1.0 | 1.0 | 1.0

  subps xmm4, xmm3         ; xmm4 = 1-value | 1-value | 1-value | 0.0
  
  mulps xmm1, xmm3         ; xmm1 = A_1 * 1.0 | B_1 * value | G_1 * value | R_1 * value   
  mulps xmm2, xmm4         ; xmm2 = A_2 * 0.0 | B_2 * (1-value) | G_2 * (1-value) | R_2 * (1-value)

  addps xmm1, xmm2         ; xmm1 = exactamente lo que queremos

  cvtps2dq xmm1, xmm1      ; Convert Packed Single-Precision FP Values to Packed Dword Integers
  
  pxor xmm2, xmm2          ; xmm2 = 0
  packusdw xmm1, xmm2      ; xmm1 = [0|0|0|0|0|0|0|0 | A|A|B|B|G|G|R|R]
  packuswb xmm1, xmm2      ; xmm1 = [0|0|0|0|0|0|0|0 | 0|0|0|0|A|B|G|R]

  movss [r14 + rbx], xmm1  ; lo guardo de nuevo en memoria

  add rbx, 4
  inc rcx

  jmp .loop


.fin:
  pop r15
  pop r14
  pop r13
  pop r12
  pop rbp
  ret

_1: dd 1.0


