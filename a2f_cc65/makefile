DP = ../
include ../makefile.common

LIB = $(OUTDIR)/a2f_cc65.lib
OBJDIR = $(OUTDIR)/a2f_cc65_lib
OBJDIR_RUNTIME = $(OBJDIR)/runtime
OBJDIR_COMMON = $(OBJDIR)/common
OBJDIR_CONIO = $(OBJDIR)/conio
OBJCDIR_COMMON = $(OBJDIR)/common.c

SRC = $(wildcard *.s)
SRC_RUNTIME = $(wildcard ../cc65/libsrc/runtime/*.s)
SRC_COMMON  = $(wildcard ../cc65/libsrc/common/*.s)
SRC_CONIO   = $(wildcard ../cc65/libsrc/conio/*.s)

CSRC_COMMON = $(wildcard ../cc65/libsrc/common/*.c)
CSSRC_COMMON = $(addprefix ($OBJCDIR_COMMON)/,$(notdir $(CSRC_COMMON:.c=.s)))
CSSRCS_CLEAN = $(wildcard $(OBJCDIR_COMMON)/*.s)

OBJ = $(addprefix $(OBJDIR)/,$(notdir $(SRC:.s=.o)))
OBJ_RUNTIME = $(addprefix $(OBJDIR_RUNTIME)/,$(notdir $(SRC_RUNTIME:.s=.o)))
OBJ_COMMON  = $(addprefix $(OBJDIR_COMMON)/,$(notdir $(SRC_COMMON:.s=.o)))
OBJ_CONIO   = $(addprefix $(OBJDIR_CONIO)/,$(notdir $(SRC_CONIO:.s=.o)))
OBJC_COMMON = $(addprefix $(OBJCDIR_COMMON)/,$(notdir $(CSSRC_COMMON:.s=.o)))
OBJS = $(OBJ) $(OBJ_RUNTIME) $(OBJ_COMMON) $(OBJ_CONIO) $(OBJC_COMMON)

.PHONY: all clean

all: $(LIB)

$(OBJCDIR_COMMON)/%.s: ../cc65/libsrc/common/%.c
	$(CC65) -o $@ -g -O -W error $<
$(OBJCDIR_COMMON)/%.o: $(OBJCDIR_COMMON)/%.s
	$(CA65) -o $@ -g $<

$(OBJDIR_RUNTIME)/%.o: ../cc65/libsrc/runtime/%.s
	$(CA65) -o $@ -g $<
$(OBJDIR_COMMON)/%.o: ../cc65/libsrc/common/%.s
	$(CA65) -o $@ -g $<
$(OBJDIR_CONIO)/%.o: ../cc65/libsrc/conio/%.s
	$(CA65) -o $@ -g $<
$(OBJDIR)/%.o: %.s ../a2f.inc
	$(CA65) -o $@ -g $<

$(CSSRC_COMMON): | $(OBJCDIR_COMMON)
$(OBJ): | $(OBJDIR)
$(OBJ_RUNTIME): | $(OBJDIR_RUNTIME)
$(OBJ_COMMON): | $(OBJDIR_COMMON)
$(OBJ_CONIO): | $(OBJDIR_CONIO)
$(OBJC_COMMON): | $(OBJCDIR_COMMON)
$(LIB): | $(OUTDIR)
$(OBJDIR):
	$(MKDIR) $(subst /,$(DS),$@)
$(OBJDIR_RUNTIME):
	$(MKDIR) $(subst /,$(DS),$@)
$(OBJDIR_COMMON):
	$(MKDIR) $(subst /,$(DS),$@)
$(OBJDIR_CONIO):
	$(MKDIR) $(subst /,$(DS),$@)
$(OBJCDIR_COMMON):
	$(MKDIR) $(subst /,$(DS),$@)
$(OUTDIR):
	$(MKDIR) $(subst /,$(DS),$@)

$(LIB): $(OBJS)
	$(AR65) a $(LIB) $(OBJS)

clean:
	$(RM) $(subst /,$(DS),$(LIB) $(OBJS) $(CSSRCS_CLEAN))
