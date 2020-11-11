; DISKBOOT & DISKREAD
;  These are routines for creating a bootable 16-sector disk.
;  The read routines will let you load/save 256-byte sectors from the disk, instead of using the DOS file system.
;  It is is informed by, but simpler than, the RWST-16 routines from Apple DOS 3.3.

.include "../a2f.inc"

; DISKBOOT will jump here on successful startup
.import start

.ifdef A2F_DISK
; Ensure this module is always included
.export __BOOT__ : absolute = 1
.endif

; ZEROPAGE imports (defined elsewhere so they can be reused)
.importzp disk_ptr ; 2-bytes: pointer to read ouput
.importzp disk_temp ; 2-bytes

; DISKREAD public exports

.export disk_error ; byte: last error code

.export disk_read
; Reads contiguous 256-byte sectors from disk:
;   X:A = (track * 16) + sector
;   Y = count of sectors to read
;   disk_ptr = data out location
; Returns: disk_error in A/flags (0 on success)

; DISKREAD variables (exported for access via optional disk write procedures)
.export disk_slot ; 
.export disk_track
.export disk_drive
.export disk_driveto
.export disk_sector
.export disk_seekto
.export disk_remain
.export disk_retryseek
.export disk_retryfind
.export disk_retryread
.export disk_counter
.export disk_field ; 4 bytes
.export disk_partial
.export disk_nibbles1 ; 86 bytes, temporary buffer for 2+2+2 nibbles

; DISKREAD internal procedures (exported for optional disk write procedures)
.export disk_delay_10ms
.export disk_read_address
.export disk_denibble
.export disk_read_sector
.export disk_start
.export disk_stop
.export disk_seek
.export disk_seek0
.export disk_find_sector
.export disk_read_unpack
.export disk_seek_prewait
.export disk_sector_index

; DISKBOOT has a COUT-string that you could use if you never clear that memory
.ifdef A2F_DISK
.export boot_couts
.endif

;
; RAM usage outside code block
;

.segment "ZEROPAGE"
disk_nibble   = disk_temp+0
disk_checksum = disk_temp+1
disk_nidx     = disk_nibble ; not used at the same time as nibble

;
; DISKBOOT
;
.ifdef A2F_DISK

.segment "DISKBOOT"

.import __DISKREAD_LOAD__ ; disk image location of DISKREAD
.import __DISKREAD_RUN__ ; memory destination of DISKREAD
.import __DISKREAD_SIZE__

.import __DISKLOAD_START__ ; memory reserved for DISKREAD (to ensure space for disk_nibbles1)
.import __DISKLOAD_LAST__
.import __DISKLOAD_SIZE__

.import __MAIN_START__ ; memory destination of MAIN
.import __MAIN_LAST__
.import A2F_BSEC ; sector where MAIN begins

DISKREAD_BOOT_START = __DISKREAD_LOAD__ + $800 ; where boot0 loads DISKREAD into memory temporarily
DISKREAD_BOOT_OFFSET = __DISKREAD_RUN__ - DISKREAD_BOOT_START
DISKREAD_END = __DISKREAD_RUN__ + __DISKREAD_SIZE__ ; end of code in DISKREAD run location

boot_slot = $2B ; device slot used by disk boot0 (i.e. what peripheral slot booted this disk)

.assert boot_sector_count = $800, error, "DISKBOOT must be placed at $800"
.assert boot1 = $801, error, "DISKBOOT must be placed at $800"

; the first byte of the boot sector indicates how many pages must be loaded at boot
boot_sector_count:
	.byte >(__DISKREAD_LOAD__ + __DISKREAD_SIZE__ + 255)

; $801 is the boot entry
.proc boot1
src = $06
dst = $08
	lda $2B ; (slot * 16) used by disk boot device
	sta disk_slot - DISKREAD_BOOT_OFFSET
	jsr $FE89 ; SETKBD initialize monitor keyboard handler
	jsr $FE93 ; SETVID initialize monitor video and text output handler
	jsr $FB2F ; INIT initialize monitor
	jsr $FD8E ; CROUT newline before we start
	lda #<msg_boot1
	ldx #>msg_boot1
	jsr boot_couts
	; copy DISKREAD to its permanent run location
	lda #<DISKREAD_BOOT_START
	sta src+0
	lda #>DISKREAD_BOOT_START
	sta src+1
	lda #<__DISKREAD_RUN__
	sta dst+0
	lda #>__DISKREAD_RUN__
	sta dst+1
	ldy #0
copy_diskread:
	lda (src), Y
	sta (dst), Y
	inc src+0
	bne :+
		inc src+1
	:
	jsr inc_dst
	lda dst+0
	cmp #<DISKREAD_END
	bne copy_diskread
	lda dst+1
	sbc #>DISKREAD_END
	bcc copy_diskread
	; use DISKREAD read to load MAIN
read_main:
	lda #<__MAIN_START__
	sta disk_ptr+0
	lda #>__MAIN_START__
	sta disk_ptr+1
	lda #<A2F_BSEC ; MAIN sector start
	ldx #>A2F_BSEC
	ldy #>((__MAIN_LAST__ - __MAIN_START__) + 255) ; MAIN sector count
	jsr disk_read
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
	;lda disk_error
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
	.asciiz "LOADING A2F PROGRAM..."
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

.endif ; A2F_DISK

;
; DISKREAD
;

.ifdef A2F_DISK
; Read routines are placed in a special segment at the end of main RAM space,
; so they can be used to load MAIN during boot.
.segment "DISKREAD"
.else
; If not needed for booting, they can just go in the aligned segment within MAIN.
.segment "ALIGN"
.endif

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
; Some procedures in DISKREAD require alignment to avoid page-crossing branches,
; or page-crossing indexed memory access, which alters the cycle timing.

; DISKREAD aligned page 0:
; - disk_read_address (branch alignment)
; - disk_denibble (table aligned at $96)
; No alignment needed, but used to fill the otherwise unused space:
; - disk_delay_10ms
; - variables
DISKREAD_PAGE_0 = *

; variables
disk_error:     .byte 0          ; error flags of last operation
disk_slot:      .byte 6<<4       ; disk peripheral slot * 16
disk_drive:     .byte 0          ; drive in use
disk_driveto:   .byte 0          ; drive requested
disk_track:     .byte 0          ; track position
disk_seekto:    .byte 0          ; track requested
disk_sector:    .byte 0          ; sector requested
disk_remain:    .byte 0          ; sectors left to read
disk_retryseek: .byte 0          ; retries left for a failed seek
disk_retryfind: .byte 0          ; retries left to find a sector address
disk_retryread: .byte 0          ; retries left to read a sector
disk_counter:   .byte 0          ; nibble tests left to find start of sector address/data
disk_field:     .byte 0, 0, 0, 0 ; last read address field
disk_partial:   .byte 0          ; temporary error if last attempt was a partial read

.proc disk_delay_10ms
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

.proc disk_read_address
	; X = disk_slot (kept)
	; Clobbers: disk_counter=0, disk_checksum
	; Return: C = 0 if a valid address field was read
	;         disk_field = the information read (4 bytes)
	; After a success, there should be about 250 cycles of gap/sync before we must start reading its following sector.
	lda #>FIND_NIBBLE_ATTEMPTS
	.assert <FIND_NIBBLE_ATTEMPTS = 0, error, "Low byte of FIND_NIBBLE_ATTEMPTS is ignored, should be zero."
	sta disk_counter
	ldy #0
	; 1. find D5 AA 96 address field indicator
	; 2. read Volume Track Sector Checksum from address field
	; 3. verify DE AA address field terminator
find_restart: ; when returning here, ensure <32 cycles between reads to avoid skipping a byte
	iny
	bne read_D5
	dec disk_counter
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
	sta z:disk_checksum
read_field0:
	lda Q6L, X
	BP bpl, read_field0
	sec
	rol
	sta z:disk_nibble
read_field1:
	lda Q6L, X
	BP bpl, read_field1
	and z:disk_nibble
	sta disk_field, Y
	eor z:disk_checksum
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
disk_denibble_suffix:
.byte                         $00,$01,$00,$00,$02,$03,$00,$04,$05,$06
.byte $00,$00,$00,$00,$00,$00,$07,$08,$00,$00,$00,$09,$0A,$0B,$0C,$0D
.byte $00,$00,$0E,$0F,$10,$11,$12,$13,$00,$14,$15,$16,$17,$18,$19,$1A
.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$1B,$00,$1C,$1D,$1E
.byte $00,$00,$00,$1F,$00,$00,$20,$21,$00,$22,$23,$24,$25,$26,$27,$28
.byte $00,$00,$00,$00,$00,$29,$2A,$2B,$00,$2C,$2D,$2E,$2F,$30,$31,$32
.byte $00,$00,$33,$34,$35,$36,$37,$38,$00,$39,$3A,$3B,$3C,$3D,$3E,$3F

disk_denibble = disk_denibble_suffix - $96
.assert (<disk_denibble_suffix)=$96, error, .sprintf("disk_denibble_suffix out of alignment: $96 != $%02X", disk_denibble_suffix - DISKREAD_PAGE_0)

; DISKREAD aligned page 1:
; - disk_read_sector (branch alignment)
; No alignment required:
; - everything else...

.proc disk_read_sector
	lda #0
	sta disk_partial
	lda #SECTOR_READ_ATTEMPTS
	sta disk_retryread
retry_read_sector:
	ldx disk_slot
	jsr disk_find_sector
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
	sty z:disk_nidx
read_nibble1:
	ldy Q6L, X
	BP bpl, read_nibble1
	eor disk_denibble, Y
	ldy z:disk_nidx
	sta disk_nibbles1, Y
	bne read_nibbles1 ; 26 cycles to next read (<32)
	;ldy #0
read_nibbles0: ; 256 bytes (forward order)
	sty z:disk_nidx
read_nibble0:
	ldy Q6L, X
	BP bpl, read_nibble0
	eor disk_denibble, Y
	ldy z:disk_nidx
	sta (disk_ptr), Y
	iny
	bne read_nibbles0 ; 27 cycles to next read (<32)
read_checksum:
	ldy Q6L, X
	BP bpl, read_checksum
	cmp disk_denibble, Y
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
	jmp disk_read_unpack ; finished reading, copy data to destination!
; errors
data_error: ; CRC or footer failed: unpack partially-corrupt data and retry (start of segment data may be valid?)
	lda #DISK_ERROR_PARTIAL
	sta disk_partial ; note that partial data was decoded
	jsr disk_read_unpack
	dec disk_retryread
	bne common_retry
	lda #DISK_ERROR_PARTIAL
	jmp common_error
head_error: ; sector header corrupt/missing: retry
	dec disk_retryread
	bne common_retry
	lda #DISK_ERROR_DATA
	jmp common_error
find_error: ; could not find address: give up
	lda #DISK_ERROR_FIND
common_error:
	ora disk_error
	ora disk_partial ; partial data was retrieved in a previous attempt
	sta disk_error
	rts
common_retry:
	jmp retry_read_sector
.endproc

.proc disk_start
	; A = drive to select
	; Return: C = motor is still spinning up
	; Return: X = disk_slot
	; Selects the requested drive and spins up its motor.
	ldx #0
	stx disk_error ; clear errors
	and #1
	cmp disk_drive
	sta disk_drive
	php ; Z = drive changed
	ldx disk_slot
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
	adc disk_drive
	tay
	lda DRIVE_ENABLE, Y ; RWST-16 does enable after motor
	plp
	bcs :+
		lda #SEEK_WAIT ; wait before doing seek to avoid voltage spike from motor start
		jsr disk_delay_10ms
		clc
	:
	rts ; C = 0 if motor needs spinup
.endproc

.proc disk_stop
	ldx disk_slot
	lda Q7L, X ; read mode (just in case)
	lda MOTOR_OFF, X
	lda disk_error
	rts
.endproc

.proc disk_seek
	; Return: X = disk_slot
	; Drives stepper motor to the seekto track.
	; RWST-16 used a complicated acceleration curve with overlapping phases.
	; This uses a simpler but slower fixed wait per single phase.
	lda disk_seekto
	cmp disk_track
	bne :+
	ldx disk_slot
	rts ; already on the right track
seek_loop:
	lda disk_seekto
	cmp disk_track
	bne :+
		; track = seekto, wait for an additional settle
		ldx disk_slot
		lda #SETTLE_WAIT
		jmp disk_delay_10ms
	:
	php
	jsr index
	lda PHASE0_OFF, X ; release current track
	plp
	bcc seek_out
seek_in: ; seekto > track
	jsr half ; +1/2
	inc disk_track
	jsr index
	jmp seek_next
seek_out: ; seekto < track
	dec disk_track
	jsr index
	jsr half ; -1/2
	;jmp seek_next
seek_next:
	lda PHASE0_ON, X ; new track
	jsr hold
	jmp seek_loop ; loop until seekto = track
; subroutines
index: ; places X index at phase 0 or phase 2 based on current track
	lda disk_track
	and #$01
	asl
	asl
	ora disk_slot
	tax
	rts
hold: ; waits for the drive to reach the next phase
	lda #PHASE_WAIT
	jmp disk_delay_10ms
half: ; steps through half-track (index+1 = odd phases)
	lda PHASE1_ON, X
	jsr hold
	lda PHASE1_OFF, X
	rts
.endproc

.proc disk_seek0
	; Return: X = disk_slot, disk_track=0
	; Steps outward 80x to realign at track 0 against the outer stop.
	lda disk_seekto
	pha
	lda #0
	sta disk_seekto
	lda #40
	sta disk_track
	jsr disk_seek
	pla
	sta disk_seekto
	rts
.endproc

.proc disk_find_sector
	; X = disk_slot (kept)
	; Clobbers: disk_retryseek, disk_retryfind
	; Return: C = 0 if the sectors address could be found
	; After a success, we have about 200 cycles to start looking for the sector data.
	lda #SEEK_ATTEMPTS
	sta disk_retryseek
retry_seek:
	jsr disk_seek
	lda #FIND_ATTEMPTS
	sta disk_retryfind
retry_address:
	jsr disk_read_address
	bcc found_address
	dec disk_retryfind
	bne retry_address
	; no valid address found on this track, try re-seeking from 0
reset_seek:
	dec disk_retryseek
	beq seek_error
	jsr disk_seek0
	jmp retry_seek
found_address:
	lda disk_seekto
	cmp disk_field + FIELD_TRK
	bne reset_seek ; address field says we're on the wrong track, do a reseek
	lda disk_sector
	cmp disk_field + FIELD_SEC
	beq found_sector
	dec disk_retryfind
	bne retry_address
seek_error:
	sec
	rts
found_sector:
	clc
	rts
.endproc

.proc disk_read_unpack
	ldy #0
outer: ; 3 passes over X = 85-0
	ldx #86
inner: ; 1 pass over Y = 0-255
	dex
	bmi outer
	lda (disk_ptr), Y
	lsr disk_nibbles1, X
	rol
	lsr disk_nibbles1, X
	rol A
	sta (disk_ptr), Y
	iny
	bne inner
	rts
.endproc

.proc disk_seek_prewait
	; Motor is spinning up, but we can seek while it happens.
	; Predict the first seek time, and wait any remaining motor spinup time.
	lda disk_seekto
	sec
	sbc disk_track
	beq motor_wait ; no seek, do full motor wait
	bcs :+
		eor #$FF ; seek distance was negative, invert
		;clc
		adc #1
	:
	; A = tracks to seek
	asl
	asl ; 40 ms per track
	.assert PHASE_WAIT = 2, error, "DISKREAD track seek calculation assumes 20ms per step"
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
		jmp disk_delay_10ms
	:
	rts
.endproc

.proc disk_sector_index
	; X:A = (track * 16) + sector
	sta disk_seekto
	and #15
	sta disk_sector
	txa
	lsr
	ror disk_seekto
	lsr
	ror disk_seekto
	lsr disk_seekto
	lsr disk_seekto
	rts
.endproc

.proc disk_read
	; X:A = (track * 16) + sector
	; Y = count of sectors to read
	; ptr = data out ptr
	sty disk_remain
	jsr disk_sector_index
	; spin up the drive
	lda disk_driveto
	jsr disk_start ; X = disk_slot
	bcs sector_loop ; drive is already spinning, start reading sectors
	jsr disk_seek_prewait
sector_loop:
	lda disk_remain
	bne :+
		jmp disk_stop ; done
	:
	dec disk_remain
	jsr disk_read_sector
	ldy disk_sector
	iny
	cpy #16
	bcc :+
		inc disk_seekto
		ldy #0
	:
	sty disk_sector
	inc disk_ptr+1
	jmp sector_loop
.endproc

.ifdef A2F_DISK

; There's empty space on the last page, so it's a reasonable place for this 2+2+2 nibbles buffer.
; Space is not reserved here so that we can share space in sector 0 with BOOT,
; but a few asserts here verify that the needed space will exist after it's copied into place.
disk_nibbles1:

.assert __DISKLOAD_LAST__ = disk_nibbles1, error, "disk_boot.o must be the last module in DISKLOAD"
.assert (__DISKLOAD_SIZE__ - (disk_nibbles1 - __DISKLOAD_START__)) >= 86, error, "Not enough trailing space in DISKLOAD for disk_nibbles1"

; Also, if this crosses a page there's an inconsistent +1 cycle penalty when accessing it.
; This is within tolerance for reading, but a fixed timing is essential when writing.
.assert (>(disk_nibbles1+85))=(>disk_nibbles1), error, "disk_nibbles1 may not cross a page."

; There's more than 100 bytes free here at the end of the reserved page.
; This is probably not significant, but could be used if we were really in a pinch.

.else ; if not booting from disk, just reserve it:
disk_nibbles1: .res 86
.endif
