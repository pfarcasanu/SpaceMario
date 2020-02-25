; #########################################################################
;
;   lines.asm - Assembly file for CompEng205 Assignment 2
;
;
; #########################################################################

      .586
      .MODEL FLAT,STDCALL
      .STACK 4096
      option casemap :none  ; case sensitive

include stars.inc
include lines.inc

.DATA

	;; If you need to, you can place global variables here

.CODE


;; My name: Paul Farcasanu

DrawLine PROC USES eax ecx edi esi x0:DWORD, y0:DWORD, x1:DWORD, y1:DWORD, color:DWORD
	;; Feel free to use local variables...declare them here
	;; For example:
	;; 	LOCAL foo:DWORD, bar:DWORD

  LOCAL delta_x:DWORD, delta_y:DWORD, inc_x:DWORD, inc_y:DWORD, error:DWORD

	;; Place your code here

  ;; compute delta_x --> delta_x
  mov eax, x1
  sub eax, x0
  cmp eax, 0
  jg delta_x_end
  neg eax
delta_x_end:
  mov delta_x, eax

  ;; compute delta_y --> delta_y
  mov eax, y1
  sub eax, y0
  cmp eax, 0
  jg delta_y_end
  neg eax
delta_y_end:
  mov delta_y, eax

  ;; compute inc_x --> inc_x
  mov eax, x0
  cmp eax, x1
  jge inc_x_else
  mov inc_x, 1
  jmp inc_x_end
inc_x_else:
  mov inc_x, -1
inc_x_end:

  ;; compute inc_y --> inc_y
  mov eax, y0
  cmp eax, y1
  jge inc_y_else
  mov inc_y, 1
  jmp inc_y_end
inc_y_else:
  mov inc_y, -1
inc_y_end:

  ;; compute error --> error
  mov eax, delta_x
  mov ecx, delta_y
  cmp eax, ecx
  jle error_else
  shr eax, 1
  mov error, eax
  jmp error_end
error_else:
  shr ecx, 1
  neg ecx
  mov error, ecx
error_end:

  ;; First draw: eax = curr_x, ecx = curr_y
  mov eax, x0
  mov ecx, y0
  invoke DrawPixel, eax, ecx, color

  ;; While Loop: error = edi, flip delta_x
  mov edi, error
  neg delta_x
  jmp eval
body:
  invoke DrawPixel, eax, ecx, color
  mov esi, edi
  cmp esi, delta_x
  jle continue
  sub edi, delta_y
  add eax, inc_x
continue:
  cmp esi, delta_y
  jge eval
  sub edi, delta_x
  add ecx, inc_y
eval:
  cmp eax, x1
  jne body
  cmp ecx, y1
  jne body

	ret        	;;  Don't delete this line...you need it
DrawLine ENDP




END
