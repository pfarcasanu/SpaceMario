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
player GameObject <50, 350, 0, 0, 0, OFFSET MarioStanding>

;; Platforms
platform1 GameObject <50, 350, 0, 0, 0, OFFSET Platform>
platforms GameObject <50, 400, -4, 0, 0, OFFSET Platform>, 
  <200, 350, -4, 0, 0, OFFSET Platform>,
  <315, 375, -4, 0, 0, OFFSET Platform>,
  <475, 300, -4, 0, 0, OFFSET Platform>,
  <600, 275, -4, 0, 0, OFFSET Platform>

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

CheckPlayerCollisions PROC USES esi edi edx ebx ecx
  xor ecx, ecx
  mov esi, OFFSET platforms
  jmp EVAL
  BODY:
    invoke CheckIntersect, player.posX, player.posY, player.btmpPtr, 
      (GameObject PTR [esi + ecx]).posX, (GameObject PTR [esi + ecx]).posY, 
      (GameObject PTR [esi + ecx]).btmpPtr
    cmp eax, 0
    jne COLLIDED
    add ecx, TYPE GameObject
  EVAL:
    cmp ecx, SIZEOF platforms
    jl BODY

  xor eax, eax
  ret

  COLLIDED:
  mov eax, 0ffffffffh

  ret
CheckPlayerCollisions ENDP

UpdatePlayer PROC USES esi edi edx ebx ecx
  ;; Case Analysis On KeyPress
  cmp KeyPress, VK_UP
  je KEY_UP
  jmp PHYSICS_UPDATES

  KEY_UP:
    ;; Case 1: On Mouse Up
    mov player.velY, 0fff80000h
    jmp PHYSICS_UPDATES

  PHYSICS_UPDATES:
    ;; Update Position
    mov ebx, player.velY
    sar ebx, 16
    add player.posY, ebx

    ;; Factor in Gravity
    add player.velY, 0bfffh

  CHECK_COLLISIONS:
    invoke CheckIntersect, player.posX, player.posY, player.btmpPtr, 
      platform1.posX, platform1.posY, platform1.btmpPtr
    cmp eax, 0
    je UPDATE_LOOK

    ;; Collided: Kill the Velocity
    mov player.velY, 0

  UPDATE_LOOK:
    cmp player.velY, 0
    je STANDING
    mov player.btmpPtr, OFFSET MarioJumping
    jmp CONTINUE

  STANDING:
    mov player.btmpPtr, OFFSET MarioStanding

  CONTINUE:
  ret
UpdatePlayer ENDP

UpdatePlatforms PROC USES esi edi edx ebx ecx
  xor ecx, ecx
  mov esi, OFFSET platforms
  jmp EVAL
  BODY:
    mov ebx, (GameObject PTR [esi + ecx]).velX
    add (GameObject PTR [esi + ecx]).posX, ebx
    cmp (GameObject PTR [esi + ecx]).posX, 0
    jge CONTINUE
    mov (GameObject PTR [esi + ecx]).posX, 700
    CONTINUE:
    add ecx, TYPE GameObject
  EVAL:
    cmp ecx, SIZEOF platforms
    jl BODY
  ret
UpdatePlatforms ENDP

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

CheckIntersect PROC USES esi edi edx ebx ecx oneX:DWORD, oneY:DWORD, oneBitmap:PTR EECS205BITMAP, twoX:DWORD, twoY:DWORD, twoBitmap:PTR EECS205BITMAP 
  LOCAL width1:DWORD, height1:DWORD, width2:DWORD, height2:DWORD
  LOCAL x1:DWORD, y1:DWORD, x2:DWORD, y2:DWORD

  ;; Save the Bitmap widths and heights
  mov esi, oneBitmap
  mov eax, (EECS205BITMAP PTR [esi]).dwWidth
  mov width1, eax
  mov eax, (EECS205BITMAP PTR [esi]).dwHeight
  mov height1, eax

  mov esi, twoBitmap
  mov eax, (EECS205BITMAP PTR [esi]).dwWidth
  mov width2, eax
  mov eax, (EECS205BITMAP PTR [esi]).dwHeight
  mov height2, eax

  ;; Calculate the Corners
  mov eax, width1
  shr eax, 2
  neg eax
  add eax, oneX
  mov x1, eax

  mov eax, height1
  shr eax, 2
  neg eax
  add eax, oneY
  mov y1, eax

  mov eax, width2
  shr eax, 2
  neg eax
  add eax, twoX
  mov x2, eax

  mov eax, height2
  shr eax, 2
  neg eax
  add eax, twoY
  mov y2, eax

  ;; Case Analysis
  mov ecx, x2
  add ecx, width2
  cmp x1, ecx
  jge NO_COLLISION

  mov ecx, x1
  add ecx, width1
  cmp x2, ecx
  jge NO_COLLISION

  mov ecx, y2
  add ecx, height2
  cmp y1, ecx
  jge NO_COLLISION

  mov ecx, y1
  add ecx, height1
  cmp y2, ecx
  jge NO_COLLISION

  ;; Collision Occurred
  mov eax, 0ffffffffh
  jmp INTERSECT_RETURN

  NO_COLLISION:
  xor eax, eax

  INTERSECT_RETURN:
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
  invoke BasicBlit, platform1.btmpPtr, platform1.posX, platform1.posY
  invoke DrawPlatforms
  invoke DrawStarField
	ret
GamePlay ENDP

END