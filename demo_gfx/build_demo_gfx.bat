python ..\gfx.py palette palette.png || @goto error
python ..\gfx.py font font.png font.bin || @goto error
python ..\gfx.py font_vwf font_vwf.png font_vwf.bin font_vwf.wid || @goto error
python ..\gfx.py -s lores leyendecker_lr.png leyendecker_lr.scr || @goto error
python ..\gfx.py -s lores leyendecker_dlr.png leyendecker_dlr.scr || @goto error
python ..\gfx.py -s mono leyendecker_mono.png leyendecker_mono.scr || @goto error
python ..\gfx.py -s hires leyendecker_hr.png leyendecker_hr.scr || @goto error
python ..\gfx.py -s double leyendecker_dhr.png leyendecker_dhr.scr || @goto error

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
