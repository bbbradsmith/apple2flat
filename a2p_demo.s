
.export start
.exportzp disksys_ptr
.exportzp disksys_temp

.segment "ZEROPAGE"
disksys_ptr: .res 2
disksys_temp: .res 2

.segment "CODE"
start:
	jmp $FF69 ; MONZ monitor * prompt

; HACK TEST the load TODO
.repeat 32, I
	.repeat 256, J
		.byte I
	.endrepeat
.endrepeat
