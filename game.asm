; #########################################################################
;
;   game.asm - Assembly file for CompEng205 Assignment 4/5
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
include game.inc

;; Has keycodes
include keys.inc

	
.DATA

;; Fxpt Value to mark how much time passes each frame
DELTA_TIME FXPT 0ffh

;; Player is a Game Object
player GameObject <320, 240, 0, 0, 0, OFFSET MarioStanding>

;; Platforms
platforms GameObject <100, 285, -3, 0, 0, OFFSET Platform>, 
  <225, 285, -3, 0, 0, OFFSET Platform>,
  <350, 285, -3, 0, 0, OFFSET Platform>,
  <475, 285, -3, 0, 0, OFFSET Platform>,
  <600, 285, -3, 0, 0, OFFSET Platform>

.CODE

;; ############################################
;;             Helper Functions
;; ############################################

ClearScreen PROC USES esi edi edx ebx ecx
  cld
  mov ecx, 76800
  mov edi, ScreenBitsPtr
  mov eax, 0
  rep stosd
  ret
ClearScreen ENDP

UpdatePlayer PROC USES esi edi edx ebx ecx
  ;; Case Analysis On KeyPress
  cmp KeyPress, VK_UP
  je KEY_UP
  jmp PHYSICS_UPDATES

  KEY_UP:
    ;; Case 1: on MouseLeft, fire the engines
    mov player.btmpPtr, OFFSET MarioJumping
    jmp PHYSICS_UPDATES

  PHYSICS_UPDATES:
  ret
UpdatePlayer ENDP

DrawPlatforms PROC USES esi edi edx ebx ecx
  xor ecx, ecx
  mov esi, OFFSET platforms
  jmp EVAL
  BODY:
    push ecx
    push esi
    invoke BasicBlit, (GameObject PTR [esi + ecx]).btmpPtr, (GameObject PTR [esi + ecx]).posX, 
      (GameObject PTR [esi + ecx]).posY
    pop esi
    pop ecx
    add ecx, TYPE GameObject
  EVAL:
    cmp ecx, SIZEOF platforms
    jl BODY
  ret
DrawPlatforms ENDP

UpdatePlatforms PROC USES esi edi edx ebx ecx
  xor ecx, ecx
  mov esi, OFFSET platforms
  jmp EVAL
  BODY:
    push ecx
    push esi

    mov ebx, (GameObject PTR [esi + ecx]).posX
    mov edx, (GameObject PTR [esi + ecx]).velX
    add ebx, edx
    mov (GameObject PTR [esi + ecx]).posX, ebx

    pop esi
    pop ecx

    add ecx, TYPE GameObject
  EVAL:
    cmp ecx, SIZEOF platforms
    jl BODY
  ret
UpdatePlatforms ENDP

CheckIntersect PROC USES esi edi edx ebx ecx oneX:DWORD, oneY:DWORD, oneBitmap:PTR EECS205BITMAP, twoX:DWORD, twoY:DWORD, twoBitmap:PTR EECS205BITMAP 
  ;; Collision Detection

  ret
CheckIntersect ENDP


;; ############################################
;;               Main Functions
;; ############################################


GameInit PROC USES esi edi edx ebx ecx

	ret
GameInit ENDP

GamePlay PROC USES esi edi edx ebx ecx
  ;; Perform Updates
  invoke UpdatePlayer
  invoke UpdatePlatforms

  ;; Draw
  invoke ClearScreen
  invoke BasicBlit, player.btmpPtr, player.posX, player.posY
  invoke DrawPlatforms
  invoke DrawStarField
	ret
GamePlay ENDP

END