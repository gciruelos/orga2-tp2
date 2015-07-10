; ************************************************************************* ;
; Organizacion del Computador II                                            ;
;                                                                           ;
;   Implementacion de la funcion HSL 1                                      ;
;                                                                           ;
; ************************************************************************* ;

%define TAMANIO_PIXEL_HSL 16

extern rgbTOhsl
extern hslTOrgb



; void ASM_hsl1(uint32_t w, uint32_t h, uint8_t* data, float hh, float ss, float ll)
global ASM_hsl1
ASM_hsl1:
  push rbp
  mov rbp, rsp
  push rbx
  push r12
  push r13
  push r14
  push r15
  sub rsp, 8

  ; xmm0 = hh
  ; xmm1 = ss
  ; xmm2 = ll
  mov r12d, edi ; r12 = w
  mov r13d, esi ; r13 = h
  mov r14, rdx  ; r14 = data
  
  mov r12d, r12d ; limpio la parte alta
  mov r13d, r13d ; de estos registros


  mov rax, r12 
  mul r13        ; rax = h*w (suponiendo que no hay overflow)
  mov r15, rax   ; r15 = h*w
  
  mov rcx, 0     ; iterador

;;;; genero el vector que le voy a sumar, que tiene que ser de la pinta
;;;; [ll | ss | hh | 00]
  pxor xmm4, xmm4
  movss xmm4, xmm2
  pslldq xmm4, 4
  addss xmm4, xmm1
  pslldq xmm4, 4
  addss xmm4, xmm0
  pslldq xmm4, 4
  sub rsp, 16
  
  mov rbx, rsp
  
  sub rsp, 16
  movdqu [rsp], xmm4
;;;; xmm4 = [ll | ss | hh | 00]
  


.loop:
  cmp rcx, r15   ; si iterador = h*w, listo, terminamos
  je .fin


  lea rdi, [r14 + 4*rcx] ; rdi = r14 + rcx
  mov rsi, rbx         ; rsi = puntero a float
  push rcx
  sub rsp, 8
  call rgbTOhsl
  add rsp, 8
  pop rcx
  ; ahora en rbx tengo 4 floats, que representan la transparencia, H, S, L

  ;;;; xmm4 = [ll | ss | hh | 00]
  movdqu xmm4, [rsp]
  
  movups xmm7, [_1111]   ; xmm7 = [1 | 1 | 1 | 1]
  pxor xmm8, xmm8      ; xmm8 = 0
  movss xmm9, [_360]   ; xmm9 = [ x | x | x | 360.0]
  movss xmm10, [_n360]   ; xmm10 = [ x | x | x | -360.0]
  movss xmm11, [_256]   ; xmm11 = [ x | x | x | 256.0]


  movups xmm3, [rbx]   ; xmn3 = [L|L|L|L | S|S|S|S | H|H|H|H | A|A|A|A]
  addps xmm3, xmm4     ; xmm3 = [l + LL | s + SS | h + HH | a + 00] 

  ;; Ahora tengo que hacer los if's. Para eso voy a usar dos registros
  ;; xmm5 = [ 1-(l+LL) | 1-(s+SS) | -360 | 0] 
  ;; xmm6 = [ -(l+LL)  | -(s+SS)  | 360  | 0]
  ;; notar que basta seleccionar cuales quiero usar (haciendo and) y sumandolos

  ;; construyo xmm5
  movaps xmm5, xmm7    ; xmm5 = [1 | 1 | 1 | 1]
  subps xmm5, xmm3     ; xmm5 = [1-(l+LL) | 1-(s+SS) | 1-(h+HH) | 1-(a+00)]
  psrldq xmm5, 4       ; xmm5 = [0        | 1-(l+LL) | 1-(s+SS) | 1-(h+HH)]
  movss xmm5, xmm10    ; xmm5 = [0        | 1-(l+LL) | 1-(s+SS) | -360     ]
  pslldq xmm5, 4       ; xmm5 = [1-(l+LL) | 1-(s+SS) | -360      | 0       ]


  ;; construyo xmm6
  pxor xmm6, xmm6      ; xmm6 = [0 | 0 | 0 | 0]
  subps xmm6, xmm3     ; xmm5 = [-(l+LL)  | -(s+SS)  | -(h+HH)  | -(a+00) ]
  psrldq xmm6, 4       ; xmm5 = [0        | -(l+LL)  | -(s+SS)  | -(h+HH) ]
  movss xmm6, xmm9     ; xmm5 = [0        | -(l+LL)  | -(s+SS)  | -360    ]
  pslldq xmm6, 4       ; xmm5 = [-(l+LL)  | -(s+SS)  | -360     | 0       ]
  
  ;; ahora tengo que comparar con los vectores 
  ;; [1 | 1 | 360 | 256] = xmm12
  ;; [0 | 0 | 0   | 0  ] = xmm13

  movaps xmm12, xmm7   ; xmm7 = [1 | 1 | 1 | 1]
  movss xmm12, xmm9    ; xmm7 = [1 | 1 | 1 | 360] 
  pslldq xmm12, 4      ; xmm7 = [1 | 1 | 360 | 0]
  movss xmm12, xmm11   ; xmm7 = [1 | 1 | 360 | 256]

  pxor xmm13, xmm13    ; xmm13 = [0 | 0 | 0 | 0]
  

  cmpltps xmm12, xmm3 ; xmm12 = 1 o 0 dependiendo
  movdqa xmm14, xmm13
  movdqa xmm13, xmm3   ; los doy vuelta porque necesito greater than
  cmpltps xmm13, xmm14  ; xmm13 = 1 o 0 dependiendo

  pand xmm5, xmm12
  pand xmm6, xmm13

  addps xmm3, xmm5
  addps xmm3, xmm6


  movups [rbx], xmm3  ; lo guardo en mi posicion de memoria
  mov rdi, rbx
  lea rsi, [r14 + 4*rcx] 


  push rcx
  sub rsp, 8
  call hslTOrgb
  add rsp, 8
  pop rcx

  inc rcx
  jmp .loop

.fin:
  add rsp, 16
  add rsp, 16
  add rsp, 8
  pop r15
  pop r14
  pop r13
  pop r12
  pop rbx
  pop rbp
  ret

_1111: dd 1.0, 1.0, 1.0, 1.0
_360: dd 360.0
_n360: dd -360.0
_256: dd 256.0

