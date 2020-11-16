@REM Generates:
@REM   temp\a2f_disk.lib
@REM   temp\a2f_tape.lib

md temp\a2f_disk_lib
md temp\a2f_tape_lib
del temp\a2f_disk_lib\*.o
del temp\a2f_tape_lib\*.o
del temp\a2f_disk.lib
del temp\a2f_tape.lib

@for %%X in (a2f\*.s) do               cc65\bin\ca65.exe %%X -D A2F_DISK -g -o temp\a2f_disk_lib\%%~nX.o || @goto error
@for %%X in (a2f\*.s) do               cc65\bin\ca65.exe %%X -D A2F_TAPE -g -o temp\a2f_tape_lib\%%~nX.o || @goto error
@for %%X in (temp\a2f_disk_lib\*.o) do cc65\bin\ar65.exe a temp\a2f_disk.lib %%X || @goto error
@for %%X in (temp\a2f_tape_lib\*.o) do cc65\bin\ar65.exe a temp\a2f_tape.lib %%X || @goto error

@echo.
@echo.
@echo temp\a2f_disk.lib
@echo temp\a2f_tape.lib
@echo Build successful!
@pause
@goto end
:error
@echo.
@echo.
@echo Build error!
@pause
:end