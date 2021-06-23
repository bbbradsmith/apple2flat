; _disk_read

; C access for disk_read

.export _disk_read
.export _disk_error
.export _disk_volume

.import popax
.import disk_read

.importzp disk_ptr
.importzp disk_temp
.import disk_error
.import disk_volume

_disk_error = disk_error
_disk_volume = disk_volume

.segment "CODE"

; uint8 disk_read(void* dest, uint16 sector, uint8 count)
_disk_read:
	sta disk_ptr+0 ; count: temporarily store
	jsr popax ; sector
	sta disk_temp+0
	stx disk_temp+1
	jsr popax ; dest
	ldy disk_ptr+0 ; count
	sta disk_ptr+0
	stx disk_ptr+1
	lda disk_temp+0 ; sector
	ldx disk_temp+1
	jsr disk_read ; X:A=sector, Y=count, disk_ptr=dest
	ldx #0 ;CC65 requires X=0 on uint8 return
	rts
