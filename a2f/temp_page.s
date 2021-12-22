; temp_page
;
; Temporary page on LOWRAM for various purposes

.export temp_page

.segment "LOWRAM"
temp_page: .res 256
