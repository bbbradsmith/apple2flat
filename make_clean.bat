make clean -C a2f || @goto error
make clean -C a2f_cc65 || @goto error
make clean || @goto error
:error
@pause
