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

;; Player is a Game Object
player GameObject <320, 240, 0, 0, 0, ?>
DELTA_TIME FXPT 0ffh

.CODE

GameInit PROC
	;; Set up the Player
  mov player.btmpPtr, OFFSET MarioStanding

	ret
GameInit ENDP

GamePlay PROC
  ;; Clear the Screen, Update the Player
  invoke ClearScreen
  invoke UpdatePlayer
  invoke BasicBlit, player.btmpPtr, player.posX, player.posY
  invoke DrawStarField
	ret
GamePlay ENDP

;; ################
;; Helper Functions
;; ################

ClearScreen PROC uses ecx edi
  cld
  mov ecx, 76800
  mov edi, ScreenBitsPtr
  mov eax, 0
  rep stosd
  ret
ClearScreen ENDP

UpdatePlayer PROC
  ;; Performs updates on the players fields

  ;; Case Analysis On KeyPress
  cmp KeyPress, VK_UP
  je MOUSE_LEFT
  
  jmp AFTER_CASE_ANALYSIS

  MOUSE_LEFT:
  ;; Case 1: on MouseLeft, fire the engines
  mov player.btmpPtr, OFFSET MarioJumping
  jmp AFTER_CASE_ANALYSIS


  AFTER_CASE_ANALYSIS:
  ret
UpdatePlayer ENDP

CheckIntersect PROC oneX:DWORD, oneY:DWORD, oneBitmap:PTR EECS205BITMAP, twoX:DWORD, twoY:DWORD, twoBitmap:PTR EECS205BITMAP 
  ;; Collision Detection Procedure

  ret
CheckIntersect ENDP

END