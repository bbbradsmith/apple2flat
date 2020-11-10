; TAPEBOOT
;   This is an Applesoft BASIC program that can load from tape
;   and auto-start the main program when finished.
;   Type LOAD at the ] prompt, hit enter, and start playing the tape.

; TAPEBOOT will jump here on successful load
.import start

.import __TAPEBOOT1_SIZE__
.import __MAIN_START__
.import __MAIN_LAST__

.segment "TAPEBOOT0"
.word __TAPEBOOT1_SIZE__ - 1
;.byte $D5 ; lock and auto-run
.byte $55 ; unlocked for testing

.segment "TAPEBOOT1"

.macro BLINE n_
	.ident(.sprintf("line%d",n_)):
	.word .ident(.sprintf("line%d",n_+10))
	.word n_
.endmacro

.macro BEND n_
	.ident(.sprintf("line%d",n_)):
	.word 0
.endmacro

BOOT  = $0300 ; some free space to stash our loader
READ0 = __MAIN_START__
READ1 = __MAIN_LAST__ - 1

BLINE 10  ; 10 PRINT "LOADING A2P PROGRAM..."
.byte $BA,'"',"LOADING A2P PROGRAM...",'"',0
BLINE 20  ; 20 DATA ...
.byte $83,.sprintf(" %d,%d,%d,%d,%d",         $A9,$24,$48,$A9,<READ0),0
BLINE 30  ; 30 DATA ...
.byte $83,.sprintf(" %d,%d,%d,%d,%d,%d",  $A2,>READ0,$85,$3C,$86,$3D),0
BLINE 40  ; 40 DATA ...
.byte $83,.sprintf(" %d,%d,%d,%d",             $A9,<READ1,$A2,>READ1),0
BLINE 50  ; 50 DATA ...
.byte $83,.sprintf(" %d,%d,%d,%d,%d,%d",     $85,$3E,$86,$3F,$A0,$00),0
BLINE 60  ; 60 DATA ...
.byte $83,.sprintf(" %d,%d,%d,%d,%d,%d",     $20,$FD,$FE,$68,$C5,$24),0
BLINE 70  ; 70 DATA ...
.byte $83,.sprintf(" %d,%d,%d,%d,%d",            $F0,$03,$4C,$69,$FF),0
BLINE 80  ; 80 DATA ...
.byte $83,.sprintf(" %d,%d,%d",                    $4C,<start,>start),0
BLINE 90  ; 90 FOR I = 0 TO 34
.byte $81,"I",$D0,"0",$C1,"34",0
BLINE 100 ; 100 READ D
.byte $87,"D",0
BLINE 110 ; 110 POKE 768 + I,D
.byte $B9,.sprintf("%d",BOOT),$C8,"I,D",0
BLINE 120 ; 120 NEXT
.byte $82,0
BLINE 130 ; 130 CALL 768
.byte $8C,.sprintf("%d",BOOT),0
BLINE 140 ; 140 END
.byte $80,0
BEND 150

; DATA:
; A9 24      LDA $24     ; CH is COUT horizontal position
; 48         PHA
; A9 ..      LDA #<READ0
; A2 ..      LDX #>READ0
; 85 3C      STA $3C     ; READ start address
; 86 3D      STX $3D
; A9         LDA #<READ1
; A2         LDX #>READ1
; 85 3E      STA $3E     ; READ end address
; 86 3F      STX $3F
; A0 00      LDY #0      ; READ seems to expect Y=0 on entry?
; 20 FD FE   JSR $FEFD   ; READ loads data from tape input
; 68         PLA
; C5 24      CMP $24     ; READ error results in COUT of 'ERR', moving CH
; F0 03      BEQ +3      ; CH has not moved, therefore success. (Run program!)
; 4C 69 FF   JMP $FF69   ; MONZ * prompt for debugging
; 4C .. ..   JMP start   ; Run program!
