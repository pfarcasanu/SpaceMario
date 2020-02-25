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
platforms GameObject <100, 285, 0, 0, 0, OFFSET Platform>, 
  <300, 300, -10, 0, 0, OFFSET Platform>

.CODE

GameInit PROC

	ret
GameInit ENDP

GamePlay PROC
  ;; Perform Updates
  invoke UpdatePlayer

  ;; Draw
  invoke ClearScreen
  invoke BasicBlit, player.btmpPtr, player.posX, player.posY
  ; invoke BasicBlit, platform1.btmpPtr, platform1.posX, platform1.posY
  ; invoke BasicBlit, platform2.btmpPtr, platform2.posX, platform2.posY
  invoke DrawPlatforms
  invoke DrawStarField
	ret
GamePlay ENDP

;; ############################################
;;             Helper Functions
;; ############################################

ClearScreen PROC uses ecx edi
  cld
  mov ecx, 76800
  mov edi, ScreenBitsPtr
  mov eax, 0
  rep stosd
  ret
ClearScreen ENDP

DrawPlatforms PROC uses ecx
  xor ecx, ecx
  mov esi, OFFSET platforms
  jmp EVAL
  BODY:
    invoke BasicBlit, (GameObject PTR [esi + ecx]).btmpPtr, (GameObject PTR [esi + ecx]).posX, (GameObject PTR [esi + ecx]).posY
    add ecx, 24
  EVAL:
    cmp ecx, 25
    jl BODY
  ret
DrawPlatforms ENDP

UpdatePlayer PROC
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

CheckIntersect PROC oneX:DWORD, oneY:DWORD, oneBitmap:PTR EECS205BITMAP, twoX:DWORD, twoY:DWORD, twoBitmap:PTR EECS205BITMAP 
  ;; Collision Detection Procedure

  ret
CheckIntersect ENDP

END