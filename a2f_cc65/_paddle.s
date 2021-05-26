; _paddle
;
; C interface for paddle

.include "../a2f.inc"

.export _paddle_buttons
.export _paddle0_x
.export _paddle0_y
.export _paddle1_x
.export _paddle1_y

.export _paddle_buttons_poll
.export _paddle0_poll
.export _paddle01_poll

.import paddle_buttons
.import paddle0_x
.import paddle0_y
.import paddle1_x
.import paddle1_y

.import paddle_buttons_poll
.import paddle0_poll
.import paddle01_poll

_paddle_buttons = paddle_buttons
_paddle0_x = paddle0_x
_paddle0_y = paddle0_y
_paddle1_x = paddle1_x
_paddle1_y = paddle1_y

; uint8 paddle_buttons_poll()
_paddle_buttons_poll = paddle_buttons_poll

; void paddle0_poll()
_paddle0_poll = paddle0_poll

; void paddle01_poll()
_paddle01_poll = paddle01_poll
