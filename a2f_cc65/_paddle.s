; _paddle
;
; C interface for paddle

.include "../a2f.inc"

.export _paddle0_b
.export _paddle1_b
.export _paddle0_x
.export _paddle0_y
.export _paddle1_x
.export _paddle1_y

.export _paddleb_poll
.export _paddle0_poll
.export _paddle01_poll

.import paddle0_b
.import paddle1_b
.import paddle0_x
.import paddle0_y
.import paddle1_x
.import paddle1_y

.import paddleb_poll
.import paddle0_poll
.import paddle01_poll

_paddle0_b = paddle0_b
_paddle1_b = paddle1_b
_paddle0_x = paddle0_x
_paddle0_y = paddle0_y
_paddle1_x = paddle1_x
_paddle1_y = paddle1_y

; uint8 paddleb_poll()
_paddleb_poll = paddleb_poll

; void paddle0_poll()
_paddle0_poll = paddle0_poll

; void paddle01_poll()
_paddle01_poll = paddle01_poll
