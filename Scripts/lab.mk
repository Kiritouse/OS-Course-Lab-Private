# Note that this file should be included directly in every Makefile inside each lab's folder.
# This sets up the environment variable for lab's Makefile.

# 这里主要是为了设置一些环境变量，方便后续的使用。
ifndef LABROOT
LABROOT := $(CURDIR)/..
endif

# SCRIPTS变量赋值为LABROOT目录下的Scripts文件夹路径
SCRIPTS := $(LABROOT)/Scripts

# 如果LAB变量没有被设置，则报错提示LAB is not set!
ifeq (,$(LAB))
$(error LAB is not set!)
endif

# 根据标签LAB，设置LABDIR变量为对应的实验目录路径
LABDIR  := $(LABROOT)/Lab$(LAB)
# 变量SCRIPTS赋值为LABROOT目录下的Scripts文件夹路径，ps:怎么感觉是重复定义了一次？
SCRIPTS := $(LABROOT)/Scripts
# 
GRADER  ?= $(SCRIPTS)/grader.sh

# Toolchain Configuration
ifeq ($(shell command -v gdb-multiarch 2> /dev/null),)  #检查 gdb-multiarch,并且报错误的信息重定向到垃圾桶
# Default to gdb if gdb-multiarch is not available
# This is only the case on debian-based distros
# 如果输出为空，代表是报错信息，那么就说明 gdb-multiarch 不存在
	GDB := gdb  
else
	GDB := gdb-multiarch
endif

# 如果用户没有定义 DOCKER 变量，则将其默认设置为 docker
DOCKER ?= docker
DOCKER_IMAGE ?= ipads/oslab:25.03
ifeq (,$(wildcard /docker.env)) # 如果说/docker.env 文件为空，docker_run变量为空，直接运行
DOCKER_RUN ?= 
else
DOCKER_RUN ?= $(DOCKER) run -it --rm \
		-e SCRIPTS=$(SCRIPTS) \
		-e LABROOT=$(LABROOT) \
		-e LABDIR=$(LABDIR) \
		-e TIMEOUT=$(TIMEOUT) \
		-e LAB=$(LAB) \
		-u $(shell id -u $(USER)):$(shell id -g $(USER)) \
		-v $(LABROOT):$(LABROOT) -w $(CURDIR) \
		--security-opt=seccomp:unconfined \
		--platform=linux/amd64 \
		$(DOCKER_IMAGE)
endif
QEMU-SYS ?= qemu-system-aarch64
QEMU-USER ?= qemu-aarch64

# Timeout for grading
TIMEOUT ?= 10

ifeq ($(shell test $(LAB) -eq 0; echo $$?),1)
	QEMU := $(QEMU-SYS)
	ifeq ($(shell test $(LAB) -gt 4; echo $$?),0)
		include $(LABROOT)/Scripts/extras/lab$(LAB).mk
	else
		include $(LABROOT)/Scripts/kernel.mk
	endif
	include $(LABROOT)/Scripts/submit.mk
else
	QEMU := $(QEMU-USER)
endif
