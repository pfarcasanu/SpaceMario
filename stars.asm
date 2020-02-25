; #########################################################################
;
;   stars.asm - Assembly file for CompEng205 Assignment 1
;
;
; #########################################################################

      .586
      .MODEL FLAT,STDCALL
      .STACK 4096
      option casemap :none  ; case sensitive


include stars.inc

.DATA

	;; If you need to, you can place global variables here

.CODE

;; DrawStar () --> (void)
;; Makes 18 calls to DrawStar, creating a starry night
;; DrawStar called with x, y value corresponding to pixel on a 640x480 screen
DrawStarField proc

  invoke DrawStar, 130, 55
	invoke DrawStar, 50, 100
	invoke DrawStar, 170, 160
	invoke DrawStar, 20, 250
  invoke DrawStar, 140, 350
	invoke DrawStar, 50, 450
  invoke DrawStar, 330, 55
  invoke DrawStar, 250, 100
  invoke DrawStar, 370, 159
  invoke DrawStar, 220, 250
  invoke DrawStar, 340, 350
  invoke DrawStar, 250, 440
  invoke DrawStar, 430, 20
  invoke DrawStar, 450, 100
  invoke DrawStar, 570, 150
  invoke DrawStar, 420, 230
  invoke DrawStar, 540, 340
  invoke DrawStar, 650, 452

	ret  			; Careful! Don't remove this line
DrawStarField endp



END
