make -C a2f || @goto error
make -C a2f_cc65 || @goto error
make || @goto error
:error
@pause
