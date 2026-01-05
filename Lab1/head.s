
Lab1/kernel/arch/aarch64/head.S.dbg.obj:     file format elf64-littleaarch64


Disassembly of section .text:

0000000000000000 <start_kernel>:
   0:	58000302 	ldr	x2, 60 <secondary_cpu_boot+0x38>
   4:	91400442 	add	x2, x2, #0x1, lsl #12
   8:	9100005f 	mov	sp, x2
   c:	a9bf07e0 	stp	x0, x1, [sp, #-16]!
  10:	90000002 	adrp	x2, 0 <empty_page>
  14:	d5182002 	msr	ttbr0_el1, x2
  18:	d5033fdf 	isb
  1c:	94000000 	bl	0 <flush_tlb_all>
  20:	a8c107e0 	ldp	x0, x1, [sp], #16
  24:	94000000 	bl	0 <main>

0000000000000028 <secondary_cpu_boot>:
  28:	aa0003f3 	mov	x19, x0
  2c:	d2820001 	mov	x1, #0x1000                	// #4096
  30:	9b017c02 	mul	x2, x0, x1
  34:	58000163 	ldr	x3, 60 <secondary_cpu_boot+0x38>
  38:	8b030042 	add	x2, x2, x3
  3c:	91400442 	add	x2, x2, #0x1, lsl #12
  40:	9100005f 	mov	sp, x2
  44:	90000003 	adrp	x3, 0 <empty_page>
  48:	d5182003 	msr	ttbr0_el1, x3
  4c:	d5033fdf 	isb
  50:	94000000 	bl	0 <flush_tlb_all>
  54:	aa1303e0 	mov	x0, x19
  58:	94000000 	bl	0 <secondary_start>
	...
