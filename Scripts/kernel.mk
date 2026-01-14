V ?= 0 #默认情况下，V变量为0，表示静默模式
Q := @  #默认情况下，命令前面加@表示不显示命令本身，只显示命令的输出结果
GRADER_V :=
ifeq ($(V), 1)
	Q :=
endif

ifeq ($(V), 2)
	Q :=
	GRADER_V := -v
endif

BUILDDIR := $(LABDIR)/build
KERNEL_IMG := $(BUILDDIR)/kernel.img
_QEMU := $(SCRIPTS)/qemu_wrapper.sh $(QEMU)
QEMU_GDB_PORT := 1234
QEMU_OPTS := -machine raspi3b -nographic -serial mon:stdio -m size=1G -kernel $(KERNEL_IMG)
CHBUILD := $(SCRIPTS)/chbuild #TODO：这后面如果面跟 -l参数，就是本地构建，否则就是docker构建
SERIAL := $(shell LC_ALL=C tr -dc A-Za-z0-9 </dev/urandom | head -c 13; echo)

export LABROOT LABDIR SCRIPTS LAB TIMEOUT

all: build

defconfig:
	$(Q)$(CHBUILD) defconfig

build:
	$(Q)test -f $(LABDIR)/.config || $(CHBUILD) defconfig
	$(Q)$(CHBUILD) build
	$(Q)find -L $(LABDIR) -path */compile_commands.json \
       ! -path $(LABDIR)/compile_commands.json -print \
	   | $(SCRIPTS)/merge_compile_commands.py
# 若 $(LABDIR)/.config 不存在，执行 defconfig 生成默认配置；存在则跳过。
# 执行实际构建: $(Q)$(CHBUILD) build
# 调用 chbuild 的 build 子命令完成内核/实验的编译。
# 合并编译命令数据库: 使用 find 查找所有子目录下的 compile_commands.json 文件（排除根目录下的），
# 并通过 merge_compile_commands.py 脚本将它们合并为一个
# compile_commands.json 文件，方便代码分析和工具使用。

# find 搜索实验目录下子目录里的 compile_commands.json（-L 跟随符号链接）。
# 排除顶层的 $(LABDIR)/compile_commands.json 自身（用 ! -path ...）。
# 把找到的路径喂给 merge_compile_commands.py，合并为统一的编译数据库，便于 VS Code 等工具准确跳转/索引。


clean:
	$(Q)$(CHBUILD) clean
	$(Q)find -L $(LABDIR) -path */compile_commands.json -exec rm {} \;

distclean:
	$(Q)$(CHBUILD) distclean

qemu: build
	$(Q)$(_QEMU) $(QEMU_OPTS)

qemu-grade:
	$(SCRIPTS)/change_serial $(KERNEL_IMG) $(SERIAL)
	$(Q)$(_QEMU) $(QEMU_OPTS)

qemu-gdb: build
	$(Q)echo "[QEMU] Waiting for GDB Connection"
	$(Q)$(_QEMU) -S -gdb tcp::$(QEMU_GDB_PORT) $(QEMU_OPTS)

gdb:
	$(Q)$(GDB) --nx -x $(SCRIPTS)/gdb/gdbinit

grade:  
	$(Q)$(MAKE) distclean > /dev/null 2>&1
	$(Q)(test -f $(LABDIR)/.config && cp $(LABDIR)/.config $(LABDIR)/.config.bak) || :
	$(Q)$(MAKE) build
	$(Q)$(DOCKER_RUN) $(GRADER) -t $(TIMEOUT) -f $(LABDIR)/scores.json $(GRADER_V) -s $(SERIAL) make SERIAL=$(SERIAL) qemu-grade
	$(Q)(test -f $(LABDIR)/.config.bak && cp $(LABDIR)/.config.bak $(LABDIR)/.config && rm .config.bak) || :

.PHONY: qemu qemu-gdb gdb defconfig build clean distclean grade all
