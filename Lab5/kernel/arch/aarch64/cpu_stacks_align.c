/*
 * all_in_one 整合修复：cpu_stacks 必须按页对齐。
 *
 * main.c（预编译，不可见）里 cpu_stacks 仅按 16 字节对齐（COMMON 符号，
 * align=0x10），但 main() 会把每个 CPU 的高地址内核栈 KSTACKx_ADDR(cpuid)
 * 映射到 virt_to_phys(cpu_stacks[cpuid])。页表项会把未对齐的物理地址向下
 * 截断到页边界，导致映射窗口相对数组整体偏移，CPU 正常使用内核栈即可
 * 覆写 cpu_stacks 附近的 .bss 全局变量（current_threads、
 * rr_ready_queue_meta 等），引发随链接布局漂移的随机内核损坏。
 *
 * 这里提供一个页对齐的同名试探性定义：链接器合并 COMMON 符号时取
 * 最大对齐，从而在不改动预编译 main.c.obj 的情况下强制页对齐。
 */
#include <common/vars.h>
#include <machine.h>

char cpu_stacks[PLAT_CPU_NUM][CPU_STACK_SIZE]
        __attribute__((aligned(CPU_STACK_SIZE)));
