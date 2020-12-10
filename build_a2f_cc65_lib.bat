@REM Generates:
@REM   temp\a2f_cc65.lib
@REM
@REM cc65\ should contain latest cc65 build (cc65\bin)
@REM cc65\libsrc\ should contain latest cc65 libsrc folder
@REM
@REM Download CC65 source here:
@REM https://github.com/cc65/cc65

if not exist cc65\libsrc goto needlibsrc
md temp\a2f_cc65_lib
del temp\a2f_cc65_lib\*.s
del temp\a2f_cc65_lib\*.o
del temp\a2f_cc65.lib
for %%X in (a2f_cc65\*.s)            do cc65\bin\ca65.exe %%X -g -o temp\a2f_cc65_lib\%%~nX.o || @goto error
for %%X in (cc65\libsrc\runtime\*.s) do cc65\bin\ca65.exe %%X -g -o temp\a2f_cc65_lib\%%~nX.o || @goto error
for %%X in (cc65\libsrc\common\*.s)  do cc65\bin\ca65.exe %%X -g -o temp\a2f_cc65_lib\%%~nX.o || @goto error
for %%X in (cc65\libsrc\conio\*.s)   do cc65\bin\ca65.exe %%X -g -o temp\a2f_cc65_lib\%%~nX.o || @goto error
for %%X in (cc65\libsrc\common\*.c)  do cc65\bin\cc65.exe %%X -g -O -W error -o temp\a2f_cc65_lib\%%~nX.s || @goto error
for %%X in (temp\a2f_cc65_lib\*.s)   do cc65\bin\ca65.exe %%X -g -o temp\a2f_cc65_lib\%%~nX.o || @goto error
for %%X in (temp\a2f_cc65_lib\*.o)   do cc65\bin\ar65.exe a temp\a2f_cc65.lib %%X || @goto error

@echo.
@echo.
@echo temp\a2f_cc65.lib
@echo Build successful!
@pause
@goto end

:needlibsrc
@echo.
@echo.
@echo temp\a2f_cc65.lib not rebuilt!
@echo Download CC65 source and place libsrc\ folder here.
@echo Read this batch file for more information.
@pause
@goto end

:error
@echo.
@echo.
@echo Build error!
@pause

:end