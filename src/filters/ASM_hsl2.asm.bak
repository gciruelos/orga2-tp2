; ************************************************************************* ;
; Organizacion del Computador II                                            ;
;                                                                           ;
;   Implementacion de la funcion HSL 2                                      ;
;                                                                           ;
; ************************************************************************* ;

section .data
align 16
setRGBA: db 0xFF
align 16
_256: dd 256.0
align 16
_1111: dd 1.0, 1.0, 1.0, 1.0
align 16
_0000: dd 0.0, 0.0, 0.0, 0.0
align 16
_2: dd 2.0, 2.0, 2.0, 2.0
align 16
_4: dd 4.0, 4.0, 4.0, 4.0
align 16
_6: dd 6.0, 6.0, 6.0, 6.0
align 16
_60: dd 60.0, 60.0, 60.0, 60.0
align 16
_120: dd 120.0, 120.0, 120.0, 120.0
align 16
_180: dd 180.0, 180.0, 180.0, 180.0
align 16
_240: dd 240.0, 240.0, 240.0, 240.0
align 16
_255: dd 255.0, 255.0, 255.0, 255.0
align 16
_300: dd 300.0, 300.0, 300.0, 300.0
align 16
_360: dd 360.0, 360.0, 360.0, 360.0
align 16
_510: dd 510.0, 510.0, 510.0, 510.0
align 16
_n360: dd -360.0, -360.0, -360.0, -360.0
align 16
_2550001: dd 255.0001, 255.0001, 255.0001, 255.0001
_255int: dd 255, 255, 255, 255

align 16
_arreglar: dd 0.000001
align 16
_floor: dd 0x7F80

align 16
_todo1: dd 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff

; RGBA
; ABGR <- Como los quiero en el registro
;              A
; [C | X | M | 0]
section .text

%define TAMANIO_PIXEL_HSL 16

extern rgbTOhsl
extern hslTOrgb
extern malloc
extern free
; void ASM_hsl2(uint32_t w, uint32_t h, uint8_t* data, float hh, float ss, float ll)
global ASM_hsl2
ASM_hsl2:
  push rbp
  mov rbp, rsp
  push rbx
  push r12
  push r13
  push r14
  push r15
  sub rsp, 8

  ldmxcsr [_floor]
  ; xmm0 = hh
  ; xmm1 = ss
  ; xmm2 = ll
  mov r12d, edi ; r12 = w
  mov r13d, esi ; r13 = h
  mov r14, rdx  ; r14 = data

  mov r12d, r12d ; limpio la parte alta
  mov r13d, r13d ; de estos registros

  ;mov rdi, TAMANIO_PIXEL_HSL
  ;call malloc

  ;mov rbx, rax   ; rbx = puntero a float
                 ; lo voy a usar para llamar a las funciones conversoras



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
  movdqu [rsp], xmm4
;;;; xmm4 = [ll | ss | hh | 00]



_loop:
  cmp rcx, r15   ; si iterador = h*w, listo, terminamos
  je _fin

  lea rdi, [r14 + 4*rcx] ; rdi = r14 + rcx
  ;mov rsi, rbx         ; rsi = puntero a float

  jmp _rgbTOhsl
rgbTOhslBack:
  ; ahora en rbx tengo 4 floats, que representan la transparencia, H, S, L


  ;;;; recupero xmm4 = [ll | ss | hh | 00]
  movdqu xmm4, [rsp]

  movups xmm7, [_1111]   ; xmm7 = [1 | 1 | 1 | 1]
  pxor xmm8, xmm8      ; xmm8 = 0
  movss xmm9, [_360]   ; xmm9 = [ x | x | x | 360.0]
  movss xmm10, [_n360]   ; xmm10 = [ x | x | x | -360.0]
  movss xmm11, [_256]   ; xmm11 = [ x | x | x | 256.0]


  ;movups xmm3, [rbx]   ; xmn3 = [L|L|L|L | S|S|S|S | H|H|H|H | A|A|A|A]
  addps xmm3, xmm4     ; xmm3 = [l + LL | s + SS | h + HH | a + 00]

  ;; Ahora tengo que hacer los if's. Para eso voy a usar dos registros
  ;; xmm5 = [ 1-(l+LL) | 1-(s+SS) | -360 | 0]
  ;; xmm6 = [ -(l+LL)  | -(s+SS)  | 360  | 0]
  ;; notar que basta seleccionar cuales quiero usar (haciendo and) y sumandolos

  ;; construyo xmm5
  movups xmm5, xmm7    ; xmm5 = [1 | 1 | 1 | 1]
  subps xmm5, xmm3     ; xmm5 = [1-(l+LL) | 1-(s+SS) | 1-(h+HH) | 1-(a+00)]
  psrldq xmm5, 4       ; xmm5 = [0        | 1-(l+LL) | 1-(s+SS) | 1-(h+HH)]
  movss xmm5, xmm10    ; xmm5 = [0        | 1-(l+LL) | 1-(s+SS) | 360     ]
  pslldq xmm5, 4       ; xmm5 = [1-(l+LL) | 1-(s+SS) | 360      | 0       ]


  ;; construyo xmm6
  pxor xmm6, xmm6      ; xmm6 = [0 | 0 | 0 | 0]
  subps xmm6, xmm3     ; xmm5 = [-(l+LL)  | -(s+SS)  | -(h+HH)  | -(a+00) ]
  psrldq xmm6, 4       ; xmm5 = [0        | -(l+LL)  | -(s+SS)  | -(h+HH) ]
  movss xmm6, xmm9     ; xmm5 = [0        | -(l+LL)  | -(s+SS)  | -360    ]
  pslldq xmm6, 4       ; xmm5 = [-(l+LL)  | -(s+SS)  | -360     | 0       ]

  ;; ahora tengo que comparar con los vectores
  ;; [1 | 1 | 360 | 256] = xmm12
  ;; [0 | 0 | 0   | 0  ] = xmm13

  movups xmm12, xmm7   ; xmm7 = [1 | 1 | 1 | 1]
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

  jmp _hslTOrgb
hslTOrgbBack:

  inc rcx
  jmp _loop

_fin:
  add rsp, 16
  ;mov rdi, rbx
  ;call free    ; libero la memoria que pedi
  add rsp, 8
  pop r15
  pop r14
  pop r13
  pop r12
  pop rbx
  pop rbp
  ret

;puedo romper todos los registros
;tengo que devolver el resultado en xmm0
_rgbTOhsl:

  ; xmm3 va a ser [L|S|H|A]
  movss xmm12, [rdi]
  pxor xmm13, xmm13

  punpcklbw xmm12, xmm13  ; xmm12 = [x|x|x|x|x|x|x|x|0|R|0|G|0|B|0|A]
  punpcklwd xmm12, xmm13  ; xmm12 = [0|0|0|R|0|0|0|G|0|0|0|B|0|0|0|A]

  cvtdq2ps xmm12, xmm12   ; (float) xmm12 = [0|0|0|B|0|0|0|G|0|0|0|R|0|0|0|A]
  movups xmm0, xmm12
  movups xmm1, xmm12
  movups xmm2, xmm12

  psrldq xmm0, 12  ;; r
  psrldq xmm1, 8  ;; g
  psrldq xmm2, 4 ;; b

  movups xmm14, xmm0
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;; CALCULO DE H ;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  maxss xmm0, xmm1
  maxss xmm0, xmm2    ; xmm0 = max

  minss xmm1, xmm14
  minss xmm1, xmm2    ; xmm1 = min

  movups xmm14, xmm0  ; xmm14 = max
  subps xmm14, xmm1   ; xmm14 = max - min
  addps xmm14, [_arreglar]

  ;;; Lo hago feo porque hacerlo de otra forma es igual de feo
  ;;; requiere muchos extracts

  movups xmm9, xmm12
  movups xmm10, xmm12
  movups xmm11, xmm12

  psrldq xmm9, 12     ;; R
  psrldq xmm10, 8     ;; G
  psrldq xmm11, 4    ;; B

  movss xmm4, xmm10   ; xmm4 = g
  subss xmm4, xmm11   ; xmm4 = g-b
  divss xmm4, xmm14  ; xmm4 = (g-b)/d
  addss xmm4, [_6]   ; xmm4 = (g-b)/d + 6
  mulss xmm4, [_60]  ; xmm4 = 60 * ((g-b)/d + 6)


  movss xmm5, xmm11   ; xmm4 = b
  subss xmm5, xmm9   ; xmm4 = b-r
  divss xmm5, xmm14  ; xmm4 = (b-r)/d
  addss xmm5, [_2]   ; xmm4 = (b-r)/d + 2
  mulss xmm5, [_60]  ; xmm4 = 60 * ((b-r)/d + 2)


  movss xmm6, xmm9   ; xmm4 = r
  subss xmm6, xmm10  ; xmm4 = r-g
  divss xmm6, xmm14  ; xmm4 = (r-g)/d
  addss xmm6, [_4]   ; xmm4 = (r-g)/d + 4
  mulss xmm6, [_60]  ; xmm4 = 60 * ((r-g)/d + 4)

  pxor xmm13, xmm13  ; xmm13 = h definitivo

  cmpeqss xmm9, xmm0 ; max == r
  pand xmm4, xmm9
  addss xmm13, xmm4

  cmpeqss xmm9, [_0000]

  cmpeqss xmm10, xmm0 ; max == g
  pand xmm5, xmm10
  pand xmm5, xmm9
  addss xmm13, xmm5

  cmpeqss xmm10, [_0000]

  cmpeqss xmm11, xmm0 ; max == b
  pand xmm6, xmm11
  pand xmm6, xmm10
  pand xmm6, xmm9
  addss xmm13, xmm6

  movss xmm11, [_n360]
  movss xmm10, [_360]
  cmpless xmm10, xmm13
  pand xmm11, xmm10

  addss xmm13, xmm11  ;; xmm13 = h
  addss xmm13, [_arreglar] ;; si no hago esto, se rompe

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;; CALCULO DE L ;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  pxor xmm3, xmm3

  movups xmm8, [_510]

  addss xmm3, xmm1
  addss xmm3, xmm0
  divss xmm3, xmm8    ; xmm3 = [ 0 | 0 | 0 | L = (cmax+cmin)/510]

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;; CALCULO DE S ;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  movss xmm4, xmm14 ; xmm4 = d
  movss xmm5, xmm3  ; xmm3 = l
  mulss xmm5, [_2]  ; xmm3 = 2*l
  subss xmm5, [_1111] ; xmm3 = 2*l-1

  pxor xmm6, xmm6
  subss xmm6, xmm5    ; xmm6 = -(2*l-1)

  maxss xmm5, xmm6  ; xmm5 = fabs(2*l-1)

  movss xmm6, [_1111]

  subss xmm6, xmm5 ; xmm6 = 1-fabs(2*l-1)

  divss xmm4, xmm6
  divss xmm4, [_2550001]

  cmpneqss xmm0, xmm1
  pand xmm4, xmm0


  pxor xmm0, xmm0
  movss xmm0, xmm3
  pslldq xmm0, 4
  movss xmm0, xmm4
  pslldq xmm0, 4
  movss xmm0, xmm13
  pslldq xmm0, 4
  movss xmm0, xmm12

  ;movups [rbx], xmm0
  movaps xmm3, xmm0

  jmp rgbTOhslBack



; pasa los pixeles hsl por xmm3
; hay que devolver los 4 pixeles rgb por $r14 + 4*$rcx
_hslTOrgb:
  ; xmm3 = [L S H X]
  ;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;; calculo de h -> xmm4 ;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;
  pxor xmm4, xmm4
  movsd xmm4, xmm3
  psrldq xmm4, 4 ; xmm4 = [0 | 0 | 0 | H]
  movss xmm6, xmm4
  pslldq xmm4, 4
  addss xmm4, xmm6
  movaps xmm5, xmm4
  pslldq xmm5, 8
  addps xmm4, xmm5 ; xmm4 = [H | H | H | H]




  ;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;; calculo de c -> xmm0 ;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;
  movaps xmm0, xmm3
  psrldq xmm0, 12  ; xmm0 = [0|0|0|L]
  movss xmm1, [_2]
  mulss xmm0, xmm1 ; xmm0 = [0|0|0|2*L]
  movaps xmm1, [_1111]
  subss xmm0, xmm1 ; xmm0 = [0|0|0|2*L-1]
  pxor xmm1, xmm1  ; xmm2 = 0
  subss xmm1, xmm0 ; xmm2 = [0|0|0|1-2*L]
  maxss xmm0, xmm1 ; xmm0 = [0|0|0|fabs(2*L-1)]
  movups xmm1, [_1111]
  subss xmm1, xmm0 ; xmm1 = [x|x|x|1-fabs(2*L-1)]
  movups xmm0, xmm3
  psrldq xmm0, 8
  mulss xmm0, xmm1 ; xmm0 = [x|x|x|c = ( 1 - fabs( 2*L - 1 )) * s]


  ;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;; calculo de x -> xmm1 ;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;

  movups xmm1, xmm3
  psrldq xmm1, 4 ; xmm1 = [0 L S H]
  ;;movss xmm15, [_60]
  divss xmm1, [_60] ; xmm1 = [x|x|x|H/60]
  movups xmm12, xmm1; xmm12 = [x|x|x|H/60]
  movss xmm13, [_2] ; xmm13 = [x|x|x|2]
  divss xmm12, xmm13
  roundss xmm12, xmm12, 0xf ;; CONSULTAR : modo de redondeo
  mulss xmm12, xmm13
  subss xmm1, xmm12  ; xmm1 = [x|x|x|n-trunc(n/d)*d = fmod(H/60, 2)]
  movss xmm13, [_1111]
  subss xmm1, xmm13; xmm1 = [x|x|x|fmod(H/60,2)-1]
  pxor xmm2, xmm2  ; xmm2 = 0
  subss xmm2, xmm1 ; xmm2 = [0|0|0|-(fmod(H/60,2)-1)]
  maxss xmm1, xmm2 ; xmm0 = [0|0|0|fabs(fmod(H/60, 2)-1)]
  subss xmm13, xmm1; xmm13= [x|x|x|1-fabs(fmod(H/60, 2)-1)]
  mulss xmm13, xmm0
  movups xmm1, xmm13  ; xmm1 = [x|x|x|x = C*(1-fabs(fmod(H/60,2)-1))]

  ;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;; calculo de m -> xmm2 ;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;

  movss xmm13, [_2]
  movss xmm2, xmm0  ; xmm2 = c
  divss xmm2, xmm13 ; xmm2 = c/2
  movss xmm14, xmm2 ; xmm14 = c/2

  movaps xmm2, xmm3  ;
  psrldq xmm2, 12
  subss xmm2, xmm14 ; xmm2 = [x|x|x|m = L-C/2]

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;; calculo RGB           ;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;

  ;xmm4 = h, xmm3 = pixel, xmm2 = m, xmm1 = x, xmm0 = c
  movups xmm15, [_255] ; xmm15 = 255.0

  addss xmm0, xmm2
  addss xmm1, xmm2 ; Le sumo m a todos los x y todos los c

  mulss xmm0, xmm15 ; Registro con los c
  mulss xmm1, xmm15 ; Registro con los x
  mulss xmm2, xmm15 ; Registro con los 0

  cvtps2dq xmm0, xmm0
  cvtps2dq xmm1, xmm1
  cvtps2dq xmm2, xmm2 ; Los convierto todos a enteros de 32 bits


  pxor xmm15, xmm15 ; xmm15 = 0
  movups xmm14, [_todo1]  ; xmm14 = trabajo que hice hasta ahora (1 = nada)

  pxor xmm7, xmm7  ; [R|G|B|A]

;;;; RECORDAR:  EN CASO DE QUE CAMBIEN ALGO DEL CODIGO DE LA CATEDRA Y DEJE DE ANDAR, HAY QUE INTERCAMBIAR LOS c, x, 0
;;;;; ^^^^
   pxor xmm9, xmm9
;; 60 ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;en xmm13 formo el vector
  pxor xmm13, xmm13
  addss xmm13, xmm0 ; c
  pslldq xmm13, 4
  addss xmm13, xmm1 ; x
  pslldq xmm13, 4
  addss xmm13, xmm2 ; 0
  pslldq xmm13, 4
  addss xmm13, [_255int] ; a

  movaps xmm9, xmm13

  movaps xmm10, xmm4    ; cargo todos los h
  cmpltps xmm10, [_60]  ; comparo con 60

  pand xmm13, xmm10
  pand xmm13, xmm14

  pandn xmm10, xmm14
  movaps xmm14, xmm10

  paddd xmm7, xmm13



;; 120 ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;en xmm13 formo el vector
  movaps xmm13, xmm9
  pshufd xmm13, xmm13, 0xB4 ; b4 = 10 11 01 00

  movaps xmm10, xmm4    ; cargo todos los h
  cmpltps xmm10, [_120]  ; comparo con 60

  pand xmm13, xmm10
  pand xmm13, xmm14

  pandn xmm10, xmm14
  movaps xmm14, xmm10

  paddd xmm7, xmm13


;; 180 ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;en xmm13 formo el vector
  movaps xmm13, xmm9
  pshufd xmm13, xmm13, 0x78 ; 78 = 01 11 10 00

  movaps xmm10, xmm4    ; cargo todos los h
  cmpltps xmm10, [_180]  ; comparo con 60

  pand xmm13, xmm10
  pand xmm13, xmm14

  pandn xmm10, xmm14
  movaps xmm14, xmm10

  paddd xmm7, xmm13

;; 240 ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;en xmm13 formo el vector
  movaps xmm13, xmm9
  pshufd xmm13, xmm13, 0x6C ; 6c = 01 10 11 00

  movaps xmm10, xmm4    ; cargo todos los h
  cmpltps xmm10, [_240]  ; comparo con 60

  pand xmm13, xmm10
  pand xmm13, xmm14

  pandn xmm10, xmm14
  movaps xmm14, xmm10

  paddd xmm7, xmm13



;; 300 ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;en xmm13 formo el vector
  movaps xmm13, xmm9
  pshufd xmm13, xmm13, 0x9C ; 9c = 10 01 11 00

  movaps xmm10, xmm4    ; cargo todos los h
  cmpltps xmm10, [_300]  ; comparo con 60

  pand xmm13, xmm10
  pand xmm13, xmm14

  pxor xmm10, [_todo1]
  pand xmm14, xmm10

  paddd xmm7, xmm13



;; 360 ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;en xmm13 formo el vector
  movaps xmm13, xmm9
  pshufd xmm13, xmm13, 0xD8 ; d8 = 11 01 10 00

  pand xmm13, xmm10
  pand xmm13, xmm14

  paddd xmm7, xmm13


  packusdw xmm7, xmm15
  packuswb xmm7, xmm15



  movss [r14 + 4*rcx], xmm7

  jmp hslTOrgbBack

