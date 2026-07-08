/*
 * Copyright (c) 2023 Institute of Parallel And Distributed Systems (IPADS), Shanghai Jiao Tong University (SJTU)
 * Licensed under the Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *     http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR
 * PURPOSE.
 * See the Mulan PSL v2 for more details.
 */

/*
 * This file will be firstly configured by CMake to fill in `init_objects`,
 * then preprocessed by C compiler to fill in some definitions from `image.h`.
 */

#include "image.h"

/* 指定 ELF 的入口点符号为 _start（对应 boot 汇编代码里的入口标号），
 * 加载器/调试器会从这里开始执行。*/
ENTRY(_start)

SECTIONS
{
    /* 把编译产生的所有 DWARF 调试信息段统一放到虚拟地址 0 开始的地方。
     * 调试信息不会被实际加载进内存运行，放在 0 只是为了不占用/不干扰
     * 后面真正会被加载执行的代码段的地址空间。*/
    DWARF_DEBUG

    /* 把"当前地址"（location counter，也就是下面的 `.`）设置为 TEXT_OFFSET（0x80000）。
     * 之后所有 section 的地址都从这里开始往后排。
     * 之所以是 0x80000 而不是 0，是因为树莓派的固件/bootloader 约定会把
     * kernel8.img 加载到物理地址 0x80000 处再跳过去执行。*/
    . = TEXT_OFFSET; /*更新第一行代码为0x8000...之类的*/

    /* img_start 记录整个内核镜像在内存中的起始地址，方便后面（比如清空/校验镜像）引用。*/
    img_start = .; /*更新img_start为0x8000...之类的*/

    /*内核初始化部分*/

    /* init 段：内核刚上电时执行的启动代码（对应 kernel/arch/aarch64/boot/raspi3
     * 编译出的目标文件）。这个阶段 MMU 还没有打开，CPU 只能直接访问物理地址，
     * 所以这里没有写 AT()，即 VMA（运行时地址）= LMA（实际存放地址）= TEXT_OFFSET，
     * 两者必须一致，代码"以为自己在哪"就必须"真的在哪"。*/
    init : {
        ${init_objects}(.text* .data* .rodata* .bss* .extable*)
    }
    

    /* 按 4K 对齐，为后面的段做准备（内存管理通常以页为单位，4K 对齐方便后续建页表映射）。*/
    . = ALIGN(4K);
    /* init_end 记录 init 段结束后的（物理）地址，也就是后面 .text 等段
     * 在镜像文件里实际紧接着摆放的位置。*/
    init_end = ABSOLUTE(.);

    /* .text 段：内核正式代码。这里是整个脚本里最关键的一行：
     *   - VMA（冒号前面的地址，也就是 "运行时认为自己在哪"）= KERNEL_VADDR + init_end，
     *     一个很高的虚拟地址。因为 init 段执行完会建好页表并打开 MMU，
     *     从此以后 CPU 发出的地址都要经过页表翻译，.text 里的指令
     *     （跳转、访问全局变量等）必须按"开了 MMU 之后看到的高地址"编码。
     *   - LMA（AT() 里的地址，也就是"字节实际被存放的位置"）= init_end，
     *     一个紧跟在 init 段后面的低（物理）地址。因为内核镜像文件是被
     *     bootloader/QEMU 从 TEXT_OFFSET 开始按顺序、连续加载进物理内存的，
     *     .text 的字节必须物理上紧挨着 init 段摆放。
     * 也就是说：.text 这时候"自认为在高地址运行"，但字节"实际被摆在低地址"，
     * 等 init 段建好的页表把这个高地址映射回这块低地址物理内存，两者就对上了。*/
    .text KERNEL_VADDR + init_end : AT(init_end) {
    _text_start = .;
        *(.text*)
    }
    . = ALIGN(4K);
    _text_end = .;

    /* .data 段：已初始化的全局变量/静态变量。
     * 这里没有再显式写运行地址或 AT()：链接器有个隐含规则——一旦某个
     * section 用 AT() 建立了"运行地址(VMA)与实际存放地址(LMA)之间的偏移量"，
     * 后面没写 AT() 的 section 会自动沿用这个偏移量继续往后排：
     * VMA 接着 .text 的 VMA 继续往高地址走，LMA 也接着 .text 的 LMA
     * 继续往低（物理）地址走，两条"地址流水线"各自连续增长，
     * 不需要每个 section 都重复写一遍。*/
    .data : {
        *(.data*)
    }
    . = ALIGN(4K);

    /* .init.serial：串口初始化相关的代码/数据，单独放一个段方便管理。*/
    .init.serial : {
        *(.init.serial*)
    }
    . = ALIGN(4K);
    /* 减去 KERNEL_VADDR，是因为此时 `.`（location counter）追踪的是
     * VMA（高虚拟地址），减去 KERNEL_VADDR 就换算回了对应的物理偏移量——
     * 内核里一些早期引导代码需要知道"这块内存实际在物理内存的哪里"，
     * 而不是虚拟地址，所以要把符号值换算成物理地址存起来供代码使用。*/
    _serial_end = . - KERNEL_VADDR;

    /* .rodata 段：只读数据，比如字符串字面量、const 常量等。*/
    .rodata : {
        *(.rodata*)
    }
    . = ALIGN(4K);
    _edata = . - KERNEL_VADDR;

    /* .bss 段：未初始化的全局变量/静态变量。因为没有初始值，
     * 理论上不需要在 ELF 文件里真的占用空间存内容，只需要记录
     * "目标内存地址 + 大小"，加载时再由内核自己把这块内存清零即可。
     * _bss_start / _bss_end 记录的都是（换算回物理后的）地址范围，
     * 供内核启动早期清零 .bss 使用。*/
    _bss_start = . - KERNEL_VADDR;
    .bss : {
        *(.bss*)
    }
    . = ALIGN(4K);
    _bss_end = . - KERNEL_VADDR;

    /* .extable 段：异常处理表（exception table），内核发生异常/缺页时
     * 用来查表决定怎么处理（比如内核态访问非法地址时的修复逻辑）。*/
    _extable_start = .;
    .extable : {
        *(.extable*)
    }
    . = ALIGN(4K);
    _extable_end = .;
    
    /* img_end 记录整个内核镜像结束的（物理）地址，和 img_start 对应，
     * 方便后续代码知道镜像整体占用了多大范围的内存。*/
    img_end = . - KERNEL_VADDR;

    /* 丢弃一些不需要放进最终镜像的段：
     *   .comment  —— 编译器版本等注释信息
     *   .gnu*     —— GNU 工具链附加的一些段（如 .gnu.version）
     *   .note*    —— ELF note 段（如 .note.gnu.build-id）
     *   .eh_frame* —— C++ 异常处理用的栈展开信息，内核不需要
     * 这些段对内核运行没有意义，丢弃掉可以让镜像更小、更干净。*/
    /DISCARD/ : { *(.comment) *(.gnu*) *(.note*) *(.eh_frame*) }
}
