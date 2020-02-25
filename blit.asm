; #########################################################################
;
;   blit.asm - Assembly file for CompEng205 Assignment 3
;
;
; #########################################################################

      .586
      .MODEL FLAT,STDCALL
      .STACK 4096
      option casemap :none  ; case sensitive

include stars.inc
include lines.inc
include trig.inc
include blit.inc


.DATA

	;; If you need to, you can place global variables here
	
.CODE

DrawPixel PROC uses esi ebx edx x:DWORD, y:DWORD, color:DWORD
  ;; Skip to the end if out of bounds
  cmp x, 0
  jl DRAW_PIXEL_END
  cmp y, 0
  jl DRAW_PIXEL_END
  cmp x, 639
  jg DRAW_PIXEL_END
  cmp y, 479
  jg DRAW_PIXEL_END

  ;; Calculate the index with 640 * y + x
  ;; Write a byte to the array at that location
  mov eax, y
  mov ebx, 640
  mul ebx
  add eax, x
  mov esi, ScreenBitsPtr
  mov edx, color
  mov [esi + eax], dl

  DRAW_PIXEL_END:
	ret 			; Don't delete this line!!!
DrawPixel ENDP

BasicBlit PROC USES esi edi ecx edx ebx ptrBitmap:PTR EECS205BITMAP , xcenter:DWORD, ycenter:DWORD
  LOCAL xStartPos:DWORD, yStartPos:DWORD
  LOCAL dwWidth:DWORD, dwHeight:DWORD
  LOCAL tColor:BYTE
  LOCAL srcX:FXPT, srcY:FXPT

  ;; save the Bitmap Pointer, width, and height
  mov esi, ptrBitmap
  mov eax, (EECS205BITMAP PTR [esi]).dwWidth
  mov dwWidth, eax
  mov eax, (EECS205BITMAP PTR [esi]).dwHeight
  mov dwHeight, eax

  ;; Calculate the x and y starting positions and final positions
  ;; using formula: startPos = -(width/2) + center
  mov eax, dwWidth
  shr eax, 1
  neg eax
  add eax, xcenter
  mov xStartPos, eax

  mov eax, dwHeight
  shr eax, 1
  neg eax
  add eax, ycenter
  mov yStartPos, eax

  ;; Save the lP bytes pointer and transparent color
  mov edi, (EECS205BITMAP PTR [esi]).lpBytes
  mov al, (EECS205BITMAP PTR [esi]).bTransparent
  mov tColor, al

  ;; Nested For-Loop that calls DrawPixel
  mov ecx, 0
  jmp eval_outer

  body_outer:
  mov esi, 0
  jmp eval_inner

    body_inner:
    ;; Calculate the color, skip if equal to bTransparent
    ;; Index array using dwWidth * y_loop + x_loop
    mov eax, dwWidth
    mul esi
    add eax, ecx
    mov bl, [edi + eax]
    cmp bl, tColor
    je END_DRAW

    ;; Add startPos to ecx and esi, then revert 
    add ecx, xStartPos
    add esi, yStartPos
    invoke DrawPixel, ecx, esi, bl
    sub ecx, xStartPos
    sub esi, yStartPos
    
    END_DRAW:
    inc esi

    eval_inner:
    cmp esi, dwHeight
    jl body_inner
  
  inc ecx
  
  eval_outer:
  cmp ecx, dwWidth
  jl body_outer

  ret
BasicBlit ENDP

TwosComplement PROC num:DWORD
  mov eax, num
  not eax
  inc eax
  ret
TwosComplement ENDP

IntTimesFxpt PROC USES edx ebx dwInt:DWORD, fxptNum:FXPT 
  ;; Multiplies an int by a fxpt --> returns a fixed point

  mov bl, 0 ;; byte keeps track of if result should be negative

  ;; If the Int is negative, flip it to a positive int
  ;; Flip bl as well
  cmp dwInt, 0
  jge CMP_FXPT
  invoke TwosComplement, dwInt
  mov dwInt, eax
  not bl

  CMP_FXPT:
  ;; if the fxpt < 0, flip it to positive
  ;; Flip bl
  cmp fxptNum, 0
  jge COMPUTE_MULTIPLY
  invoke TwosComplement, fxptNum
  mov fxptNum, eax
  not bl

  COMPUTE_MULTIPLY:
  ;; Shifts eax to convert it to fixed point
  ;; Multiplies, combines the 16 lowest bits of edx and 16 highest of eax
  mov eax, dwInt
  shl eax, 16
  mul fxptNum
  shr eax, 16
  shl edx, 16
  or eax, edx

  ;; if bl is a 1, then the answer should be negative
  cmp bl, 0
  je MULTIPLY_END
  not eax
  inc eax

  MULTIPLY_END:
	ret
IntTimesFxpt ENDP

FxptToInt PROC fxptVal:FXPT
  ;; shifts arithmetically to convert fixpt to int
  mov eax, fxptVal
  sar eax, 16
  ret
FxptToInt ENDP

RotateBlit PROC USES esi edi ebx edx ecx lpBmp:PTR EECS205BITMAP, xcenter:DWORD, ycenter:DWORD, angle:FXPT
  LOCAL cosA:FXPT, sinA:FXPT, shiftX:FXPT, shiftY:FXPT
  LOCAL srcX:FXPT, srcY:FXPT, dstX:FXPT, dstY:FXPT
  LOCAL dwWidth:DWORD, dwHeight:DWORD, dstWidth:DWORD, dstHeight:DWORD
  LOCAL xCenterCalc:DWORD, yCenterCalc:DWORD, tColor:DWORD, bTransparent:BYTE 
  
  ;; Calculate cos and sin of the angle
  invoke FixedCos, angle
  mov cosA, eax
  invoke FixedSin, angle
  mov sinA, eax

  ;; Store bitmap ptr in esi, grab width and height
  mov esi, lpBmp
  mov eax, (EECS205BITMAP PTR [esi]).dwWidth
  mov dwWidth, eax
  mov eax, (EECS205BITMAP PTR [esi]).dwHeight
  mov dwHeight, eax
  mov al, (EECS205BITMAP PTR [esi]).bTransparent
  mov bTransparent, al

  ;; Calculate Shift x and shift y
  ;; Follow the Formula, use function IntTimesFxpt to do multiplication
  mov ebx, cosA
  sar ebx, 1
  invoke IntTimesFxpt, dwWidth, ebx
  mov shiftX, eax
  mov ebx, sinA
  sar ebx, 1
  invoke IntTimesFxpt, dwHeight, ebx
  sub shiftX, eax

  mov ebx, cosA
  sar ebx, 1
  invoke IntTimesFxpt, dwHeight, ebx
  mov shiftY, eax
  mov ebx, sinA
  sar ebx, 1
  invoke IntTimesFxpt, dwWidth, ebx
  add shiftY, eax

  ;; Convert ShiftX and ShiftY To Ints
  ;; Uses conversion function
  invoke FxptToInt, shiftX
  mov shiftX, eax
  invoke FxptToInt, shiftY
  mov shiftY, eax

  ;; Calculate the dstWidth and Height
  mov eax, dwWidth
  add eax, dwHeight
  mov dstWidth, eax
  mov dstHeight, eax

  ;; Double for-loop
  mov eax, dstWidth
  neg eax
  mov dstX, eax
  jmp EVAL_OUTER_ROT
  BODY_OUTER_ROT:
  mov eax, dstHeight
  neg eax
  mov dstY, eax
  jmp EVAL_INNER_ROT

    BODY_INNER_ROT:
    ;; Calculate srcX and srcY using the two functions
    ;; Eax contains srcY, ebx contains srcX
    invoke IntTimesFxpt, dstX, cosA
    mov srcX, eax
    invoke IntTimesFxpt, dstY, sinA
    add srcX, eax
    invoke FxptToInt, srcX
    mov srcX, eax

    invoke IntTimesFxpt, dstY, cosA
    mov srcY, eax
    invoke IntTimesFxpt, dstX, sinA
    sub srcY, eax
    invoke FxptToInt, srcY
    mov srcY, eax

    ;; With srcX and srcY calculated, determine whether or not to skip
    mov eax, srcX
    cmp eax, 0
    jl SKIP_DRAW_ROT
    cmp eax, dwWidth
    jge SKIP_DRAW_ROT

    mov eax, srcY
    cmp eax, 0
    jl SKIP_DRAW_ROT
    cmp eax, dwHeight
    jge SKIP_DRAW_ROT

    ;; Calculate (xcenter + dstX - shiftX) and (ycenter + dstY - shiftY)
    ;; More conditionals based off the center position
    mov edx, xcenter
    add edx, dstX
    sub edx, shiftX
    mov xCenterCalc, edx
    cmp xCenterCalc, 0
    jl SKIP_DRAW_ROT
    cmp xCenterCalc, 639
    jg SKIP_DRAW_ROT

    mov edx, ycenter
    add edx, dstY
    sub edx, shiftY
    mov yCenterCalc, edx
    cmp yCenterCalc, 0
    jl SKIP_DRAW_ROT
    cmp yCenterCalc, 479
    jg SKIP_DRAW_ROT

    ;; Calculate the color, compare to bTransparent
    ;; Calculate index with srcY * dwWidth + srcX
    ;; If equal, skip
    mov ebx, dwWidth
    mov eax, srcY
    mul ebx
    add eax, srcX
    mov edx, (EECS205BITMAP PTR [esi]).lpBytes
    mov bl, [eax + edx]
    cmp bl, bTransparent
    je SKIP_DRAW_ROT

    ;; Actually do the draw
    invoke DrawPixel, xCenterCalc, yCenterCalc, bl

    SKIP_DRAW_ROT:
    inc dstY

    EVAL_INNER_ROT:
    mov eax, dstY
    cmp eax, dstHeight
    jl BODY_INNER_ROT
  
  inc dstX
  
  EVAL_OUTER_ROT:
  mov eax, dstX
  cmp eax, dstWidth
  jl BODY_OUTER_ROT

  ret
RotateBlit ENDP

END
