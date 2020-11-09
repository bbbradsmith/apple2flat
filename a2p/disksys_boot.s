; DISKBOOT & DISKSYS
;  These are routines for creating a bootable 16-sector disk.
;  The read routines will let you load/save 256-byte sectors from the disk, instead of using the DOS file system.
;  It is is informed by, but simpler than, the RWST-16 routines from Apple DOS 3.3.

.include "../a2p.inc"

; DISKBOOT will jump here on successful startup
.import start

; ZEROPAGE imports (defined elsewhere so they can be reused)
.importzp disksys_ptr ; 2-bytes: pointer to read ouput
.importzp disksys_temp ; 2-bytes

; DISKSYS public exports

.export disksys_error ; byte: last error code

.export disksys_read
; Reads contiguous 256-byte sectors from disk:
;   X:A = (track * 16) + sector
;   Y = count of sectors to read
;   disksys_ptr = data out location
; Returns: disksys_error in A/flags (0 on success)

; DISKSYS variables (exported for access via optional DISKSYS write procedures)
.export disksys_slot ; 
.export disksys_track
.export disksys_drive
.export disksys_driveto
.export disksys_sector
.export disksys_seekto
.export disksys_remain
.export disksys_retryseek
.export disksys_retryfind
.export disksys_retryread
.export disksys_counter
.export disksys_field ; 4 bytes
.export disksys_partial
.export disksys_nibbles1 ; 86 bytes, temporary buffer for 2+2+2 nibbles

; DISKSYS internal procedures (exported for optional DISKSYS write procedures)
.export disksys_delay_10ms
.export disksys_read_address
.export disksys_denibble
.export disksys_read_sector
.export disksys_start
.export disksys_stop
.export disksys_seek
.export disksys_seek0
.export disksys_find_sector
.export disksys_read_unpack
.export disksys_seek_prewait

;
; RAM usage outside code block
;

.segment "ZEROPAGE"
disksys_nibble   = disksys_temp+0
disksys_checksum = disksys_temp+1
disksys_nidx     = disksys_nibble ; not used at the same time as nibble

;
; DISKBOOT
;

.segment "DISKBOOT"

.import __DISKSYS_LOAD__ ; disk image location of DISKSYS
.import __DISKSYS_RUN__ ; memory destination of DISKSYS
.import __DISKSYS_SIZE__

.import __DISKREAD_START__ ; memory reserved for DISKSYS (to ensure space for disksys_nibbles1)
.import __DISKREAD_LAST__
.import __DISKREAD_SIZE__

.import __MAIN_START__ ; memory destination of MAIN
.import __MAIN_LAST__
.import BSEC ; sector where MAIN begins

DISKSYS_BOOT_START = __DISKSYS_LOAD__ + $800 ; where boot0 loads DISKSYS into memory temporarily
DISKSYS_BOOT_OFFSET = __DISKSYS_RUN__ - DISKSYS_BOOT_START
DISKSYS_END = __DISKSYS_RUN__ + __DISKSYS_SIZE__ ; end of code in DISKSYS run location
DISKREAD_END = __DISKREAD_START__ + __DISKREAD_SIZE__ ; end of memory reserved for DISKSYS

boot_slot = $2B ; device slot used by disk boot0 (i.e. what peripheral slot booted this disk)

.assert boot_sector_count = $800, error, "DISKBOOT must be placed at $800"
.assert boot1 = $801, error, "DISKBOOT must be placed at $800"

; the first byte of the boot sector indicates how many pages must be loaded at boot
boot_sector_count:
	.byte >(__DISKSYS_LOAD__ + __DISKSYS_SIZE__ + 255)

; $801 is the boot entry
.proc boot1
src = $06
dst = $08
	lda $2B ; (slot * 16) used by disk boot device
	sta disksys_slot - DISKSYS_BOOT_OFFSET
	jsr $FE89 ; SETKBD initialize monitor keyboard handler
	jsr $FE93 ; SETVID initialize monitor video and text output handler
	jsr $FB2F ; INIT initialize monitor
	jsr $FD8E ; CROUT newline before we start
	lda #<msg_boot1
	ldx #>msg_boot1
	jsr boot_couts
	; copy DISKSYS to its permanent run location
	lda #<DISKSYS_BOOT_START
	sta src+0
	lda #>DISKSYS_BOOT_START
	sta src+1
	lda #<__DISKSYS_RUN__
	sta dst+0
	lda #>__DISKSYS_RUN__
	sta dst+1
	ldy #0
copy_disksys:
	lda (src), Y
	sta (dst), Y
	inc src+0
	bne :+
		inc src+1
	:
	jsr inc_dst
	lda dst+0
	cmp #<DISKSYS_END
	bne copy_disksys
	lda dst+1
	sbc #>DISKSYS_END
	bcc copy_disksys
	; initialize rest of reserved space to 0
	ldy #0
zero_disksys:
	lda dst+0
	cmp #<DISKREAD_END
	lda dst+1
	sbc #>DISKREAD_END
	bcc :+
		bcs read_main
	:
	tya
	sta (dst), Y
	jsr inc_dst
	jmp zero_disksys
	; use DISKSYS read to load MAIN
read_main:
	lda #<__MAIN_START__
	sta disksys_ptr+0
	lda #>__MAIN_START__
	sta disksys_ptr+1
	lda #<BSEC ; MAIN sector start
	ldx #>BSEC
	ldy #>((__MAIN_LAST__ - __MAIN_START__) + 255) ; MAIN sector count
	jsr disksys_read
	bne error
	; Success!
	lda #<msg_run
	ldx #>msg_run
	jsr boot_couts
	jmp start
error:
	lda #<msg_error
	ldx #>msg_error
	jsr boot_couts
	;lda disksys_error
	;jsr $FDDA ; PRBYTE (if you want to know the specific reason the read failed)
	;jsr $FD8E ; CROUT
	jmp $FF69 ; MONZ monitor * prompt, for debugging
inc_dst: ; shared increment for smaller code
	inc dst+0
	bne :+
		inc dst+1
	:
	rts
msg_boot1:
	.asciiz "LOADING A2P PROGRAM..."
msg_error:
	.asciiz "LOAD ERROR"
msg_run:
	.asciiz "RUN"
.endproc

.proc boot_couts
; X:A = pointer to ASCII string to print, 0 terminated
ptr = $06 ; any 2 ZP bytes not used by COUT
	sta ptr+0
	stx ptr+1
	ldy #0
	:
		lda (ptr), Y
		beq :+
		ora #$80
		jsr $FDED ; COUT monitor output character
		iny
		jmp :-
	:
	jmp $FD8E ; CROUT monitor output newline
.endproc

;
; DISKSYS
;

.segment "DISKSYS"

SPIN_DETECT_ATTEMPTS = 8
SEEK_ATTEMPTS = 2 ; if address not found after 1 reseek, a second probably won't help
FIND_ATTEMPTS = 48 ; times to look for address field on a track
FIND_NIBBLE_ATTEMPTS = $800 ; RDADR16 seems to do ~$300, but a comment says "2K"
SECTOR_NIBBLE_ATTEMPTS = 32 ; nibbles to read looking for a sector start
SECTOR_READ_ATTEMPTS = 8 ; times to reread a sector if bad data is found

SEEK_WAIT   = 15 ; RWST-16 waits 150ms between motor-on and track seeking
MOTOR_WAIT  = 100-SEEK_WAIT ; wait at least 1000ms after motor-on before reading
PHASE_WAIT  = 2 ; 20ms on each stepper phase
SETTLE_WAIT = 3 ; 30ms to settle at end of seek (RWST-16 waits 25ms)

FIELD_VOL = 3
FIELD_TRK = 2
FIELD_SEC = 1
FIELD_SUM = 0

PHASE0_OFF   = $C080
PHASE0_ON    = $C081
PHASE1_OFF   = $C082
PHASE1_ON    = $C083
MOTOR_OFF    = $C088
MOTOR_ON     = $C089
DRIVE_ENABLE = $C08A
Q6L          = $C08C
Q6H          = $C08D
Q7L          = $C08E
Q7H          = $C08F

; assert macro to ensure branches do not cross a page
.macro BP instruction_, label_
    instruction_ label_
    .assert >(label_) = >*, error, "Page crossed!"
.endmacro

.align 256
; Some procedures in DISKSYS require alignment to avoid page-crossing branches,
; or page-crossing indexed memory access, which alters the cycle timing.

; DISKSYS aligned page 0:
; - disksys_read_address (branch alignment)
; - disksys_denibble (table aligned at $96)
; No alignment needed, but used to fill the otherwise unused space:
; - disksys_delay_10ms
; - variables
DISKSYS_PAGE_0 = *

; variables
disksys_error:     .byte 0          ; error flags of last operation
disksys_slot:      .byte 6<<4       ; disk peripheral slot * 16
disksys_drive:     .byte 0          ; drive in use
disksys_driveto:   .byte 0          ; drive requested
disksys_track:     .byte 0          ; track position
disksys_seekto:    .byte 0          ; track requested
disksys_sector:    .byte 0          ; sector requested
disksys_remain:    .byte 0          ; sectors left to read
disksys_retryseek: .byte 0          ; retries left for a failed seek
disksys_retryfind: .byte 0          ; retries left to find a sector address
disksys_retryread: .byte 0          ; retries left to read a sector
disksys_counter:   .byte 0          ; nibble tests left to find start of sector address/data
disksys_field:     .byte 0, 0, 0, 0 ; last read address field
disksys_partial:   .byte 0          ; temporary error if last attempt was a partial read

.proc disksys_delay_10ms
	; A * 10 = ms to delay (approximate, at least), A >= 1
	; clobbers A/Y = 0
	sec
	ldy #0
:
	: ; 40 cycle loop * 256 >= 10,241 cycles
		iny
		php
		plp
		php
		plp
		php
		plp
		php
		plp
		php
		plp
		bne :-
	sbc #1
	bne :--
	rts
.endproc

.proc disksys_read_address
	; X = disksys_slot (kept)
	; Clobbers: disksys_counter=0, disksys_checksum
	; Return: C = 0 if a valid address field was read
	;         disksys_field = the information read (4 bytes)
	; After a success, there should be about 250 cycles of gap/sync before we must start reading its following sector.
	lda #>FIND_NIBBLE_ATTEMPTS
	.assert <FIND_NIBBLE_ATTEMPTS = 0, error, "Low byte of FIND_NIBBLE_ATTEMPTS is ignored, should be zero."
	sta disksys_counter
	ldy #0
	; 1. find D5 AA 96 address field indicator
	; 2. read Volume Track Sector Checksum from address field
	; 3. verify DE AA address field terminator
find_restart: ; when returning here, ensure <32 cycles between reads to avoid skipping a byte
	iny
	bne read_D5
	dec disksys_counter
	beq find_error
read_D5:
	lda Q6L, X
	BP bpl, read_D5
check_D5:
	cmp #$D5
	bne find_restart
	nop ; must wait >=8 cycles for next read
read_AA:
	lda Q6L, X
	BP bpl, read_AA
	cmp #$AA
	bne check_D5 ; not D5 AA, but might be a new D5
	nop
read_96:
	lda Q6L, X
	BP bpl, read_96
	cmp #$96
	bne check_D5
	ldy #3
	lda #0
read_fields:
	sta disksys_checksum
read_field0:
	lda Q6L, X
	BP bpl, read_field0
	sec
	rol
	sta disksys_nibble
read_field1:
	lda Q6L, X
	BP bpl, read_field1
	and disksys_nibble
	sta disksys_field, Y
	eor disksys_checksum
	dey
	bpl read_fields ; 25 cycles to next read (<32)
	cmp #0 ; EOR checksum should be 0
	bne find_error
read_DE:
	lda Q6L, X
	BP bpl, read_DE
	cmp #$DE
	bne find_error
	nop
read_AA_again:
	lda Q6L, X
	BP bpl, read_AA_again
	cmp #$AA
	bne find_error
	; NOTE: an EB byte is specified here but is ignored by RWST-16 because it is never formatted correctly anyway.
	; See: Understanding the Apple II, Jim Sather, 1983. Page 9-27.
	clc ; success
	rts
find_error:
	sec ; error
	rts
.endproc

; denibble table must be placed at exactly $96 bytes into the page
.res 11 ; padding

; Generated by notes/nibble.py
disksys_denibble_suffix:
.byte                         $00,$01,$00,$00,$02,$03,$00,$04,$05,$06
.byte $00,$00,$00,$00,$00,$00,$07,$08,$00,$00,$00,$09,$0A,$0B,$0C,$0D
.byte $00,$00,$0E,$0F,$10,$11,$12,$13,$00,$14,$15,$16,$17,$18,$19,$1A
.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$1B,$00,$1C,$1D,$1E
.byte $00,$00,$00,$1F,$00,$00,$20,$21,$00,$22,$23,$24,$25,$26,$27,$28
.byte $00,$00,$00,$00,$00,$29,$2A,$2B,$00,$2C,$2D,$2E,$2F,$30,$31,$32
.byte $00,$00,$33,$34,$35,$36,$37,$38,$00,$39,$3A,$3B,$3C,$3D,$3E,$3F

disksys_denibble = disksys_denibble_suffix - $96
.assert (<disksys_denibble_suffix)=$96, error, .sprintf("disksys_denibble_suffix out of alignment: $96 != $%02X", disksys_denibble_suffix - DISKSYS_PAGE_0)

; DISKSYS aligned page 1:
; - disksys_read_sector (branch alignment)
; No alignment required:
; - everything else...

.proc disksys_read_sector
	lda #0
	sta disksys_partial
	lda #SECTOR_READ_ATTEMPTS
	sta disksys_retryread
retry_read_sector:
	ldx disksys_slot
	jsr disksys_find_sector
	bcc :+
		jmp find_error
	:
	; 1. find D5 AA AD to start segment data
	; 2. read and decode 86 x 2+2+2-bit nibbles (backwards)
	; 3. read and decode 256 x 6-bit nibbles (forwards)
	; 4. combine and copy data
	ldy #SECTOR_NIBBLE_ATTEMPTS
data_restart:
	dey
	beq head_error
read_D5:
	lda Q6L, X
	BP bpl, read_D5
check_D5:
	cmp #$D5
	bne data_restart
	nop ; >=8 cycles between reads
read_AA:
	lda Q6L, X
	BP bpl, read_AA
	cmp #$AA
	bne check_D5
	nop
read_AD:
	lda Q6L, X
	BP bpl, read_AD
	cmp #$AD
	bne check_D5
	ldy #86
	lda #0
read_nibbles1: ; 86 bytes (reverse order)
	dey
	sty disksys_nidx
read_nibble1:
	ldy Q6L, X
	BP bpl, read_nibble1
	eor disksys_denibble, Y
	ldy disksys_nidx
	sta disksys_nibbles1, Y
	bne read_nibbles1 ; 26 cycles to next read (<32)
	;ldy #0
read_nibbles0: ; 256 bytes (forward order)
	sty disksys_nidx
read_nibble0:
	ldy Q6L, X
	BP bpl, read_nibble0
	eor disksys_denibble, Y
	ldy disksys_nidx
	sta (disksys_ptr), Y
	iny
	bne read_nibbles0 ; 27 cycles to next read (<32)
read_checksum:
	ldy Q6L, X
	BP bpl, read_checksum
	cmp disksys_denibble, Y
	bne data_error
read_DE:
	lda Q6L, X
	BP bpl, read_DE
	cmp #$DE
	bne data_error
	nop
read_AA_again:
	lda Q6L, X
	BP bpl, read_AA_again
	cmp #$AA
	bne data_error
	jmp disksys_read_unpack ; finished reading, copy data to destination!
; errors
data_error: ; CRC or footer failed: unpack partially-corrupt data and retry (start of segment data may be valid?)
	lda #DISKSYS_ERROR_PARTIAL
	sta disksys_partial ; note that partial data was decoded
	jsr disksys_read_unpack
	dec disksys_retryread
	bne common_retry
	lda #DISKSYS_ERROR_PARTIAL
	jmp common_error
head_error: ; sector header corrupt/missing: retry
	dec disksys_retryread
	bne common_retry
	lda #DISKSYS_ERROR_DATA
	jmp common_error
find_error: ; could not find address: give up
	lda #DISKSYS_ERROR_FIND
common_error:
	ora disksys_error
	ora disksys_partial ; partial data was retrieved in a previous attempt
	sta disksys_error
	rts
common_retry:
	jmp retry_read_sector
.endproc

.proc disksys_start
	; A = drive to select
	; Return: C = motor is still spinning up
	; Return: X = disksys_slot
	; Selects the requested drive and spins up its motor.
	ldx #0
	stx disksys_error ; clear errors
	and #1
	cmp disksys_drive
	sta disksys_drive
	php ; Z = drive changed
	ldx disksys_slot
	; check if motor is already spinning
	lda Q7L, X ; read mode
	lda Q6L, X
	ldy #SPIN_DETECT_ATTEMPTS
@spincheck:
	lda Q6L, X
	php ; RWST-16 waits 18 cycles to check for a data change
	plp
	php
	plp
	nop
	nop
	cmp Q6L, X
	bne @spin_on ; data is changing, spin is on
	dey
	bne @spincheck ; check again
	plp ; doesn't matter if drive changed, spin is off
@spin_off:
	clc
	jmp @motor_start
@spin_on:
	plp
	bne @spin_off ; drive changed, spin on the drive we want is off
	sec
@motor_start:
	php ; save drive spinning (C flag)
	lda MOTOR_ON, X ; drive motor on
	txa
	clc
	adc disksys_drive
	tay
	lda DRIVE_ENABLE, Y ; RWST-16 does enable after motor
	plp
	bcs :+
		lda #SEEK_WAIT ; wait before doing seek to avoid voltage spike from motor start
		jsr disksys_delay_10ms
		clc
	:
	rts ; C = 0 if motor needs spinup
.endproc

.proc disksys_stop
	ldx disksys_slot
	lda Q7L, X ; read mode (just in case)
	lda MOTOR_OFF, X
	lda disksys_error
	rts
.endproc

.proc disksys_seek
	; Return: X = disksys_slot
	; Drives stepper motor to the seekto track.
	; RWST-16 used a complicated acceleration curve with overlapping phases.
	; This uses a simpler but slower fixed wait per single phase.
	lda disksys_seekto
	cmp disksys_track
	bne :+
	ldx disksys_slot
	rts ; already on the right track
seek_loop:
	lda disksys_seekto
	cmp disksys_track
	bne :+
		; track = seekto, wait for an additional settle
		ldx disksys_slot
		lda #SETTLE_WAIT
		jmp disksys_delay_10ms
	:
	php
	jsr index
	lda PHASE0_OFF, X ; release current track
	plp
	bcc seek_out
seek_in: ; seekto > track
	jsr half ; +1/2
	inc disksys_track
	jsr index
	jmp seek_next
seek_out: ; seekto < track
	dec disksys_track
	jsr index
	jsr half ; -1/2
	;jmp seek_next
seek_next:
	lda PHASE0_ON, X ; new track
	jsr hold
	jmp seek_loop ; loop until seekto = track
; subroutines
index: ; places X index at phase 0 or phase 2 based on current track
	lda disksys_track
	and #$01
	asl
	asl
	ora disksys_slot
	tax
	rts
hold: ; waits for the drive to reach the next phase
	lda #SEEK_WAIT
	jmp disksys_delay_10ms
half: ; steps through half-track (index+1 = odd phases)
	lda PHASE1_ON, X
	jsr hold
	lda PHASE1_OFF, X
	rts
.endproc

.proc disksys_seek0
	; Return: X = disksys_slot, disksys_track=0
	; Steps outward 80x to realign at track 0 against the outer stop.
	lda disksys_seekto
	pha
	lda #0
	sta disksys_seekto
	lda #40
	sta disksys_track
	jsr disksys_seek
	pla
	sta disksys_seekto
	rts
.endproc

.proc disksys_find_sector
	; X = disksys_slot (kept)
	; Clobbers: disksys_retryseek, disksys_retryfind
	; Return: C = 0 if the sectors address could be found
	; After a success, we have about 200 cycles to start looking for the sector data.
	lda #SEEK_ATTEMPTS
	sta disksys_retryseek
retry_seek:
	jsr disksys_seek
	lda #FIND_ATTEMPTS
	sta disksys_retryfind
retry_address:
	jsr disksys_read_address
	bcc found_address
	dec disksys_retryfind
	bne retry_address
	; no valid address found on this track, try re-seeking from 0
reset_seek:
	dec disksys_retryseek
	beq seek_error
	jsr disksys_seek0
	jmp retry_seek
found_address:
	lda disksys_seekto
	cmp disksys_field + FIELD_TRK
	bne reset_seek ; address field says we're on the wrong track, do a reseek
	lda disksys_sector
	cmp disksys_field + FIELD_SEC
	beq found_sector
	dec disksys_retryfind
	bne retry_address
seek_error:
	sec
	rts
found_sector:
	clc
	rts
.endproc

.proc disksys_read_unpack
	ldy #0
outer: ; 3 passes over X = 85-0
	ldx #86
inner: ; 1 pass over Y = 0-255
	dex
	bmi outer
	lda (disksys_ptr), Y
	lsr disksys_nibbles1, X
	rol
	lsr disksys_nibbles1, X
	rol A
	sta (disksys_ptr), Y
	iny
	bne inner
	rts
.endproc

.proc disksys_seek_prewait
	; Motor is spinning up, but we can seek while it happens.
	; Predict the first seek time, and wait any remaining motor spinup time.
	lda disksys_seekto
	sec
	sbc disksys_track
	beq motor_wait ; no seek, do full motor wait
	bcs :+
		eor #$FF ; seek distance was negative, invert
		;clc
		adc #1
	:
	; A = tracks to seek
	asl
	asl ; 40 ms per track
	.assert PHASE_WAIT = 2, error, "DISKSYS track seek calculation assumes 20ms per step"
	clc
	adc #SETTLE_WAIT ; settling time
	; subtract predicted seek time from remaining motor spinup time
	eor #$FF
	clc
	adc #1
motor_wait:
	clc
	adc #MOTOR_WAIT
	bmi :+ ; seek is already longer than MOTOR_WAIT
		jmp disksys_delay_10ms
	:
	rts
.endproc

.proc disksys_read
	; X:A = (track * 16) + sector
	; Y = count of sectors to read
	; ptr = data out ptr
	sty disksys_remain
	sta disksys_seekto
	and #15
	sta disksys_sector
	txa
	lsr
	ror disksys_seekto
	lsr
	ror disksys_seekto
	lsr disksys_seekto
	lsr disksys_seekto
	; spin up the drive
	lda disksys_driveto
	jsr disksys_start ; X = disksys_slot
	bcs sector_loop ; drive is already spinning, start reading sectors
	jsr disksys_seek_prewait
sector_loop:
	lda disksys_remain
	bne :+
		jmp disksys_stop ; done
	:
	dec disksys_remain
	jsr disksys_read_sector
	ldy disksys_sector
	iny
	cpy #16
	bcc :+
		inc disksys_seekto
		ldy #0
	:
	sty disksys_sector
	inc disksys_ptr+1
	jmp sector_loop
.endproc

; There's empty space on the last page, so it's a reasonable place for this 2+2+2 nibbles buffer.
; Space is not reserved here so that we can share space in sector 0 with BOOT,
; but a few asserts here verify that the needed space will exist after it's copied into place.
disksys_nibbles1:
;.res 86
.assert __DISKREAD_LAST__ = disksys_nibbles1, error, "disksys_boot.o must be the last module in DISKBOOT"
.assert (__DISKREAD_SIZE__ - (disksys_nibbles1 - __DISKREAD_START__)) >= 86, error, "Not enough trailing space in DISKREAD for disksys_nibbles1"

; Also, if this crosses a page there's an inconsistent +1 cycle penalty when accessing it.
; This is within tolerance for reading, but a fixed timing is essential when writing.
.assert (>(disksys_nibbles1+85))=(>disksys_nibbles1), error, "disksys_nibbles1 may not cross a page."

; There's more than 100 bytes free here at the end of the reserved page.
; This is probably not significant, but could be used if we were really in a pinch.
