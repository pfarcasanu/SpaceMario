; #########################################################################
;
; Overview (Space Mario)
;     -- Infinite sidescroller in space
;     -- How To play
;         -- Up Arrow: mario jumps
;         -- P: Game Pauses
;         -- R: If game is over, you can press this to restart
;     -- Win Condition: you hit 50 points
;     -- Lose Condition: you fall off
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
include \Users\paulfarcasanu\wine-masm\drive_c\masm32\include\windows.inc
include \Users\paulfarcasanu\wine-masm\drive_c\masm32\include\winmm.inc
include \Users\paulfarcasanu\wine-masm\drive_c\masm32\include\user32.inc
includelib \Users\paulfarcasanu\wine-masm\drive_c\masm32\lib\winmm.lib
includelib \Users\paulfarcasanu\wine-masm\drive_c\masm32\lib\user32.lib

;; Has keycodes
include keys.inc

.DATA

;; Init a Struct to keep track of game state
;; Initially, game is running (0)
gamestate GameState <0, 0>

;; Player is a Game Object
;; Player State, 0 = cant jump, 1 = can jump
player GameObject <50, 250, 0, 0, ?, OFFSET MarioStanding, 1>

;; Platforms Array
platformX DWORD 160, 330, 510, 665
platformY DWORD 355, 305, 285, 345
platforms GameObject <160, 355, -5, 0, ?, OFFSET Platform, ?>,
  <330, 305, -5, 0, ?, OFFSET Platform, ?>,
  <510, 285, -5, 0, ?, OFFSET Platform, ?>,
  <665, 345, -5, 0, ?, OFFSET Platform, ?>

;; Scrolling Background Array
backgrounds GameObject <600, 40, -1, ?, ?, OFFSET Sun, ?>,
  <1280, 40, -1, ?, ?, OFFSET Moon, ?>

;; Audio
SongPath BYTE "rest.wav", 0

;; Text
GameOverText BYTE "You lost :(   Press R to restart", 0
GameWonText  BYTE "You won!  Press R to restart", 0
GamePauseText BYTE "Paused", 0
fmtStr BYTE "Up Arrow: Jump       P: Toggle Pause       Score: %d", 0
outStr BYTE 256 DUP(0)

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

DrawObjects PROC USES esi edi edx ebx ecx arrayPtr:DWORD, arraySize:DWORD
  ;; General function for bliting GameObjects
  ;; Takes an array pointer and size
  xor ecx, ecx
  mov esi, arrayPtr
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
    cmp ecx, arraySize
    jl BODY
  ret
DrawObjects ENDP

DrawScore PROC USES esi edi edx ebx ecx 
  movzx eax, gamestate.score
  push eax
  push offset fmtStr
  push offset outStr
  call wsprintf
  add esp, 12
  invoke DrawStr, offset outStr, 100, 425, 0ffh
  ret
DrawScore ENDP

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
  ;; Player Can only jump if state = 1
  ;; Player must also not be falling
  mov ecx, player.state
  cmp ecx, 1
  jne CONTINUE

  mov ebx, player.velY
  cmp ebx, 0
  jne CONTINUE

  mov player.velY, 0fff60000h
  mov player.state, 0
  CONTINUE:
  ret
PlayerJump ENDP

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

HandleKeyDown PROC USES esi edi edx ebx ecx
  ;; Case Analysis on Key Down
  cmp KeyDown, VK_P
  je KEY_P
  cmp KeyDown, VK_R
  je KEY_R
  jmp CONTINUE

  KEY_P:
    ;; Flip whether or not game is running
    mov cl, gamestate.state
    cmp cl, 0
    je RUNNING
    cmp cl, 1
    je PAUSED
    jmp CONTINUE

    RUNNING:
      mov gamestate.state, 1
      jmp CONTINUE
    
    PAUSED:
      mov gamestate.state, 0
      jmp CONTINUE

  KEY_R:
    ;; Restart the game if in menu
    mov cl, gamestate.state
    cmp cl, 2
    jl CONTINUE

    invoke GameInit
    jmp CONTINUE

  CONTINUE:
  mov KeyDown, 0
  ret
HandleKeyDown ENDP

;; ##################################################################
;;                        Update Functions
;; ##################################################################

UpdatePlayer PROC USES esi edi edx ebx ecx
  LIFE_UPDATES:
    ;; Check to see if the player died
    mov edx, player.posY
    cmp edx, 630
    jl PHYSICS_UPDATES
    mov gamestate.state, 2

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

UpdateObjects PROC USES esi edi edx ebx ecx arrayPtr:DWORD, 
  arraySize:DWORD, resetX:DWORD, score:BYTE
  ;; General Function for GameObject physics updates
  ;; Takes a pointer to an array, array size and value to reset position to
  ;; Also takes a score value to update gamescore by
  xor ecx, ecx
  mov esi, arrayPtr
  jmp EVAL
  BODY:
    mov ebx, (GameObject PTR [esi + ecx]).velX
    add (GameObject PTR [esi + ecx]).posX, ebx
    cmp (GameObject PTR [esi + ecx]).posX, 0
    jge CONTINUE

    ;; The object has gone off screen
    ;; Reset its postion and increment score
    mov edx, resetX
    mov (GameObject PTR [esi + ecx]).posX, edx
    mov bl, score
    add gamestate.score, bl
    CONTINUE:
    add ecx, TYPE GameObject
  EVAL:
    cmp ecx, arraySize
    jl BODY
  ret
UpdateObjects ENDP

CheckScore PROC USES esi edi edx ebx ecx 
  ;; If score > 50, player wins
  mov cl, gamestate.score
  cmp cl, 50
  jl CONTINUE
  mov gamestate.state, 3
  CONTINUE:
  ret
CheckScore ENDP

;; ############################################
;;             Main Functions & Init
;; ############################################

InitPlatforms PROC USES esi edi edx ebx ecx
  ;; Initializes Platform x and y positions
  xor ecx, ecx
  xor edx, edx
  jmp EVAL
  BODY:
    mov esi, [platformX + edx]
    mov edi, [platformY + edx]
    mov (GameObject PTR [platforms + ecx]).posX, esi
    mov (GameObject PTR [platforms + ecx]).posY, edi
    add ecx, TYPE GameObject
    add edx, TYPE DWORD
  EVAL:
    cmp ecx, SIZEOF platforms
    jl BODY
  ret
InitPlatforms ENDP

GameInit PROC USES esi edi edx ebx ecx
  ;; Start Playing Music
	invoke PlaySound, offset SongPath, 0, SND_ASYNC

  ;; Reset Objects & Player
  mov player.posY, 250
  mov player.velY, 0
  invoke InitPlatforms

  ;; Game state is running, score is 0
  mov gamestate.state, 0
  mov gamestate.score, 0

  ret
GameInit ENDP

GamePlay PROC USES esi edi edx ebx ecx
  ;; Handle KeyDown no matter what
  invoke HandleKeyDown

  ;; Case Analysis on the Different States
  ;; Running, Paused, and Menu
  mov cl, gamestate.state
  cmp cl, 0
  je RUNNING
  cmp cl, 1
  je PAUSED
  cmp cl, 2
  je MENU_LOST
  cmp cl, 3
  je MENU_WON

  RUNNING:
    ;; Handle User Input
    invoke HandleKeyPress

    ;; Perform Updates
    invoke UpdatePlayer
    invoke UpdateObjects, OFFSET backgrounds, SIZEOF backgrounds, 1290, 10
    invoke UpdateObjects, OFFSET platforms, SIZEOF platforms, 700, 1
    invoke CheckScore

    ;; Draw
    invoke ClearScreen
    invoke DrawStarField
    invoke DrawObjects, OFFSET platforms, SIZEOF platforms
    invoke DrawObjects, OFFSET backgrounds, SIZEOF backgrounds
    invoke BasicBlit, player.btmpPtr, player.posX, player.posY
    invoke DrawScore
    jmp CONTINUE

  PAUSED:
    ;; Draw Pause Text
    invoke DrawStr, OFFSET GamePauseText, 280, 220, 0ffh
    jmp CONTINUE

  MENU_LOST:
    ;; Draw the game over text
    invoke ClearScreen
    invoke DrawStr, OFFSET GameOverText, 190, 220, 0ffh
    jmp CONTINUE

  MENU_WON:
    ;; Draw the game over text
    invoke ClearScreen
    invoke DrawStr, OFFSET GameWonText, 200, 220, 0ffh
    jmp CONTINUE

  CONTINUE:
	ret
GamePlay ENDP

END