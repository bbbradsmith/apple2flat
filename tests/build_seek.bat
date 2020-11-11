cd..
@del temp\*.s
@del temp\*.o
@del temp\a2f_seek.bin
@del temp\a2f_seek.dsk
@del temp\a2f_seek.dbg
@del temp\a2f_seek.map

cc65\bin\ca65 -o temp\a2f_seek.o -D A2F_DISK -g tests\a2f_seek.s || @goto error

cc65\bin\ld65 -o temp\a2f_seek.bin -m temp\a2f_seek.map --dbgfile temp\a2f_seek.dbg -C a2f_disk.cfg temp\a2f_seek.o temp\a2f_disk.lib || @goto error

python sector_order.py temp\a2f_seek.bin temp\a2f_seek.dsk || @goto error

python dbg_sym.py temp\a2f_seek.dbg temp\a2f_seek.sym || @goto error

@echo.
@echo.
@echo Build successful!
@pause
@goto end
:error
@echo.
@echo.
@echo Build error!
@pause
:end