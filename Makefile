#
# Makefile for tonclib.
#

#---------------------------------------------------------------------------------
.SUFFIXES:
#---------------------------------------------------------------------------------




# Works fine as-is (May need to copy more flags) for most but chokes on the tte.
#Seems to need "newlib"
# https://github.com/Patater/newlib/blob/master/newlib/libc/include/sys/iosupport.h
# C:\devkitPro\devkitARM\arm-none-eabi\include
# vs
# C:\Path\arm-gnu-toolchain-13.3.rel1-mingw-w64-i686-arm-none-eabi\lib\gcc\arm-none-eabi\13.3.1


PREFIX	:=	arm-none-eabi-
CC	:=	$(PREFIX)gcc
CXX	:=	$(PREFIX)g++
AS	:=	$(PREFIX)as
AR	:=	$(PREFIX)gcc-ar
OBJDUMP		:= $(PREFIX)objdump
OBJCOPY	:=	$(PREFIX)objcopy
STRIP	:=	$(PREFIX)strip
NM	:=	$(PREFIX)gcc-nm
RANLIB	:=	$(PREFIX)gcc-ranlib



BUILD		:=	build
SRCDIRS		:=	asm src src/font src/tte src/pre1.3
INCDIRS		:=	include
DATADIRS	:=	data

ARCH		:=	-mthumb -mthumb-interwork
RARCH		:= -mthumb-interwork -mthumb
IARCH		:= -mthumb-interwork -marm

bTEMPS		:= 0	# Save gcc temporaries (.i and .s files)
bDEBUG2		:= 0	# Generate debug info (bDEBUG2? Not a full DEBUG flag. Yet)

VERSION		:=	1.4.3

# --- Define V as "1" for explicit output ---
ifeq ($(V),1)
	SILENTMSG := @true
	SILENTCMD :=
else
	SILENTMSG := @echo
	SILENTCMD := @
endif

#---------------------------------------------------------------------------------
# Options for code generation
#---------------------------------------------------------------------------------

CBASE	:= $(INCLUDE) -Wall -fno-strict-aliasing #-fno-tree-loop-optimize
CBASE	+= -O2

RCFLAGS := $(CBASE) $(RARCH)
ICFLAGS := $(CBASE) $(IARCH) -mlong-calls #-fno-gcse
CFLAGS  := $(RCFLAGS)

ASFLAGS := $(INCLUDE) -Wa,--warn $(ARCH)

# --- Save temporary files ? ---
ifeq ($(strip $(bTEMPS)), 1)
	RCFLAGS  += -save-temps
	ICFLAGS  += -save-temps
	CFLAGS	 += -save-temps
	CXXFLAGS += -save-temps
endif

# --- Debug info ? ---

ifeq ($(strip $(bDEBUG2)), 1)
	CFLAGS	+= -g
	LDFLAGS	+= -g
endif

#---------------------------------------------------------------------------------

ifneq ($(BUILD),$(notdir $(CURDIR)))

export TARGET	:=	$(CURDIR)/lib/libtonc.a

export VPATH	:=	$(foreach dir,$(DATADIRS),$(CURDIR)/$(dir)) $(foreach dir,$(SRCDIRS),$(CURDIR)/$(dir))

ICFILES		:=	$(foreach dir,$(SRCDIRS),$(notdir $(wildcard $(dir)/*.iwram.c)))
RCFILES		:=	$(foreach dir,$(SRCDIRS),$(notdir $(wildcard $(dir)/*.c)))
CFILES		:=  $(ICFILES) $(RCFILES)

SFILES		:=	$(foreach dir,$(SRCDIRS),$(notdir $(wildcard $(dir)/*.s)))
BINFILES	:=	$(foreach dir,$(DATADIRS),$(notdir $(wildcard $(dir)/*.*)))

export OFILES	:=	$(addsuffix .o,$(BINFILES)) $(CFILES:.c=.o) $(SFILES:.s=.o)
export INCLUDE	:=	$(foreach dir,$(INCDIRS),-I$(CURDIR)/$(dir))
export DEPSDIR	:=	$(CURDIR)/build

.PHONY: $(BUILD) clean docs

$(BUILD):
	-@mkdir lib
	-@mkdir $@
	@$(MAKE) --no-print-directory -C $(BUILD) -f $(CURDIR)/Makefile

docs:
	doxygen libtonc.dox

clean:
	@echo clean ...
	@rm -fr $(BUILD)

#-------------------------------------------------------------------------------
dist:
#-------------------------------------------------------------------------------
	@tar -cvjf libtonc-src-$(VERSION).tar.bz2 asm src include \
		Makefile todo.txt libtonc.dox base.c base.h

#---------------------------------------------------------------------------------

else

DEPENDS	:=	$(OFILES:.o=.d)

#---------------------------------------------------------------------------------

%.a :

$(TARGET): $(OFILES)

%.a : $(OFILES)
	@echo Building $@
#	@rm -f $@
	@$(AR) -crs $@ $^
	$(PREFIX)nm -Sn $@ > $(basename $(notdir $@)).map

%.iwram.o : %.iwram.c
	@echo $(notdir $<)
	$(CC) -MMD -MP -MF $(DEPSDIR)/$(@:.o=.d) $(ICFLAGS) -c $< -o $@

%.o : %.c
	@echo $(notdir $<)
	$(CC) -MMD -MP -MF $(DEPSDIR)/$*.d $(RCFLAGS) -c $< -o $@

%.o: %.s
	@echo $(notdir $<)
	$(CC) -MMD -MP -MF $(DEPSDIR)/$*.d -x assembler-with-cpp $(CXXFLAGS) $(ASFLAGS) -c $< -o $@ $(ERROR_FILTER)

-include $(DEPENDS)

endif

#---------------------------------------------------------------------------------
