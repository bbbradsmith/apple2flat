python ..\gfx.py palette palette.png || @goto error
python ..\gfx.py font font.png font.bin || @goto error
python ..\gfx.py font_vwf font_vwf.png font_vwf.bin font_vwf.wid || @goto error
python ..\gfx.py lores leyendecker_lr.png leyendecker_lr.bin || @goto error
python ..\gfx.py lores leyendecker_dlr.png leyendecker_dlr.bin || @goto error
REM python ..\gfx.py hires leyendecker_hr.png leyendecker_hr.bin || @goto error
REM python ..\gfx.py double leyendecker_dhr.png leyendecker_dhr.bin || @goto error

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
