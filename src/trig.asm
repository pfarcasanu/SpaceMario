; #########################################################################
;
;   trig.asm - Assembly file for CompEng205 Assignment 3
;
;
; #########################################################################

      .586
      .MODEL FLAT,STDCALL
      .STACK 4096
      option casemap :none  ; case sensitive

include trig.inc

.DATA

;;  These are some useful constants (fixed point values that correspond to important angles)
PI_HALF = 102943           	;;  PI / 2
PI =  205887	                ;;  PI
TWO_PI	= 411774                ;;  2 * PI
PI_INC_RECIP =  5340353        	;;  Use reciprcal to find the table entry for a given angle
	                        ;;              (It is easier to use than divison would be)


	;; If you need to, you can place global variables here

.CODE

FixedSin PROC USES esi edi edx ebx ecx angle:FXPT
	xor eax, eax

  ;; Case 0: angle is 0
  cmp angle, 0
  je FIXED_SIN_RET
  ;; Case 1: angle < 0
  cmp angle, 0
  jl BELOW_ZERO
  ;; Case 2: angle is in range [0, pi/2]
  cmp angle, PI_HALF
  jle ZERO_TO_PI_HALF
  ;; Case 3: angle is in range [pi/2, pi]
  cmp angle, PI
  jl PI_HALF_TO_PI
  ;; Case 4: angle is in range [pi, 2*pi]
  cmp angle, TWO_PI
  jl PI_TO_2_PI
  ;; Case 5: else
  jmp ABOVE_2_PI

  BELOW_ZERO:
  ;; Angle < 0
  ;; Invoke Fixed Sin with pi + 2 pi
  mov ebx, TWO_PI
  add ebx, angle
  invoke FixedSin, ebx
  jmp FIXED_SIN_RET

  ZERO_TO_PI_HALF:
  ;; Angle in [0, pi/2]
  ;; Multiply by pi_reciprcal, round by using only the upper bits in edx
  mov eax, angle
  mov ebx, PI_INC_RECIP
  mul ebx
  mov esi, edx
  xor eax, eax
  mov ax, [SINTAB + 2*esi]
  jmp FIXED_SIN_RET

  PI_HALF_TO_PI:
  ;; Angle in [pi/2, pi]
  ;; Invoke FixedSin with pi - x
  mov ebx, PI
  sub ebx, angle
  invoke FixedSin, ebx
  jmp FIXED_SIN_RET

  PI_TO_2_PI:
  ;; Angle in [pi, 2pi]
  ;; Subtract pi from angle, invoke FixedSin and flip sign
  mov ebx, angle
  sub ebx, PI
  invoke FixedSin, ebx
  neg eax
  jmp FIXED_SIN_RET

  ABOVE_2_PI:
  ;; Angle > 2pi
  ;; Subtract 2pi from angle and invoke FixedSin
  mov ebx, angle
  sub ebx, TWO_PI
  invoke FixedSin, ebx
  jmp FIXED_SIN_RET

  FIXED_SIN_RET:
	ret			; Don't delete this line!!!
FixedSin ENDP

FixedCos PROC USES esi edi edx ebx ecx angle:FXPT
  ; Add pi/2 and call FixedSin
  mov ebx, angle
  add ebx, PI_HALF
  invoke FixedSin, ebx
	ret
FixedCos ENDP
END
