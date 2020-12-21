DP = ../
include ../makefile.common

LIB_DISK = $(OUTDIR)/a2f_disk.lib
LIB_TAPE = $(OUTDIR)/a2f_tape.lib
OBJDIR_DISK = $(OUTDIR)/a2f_disk_lib
OBJDIR_TAPE = $(OUTDIR)/a2f_tape_lib

SRC = $(wildcard *.s)
OBJ = $(SRC:.s=.o)
OBJ_DISK = $(addprefix $(OBJDIR_DISK)/,$(OBJ))
OBJ_TAPE = $(addprefix $(OBJDIR_TAPE)/,$(OBJ))

.PHONY: all clean a2f_disk a2f_tape

all: a2f_disk a2f_tape

a2f_disk: $(LIB_DISK)
a2f_tape: $(LIB_TAPE)

$(OBJDIR_DISK)/%.o: %.s ../a2f.inc
	$(CA65) -o $@ -D A2F_DISK -g $<
$(OBJDIR_TAPE)/%.o: %.s ../a2f.inc
	$(CA65) -o $@ -D A2F_TAPE -g $<

$(OBJ_DISK): | $(OBJDIR_DISK)
$(OBJ_TAPE): | $(OBJDIR_TAPE)
$(LIB_DISK) $(LIB_TAPE): | $(OUTDIR)

$(OBJDIR_DISK):
	$(MKDIR) $(subst /,$(DS),$@)
$(OBJDIR_TAPE):
	$(MKDIR) $(subst /,$(DS),$@)
$(OUTDIR):
	$(MKDIR) $(subst /,$(DS),$@)

$(LIB_DISK): $(OBJ_DISK)
	$(AR65) a $(LIB_DISK) $(OBJ_DISK)
$(LIB_TAPE): $(OBJ_TAPE)
	$(AR65) a $(LIB_TAPE) $(OBJ_TAPE)

clean:
	$(RM) $(subst /,$(DS),$(LIB_DISK) $(LIB_TAPE) $(OBJ_DISK) $(OBJ_TAPE))
