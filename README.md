# ChCore —— all-in-one 可控内核

基于上海交通大学 IPADS《操作系统》课程 ChCore(v25.03)的完整微内核操作系统。
本分支把 Lab1-5 各实验中由我亲手实现、原本在后续实验中被封装为预编译
`.obj` 的代码全部还原为源码,融合为一棵可构建、可启动、可调试的完整源码树,
并以真实项目的目录结构组织(课程材料与各实验的独立目录见 lab0-lab6 分支)。

## 目录结构

```
kernel/       内核:启动(boot)、内存管理(mm)、进程线程与能力(object)、
              调度(sched)、IPC、系统调用、体系结构相关代码(arch/aarch64)
user/         用户态:procmgr、fsm、tmpfs 等系统服务,chcore-libc,测试程序
ramdisk/      初始 ramdisk(shell 与测试二进制)
Thirdparty/   musl-libc 等第三方组件
Scripts/      构建脚本(chbuild、CMake 模块、QEMU/GDB 封装)
CMakeLists.txt / config.cmake / Makefile   构建入口
```

## 构建与运行(建议在课程 devcontainer/ipads oslab 镜像内)

```bash
make defconfig   # 首次:生成 .config(raspi3 平台)
make build       # 构建内核与用户态,产物在 build/kernel.img
make qemu        # QEMU (raspi3b) 启动,启动后自动跑 fs 测试并进入 shell
make qemu-gdb    # 挂起等待 GDB(端口 1234)
make gdb         # 另一终端:连接调试
```

## 自实现部分(已全部源码化)

- Lab1 启动:`kernel/arch/aarch64/boot/raspi3`(start.S/tools.S/mmu.c/init_c.c/uart.c)
- Lab2 内存管理:`kernel/mm`(buddy/slab/kmalloc/vmspace/pgfault)与
  `kernel/arch/aarch64/mm/page_table.c`
- Lab3 进程线程:`kernel/object/{thread,cap_group}.c`、异常入口
  `kernel/arch/aarch64/irq/irq_entry.S`、上下文 `kernel/arch/aarch64/sched/context.c`
- Lab4 多核调度与 IPC:`kernel/sched/{sched,policy_rr}.c`、`kernel/ipc/connection.c`、
  时钟中断 `kernel/irq/timer.c` 等
- Lab5 文件系统:`user/system-services/system-servers/{fsm,fs_base}`
  (vnode/wrapper/页缓存/缺页与 llm 预取)

仍保持预编译的仅为课程未开放的参考实现(如 `kernel/arch/aarch64/main.c`、
`kernel/syscall/syscall.c` 等,见各目录 CMakeLists 的 chcore_target_precompile)。

## 整合过程中修复的问题

1. `kernel/incbin.tpl.S`:内嵌 procmgr ELF 强制页对齐(零拷贝加载的隐含前提)。
2. `kernel/arch/aarch64/cpu_stacks_align.c`:cpu_stacks 强制页对齐,
   修复 KSTACK 映射物理截断导致的 .bss 静默损坏。
3. 调度器 `find_runnable_thread` 迭代器误用修复。
4. llm 缺页优化:按访问递推链预取,全程 2 次缺页。

验证:QEMU 连续 10/10 次启动通过全部 fs 测试;课程评分 100/100。

## License

Mulan PSL v2(见 LICENSE;ChCore 版权归 SJTU IPADS)。
