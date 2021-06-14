DP = ./
include makefile.common

DSK_DISK = $(OUTDIR)/a2f_demo.dsk
BIN_DISK = $(DSK_DISK:.dsk=.bin)
MAP_DISK = $(DSK_DISK:.dsk=.map)
DBG_DISK = $(DSK_DISK:.dsk=.dbg)
SYM_DISK = $(DSK_DISK:.dsk=.sym)

WAV_TAPE = $(OUTDIR)/a2f_demo.wav
BIN_TAPE = $(OUTDIR)/a2f_demo_tape.bin
MAP_TAPE = $(BIN_TAPE:.bin=.map)
DBG_TAPE = $(BIN_TAPE:.bin=.dbg)
TAPEBOOT0 = $(OUTDIR)/tapeboot0.bin
TAPEBOOT1 = $(OUTDIR)/tapeboot1.bin

LIB_DISK = $(OUTDIR)/a2f_disk.lib
LIB_TAPE = $(OUTDIR)/a2f_tape.lib
LIB_CC65 = $(OUTDIR)/a2f_cc65.lib

CSRC = $(wildcard *.c)
SRC = $(wildcard *.s)

OUTCDIR = $(OUTDIR)/c
CSSRC = $(addprefix $(OUTCDIR)/,$(CSRC:.c=.c.s))
OBJ = $(addprefix $(OUTDIR)/,$(SRC:.s=.o))
OBJ += $(addprefix $(OUTCDIR)/,$(CSRC:.c=.c.o))

CLEAN = $(OBJ) $(CSSRC) \
	$(DSK_DISK) $(BIN_DISK) $(MAP_DISK) $(DBG_DISK) $(SYM_DISK) \
	$(WAV_TAPE) $(BIN_TAPE) $(MAP_TAPE) $(DBG_TAPE) $(TAPEBOOT0) $(TAPEBOOT1)

.PHONY: all disk tape clean

# only make disk by default
all: disk
#all: disk tape
disk: $(DSK_DISK) $(SYM_DISK)
tape: $(WAV_TAPE)

$(OUTCDIR)/%.c.s: %.c a2f.h
	$(CC65) -o $@ -g -O $<
$(OUTCDIR)/%.c.o: $(OUTCDIR)/%.c.s
	$(CA65) -o $@ -g $<

$(OUTDIR)/%.o: %.s a2f.inc
	$(CA65) -o $@ -g $<

$(CLEAN): | $(OUTDIR)
$(CSSRC): | $(OUTCDIR)
$(OUTDIR):
	$(MKDIR) $(subst /,$(DS),$@)
$(OUTCDIR):
	$(MKDIR) $(subst /,$(DS),$@)

$(LIB_DISK) $(LIB_TAPE):
	$(MAKE) -C a2f
$(LIB_CC65):
	$(MAKE) -C a2f_cc65

$(BIN_DISK) $(DBG_DISK): $(OBJ) $(LIB_DISK) $(LIB_CC65) a2f_disk.cfg
	$(LD65) -o $@ -m $(MAP_DISK) --dbgfile $(DBG_DISK) -C a2f_disk.cfg $(OBJ) $(LIB_CC65) $(LIB_DISK)

$(DSK_DISK): $(BIN_DISK)
	$(PYTHON) sector_order.py $< $@

$(SYM_DISK): $(DBG_DISK)
	$(PYTHON) dbg_sym.py $< $@

$(BIN_TAPE) $(TAPEBOOT0) $(TAPEBOOT1): $(OBJ) $(LIB_TAPE) $(LIB_CC65)
	$(LD65) -o $@ -m $(MAP_TAPE) --dbgfile $(DBG_TAPE) -C a2f_tape.cfg $(OBJ) $(LIB_CC65) $(LIB_TAPE)

$(WAV_TAPE): $(TAPEBOOT0) $(TAPEBOOT1) $(BIN_TAPE)
	$(PYTHON) tape.py $@ $^

clean:
	$(RM) $(subst /,$(DS),$(CLEAN))
