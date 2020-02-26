; #########################################################################
;
; Overview (Space Mario)
;     -- Infinite sidescroller
;     -- How To play
;         -- Up Arrow: mario jumps
;         -- Left Mouse: mario shoots a fireball (fireball does nothing)
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
;; Player State, 0 = cant jump, 1 = can jump
player GameObject <50, 250, 0, 0, ?, OFFSET MarioStanding, 1>

;; Platforms
platforms GameObject <160, 355, -5, 0, ?, OFFSET Platform, ?>,
  <330, 305, -5, 0, ?, OFFSET Platform, ?>,
  <510, 285, -5, 0, ?, OFFSET Platform, ?>,
  <665, 345, -5, 0, ?, OFFSET Platform, ?>

;; Fireball
fireball GameObject <-100, ?, ?, ?, ?, OFFSET Fireball, ?>

.CODE

;; ##################################################################
;;                        Drawing Functions
;; ##################################################################

ClearScreen PROC USES esi edi edx ebx ecx
  cld
  mov ecx, 76800
  mov edi, ScreenBitsPtr
  mov eax, 0
  rep stosd
  ret
ClearScreen ENDP

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

;; ##################################################################
;;                        Collision Functions
;; ##################################################################

CheckPlayerCollisions PROC USES esi edi edx ebx ecx
  xor ecx, ecx
  mov esi, OFFSET platforms
  jmp EVAL
  BODY:
    ;; Call off to CheckIntersect
    invoke CheckIntersect, player.posX, player.posY, player.btmpPtr, 
      (GameObject PTR [esi + ecx]).posX, (GameObject PTR [esi + ecx]).posY, 
      (GameObject PTR [esi + ecx]).btmpPtr
    ;; If CheckIntersect returns non-zero, a collision occurred
    cmp eax, 0
    jne COLLIDED
    add ecx, TYPE GameObject
  EVAL:
    cmp ecx, SIZEOF platforms
    jl BODY

  ;; If we got here, return 0
  xor eax, eax
  ret

  COLLIDED:
    ;; Return a Pointer to the Collided Object
    mov eax, esi
    add eax, ecx
  ret
CheckPlayerCollisions ENDP

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

  ;; Calculate the Top Left Corners of the Bitmaps
  ;; x = centerX - width/2
  ;; y = centerY - height/2
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

  ;; A Collision Occcurs If:
  ;;    x1 < x2 + width2 && x1 + width1 > x2 && 
  ;;    y1 < y2 + height2 && y1 + height1 > y2
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

;; ##################################################################
;;                         Event Handlers
;; ##################################################################

PlayerJump PROC USES esi edi edx ebx ecx
  mov ecx, player.state
  cmp ecx, 1
  jne CONTINUE
  mov player.velY, 0fff60000h
  mov player.state, 0
  CONTINUE:
  ret
PlayerJump ENDP

FireProjectile PROC USES esi edi edx ebx ecx
  mov ecx, fireball.posX
  cmp ecx, 0
  jg CONTINUE

  FIRE:
    ;; Move the projectile to where the player is
    ;; Give it velocity
    mov ecx, player.posX
    add ecx, 30
    mov ebx, player.posY
    mov fireball.posX, ecx
    mov fireball.posY, ebx
    mov fireball.velX, 5
    jmp CONTINUE
  
  CONTINUE:
  ret
FireProjectile ENDP

HandleKeyPress PROC USES esi edi edx ebx ecx
  ;; Case Analysis On KeyPress
  cmp KeyPress, VK_UP
  je KEY_UP
  jmp CONTINUE

  KEY_UP:
    ;; Case 1: On Key Up --> Player Jumps
    invoke PlayerJump
    jmp CONTINUE

  CONTINUE:
  ret
HandleKeyPress ENDP

HandleMouseClicks PROC USES esi edi edx ebx ecx
  ;; Case Analysis On Mouse Buttons
  mov ecx, MouseStatus.buttons
  cmp ecx, MK_LBUTTON
  je LEFT_BUTTON
  jmp CONTINUE

  LEFT_BUTTON:
    ;; Case 1: On Left Mouse --> Fireball
    invoke FireProjectile
    jmp CONTINUE

  CONTINUE:
  ret
HandleMouseClicks ENDP

;; ##################################################################
;;                        Update Functions
;; ##################################################################

UpdatePlayer PROC USES esi edi edx ebx ecx
  PHYSICS_UPDATES:
    ;; Update Position
    mov ebx, player.velY
    sar ebx, 16
    add player.posY, ebx

    ;; Factor in Gravity
    add player.velY, 0cfffh

  CHECK_COLLISIONS:
    invoke CheckPlayerCollisions
    cmp eax, 0
    je UPDATE_LOOK

    ;; Collided
    ;; Assume the player is below the platform, increase the Velocity
    mov player.velY, 01ffffh
    mov ebx, (GameObject PTR [eax]).posY
    cmp player.posY, ebx
    jge UPDATE_LOOK

    ;; If the Player is above the platform, kill velocity
    ;; Reset the position to be above the platform
    ;; Reset state so player can jump
    mov player.velY, 0
    sub ebx, 30
    mov player.posY, ebx
    mov player.state, 1

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

UpdateFireball PROC USES esi edi edx ebx ecx
  mov ecx, fireball.posX
  cmp ecx, 0
  jl CONTINUE
  cmp ecx, 340
  jge RESET_FIREBALL

  MOVE_FIREBALL:
    add ecx, fireball.velX
    mov fireball.posX, ecx
    jmp CONTINUE
  
  RESET_FIREBALL:
    mov fireball.posX, -100
    jmp CONTINUE

  CONTINUE:
  ret
UpdateFireball ENDP

;; ############################################
;;               Main Functions
;; ############################################

GameInit PROC USES esi edi edx ebx ecx

	ret
GameInit ENDP

GamePlay PROC USES esi edi edx ebx ecx
  ;; Handle User Input
  invoke HandleKeyPress
  invoke HandleMouseClicks

  ;; Perform Updates
  invoke UpdatePlayer
  invoke UpdatePlatforms
  invoke UpdateFireball

  ;; Draw
  invoke ClearScreen
  invoke DrawStarField
  invoke DrawPlatforms
  invoke BasicBlit, fireball.btmpPtr, fireball.posX, fireball.posY
  invoke BasicBlit, player.btmpPtr, player.posX, player.posY
	ret
GamePlay ENDP

END