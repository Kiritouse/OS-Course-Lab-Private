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

#include <irq/timer.h>
#include <machine.h>
#include <common/kprint.h>
#include <common/types.h>
#include <arch/machine/smp.h>
#include <sched/sched.h>
#include <arch/tools.h>
#include <runtime/tests.h>

u64 cntp_tval;
u64 tick_per_us;
u64 cntp_init;
u64 cntp_freq;

/* Per core IRQ SOURCE MMIO address */
u64 core_timer_irqcntl[PLAT_CPU_NUM] = {
	CORE0_TIMER_IRQCNTL,
	CORE1_TIMER_IRQCNTL,
	CORE2_TIMER_IRQCNTL,
	CORE3_TIMER_IRQCNTL
};

void plat_timer_init(void)
{
	u64 timer_ctl = 0;
	u32 cpuid = smp_get_cpu_id();

	/* Since QEMU only emulate the generic timer, we use the generic timer here */
	asm volatile ("mrs %0, cntpct_el0":"=r" (cntp_init));
	kdebug("timer init cntpct_el0 = %lu\n", cntp_init);

	/* LAB 4 TODO BEGIN (exercise 5) */
	/* Note: you should add three lines of code. */
	/* Read system register cntfrq_el0 to cntp_freq*/
	// UNUSED(timer_ctl);
	//读取 CNTFRQ_EL0 寄存器，为全局变量 cntp_freq 赋值。
	asm volatile ("mrs %0, cntfrq_el0":"=r" (cntp_freq)); //获取计数频率
	/* Calculate the cntp_tval based on TICK_MS and cntp_freq */
	//注意cntp_freq的单位是HZ,我们要求ms
	//这里计算的是多少个时钟周期可以出发一个中断
	/* Write cntp_tval to the system register cntp_tval_el0 */
	cntp_tval = (cntp_freq *TICK_MS/ 1000); //计算多少个计数=一个时钟周期（类比于时钟周期，本质上上时钟滴答数）
	asm volatile ("msr cntp_tval_el0, %0"::"r" (cntp_tval));//设置一个时钟周期对应于多少个计数到寄存器汇总
	/* LAB 4 TODO END (exercise 5) */


	tick_per_us = cntp_freq / 1000 / 1000;
	/* Enable CNTPNSIRQ and CNTVIRQ */
	put32(core_timer_irqcntl[cpuid], INT_SRC_TIMER1 | INT_SRC_TIMER3);

	/* LAB 4 TODO BEGIN (exercise 5) */
	/* Note: you should add two lines of code. */
	/* Calculate the value of timer_ctl */
	/*计算控制寄存器*/
	timer_ctl = 1; //使能定时器，注意，这里第0位是最右边的，第1位是最左边的，那么bit 0 = 1，表示开启定时器,bit 1 = 0,表示中断未屏蔽
	/* Write timer_ctl to the control register (cntp_ctl_el0) */
	asm volatile ("msr cntp_ctl_el0, %0"::"r" (timer_ctl));

	/* LAB 4 TODO END (exercise 5) */
	lab4_test_timer_init();
	return;
}

void plat_set_next_timer(u64 tick_delta)
{
	// kinfo("%s: tick_delta 0x%lx\n", __func__, tick_delta);
	asm volatile ("msr cntp_tval_el0, %0"::"r" (tick_delta));
}

void plat_handle_timer_irq(u64 tick_delta)
{
	asm volatile ("msr cntp_tval_el0, %0"::"r" (tick_delta));
}

void plat_disable_timer(void)
{
	u64 timer_ctl = 0x0;

	asm volatile ("msr cntp_ctl_el0, %0"::"r" (timer_ctl));
}

void plat_enable_timer(void)
{
	u64 timer_ctl = 0x1;

	asm volatile ("msr cntp_tval_el0, %0"::"r" (cntp_tval));
	asm volatile ("msr cntp_ctl_el0, %0"::"r" (timer_ctl));

}

/* Return the mono time using nano-seconds */
u64 plat_get_mono_time(void)
{
	u64 cur_cnt = 0;
	asm volatile ("mrs %0, cntpct_el0":"=r" (cur_cnt));
	return (cur_cnt - cntp_init) * NS_IN_US / tick_per_us;
}

u64 plat_get_current_tick(void)
{
	u64 cur_cnt = 0;
	asm volatile ("mrs %0, cntpct_el0":"=r" (cur_cnt));
	return cur_cnt;
}
