# ChCore all-in-one —— 独立构建入口(源自 Scripts/extras/lab5.mk,去除课程评分逻辑)
V ?= 0
Q := @
ifeq ($(V), 1)
	Q :=
endif

LABROOT  := $(CURDIR)
LABDIR   := $(CURDIR)
SCRIPTS  := $(LABROOT)/Scripts
BUILDDIR := $(LABDIR)/build
KERNEL_IMG := $(BUILDDIR)/kernel.img
CHBUILD  := $(SCRIPTS)/chbuild

QEMU-SYS ?= qemu-system-aarch64
_QEMU    := $(SCRIPTS)/qemu_wrapper.sh $(QEMU-SYS)
QEMU_GDB_PORT := 1234
QEMU_OPTS := -machine raspi3b -nographic -serial mon:stdio -m size=1G -kernel $(KERNEL_IMG)

ifeq ($(shell command -v gdb-multiarch 2> /dev/null),)
	GDB := gdb
else
	GDB := gdb-multiarch
endif

export LABROOT LABDIR SCRIPTS

all: build

defconfig:
	$(Q)$(CHBUILD) defconfig

build:
	$(Q)test -f $(LABDIR)/.config || $(CHBUILD) defconfig
	$(Q)$(CHBUILD) build

clean:
	$(Q)$(CHBUILD) clean

distclean:
	$(Q)$(CHBUILD) distclean

qemu: build
	$(Q)$(_QEMU) $(QEMU_OPTS)

qemu-gdb: build
	$(Q)echo "[QEMU] Waiting for GDB Connection"
	$(Q)$(_QEMU) -S -gdb tcp::$(QEMU_GDB_PORT) $(QEMU_OPTS)

gdb:
	$(Q)$(GDB) --nx -x $(SCRIPTS)/gdb/gdbinit

.PHONY: all defconfig build clean distclean qemu qemu-gdb gdb
