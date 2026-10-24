
bin/kernel:     file format elf64-littleriscv


Disassembly of section .text:

ffffffffc0200000 <kern_entry>:
    .globl kern_entry
kern_entry:
    # a0: hartid
    # a1: dtb physical address
    # save hartid and dtb address
    la t0, boot_hartid
ffffffffc0200000:	00007297          	auipc	t0,0x7
ffffffffc0200004:	00028293          	mv	t0,t0
    sd a0, 0(t0)
ffffffffc0200008:	00a2b023          	sd	a0,0(t0) # ffffffffc0207000 <boot_hartid>
    la t0, boot_dtb
ffffffffc020000c:	00007297          	auipc	t0,0x7
ffffffffc0200010:	ffc28293          	addi	t0,t0,-4 # ffffffffc0207008 <boot_dtb>
    sd a1, 0(t0)
ffffffffc0200014:	00b2b023          	sd	a1,0(t0)

    # t0 := 三级页表的虚拟地址
    lui     t0, %hi(boot_page_table_sv39)
ffffffffc0200018:	c02062b7          	lui	t0,0xc0206
    # t1 := 0xffffffff40000000 即虚实映射偏移量
    li      t1, 0xffffffffc0000000 - 0x80000000
ffffffffc020001c:	ffd0031b          	addiw	t1,zero,-3
ffffffffc0200020:	037a                	slli	t1,t1,0x1e
    # t0 减去虚实映射偏移量 0xffffffff40000000，变为三级页表的物理地址
    sub     t0, t0, t1
ffffffffc0200022:	406282b3          	sub	t0,t0,t1
    # t0 >>= 12，变为三级页表的物理页号
    srli    t0, t0, 12
ffffffffc0200026:	00c2d293          	srli	t0,t0,0xc

    # t1 := 8 << 60，设置 satp 的 MODE 字段为 Sv39
    li      t1, 8 << 60
ffffffffc020002a:	fff0031b          	addiw	t1,zero,-1
ffffffffc020002e:	137e                	slli	t1,t1,0x3f
    # 将刚才计算出的预设三级页表物理页号附加到 satp 中
    or      t0, t0, t1
ffffffffc0200030:	0062e2b3          	or	t0,t0,t1
    # 将算出的 t0(即新的MODE|页表基址物理页号) 覆盖到 satp 中
    csrw    satp, t0
ffffffffc0200034:	18029073          	csrw	satp,t0
    # 使用 sfence.vma 指令刷新 TLB
    sfence.vma
ffffffffc0200038:	12000073          	sfence.vma
    # 从此，我们给内核搭建出了一个完美的虚拟内存空间！
    #nop # 可能映射的位置有些bug。。插入一个nop
    
    # 我们在虚拟内存空间中：随意将 sp 设置为虚拟地址！
    lui sp, %hi(bootstacktop)
ffffffffc020003c:	c0206137          	lui	sp,0xc0206

    # 我们在虚拟内存空间中：随意跳转到虚拟地址！
    # 跳转到 kern_init
    lui t0, %hi(kern_init)
ffffffffc0200040:	c02002b7          	lui	t0,0xc0200
    addi t0, t0, %lo(kern_init)
ffffffffc0200044:	0d828293          	addi	t0,t0,216 # ffffffffc02000d8 <kern_init>
    jr t0
ffffffffc0200048:	8282                	jr	t0

ffffffffc020004a <print_kerninfo>:
/* *
 * print_kerninfo - print the information about kernel, including the location
 * of kernel entry, the start addresses of data and text segements, the start
 * address of free memory and how many memory that kernel has used.
 * */
void print_kerninfo(void) {
ffffffffc020004a:	1141                	addi	sp,sp,-16
    extern char etext[], edata[], end[];
    cprintf("Special kernel symbols:\n");
ffffffffc020004c:	00002517          	auipc	a0,0x2
ffffffffc0200050:	14450513          	addi	a0,a0,324 # ffffffffc0202190 <etext+0x6>
void print_kerninfo(void) {
ffffffffc0200054:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc0200056:	0fe000ef          	jal	ra,ffffffffc0200154 <cprintf>
    cprintf("  entry  0x%016lx (virtual)\n", (uintptr_t)kern_init);
ffffffffc020005a:	00000597          	auipc	a1,0x0
ffffffffc020005e:	07e58593          	addi	a1,a1,126 # ffffffffc02000d8 <kern_init>
ffffffffc0200062:	00002517          	auipc	a0,0x2
ffffffffc0200066:	14e50513          	addi	a0,a0,334 # ffffffffc02021b0 <etext+0x26>
ffffffffc020006a:	0ea000ef          	jal	ra,ffffffffc0200154 <cprintf>
    cprintf("  etext  0x%016lx (virtual)\n", etext);
ffffffffc020006e:	00002597          	auipc	a1,0x2
ffffffffc0200072:	11c58593          	addi	a1,a1,284 # ffffffffc020218a <etext>
ffffffffc0200076:	00002517          	auipc	a0,0x2
ffffffffc020007a:	15a50513          	addi	a0,a0,346 # ffffffffc02021d0 <etext+0x46>
ffffffffc020007e:	0d6000ef          	jal	ra,ffffffffc0200154 <cprintf>
    cprintf("  edata  0x%016lx (virtual)\n", edata);
ffffffffc0200082:	00007597          	auipc	a1,0x7
ffffffffc0200086:	f9658593          	addi	a1,a1,-106 # ffffffffc0207018 <free_area>
ffffffffc020008a:	00002517          	auipc	a0,0x2
ffffffffc020008e:	16650513          	addi	a0,a0,358 # ffffffffc02021f0 <etext+0x66>
ffffffffc0200092:	0c2000ef          	jal	ra,ffffffffc0200154 <cprintf>
    cprintf("  end    0x%016lx (virtual)\n", end);
ffffffffc0200096:	00007597          	auipc	a1,0x7
ffffffffc020009a:	0a258593          	addi	a1,a1,162 # ffffffffc0207138 <end>
ffffffffc020009e:	00002517          	auipc	a0,0x2
ffffffffc02000a2:	17250513          	addi	a0,a0,370 # ffffffffc0202210 <etext+0x86>
ffffffffc02000a6:	0ae000ef          	jal	ra,ffffffffc0200154 <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - (char*)kern_init + 1023) / 1024);
ffffffffc02000aa:	00007597          	auipc	a1,0x7
ffffffffc02000ae:	48d58593          	addi	a1,a1,1165 # ffffffffc0207537 <end+0x3ff>
ffffffffc02000b2:	00000797          	auipc	a5,0x0
ffffffffc02000b6:	02678793          	addi	a5,a5,38 # ffffffffc02000d8 <kern_init>
ffffffffc02000ba:	40f587b3          	sub	a5,a1,a5
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02000be:	43f7d593          	srai	a1,a5,0x3f
}
ffffffffc02000c2:	60a2                	ld	ra,8(sp)
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02000c4:	3ff5f593          	andi	a1,a1,1023
ffffffffc02000c8:	95be                	add	a1,a1,a5
ffffffffc02000ca:	85a9                	srai	a1,a1,0xa
ffffffffc02000cc:	00002517          	auipc	a0,0x2
ffffffffc02000d0:	16450513          	addi	a0,a0,356 # ffffffffc0202230 <etext+0xa6>
}
ffffffffc02000d4:	0141                	addi	sp,sp,16
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02000d6:	a8bd                	j	ffffffffc0200154 <cprintf>

ffffffffc02000d8 <kern_init>:

int kern_init(void) {
    extern char edata[], end[];
    memset(edata, 0, end - edata);
ffffffffc02000d8:	00007517          	auipc	a0,0x7
ffffffffc02000dc:	f4050513          	addi	a0,a0,-192 # ffffffffc0207018 <free_area>
ffffffffc02000e0:	00007617          	auipc	a2,0x7
ffffffffc02000e4:	05860613          	addi	a2,a2,88 # ffffffffc0207138 <end>
int kern_init(void) {
ffffffffc02000e8:	1141                	addi	sp,sp,-16
    memset(edata, 0, end - edata);
ffffffffc02000ea:	8e09                	sub	a2,a2,a0
ffffffffc02000ec:	4581                	li	a1,0
int kern_init(void) {
ffffffffc02000ee:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
ffffffffc02000f0:	088020ef          	jal	ra,ffffffffc0202178 <memset>
    dtb_init();
ffffffffc02000f4:	134000ef          	jal	ra,ffffffffc0200228 <dtb_init>
    cons_init();  // init the console
ffffffffc02000f8:	126000ef          	jal	ra,ffffffffc020021e <cons_init>
    const char *message = "(THU.CST) os is loading ...\0";
    //cprintf("%s\n\n", message);
    cputs(message);
ffffffffc02000fc:	00002517          	auipc	a0,0x2
ffffffffc0200100:	16450513          	addi	a0,a0,356 # ffffffffc0202260 <etext+0xd6>
ffffffffc0200104:	086000ef          	jal	ra,ffffffffc020018a <cputs>

    print_kerninfo();
ffffffffc0200108:	f43ff0ef          	jal	ra,ffffffffc020004a <print_kerninfo>

    // grade_backtrace();
    pmm_init();  // init physical memory management
ffffffffc020010c:	76f000ef          	jal	ra,ffffffffc020107a <pmm_init>

    slub_init();  // init the simplified SLUB allocator
ffffffffc0200110:	406010ef          	jal	ra,ffffffffc0201516 <slub_init>
    slub_check();
ffffffffc0200114:	7c0010ef          	jal	ra,ffffffffc02018d4 <slub_check>

    /* do nothing */
    while (1)
ffffffffc0200118:	a001                	j	ffffffffc0200118 <kern_init+0x40>

ffffffffc020011a <cputch>:
/* *
 * cputch - writes a single character @c to stdout, and it will
 * increace the value of counter pointed by @cnt.
 * */
static void
cputch(int c, int *cnt) {
ffffffffc020011a:	1141                	addi	sp,sp,-16
ffffffffc020011c:	e022                	sd	s0,0(sp)
ffffffffc020011e:	e406                	sd	ra,8(sp)
ffffffffc0200120:	842e                	mv	s0,a1
    cons_putc(c);
ffffffffc0200122:	0fe000ef          	jal	ra,ffffffffc0200220 <cons_putc>
    (*cnt) ++;
ffffffffc0200126:	401c                	lw	a5,0(s0)
}
ffffffffc0200128:	60a2                	ld	ra,8(sp)
    (*cnt) ++;
ffffffffc020012a:	2785                	addiw	a5,a5,1
ffffffffc020012c:	c01c                	sw	a5,0(s0)
}
ffffffffc020012e:	6402                	ld	s0,0(sp)
ffffffffc0200130:	0141                	addi	sp,sp,16
ffffffffc0200132:	8082                	ret

ffffffffc0200134 <vcprintf>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want cprintf() instead.
 * */
int
vcprintf(const char *fmt, va_list ap) {
ffffffffc0200134:	1101                	addi	sp,sp,-32
ffffffffc0200136:	862a                	mv	a2,a0
ffffffffc0200138:	86ae                	mv	a3,a1
    int cnt = 0;
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc020013a:	00000517          	auipc	a0,0x0
ffffffffc020013e:	fe050513          	addi	a0,a0,-32 # ffffffffc020011a <cputch>
ffffffffc0200142:	006c                	addi	a1,sp,12
vcprintf(const char *fmt, va_list ap) {
ffffffffc0200144:	ec06                	sd	ra,24(sp)
    int cnt = 0;
ffffffffc0200146:	c602                	sw	zero,12(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc0200148:	41b010ef          	jal	ra,ffffffffc0201d62 <vprintfmt>
    return cnt;
}
ffffffffc020014c:	60e2                	ld	ra,24(sp)
ffffffffc020014e:	4532                	lw	a0,12(sp)
ffffffffc0200150:	6105                	addi	sp,sp,32
ffffffffc0200152:	8082                	ret

ffffffffc0200154 <cprintf>:
 *
 * The return value is the number of characters which would be
 * written to stdout.
 * */
int
cprintf(const char *fmt, ...) {
ffffffffc0200154:	711d                	addi	sp,sp,-96
    va_list ap;
    int cnt;
    va_start(ap, fmt);
ffffffffc0200156:	02810313          	addi	t1,sp,40 # ffffffffc0206028 <boot_page_table_sv39+0x28>
cprintf(const char *fmt, ...) {
ffffffffc020015a:	8e2a                	mv	t3,a0
ffffffffc020015c:	f42e                	sd	a1,40(sp)
ffffffffc020015e:	f832                	sd	a2,48(sp)
ffffffffc0200160:	fc36                	sd	a3,56(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc0200162:	00000517          	auipc	a0,0x0
ffffffffc0200166:	fb850513          	addi	a0,a0,-72 # ffffffffc020011a <cputch>
ffffffffc020016a:	004c                	addi	a1,sp,4
ffffffffc020016c:	869a                	mv	a3,t1
ffffffffc020016e:	8672                	mv	a2,t3
cprintf(const char *fmt, ...) {
ffffffffc0200170:	ec06                	sd	ra,24(sp)
ffffffffc0200172:	e0ba                	sd	a4,64(sp)
ffffffffc0200174:	e4be                	sd	a5,72(sp)
ffffffffc0200176:	e8c2                	sd	a6,80(sp)
ffffffffc0200178:	ecc6                	sd	a7,88(sp)
    va_start(ap, fmt);
ffffffffc020017a:	e41a                	sd	t1,8(sp)
    int cnt = 0;
ffffffffc020017c:	c202                	sw	zero,4(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc020017e:	3e5010ef          	jal	ra,ffffffffc0201d62 <vprintfmt>
    cnt = vcprintf(fmt, ap);
    va_end(ap);
    return cnt;
}
ffffffffc0200182:	60e2                	ld	ra,24(sp)
ffffffffc0200184:	4512                	lw	a0,4(sp)
ffffffffc0200186:	6125                	addi	sp,sp,96
ffffffffc0200188:	8082                	ret

ffffffffc020018a <cputs>:
/* *
 * cputs- writes the string pointed by @str to stdout and
 * appends a newline character.
 * */
int
cputs(const char *str) {
ffffffffc020018a:	1101                	addi	sp,sp,-32
ffffffffc020018c:	e822                	sd	s0,16(sp)
ffffffffc020018e:	ec06                	sd	ra,24(sp)
ffffffffc0200190:	e426                	sd	s1,8(sp)
ffffffffc0200192:	842a                	mv	s0,a0
    int cnt = 0;
    char c;
    while ((c = *str ++) != '\0') {
ffffffffc0200194:	00054503          	lbu	a0,0(a0)
ffffffffc0200198:	c51d                	beqz	a0,ffffffffc02001c6 <cputs+0x3c>
ffffffffc020019a:	0405                	addi	s0,s0,1
ffffffffc020019c:	4485                	li	s1,1
ffffffffc020019e:	9c81                	subw	s1,s1,s0
    cons_putc(c);
ffffffffc02001a0:	080000ef          	jal	ra,ffffffffc0200220 <cons_putc>
    while ((c = *str ++) != '\0') {
ffffffffc02001a4:	00044503          	lbu	a0,0(s0)
ffffffffc02001a8:	008487bb          	addw	a5,s1,s0
ffffffffc02001ac:	0405                	addi	s0,s0,1
ffffffffc02001ae:	f96d                	bnez	a0,ffffffffc02001a0 <cputs+0x16>
    (*cnt) ++;
ffffffffc02001b0:	0017841b          	addiw	s0,a5,1
    cons_putc(c);
ffffffffc02001b4:	4529                	li	a0,10
ffffffffc02001b6:	06a000ef          	jal	ra,ffffffffc0200220 <cons_putc>
        cputch(c, &cnt);
    }
    cputch('\n', &cnt);
    return cnt;
}
ffffffffc02001ba:	60e2                	ld	ra,24(sp)
ffffffffc02001bc:	8522                	mv	a0,s0
ffffffffc02001be:	6442                	ld	s0,16(sp)
ffffffffc02001c0:	64a2                	ld	s1,8(sp)
ffffffffc02001c2:	6105                	addi	sp,sp,32
ffffffffc02001c4:	8082                	ret
    while ((c = *str ++) != '\0') {
ffffffffc02001c6:	4405                	li	s0,1
ffffffffc02001c8:	b7f5                	j	ffffffffc02001b4 <cputs+0x2a>

ffffffffc02001ca <__panic>:
 * __panic - __panic is called on unresolvable fatal errors. it prints
 * "panic: 'message'", and then enters the kernel monitor.
 * */
void
__panic(const char *file, int line, const char *fmt, ...) {
    if (is_panic) {
ffffffffc02001ca:	00007317          	auipc	t1,0x7
ffffffffc02001ce:	f2630313          	addi	t1,t1,-218 # ffffffffc02070f0 <is_panic>
ffffffffc02001d2:	00032e03          	lw	t3,0(t1)
__panic(const char *file, int line, const char *fmt, ...) {
ffffffffc02001d6:	715d                	addi	sp,sp,-80
ffffffffc02001d8:	ec06                	sd	ra,24(sp)
ffffffffc02001da:	e822                	sd	s0,16(sp)
ffffffffc02001dc:	f436                	sd	a3,40(sp)
ffffffffc02001de:	f83a                	sd	a4,48(sp)
ffffffffc02001e0:	fc3e                	sd	a5,56(sp)
ffffffffc02001e2:	e0c2                	sd	a6,64(sp)
ffffffffc02001e4:	e4c6                	sd	a7,72(sp)
    if (is_panic) {
ffffffffc02001e6:	000e0363          	beqz	t3,ffffffffc02001ec <__panic+0x22>
    vcprintf(fmt, ap);
    cprintf("\n");
    va_end(ap);

panic_dead:
    while (1) {
ffffffffc02001ea:	a001                	j	ffffffffc02001ea <__panic+0x20>
    is_panic = 1;
ffffffffc02001ec:	4785                	li	a5,1
ffffffffc02001ee:	00f32023          	sw	a5,0(t1)
    va_start(ap, fmt);
ffffffffc02001f2:	8432                	mv	s0,a2
ffffffffc02001f4:	103c                	addi	a5,sp,40
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02001f6:	862e                	mv	a2,a1
ffffffffc02001f8:	85aa                	mv	a1,a0
ffffffffc02001fa:	00002517          	auipc	a0,0x2
ffffffffc02001fe:	08650513          	addi	a0,a0,134 # ffffffffc0202280 <etext+0xf6>
    va_start(ap, fmt);
ffffffffc0200202:	e43e                	sd	a5,8(sp)
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc0200204:	f51ff0ef          	jal	ra,ffffffffc0200154 <cprintf>
    vcprintf(fmt, ap);
ffffffffc0200208:	65a2                	ld	a1,8(sp)
ffffffffc020020a:	8522                	mv	a0,s0
ffffffffc020020c:	f29ff0ef          	jal	ra,ffffffffc0200134 <vcprintf>
    cprintf("\n");
ffffffffc0200210:	00003517          	auipc	a0,0x3
ffffffffc0200214:	85850513          	addi	a0,a0,-1960 # ffffffffc0202a68 <best_fit_pmm_manager+0x330>
ffffffffc0200218:	f3dff0ef          	jal	ra,ffffffffc0200154 <cprintf>
ffffffffc020021c:	b7f9                	j	ffffffffc02001ea <__panic+0x20>

ffffffffc020021e <cons_init>:

/* serial_intr - try to feed input characters from serial port */
void serial_intr(void) {}

/* cons_init - initializes the console devices */
void cons_init(void) {}
ffffffffc020021e:	8082                	ret

ffffffffc0200220 <cons_putc>:

/* cons_putc - print a single character @c to console devices */
void cons_putc(int c) { sbi_console_putchar((unsigned char)c); }
ffffffffc0200220:	0ff57513          	zext.b	a0,a0
ffffffffc0200224:	6c10106f          	j	ffffffffc02020e4 <sbi_console_putchar>

ffffffffc0200228 <dtb_init>:

// 保存解析出的系统物理内存信息
static uint64_t memory_base = 0;
static uint64_t memory_size = 0;

void dtb_init(void) {
ffffffffc0200228:	7119                	addi	sp,sp,-128
    cprintf("DTB Init\n");
ffffffffc020022a:	00002517          	auipc	a0,0x2
ffffffffc020022e:	07650513          	addi	a0,a0,118 # ffffffffc02022a0 <etext+0x116>
void dtb_init(void) {
ffffffffc0200232:	fc86                	sd	ra,120(sp)
ffffffffc0200234:	f8a2                	sd	s0,112(sp)
ffffffffc0200236:	e8d2                	sd	s4,80(sp)
ffffffffc0200238:	f4a6                	sd	s1,104(sp)
ffffffffc020023a:	f0ca                	sd	s2,96(sp)
ffffffffc020023c:	ecce                	sd	s3,88(sp)
ffffffffc020023e:	e4d6                	sd	s5,72(sp)
ffffffffc0200240:	e0da                	sd	s6,64(sp)
ffffffffc0200242:	fc5e                	sd	s7,56(sp)
ffffffffc0200244:	f862                	sd	s8,48(sp)
ffffffffc0200246:	f466                	sd	s9,40(sp)
ffffffffc0200248:	f06a                	sd	s10,32(sp)
ffffffffc020024a:	ec6e                	sd	s11,24(sp)
    cprintf("DTB Init\n");
ffffffffc020024c:	f09ff0ef          	jal	ra,ffffffffc0200154 <cprintf>
    cprintf("HartID: %ld\n", boot_hartid);
ffffffffc0200250:	00007597          	auipc	a1,0x7
ffffffffc0200254:	db05b583          	ld	a1,-592(a1) # ffffffffc0207000 <boot_hartid>
ffffffffc0200258:	00002517          	auipc	a0,0x2
ffffffffc020025c:	05850513          	addi	a0,a0,88 # ffffffffc02022b0 <etext+0x126>
ffffffffc0200260:	ef5ff0ef          	jal	ra,ffffffffc0200154 <cprintf>
    cprintf("DTB Address: 0x%lx\n", boot_dtb);
ffffffffc0200264:	00007417          	auipc	s0,0x7
ffffffffc0200268:	da440413          	addi	s0,s0,-604 # ffffffffc0207008 <boot_dtb>
ffffffffc020026c:	600c                	ld	a1,0(s0)
ffffffffc020026e:	00002517          	auipc	a0,0x2
ffffffffc0200272:	05250513          	addi	a0,a0,82 # ffffffffc02022c0 <etext+0x136>
ffffffffc0200276:	edfff0ef          	jal	ra,ffffffffc0200154 <cprintf>
    
    if (boot_dtb == 0) {
ffffffffc020027a:	00043a03          	ld	s4,0(s0)
        cprintf("Error: DTB address is null\n");
ffffffffc020027e:	00002517          	auipc	a0,0x2
ffffffffc0200282:	05a50513          	addi	a0,a0,90 # ffffffffc02022d8 <etext+0x14e>
    if (boot_dtb == 0) {
ffffffffc0200286:	120a0463          	beqz	s4,ffffffffc02003ae <dtb_init+0x186>
        return;
    }
    
    // 转换为虚拟地址
    uintptr_t dtb_vaddr = boot_dtb + PHYSICAL_MEMORY_OFFSET;
ffffffffc020028a:	57f5                	li	a5,-3
ffffffffc020028c:	07fa                	slli	a5,a5,0x1e
ffffffffc020028e:	00fa0733          	add	a4,s4,a5
    const struct fdt_header *header = (const struct fdt_header *)dtb_vaddr;
    
    // 验证DTB
    uint32_t magic = fdt32_to_cpu(header->magic);
ffffffffc0200292:	431c                	lw	a5,0(a4)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200294:	00ff0637          	lui	a2,0xff0
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200298:	6b41                	lui	s6,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020029a:	0087d59b          	srliw	a1,a5,0x8
ffffffffc020029e:	0187969b          	slliw	a3,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002a2:	0187d51b          	srliw	a0,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002a6:	0105959b          	slliw	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002aa:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002ae:	8df1                	and	a1,a1,a2
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002b0:	8ec9                	or	a3,a3,a0
ffffffffc02002b2:	0087979b          	slliw	a5,a5,0x8
ffffffffc02002b6:	1b7d                	addi	s6,s6,-1
ffffffffc02002b8:	0167f7b3          	and	a5,a5,s6
ffffffffc02002bc:	8dd5                	or	a1,a1,a3
ffffffffc02002be:	8ddd                	or	a1,a1,a5
    if (magic != 0xd00dfeed) {
ffffffffc02002c0:	d00e07b7          	lui	a5,0xd00e0
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002c4:	2581                	sext.w	a1,a1
    if (magic != 0xd00dfeed) {
ffffffffc02002c6:	eed78793          	addi	a5,a5,-275 # ffffffffd00dfeed <end+0xfed8db5>
ffffffffc02002ca:	10f59163          	bne	a1,a5,ffffffffc02003cc <dtb_init+0x1a4>
        return;
    }
    
    // 提取内存信息
    uint64_t mem_base, mem_size;
    if (extract_memory_info(dtb_vaddr, header, &mem_base, &mem_size) == 0) {
ffffffffc02002ce:	471c                	lw	a5,8(a4)
ffffffffc02002d0:	4754                	lw	a3,12(a4)
    int in_memory_node = 0;
ffffffffc02002d2:	4c81                	li	s9,0
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002d4:	0087d59b          	srliw	a1,a5,0x8
ffffffffc02002d8:	0086d51b          	srliw	a0,a3,0x8
ffffffffc02002dc:	0186941b          	slliw	s0,a3,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002e0:	0186d89b          	srliw	a7,a3,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002e4:	01879a1b          	slliw	s4,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002e8:	0187d81b          	srliw	a6,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002ec:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002f0:	0106d69b          	srliw	a3,a3,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002f4:	0105959b          	slliw	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002f8:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002fc:	8d71                	and	a0,a0,a2
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002fe:	01146433          	or	s0,s0,a7
ffffffffc0200302:	0086969b          	slliw	a3,a3,0x8
ffffffffc0200306:	010a6a33          	or	s4,s4,a6
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020030a:	8e6d                	and	a2,a2,a1
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020030c:	0087979b          	slliw	a5,a5,0x8
ffffffffc0200310:	8c49                	or	s0,s0,a0
ffffffffc0200312:	0166f6b3          	and	a3,a3,s6
ffffffffc0200316:	00ca6a33          	or	s4,s4,a2
ffffffffc020031a:	0167f7b3          	and	a5,a5,s6
ffffffffc020031e:	8c55                	or	s0,s0,a3
ffffffffc0200320:	00fa6a33          	or	s4,s4,a5
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc0200324:	1402                	slli	s0,s0,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc0200326:	1a02                	slli	s4,s4,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc0200328:	9001                	srli	s0,s0,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc020032a:	020a5a13          	srli	s4,s4,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc020032e:	943a                	add	s0,s0,a4
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc0200330:	9a3a                	add	s4,s4,a4
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200332:	00ff0c37          	lui	s8,0xff0
        switch (token) {
ffffffffc0200336:	4b8d                	li	s7,3
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc0200338:	00002917          	auipc	s2,0x2
ffffffffc020033c:	ff090913          	addi	s2,s2,-16 # ffffffffc0202328 <etext+0x19e>
ffffffffc0200340:	49bd                	li	s3,15
        switch (token) {
ffffffffc0200342:	4d91                	li	s11,4
ffffffffc0200344:	4d05                	li	s10,1
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc0200346:	00002497          	auipc	s1,0x2
ffffffffc020034a:	fda48493          	addi	s1,s1,-38 # ffffffffc0202320 <etext+0x196>
        uint32_t token = fdt32_to_cpu(*struct_ptr++);
ffffffffc020034e:	000a2703          	lw	a4,0(s4)
ffffffffc0200352:	004a0a93          	addi	s5,s4,4
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200356:	0087569b          	srliw	a3,a4,0x8
ffffffffc020035a:	0187179b          	slliw	a5,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020035e:	0187561b          	srliw	a2,a4,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200362:	0106969b          	slliw	a3,a3,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200366:	0107571b          	srliw	a4,a4,0x10
ffffffffc020036a:	8fd1                	or	a5,a5,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020036c:	0186f6b3          	and	a3,a3,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200370:	0087171b          	slliw	a4,a4,0x8
ffffffffc0200374:	8fd5                	or	a5,a5,a3
ffffffffc0200376:	00eb7733          	and	a4,s6,a4
ffffffffc020037a:	8fd9                	or	a5,a5,a4
ffffffffc020037c:	2781                	sext.w	a5,a5
        switch (token) {
ffffffffc020037e:	09778c63          	beq	a5,s7,ffffffffc0200416 <dtb_init+0x1ee>
ffffffffc0200382:	00fbea63          	bltu	s7,a5,ffffffffc0200396 <dtb_init+0x16e>
ffffffffc0200386:	07a78663          	beq	a5,s10,ffffffffc02003f2 <dtb_init+0x1ca>
ffffffffc020038a:	4709                	li	a4,2
ffffffffc020038c:	00e79763          	bne	a5,a4,ffffffffc020039a <dtb_init+0x172>
ffffffffc0200390:	4c81                	li	s9,0
ffffffffc0200392:	8a56                	mv	s4,s5
ffffffffc0200394:	bf6d                	j	ffffffffc020034e <dtb_init+0x126>
ffffffffc0200396:	ffb78ee3          	beq	a5,s11,ffffffffc0200392 <dtb_init+0x16a>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
        // 保存到全局变量，供 PMM 查询
        memory_base = mem_base;
        memory_size = mem_size;
    } else {
        cprintf("Warning: Could not extract memory info from DTB\n");
ffffffffc020039a:	00002517          	auipc	a0,0x2
ffffffffc020039e:	00650513          	addi	a0,a0,6 # ffffffffc02023a0 <etext+0x216>
ffffffffc02003a2:	db3ff0ef          	jal	ra,ffffffffc0200154 <cprintf>
    }
    cprintf("DTB init completed\n");
ffffffffc02003a6:	00002517          	auipc	a0,0x2
ffffffffc02003aa:	03250513          	addi	a0,a0,50 # ffffffffc02023d8 <etext+0x24e>
}
ffffffffc02003ae:	7446                	ld	s0,112(sp)
ffffffffc02003b0:	70e6                	ld	ra,120(sp)
ffffffffc02003b2:	74a6                	ld	s1,104(sp)
ffffffffc02003b4:	7906                	ld	s2,96(sp)
ffffffffc02003b6:	69e6                	ld	s3,88(sp)
ffffffffc02003b8:	6a46                	ld	s4,80(sp)
ffffffffc02003ba:	6aa6                	ld	s5,72(sp)
ffffffffc02003bc:	6b06                	ld	s6,64(sp)
ffffffffc02003be:	7be2                	ld	s7,56(sp)
ffffffffc02003c0:	7c42                	ld	s8,48(sp)
ffffffffc02003c2:	7ca2                	ld	s9,40(sp)
ffffffffc02003c4:	7d02                	ld	s10,32(sp)
ffffffffc02003c6:	6de2                	ld	s11,24(sp)
ffffffffc02003c8:	6109                	addi	sp,sp,128
    cprintf("DTB init completed\n");
ffffffffc02003ca:	b369                	j	ffffffffc0200154 <cprintf>
}
ffffffffc02003cc:	7446                	ld	s0,112(sp)
ffffffffc02003ce:	70e6                	ld	ra,120(sp)
ffffffffc02003d0:	74a6                	ld	s1,104(sp)
ffffffffc02003d2:	7906                	ld	s2,96(sp)
ffffffffc02003d4:	69e6                	ld	s3,88(sp)
ffffffffc02003d6:	6a46                	ld	s4,80(sp)
ffffffffc02003d8:	6aa6                	ld	s5,72(sp)
ffffffffc02003da:	6b06                	ld	s6,64(sp)
ffffffffc02003dc:	7be2                	ld	s7,56(sp)
ffffffffc02003de:	7c42                	ld	s8,48(sp)
ffffffffc02003e0:	7ca2                	ld	s9,40(sp)
ffffffffc02003e2:	7d02                	ld	s10,32(sp)
ffffffffc02003e4:	6de2                	ld	s11,24(sp)
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc02003e6:	00002517          	auipc	a0,0x2
ffffffffc02003ea:	f1250513          	addi	a0,a0,-238 # ffffffffc02022f8 <etext+0x16e>
}
ffffffffc02003ee:	6109                	addi	sp,sp,128
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc02003f0:	b395                	j	ffffffffc0200154 <cprintf>
                int name_len = strlen(name);
ffffffffc02003f2:	8556                	mv	a0,s5
ffffffffc02003f4:	50b010ef          	jal	ra,ffffffffc02020fe <strlen>
ffffffffc02003f8:	8a2a                	mv	s4,a0
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02003fa:	4619                	li	a2,6
ffffffffc02003fc:	85a6                	mv	a1,s1
ffffffffc02003fe:	8556                	mv	a0,s5
                int name_len = strlen(name);
ffffffffc0200400:	2a01                	sext.w	s4,s4
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc0200402:	551010ef          	jal	ra,ffffffffc0202152 <strncmp>
ffffffffc0200406:	e111                	bnez	a0,ffffffffc020040a <dtb_init+0x1e2>
                    in_memory_node = 1;
ffffffffc0200408:	4c85                	li	s9,1
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + name_len + 4) & ~3);
ffffffffc020040a:	0a91                	addi	s5,s5,4
ffffffffc020040c:	9ad2                	add	s5,s5,s4
ffffffffc020040e:	ffcafa93          	andi	s5,s5,-4
        switch (token) {
ffffffffc0200412:	8a56                	mv	s4,s5
ffffffffc0200414:	bf2d                	j	ffffffffc020034e <dtb_init+0x126>
                uint32_t prop_len = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200416:	004a2783          	lw	a5,4(s4)
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc020041a:	00ca0693          	addi	a3,s4,12
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020041e:	0087d71b          	srliw	a4,a5,0x8
ffffffffc0200422:	01879a9b          	slliw	s5,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200426:	0187d61b          	srliw	a2,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020042a:	0107171b          	slliw	a4,a4,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020042e:	0107d79b          	srliw	a5,a5,0x10
ffffffffc0200432:	00caeab3          	or	s5,s5,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200436:	01877733          	and	a4,a4,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020043a:	0087979b          	slliw	a5,a5,0x8
ffffffffc020043e:	00eaeab3          	or	s5,s5,a4
ffffffffc0200442:	00fb77b3          	and	a5,s6,a5
ffffffffc0200446:	00faeab3          	or	s5,s5,a5
ffffffffc020044a:	2a81                	sext.w	s5,s5
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc020044c:	000c9c63          	bnez	s9,ffffffffc0200464 <dtb_init+0x23c>
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + prop_len + 3) & ~3);
ffffffffc0200450:	1a82                	slli	s5,s5,0x20
ffffffffc0200452:	00368793          	addi	a5,a3,3
ffffffffc0200456:	020ada93          	srli	s5,s5,0x20
ffffffffc020045a:	9abe                	add	s5,s5,a5
ffffffffc020045c:	ffcafa93          	andi	s5,s5,-4
        switch (token) {
ffffffffc0200460:	8a56                	mv	s4,s5
ffffffffc0200462:	b5f5                	j	ffffffffc020034e <dtb_init+0x126>
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200464:	008a2783          	lw	a5,8(s4)
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc0200468:	85ca                	mv	a1,s2
ffffffffc020046a:	e436                	sd	a3,8(sp)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020046c:	0087d51b          	srliw	a0,a5,0x8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200470:	0187d61b          	srliw	a2,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200474:	0187971b          	slliw	a4,a5,0x18
ffffffffc0200478:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020047c:	0107d79b          	srliw	a5,a5,0x10
ffffffffc0200480:	8f51                	or	a4,a4,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200482:	01857533          	and	a0,a0,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200486:	0087979b          	slliw	a5,a5,0x8
ffffffffc020048a:	8d59                	or	a0,a0,a4
ffffffffc020048c:	00fb77b3          	and	a5,s6,a5
ffffffffc0200490:	8d5d                	or	a0,a0,a5
                const char *prop_name = strings_base + prop_nameoff;
ffffffffc0200492:	1502                	slli	a0,a0,0x20
ffffffffc0200494:	9101                	srli	a0,a0,0x20
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc0200496:	9522                	add	a0,a0,s0
ffffffffc0200498:	49d010ef          	jal	ra,ffffffffc0202134 <strcmp>
ffffffffc020049c:	66a2                	ld	a3,8(sp)
ffffffffc020049e:	f94d                	bnez	a0,ffffffffc0200450 <dtb_init+0x228>
ffffffffc02004a0:	fb59f8e3          	bgeu	s3,s5,ffffffffc0200450 <dtb_init+0x228>
                    *mem_base = fdt64_to_cpu(reg_data[0]);
ffffffffc02004a4:	00ca3783          	ld	a5,12(s4)
                    *mem_size = fdt64_to_cpu(reg_data[1]);
ffffffffc02004a8:	014a3703          	ld	a4,20(s4)
        cprintf("Physical Memory from DTB:\n");
ffffffffc02004ac:	00002517          	auipc	a0,0x2
ffffffffc02004b0:	e8450513          	addi	a0,a0,-380 # ffffffffc0202330 <etext+0x1a6>
           fdt32_to_cpu(x >> 32);
ffffffffc02004b4:	4207d613          	srai	a2,a5,0x20
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004b8:	0087d31b          	srliw	t1,a5,0x8
           fdt32_to_cpu(x >> 32);
ffffffffc02004bc:	42075593          	srai	a1,a4,0x20
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004c0:	0187de1b          	srliw	t3,a5,0x18
ffffffffc02004c4:	0186581b          	srliw	a6,a2,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004c8:	0187941b          	slliw	s0,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004cc:	0107d89b          	srliw	a7,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004d0:	0187d693          	srli	a3,a5,0x18
ffffffffc02004d4:	01861f1b          	slliw	t5,a2,0x18
ffffffffc02004d8:	0087579b          	srliw	a5,a4,0x8
ffffffffc02004dc:	0103131b          	slliw	t1,t1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004e0:	0106561b          	srliw	a2,a2,0x10
ffffffffc02004e4:	010f6f33          	or	t5,t5,a6
ffffffffc02004e8:	0187529b          	srliw	t0,a4,0x18
ffffffffc02004ec:	0185df9b          	srliw	t6,a1,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004f0:	01837333          	and	t1,t1,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004f4:	01c46433          	or	s0,s0,t3
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004f8:	0186f6b3          	and	a3,a3,s8
ffffffffc02004fc:	01859e1b          	slliw	t3,a1,0x18
ffffffffc0200500:	01871e9b          	slliw	t4,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200504:	0107581b          	srliw	a6,a4,0x10
ffffffffc0200508:	0086161b          	slliw	a2,a2,0x8
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020050c:	8361                	srli	a4,a4,0x18
ffffffffc020050e:	0107979b          	slliw	a5,a5,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200512:	0105d59b          	srliw	a1,a1,0x10
ffffffffc0200516:	01e6e6b3          	or	a3,a3,t5
ffffffffc020051a:	00cb7633          	and	a2,s6,a2
ffffffffc020051e:	0088181b          	slliw	a6,a6,0x8
ffffffffc0200522:	0085959b          	slliw	a1,a1,0x8
ffffffffc0200526:	00646433          	or	s0,s0,t1
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020052a:	0187f7b3          	and	a5,a5,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020052e:	01fe6333          	or	t1,t3,t6
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200532:	01877c33          	and	s8,a4,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200536:	0088989b          	slliw	a7,a7,0x8
ffffffffc020053a:	011b78b3          	and	a7,s6,a7
ffffffffc020053e:	005eeeb3          	or	t4,t4,t0
ffffffffc0200542:	00c6e733          	or	a4,a3,a2
ffffffffc0200546:	006c6c33          	or	s8,s8,t1
ffffffffc020054a:	010b76b3          	and	a3,s6,a6
ffffffffc020054e:	00bb7b33          	and	s6,s6,a1
ffffffffc0200552:	01d7e7b3          	or	a5,a5,t4
ffffffffc0200556:	016c6b33          	or	s6,s8,s6
ffffffffc020055a:	01146433          	or	s0,s0,a7
ffffffffc020055e:	8fd5                	or	a5,a5,a3
           fdt32_to_cpu(x >> 32);
ffffffffc0200560:	1702                	slli	a4,a4,0x20
ffffffffc0200562:	1b02                	slli	s6,s6,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc0200564:	1782                	slli	a5,a5,0x20
           fdt32_to_cpu(x >> 32);
ffffffffc0200566:	9301                	srli	a4,a4,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc0200568:	1402                	slli	s0,s0,0x20
           fdt32_to_cpu(x >> 32);
ffffffffc020056a:	020b5b13          	srli	s6,s6,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc020056e:	0167eb33          	or	s6,a5,s6
ffffffffc0200572:	8c59                	or	s0,s0,a4
        cprintf("Physical Memory from DTB:\n");
ffffffffc0200574:	be1ff0ef          	jal	ra,ffffffffc0200154 <cprintf>
        cprintf("  Base: 0x%016lx\n", mem_base);
ffffffffc0200578:	85a2                	mv	a1,s0
ffffffffc020057a:	00002517          	auipc	a0,0x2
ffffffffc020057e:	dd650513          	addi	a0,a0,-554 # ffffffffc0202350 <etext+0x1c6>
ffffffffc0200582:	bd3ff0ef          	jal	ra,ffffffffc0200154 <cprintf>
        cprintf("  Size: 0x%016lx (%ld MB)\n", mem_size, mem_size / (1024 * 1024));
ffffffffc0200586:	014b5613          	srli	a2,s6,0x14
ffffffffc020058a:	85da                	mv	a1,s6
ffffffffc020058c:	00002517          	auipc	a0,0x2
ffffffffc0200590:	ddc50513          	addi	a0,a0,-548 # ffffffffc0202368 <etext+0x1de>
ffffffffc0200594:	bc1ff0ef          	jal	ra,ffffffffc0200154 <cprintf>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
ffffffffc0200598:	008b05b3          	add	a1,s6,s0
ffffffffc020059c:	15fd                	addi	a1,a1,-1
ffffffffc020059e:	00002517          	auipc	a0,0x2
ffffffffc02005a2:	dea50513          	addi	a0,a0,-534 # ffffffffc0202388 <etext+0x1fe>
ffffffffc02005a6:	bafff0ef          	jal	ra,ffffffffc0200154 <cprintf>
    cprintf("DTB init completed\n");
ffffffffc02005aa:	00002517          	auipc	a0,0x2
ffffffffc02005ae:	e2e50513          	addi	a0,a0,-466 # ffffffffc02023d8 <etext+0x24e>
        memory_base = mem_base;
ffffffffc02005b2:	00007797          	auipc	a5,0x7
ffffffffc02005b6:	b487b323          	sd	s0,-1210(a5) # ffffffffc02070f8 <memory_base>
        memory_size = mem_size;
ffffffffc02005ba:	00007797          	auipc	a5,0x7
ffffffffc02005be:	b567b323          	sd	s6,-1210(a5) # ffffffffc0207100 <memory_size>
    cprintf("DTB init completed\n");
ffffffffc02005c2:	b3f5                	j	ffffffffc02003ae <dtb_init+0x186>

ffffffffc02005c4 <get_memory_base>:

uint64_t get_memory_base(void) {
    return memory_base;
}
ffffffffc02005c4:	00007517          	auipc	a0,0x7
ffffffffc02005c8:	b3453503          	ld	a0,-1228(a0) # ffffffffc02070f8 <memory_base>
ffffffffc02005cc:	8082                	ret

ffffffffc02005ce <get_memory_size>:

uint64_t get_memory_size(void) {
    return memory_size;
ffffffffc02005ce:	00007517          	auipc	a0,0x7
ffffffffc02005d2:	b3253503          	ld	a0,-1230(a0) # ffffffffc0207100 <memory_size>
ffffffffc02005d6:	8082                	ret

ffffffffc02005d8 <best_fit_init>:
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
ffffffffc02005d8:	00007797          	auipc	a5,0x7
ffffffffc02005dc:	a4078793          	addi	a5,a5,-1472 # ffffffffc0207018 <free_area>
ffffffffc02005e0:	e79c                	sd	a5,8(a5)
ffffffffc02005e2:	e39c                	sd	a5,0(a5)
#define nr_free (free_area.nr_free)

static void
best_fit_init(void) {
    list_init(&free_list);
    nr_free = 0;
ffffffffc02005e4:	0007a823          	sw	zero,16(a5)
}
ffffffffc02005e8:	8082                	ret

ffffffffc02005ea <best_fit_nr_free_pages>:
}

static size_t
best_fit_nr_free_pages(void) {
    return nr_free;
}
ffffffffc02005ea:	00007517          	auipc	a0,0x7
ffffffffc02005ee:	a3e56503          	lwu	a0,-1474(a0) # ffffffffc0207028 <free_area+0x10>
ffffffffc02005f2:	8082                	ret

ffffffffc02005f4 <best_fit_alloc_pages>:
    assert(n > 0);
ffffffffc02005f4:	cd51                	beqz	a0,ffffffffc0200690 <best_fit_alloc_pages+0x9c>
    if (n > nr_free) {
ffffffffc02005f6:	00007597          	auipc	a1,0x7
ffffffffc02005fa:	a2258593          	addi	a1,a1,-1502 # ffffffffc0207018 <free_area>
ffffffffc02005fe:	0105a883          	lw	a7,16(a1)
ffffffffc0200602:	86aa                	mv	a3,a0
ffffffffc0200604:	02089793          	slli	a5,a7,0x20
ffffffffc0200608:	9381                	srli	a5,a5,0x20
ffffffffc020060a:	08a7e163          	bltu	a5,a0,ffffffffc020068c <best_fit_alloc_pages+0x98>
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
ffffffffc020060e:	659c                	ld	a5,8(a1)
    struct Page *page = NULL;
ffffffffc0200610:	4501                	li	a0,0
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200612:	06b78c63          	beq	a5,a1,ffffffffc020068a <best_fit_alloc_pages+0x96>
        if (p->property >= n && (page == NULL || p->property < page->property)) {
ffffffffc0200616:	ff87a703          	lw	a4,-8(a5)
        struct Page *p = le2page(le, page_link);
ffffffffc020061a:	fe878813          	addi	a6,a5,-24
        if (p->property >= n && (page == NULL || p->property < page->property)) {
ffffffffc020061e:	02071613          	slli	a2,a4,0x20
ffffffffc0200622:	9201                	srli	a2,a2,0x20
ffffffffc0200624:	00d66763          	bltu	a2,a3,ffffffffc0200632 <best_fit_alloc_pages+0x3e>
ffffffffc0200628:	c501                	beqz	a0,ffffffffc0200630 <best_fit_alloc_pages+0x3c>
ffffffffc020062a:	4910                	lw	a2,16(a0)
ffffffffc020062c:	00c77363          	bgeu	a4,a2,ffffffffc0200632 <best_fit_alloc_pages+0x3e>
            page = p;
ffffffffc0200630:	8542                	mv	a0,a6
ffffffffc0200632:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200634:	feb791e3          	bne	a5,a1,ffffffffc0200616 <best_fit_alloc_pages+0x22>
    if (page != NULL) {
ffffffffc0200638:	c929                	beqz	a0,ffffffffc020068a <best_fit_alloc_pages+0x96>
        if (page->property > n) {
ffffffffc020063a:	01052803          	lw	a6,16(a0)
 * list_prev - get the previous entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_prev(list_entry_t *listelm) {
    return listelm->prev;
ffffffffc020063e:	6d18                	ld	a4,24(a0)
    __list_del(listelm->prev, listelm->next);
ffffffffc0200640:	7110                	ld	a2,32(a0)
ffffffffc0200642:	02081793          	slli	a5,a6,0x20
ffffffffc0200646:	9381                	srli	a5,a5,0x20
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
ffffffffc0200648:	e710                	sd	a2,8(a4)
    next->prev = prev;
ffffffffc020064a:	e218                	sd	a4,0(a2)
            p->property = page->property - n;
ffffffffc020064c:	0006831b          	sext.w	t1,a3
        if (page->property > n) {
ffffffffc0200650:	02f6f563          	bgeu	a3,a5,ffffffffc020067a <best_fit_alloc_pages+0x86>
            struct Page *p = page + n;
ffffffffc0200654:	00269793          	slli	a5,a3,0x2
ffffffffc0200658:	97b6                	add	a5,a5,a3
ffffffffc020065a:	078e                	slli	a5,a5,0x3
ffffffffc020065c:	97aa                	add	a5,a5,a0
            SetPageProperty(p);
ffffffffc020065e:	6794                	ld	a3,8(a5)
            p->property = page->property - n;
ffffffffc0200660:	4068083b          	subw	a6,a6,t1
ffffffffc0200664:	0107a823          	sw	a6,16(a5)
            SetPageProperty(p);
ffffffffc0200668:	0026e693          	ori	a3,a3,2
ffffffffc020066c:	e794                	sd	a3,8(a5)
            list_add(prev, &(p->page_link));
ffffffffc020066e:	01878693          	addi	a3,a5,24
    prev->next = next->prev = elm;
ffffffffc0200672:	e214                	sd	a3,0(a2)
ffffffffc0200674:	e714                	sd	a3,8(a4)
    elm->next = next;
ffffffffc0200676:	f390                	sd	a2,32(a5)
    elm->prev = prev;
ffffffffc0200678:	ef98                	sd	a4,24(a5)
        ClearPageProperty(page);
ffffffffc020067a:	651c                	ld	a5,8(a0)
        nr_free -= n;
ffffffffc020067c:	406888bb          	subw	a7,a7,t1
ffffffffc0200680:	0115a823          	sw	a7,16(a1)
        ClearPageProperty(page);
ffffffffc0200684:	9bf5                	andi	a5,a5,-3
ffffffffc0200686:	e51c                	sd	a5,8(a0)
ffffffffc0200688:	8082                	ret
}
ffffffffc020068a:	8082                	ret
        return NULL;
ffffffffc020068c:	4501                	li	a0,0
ffffffffc020068e:	8082                	ret
best_fit_alloc_pages(size_t n) {
ffffffffc0200690:	1141                	addi	sp,sp,-16
    assert(n > 0);
ffffffffc0200692:	00002697          	auipc	a3,0x2
ffffffffc0200696:	d5e68693          	addi	a3,a3,-674 # ffffffffc02023f0 <etext+0x266>
ffffffffc020069a:	00002617          	auipc	a2,0x2
ffffffffc020069e:	d5e60613          	addi	a2,a2,-674 # ffffffffc02023f8 <etext+0x26e>
ffffffffc02006a2:	03000593          	li	a1,48
ffffffffc02006a6:	00002517          	auipc	a0,0x2
ffffffffc02006aa:	d6a50513          	addi	a0,a0,-662 # ffffffffc0202410 <etext+0x286>
best_fit_alloc_pages(size_t n) {
ffffffffc02006ae:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc02006b0:	b1bff0ef          	jal	ra,ffffffffc02001ca <__panic>

ffffffffc02006b4 <best_fit_check>:
    free_page(p1);
    free_page(p2);
}

static void
best_fit_check(void) {
ffffffffc02006b4:	715d                	addi	sp,sp,-80
ffffffffc02006b6:	e0a2                	sd	s0,64(sp)
    return listelm->next;
ffffffffc02006b8:	00007417          	auipc	s0,0x7
ffffffffc02006bc:	96040413          	addi	s0,s0,-1696 # ffffffffc0207018 <free_area>
ffffffffc02006c0:	641c                	ld	a5,8(s0)
ffffffffc02006c2:	e486                	sd	ra,72(sp)
ffffffffc02006c4:	fc26                	sd	s1,56(sp)
ffffffffc02006c6:	f84a                	sd	s2,48(sp)
ffffffffc02006c8:	f44e                	sd	s3,40(sp)
ffffffffc02006ca:	f052                	sd	s4,32(sp)
ffffffffc02006cc:	ec56                	sd	s5,24(sp)
ffffffffc02006ce:	e85a                	sd	s6,16(sp)
ffffffffc02006d0:	e45e                	sd	s7,8(sp)
ffffffffc02006d2:	e062                	sd	s8,0(sp)
    int score = 0, sumscore = 6;
    int count = 0, total = 0;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc02006d4:	26878963          	beq	a5,s0,ffffffffc0200946 <best_fit_check+0x292>
    int count = 0, total = 0;
ffffffffc02006d8:	4481                	li	s1,0
ffffffffc02006da:	4901                	li	s2,0
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
ffffffffc02006dc:	ff07b703          	ld	a4,-16(a5)
ffffffffc02006e0:	8b09                	andi	a4,a4,2
ffffffffc02006e2:	26070663          	beqz	a4,ffffffffc020094e <best_fit_check+0x29a>
        count++, total += p->property;
ffffffffc02006e6:	ff87a703          	lw	a4,-8(a5)
ffffffffc02006ea:	679c                	ld	a5,8(a5)
ffffffffc02006ec:	2905                	addiw	s2,s2,1
ffffffffc02006ee:	9cb9                	addw	s1,s1,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc02006f0:	fe8796e3          	bne	a5,s0,ffffffffc02006dc <best_fit_check+0x28>
    }
    assert(total == nr_free_pages());
ffffffffc02006f4:	89a6                	mv	s3,s1
ffffffffc02006f6:	179000ef          	jal	ra,ffffffffc020106e <nr_free_pages>
ffffffffc02006fa:	33351a63          	bne	a0,s3,ffffffffc0200a2e <best_fit_check+0x37a>
    assert((p0 = alloc_page()) != NULL);
ffffffffc02006fe:	4505                	li	a0,1
ffffffffc0200700:	157000ef          	jal	ra,ffffffffc0201056 <alloc_pages>
ffffffffc0200704:	8a2a                	mv	s4,a0
ffffffffc0200706:	36050463          	beqz	a0,ffffffffc0200a6e <best_fit_check+0x3ba>
    assert((p1 = alloc_page()) != NULL);
ffffffffc020070a:	4505                	li	a0,1
ffffffffc020070c:	14b000ef          	jal	ra,ffffffffc0201056 <alloc_pages>
ffffffffc0200710:	89aa                	mv	s3,a0
ffffffffc0200712:	32050e63          	beqz	a0,ffffffffc0200a4e <best_fit_check+0x39a>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200716:	4505                	li	a0,1
ffffffffc0200718:	13f000ef          	jal	ra,ffffffffc0201056 <alloc_pages>
ffffffffc020071c:	8aaa                	mv	s5,a0
ffffffffc020071e:	2c050863          	beqz	a0,ffffffffc02009ee <best_fit_check+0x33a>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0200722:	253a0663          	beq	s4,s3,ffffffffc020096e <best_fit_check+0x2ba>
ffffffffc0200726:	24aa0463          	beq	s4,a0,ffffffffc020096e <best_fit_check+0x2ba>
ffffffffc020072a:	24a98263          	beq	s3,a0,ffffffffc020096e <best_fit_check+0x2ba>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc020072e:	000a2783          	lw	a5,0(s4)
ffffffffc0200732:	24079e63          	bnez	a5,ffffffffc020098e <best_fit_check+0x2da>
ffffffffc0200736:	0009a783          	lw	a5,0(s3)
ffffffffc020073a:	24079a63          	bnez	a5,ffffffffc020098e <best_fit_check+0x2da>
ffffffffc020073e:	411c                	lw	a5,0(a0)
ffffffffc0200740:	24079763          	bnez	a5,ffffffffc020098e <best_fit_check+0x2da>
extern struct Page *pages;
extern size_t npage;
extern const size_t nbase;
extern uint64_t va_pa_offset;

static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200744:	00007797          	auipc	a5,0x7
ffffffffc0200748:	9cc7b783          	ld	a5,-1588(a5) # ffffffffc0207110 <pages>
ffffffffc020074c:	40fa0733          	sub	a4,s4,a5
ffffffffc0200750:	870d                	srai	a4,a4,0x3
ffffffffc0200752:	00003597          	auipc	a1,0x3
ffffffffc0200756:	ca65b583          	ld	a1,-858(a1) # ffffffffc02033f8 <error_string+0x38>
ffffffffc020075a:	02b70733          	mul	a4,a4,a1
ffffffffc020075e:	00003617          	auipc	a2,0x3
ffffffffc0200762:	caa63603          	ld	a2,-854(a2) # ffffffffc0203408 <nbase>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0200766:	00007697          	auipc	a3,0x7
ffffffffc020076a:	9a26b683          	ld	a3,-1630(a3) # ffffffffc0207108 <npage>
ffffffffc020076e:	06b2                	slli	a3,a3,0xc
ffffffffc0200770:	9732                	add	a4,a4,a2

static inline uintptr_t page2pa(struct Page *page) {
    return page2ppn(page) << PGSHIFT;
ffffffffc0200772:	0732                	slli	a4,a4,0xc
ffffffffc0200774:	22d77d63          	bgeu	a4,a3,ffffffffc02009ae <best_fit_check+0x2fa>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200778:	40f98733          	sub	a4,s3,a5
ffffffffc020077c:	870d                	srai	a4,a4,0x3
ffffffffc020077e:	02b70733          	mul	a4,a4,a1
ffffffffc0200782:	9732                	add	a4,a4,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0200784:	0732                	slli	a4,a4,0xc
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0200786:	3ed77463          	bgeu	a4,a3,ffffffffc0200b6e <best_fit_check+0x4ba>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc020078a:	40f507b3          	sub	a5,a0,a5
ffffffffc020078e:	878d                	srai	a5,a5,0x3
ffffffffc0200790:	02b787b3          	mul	a5,a5,a1
ffffffffc0200794:	97b2                	add	a5,a5,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0200796:	07b2                	slli	a5,a5,0xc
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0200798:	3ad7fb63          	bgeu	a5,a3,ffffffffc0200b4e <best_fit_check+0x49a>
    assert(alloc_page() == NULL);
ffffffffc020079c:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc020079e:	00043c03          	ld	s8,0(s0)
ffffffffc02007a2:	00843b83          	ld	s7,8(s0)
    unsigned int nr_free_store = nr_free;
ffffffffc02007a6:	01042b03          	lw	s6,16(s0)
    elm->prev = elm->next = elm;
ffffffffc02007aa:	e400                	sd	s0,8(s0)
ffffffffc02007ac:	e000                	sd	s0,0(s0)
    nr_free = 0;
ffffffffc02007ae:	00007797          	auipc	a5,0x7
ffffffffc02007b2:	8607ad23          	sw	zero,-1926(a5) # ffffffffc0207028 <free_area+0x10>
    assert(alloc_page() == NULL);
ffffffffc02007b6:	0a1000ef          	jal	ra,ffffffffc0201056 <alloc_pages>
ffffffffc02007ba:	36051a63          	bnez	a0,ffffffffc0200b2e <best_fit_check+0x47a>
    free_page(p0);
ffffffffc02007be:	4585                	li	a1,1
ffffffffc02007c0:	8552                	mv	a0,s4
ffffffffc02007c2:	0a1000ef          	jal	ra,ffffffffc0201062 <free_pages>
    free_page(p1);
ffffffffc02007c6:	4585                	li	a1,1
ffffffffc02007c8:	854e                	mv	a0,s3
ffffffffc02007ca:	099000ef          	jal	ra,ffffffffc0201062 <free_pages>
    free_page(p2);
ffffffffc02007ce:	4585                	li	a1,1
ffffffffc02007d0:	8556                	mv	a0,s5
ffffffffc02007d2:	091000ef          	jal	ra,ffffffffc0201062 <free_pages>
    assert(nr_free == 3);
ffffffffc02007d6:	4818                	lw	a4,16(s0)
ffffffffc02007d8:	478d                	li	a5,3
ffffffffc02007da:	32f71a63          	bne	a4,a5,ffffffffc0200b0e <best_fit_check+0x45a>
    assert((p0 = alloc_page()) != NULL);
ffffffffc02007de:	4505                	li	a0,1
ffffffffc02007e0:	077000ef          	jal	ra,ffffffffc0201056 <alloc_pages>
ffffffffc02007e4:	89aa                	mv	s3,a0
ffffffffc02007e6:	30050463          	beqz	a0,ffffffffc0200aee <best_fit_check+0x43a>
    assert((p1 = alloc_page()) != NULL);
ffffffffc02007ea:	4505                	li	a0,1
ffffffffc02007ec:	06b000ef          	jal	ra,ffffffffc0201056 <alloc_pages>
ffffffffc02007f0:	8aaa                	mv	s5,a0
ffffffffc02007f2:	2c050e63          	beqz	a0,ffffffffc0200ace <best_fit_check+0x41a>
    assert((p2 = alloc_page()) != NULL);
ffffffffc02007f6:	4505                	li	a0,1
ffffffffc02007f8:	05f000ef          	jal	ra,ffffffffc0201056 <alloc_pages>
ffffffffc02007fc:	8a2a                	mv	s4,a0
ffffffffc02007fe:	2a050863          	beqz	a0,ffffffffc0200aae <best_fit_check+0x3fa>
    assert(alloc_page() == NULL);
ffffffffc0200802:	4505                	li	a0,1
ffffffffc0200804:	053000ef          	jal	ra,ffffffffc0201056 <alloc_pages>
ffffffffc0200808:	28051363          	bnez	a0,ffffffffc0200a8e <best_fit_check+0x3da>
    free_page(p0);
ffffffffc020080c:	4585                	li	a1,1
ffffffffc020080e:	854e                	mv	a0,s3
ffffffffc0200810:	053000ef          	jal	ra,ffffffffc0201062 <free_pages>
    assert(!list_empty(&free_list));
ffffffffc0200814:	641c                	ld	a5,8(s0)
ffffffffc0200816:	1a878c63          	beq	a5,s0,ffffffffc02009ce <best_fit_check+0x31a>
    assert((p = alloc_page()) == p0);
ffffffffc020081a:	4505                	li	a0,1
ffffffffc020081c:	03b000ef          	jal	ra,ffffffffc0201056 <alloc_pages>
ffffffffc0200820:	52a99763          	bne	s3,a0,ffffffffc0200d4e <best_fit_check+0x69a>
    assert(alloc_page() == NULL);
ffffffffc0200824:	4505                	li	a0,1
ffffffffc0200826:	031000ef          	jal	ra,ffffffffc0201056 <alloc_pages>
ffffffffc020082a:	50051263          	bnez	a0,ffffffffc0200d2e <best_fit_check+0x67a>
    assert(nr_free == 0);
ffffffffc020082e:	481c                	lw	a5,16(s0)
ffffffffc0200830:	4c079f63          	bnez	a5,ffffffffc0200d0e <best_fit_check+0x65a>
    free_page(p);
ffffffffc0200834:	854e                	mv	a0,s3
ffffffffc0200836:	4585                	li	a1,1
    free_list = free_list_store;
ffffffffc0200838:	01843023          	sd	s8,0(s0)
ffffffffc020083c:	01743423          	sd	s7,8(s0)
    nr_free = nr_free_store;
ffffffffc0200840:	01642823          	sw	s6,16(s0)
    free_page(p);
ffffffffc0200844:	01f000ef          	jal	ra,ffffffffc0201062 <free_pages>
    free_page(p1);
ffffffffc0200848:	4585                	li	a1,1
ffffffffc020084a:	8556                	mv	a0,s5
ffffffffc020084c:	017000ef          	jal	ra,ffffffffc0201062 <free_pages>
    free_page(p2);
ffffffffc0200850:	4585                	li	a1,1
ffffffffc0200852:	8552                	mv	a0,s4
ffffffffc0200854:	00f000ef          	jal	ra,ffffffffc0201062 <free_pages>

    #ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n", score, sumscore);
    #endif
    struct Page *p0 = alloc_pages(5), *p1, *p2;
ffffffffc0200858:	4515                	li	a0,5
ffffffffc020085a:	7fc000ef          	jal	ra,ffffffffc0201056 <alloc_pages>
ffffffffc020085e:	89aa                	mv	s3,a0
    assert(p0 != NULL);
ffffffffc0200860:	48050763          	beqz	a0,ffffffffc0200cee <best_fit_check+0x63a>
    assert(!PageProperty(p0));
ffffffffc0200864:	651c                	ld	a5,8(a0)
ffffffffc0200866:	8b89                	andi	a5,a5,2
ffffffffc0200868:	46079363          	bnez	a5,ffffffffc0200cce <best_fit_check+0x61a>
    cprintf("grading: %d / %d points\n", score, sumscore);
    #endif
    list_entry_t free_list_store = free_list;
    list_init(&free_list);
    assert(list_empty(&free_list));
    assert(alloc_page() == NULL);
ffffffffc020086c:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc020086e:	00043b03          	ld	s6,0(s0)
ffffffffc0200872:	00843a83          	ld	s5,8(s0)
ffffffffc0200876:	e000                	sd	s0,0(s0)
ffffffffc0200878:	e400                	sd	s0,8(s0)
    assert(alloc_page() == NULL);
ffffffffc020087a:	7dc000ef          	jal	ra,ffffffffc0201056 <alloc_pages>
ffffffffc020087e:	42051863          	bnez	a0,ffffffffc0200cae <best_fit_check+0x5fa>
    #endif
    unsigned int nr_free_store = nr_free;
    nr_free = 0;

    // * - - * -
    free_pages(p0 + 1, 2);
ffffffffc0200882:	4589                	li	a1,2
ffffffffc0200884:	02898513          	addi	a0,s3,40
    unsigned int nr_free_store = nr_free;
ffffffffc0200888:	01042b83          	lw	s7,16(s0)
    free_pages(p0 + 4, 1);
ffffffffc020088c:	0a098c13          	addi	s8,s3,160
    nr_free = 0;
ffffffffc0200890:	00006797          	auipc	a5,0x6
ffffffffc0200894:	7807ac23          	sw	zero,1944(a5) # ffffffffc0207028 <free_area+0x10>
    free_pages(p0 + 1, 2);
ffffffffc0200898:	7ca000ef          	jal	ra,ffffffffc0201062 <free_pages>
    free_pages(p0 + 4, 1);
ffffffffc020089c:	8562                	mv	a0,s8
ffffffffc020089e:	4585                	li	a1,1
ffffffffc02008a0:	7c2000ef          	jal	ra,ffffffffc0201062 <free_pages>
    assert(alloc_pages(4) == NULL);
ffffffffc02008a4:	4511                	li	a0,4
ffffffffc02008a6:	7b0000ef          	jal	ra,ffffffffc0201056 <alloc_pages>
ffffffffc02008aa:	3e051263          	bnez	a0,ffffffffc0200c8e <best_fit_check+0x5da>
    assert(PageProperty(p0 + 1) && p0[1].property == 2);
ffffffffc02008ae:	0309b783          	ld	a5,48(s3)
ffffffffc02008b2:	8b89                	andi	a5,a5,2
ffffffffc02008b4:	3a078d63          	beqz	a5,ffffffffc0200c6e <best_fit_check+0x5ba>
ffffffffc02008b8:	0389a703          	lw	a4,56(s3)
ffffffffc02008bc:	4789                	li	a5,2
ffffffffc02008be:	3af71863          	bne	a4,a5,ffffffffc0200c6e <best_fit_check+0x5ba>
    // * - - * *
    assert((p1 = alloc_pages(1)) != NULL);
ffffffffc02008c2:	4505                	li	a0,1
ffffffffc02008c4:	792000ef          	jal	ra,ffffffffc0201056 <alloc_pages>
ffffffffc02008c8:	8a2a                	mv	s4,a0
ffffffffc02008ca:	38050263          	beqz	a0,ffffffffc0200c4e <best_fit_check+0x59a>
    assert(alloc_pages(2) != NULL);
ffffffffc02008ce:	4509                	li	a0,2
ffffffffc02008d0:	786000ef          	jal	ra,ffffffffc0201056 <alloc_pages>
ffffffffc02008d4:	34050d63          	beqz	a0,ffffffffc0200c2e <best_fit_check+0x57a>
    assert(p0 + 4 == p1);
ffffffffc02008d8:	334c1b63          	bne	s8,s4,ffffffffc0200c0e <best_fit_check+0x55a>
    #ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n", score, sumscore);
    #endif
    p2 = p0 + 1;
    free_pages(p0, 5);
ffffffffc02008dc:	854e                	mv	a0,s3
ffffffffc02008de:	4595                	li	a1,5
ffffffffc02008e0:	782000ef          	jal	ra,ffffffffc0201062 <free_pages>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc02008e4:	4515                	li	a0,5
ffffffffc02008e6:	770000ef          	jal	ra,ffffffffc0201056 <alloc_pages>
ffffffffc02008ea:	89aa                	mv	s3,a0
ffffffffc02008ec:	30050163          	beqz	a0,ffffffffc0200bee <best_fit_check+0x53a>
    assert(alloc_page() == NULL);
ffffffffc02008f0:	4505                	li	a0,1
ffffffffc02008f2:	764000ef          	jal	ra,ffffffffc0201056 <alloc_pages>
ffffffffc02008f6:	2c051c63          	bnez	a0,ffffffffc0200bce <best_fit_check+0x51a>

    #ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n", score, sumscore);
    #endif
    assert(nr_free == 0);
ffffffffc02008fa:	481c                	lw	a5,16(s0)
ffffffffc02008fc:	2a079963          	bnez	a5,ffffffffc0200bae <best_fit_check+0x4fa>
    nr_free = nr_free_store;

    free_list = free_list_store;
    free_pages(p0, 5);
ffffffffc0200900:	4595                	li	a1,5
ffffffffc0200902:	854e                	mv	a0,s3
    nr_free = nr_free_store;
ffffffffc0200904:	01742823          	sw	s7,16(s0)
    free_list = free_list_store;
ffffffffc0200908:	01643023          	sd	s6,0(s0)
ffffffffc020090c:	01543423          	sd	s5,8(s0)
    free_pages(p0, 5);
ffffffffc0200910:	752000ef          	jal	ra,ffffffffc0201062 <free_pages>
    return listelm->next;
ffffffffc0200914:	641c                	ld	a5,8(s0)

    le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200916:	00878963          	beq	a5,s0,ffffffffc0200928 <best_fit_check+0x274>
        struct Page *p = le2page(le, page_link);
        count--, total -= p->property;
ffffffffc020091a:	ff87a703          	lw	a4,-8(a5)
ffffffffc020091e:	679c                	ld	a5,8(a5)
ffffffffc0200920:	397d                	addiw	s2,s2,-1
ffffffffc0200922:	9c99                	subw	s1,s1,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200924:	fe879be3          	bne	a5,s0,ffffffffc020091a <best_fit_check+0x266>
    }
    assert(count == 0);
ffffffffc0200928:	26091363          	bnez	s2,ffffffffc0200b8e <best_fit_check+0x4da>
    assert(total == 0);
ffffffffc020092c:	e0ed                	bnez	s1,ffffffffc0200a0e <best_fit_check+0x35a>
    #ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n", score, sumscore);
    #endif
}
ffffffffc020092e:	60a6                	ld	ra,72(sp)
ffffffffc0200930:	6406                	ld	s0,64(sp)
ffffffffc0200932:	74e2                	ld	s1,56(sp)
ffffffffc0200934:	7942                	ld	s2,48(sp)
ffffffffc0200936:	79a2                	ld	s3,40(sp)
ffffffffc0200938:	7a02                	ld	s4,32(sp)
ffffffffc020093a:	6ae2                	ld	s5,24(sp)
ffffffffc020093c:	6b42                	ld	s6,16(sp)
ffffffffc020093e:	6ba2                	ld	s7,8(sp)
ffffffffc0200940:	6c02                	ld	s8,0(sp)
ffffffffc0200942:	6161                	addi	sp,sp,80
ffffffffc0200944:	8082                	ret
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200946:	4981                	li	s3,0
    int count = 0, total = 0;
ffffffffc0200948:	4481                	li	s1,0
ffffffffc020094a:	4901                	li	s2,0
ffffffffc020094c:	b36d                	j	ffffffffc02006f6 <best_fit_check+0x42>
        assert(PageProperty(p));
ffffffffc020094e:	00002697          	auipc	a3,0x2
ffffffffc0200952:	ada68693          	addi	a3,a3,-1318 # ffffffffc0202428 <etext+0x29e>
ffffffffc0200956:	00002617          	auipc	a2,0x2
ffffffffc020095a:	aa260613          	addi	a2,a2,-1374 # ffffffffc02023f8 <etext+0x26e>
ffffffffc020095e:	0bf00593          	li	a1,191
ffffffffc0200962:	00002517          	auipc	a0,0x2
ffffffffc0200966:	aae50513          	addi	a0,a0,-1362 # ffffffffc0202410 <etext+0x286>
ffffffffc020096a:	861ff0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc020096e:	00002697          	auipc	a3,0x2
ffffffffc0200972:	b4a68693          	addi	a3,a3,-1206 # ffffffffc02024b8 <etext+0x32e>
ffffffffc0200976:	00002617          	auipc	a2,0x2
ffffffffc020097a:	a8260613          	addi	a2,a2,-1406 # ffffffffc02023f8 <etext+0x26e>
ffffffffc020097e:	08d00593          	li	a1,141
ffffffffc0200982:	00002517          	auipc	a0,0x2
ffffffffc0200986:	a8e50513          	addi	a0,a0,-1394 # ffffffffc0202410 <etext+0x286>
ffffffffc020098a:	841ff0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc020098e:	00002697          	auipc	a3,0x2
ffffffffc0200992:	b5268693          	addi	a3,a3,-1198 # ffffffffc02024e0 <etext+0x356>
ffffffffc0200996:	00002617          	auipc	a2,0x2
ffffffffc020099a:	a6260613          	addi	a2,a2,-1438 # ffffffffc02023f8 <etext+0x26e>
ffffffffc020099e:	08e00593          	li	a1,142
ffffffffc02009a2:	00002517          	auipc	a0,0x2
ffffffffc02009a6:	a6e50513          	addi	a0,a0,-1426 # ffffffffc0202410 <etext+0x286>
ffffffffc02009aa:	821ff0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc02009ae:	00002697          	auipc	a3,0x2
ffffffffc02009b2:	b7268693          	addi	a3,a3,-1166 # ffffffffc0202520 <etext+0x396>
ffffffffc02009b6:	00002617          	auipc	a2,0x2
ffffffffc02009ba:	a4260613          	addi	a2,a2,-1470 # ffffffffc02023f8 <etext+0x26e>
ffffffffc02009be:	09000593          	li	a1,144
ffffffffc02009c2:	00002517          	auipc	a0,0x2
ffffffffc02009c6:	a4e50513          	addi	a0,a0,-1458 # ffffffffc0202410 <etext+0x286>
ffffffffc02009ca:	801ff0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert(!list_empty(&free_list));
ffffffffc02009ce:	00002697          	auipc	a3,0x2
ffffffffc02009d2:	bda68693          	addi	a3,a3,-1062 # ffffffffc02025a8 <etext+0x41e>
ffffffffc02009d6:	00002617          	auipc	a2,0x2
ffffffffc02009da:	a2260613          	addi	a2,a2,-1502 # ffffffffc02023f8 <etext+0x26e>
ffffffffc02009de:	0a900593          	li	a1,169
ffffffffc02009e2:	00002517          	auipc	a0,0x2
ffffffffc02009e6:	a2e50513          	addi	a0,a0,-1490 # ffffffffc0202410 <etext+0x286>
ffffffffc02009ea:	fe0ff0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc02009ee:	00002697          	auipc	a3,0x2
ffffffffc02009f2:	aaa68693          	addi	a3,a3,-1366 # ffffffffc0202498 <etext+0x30e>
ffffffffc02009f6:	00002617          	auipc	a2,0x2
ffffffffc02009fa:	a0260613          	addi	a2,a2,-1534 # ffffffffc02023f8 <etext+0x26e>
ffffffffc02009fe:	08b00593          	li	a1,139
ffffffffc0200a02:	00002517          	auipc	a0,0x2
ffffffffc0200a06:	a0e50513          	addi	a0,a0,-1522 # ffffffffc0202410 <etext+0x286>
ffffffffc0200a0a:	fc0ff0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert(total == 0);
ffffffffc0200a0e:	00002697          	auipc	a3,0x2
ffffffffc0200a12:	cca68693          	addi	a3,a3,-822 # ffffffffc02026d8 <etext+0x54e>
ffffffffc0200a16:	00002617          	auipc	a2,0x2
ffffffffc0200a1a:	9e260613          	addi	a2,a2,-1566 # ffffffffc02023f8 <etext+0x26e>
ffffffffc0200a1e:	10100593          	li	a1,257
ffffffffc0200a22:	00002517          	auipc	a0,0x2
ffffffffc0200a26:	9ee50513          	addi	a0,a0,-1554 # ffffffffc0202410 <etext+0x286>
ffffffffc0200a2a:	fa0ff0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert(total == nr_free_pages());
ffffffffc0200a2e:	00002697          	auipc	a3,0x2
ffffffffc0200a32:	a0a68693          	addi	a3,a3,-1526 # ffffffffc0202438 <etext+0x2ae>
ffffffffc0200a36:	00002617          	auipc	a2,0x2
ffffffffc0200a3a:	9c260613          	addi	a2,a2,-1598 # ffffffffc02023f8 <etext+0x26e>
ffffffffc0200a3e:	0c200593          	li	a1,194
ffffffffc0200a42:	00002517          	auipc	a0,0x2
ffffffffc0200a46:	9ce50513          	addi	a0,a0,-1586 # ffffffffc0202410 <etext+0x286>
ffffffffc0200a4a:	f80ff0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200a4e:	00002697          	auipc	a3,0x2
ffffffffc0200a52:	a2a68693          	addi	a3,a3,-1494 # ffffffffc0202478 <etext+0x2ee>
ffffffffc0200a56:	00002617          	auipc	a2,0x2
ffffffffc0200a5a:	9a260613          	addi	a2,a2,-1630 # ffffffffc02023f8 <etext+0x26e>
ffffffffc0200a5e:	08a00593          	li	a1,138
ffffffffc0200a62:	00002517          	auipc	a0,0x2
ffffffffc0200a66:	9ae50513          	addi	a0,a0,-1618 # ffffffffc0202410 <etext+0x286>
ffffffffc0200a6a:	f60ff0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200a6e:	00002697          	auipc	a3,0x2
ffffffffc0200a72:	9ea68693          	addi	a3,a3,-1558 # ffffffffc0202458 <etext+0x2ce>
ffffffffc0200a76:	00002617          	auipc	a2,0x2
ffffffffc0200a7a:	98260613          	addi	a2,a2,-1662 # ffffffffc02023f8 <etext+0x26e>
ffffffffc0200a7e:	08900593          	li	a1,137
ffffffffc0200a82:	00002517          	auipc	a0,0x2
ffffffffc0200a86:	98e50513          	addi	a0,a0,-1650 # ffffffffc0202410 <etext+0x286>
ffffffffc0200a8a:	f40ff0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert(alloc_page() == NULL);
ffffffffc0200a8e:	00002697          	auipc	a3,0x2
ffffffffc0200a92:	af268693          	addi	a3,a3,-1294 # ffffffffc0202580 <etext+0x3f6>
ffffffffc0200a96:	00002617          	auipc	a2,0x2
ffffffffc0200a9a:	96260613          	addi	a2,a2,-1694 # ffffffffc02023f8 <etext+0x26e>
ffffffffc0200a9e:	0a600593          	li	a1,166
ffffffffc0200aa2:	00002517          	auipc	a0,0x2
ffffffffc0200aa6:	96e50513          	addi	a0,a0,-1682 # ffffffffc0202410 <etext+0x286>
ffffffffc0200aaa:	f20ff0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200aae:	00002697          	auipc	a3,0x2
ffffffffc0200ab2:	9ea68693          	addi	a3,a3,-1558 # ffffffffc0202498 <etext+0x30e>
ffffffffc0200ab6:	00002617          	auipc	a2,0x2
ffffffffc0200aba:	94260613          	addi	a2,a2,-1726 # ffffffffc02023f8 <etext+0x26e>
ffffffffc0200abe:	0a400593          	li	a1,164
ffffffffc0200ac2:	00002517          	auipc	a0,0x2
ffffffffc0200ac6:	94e50513          	addi	a0,a0,-1714 # ffffffffc0202410 <etext+0x286>
ffffffffc0200aca:	f00ff0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200ace:	00002697          	auipc	a3,0x2
ffffffffc0200ad2:	9aa68693          	addi	a3,a3,-1622 # ffffffffc0202478 <etext+0x2ee>
ffffffffc0200ad6:	00002617          	auipc	a2,0x2
ffffffffc0200ada:	92260613          	addi	a2,a2,-1758 # ffffffffc02023f8 <etext+0x26e>
ffffffffc0200ade:	0a300593          	li	a1,163
ffffffffc0200ae2:	00002517          	auipc	a0,0x2
ffffffffc0200ae6:	92e50513          	addi	a0,a0,-1746 # ffffffffc0202410 <etext+0x286>
ffffffffc0200aea:	ee0ff0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200aee:	00002697          	auipc	a3,0x2
ffffffffc0200af2:	96a68693          	addi	a3,a3,-1686 # ffffffffc0202458 <etext+0x2ce>
ffffffffc0200af6:	00002617          	auipc	a2,0x2
ffffffffc0200afa:	90260613          	addi	a2,a2,-1790 # ffffffffc02023f8 <etext+0x26e>
ffffffffc0200afe:	0a200593          	li	a1,162
ffffffffc0200b02:	00002517          	auipc	a0,0x2
ffffffffc0200b06:	90e50513          	addi	a0,a0,-1778 # ffffffffc0202410 <etext+0x286>
ffffffffc0200b0a:	ec0ff0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert(nr_free == 3);
ffffffffc0200b0e:	00002697          	auipc	a3,0x2
ffffffffc0200b12:	a8a68693          	addi	a3,a3,-1398 # ffffffffc0202598 <etext+0x40e>
ffffffffc0200b16:	00002617          	auipc	a2,0x2
ffffffffc0200b1a:	8e260613          	addi	a2,a2,-1822 # ffffffffc02023f8 <etext+0x26e>
ffffffffc0200b1e:	0a000593          	li	a1,160
ffffffffc0200b22:	00002517          	auipc	a0,0x2
ffffffffc0200b26:	8ee50513          	addi	a0,a0,-1810 # ffffffffc0202410 <etext+0x286>
ffffffffc0200b2a:	ea0ff0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert(alloc_page() == NULL);
ffffffffc0200b2e:	00002697          	auipc	a3,0x2
ffffffffc0200b32:	a5268693          	addi	a3,a3,-1454 # ffffffffc0202580 <etext+0x3f6>
ffffffffc0200b36:	00002617          	auipc	a2,0x2
ffffffffc0200b3a:	8c260613          	addi	a2,a2,-1854 # ffffffffc02023f8 <etext+0x26e>
ffffffffc0200b3e:	09b00593          	li	a1,155
ffffffffc0200b42:	00002517          	auipc	a0,0x2
ffffffffc0200b46:	8ce50513          	addi	a0,a0,-1842 # ffffffffc0202410 <etext+0x286>
ffffffffc0200b4a:	e80ff0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0200b4e:	00002697          	auipc	a3,0x2
ffffffffc0200b52:	a1268693          	addi	a3,a3,-1518 # ffffffffc0202560 <etext+0x3d6>
ffffffffc0200b56:	00002617          	auipc	a2,0x2
ffffffffc0200b5a:	8a260613          	addi	a2,a2,-1886 # ffffffffc02023f8 <etext+0x26e>
ffffffffc0200b5e:	09200593          	li	a1,146
ffffffffc0200b62:	00002517          	auipc	a0,0x2
ffffffffc0200b66:	8ae50513          	addi	a0,a0,-1874 # ffffffffc0202410 <etext+0x286>
ffffffffc0200b6a:	e60ff0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0200b6e:	00002697          	auipc	a3,0x2
ffffffffc0200b72:	9d268693          	addi	a3,a3,-1582 # ffffffffc0202540 <etext+0x3b6>
ffffffffc0200b76:	00002617          	auipc	a2,0x2
ffffffffc0200b7a:	88260613          	addi	a2,a2,-1918 # ffffffffc02023f8 <etext+0x26e>
ffffffffc0200b7e:	09100593          	li	a1,145
ffffffffc0200b82:	00002517          	auipc	a0,0x2
ffffffffc0200b86:	88e50513          	addi	a0,a0,-1906 # ffffffffc0202410 <etext+0x286>
ffffffffc0200b8a:	e40ff0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert(count == 0);
ffffffffc0200b8e:	00002697          	auipc	a3,0x2
ffffffffc0200b92:	b3a68693          	addi	a3,a3,-1222 # ffffffffc02026c8 <etext+0x53e>
ffffffffc0200b96:	00002617          	auipc	a2,0x2
ffffffffc0200b9a:	86260613          	addi	a2,a2,-1950 # ffffffffc02023f8 <etext+0x26e>
ffffffffc0200b9e:	10000593          	li	a1,256
ffffffffc0200ba2:	00002517          	auipc	a0,0x2
ffffffffc0200ba6:	86e50513          	addi	a0,a0,-1938 # ffffffffc0202410 <etext+0x286>
ffffffffc0200baa:	e20ff0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert(nr_free == 0);
ffffffffc0200bae:	00002697          	auipc	a3,0x2
ffffffffc0200bb2:	a3268693          	addi	a3,a3,-1486 # ffffffffc02025e0 <etext+0x456>
ffffffffc0200bb6:	00002617          	auipc	a2,0x2
ffffffffc0200bba:	84260613          	addi	a2,a2,-1982 # ffffffffc02023f8 <etext+0x26e>
ffffffffc0200bbe:	0f500593          	li	a1,245
ffffffffc0200bc2:	00002517          	auipc	a0,0x2
ffffffffc0200bc6:	84e50513          	addi	a0,a0,-1970 # ffffffffc0202410 <etext+0x286>
ffffffffc0200bca:	e00ff0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert(alloc_page() == NULL);
ffffffffc0200bce:	00002697          	auipc	a3,0x2
ffffffffc0200bd2:	9b268693          	addi	a3,a3,-1614 # ffffffffc0202580 <etext+0x3f6>
ffffffffc0200bd6:	00002617          	auipc	a2,0x2
ffffffffc0200bda:	82260613          	addi	a2,a2,-2014 # ffffffffc02023f8 <etext+0x26e>
ffffffffc0200bde:	0ef00593          	li	a1,239
ffffffffc0200be2:	00002517          	auipc	a0,0x2
ffffffffc0200be6:	82e50513          	addi	a0,a0,-2002 # ffffffffc0202410 <etext+0x286>
ffffffffc0200bea:	de0ff0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc0200bee:	00002697          	auipc	a3,0x2
ffffffffc0200bf2:	aba68693          	addi	a3,a3,-1350 # ffffffffc02026a8 <etext+0x51e>
ffffffffc0200bf6:	00002617          	auipc	a2,0x2
ffffffffc0200bfa:	80260613          	addi	a2,a2,-2046 # ffffffffc02023f8 <etext+0x26e>
ffffffffc0200bfe:	0ee00593          	li	a1,238
ffffffffc0200c02:	00002517          	auipc	a0,0x2
ffffffffc0200c06:	80e50513          	addi	a0,a0,-2034 # ffffffffc0202410 <etext+0x286>
ffffffffc0200c0a:	dc0ff0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert(p0 + 4 == p1);
ffffffffc0200c0e:	00002697          	auipc	a3,0x2
ffffffffc0200c12:	a8a68693          	addi	a3,a3,-1398 # ffffffffc0202698 <etext+0x50e>
ffffffffc0200c16:	00001617          	auipc	a2,0x1
ffffffffc0200c1a:	7e260613          	addi	a2,a2,2018 # ffffffffc02023f8 <etext+0x26e>
ffffffffc0200c1e:	0e600593          	li	a1,230
ffffffffc0200c22:	00001517          	auipc	a0,0x1
ffffffffc0200c26:	7ee50513          	addi	a0,a0,2030 # ffffffffc0202410 <etext+0x286>
ffffffffc0200c2a:	da0ff0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert(alloc_pages(2) != NULL);
ffffffffc0200c2e:	00002697          	auipc	a3,0x2
ffffffffc0200c32:	a5268693          	addi	a3,a3,-1454 # ffffffffc0202680 <etext+0x4f6>
ffffffffc0200c36:	00001617          	auipc	a2,0x1
ffffffffc0200c3a:	7c260613          	addi	a2,a2,1986 # ffffffffc02023f8 <etext+0x26e>
ffffffffc0200c3e:	0e500593          	li	a1,229
ffffffffc0200c42:	00001517          	auipc	a0,0x1
ffffffffc0200c46:	7ce50513          	addi	a0,a0,1998 # ffffffffc0202410 <etext+0x286>
ffffffffc0200c4a:	d80ff0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert((p1 = alloc_pages(1)) != NULL);
ffffffffc0200c4e:	00002697          	auipc	a3,0x2
ffffffffc0200c52:	a1268693          	addi	a3,a3,-1518 # ffffffffc0202660 <etext+0x4d6>
ffffffffc0200c56:	00001617          	auipc	a2,0x1
ffffffffc0200c5a:	7a260613          	addi	a2,a2,1954 # ffffffffc02023f8 <etext+0x26e>
ffffffffc0200c5e:	0e400593          	li	a1,228
ffffffffc0200c62:	00001517          	auipc	a0,0x1
ffffffffc0200c66:	7ae50513          	addi	a0,a0,1966 # ffffffffc0202410 <etext+0x286>
ffffffffc0200c6a:	d60ff0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert(PageProperty(p0 + 1) && p0[1].property == 2);
ffffffffc0200c6e:	00002697          	auipc	a3,0x2
ffffffffc0200c72:	9c268693          	addi	a3,a3,-1598 # ffffffffc0202630 <etext+0x4a6>
ffffffffc0200c76:	00001617          	auipc	a2,0x1
ffffffffc0200c7a:	78260613          	addi	a2,a2,1922 # ffffffffc02023f8 <etext+0x26e>
ffffffffc0200c7e:	0e200593          	li	a1,226
ffffffffc0200c82:	00001517          	auipc	a0,0x1
ffffffffc0200c86:	78e50513          	addi	a0,a0,1934 # ffffffffc0202410 <etext+0x286>
ffffffffc0200c8a:	d40ff0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert(alloc_pages(4) == NULL);
ffffffffc0200c8e:	00002697          	auipc	a3,0x2
ffffffffc0200c92:	98a68693          	addi	a3,a3,-1654 # ffffffffc0202618 <etext+0x48e>
ffffffffc0200c96:	00001617          	auipc	a2,0x1
ffffffffc0200c9a:	76260613          	addi	a2,a2,1890 # ffffffffc02023f8 <etext+0x26e>
ffffffffc0200c9e:	0e100593          	li	a1,225
ffffffffc0200ca2:	00001517          	auipc	a0,0x1
ffffffffc0200ca6:	76e50513          	addi	a0,a0,1902 # ffffffffc0202410 <etext+0x286>
ffffffffc0200caa:	d20ff0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert(alloc_page() == NULL);
ffffffffc0200cae:	00002697          	auipc	a3,0x2
ffffffffc0200cb2:	8d268693          	addi	a3,a3,-1838 # ffffffffc0202580 <etext+0x3f6>
ffffffffc0200cb6:	00001617          	auipc	a2,0x1
ffffffffc0200cba:	74260613          	addi	a2,a2,1858 # ffffffffc02023f8 <etext+0x26e>
ffffffffc0200cbe:	0d500593          	li	a1,213
ffffffffc0200cc2:	00001517          	auipc	a0,0x1
ffffffffc0200cc6:	74e50513          	addi	a0,a0,1870 # ffffffffc0202410 <etext+0x286>
ffffffffc0200cca:	d00ff0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert(!PageProperty(p0));
ffffffffc0200cce:	00002697          	auipc	a3,0x2
ffffffffc0200cd2:	93268693          	addi	a3,a3,-1742 # ffffffffc0202600 <etext+0x476>
ffffffffc0200cd6:	00001617          	auipc	a2,0x1
ffffffffc0200cda:	72260613          	addi	a2,a2,1826 # ffffffffc02023f8 <etext+0x26e>
ffffffffc0200cde:	0cc00593          	li	a1,204
ffffffffc0200ce2:	00001517          	auipc	a0,0x1
ffffffffc0200ce6:	72e50513          	addi	a0,a0,1838 # ffffffffc0202410 <etext+0x286>
ffffffffc0200cea:	ce0ff0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert(p0 != NULL);
ffffffffc0200cee:	00002697          	auipc	a3,0x2
ffffffffc0200cf2:	90268693          	addi	a3,a3,-1790 # ffffffffc02025f0 <etext+0x466>
ffffffffc0200cf6:	00001617          	auipc	a2,0x1
ffffffffc0200cfa:	70260613          	addi	a2,a2,1794 # ffffffffc02023f8 <etext+0x26e>
ffffffffc0200cfe:	0cb00593          	li	a1,203
ffffffffc0200d02:	00001517          	auipc	a0,0x1
ffffffffc0200d06:	70e50513          	addi	a0,a0,1806 # ffffffffc0202410 <etext+0x286>
ffffffffc0200d0a:	cc0ff0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert(nr_free == 0);
ffffffffc0200d0e:	00002697          	auipc	a3,0x2
ffffffffc0200d12:	8d268693          	addi	a3,a3,-1838 # ffffffffc02025e0 <etext+0x456>
ffffffffc0200d16:	00001617          	auipc	a2,0x1
ffffffffc0200d1a:	6e260613          	addi	a2,a2,1762 # ffffffffc02023f8 <etext+0x26e>
ffffffffc0200d1e:	0af00593          	li	a1,175
ffffffffc0200d22:	00001517          	auipc	a0,0x1
ffffffffc0200d26:	6ee50513          	addi	a0,a0,1774 # ffffffffc0202410 <etext+0x286>
ffffffffc0200d2a:	ca0ff0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert(alloc_page() == NULL);
ffffffffc0200d2e:	00002697          	auipc	a3,0x2
ffffffffc0200d32:	85268693          	addi	a3,a3,-1966 # ffffffffc0202580 <etext+0x3f6>
ffffffffc0200d36:	00001617          	auipc	a2,0x1
ffffffffc0200d3a:	6c260613          	addi	a2,a2,1730 # ffffffffc02023f8 <etext+0x26e>
ffffffffc0200d3e:	0ad00593          	li	a1,173
ffffffffc0200d42:	00001517          	auipc	a0,0x1
ffffffffc0200d46:	6ce50513          	addi	a0,a0,1742 # ffffffffc0202410 <etext+0x286>
ffffffffc0200d4a:	c80ff0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert((p = alloc_page()) == p0);
ffffffffc0200d4e:	00002697          	auipc	a3,0x2
ffffffffc0200d52:	87268693          	addi	a3,a3,-1934 # ffffffffc02025c0 <etext+0x436>
ffffffffc0200d56:	00001617          	auipc	a2,0x1
ffffffffc0200d5a:	6a260613          	addi	a2,a2,1698 # ffffffffc02023f8 <etext+0x26e>
ffffffffc0200d5e:	0ac00593          	li	a1,172
ffffffffc0200d62:	00001517          	auipc	a0,0x1
ffffffffc0200d66:	6ae50513          	addi	a0,a0,1710 # ffffffffc0202410 <etext+0x286>
ffffffffc0200d6a:	c60ff0ef          	jal	ra,ffffffffc02001ca <__panic>

ffffffffc0200d6e <best_fit_free_pages>:
best_fit_free_pages(struct Page *base, size_t n) {
ffffffffc0200d6e:	1141                	addi	sp,sp,-16
ffffffffc0200d70:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0200d72:	14058c63          	beqz	a1,ffffffffc0200eca <best_fit_free_pages+0x15c>
    for (; p != base + n; p ++) {
ffffffffc0200d76:	00259693          	slli	a3,a1,0x2
ffffffffc0200d7a:	96ae                	add	a3,a3,a1
ffffffffc0200d7c:	068e                	slli	a3,a3,0x3
ffffffffc0200d7e:	96aa                	add	a3,a3,a0
ffffffffc0200d80:	87aa                	mv	a5,a0
ffffffffc0200d82:	00d50e63          	beq	a0,a3,ffffffffc0200d9e <best_fit_free_pages+0x30>
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc0200d86:	6798                	ld	a4,8(a5)
ffffffffc0200d88:	8b0d                	andi	a4,a4,3
ffffffffc0200d8a:	12071063          	bnez	a4,ffffffffc0200eaa <best_fit_free_pages+0x13c>
        p->flags = 0;
ffffffffc0200d8e:	0007b423          	sd	zero,8(a5)



static inline int page_ref(struct Page *page) { return page->ref; }

static inline void set_page_ref(struct Page *page, int val) { page->ref = val; }
ffffffffc0200d92:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc0200d96:	02878793          	addi	a5,a5,40
ffffffffc0200d9a:	fed796e3          	bne	a5,a3,ffffffffc0200d86 <best_fit_free_pages+0x18>
    SetPageProperty(base);
ffffffffc0200d9e:	00853883          	ld	a7,8(a0)
    nr_free += n;
ffffffffc0200da2:	00006697          	auipc	a3,0x6
ffffffffc0200da6:	27668693          	addi	a3,a3,630 # ffffffffc0207018 <free_area>
ffffffffc0200daa:	4a98                	lw	a4,16(a3)
    base->property = n;
ffffffffc0200dac:	2581                	sext.w	a1,a1
    SetPageProperty(base);
ffffffffc0200dae:	0028e613          	ori	a2,a7,2
    return list->next == list;
ffffffffc0200db2:	669c                	ld	a5,8(a3)
    base->property = n;
ffffffffc0200db4:	c90c                	sw	a1,16(a0)
    SetPageProperty(base);
ffffffffc0200db6:	e510                	sd	a2,8(a0)
    nr_free += n;
ffffffffc0200db8:	9f2d                	addw	a4,a4,a1
ffffffffc0200dba:	ca98                	sw	a4,16(a3)
        list_add(&free_list, &(base->page_link));
ffffffffc0200dbc:	01850613          	addi	a2,a0,24
    if (list_empty(&free_list)) {
ffffffffc0200dc0:	0ad78b63          	beq	a5,a3,ffffffffc0200e76 <best_fit_free_pages+0x108>
            struct Page *page = le2page(le, page_link);
ffffffffc0200dc4:	fe878713          	addi	a4,a5,-24
ffffffffc0200dc8:	0006b303          	ld	t1,0(a3)
    if (list_empty(&free_list)) {
ffffffffc0200dcc:	4801                	li	a6,0
            if (base < page) {
ffffffffc0200dce:	00e56a63          	bltu	a0,a4,ffffffffc0200de2 <best_fit_free_pages+0x74>
    return listelm->next;
ffffffffc0200dd2:	6798                	ld	a4,8(a5)
            } else if (list_next(le) == &free_list) {
ffffffffc0200dd4:	06d70563          	beq	a4,a3,ffffffffc0200e3e <best_fit_free_pages+0xd0>
    for (; p != base + n; p ++) {
ffffffffc0200dd8:	87ba                	mv	a5,a4
            struct Page *page = le2page(le, page_link);
ffffffffc0200dda:	fe878713          	addi	a4,a5,-24
            if (base < page) {
ffffffffc0200dde:	fee57ae3          	bgeu	a0,a4,ffffffffc0200dd2 <best_fit_free_pages+0x64>
ffffffffc0200de2:	00080463          	beqz	a6,ffffffffc0200dea <best_fit_free_pages+0x7c>
ffffffffc0200de6:	0066b023          	sd	t1,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc0200dea:	0007b803          	ld	a6,0(a5)
    prev->next = next->prev = elm;
ffffffffc0200dee:	e390                	sd	a2,0(a5)
ffffffffc0200df0:	00c83423          	sd	a2,8(a6)
    elm->next = next;
ffffffffc0200df4:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0200df6:	01053c23          	sd	a6,24(a0)
    if (le != &free_list) {
ffffffffc0200dfa:	02d80463          	beq	a6,a3,ffffffffc0200e22 <best_fit_free_pages+0xb4>
        if (p + p->property == base) {
ffffffffc0200dfe:	ff882e03          	lw	t3,-8(a6)
        p = le2page(le, page_link);
ffffffffc0200e02:	fe880313          	addi	t1,a6,-24
        if (p + p->property == base) {
ffffffffc0200e06:	020e1613          	slli	a2,t3,0x20
ffffffffc0200e0a:	9201                	srli	a2,a2,0x20
ffffffffc0200e0c:	00261713          	slli	a4,a2,0x2
ffffffffc0200e10:	9732                	add	a4,a4,a2
ffffffffc0200e12:	070e                	slli	a4,a4,0x3
ffffffffc0200e14:	971a                	add	a4,a4,t1
ffffffffc0200e16:	02e50e63          	beq	a0,a4,ffffffffc0200e52 <best_fit_free_pages+0xe4>
    if (le != &free_list) {
ffffffffc0200e1a:	00d78f63          	beq	a5,a3,ffffffffc0200e38 <best_fit_free_pages+0xca>
ffffffffc0200e1e:	fe878713          	addi	a4,a5,-24
        if (base + base->property == p) {
ffffffffc0200e22:	490c                	lw	a1,16(a0)
ffffffffc0200e24:	02059613          	slli	a2,a1,0x20
ffffffffc0200e28:	9201                	srli	a2,a2,0x20
ffffffffc0200e2a:	00261693          	slli	a3,a2,0x2
ffffffffc0200e2e:	96b2                	add	a3,a3,a2
ffffffffc0200e30:	068e                	slli	a3,a3,0x3
ffffffffc0200e32:	96aa                	add	a3,a3,a0
ffffffffc0200e34:	04d70863          	beq	a4,a3,ffffffffc0200e84 <best_fit_free_pages+0x116>
}
ffffffffc0200e38:	60a2                	ld	ra,8(sp)
ffffffffc0200e3a:	0141                	addi	sp,sp,16
ffffffffc0200e3c:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc0200e3e:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0200e40:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc0200e42:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc0200e44:	ed1c                	sd	a5,24(a0)
        while ((le = list_next(le)) != &free_list) {
ffffffffc0200e46:	02d70463          	beq	a4,a3,ffffffffc0200e6e <best_fit_free_pages+0x100>
    prev->next = next->prev = elm;
ffffffffc0200e4a:	8332                	mv	t1,a2
ffffffffc0200e4c:	4805                	li	a6,1
    for (; p != base + n; p ++) {
ffffffffc0200e4e:	87ba                	mv	a5,a4
ffffffffc0200e50:	b769                	j	ffffffffc0200dda <best_fit_free_pages+0x6c>
            p->property += base->property;
ffffffffc0200e52:	01c585bb          	addw	a1,a1,t3
ffffffffc0200e56:	feb82c23          	sw	a1,-8(a6)
            ClearPageProperty(base);
ffffffffc0200e5a:	ffd8f893          	andi	a7,a7,-3
ffffffffc0200e5e:	01153423          	sd	a7,8(a0)
    prev->next = next;
ffffffffc0200e62:	00f83423          	sd	a5,8(a6)
    next->prev = prev;
ffffffffc0200e66:	0107b023          	sd	a6,0(a5)
            base = p;
ffffffffc0200e6a:	851a                	mv	a0,t1
ffffffffc0200e6c:	b77d                	j	ffffffffc0200e1a <best_fit_free_pages+0xac>
        while ((le = list_next(le)) != &free_list) {
ffffffffc0200e6e:	883e                	mv	a6,a5
ffffffffc0200e70:	e290                	sd	a2,0(a3)
ffffffffc0200e72:	87b6                	mv	a5,a3
ffffffffc0200e74:	b769                	j	ffffffffc0200dfe <best_fit_free_pages+0x90>
}
ffffffffc0200e76:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc0200e78:	e390                	sd	a2,0(a5)
ffffffffc0200e7a:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0200e7c:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0200e7e:	ed1c                	sd	a5,24(a0)
ffffffffc0200e80:	0141                	addi	sp,sp,16
ffffffffc0200e82:	8082                	ret
            base->property += p->property;
ffffffffc0200e84:	ff87a683          	lw	a3,-8(a5)
            ClearPageProperty(p);
ffffffffc0200e88:	ff07b703          	ld	a4,-16(a5)
    __list_del(listelm->prev, listelm->next);
ffffffffc0200e8c:	0007b803          	ld	a6,0(a5)
ffffffffc0200e90:	6790                	ld	a2,8(a5)
            base->property += p->property;
ffffffffc0200e92:	9db5                	addw	a1,a1,a3
ffffffffc0200e94:	c90c                	sw	a1,16(a0)
            ClearPageProperty(p);
ffffffffc0200e96:	9b75                	andi	a4,a4,-3
ffffffffc0200e98:	fee7b823          	sd	a4,-16(a5)
}
ffffffffc0200e9c:	60a2                	ld	ra,8(sp)
    prev->next = next;
ffffffffc0200e9e:	00c83423          	sd	a2,8(a6)
    next->prev = prev;
ffffffffc0200ea2:	01063023          	sd	a6,0(a2)
ffffffffc0200ea6:	0141                	addi	sp,sp,16
ffffffffc0200ea8:	8082                	ret
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc0200eaa:	00002697          	auipc	a3,0x2
ffffffffc0200eae:	83e68693          	addi	a3,a3,-1986 # ffffffffc02026e8 <etext+0x55e>
ffffffffc0200eb2:	00001617          	auipc	a2,0x1
ffffffffc0200eb6:	54660613          	addi	a2,a2,1350 # ffffffffc02023f8 <etext+0x26e>
ffffffffc0200eba:	05000593          	li	a1,80
ffffffffc0200ebe:	00001517          	auipc	a0,0x1
ffffffffc0200ec2:	55250513          	addi	a0,a0,1362 # ffffffffc0202410 <etext+0x286>
ffffffffc0200ec6:	b04ff0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert(n > 0);
ffffffffc0200eca:	00001697          	auipc	a3,0x1
ffffffffc0200ece:	52668693          	addi	a3,a3,1318 # ffffffffc02023f0 <etext+0x266>
ffffffffc0200ed2:	00001617          	auipc	a2,0x1
ffffffffc0200ed6:	52660613          	addi	a2,a2,1318 # ffffffffc02023f8 <etext+0x26e>
ffffffffc0200eda:	04d00593          	li	a1,77
ffffffffc0200ede:	00001517          	auipc	a0,0x1
ffffffffc0200ee2:	53250513          	addi	a0,a0,1330 # ffffffffc0202410 <etext+0x286>
ffffffffc0200ee6:	ae4ff0ef          	jal	ra,ffffffffc02001ca <__panic>

ffffffffc0200eea <best_fit_init_memmap>:
best_fit_init_memmap(struct Page *base, size_t n) {
ffffffffc0200eea:	1141                	addi	sp,sp,-16
ffffffffc0200eec:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0200eee:	c5f1                	beqz	a1,ffffffffc0200fba <best_fit_init_memmap+0xd0>
    for (; p != base + n; p ++) {
ffffffffc0200ef0:	00259693          	slli	a3,a1,0x2
ffffffffc0200ef4:	96ae                	add	a3,a3,a1
ffffffffc0200ef6:	068e                	slli	a3,a3,0x3
ffffffffc0200ef8:	96aa                	add	a3,a3,a0
ffffffffc0200efa:	87aa                	mv	a5,a0
ffffffffc0200efc:	00d50f63          	beq	a0,a3,ffffffffc0200f1a <best_fit_init_memmap+0x30>
        assert(PageReserved(p));
ffffffffc0200f00:	6798                	ld	a4,8(a5)
ffffffffc0200f02:	8b05                	andi	a4,a4,1
ffffffffc0200f04:	cf41                	beqz	a4,ffffffffc0200f9c <best_fit_init_memmap+0xb2>
        p->flags = p->property = 0;
ffffffffc0200f06:	0007a823          	sw	zero,16(a5)
ffffffffc0200f0a:	0007b423          	sd	zero,8(a5)
ffffffffc0200f0e:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc0200f12:	02878793          	addi	a5,a5,40
ffffffffc0200f16:	fed795e3          	bne	a5,a3,ffffffffc0200f00 <best_fit_init_memmap+0x16>
    SetPageProperty(base);
ffffffffc0200f1a:	6510                	ld	a2,8(a0)
    nr_free += n;
ffffffffc0200f1c:	00006697          	auipc	a3,0x6
ffffffffc0200f20:	0fc68693          	addi	a3,a3,252 # ffffffffc0207018 <free_area>
ffffffffc0200f24:	4a98                	lw	a4,16(a3)
    base->property = n;
ffffffffc0200f26:	2581                	sext.w	a1,a1
    SetPageProperty(base);
ffffffffc0200f28:	00266613          	ori	a2,a2,2
    return list->next == list;
ffffffffc0200f2c:	669c                	ld	a5,8(a3)
    base->property = n;
ffffffffc0200f2e:	c90c                	sw	a1,16(a0)
    SetPageProperty(base);
ffffffffc0200f30:	e510                	sd	a2,8(a0)
    nr_free += n;
ffffffffc0200f32:	9db9                	addw	a1,a1,a4
ffffffffc0200f34:	ca8c                	sw	a1,16(a3)
        list_add(&free_list, &(base->page_link));
ffffffffc0200f36:	01850613          	addi	a2,a0,24
    if (list_empty(&free_list)) {
ffffffffc0200f3a:	04d78a63          	beq	a5,a3,ffffffffc0200f8e <best_fit_init_memmap+0xa4>
            struct Page *page = le2page(le, page_link);
ffffffffc0200f3e:	fe878713          	addi	a4,a5,-24
ffffffffc0200f42:	0006b803          	ld	a6,0(a3)
    if (list_empty(&free_list)) {
ffffffffc0200f46:	4581                	li	a1,0
            if (base < page) {
ffffffffc0200f48:	00e56a63          	bltu	a0,a4,ffffffffc0200f5c <best_fit_init_memmap+0x72>
    return listelm->next;
ffffffffc0200f4c:	6798                	ld	a4,8(a5)
            } else if (list_next(le) == &free_list) {
ffffffffc0200f4e:	02d70263          	beq	a4,a3,ffffffffc0200f72 <best_fit_init_memmap+0x88>
    for (; p != base + n; p ++) {
ffffffffc0200f52:	87ba                	mv	a5,a4
            struct Page *page = le2page(le, page_link);
ffffffffc0200f54:	fe878713          	addi	a4,a5,-24
            if (base < page) {
ffffffffc0200f58:	fee57ae3          	bgeu	a0,a4,ffffffffc0200f4c <best_fit_init_memmap+0x62>
ffffffffc0200f5c:	c199                	beqz	a1,ffffffffc0200f62 <best_fit_init_memmap+0x78>
ffffffffc0200f5e:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc0200f62:	6398                	ld	a4,0(a5)
}
ffffffffc0200f64:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc0200f66:	e390                	sd	a2,0(a5)
ffffffffc0200f68:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc0200f6a:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0200f6c:	ed18                	sd	a4,24(a0)
ffffffffc0200f6e:	0141                	addi	sp,sp,16
ffffffffc0200f70:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc0200f72:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0200f74:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc0200f76:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc0200f78:	ed1c                	sd	a5,24(a0)
        while ((le = list_next(le)) != &free_list) {
ffffffffc0200f7a:	00d70663          	beq	a4,a3,ffffffffc0200f86 <best_fit_init_memmap+0x9c>
    prev->next = next->prev = elm;
ffffffffc0200f7e:	8832                	mv	a6,a2
ffffffffc0200f80:	4585                	li	a1,1
    for (; p != base + n; p ++) {
ffffffffc0200f82:	87ba                	mv	a5,a4
ffffffffc0200f84:	bfc1                	j	ffffffffc0200f54 <best_fit_init_memmap+0x6a>
}
ffffffffc0200f86:	60a2                	ld	ra,8(sp)
ffffffffc0200f88:	e290                	sd	a2,0(a3)
ffffffffc0200f8a:	0141                	addi	sp,sp,16
ffffffffc0200f8c:	8082                	ret
ffffffffc0200f8e:	60a2                	ld	ra,8(sp)
ffffffffc0200f90:	e390                	sd	a2,0(a5)
ffffffffc0200f92:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0200f94:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0200f96:	ed1c                	sd	a5,24(a0)
ffffffffc0200f98:	0141                	addi	sp,sp,16
ffffffffc0200f9a:	8082                	ret
        assert(PageReserved(p));
ffffffffc0200f9c:	00001697          	auipc	a3,0x1
ffffffffc0200fa0:	77468693          	addi	a3,a3,1908 # ffffffffc0202710 <etext+0x586>
ffffffffc0200fa4:	00001617          	auipc	a2,0x1
ffffffffc0200fa8:	45460613          	addi	a2,a2,1108 # ffffffffc02023f8 <etext+0x26e>
ffffffffc0200fac:	45dd                	li	a1,23
ffffffffc0200fae:	00001517          	auipc	a0,0x1
ffffffffc0200fb2:	46250513          	addi	a0,a0,1122 # ffffffffc0202410 <etext+0x286>
ffffffffc0200fb6:	a14ff0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert(n > 0);
ffffffffc0200fba:	00001697          	auipc	a3,0x1
ffffffffc0200fbe:	43668693          	addi	a3,a3,1078 # ffffffffc02023f0 <etext+0x266>
ffffffffc0200fc2:	00001617          	auipc	a2,0x1
ffffffffc0200fc6:	43660613          	addi	a2,a2,1078 # ffffffffc02023f8 <etext+0x26e>
ffffffffc0200fca:	45d1                	li	a1,20
ffffffffc0200fcc:	00001517          	auipc	a0,0x1
ffffffffc0200fd0:	44450513          	addi	a0,a0,1092 # ffffffffc0202410 <etext+0x286>
ffffffffc0200fd4:	9f6ff0ef          	jal	ra,ffffffffc02001ca <__panic>

ffffffffc0200fd8 <init_free_pages>:
        start_pa = managed_start;
    }
    if (end_pa > managed_end) {
        end_pa = managed_end;
    }
    start_pa = ROUNDUP(start_pa, PGSIZE);
ffffffffc0200fd8:	4785                	li	a5,1
ffffffffc0200fda:	07fe                	slli	a5,a5,0x1f
    uintptr_t managed_end = (uintptr_t)npage << PGSHIFT;
ffffffffc0200fdc:	00006697          	auipc	a3,0x6
ffffffffc0200fe0:	12c6b683          	ld	a3,300(a3) # ffffffffc0207108 <npage>
    start_pa = ROUNDUP(start_pa, PGSIZE);
ffffffffc0200fe4:	00f57363          	bgeu	a0,a5,ffffffffc0200fea <init_free_pages+0x12>
ffffffffc0200fe8:	853e                	mv	a0,a5
ffffffffc0200fea:	6785                	lui	a5,0x1
ffffffffc0200fec:	17fd                	addi	a5,a5,-1
ffffffffc0200fee:	953e                	add	a0,a0,a5
ffffffffc0200ff0:	777d                	lui	a4,0xfffff
    uintptr_t managed_end = (uintptr_t)npage << PGSHIFT;
ffffffffc0200ff2:	00c69793          	slli	a5,a3,0xc
ffffffffc0200ff6:	8d79                	and	a0,a0,a4
    end_pa = ROUNDDOWN(end_pa, PGSIZE);
ffffffffc0200ff8:	00f5f363          	bgeu	a1,a5,ffffffffc0200ffe <init_free_pages+0x26>
ffffffffc0200ffc:	87ae                	mv	a5,a1
ffffffffc0200ffe:	75fd                	lui	a1,0xfffff
ffffffffc0201000:	8fed                	and	a5,a5,a1
    if (start_pa >= end_pa) {
ffffffffc0201002:	00f56363          	bltu	a0,a5,ffffffffc0201008 <init_free_pages+0x30>
ffffffffc0201006:	8082                	ret
static inline int page_ref_dec(struct Page *page) {
    page->ref -= 1;
    return page->ref;
}
static inline struct Page *pa2page(uintptr_t pa) {
    if (PPN(pa) >= npage) {
ffffffffc0201008:	00c55713          	srli	a4,a0,0xc
ffffffffc020100c:	02d77763          	bgeu	a4,a3,ffffffffc020103a <init_free_pages+0x62>
        panic("pa2page called with invalid pa");
    }
    return &pages[PPN(pa) - nbase];
ffffffffc0201010:	fff806b7          	lui	a3,0xfff80
ffffffffc0201014:	96ba                	add	a3,a3,a4
ffffffffc0201016:	00269713          	slli	a4,a3,0x2
ffffffffc020101a:	9736                	add	a4,a4,a3
    pmm_manager->init_memmap(base, n);
ffffffffc020101c:	00006697          	auipc	a3,0x6
ffffffffc0201020:	0fc6b683          	ld	a3,252(a3) # ffffffffc0207118 <pmm_manager>
ffffffffc0201024:	6a94                	ld	a3,16(a3)
        return;
    }
    init_memmap(pa2page(start_pa), (end_pa - start_pa) >> PGSHIFT);
ffffffffc0201026:	8f89                	sub	a5,a5,a0
ffffffffc0201028:	070e                	slli	a4,a4,0x3
    pmm_manager->init_memmap(base, n);
ffffffffc020102a:	00006517          	auipc	a0,0x6
ffffffffc020102e:	0e653503          	ld	a0,230(a0) # ffffffffc0207110 <pages>
ffffffffc0201032:	00c7d593          	srli	a1,a5,0xc
ffffffffc0201036:	953a                	add	a0,a0,a4
ffffffffc0201038:	8682                	jr	a3
static void init_free_pages(uintptr_t start_pa, uintptr_t end_pa) {
ffffffffc020103a:	1141                	addi	sp,sp,-16
        panic("pa2page called with invalid pa");
ffffffffc020103c:	00001617          	auipc	a2,0x1
ffffffffc0201040:	73460613          	addi	a2,a2,1844 # ffffffffc0202770 <best_fit_pmm_manager+0x38>
ffffffffc0201044:	06800593          	li	a1,104
ffffffffc0201048:	00001517          	auipc	a0,0x1
ffffffffc020104c:	74850513          	addi	a0,a0,1864 # ffffffffc0202790 <best_fit_pmm_manager+0x58>
ffffffffc0201050:	e406                	sd	ra,8(sp)
ffffffffc0201052:	978ff0ef          	jal	ra,ffffffffc02001ca <__panic>

ffffffffc0201056 <alloc_pages>:
    return pmm_manager->alloc_pages(n);
ffffffffc0201056:	00006797          	auipc	a5,0x6
ffffffffc020105a:	0c27b783          	ld	a5,194(a5) # ffffffffc0207118 <pmm_manager>
ffffffffc020105e:	6f9c                	ld	a5,24(a5)
ffffffffc0201060:	8782                	jr	a5

ffffffffc0201062 <free_pages>:
    pmm_manager->free_pages(base, n);
ffffffffc0201062:	00006797          	auipc	a5,0x6
ffffffffc0201066:	0b67b783          	ld	a5,182(a5) # ffffffffc0207118 <pmm_manager>
ffffffffc020106a:	739c                	ld	a5,32(a5)
ffffffffc020106c:	8782                	jr	a5

ffffffffc020106e <nr_free_pages>:
    return pmm_manager->nr_free_pages();
ffffffffc020106e:	00006797          	auipc	a5,0x6
ffffffffc0201072:	0aa7b783          	ld	a5,170(a5) # ffffffffc0207118 <pmm_manager>
ffffffffc0201076:	779c                	ld	a5,40(a5)
ffffffffc0201078:	8782                	jr	a5

ffffffffc020107a <pmm_init>:
    pmm_manager = &best_fit_pmm_manager; //需改动
ffffffffc020107a:	00001797          	auipc	a5,0x1
ffffffffc020107e:	6be78793          	addi	a5,a5,1726 # ffffffffc0202738 <best_fit_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0201082:	638c                	ld	a1,0(a5)

    cprintf("Free pages registered: %lu\n", (unsigned long)nr_free_pages());
}

/* pmm_init - initialize the physical memory management */
void pmm_init(void) {
ffffffffc0201084:	715d                	addi	sp,sp,-80
ffffffffc0201086:	f84a                	sd	s2,48(sp)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0201088:	00001517          	auipc	a0,0x1
ffffffffc020108c:	71850513          	addi	a0,a0,1816 # ffffffffc02027a0 <best_fit_pmm_manager+0x68>
    pmm_manager = &best_fit_pmm_manager; //需改动
ffffffffc0201090:	00006917          	auipc	s2,0x6
ffffffffc0201094:	08890913          	addi	s2,s2,136 # ffffffffc0207118 <pmm_manager>
void pmm_init(void) {
ffffffffc0201098:	e486                	sd	ra,72(sp)
ffffffffc020109a:	f052                	sd	s4,32(sp)
ffffffffc020109c:	e0a2                	sd	s0,64(sp)
ffffffffc020109e:	fc26                	sd	s1,56(sp)
ffffffffc02010a0:	f44e                	sd	s3,40(sp)
ffffffffc02010a2:	ec56                	sd	s5,24(sp)
ffffffffc02010a4:	e85a                	sd	s6,16(sp)
ffffffffc02010a6:	e45e                	sd	s7,8(sp)
ffffffffc02010a8:	e062                	sd	s8,0(sp)
    pmm_manager = &best_fit_pmm_manager; //需改动
ffffffffc02010aa:	00f93023          	sd	a5,0(s2)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc02010ae:	8a6ff0ef          	jal	ra,ffffffffc0200154 <cprintf>
    pmm_manager->init();
ffffffffc02010b2:	00093783          	ld	a5,0(s2)
ffffffffc02010b6:	679c                	ld	a5,8(a5)
ffffffffc02010b8:	9782                	jalr	a5
    uint64_t mem_base = get_memory_base();
ffffffffc02010ba:	d0aff0ef          	jal	ra,ffffffffc02005c4 <get_memory_base>
ffffffffc02010be:	8a2a                	mv	s4,a0
    uint64_t mem_size = get_memory_size();
ffffffffc02010c0:	d0eff0ef          	jal	ra,ffffffffc02005ce <get_memory_size>
    if (mem_base == 0 || mem_size == 0) {
ffffffffc02010c4:	180a0c63          	beqz	s4,ffffffffc020125c <pmm_init+0x1e2>
ffffffffc02010c8:	18050a63          	beqz	a0,ffffffffc020125c <pmm_init+0x1e2>
    uintptr_t mem_end = mem_start + (uintptr_t)mem_size;
ffffffffc02010cc:	00aa0433          	add	s0,s4,a0
    if (mem_end <= mem_start) {
ffffffffc02010d0:	1c8a7b63          	bgeu	s4,s0,ffffffffc02012a6 <pmm_init+0x22c>
    if (mem_start < DRAM_BASE) {
ffffffffc02010d4:	4785                	li	a5,1
ffffffffc02010d6:	07fe                	slli	a5,a5,0x1f
ffffffffc02010d8:	8ad2                	mv	s5,s4
ffffffffc02010da:	14fa6663          	bltu	s4,a5,ffffffffc0201226 <pmm_init+0x1ac>
    if (mem_end > PHYSICAL_MEMORY_END) {
ffffffffc02010de:	47c5                	li	a5,17
ffffffffc02010e0:	07ee                	slli	a5,a5,0x1b
ffffffffc02010e2:	1487e063          	bltu	a5,s0,ffffffffc0201222 <pmm_init+0x1a8>
    if (mem_end <= mem_start) {
ffffffffc02010e6:	1c8afc63          	bgeu	s5,s0,ffffffffc02012be <pmm_init+0x244>
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc02010ea:	57f5                	li	a5,-3
ffffffffc02010ec:	07fa                	slli	a5,a5,0x1e
ffffffffc02010ee:	00006997          	auipc	s3,0x6
ffffffffc02010f2:	04298993          	addi	s3,s3,66 # ffffffffc0207130 <va_pa_offset>
    npage = PPN(mem_end);
ffffffffc02010f6:	00c45693          	srli	a3,s0,0xc
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc02010fa:	00f9b023          	sd	a5,0(s3)
    if (npage <= nbase) {
ffffffffc02010fe:	00080b37          	lui	s6,0x80
    npage = PPN(mem_end);
ffffffffc0201102:	00006797          	auipc	a5,0x6
ffffffffc0201106:	00d7b323          	sd	a3,6(a5) # ffffffffc0207108 <npage>
    if (npage <= nbase) {
ffffffffc020110a:	1f668363          	beq	a3,s6,ffffffffc02012f0 <pmm_init+0x276>
    pages = (struct Page *)ROUNDUP((uintptr_t)end, PGSIZE);
ffffffffc020110e:	777d                	lui	a4,0xfffff
ffffffffc0201110:	00007797          	auipc	a5,0x7
ffffffffc0201114:	02778793          	addi	a5,a5,39 # ffffffffc0208137 <end+0xfff>
ffffffffc0201118:	8ff9                	and	a5,a5,a4
ffffffffc020111a:	00006c17          	auipc	s8,0x6
ffffffffc020111e:	ff6c0c13          	addi	s8,s8,-10 # ffffffffc0207110 <pages>
ffffffffc0201122:	00fc3023          	sd	a5,0(s8)
    uintptr_t desc_pa = PADDR((uintptr_t)pages);
ffffffffc0201126:	c0200737          	lui	a4,0xc0200
    size_t ndesc = npage - nbase;
ffffffffc020112a:	41668b33          	sub	s6,a3,s6
    uintptr_t desc_pa = PADDR((uintptr_t)pages);
ffffffffc020112e:	1ae7e463          	bltu	a5,a4,ffffffffc02012d6 <pmm_init+0x25c>
    uintptr_t desc_end_pa = desc_pa + ndesc * sizeof(struct Page);
ffffffffc0201132:	002b1b93          	slli	s7,s6,0x2
    uintptr_t desc_pa = PADDR((uintptr_t)pages);
ffffffffc0201136:	448d                	li	s1,3
    uintptr_t desc_end_pa = desc_pa + ndesc * sizeof(struct Page);
ffffffffc0201138:	9bda                	add	s7,s7,s6
    uintptr_t desc_pa = PADDR((uintptr_t)pages);
ffffffffc020113a:	04fa                	slli	s1,s1,0x1e
    uintptr_t desc_end_pa = desc_pa + ndesc * sizeof(struct Page);
ffffffffc020113c:	0b8e                	slli	s7,s7,0x3
    uintptr_t desc_pa = PADDR((uintptr_t)pages);
ffffffffc020113e:	94be                	add	s1,s1,a5
    uintptr_t desc_end_pa = desc_pa + ndesc * sizeof(struct Page);
ffffffffc0201140:	94de                	add	s1,s1,s7
    if (desc_end_pa > mem_end) {
ffffffffc0201142:	14946663          	bltu	s0,s1,ffffffffc020128e <pmm_init+0x214>
ffffffffc0201146:	00269713          	slli	a4,a3,0x2
ffffffffc020114a:	9736                	add	a4,a4,a3
ffffffffc020114c:	fec00637          	lui	a2,0xfec00
ffffffffc0201150:	963e                	add	a2,a2,a5
ffffffffc0201152:	070e                	slli	a4,a4,0x3
ffffffffc0201154:	963a                	add	a2,a2,a4
        SetPageReserved(pages + i);
ffffffffc0201156:	6798                	ld	a4,8(a5)
    for (size_t i = 0; i < ndesc; i++) {
ffffffffc0201158:	02878793          	addi	a5,a5,40
        SetPageReserved(pages + i);
ffffffffc020115c:	00176713          	ori	a4,a4,1
ffffffffc0201160:	fee7b023          	sd	a4,-32(a5)
    for (size_t i = 0; i < ndesc; i++) {
ffffffffc0201164:	fec799e3          	bne	a5,a2,ffffffffc0201156 <pmm_init+0xdc>
    cprintf("Physical memory: [0x%016lx, 0x%016lx), npage = %lu, nbase = %lu\n",
ffffffffc0201168:	00080737          	lui	a4,0x80
ffffffffc020116c:	85d6                	mv	a1,s5
ffffffffc020116e:	8622                	mv	a2,s0
ffffffffc0201170:	00001517          	auipc	a0,0x1
ffffffffc0201174:	77050513          	addi	a0,a0,1904 # ffffffffc02028e0 <best_fit_pmm_manager+0x1a8>
ffffffffc0201178:	fddfe0ef          	jal	ra,ffffffffc0200154 <cprintf>
    cprintf("Page descriptors: 0x%016lx, %lu pages (%lu bytes)\n",
ffffffffc020117c:	000c3583          	ld	a1,0(s8)
ffffffffc0201180:	86de                	mv	a3,s7
ffffffffc0201182:	865a                	mv	a2,s6
ffffffffc0201184:	00001517          	auipc	a0,0x1
ffffffffc0201188:	7a450513          	addi	a0,a0,1956 # ffffffffc0202928 <best_fit_pmm_manager+0x1f0>
ffffffffc020118c:	fc9fe0ef          	jal	ra,ffffffffc0200154 <cprintf>
        if (start >= end) {
ffffffffc0201190:	40100793          	li	a5,1025
ffffffffc0201194:	07d6                	slli	a5,a5,0x15
ffffffffc0201196:	0afa7563          	bgeu	s4,a5,ffffffffc0201240 <pmm_init+0x1c6>
        if (end > mem_end) {
ffffffffc020119a:	87a2                	mv	a5,s0
ffffffffc020119c:	0884eb63          	bltu	s1,s0,ffffffffc0201232 <pmm_init+0x1b8>
        if (start >= end) {
ffffffffc02011a0:	40100a93          	li	s5,1025
ffffffffc02011a4:	0ad6                	slli	s5,s5,0x15
        if (end > cursor) {
ffffffffc02011a6:	0afae363          	bltu	s5,a5,ffffffffc020124c <pmm_init+0x1d2>
    if (cursor < mem_end) {
ffffffffc02011aa:	0a8ae463          	bltu	s5,s0,ffffffffc0201252 <pmm_init+0x1d8>
    return pmm_manager->nr_free_pages();
ffffffffc02011ae:	00093783          	ld	a5,0(s2)
ffffffffc02011b2:	779c                	ld	a5,40(a5)
ffffffffc02011b4:	9782                	jalr	a5
ffffffffc02011b6:	85aa                	mv	a1,a0
    cprintf("Free pages registered: %lu\n", (unsigned long)nr_free_pages());
ffffffffc02011b8:	00001517          	auipc	a0,0x1
ffffffffc02011bc:	7a850513          	addi	a0,a0,1960 # ffffffffc0202960 <best_fit_pmm_manager+0x228>
ffffffffc02011c0:	f95fe0ef          	jal	ra,ffffffffc0200154 <cprintf>
    satp_physical = PADDR(satp_virtual);
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
}

static void check_alloc_page(void) {
    pmm_manager->check();
ffffffffc02011c4:	00093783          	ld	a5,0(s2)
ffffffffc02011c8:	7b9c                	ld	a5,48(a5)
ffffffffc02011ca:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc02011cc:	00001517          	auipc	a0,0x1
ffffffffc02011d0:	7b450513          	addi	a0,a0,1972 # ffffffffc0202980 <best_fit_pmm_manager+0x248>
ffffffffc02011d4:	f81fe0ef          	jal	ra,ffffffffc0200154 <cprintf>
    satp_virtual = (pte_t*)boot_page_table_sv39;
ffffffffc02011d8:	00005597          	auipc	a1,0x5
ffffffffc02011dc:	e2858593          	addi	a1,a1,-472 # ffffffffc0206000 <boot_page_table_sv39>
ffffffffc02011e0:	00006797          	auipc	a5,0x6
ffffffffc02011e4:	f4b7b423          	sd	a1,-184(a5) # ffffffffc0207128 <satp_virtual>
    satp_physical = PADDR(satp_virtual);
ffffffffc02011e8:	c02007b7          	lui	a5,0xc0200
ffffffffc02011ec:	08f5e463          	bltu	a1,a5,ffffffffc0201274 <pmm_init+0x1fa>
ffffffffc02011f0:	0009b603          	ld	a2,0(s3)
}
ffffffffc02011f4:	6406                	ld	s0,64(sp)
ffffffffc02011f6:	60a6                	ld	ra,72(sp)
ffffffffc02011f8:	74e2                	ld	s1,56(sp)
ffffffffc02011fa:	7942                	ld	s2,48(sp)
ffffffffc02011fc:	79a2                	ld	s3,40(sp)
ffffffffc02011fe:	7a02                	ld	s4,32(sp)
ffffffffc0201200:	6ae2                	ld	s5,24(sp)
ffffffffc0201202:	6b42                	ld	s6,16(sp)
ffffffffc0201204:	6ba2                	ld	s7,8(sp)
ffffffffc0201206:	6c02                	ld	s8,0(sp)
    satp_physical = PADDR(satp_virtual);
ffffffffc0201208:	40c58633          	sub	a2,a1,a2
ffffffffc020120c:	00006797          	auipc	a5,0x6
ffffffffc0201210:	f0c7ba23          	sd	a2,-236(a5) # ffffffffc0207120 <satp_physical>
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc0201214:	00001517          	auipc	a0,0x1
ffffffffc0201218:	78c50513          	addi	a0,a0,1932 # ffffffffc02029a0 <best_fit_pmm_manager+0x268>
}
ffffffffc020121c:	6161                	addi	sp,sp,80
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc020121e:	f37fe06f          	j	ffffffffc0200154 <cprintf>
ffffffffc0201222:	843e                	mv	s0,a5
ffffffffc0201224:	b5c9                	j	ffffffffc02010e6 <pmm_init+0x6c>
ffffffffc0201226:	8abe                	mv	s5,a5
    if (mem_end > PHYSICAL_MEMORY_END) {
ffffffffc0201228:	47c5                	li	a5,17
ffffffffc020122a:	07ee                	slli	a5,a5,0x1b
ffffffffc020122c:	ea87fde3          	bgeu	a5,s0,ffffffffc02010e6 <pmm_init+0x6c>
ffffffffc0201230:	bfcd                	j	ffffffffc0201222 <pmm_init+0x1a8>
        if (start >= end) {
ffffffffc0201232:	40100a93          	li	s5,1025
ffffffffc0201236:	87a6                	mv	a5,s1
ffffffffc0201238:	0ad6                	slli	s5,s5,0x15
        if (end > cursor) {
ffffffffc020123a:	f6faf8e3          	bgeu	s5,a5,ffffffffc02011aa <pmm_init+0x130>
ffffffffc020123e:	a039                	j	ffffffffc020124c <pmm_init+0x1d2>
        if (end > mem_end) {
ffffffffc0201240:	87a2                	mv	a5,s0
ffffffffc0201242:	0084f363          	bgeu	s1,s0,ffffffffc0201248 <pmm_init+0x1ce>
ffffffffc0201246:	87a6                	mv	a5,s1
        if (start >= end) {
ffffffffc0201248:	00faf563          	bgeu	s5,a5,ffffffffc0201252 <pmm_init+0x1d8>
ffffffffc020124c:	8abe                	mv	s5,a5
    if (cursor < mem_end) {
ffffffffc020124e:	f68af0e3          	bgeu	s5,s0,ffffffffc02011ae <pmm_init+0x134>
        init_free_pages(cursor, mem_end);
ffffffffc0201252:	85a2                	mv	a1,s0
ffffffffc0201254:	8556                	mv	a0,s5
ffffffffc0201256:	d83ff0ef          	jal	ra,ffffffffc0200fd8 <init_free_pages>
ffffffffc020125a:	bf91                	j	ffffffffc02011ae <pmm_init+0x134>
        panic("page_init: invalid memory information from device tree");
ffffffffc020125c:	00001617          	auipc	a2,0x1
ffffffffc0201260:	55c60613          	addi	a2,a2,1372 # ffffffffc02027b8 <best_fit_pmm_manager+0x80>
ffffffffc0201264:	06700593          	li	a1,103
ffffffffc0201268:	00001517          	auipc	a0,0x1
ffffffffc020126c:	58850513          	addi	a0,a0,1416 # ffffffffc02027f0 <best_fit_pmm_manager+0xb8>
ffffffffc0201270:	f5bfe0ef          	jal	ra,ffffffffc02001ca <__panic>
    satp_physical = PADDR(satp_virtual);
ffffffffc0201274:	86ae                	mv	a3,a1
ffffffffc0201276:	00001617          	auipc	a2,0x1
ffffffffc020127a:	60260613          	addi	a2,a2,1538 # ffffffffc0202878 <best_fit_pmm_manager+0x140>
ffffffffc020127e:	0d400593          	li	a1,212
ffffffffc0201282:	00001517          	auipc	a0,0x1
ffffffffc0201286:	56e50513          	addi	a0,a0,1390 # ffffffffc02027f0 <best_fit_pmm_manager+0xb8>
ffffffffc020128a:	f41fe0ef          	jal	ra,ffffffffc02001ca <__panic>
        panic("page_init: page descriptors do not fit in physical memory");
ffffffffc020128e:	00001617          	auipc	a2,0x1
ffffffffc0201292:	61260613          	addi	a2,a2,1554 # ffffffffc02028a0 <best_fit_pmm_manager+0x168>
ffffffffc0201296:	08c00593          	li	a1,140
ffffffffc020129a:	00001517          	auipc	a0,0x1
ffffffffc020129e:	55650513          	addi	a0,a0,1366 # ffffffffc02027f0 <best_fit_pmm_manager+0xb8>
ffffffffc02012a2:	f29fe0ef          	jal	ra,ffffffffc02001ca <__panic>
        panic("page_init: physical memory range overflow");
ffffffffc02012a6:	00001617          	auipc	a2,0x1
ffffffffc02012aa:	55a60613          	addi	a2,a2,1370 # ffffffffc0202800 <best_fit_pmm_manager+0xc8>
ffffffffc02012ae:	06d00593          	li	a1,109
ffffffffc02012b2:	00001517          	auipc	a0,0x1
ffffffffc02012b6:	53e50513          	addi	a0,a0,1342 # ffffffffc02027f0 <best_fit_pmm_manager+0xb8>
ffffffffc02012ba:	f11fe0ef          	jal	ra,ffffffffc02001ca <__panic>
        panic("page_init: no usable physical memory");
ffffffffc02012be:	00001617          	auipc	a2,0x1
ffffffffc02012c2:	57260613          	addi	a2,a2,1394 # ffffffffc0202830 <best_fit_pmm_manager+0xf8>
ffffffffc02012c6:	07800593          	li	a1,120
ffffffffc02012ca:	00001517          	auipc	a0,0x1
ffffffffc02012ce:	52650513          	addi	a0,a0,1318 # ffffffffc02027f0 <best_fit_pmm_manager+0xb8>
ffffffffc02012d2:	ef9fe0ef          	jal	ra,ffffffffc02001ca <__panic>
    uintptr_t desc_pa = PADDR((uintptr_t)pages);
ffffffffc02012d6:	86be                	mv	a3,a5
ffffffffc02012d8:	00001617          	auipc	a2,0x1
ffffffffc02012dc:	5a060613          	addi	a2,a2,1440 # ffffffffc0202878 <best_fit_pmm_manager+0x140>
ffffffffc02012e0:	08900593          	li	a1,137
ffffffffc02012e4:	00001517          	auipc	a0,0x1
ffffffffc02012e8:	50c50513          	addi	a0,a0,1292 # ffffffffc02027f0 <best_fit_pmm_manager+0xb8>
ffffffffc02012ec:	edffe0ef          	jal	ra,ffffffffc02001ca <__panic>
        panic("page_init: invalid npage");
ffffffffc02012f0:	00001617          	auipc	a2,0x1
ffffffffc02012f4:	56860613          	addi	a2,a2,1384 # ffffffffc0202858 <best_fit_pmm_manager+0x120>
ffffffffc02012f8:	08200593          	li	a1,130
ffffffffc02012fc:	00001517          	auipc	a0,0x1
ffffffffc0201300:	4f450513          	addi	a0,a0,1268 # ffffffffc02027f0 <best_fit_pmm_manager+0xb8>
ffffffffc0201304:	ec7fe0ef          	jal	ra,ffffffffc02001ca <__panic>

ffffffffc0201308 <kmalloc.part.0>:
            "oversized (>%u) falls back to pages\n",
            (unsigned int)SLUB_CACHE_COUNT, (unsigned int)SLUB_MAX_SIZE);
}

void *
kmalloc(size_t size) {
ffffffffc0201308:	7179                	addi	sp,sp,-48
ffffffffc020130a:	e84a                	sd	s2,16(sp)
ffffffffc020130c:	00006917          	auipc	s2,0x6
ffffffffc0201310:	d2490913          	addi	s2,s2,-732 # ffffffffc0207030 <kmem_caches>
ffffffffc0201314:	f022                	sd	s0,32(sp)
ffffffffc0201316:	ec26                	sd	s1,24(sp)
ffffffffc0201318:	f406                	sd	ra,40(sp)
ffffffffc020131a:	e44e                	sd	s3,8(sp)
ffffffffc020131c:	e052                	sd	s4,0(sp)
ffffffffc020131e:	84aa                	mv	s1,a0
ffffffffc0201320:	87ca                	mv	a5,s2
    for (size_t i = 0; i < SLUB_CACHE_COUNT; i++) {
ffffffffc0201322:	4401                	li	s0,0
ffffffffc0201324:	4691                	li	a3,4
        if (size <= kmem_caches[i].size) {
ffffffffc0201326:	6798                	ld	a4,8(a5)
ffffffffc0201328:	06977c63          	bgeu	a4,s1,ffffffffc02013a0 <kmalloc.part.0+0x98>
    for (size_t i = 0; i < SLUB_CACHE_COUNT; i++) {
ffffffffc020132c:	0405                	addi	s0,s0,1
ffffffffc020132e:	03078793          	addi	a5,a5,48
ffffffffc0201332:	fed41ae3          	bne	s0,a3,ffffffffc0201326 <kmalloc.part.0+0x1e>
        }
        return slab_alloc_object(cache);
    }

    /* 超大对象：整页回退。返回页对应的内核虚拟地址（可直接读写）。 */
    size_t n = ROUNDUP(size, PGSIZE) / PGSIZE;
ffffffffc0201336:	6905                	lui	s2,0x1
ffffffffc0201338:	197d                	addi	s2,s2,-1
ffffffffc020133a:	9926                	add	s2,s2,s1
ffffffffc020133c:	00c95913          	srli	s2,s2,0xc
    struct Page *page = alloc_pages(n);
ffffffffc0201340:	854a                	mv	a0,s2
ffffffffc0201342:	d15ff0ef          	jal	ra,ffffffffc0201056 <alloc_pages>
ffffffffc0201346:	842a                	mv	s0,a0
    if (page == NULL) {
ffffffffc0201348:	14050063          	beqz	a0,ffffffffc0201488 <kmalloc.part.0+0x180>
        return NULL;
    }
    page->property = (unsigned int)n;  // 记下页数，供 kfree 释放
ffffffffc020134c:	01242823          	sw	s2,16(s0)
    cprintf("slub: oversized %lu bytes -> %lu page(s)\n",
ffffffffc0201350:	864a                	mv	a2,s2
ffffffffc0201352:	85a6                	mv	a1,s1
ffffffffc0201354:	00001517          	auipc	a0,0x1
ffffffffc0201358:	6ec50513          	addi	a0,a0,1772 # ffffffffc0202a40 <best_fit_pmm_manager+0x308>
ffffffffc020135c:	df9fe0ef          	jal	ra,ffffffffc0200154 <cprintf>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0201360:	00006517          	auipc	a0,0x6
ffffffffc0201364:	db053503          	ld	a0,-592(a0) # ffffffffc0207110 <pages>
ffffffffc0201368:	40a40533          	sub	a0,s0,a0
ffffffffc020136c:	00002797          	auipc	a5,0x2
ffffffffc0201370:	08c7b783          	ld	a5,140(a5) # ffffffffc02033f8 <error_string+0x38>
ffffffffc0201374:	850d                	srai	a0,a0,0x3
ffffffffc0201376:	02f50533          	mul	a0,a0,a5
            (unsigned long)size, (unsigned long)n);
    return slub_page2kva(page);
}
ffffffffc020137a:	70a2                	ld	ra,40(sp)
ffffffffc020137c:	00002797          	auipc	a5,0x2
ffffffffc0201380:	08c7b783          	ld	a5,140(a5) # ffffffffc0203408 <nbase>
ffffffffc0201384:	7402                	ld	s0,32(sp)
ffffffffc0201386:	64e2                	ld	s1,24(sp)
ffffffffc0201388:	6942                	ld	s2,16(sp)
ffffffffc020138a:	69a2                	ld	s3,8(sp)
ffffffffc020138c:	6a02                	ld	s4,0(sp)
ffffffffc020138e:	953e                	add	a0,a0,a5
    return page2ppn(page) << PGSHIFT;
ffffffffc0201390:	0532                	slli	a0,a0,0xc
    return (void *)(page2pa(page) + va_pa_offset);
ffffffffc0201392:	00006797          	auipc	a5,0x6
ffffffffc0201396:	d9e7b783          	ld	a5,-610(a5) # ffffffffc0207130 <va_pa_offset>
ffffffffc020139a:	953e                	add	a0,a0,a5
}
ffffffffc020139c:	6145                	addi	sp,sp,48
ffffffffc020139e:	8082                	ret
        if (cache->freelist == NULL && slab_grow(cache) != 0) {
ffffffffc02013a0:	00141993          	slli	s3,s0,0x1
ffffffffc02013a4:	00898a33          	add	s4,s3,s0
ffffffffc02013a8:	0a12                	slli	s4,s4,0x4
ffffffffc02013aa:	014904b3          	add	s1,s2,s4
ffffffffc02013ae:	6c88                	ld	a0,24(s1)
ffffffffc02013b0:	c505                	beqz	a0,ffffffffc02013d8 <kmalloc.part.0+0xd0>
    cache->freelist = *(void **)obj;
ffffffffc02013b2:	944e                	add	s0,s0,s3
ffffffffc02013b4:	0412                	slli	s0,s0,0x4
ffffffffc02013b6:	9922                	add	s2,s2,s0
    cache->nr_inuse++;
ffffffffc02013b8:	02893783          	ld	a5,40(s2) # 1028 <kern_entry-0xffffffffc01fefd8>
    cache->freelist = *(void **)obj;
ffffffffc02013bc:	6118                	ld	a4,0(a0)
    cache->nr_inuse++;
ffffffffc02013be:	0785                	addi	a5,a5,1
    cache->freelist = *(void **)obj;
ffffffffc02013c0:	00e93c23          	sd	a4,24(s2)
    cache->nr_inuse++;
ffffffffc02013c4:	02f93423          	sd	a5,40(s2)
}
ffffffffc02013c8:	70a2                	ld	ra,40(sp)
ffffffffc02013ca:	7402                	ld	s0,32(sp)
ffffffffc02013cc:	64e2                	ld	s1,24(sp)
ffffffffc02013ce:	6942                	ld	s2,16(sp)
ffffffffc02013d0:	69a2                	ld	s3,8(sp)
ffffffffc02013d2:	6a02                	ld	s4,0(sp)
ffffffffc02013d4:	6145                	addi	sp,sp,48
ffffffffc02013d6:	8082                	ret
    struct Page *page = alloc_page();
ffffffffc02013d8:	4505                	li	a0,1
ffffffffc02013da:	c7dff0ef          	jal	ra,ffffffffc0201056 <alloc_pages>
    if (page == NULL) {
ffffffffc02013de:	c54d                	beqz	a0,ffffffffc0201488 <kmalloc.part.0+0x180>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc02013e0:	00006597          	auipc	a1,0x6
ffffffffc02013e4:	d305b583          	ld	a1,-720(a1) # ffffffffc0207110 <pages>
ffffffffc02013e8:	40b505b3          	sub	a1,a0,a1
ffffffffc02013ec:	00002797          	auipc	a5,0x2
ffffffffc02013f0:	00c7b783          	ld	a5,12(a5) # ffffffffc02033f8 <error_string+0x38>
ffffffffc02013f4:	858d                	srai	a1,a1,0x3
ffffffffc02013f6:	02f585b3          	mul	a1,a1,a5
    SetPageSlab(page);
ffffffffc02013fa:	651c                	ld	a5,8(a0)
    for (size_t i = 0; i < cache->objs_per_page; i++) {
ffffffffc02013fc:	6890                	ld	a2,16(s1)
    page->property = (unsigned int)(cache - kmem_caches);  // 记下所属 cache 索引
ffffffffc02013fe:	404a5a13          	srai	s4,s4,0x4
    SetPageSlab(page);
ffffffffc0201402:	0047e793          	ori	a5,a5,4
ffffffffc0201406:	e51c                	sd	a5,8(a0)
    page->property = (unsigned int)(cache - kmem_caches);  // 记下所属 cache 索引
ffffffffc0201408:	00002797          	auipc	a5,0x2
ffffffffc020140c:	ff87b783          	ld	a5,-8(a5) # ffffffffc0203400 <error_string+0x40>
ffffffffc0201410:	02fa0a33          	mul	s4,s4,a5
ffffffffc0201414:	00002797          	auipc	a5,0x2
ffffffffc0201418:	ff47b783          	ld	a5,-12(a5) # ffffffffc0203408 <nbase>
ffffffffc020141c:	95be                	add	a1,a1,a5
    return page2ppn(page) << PGSHIFT;
ffffffffc020141e:	05b2                	slli	a1,a1,0xc
    return (void *)(page2pa(page) + va_pa_offset);
ffffffffc0201420:	00006797          	auipc	a5,0x6
ffffffffc0201424:	d107b783          	ld	a5,-752(a5) # ffffffffc0207130 <va_pa_offset>
ffffffffc0201428:	95be                	add	a1,a1,a5
    page->property = (unsigned int)(cache - kmem_caches);  // 记下所属 cache 索引
ffffffffc020142a:	01452823          	sw	s4,16(a0)
    for (size_t i = 0; i < cache->objs_per_page; i++) {
ffffffffc020142e:	ce09                	beqz	a2,ffffffffc0201448 <kmalloc.part.0+0x140>
        *(void **)obj = cache->freelist;  // 空闲对象头部存下一空闲对象地址
ffffffffc0201430:	6c98                	ld	a4,24(s1)
    for (size_t i = 0; i < cache->objs_per_page; i++) {
ffffffffc0201432:	4781                	li	a5,0
        void *obj = (char *)base + i * cache->size;
ffffffffc0201434:	6494                	ld	a3,8(s1)
ffffffffc0201436:	853a                	mv	a0,a4
ffffffffc0201438:	02d78733          	mul	a4,a5,a3
    for (size_t i = 0; i < cache->objs_per_page; i++) {
ffffffffc020143c:	0785                	addi	a5,a5,1
        void *obj = (char *)base + i * cache->size;
ffffffffc020143e:	972e                	add	a4,a4,a1
        *(void **)obj = cache->freelist;  // 空闲对象头部存下一空闲对象地址
ffffffffc0201440:	e308                	sd	a0,0(a4)
        cache->freelist = obj;
ffffffffc0201442:	ec98                	sd	a4,24(s1)
    for (size_t i = 0; i < cache->objs_per_page; i++) {
ffffffffc0201444:	fec798e3          	bne	a5,a2,ffffffffc0201434 <kmalloc.part.0+0x12c>
    cache->nr_slabs++;
ffffffffc0201448:	008984b3          	add	s1,s3,s0
ffffffffc020144c:	0492                	slli	s1,s1,0x4
ffffffffc020144e:	94ca                	add	s1,s1,s2
ffffffffc0201450:	7094                	ld	a3,32(s1)
    cprintf("slub: cache %-12s grown, %lu objects/page, %lu slabs now\n",
ffffffffc0201452:	608c                	ld	a1,0(s1)
ffffffffc0201454:	00001517          	auipc	a0,0x1
ffffffffc0201458:	58c50513          	addi	a0,a0,1420 # ffffffffc02029e0 <best_fit_pmm_manager+0x2a8>
    cache->nr_slabs++;
ffffffffc020145c:	0685                	addi	a3,a3,1
ffffffffc020145e:	f094                	sd	a3,32(s1)
    cprintf("slub: cache %-12s grown, %lu objects/page, %lu slabs now\n",
ffffffffc0201460:	cf5fe0ef          	jal	ra,ffffffffc0200154 <cprintf>
    void *obj = cache->freelist;
ffffffffc0201464:	6c88                	ld	a0,24(s1)
    assert(obj != NULL);
ffffffffc0201466:	f531                	bnez	a0,ffffffffc02013b2 <kmalloc.part.0+0xaa>
ffffffffc0201468:	00001697          	auipc	a3,0x1
ffffffffc020146c:	5b868693          	addi	a3,a3,1464 # ffffffffc0202a20 <best_fit_pmm_manager+0x2e8>
ffffffffc0201470:	00001617          	auipc	a2,0x1
ffffffffc0201474:	f8860613          	addi	a2,a2,-120 # ffffffffc02023f8 <etext+0x26e>
ffffffffc0201478:	05a00593          	li	a1,90
ffffffffc020147c:	00001517          	auipc	a0,0x1
ffffffffc0201480:	5b450513          	addi	a0,a0,1460 # ffffffffc0202a30 <best_fit_pmm_manager+0x2f8>
ffffffffc0201484:	d47fe0ef          	jal	ra,ffffffffc02001ca <__panic>
            return NULL;
ffffffffc0201488:	4501                	li	a0,0
ffffffffc020148a:	bf3d                	j	ffffffffc02013c8 <kmalloc.part.0+0xc0>

ffffffffc020148c <slub_ptr_cache_index>:
}

/* 返回指针所属 cache 的索引；超大对象（整页回退）或非法指针返回 -1。 */
static int
slub_ptr_cache_index(void *ptr) {
    if (ptr == NULL) {
ffffffffc020148c:	c931                	beqz	a0,ffffffffc02014e0 <slub_ptr_cache_index+0x54>
slub_ptr_cache_index(void *ptr) {
ffffffffc020148e:	1141                	addi	sp,sp,-16
ffffffffc0201490:	e406                	sd	ra,8(sp)
        return -1;
    }
    struct Page *page = pa2page(PADDR((uintptr_t)ptr));
ffffffffc0201492:	c02007b7          	lui	a5,0xc0200
ffffffffc0201496:	06f56363          	bltu	a0,a5,ffffffffc02014fc <slub_ptr_cache_index+0x70>
ffffffffc020149a:	00006697          	auipc	a3,0x6
ffffffffc020149e:	c966b683          	ld	a3,-874(a3) # ffffffffc0207130 <va_pa_offset>
ffffffffc02014a2:	8d15                	sub	a0,a0,a3
    if (PPN(pa) >= npage) {
ffffffffc02014a4:	8131                	srli	a0,a0,0xc
ffffffffc02014a6:	00006797          	auipc	a5,0x6
ffffffffc02014aa:	c627b783          	ld	a5,-926(a5) # ffffffffc0207108 <npage>
ffffffffc02014ae:	02f57b63          	bgeu	a0,a5,ffffffffc02014e4 <slub_ptr_cache_index+0x58>
    return &pages[PPN(pa) - nbase];
ffffffffc02014b2:	00002697          	auipc	a3,0x2
ffffffffc02014b6:	f566b683          	ld	a3,-170(a3) # ffffffffc0203408 <nbase>
ffffffffc02014ba:	8d15                	sub	a0,a0,a3
ffffffffc02014bc:	00251793          	slli	a5,a0,0x2
ffffffffc02014c0:	953e                	add	a0,a0,a5
ffffffffc02014c2:	050e                	slli	a0,a0,0x3
ffffffffc02014c4:	00006797          	auipc	a5,0x6
ffffffffc02014c8:	c4c7b783          	ld	a5,-948(a5) # ffffffffc0207110 <pages>
ffffffffc02014cc:	953e                	add	a0,a0,a5
    if (!PageSlab(page)) {
ffffffffc02014ce:	651c                	ld	a5,8(a0)
ffffffffc02014d0:	8b91                	andi	a5,a5,4
ffffffffc02014d2:	c789                	beqz	a5,ffffffffc02014dc <slub_ptr_cache_index+0x50>
        return -1;
    }
    return (int)page->property;
ffffffffc02014d4:	4908                	lw	a0,16(a0)
}
ffffffffc02014d6:	60a2                	ld	ra,8(sp)
ffffffffc02014d8:	0141                	addi	sp,sp,16
ffffffffc02014da:	8082                	ret
        return -1;
ffffffffc02014dc:	557d                	li	a0,-1
ffffffffc02014de:	bfe5                	j	ffffffffc02014d6 <slub_ptr_cache_index+0x4a>
ffffffffc02014e0:	557d                	li	a0,-1
}
ffffffffc02014e2:	8082                	ret
        panic("pa2page called with invalid pa");
ffffffffc02014e4:	00001617          	auipc	a2,0x1
ffffffffc02014e8:	28c60613          	addi	a2,a2,652 # ffffffffc0202770 <best_fit_pmm_manager+0x38>
ffffffffc02014ec:	06800593          	li	a1,104
ffffffffc02014f0:	00001517          	auipc	a0,0x1
ffffffffc02014f4:	2a050513          	addi	a0,a0,672 # ffffffffc0202790 <best_fit_pmm_manager+0x58>
ffffffffc02014f8:	cd3fe0ef          	jal	ra,ffffffffc02001ca <__panic>
    struct Page *page = pa2page(PADDR((uintptr_t)ptr));
ffffffffc02014fc:	86aa                	mv	a3,a0
ffffffffc02014fe:	00001617          	auipc	a2,0x1
ffffffffc0201502:	37a60613          	addi	a2,a2,890 # ffffffffc0202878 <best_fit_pmm_manager+0x140>
ffffffffc0201506:	0b400593          	li	a1,180
ffffffffc020150a:	00001517          	auipc	a0,0x1
ffffffffc020150e:	52650513          	addi	a0,a0,1318 # ffffffffc0202a30 <best_fit_pmm_manager+0x2f8>
ffffffffc0201512:	cb9fe0ef          	jal	ra,ffffffffc02001ca <__panic>

ffffffffc0201516 <slub_init>:
slub_init(void) {
ffffffffc0201516:	4741                	li	a4,16
        assert(PGSIZE % specs[i].size == 0);
ffffffffc0201518:	6605                	lui	a2,0x1
ffffffffc020151a:	02e675b3          	remu	a1,a2,a4
ffffffffc020151e:	00002697          	auipc	a3,0x2
ffffffffc0201522:	c5268693          	addi	a3,a3,-942 # ffffffffc0203170 <specs.0>
ffffffffc0201526:	00006797          	auipc	a5,0x6
ffffffffc020152a:	b0a78793          	addi	a5,a5,-1270 # ffffffffc0207030 <kmem_caches>
ffffffffc020152e:	00006817          	auipc	a6,0x6
ffffffffc0201532:	bc280813          	addi	a6,a6,-1086 # ffffffffc02070f0 <is_panic>
ffffffffc0201536:	e59d                	bnez	a1,ffffffffc0201564 <slub_init+0x4e>
        kmem_caches[i].objs_per_page = PGSIZE / specs[i].size;
ffffffffc0201538:	02e655b3          	divu	a1,a2,a4
        kmem_caches[i].name = specs[i].name;
ffffffffc020153c:	6288                	ld	a0,0(a3)
        kmem_caches[i].size = specs[i].size;
ffffffffc020153e:	e798                	sd	a4,8(a5)
        kmem_caches[i].freelist = NULL;
ffffffffc0201540:	0007bc23          	sd	zero,24(a5)
        kmem_caches[i].name = specs[i].name;
ffffffffc0201544:	e388                	sd	a0,0(a5)
        kmem_caches[i].nr_slabs = 0;
ffffffffc0201546:	0207b023          	sd	zero,32(a5)
        kmem_caches[i].nr_inuse = 0;
ffffffffc020154a:	0207b423          	sd	zero,40(a5)
    for (size_t i = 0; i < SLUB_CACHE_COUNT; i++) {
ffffffffc020154e:	03078793          	addi	a5,a5,48
ffffffffc0201552:	06c1                	addi	a3,a3,16
        kmem_caches[i].objs_per_page = PGSIZE / specs[i].size;
ffffffffc0201554:	feb7b023          	sd	a1,-32(a5)
    for (size_t i = 0; i < SLUB_CACHE_COUNT; i++) {
ffffffffc0201558:	03078863          	beq	a5,a6,ffffffffc0201588 <slub_init+0x72>
        assert(PGSIZE % specs[i].size == 0);
ffffffffc020155c:	6698                	ld	a4,8(a3)
ffffffffc020155e:	02e675b3          	remu	a1,a2,a4
ffffffffc0201562:	d9f9                	beqz	a1,ffffffffc0201538 <slub_init+0x22>
slub_init(void) {
ffffffffc0201564:	1141                	addi	sp,sp,-16
        assert(PGSIZE % specs[i].size == 0);
ffffffffc0201566:	00001697          	auipc	a3,0x1
ffffffffc020156a:	50a68693          	addi	a3,a3,1290 # ffffffffc0202a70 <best_fit_pmm_manager+0x338>
ffffffffc020156e:	00001617          	auipc	a2,0x1
ffffffffc0201572:	e8a60613          	addi	a2,a2,-374 # ffffffffc02023f8 <etext+0x26e>
ffffffffc0201576:	07600593          	li	a1,118
ffffffffc020157a:	00001517          	auipc	a0,0x1
ffffffffc020157e:	4b650513          	addi	a0,a0,1206 # ffffffffc0202a30 <best_fit_pmm_manager+0x2f8>
slub_init(void) {
ffffffffc0201582:	e406                	sd	ra,8(sp)
        assert(PGSIZE % specs[i].size == 0);
ffffffffc0201584:	c47fe0ef          	jal	ra,ffffffffc02001ca <__panic>
    cprintf("slub_init: %u caches ready (16/32/64/128 bytes), "
ffffffffc0201588:	08000613          	li	a2,128
ffffffffc020158c:	4591                	li	a1,4
ffffffffc020158e:	00001517          	auipc	a0,0x1
ffffffffc0201592:	50250513          	addi	a0,a0,1282 # ffffffffc0202a90 <best_fit_pmm_manager+0x358>
ffffffffc0201596:	bbffe06f          	j	ffffffffc0200154 <cprintf>

ffffffffc020159a <kfree>:
    if (ptr == NULL) {
ffffffffc020159a:	c551                	beqz	a0,ffffffffc0201626 <kfree+0x8c>
kfree(void *ptr) {
ffffffffc020159c:	1141                	addi	sp,sp,-16
ffffffffc020159e:	e406                	sd	ra,8(sp)
    struct Page *page = pa2page(PADDR((uintptr_t)ptr));
ffffffffc02015a0:	c02007b7          	lui	a5,0xc0200
ffffffffc02015a4:	86aa                	mv	a3,a0
ffffffffc02015a6:	08f56163          	bltu	a0,a5,ffffffffc0201628 <kfree+0x8e>
ffffffffc02015aa:	00006797          	auipc	a5,0x6
ffffffffc02015ae:	b867b783          	ld	a5,-1146(a5) # ffffffffc0207130 <va_pa_offset>
ffffffffc02015b2:	40f507b3          	sub	a5,a0,a5
    if (PPN(pa) >= npage) {
ffffffffc02015b6:	83b1                	srli	a5,a5,0xc
ffffffffc02015b8:	00006717          	auipc	a4,0x6
ffffffffc02015bc:	b5073703          	ld	a4,-1200(a4) # ffffffffc0207108 <npage>
ffffffffc02015c0:	08e7f063          	bgeu	a5,a4,ffffffffc0201640 <kfree+0xa6>
    return &pages[PPN(pa) - nbase];
ffffffffc02015c4:	00002517          	auipc	a0,0x2
ffffffffc02015c8:	e4453503          	ld	a0,-444(a0) # ffffffffc0203408 <nbase>
ffffffffc02015cc:	8f89                	sub	a5,a5,a0
ffffffffc02015ce:	00279513          	slli	a0,a5,0x2
ffffffffc02015d2:	953e                	add	a0,a0,a5
ffffffffc02015d4:	050e                	slli	a0,a0,0x3
ffffffffc02015d6:	00006797          	auipc	a5,0x6
ffffffffc02015da:	b3a7b783          	ld	a5,-1222(a5) # ffffffffc0207110 <pages>
ffffffffc02015de:	953e                	add	a0,a0,a5
    if (PageSlab(page)) {
ffffffffc02015e0:	651c                	ld	a5,8(a0)
        assert(page->property < SLUB_CACHE_COUNT);
ffffffffc02015e2:	490c                	lw	a1,16(a0)
    if (PageSlab(page)) {
ffffffffc02015e4:	8b91                	andi	a5,a5,4
ffffffffc02015e6:	cb95                	beqz	a5,ffffffffc020161a <kfree+0x80>
        assert(page->property < SLUB_CACHE_COUNT);
ffffffffc02015e8:	478d                	li	a5,3
ffffffffc02015ea:	0ab7e763          	bltu	a5,a1,ffffffffc0201698 <kfree+0xfe>
    assert(cache->nr_inuse > 0);
ffffffffc02015ee:	1582                	slli	a1,a1,0x20
ffffffffc02015f0:	9181                	srli	a1,a1,0x20
ffffffffc02015f2:	00159793          	slli	a5,a1,0x1
ffffffffc02015f6:	95be                	add	a1,a1,a5
ffffffffc02015f8:	00459793          	slli	a5,a1,0x4
ffffffffc02015fc:	00006597          	auipc	a1,0x6
ffffffffc0201600:	a3458593          	addi	a1,a1,-1484 # ffffffffc0207030 <kmem_caches>
ffffffffc0201604:	95be                	add	a1,a1,a5
ffffffffc0201606:	759c                	ld	a5,40(a1)
ffffffffc0201608:	cba1                	beqz	a5,ffffffffc0201658 <kfree+0xbe>
    *(void **)obj = cache->freelist;
ffffffffc020160a:	6d98                	ld	a4,24(a1)
}
ffffffffc020160c:	60a2                	ld	ra,8(sp)
    cache->nr_inuse--;
ffffffffc020160e:	17fd                	addi	a5,a5,-1
    *(void **)obj = cache->freelist;
ffffffffc0201610:	e298                	sd	a4,0(a3)
    cache->freelist = obj;
ffffffffc0201612:	ed94                	sd	a3,24(a1)
    cache->nr_inuse--;
ffffffffc0201614:	f59c                	sd	a5,40(a1)
}
ffffffffc0201616:	0141                	addi	sp,sp,16
ffffffffc0201618:	8082                	ret
        size_t n = page->property;
ffffffffc020161a:	1582                	slli	a1,a1,0x20
ffffffffc020161c:	9181                	srli	a1,a1,0x20
        assert(n > 0);
ffffffffc020161e:	cda9                	beqz	a1,ffffffffc0201678 <kfree+0xde>
}
ffffffffc0201620:	60a2                	ld	ra,8(sp)
ffffffffc0201622:	0141                	addi	sp,sp,16
        free_pages(page, n);
ffffffffc0201624:	bc3d                	j	ffffffffc0201062 <free_pages>
ffffffffc0201626:	8082                	ret
    struct Page *page = pa2page(PADDR((uintptr_t)ptr));
ffffffffc0201628:	00001617          	auipc	a2,0x1
ffffffffc020162c:	25060613          	addi	a2,a2,592 # ffffffffc0202878 <best_fit_pmm_manager+0x140>
ffffffffc0201630:	0a300593          	li	a1,163
ffffffffc0201634:	00001517          	auipc	a0,0x1
ffffffffc0201638:	3fc50513          	addi	a0,a0,1020 # ffffffffc0202a30 <best_fit_pmm_manager+0x2f8>
ffffffffc020163c:	b8ffe0ef          	jal	ra,ffffffffc02001ca <__panic>
        panic("pa2page called with invalid pa");
ffffffffc0201640:	00001617          	auipc	a2,0x1
ffffffffc0201644:	13060613          	addi	a2,a2,304 # ffffffffc0202770 <best_fit_pmm_manager+0x38>
ffffffffc0201648:	06800593          	li	a1,104
ffffffffc020164c:	00001517          	auipc	a0,0x1
ffffffffc0201650:	14450513          	addi	a0,a0,324 # ffffffffc0202790 <best_fit_pmm_manager+0x58>
ffffffffc0201654:	b77fe0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert(cache->nr_inuse > 0);
ffffffffc0201658:	00001697          	auipc	a3,0x1
ffffffffc020165c:	4b868693          	addi	a3,a3,1208 # ffffffffc0202b10 <best_fit_pmm_manager+0x3d8>
ffffffffc0201660:	00001617          	auipc	a2,0x1
ffffffffc0201664:	d9860613          	addi	a2,a2,-616 # ffffffffc02023f8 <etext+0x26e>
ffffffffc0201668:	06300593          	li	a1,99
ffffffffc020166c:	00001517          	auipc	a0,0x1
ffffffffc0201670:	3c450513          	addi	a0,a0,964 # ffffffffc0202a30 <best_fit_pmm_manager+0x2f8>
ffffffffc0201674:	b57fe0ef          	jal	ra,ffffffffc02001ca <__panic>
        assert(n > 0);
ffffffffc0201678:	00001697          	auipc	a3,0x1
ffffffffc020167c:	d7868693          	addi	a3,a3,-648 # ffffffffc02023f0 <etext+0x266>
ffffffffc0201680:	00001617          	auipc	a2,0x1
ffffffffc0201684:	d7860613          	addi	a2,a2,-648 # ffffffffc02023f8 <etext+0x26e>
ffffffffc0201688:	0a900593          	li	a1,169
ffffffffc020168c:	00001517          	auipc	a0,0x1
ffffffffc0201690:	3a450513          	addi	a0,a0,932 # ffffffffc0202a30 <best_fit_pmm_manager+0x2f8>
ffffffffc0201694:	b37fe0ef          	jal	ra,ffffffffc02001ca <__panic>
        assert(page->property < SLUB_CACHE_COUNT);
ffffffffc0201698:	00001697          	auipc	a3,0x1
ffffffffc020169c:	45068693          	addi	a3,a3,1104 # ffffffffc0202ae8 <best_fit_pmm_manager+0x3b0>
ffffffffc02016a0:	00001617          	auipc	a2,0x1
ffffffffc02016a4:	d5860613          	addi	a2,a2,-680 # ffffffffc02023f8 <etext+0x26e>
ffffffffc02016a8:	0a500593          	li	a1,165
ffffffffc02016ac:	00001517          	auipc	a0,0x1
ffffffffc02016b0:	38450513          	addi	a0,a0,900 # ffffffffc0202a30 <best_fit_pmm_manager+0x2f8>
ffffffffc02016b4:	b17fe0ef          	jal	ra,ffffffffc02001ca <__panic>

ffffffffc02016b8 <check_stress>:
    cprintf("slub_check: PASS boundary (0B, NULL, 2000B, 5000B)\n");
}

/* 用例 4：压力测试——100 个 64B 对象反复取放，页数应稳定、无泄漏。 */
static void
check_stress(void) {
ffffffffc02016b8:	ca010113          	addi	sp,sp,-864
ffffffffc02016bc:	34813823          	sd	s0,848(sp)
ffffffffc02016c0:	840a                	mv	s0,sp
ffffffffc02016c2:	34913423          	sd	s1,840(sp)
ffffffffc02016c6:	35213023          	sd	s2,832(sp)
ffffffffc02016ca:	33313c23          	sd	s3,824(sp)
ffffffffc02016ce:	34113c23          	sd	ra,856(sp)
ffffffffc02016d2:	33413823          	sd	s4,816(sp)
ffffffffc02016d6:	33513423          	sd	s5,808(sp)
ffffffffc02016da:	33613023          	sd	s6,800(sp)
    enum { kNum = 100 };
    void *objs[kNum];

    size_t before = nr_free_pages();
ffffffffc02016de:	8922                	mv	s2,s0
ffffffffc02016e0:	98fff0ef          	jal	ra,ffffffffc020106e <nr_free_pages>
    for (int i = 0; i < kNum; i++) {
ffffffffc02016e4:	4481                	li	s1,0
ffffffffc02016e6:	06400993          	li	s3,100
    if (size == 0) {
ffffffffc02016ea:	04000513          	li	a0,64
ffffffffc02016ee:	c1bff0ef          	jal	ra,ffffffffc0201308 <kmalloc.part.0>
        objs[i] = kmalloc(64);
ffffffffc02016f2:	00a93023          	sd	a0,0(s2)
        if (objs[i] == NULL) {
ffffffffc02016f6:	12050963          	beqz	a0,ffffffffc0201828 <check_stress+0x170>
            panic("slub_check: kmalloc(64) returned NULL at #%d", i);
        }
        memset(objs[i], i & 0xFF, 64);
ffffffffc02016fa:	0ff4f593          	zext.b	a1,s1
ffffffffc02016fe:	04000613          	li	a2,64
    for (int i = 0; i < kNum; i++) {
ffffffffc0201702:	2485                	addiw	s1,s1,1
        memset(objs[i], i & 0xFF, 64);
ffffffffc0201704:	275000ef          	jal	ra,ffffffffc0202178 <memset>
    for (int i = 0; i < kNum; i++) {
ffffffffc0201708:	0921                	addi	s2,s2,8
ffffffffc020170a:	ff3490e3          	bne	s1,s3,ffffffffc02016ea <check_stress+0x32>
ffffffffc020170e:	0024                	addi	s1,sp,8
ffffffffc0201710:	4581                	li	a1,0
    }
    /* 两两不同（不重叠）。 */
    for (int i = 0; i < kNum; i++) {
        for (int j = i + 1; j < kNum; j++) {
ffffffffc0201712:	06300813          	li	a6,99
    for (int i = 0; i < kNum; i++) {
ffffffffc0201716:	8526                	mv	a0,s1
ffffffffc0201718:	06200313          	li	t1,98
ffffffffc020171c:	01040893          	addi	a7,s0,16
        for (int j = i + 1; j < kNum; j++) {
ffffffffc0201720:	0005879b          	sext.w	a5,a1
ffffffffc0201724:	03058863          	beq	a1,a6,ffffffffc0201754 <check_stress+0x9c>
ffffffffc0201728:	40f306bb          	subw	a3,t1,a5
ffffffffc020172c:	1682                	slli	a3,a3,0x20
ffffffffc020172e:	9281                	srli	a3,a3,0x20
ffffffffc0201730:	96ae                	add	a3,a3,a1
            if (objs[i] == objs[j]) {
ffffffffc0201732:	ff853603          	ld	a2,-8(a0)
ffffffffc0201736:	068e                	slli	a3,a3,0x3
ffffffffc0201738:	96c6                	add	a3,a3,a7
ffffffffc020173a:	87aa                	mv	a5,a0
ffffffffc020173c:	6398                	ld	a4,0(a5)
ffffffffc020173e:	0ce60963          	beq	a2,a4,ffffffffc0201810 <check_stress+0x158>
        for (int j = i + 1; j < kNum; j++) {
ffffffffc0201742:	07a1                	addi	a5,a5,8
ffffffffc0201744:	fed79ce3          	bne	a5,a3,ffffffffc020173c <check_stress+0x84>
ffffffffc0201748:	0585                	addi	a1,a1,1
ffffffffc020174a:	0521                	addi	a0,a0,8
ffffffffc020174c:	0005879b          	sext.w	a5,a1
ffffffffc0201750:	fd059ce3          	bne	a1,a6,ffffffffc0201728 <check_stress+0x70>
ffffffffc0201754:	8722                	mv	a4,s0
                panic("slub_check: stress duplicate pointer");
            }
        }
    }
    for (int i = 0; i < kNum; i++) {
ffffffffc0201756:	4681                	li	a3,0
ffffffffc0201758:	06400593          	li	a1,100
        if (*(unsigned char *)objs[i] != (unsigned char)(i & 0xFF)) {
ffffffffc020175c:	6310                	ld	a2,0(a4)
ffffffffc020175e:	0ff6f793          	zext.b	a5,a3
ffffffffc0201762:	00064603          	lbu	a2,0(a2)
ffffffffc0201766:	14f61b63          	bne	a2,a5,ffffffffc02018bc <check_stress+0x204>
    for (int i = 0; i < kNum; i++) {
ffffffffc020176a:	2685                	addiw	a3,a3,1
ffffffffc020176c:	0721                	addi	a4,a4,8
ffffffffc020176e:	feb697e3          	bne	a3,a1,ffffffffc020175c <check_stress+0xa4>
            panic("slub_check: stress write/read-back failed at #%d", i);
        }
    }
    size_t held = nr_free_pages();  // 首次取满后，cache 持有的 slab 页已稳定
ffffffffc0201772:	8fdff0ef          	jal	ra,ffffffffc020106e <nr_free_pages>
    void *first_last = objs[kNum - 1];  // 第一轮最后释放的对象，应是复用时的栈顶
ffffffffc0201776:	31813b03          	ld	s6,792(sp)
    size_t held = nr_free_pages();  // 首次取满后，cache 持有的 slab 页已稳定
ffffffffc020177a:	8aaa                	mv	s5,a0

    /* 全部释放：缓存对象不归还 Buddy，页数应保持不变。 */
    for (int i = 0; i < kNum; i++) {
ffffffffc020177c:	32040993          	addi	s3,s0,800
    void *first_last = objs[kNum - 1];  // 第一轮最后释放的对象，应是复用时的栈顶
ffffffffc0201780:	8922                	mv	s2,s0
        kfree(objs[i]);
ffffffffc0201782:	00093503          	ld	a0,0(s2)
    for (int i = 0; i < kNum; i++) {
ffffffffc0201786:	0921                	addi	s2,s2,8
        kfree(objs[i]);
ffffffffc0201788:	e13ff0ef          	jal	ra,ffffffffc020159a <kfree>
    for (int i = 0; i < kNum; i++) {
ffffffffc020178c:	ff299be3          	bne	s3,s2,ffffffffc0201782 <check_stress+0xca>
    }
    if (nr_free_pages() != held) {
ffffffffc0201790:	8dfff0ef          	jal	ra,ffffffffc020106e <nr_free_pages>
        panic("slub_check: freeing cached objects changed page count");
    }

    /* 再次申请 100 个：应完全复用已缓存对象，不再消耗新页。 */
    for (int i = 0; i < kNum; i++) {
ffffffffc0201794:	4901                	li	s2,0
ffffffffc0201796:	06400a13          	li	s4,100
    if (nr_free_pages() != held) {
ffffffffc020179a:	11551563          	bne	a0,s5,ffffffffc02018a4 <check_stress+0x1ec>
    if (size == 0) {
ffffffffc020179e:	04000513          	li	a0,64
ffffffffc02017a2:	b67ff0ef          	jal	ra,ffffffffc0201308 <kmalloc.part.0>
        objs[i] = kmalloc(64);
ffffffffc02017a6:	e008                	sd	a0,0(s0)
        if (objs[i] == NULL) {
ffffffffc02017a8:	0e050163          	beqz	a0,ffffffffc020188a <check_stress+0x1d2>
    for (int i = 0; i < kNum; i++) {
ffffffffc02017ac:	2905                	addiw	s2,s2,1
ffffffffc02017ae:	0421                	addi	s0,s0,8
ffffffffc02017b0:	ff4917e3          	bne	s2,s4,ffffffffc020179e <check_stress+0xe6>
            panic("slub_check: second round kmalloc returned NULL at #%d", i);
        }
    }
    if (nr_free_pages() != held) {
ffffffffc02017b4:	8bbff0ef          	jal	ra,ffffffffc020106e <nr_free_pages>
ffffffffc02017b8:	0b551d63          	bne	a0,s5,ffffffffc0201872 <check_stress+0x1ba>
        panic("slub_check: second round consumed extra pages (leak)");
    }
    if (objs[0] != first_last) {
ffffffffc02017bc:	6502                	ld	a0,0(sp)
ffffffffc02017be:	01650563          	beq	a0,s6,ffffffffc02017c8 <check_stress+0x110>
ffffffffc02017c2:	a861                	j	ffffffffc020185a <check_stress+0x1a2>
        panic("slub_check: cached objects not reused (expected LIFO)");
    }
    for (int i = 0; i < kNum; i++) {
        kfree(objs[i]);
ffffffffc02017c4:	6088                	ld	a0,0(s1)
ffffffffc02017c6:	04a1                	addi	s1,s1,8
ffffffffc02017c8:	dd3ff0ef          	jal	ra,ffffffffc020159a <kfree>
    for (int i = 0; i < kNum; i++) {
ffffffffc02017cc:	fe999ce3          	bne	s3,s1,ffffffffc02017c4 <check_stress+0x10c>
    }
    if (nr_free_pages() != held) {
ffffffffc02017d0:	89fff0ef          	jal	ra,ffffffffc020106e <nr_free_pages>
ffffffffc02017d4:	07551763          	bne	a0,s5,ffffffffc0201842 <check_stress+0x18a>
        panic("slub_check: page count changed after second free");
    }

    cprintf("slub_check: PASS stress (100 x 64B, %lu slab page(s), no leak)\n",
            (unsigned long)kmem_caches[SLUB_CACHE_64].nr_slabs);
}
ffffffffc02017d8:	35013403          	ld	s0,848(sp)
ffffffffc02017dc:	35813083          	ld	ra,856(sp)
ffffffffc02017e0:	34813483          	ld	s1,840(sp)
ffffffffc02017e4:	34013903          	ld	s2,832(sp)
ffffffffc02017e8:	33813983          	ld	s3,824(sp)
ffffffffc02017ec:	33013a03          	ld	s4,816(sp)
ffffffffc02017f0:	32813a83          	ld	s5,808(sp)
ffffffffc02017f4:	32013b03          	ld	s6,800(sp)
    cprintf("slub_check: PASS stress (100 x 64B, %lu slab page(s), no leak)\n",
ffffffffc02017f8:	00006597          	auipc	a1,0x6
ffffffffc02017fc:	8b85b583          	ld	a1,-1864(a1) # ffffffffc02070b0 <kmem_caches+0x80>
ffffffffc0201800:	00001517          	auipc	a0,0x1
ffffffffc0201804:	4d050513          	addi	a0,a0,1232 # ffffffffc0202cd0 <best_fit_pmm_manager+0x598>
}
ffffffffc0201808:	36010113          	addi	sp,sp,864
    cprintf("slub_check: PASS stress (100 x 64B, %lu slab page(s), no leak)\n",
ffffffffc020180c:	949fe06f          	j	ffffffffc0200154 <cprintf>
                panic("slub_check: stress duplicate pointer");
ffffffffc0201810:	00001617          	auipc	a2,0x1
ffffffffc0201814:	34860613          	addi	a2,a2,840 # ffffffffc0202b58 <best_fit_pmm_manager+0x420>
ffffffffc0201818:	15300593          	li	a1,339
ffffffffc020181c:	00001517          	auipc	a0,0x1
ffffffffc0201820:	21450513          	addi	a0,a0,532 # ffffffffc0202a30 <best_fit_pmm_manager+0x2f8>
ffffffffc0201824:	9a7fe0ef          	jal	ra,ffffffffc02001ca <__panic>
            panic("slub_check: kmalloc(64) returned NULL at #%d", i);
ffffffffc0201828:	86a6                	mv	a3,s1
ffffffffc020182a:	00001617          	auipc	a2,0x1
ffffffffc020182e:	2fe60613          	addi	a2,a2,766 # ffffffffc0202b28 <best_fit_pmm_manager+0x3f0>
ffffffffc0201832:	14b00593          	li	a1,331
ffffffffc0201836:	00001517          	auipc	a0,0x1
ffffffffc020183a:	1fa50513          	addi	a0,a0,506 # ffffffffc0202a30 <best_fit_pmm_manager+0x2f8>
ffffffffc020183e:	98dfe0ef          	jal	ra,ffffffffc02001ca <__panic>
        panic("slub_check: page count changed after second free");
ffffffffc0201842:	00001617          	auipc	a2,0x1
ffffffffc0201846:	45660613          	addi	a2,a2,1110 # ffffffffc0202c98 <best_fit_pmm_manager+0x560>
ffffffffc020184a:	17800593          	li	a1,376
ffffffffc020184e:	00001517          	auipc	a0,0x1
ffffffffc0201852:	1e250513          	addi	a0,a0,482 # ffffffffc0202a30 <best_fit_pmm_manager+0x2f8>
ffffffffc0201856:	975fe0ef          	jal	ra,ffffffffc02001ca <__panic>
        panic("slub_check: cached objects not reused (expected LIFO)");
ffffffffc020185a:	00001617          	auipc	a2,0x1
ffffffffc020185e:	40660613          	addi	a2,a2,1030 # ffffffffc0202c60 <best_fit_pmm_manager+0x528>
ffffffffc0201862:	17200593          	li	a1,370
ffffffffc0201866:	00001517          	auipc	a0,0x1
ffffffffc020186a:	1ca50513          	addi	a0,a0,458 # ffffffffc0202a30 <best_fit_pmm_manager+0x2f8>
ffffffffc020186e:	95dfe0ef          	jal	ra,ffffffffc02001ca <__panic>
        panic("slub_check: second round consumed extra pages (leak)");
ffffffffc0201872:	00001617          	auipc	a2,0x1
ffffffffc0201876:	3b660613          	addi	a2,a2,950 # ffffffffc0202c28 <best_fit_pmm_manager+0x4f0>
ffffffffc020187a:	16f00593          	li	a1,367
ffffffffc020187e:	00001517          	auipc	a0,0x1
ffffffffc0201882:	1b250513          	addi	a0,a0,434 # ffffffffc0202a30 <best_fit_pmm_manager+0x2f8>
ffffffffc0201886:	945fe0ef          	jal	ra,ffffffffc02001ca <__panic>
            panic("slub_check: second round kmalloc returned NULL at #%d", i);
ffffffffc020188a:	86ca                	mv	a3,s2
ffffffffc020188c:	00001617          	auipc	a2,0x1
ffffffffc0201890:	36460613          	addi	a2,a2,868 # ffffffffc0202bf0 <best_fit_pmm_manager+0x4b8>
ffffffffc0201894:	16b00593          	li	a1,363
ffffffffc0201898:	00001517          	auipc	a0,0x1
ffffffffc020189c:	19850513          	addi	a0,a0,408 # ffffffffc0202a30 <best_fit_pmm_manager+0x2f8>
ffffffffc02018a0:	92bfe0ef          	jal	ra,ffffffffc02001ca <__panic>
        panic("slub_check: freeing cached objects changed page count");
ffffffffc02018a4:	00001617          	auipc	a2,0x1
ffffffffc02018a8:	31460613          	addi	a2,a2,788 # ffffffffc0202bb8 <best_fit_pmm_manager+0x480>
ffffffffc02018ac:	16400593          	li	a1,356
ffffffffc02018b0:	00001517          	auipc	a0,0x1
ffffffffc02018b4:	18050513          	addi	a0,a0,384 # ffffffffc0202a30 <best_fit_pmm_manager+0x2f8>
ffffffffc02018b8:	913fe0ef          	jal	ra,ffffffffc02001ca <__panic>
            panic("slub_check: stress write/read-back failed at #%d", i);
ffffffffc02018bc:	00001617          	auipc	a2,0x1
ffffffffc02018c0:	2c460613          	addi	a2,a2,708 # ffffffffc0202b80 <best_fit_pmm_manager+0x448>
ffffffffc02018c4:	15900593          	li	a1,345
ffffffffc02018c8:	00001517          	auipc	a0,0x1
ffffffffc02018cc:	16850513          	addi	a0,a0,360 # ffffffffc0202a30 <best_fit_pmm_manager+0x2f8>
ffffffffc02018d0:	8fbfe0ef          	jal	ra,ffffffffc02001ca <__panic>

ffffffffc02018d4 <slub_check>:

void
slub_check(void) {
ffffffffc02018d4:	711d                	addi	sp,sp,-96
ffffffffc02018d6:	ec86                	sd	ra,88(sp)
ffffffffc02018d8:	e8a2                	sd	s0,80(sp)
ffffffffc02018da:	e4a6                	sd	s1,72(sp)
ffffffffc02018dc:	e0ca                	sd	s2,64(sp)
ffffffffc02018de:	fc4e                	sd	s3,56(sp)
ffffffffc02018e0:	f852                	sd	s4,48(sp)
    cprintf("slub_check: begin (free pages = %lu)\n",
            (unsigned long)nr_free_pages());
ffffffffc02018e2:	f8cff0ef          	jal	ra,ffffffffc020106e <nr_free_pages>
ffffffffc02018e6:	85aa                	mv	a1,a0
ffffffffc02018e8:	0020                	addi	s0,sp,8
    cprintf("slub_check: begin (free pages = %lu)\n",
ffffffffc02018ea:	00001517          	auipc	a0,0x1
ffffffffc02018ee:	42650513          	addi	a0,a0,1062 # ffffffffc0202d10 <best_fit_pmm_manager+0x5d8>
ffffffffc02018f2:	863fe0ef          	jal	ra,ffffffffc0200154 <cprintf>
ffffffffc02018f6:	8922                	mv	s2,s0
    for (size_t i = 0; i < kNum; i++) {
ffffffffc02018f8:	4481                	li	s1,0
ffffffffc02018fa:	4995                	li	s3,5
    if (size == 0) {
ffffffffc02018fc:	02000513          	li	a0,32
ffffffffc0201900:	a09ff0ef          	jal	ra,ffffffffc0201308 <kmalloc.part.0>
        objs[i] = kmalloc(32);
ffffffffc0201904:	00a93023          	sd	a0,0(s2)
        if (objs[i] == NULL) {
ffffffffc0201908:	2c050563          	beqz	a0,ffffffffc0201bd2 <slub_check+0x2fe>
    for (size_t i = 0; i < kNum; i++) {
ffffffffc020190c:	0485                	addi	s1,s1,1
ffffffffc020190e:	0921                	addi	s2,s2,8
ffffffffc0201910:	ff3496e3          	bne	s1,s3,ffffffffc02018fc <slub_check+0x28>
ffffffffc0201914:	01010813          	addi	a6,sp,16
        for (size_t j = i + 1; j < kNum; j++) {
ffffffffc0201918:	4885                	li	a7,1
ffffffffc020191a:	4515                	li	a0,5
            if (objs[i] == objs[j]) {
ffffffffc020191c:	ff883603          	ld	a2,-8(a6)
ffffffffc0201920:	86c2                	mv	a3,a6
ffffffffc0201922:	8746                	mv	a4,a7
            if (!((uintptr_t)objs[i] + 32 <= (uintptr_t)objs[j] ||
ffffffffc0201924:	02060593          	addi	a1,a2,32
            if (objs[i] == objs[j]) {
ffffffffc0201928:	629c                	ld	a5,0(a3)
ffffffffc020192a:	24c78463          	beq	a5,a2,ffffffffc0201b72 <slub_check+0x29e>
            if (!((uintptr_t)objs[i] + 32 <= (uintptr_t)objs[j] ||
ffffffffc020192e:	00b7f663          	bgeu	a5,a1,ffffffffc020193a <slub_check+0x66>
                  (uintptr_t)objs[j] + 32 <= (uintptr_t)objs[i])) {
ffffffffc0201932:	02078793          	addi	a5,a5,32
            if (!((uintptr_t)objs[i] + 32 <= (uintptr_t)objs[j] ||
ffffffffc0201936:	24f66a63          	bltu	a2,a5,ffffffffc0201b8a <slub_check+0x2b6>
        for (size_t j = i + 1; j < kNum; j++) {
ffffffffc020193a:	0705                	addi	a4,a4,1
ffffffffc020193c:	06a1                	addi	a3,a3,8
ffffffffc020193e:	fea715e3          	bne	a4,a0,ffffffffc0201928 <slub_check+0x54>
ffffffffc0201942:	0885                	addi	a7,a7,1
ffffffffc0201944:	0821                	addi	a6,a6,8
ffffffffc0201946:	fce89be3          	bne	a7,a4,ffffffffc020191c <slub_check+0x48>
    void *freed = objs[2];
ffffffffc020194a:	64e2                	ld	s1,24(sp)
    kfree(freed);
ffffffffc020194c:	8526                	mv	a0,s1
ffffffffc020194e:	c4dff0ef          	jal	ra,ffffffffc020159a <kfree>
    if (size == 0) {
ffffffffc0201952:	02000513          	li	a0,32
ffffffffc0201956:	9b3ff0ef          	jal	ra,ffffffffc0201308 <kmalloc.part.0>
    if (again != freed) {
ffffffffc020195a:	34a49a63          	bne	s1,a0,ffffffffc0201cae <slub_check+0x3da>
    kfree(again);
ffffffffc020195e:	c3dff0ef          	jal	ra,ffffffffc020159a <kfree>
    for (size_t i = 0; i < kNum; i++) {
ffffffffc0201962:	4781                	li	a5,0
        if (i != 2) {
ffffffffc0201964:	4a09                	li	s4,2
    for (size_t i = 0; i < kNum; i++) {
ffffffffc0201966:	4915                	li	s2,5
ffffffffc0201968:	00178493          	addi	s1,a5,1
        if (i != 2) {
ffffffffc020196c:	01478763          	beq	a5,s4,ffffffffc020197a <slub_check+0xa6>
            kfree(objs[i]);
ffffffffc0201970:	6008                	ld	a0,0(s0)
ffffffffc0201972:	c29ff0ef          	jal	ra,ffffffffc020159a <kfree>
    for (size_t i = 0; i < kNum; i++) {
ffffffffc0201976:	01248d63          	beq	s1,s2,ffffffffc0201990 <slub_check+0xbc>
ffffffffc020197a:	87a6                	mv	a5,s1
ffffffffc020197c:	0421                	addi	s0,s0,8
ffffffffc020197e:	00178493          	addi	s1,a5,1
        if (i != 2) {
ffffffffc0201982:	ff478ce3          	beq	a5,s4,ffffffffc020197a <slub_check+0xa6>
            kfree(objs[i]);
ffffffffc0201986:	6008                	ld	a0,0(s0)
ffffffffc0201988:	c13ff0ef          	jal	ra,ffffffffc020159a <kfree>
    for (size_t i = 0; i < kNum; i++) {
ffffffffc020198c:	ff2497e3          	bne	s1,s2,ffffffffc020197a <slub_check+0xa6>
    cprintf("slub_check: PASS basic alloc/free + reuse (5 x 32B)\n");
ffffffffc0201990:	00001517          	auipc	a0,0x1
ffffffffc0201994:	47850513          	addi	a0,a0,1144 # ffffffffc0202e08 <best_fit_pmm_manager+0x6d0>
ffffffffc0201998:	fbcfe0ef          	jal	ra,ffffffffc0200154 <cprintf>
    if (size == 0) {
ffffffffc020199c:	4541                	li	a0,16
ffffffffc020199e:	96bff0ef          	jal	ra,ffffffffc0201308 <kmalloc.part.0>
ffffffffc02019a2:	89aa                	mv	s3,a0
ffffffffc02019a4:	02000513          	li	a0,32
ffffffffc02019a8:	961ff0ef          	jal	ra,ffffffffc0201308 <kmalloc.part.0>
ffffffffc02019ac:	892a                	mv	s2,a0
ffffffffc02019ae:	04000513          	li	a0,64
ffffffffc02019b2:	957ff0ef          	jal	ra,ffffffffc0201308 <kmalloc.part.0>
ffffffffc02019b6:	84aa                	mv	s1,a0
ffffffffc02019b8:	08000513          	li	a0,128
ffffffffc02019bc:	94dff0ef          	jal	ra,ffffffffc0201308 <kmalloc.part.0>
ffffffffc02019c0:	842a                	mv	s0,a0
    if (p16 == NULL || p32 == NULL || p64 == NULL || p128 == NULL) {
ffffffffc02019c2:	30098e63          	beqz	s3,ffffffffc0201cde <slub_check+0x40a>
ffffffffc02019c6:	30090c63          	beqz	s2,ffffffffc0201cde <slub_check+0x40a>
ffffffffc02019ca:	30048a63          	beqz	s1,ffffffffc0201cde <slub_check+0x40a>
ffffffffc02019ce:	30050863          	beqz	a0,ffffffffc0201cde <slub_check+0x40a>
    if (slub_ptr_cache_index(p16) != SLUB_CACHE_16 ||
ffffffffc02019d2:	854e                	mv	a0,s3
ffffffffc02019d4:	ab9ff0ef          	jal	ra,ffffffffc020148c <slub_ptr_cache_index>
ffffffffc02019d8:	2e051763          	bnez	a0,ffffffffc0201cc6 <slub_check+0x3f2>
        slub_ptr_cache_index(p32) != SLUB_CACHE_32 ||
ffffffffc02019dc:	854a                	mv	a0,s2
ffffffffc02019de:	aafff0ef          	jal	ra,ffffffffc020148c <slub_ptr_cache_index>
    if (slub_ptr_cache_index(p16) != SLUB_CACHE_16 ||
ffffffffc02019e2:	4785                	li	a5,1
ffffffffc02019e4:	2ef51163          	bne	a0,a5,ffffffffc0201cc6 <slub_check+0x3f2>
        slub_ptr_cache_index(p64) != SLUB_CACHE_64 ||
ffffffffc02019e8:	8526                	mv	a0,s1
ffffffffc02019ea:	aa3ff0ef          	jal	ra,ffffffffc020148c <slub_ptr_cache_index>
        slub_ptr_cache_index(p32) != SLUB_CACHE_32 ||
ffffffffc02019ee:	2d451c63          	bne	a0,s4,ffffffffc0201cc6 <slub_check+0x3f2>
        slub_ptr_cache_index(p128) != SLUB_CACHE_128) {
ffffffffc02019f2:	8522                	mv	a0,s0
ffffffffc02019f4:	a99ff0ef          	jal	ra,ffffffffc020148c <slub_ptr_cache_index>
        slub_ptr_cache_index(p64) != SLUB_CACHE_64 ||
ffffffffc02019f8:	478d                	li	a5,3
ffffffffc02019fa:	2cf51663          	bne	a0,a5,ffffffffc0201cc6 <slub_check+0x3f2>
    memset(p16, 0x11, 16);
ffffffffc02019fe:	4641                	li	a2,16
ffffffffc0201a00:	45c5                	li	a1,17
ffffffffc0201a02:	854e                	mv	a0,s3
ffffffffc0201a04:	774000ef          	jal	ra,ffffffffc0202178 <memset>
    memset(p32, 0x22, 32);
ffffffffc0201a08:	02000613          	li	a2,32
ffffffffc0201a0c:	02200593          	li	a1,34
ffffffffc0201a10:	854a                	mv	a0,s2
ffffffffc0201a12:	766000ef          	jal	ra,ffffffffc0202178 <memset>
    memset(p64, 0x33, 64);
ffffffffc0201a16:	04000613          	li	a2,64
ffffffffc0201a1a:	03300593          	li	a1,51
ffffffffc0201a1e:	8526                	mv	a0,s1
ffffffffc0201a20:	758000ef          	jal	ra,ffffffffc0202178 <memset>
    memset(p128, 0x44, 128);
ffffffffc0201a24:	08000613          	li	a2,128
ffffffffc0201a28:	04400593          	li	a1,68
ffffffffc0201a2c:	8522                	mv	a0,s0
ffffffffc0201a2e:	74a000ef          	jal	ra,ffffffffc0202178 <memset>
    if (*(unsigned char *)p16 != 0x11 ||
ffffffffc0201a32:	0009c703          	lbu	a4,0(s3)
ffffffffc0201a36:	47c5                	li	a5,17
ffffffffc0201a38:	24f71f63          	bne	a4,a5,ffffffffc0201c96 <slub_check+0x3c2>
ffffffffc0201a3c:	00094703          	lbu	a4,0(s2)
ffffffffc0201a40:	02200793          	li	a5,34
ffffffffc0201a44:	24f71963          	bne	a4,a5,ffffffffc0201c96 <slub_check+0x3c2>
        *(unsigned char *)p32 != 0x22 ||
ffffffffc0201a48:	0004c703          	lbu	a4,0(s1)
ffffffffc0201a4c:	03300793          	li	a5,51
ffffffffc0201a50:	24f71363          	bne	a4,a5,ffffffffc0201c96 <slub_check+0x3c2>
        *(unsigned char *)p64 != 0x33 ||
ffffffffc0201a54:	00044703          	lbu	a4,0(s0)
ffffffffc0201a58:	04400793          	li	a5,68
ffffffffc0201a5c:	22f71d63          	bne	a4,a5,ffffffffc0201c96 <slub_check+0x3c2>
    kfree(p16);
ffffffffc0201a60:	854e                	mv	a0,s3
ffffffffc0201a62:	b39ff0ef          	jal	ra,ffffffffc020159a <kfree>
    kfree(p32);
ffffffffc0201a66:	854a                	mv	a0,s2
ffffffffc0201a68:	b33ff0ef          	jal	ra,ffffffffc020159a <kfree>
    kfree(p64);
ffffffffc0201a6c:	8526                	mv	a0,s1
ffffffffc0201a6e:	b2dff0ef          	jal	ra,ffffffffc020159a <kfree>
    kfree(p128);
ffffffffc0201a72:	8522                	mv	a0,s0
ffffffffc0201a74:	b27ff0ef          	jal	ra,ffffffffc020159a <kfree>
    cprintf("slub_check: PASS different caches (16/32/64/128B)\n");
ffffffffc0201a78:	00001517          	auipc	a0,0x1
ffffffffc0201a7c:	46850513          	addi	a0,a0,1128 # ffffffffc0202ee0 <best_fit_pmm_manager+0x7a8>
ffffffffc0201a80:	ed4fe0ef          	jal	ra,ffffffffc0200154 <cprintf>
    if (size == 0) {
ffffffffc0201a84:	4541                	li	a0,16
ffffffffc0201a86:	883ff0ef          	jal	ra,ffffffffc0201308 <kmalloc.part.0>
    if (probe == NULL) {
ffffffffc0201a8a:	1c050263          	beqz	a0,ffffffffc0201c4e <slub_check+0x37a>
    kfree(probe);
ffffffffc0201a8e:	b0dff0ef          	jal	ra,ffffffffc020159a <kfree>
    size_t before = nr_free_pages();
ffffffffc0201a92:	ddcff0ef          	jal	ra,ffffffffc020106e <nr_free_pages>
ffffffffc0201a96:	892a                	mv	s2,a0
ffffffffc0201a98:	7d000513          	li	a0,2000
    if (size == 0) {
ffffffffc0201a9c:	86dff0ef          	jal	ra,ffffffffc0201308 <kmalloc.part.0>
ffffffffc0201aa0:	842a                	mv	s0,a0
    if (big == NULL) {
ffffffffc0201aa2:	1c050e63          	beqz	a0,ffffffffc0201c7e <slub_check+0x3aa>
    if (slub_ptr_cache_index(big) != -1) {
ffffffffc0201aa6:	9e7ff0ef          	jal	ra,ffffffffc020148c <slub_ptr_cache_index>
ffffffffc0201aaa:	57fd                	li	a5,-1
ffffffffc0201aac:	84aa                	mv	s1,a0
ffffffffc0201aae:	1af51c63          	bne	a0,a5,ffffffffc0201c66 <slub_check+0x392>
    memset(big, 0x5A, 2000);
ffffffffc0201ab2:	7d000613          	li	a2,2000
ffffffffc0201ab6:	05a00593          	li	a1,90
ffffffffc0201aba:	8522                	mv	a0,s0
ffffffffc0201abc:	6bc000ef          	jal	ra,ffffffffc0202178 <memset>
    if (*(unsigned char *)big != 0x5A) {
ffffffffc0201ac0:	00044703          	lbu	a4,0(s0)
ffffffffc0201ac4:	05a00793          	li	a5,90
ffffffffc0201ac8:	0ef71963          	bne	a4,a5,ffffffffc0201bba <slub_check+0x2e6>
    kfree(big);
ffffffffc0201acc:	8522                	mv	a0,s0
ffffffffc0201ace:	acdff0ef          	jal	ra,ffffffffc020159a <kfree>
    if (size == 0) {
ffffffffc0201ad2:	6505                	lui	a0,0x1
ffffffffc0201ad4:	38850513          	addi	a0,a0,904 # 1388 <kern_entry-0xffffffffc01fec78>
ffffffffc0201ad8:	831ff0ef          	jal	ra,ffffffffc0201308 <kmalloc.part.0>
ffffffffc0201adc:	842a                	mv	s0,a0
    if (huge == NULL) {
ffffffffc0201ade:	c171                	beqz	a0,ffffffffc0201ba2 <slub_check+0x2ce>
    if (slub_ptr_cache_index(huge) != -1) {
ffffffffc0201ae0:	9adff0ef          	jal	ra,ffffffffc020148c <slub_ptr_cache_index>
ffffffffc0201ae4:	14951963          	bne	a0,s1,ffffffffc0201c36 <slub_check+0x362>
    memset(huge, 0x6B, 5000);
ffffffffc0201ae8:	6605                	lui	a2,0x1
ffffffffc0201aea:	38860613          	addi	a2,a2,904 # 1388 <kern_entry-0xffffffffc01fec78>
ffffffffc0201aee:	06b00593          	li	a1,107
ffffffffc0201af2:	8522                	mv	a0,s0
ffffffffc0201af4:	684000ef          	jal	ra,ffffffffc0202178 <memset>
    if (*(unsigned char *)huge != 0x6B) {
ffffffffc0201af8:	00044703          	lbu	a4,0(s0)
ffffffffc0201afc:	06b00793          	li	a5,107
ffffffffc0201b00:	10f71263          	bne	a4,a5,ffffffffc0201c04 <slub_check+0x330>
    kfree(huge);
ffffffffc0201b04:	8522                	mv	a0,s0
ffffffffc0201b06:	a95ff0ef          	jal	ra,ffffffffc020159a <kfree>
    if (nr_free_pages() != before) {
ffffffffc0201b0a:	d64ff0ef          	jal	ra,ffffffffc020106e <nr_free_pages>
ffffffffc0201b0e:	0ca91f63          	bne	s2,a0,ffffffffc0201bec <slub_check+0x318>
    cprintf("slub_check: PASS boundary (0B, NULL, 2000B, 5000B)\n");
ffffffffc0201b12:	00001517          	auipc	a0,0x1
ffffffffc0201b16:	55650513          	addi	a0,a0,1366 # ffffffffc0203068 <best_fit_pmm_manager+0x930>
ffffffffc0201b1a:	e3afe0ef          	jal	ra,ffffffffc0200154 <cprintf>

    check_basic_alloc_free();
    check_different_caches();
    check_boundary();
    check_stress();
ffffffffc0201b1e:	b9bff0ef          	jal	ra,ffffffffc02016b8 <check_stress>

    /* 全部用例结束后，各 cache 不应有未归还的对象。 */
    for (size_t i = 0; i < SLUB_CACHE_COUNT; i++) {
ffffffffc0201b22:	00005417          	auipc	s0,0x5
ffffffffc0201b26:	50e40413          	addi	s0,s0,1294 # ffffffffc0207030 <kmem_caches>
ffffffffc0201b2a:	00005917          	auipc	s2,0x5
ffffffffc0201b2e:	5c690913          	addi	s2,s2,1478 # ffffffffc02070f0 <is_panic>
        if (kmem_caches[i].nr_inuse != 0) {
            panic("slub_check: cache %s leaks %lu object(s)",
                  kmem_caches[i].name,
                  (unsigned long)kmem_caches[i].nr_inuse);
        }
        cprintf("slub_check: cache %-12s slabs=%lu\n",
ffffffffc0201b32:	00001497          	auipc	s1,0x1
ffffffffc0201b36:	59e48493          	addi	s1,s1,1438 # ffffffffc02030d0 <best_fit_pmm_manager+0x998>
        if (kmem_caches[i].nr_inuse != 0) {
ffffffffc0201b3a:	7418                	ld	a4,40(s0)
            panic("slub_check: cache %s leaks %lu object(s)",
ffffffffc0201b3c:	600c                	ld	a1,0(s0)
        if (kmem_caches[i].nr_inuse != 0) {
ffffffffc0201b3e:	0c071f63          	bnez	a4,ffffffffc0201c1c <slub_check+0x348>
        cprintf("slub_check: cache %-12s slabs=%lu\n",
ffffffffc0201b42:	7010                	ld	a2,32(s0)
ffffffffc0201b44:	8526                	mv	a0,s1
    for (size_t i = 0; i < SLUB_CACHE_COUNT; i++) {
ffffffffc0201b46:	03040413          	addi	s0,s0,48
        cprintf("slub_check: cache %-12s slabs=%lu\n",
ffffffffc0201b4a:	e0afe0ef          	jal	ra,ffffffffc0200154 <cprintf>
    for (size_t i = 0; i < SLUB_CACHE_COUNT; i++) {
ffffffffc0201b4e:	fe8916e3          	bne	s2,s0,ffffffffc0201b3a <slub_check+0x266>
                kmem_caches[i].name,
                (unsigned long)kmem_caches[i].nr_slabs);
    }

    cprintf("slub_check: all tests passed (free pages = %lu)\n",
            (unsigned long)nr_free_pages());
ffffffffc0201b52:	d1cff0ef          	jal	ra,ffffffffc020106e <nr_free_pages>
}
ffffffffc0201b56:	6446                	ld	s0,80(sp)
ffffffffc0201b58:	60e6                	ld	ra,88(sp)
ffffffffc0201b5a:	64a6                	ld	s1,72(sp)
ffffffffc0201b5c:	6906                	ld	s2,64(sp)
ffffffffc0201b5e:	79e2                	ld	s3,56(sp)
ffffffffc0201b60:	7a42                	ld	s4,48(sp)
            (unsigned long)nr_free_pages());
ffffffffc0201b62:	85aa                	mv	a1,a0
    cprintf("slub_check: all tests passed (free pages = %lu)\n",
ffffffffc0201b64:	00001517          	auipc	a0,0x1
ffffffffc0201b68:	59450513          	addi	a0,a0,1428 # ffffffffc02030f8 <best_fit_pmm_manager+0x9c0>
}
ffffffffc0201b6c:	6125                	addi	sp,sp,96
    cprintf("slub_check: all tests passed (free pages = %lu)\n",
ffffffffc0201b6e:	de6fe06f          	j	ffffffffc0200154 <cprintf>
                panic("slub_check: kmalloc(32) returned duplicate pointer");
ffffffffc0201b72:	00001617          	auipc	a2,0x1
ffffffffc0201b76:	1f660613          	addi	a2,a2,502 # ffffffffc0202d68 <best_fit_pmm_manager+0x630>
ffffffffc0201b7a:	0ce00593          	li	a1,206
ffffffffc0201b7e:	00001517          	auipc	a0,0x1
ffffffffc0201b82:	eb250513          	addi	a0,a0,-334 # ffffffffc0202a30 <best_fit_pmm_manager+0x2f8>
ffffffffc0201b86:	e44fe0ef          	jal	ra,ffffffffc02001ca <__panic>
                panic("slub_check: kmalloc(32) objects overlap");
ffffffffc0201b8a:	00001617          	auipc	a2,0x1
ffffffffc0201b8e:	21660613          	addi	a2,a2,534 # ffffffffc0202da0 <best_fit_pmm_manager+0x668>
ffffffffc0201b92:	0d200593          	li	a1,210
ffffffffc0201b96:	00001517          	auipc	a0,0x1
ffffffffc0201b9a:	e9a50513          	addi	a0,a0,-358 # ffffffffc0202a30 <best_fit_pmm_manager+0x2f8>
ffffffffc0201b9e:	e2cfe0ef          	jal	ra,ffffffffc02001ca <__panic>
        panic("slub_check: kmalloc(5000) returned NULL");
ffffffffc0201ba2:	00001617          	auipc	a2,0x1
ffffffffc0201ba6:	43660613          	addi	a2,a2,1078 # ffffffffc0202fd8 <best_fit_pmm_manager+0x8a0>
ffffffffc0201baa:	12f00593          	li	a1,303
ffffffffc0201bae:	00001517          	auipc	a0,0x1
ffffffffc0201bb2:	e8250513          	addi	a0,a0,-382 # ffffffffc0202a30 <best_fit_pmm_manager+0x2f8>
ffffffffc0201bb6:	e14fe0ef          	jal	ra,ffffffffc02001ca <__panic>
        panic("slub_check: oversized object read-back failed");
ffffffffc0201bba:	00001617          	auipc	a2,0x1
ffffffffc0201bbe:	3ee60613          	addi	a2,a2,1006 # ffffffffc0202fa8 <best_fit_pmm_manager+0x870>
ffffffffc0201bc2:	12900593          	li	a1,297
ffffffffc0201bc6:	00001517          	auipc	a0,0x1
ffffffffc0201bca:	e6a50513          	addi	a0,a0,-406 # ffffffffc0202a30 <best_fit_pmm_manager+0x2f8>
ffffffffc0201bce:	dfcfe0ef          	jal	ra,ffffffffc02001ca <__panic>
            panic("slub_check: kmalloc(32) returned NULL at #%lu",
ffffffffc0201bd2:	86a6                	mv	a3,s1
ffffffffc0201bd4:	00001617          	auipc	a2,0x1
ffffffffc0201bd8:	16460613          	addi	a2,a2,356 # ffffffffc0202d38 <best_fit_pmm_manager+0x600>
ffffffffc0201bdc:	0c500593          	li	a1,197
ffffffffc0201be0:	00001517          	auipc	a0,0x1
ffffffffc0201be4:	e5050513          	addi	a0,a0,-432 # ffffffffc0202a30 <best_fit_pmm_manager+0x2f8>
ffffffffc0201be8:	de2fe0ef          	jal	ra,ffffffffc02001ca <__panic>
        panic("slub_check: oversized objects leaked pages");
ffffffffc0201bec:	00001617          	auipc	a2,0x1
ffffffffc0201bf0:	44c60613          	addi	a2,a2,1100 # ffffffffc0203038 <best_fit_pmm_manager+0x900>
ffffffffc0201bf4:	13b00593          	li	a1,315
ffffffffc0201bf8:	00001517          	auipc	a0,0x1
ffffffffc0201bfc:	e3850513          	addi	a0,a0,-456 # ffffffffc0202a30 <best_fit_pmm_manager+0x2f8>
ffffffffc0201c00:	dcafe0ef          	jal	ra,ffffffffc02001ca <__panic>
        panic("slub_check: oversized object read-back failed");
ffffffffc0201c04:	00001617          	auipc	a2,0x1
ffffffffc0201c08:	3a460613          	addi	a2,a2,932 # ffffffffc0202fa8 <best_fit_pmm_manager+0x870>
ffffffffc0201c0c:	13600593          	li	a1,310
ffffffffc0201c10:	00001517          	auipc	a0,0x1
ffffffffc0201c14:	e2050513          	addi	a0,a0,-480 # ffffffffc0202a30 <best_fit_pmm_manager+0x2f8>
ffffffffc0201c18:	db2fe0ef          	jal	ra,ffffffffc02001ca <__panic>
            panic("slub_check: cache %s leaks %lu object(s)",
ffffffffc0201c1c:	86ae                	mv	a3,a1
ffffffffc0201c1e:	00001617          	auipc	a2,0x1
ffffffffc0201c22:	48260613          	addi	a2,a2,1154 # ffffffffc02030a0 <best_fit_pmm_manager+0x968>
ffffffffc0201c26:	18c00593          	li	a1,396
ffffffffc0201c2a:	00001517          	auipc	a0,0x1
ffffffffc0201c2e:	e0650513          	addi	a0,a0,-506 # ffffffffc0202a30 <best_fit_pmm_manager+0x2f8>
ffffffffc0201c32:	d98fe0ef          	jal	ra,ffffffffc02001ca <__panic>
        panic("slub_check: 5000B object should fall back to pages");
ffffffffc0201c36:	00001617          	auipc	a2,0x1
ffffffffc0201c3a:	3ca60613          	addi	a2,a2,970 # ffffffffc0203000 <best_fit_pmm_manager+0x8c8>
ffffffffc0201c3e:	13200593          	li	a1,306
ffffffffc0201c42:	00001517          	auipc	a0,0x1
ffffffffc0201c46:	dee50513          	addi	a0,a0,-530 # ffffffffc0202a30 <best_fit_pmm_manager+0x2f8>
ffffffffc0201c4a:	d80fe0ef          	jal	ra,ffffffffc02001ca <__panic>
        panic("slub_check: allocation failed after kfree(NULL)");
ffffffffc0201c4e:	00001617          	auipc	a2,0x1
ffffffffc0201c52:	2ca60613          	addi	a2,a2,714 # ffffffffc0202f18 <best_fit_pmm_manager+0x7e0>
ffffffffc0201c56:	11900593          	li	a1,281
ffffffffc0201c5a:	00001517          	auipc	a0,0x1
ffffffffc0201c5e:	dd650513          	addi	a0,a0,-554 # ffffffffc0202a30 <best_fit_pmm_manager+0x2f8>
ffffffffc0201c62:	d68fe0ef          	jal	ra,ffffffffc02001ca <__panic>
        panic("slub_check: 2000B object should fall back to pages");
ffffffffc0201c66:	00001617          	auipc	a2,0x1
ffffffffc0201c6a:	30a60613          	addi	a2,a2,778 # ffffffffc0202f70 <best_fit_pmm_manager+0x838>
ffffffffc0201c6e:	12500593          	li	a1,293
ffffffffc0201c72:	00001517          	auipc	a0,0x1
ffffffffc0201c76:	dbe50513          	addi	a0,a0,-578 # ffffffffc0202a30 <best_fit_pmm_manager+0x2f8>
ffffffffc0201c7a:	d50fe0ef          	jal	ra,ffffffffc02001ca <__panic>
        panic("slub_check: kmalloc(2000) returned NULL");
ffffffffc0201c7e:	00001617          	auipc	a2,0x1
ffffffffc0201c82:	2ca60613          	addi	a2,a2,714 # ffffffffc0202f48 <best_fit_pmm_manager+0x810>
ffffffffc0201c86:	12200593          	li	a1,290
ffffffffc0201c8a:	00001517          	auipc	a0,0x1
ffffffffc0201c8e:	da650513          	addi	a0,a0,-602 # ffffffffc0202a30 <best_fit_pmm_manager+0x2f8>
ffffffffc0201c92:	d38fe0ef          	jal	ra,ffffffffc02001ca <__panic>
        panic("slub_check: caches interfere with each other");
ffffffffc0201c96:	00001617          	auipc	a2,0x1
ffffffffc0201c9a:	21a60613          	addi	a2,a2,538 # ffffffffc0202eb0 <best_fit_pmm_manager+0x778>
ffffffffc0201c9e:	10300593          	li	a1,259
ffffffffc0201ca2:	00001517          	auipc	a0,0x1
ffffffffc0201ca6:	d8e50513          	addi	a0,a0,-626 # ffffffffc0202a30 <best_fit_pmm_manager+0x2f8>
ffffffffc0201caa:	d20fe0ef          	jal	ra,ffffffffc02001ca <__panic>
        panic("slub_check: kfree+kmalloc did not reuse the freed object");
ffffffffc0201cae:	00001617          	auipc	a2,0x1
ffffffffc0201cb2:	11a60613          	addi	a2,a2,282 # ffffffffc0202dc8 <best_fit_pmm_manager+0x690>
ffffffffc0201cb6:	0dc00593          	li	a1,220
ffffffffc0201cba:	00001517          	auipc	a0,0x1
ffffffffc0201cbe:	d7650513          	addi	a0,a0,-650 # ffffffffc0202a30 <best_fit_pmm_manager+0x2f8>
ffffffffc0201cc2:	d08fe0ef          	jal	ra,ffffffffc02001ca <__panic>
        panic("slub_check: objects not routed to their own caches");
ffffffffc0201cc6:	00001617          	auipc	a2,0x1
ffffffffc0201cca:	1b260613          	addi	a2,a2,434 # ffffffffc0202e78 <best_fit_pmm_manager+0x740>
ffffffffc0201cce:	0f700593          	li	a1,247
ffffffffc0201cd2:	00001517          	auipc	a0,0x1
ffffffffc0201cd6:	d5e50513          	addi	a0,a0,-674 # ffffffffc0202a30 <best_fit_pmm_manager+0x2f8>
ffffffffc0201cda:	cf0fe0ef          	jal	ra,ffffffffc02001ca <__panic>
        panic("slub_check: kmalloc returned NULL for 16/32/64/128");
ffffffffc0201cde:	00001617          	auipc	a2,0x1
ffffffffc0201ce2:	16260613          	addi	a2,a2,354 # ffffffffc0202e40 <best_fit_pmm_manager+0x708>
ffffffffc0201ce6:	0ef00593          	li	a1,239
ffffffffc0201cea:	00001517          	auipc	a0,0x1
ffffffffc0201cee:	d4650513          	addi	a0,a0,-698 # ffffffffc0202a30 <best_fit_pmm_manager+0x2f8>
ffffffffc0201cf2:	cd8fe0ef          	jal	ra,ffffffffc02001ca <__panic>

ffffffffc0201cf6 <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc0201cf6:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0201cfa:	7179                	addi	sp,sp,-48
    unsigned mod = do_div(result, base);
ffffffffc0201cfc:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0201d00:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc0201d02:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0201d06:	f022                	sd	s0,32(sp)
ffffffffc0201d08:	ec26                	sd	s1,24(sp)
ffffffffc0201d0a:	e84a                	sd	s2,16(sp)
ffffffffc0201d0c:	f406                	sd	ra,40(sp)
ffffffffc0201d0e:	e44e                	sd	s3,8(sp)
ffffffffc0201d10:	84aa                	mv	s1,a0
ffffffffc0201d12:	892e                	mv	s2,a1
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc0201d14:	fff7041b          	addiw	s0,a4,-1
    unsigned mod = do_div(result, base);
ffffffffc0201d18:	2a01                	sext.w	s4,s4
    if (num >= base) {
ffffffffc0201d1a:	03067e63          	bgeu	a2,a6,ffffffffc0201d56 <printnum+0x60>
ffffffffc0201d1e:	89be                	mv	s3,a5
        while (-- width > 0)
ffffffffc0201d20:	00805763          	blez	s0,ffffffffc0201d2e <printnum+0x38>
ffffffffc0201d24:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc0201d26:	85ca                	mv	a1,s2
ffffffffc0201d28:	854e                	mv	a0,s3
ffffffffc0201d2a:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc0201d2c:	fc65                	bnez	s0,ffffffffc0201d24 <printnum+0x2e>
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201d2e:	1a02                	slli	s4,s4,0x20
ffffffffc0201d30:	00001797          	auipc	a5,0x1
ffffffffc0201d34:	48078793          	addi	a5,a5,1152 # ffffffffc02031b0 <specs.0+0x40>
ffffffffc0201d38:	020a5a13          	srli	s4,s4,0x20
ffffffffc0201d3c:	9a3e                	add	s4,s4,a5
}
ffffffffc0201d3e:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201d40:	000a4503          	lbu	a0,0(s4)
}
ffffffffc0201d44:	70a2                	ld	ra,40(sp)
ffffffffc0201d46:	69a2                	ld	s3,8(sp)
ffffffffc0201d48:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201d4a:	85ca                	mv	a1,s2
ffffffffc0201d4c:	87a6                	mv	a5,s1
}
ffffffffc0201d4e:	6942                	ld	s2,16(sp)
ffffffffc0201d50:	64e2                	ld	s1,24(sp)
ffffffffc0201d52:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201d54:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc0201d56:	03065633          	divu	a2,a2,a6
ffffffffc0201d5a:	8722                	mv	a4,s0
ffffffffc0201d5c:	f9bff0ef          	jal	ra,ffffffffc0201cf6 <printnum>
ffffffffc0201d60:	b7f9                	j	ffffffffc0201d2e <printnum+0x38>

ffffffffc0201d62 <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc0201d62:	7119                	addi	sp,sp,-128
ffffffffc0201d64:	f4a6                	sd	s1,104(sp)
ffffffffc0201d66:	f0ca                	sd	s2,96(sp)
ffffffffc0201d68:	ecce                	sd	s3,88(sp)
ffffffffc0201d6a:	e8d2                	sd	s4,80(sp)
ffffffffc0201d6c:	e4d6                	sd	s5,72(sp)
ffffffffc0201d6e:	e0da                	sd	s6,64(sp)
ffffffffc0201d70:	fc5e                	sd	s7,56(sp)
ffffffffc0201d72:	f06a                	sd	s10,32(sp)
ffffffffc0201d74:	fc86                	sd	ra,120(sp)
ffffffffc0201d76:	f8a2                	sd	s0,112(sp)
ffffffffc0201d78:	f862                	sd	s8,48(sp)
ffffffffc0201d7a:	f466                	sd	s9,40(sp)
ffffffffc0201d7c:	ec6e                	sd	s11,24(sp)
ffffffffc0201d7e:	892a                	mv	s2,a0
ffffffffc0201d80:	84ae                	mv	s1,a1
ffffffffc0201d82:	8d32                	mv	s10,a2
ffffffffc0201d84:	8a36                	mv	s4,a3
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201d86:	02500993          	li	s3,37
            putch(ch, putdat);
        }

        // Process a %-escape sequence
        char padc = ' ';
        width = precision = -1;
ffffffffc0201d8a:	5b7d                	li	s6,-1
ffffffffc0201d8c:	00001a97          	auipc	s5,0x1
ffffffffc0201d90:	458a8a93          	addi	s5,s5,1112 # ffffffffc02031e4 <specs.0+0x74>
        case 'e':
            err = va_arg(ap, int);
            if (err < 0) {
                err = -err;
            }
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0201d94:	00001b97          	auipc	s7,0x1
ffffffffc0201d98:	62cb8b93          	addi	s7,s7,1580 # ffffffffc02033c0 <error_string>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201d9c:	000d4503          	lbu	a0,0(s10)
ffffffffc0201da0:	001d0413          	addi	s0,s10,1
ffffffffc0201da4:	01350a63          	beq	a0,s3,ffffffffc0201db8 <vprintfmt+0x56>
            if (ch == '\0') {
ffffffffc0201da8:	c121                	beqz	a0,ffffffffc0201de8 <vprintfmt+0x86>
            putch(ch, putdat);
ffffffffc0201daa:	85a6                	mv	a1,s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201dac:	0405                	addi	s0,s0,1
            putch(ch, putdat);
ffffffffc0201dae:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201db0:	fff44503          	lbu	a0,-1(s0)
ffffffffc0201db4:	ff351ae3          	bne	a0,s3,ffffffffc0201da8 <vprintfmt+0x46>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201db8:	00044603          	lbu	a2,0(s0)
        char padc = ' ';
ffffffffc0201dbc:	02000793          	li	a5,32
        lflag = altflag = 0;
ffffffffc0201dc0:	4c81                	li	s9,0
ffffffffc0201dc2:	4881                	li	a7,0
        width = precision = -1;
ffffffffc0201dc4:	5c7d                	li	s8,-1
ffffffffc0201dc6:	5dfd                	li	s11,-1
ffffffffc0201dc8:	05500513          	li	a0,85
                if (ch < '0' || ch > '9') {
ffffffffc0201dcc:	4825                	li	a6,9
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201dce:	fdd6059b          	addiw	a1,a2,-35
ffffffffc0201dd2:	0ff5f593          	zext.b	a1,a1
ffffffffc0201dd6:	00140d13          	addi	s10,s0,1
ffffffffc0201dda:	04b56263          	bltu	a0,a1,ffffffffc0201e1e <vprintfmt+0xbc>
ffffffffc0201dde:	058a                	slli	a1,a1,0x2
ffffffffc0201de0:	95d6                	add	a1,a1,s5
ffffffffc0201de2:	4194                	lw	a3,0(a1)
ffffffffc0201de4:	96d6                	add	a3,a3,s5
ffffffffc0201de6:	8682                	jr	a3
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc0201de8:	70e6                	ld	ra,120(sp)
ffffffffc0201dea:	7446                	ld	s0,112(sp)
ffffffffc0201dec:	74a6                	ld	s1,104(sp)
ffffffffc0201dee:	7906                	ld	s2,96(sp)
ffffffffc0201df0:	69e6                	ld	s3,88(sp)
ffffffffc0201df2:	6a46                	ld	s4,80(sp)
ffffffffc0201df4:	6aa6                	ld	s5,72(sp)
ffffffffc0201df6:	6b06                	ld	s6,64(sp)
ffffffffc0201df8:	7be2                	ld	s7,56(sp)
ffffffffc0201dfa:	7c42                	ld	s8,48(sp)
ffffffffc0201dfc:	7ca2                	ld	s9,40(sp)
ffffffffc0201dfe:	7d02                	ld	s10,32(sp)
ffffffffc0201e00:	6de2                	ld	s11,24(sp)
ffffffffc0201e02:	6109                	addi	sp,sp,128
ffffffffc0201e04:	8082                	ret
            padc = '0';
ffffffffc0201e06:	87b2                	mv	a5,a2
            goto reswitch;
ffffffffc0201e08:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201e0c:	846a                	mv	s0,s10
ffffffffc0201e0e:	00140d13          	addi	s10,s0,1
ffffffffc0201e12:	fdd6059b          	addiw	a1,a2,-35
ffffffffc0201e16:	0ff5f593          	zext.b	a1,a1
ffffffffc0201e1a:	fcb572e3          	bgeu	a0,a1,ffffffffc0201dde <vprintfmt+0x7c>
            putch('%', putdat);
ffffffffc0201e1e:	85a6                	mv	a1,s1
ffffffffc0201e20:	02500513          	li	a0,37
ffffffffc0201e24:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc0201e26:	fff44783          	lbu	a5,-1(s0)
ffffffffc0201e2a:	8d22                	mv	s10,s0
ffffffffc0201e2c:	f73788e3          	beq	a5,s3,ffffffffc0201d9c <vprintfmt+0x3a>
ffffffffc0201e30:	ffed4783          	lbu	a5,-2(s10)
ffffffffc0201e34:	1d7d                	addi	s10,s10,-1
ffffffffc0201e36:	ff379de3          	bne	a5,s3,ffffffffc0201e30 <vprintfmt+0xce>
ffffffffc0201e3a:	b78d                	j	ffffffffc0201d9c <vprintfmt+0x3a>
                precision = precision * 10 + ch - '0';
ffffffffc0201e3c:	fd060c1b          	addiw	s8,a2,-48
                ch = *fmt;
ffffffffc0201e40:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201e44:	846a                	mv	s0,s10
                if (ch < '0' || ch > '9') {
ffffffffc0201e46:	fd06069b          	addiw	a3,a2,-48
                ch = *fmt;
ffffffffc0201e4a:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc0201e4e:	02d86463          	bltu	a6,a3,ffffffffc0201e76 <vprintfmt+0x114>
                ch = *fmt;
ffffffffc0201e52:	00144603          	lbu	a2,1(s0)
                precision = precision * 10 + ch - '0';
ffffffffc0201e56:	002c169b          	slliw	a3,s8,0x2
ffffffffc0201e5a:	0186873b          	addw	a4,a3,s8
ffffffffc0201e5e:	0017171b          	slliw	a4,a4,0x1
ffffffffc0201e62:	9f2d                	addw	a4,a4,a1
                if (ch < '0' || ch > '9') {
ffffffffc0201e64:	fd06069b          	addiw	a3,a2,-48
            for (precision = 0; ; ++ fmt) {
ffffffffc0201e68:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc0201e6a:	fd070c1b          	addiw	s8,a4,-48
                ch = *fmt;
ffffffffc0201e6e:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc0201e72:	fed870e3          	bgeu	a6,a3,ffffffffc0201e52 <vprintfmt+0xf0>
            if (width < 0)
ffffffffc0201e76:	f40ddce3          	bgez	s11,ffffffffc0201dce <vprintfmt+0x6c>
                width = precision, precision = -1;
ffffffffc0201e7a:	8de2                	mv	s11,s8
ffffffffc0201e7c:	5c7d                	li	s8,-1
ffffffffc0201e7e:	bf81                	j	ffffffffc0201dce <vprintfmt+0x6c>
            if (width < 0)
ffffffffc0201e80:	fffdc693          	not	a3,s11
ffffffffc0201e84:	96fd                	srai	a3,a3,0x3f
ffffffffc0201e86:	00ddfdb3          	and	s11,s11,a3
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201e8a:	00144603          	lbu	a2,1(s0)
ffffffffc0201e8e:	2d81                	sext.w	s11,s11
ffffffffc0201e90:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0201e92:	bf35                	j	ffffffffc0201dce <vprintfmt+0x6c>
            precision = va_arg(ap, int);
ffffffffc0201e94:	000a2c03          	lw	s8,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201e98:	00144603          	lbu	a2,1(s0)
            precision = va_arg(ap, int);
ffffffffc0201e9c:	0a21                	addi	s4,s4,8
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201e9e:	846a                	mv	s0,s10
            goto process_precision;
ffffffffc0201ea0:	bfd9                	j	ffffffffc0201e76 <vprintfmt+0x114>
    if (lflag >= 2) {
ffffffffc0201ea2:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201ea4:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0201ea8:	01174463          	blt	a4,a7,ffffffffc0201eb0 <vprintfmt+0x14e>
    else if (lflag) {
ffffffffc0201eac:	1a088e63          	beqz	a7,ffffffffc0202068 <vprintfmt+0x306>
        return va_arg(*ap, unsigned long);
ffffffffc0201eb0:	000a3603          	ld	a2,0(s4)
ffffffffc0201eb4:	46c1                	li	a3,16
ffffffffc0201eb6:	8a2e                	mv	s4,a1
            printnum(putch, putdat, num, base, width, padc);
ffffffffc0201eb8:	2781                	sext.w	a5,a5
ffffffffc0201eba:	876e                	mv	a4,s11
ffffffffc0201ebc:	85a6                	mv	a1,s1
ffffffffc0201ebe:	854a                	mv	a0,s2
ffffffffc0201ec0:	e37ff0ef          	jal	ra,ffffffffc0201cf6 <printnum>
            break;
ffffffffc0201ec4:	bde1                	j	ffffffffc0201d9c <vprintfmt+0x3a>
            putch(va_arg(ap, int), putdat);
ffffffffc0201ec6:	000a2503          	lw	a0,0(s4)
ffffffffc0201eca:	85a6                	mv	a1,s1
ffffffffc0201ecc:	0a21                	addi	s4,s4,8
ffffffffc0201ece:	9902                	jalr	s2
            break;
ffffffffc0201ed0:	b5f1                	j	ffffffffc0201d9c <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc0201ed2:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201ed4:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0201ed8:	01174463          	blt	a4,a7,ffffffffc0201ee0 <vprintfmt+0x17e>
    else if (lflag) {
ffffffffc0201edc:	18088163          	beqz	a7,ffffffffc020205e <vprintfmt+0x2fc>
        return va_arg(*ap, unsigned long);
ffffffffc0201ee0:	000a3603          	ld	a2,0(s4)
ffffffffc0201ee4:	46a9                	li	a3,10
ffffffffc0201ee6:	8a2e                	mv	s4,a1
ffffffffc0201ee8:	bfc1                	j	ffffffffc0201eb8 <vprintfmt+0x156>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201eea:	00144603          	lbu	a2,1(s0)
            altflag = 1;
ffffffffc0201eee:	4c85                	li	s9,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201ef0:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0201ef2:	bdf1                	j	ffffffffc0201dce <vprintfmt+0x6c>
            putch(ch, putdat);
ffffffffc0201ef4:	85a6                	mv	a1,s1
ffffffffc0201ef6:	02500513          	li	a0,37
ffffffffc0201efa:	9902                	jalr	s2
            break;
ffffffffc0201efc:	b545                	j	ffffffffc0201d9c <vprintfmt+0x3a>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201efe:	00144603          	lbu	a2,1(s0)
            lflag ++;
ffffffffc0201f02:	2885                	addiw	a7,a7,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201f04:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0201f06:	b5e1                	j	ffffffffc0201dce <vprintfmt+0x6c>
    if (lflag >= 2) {
ffffffffc0201f08:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201f0a:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0201f0e:	01174463          	blt	a4,a7,ffffffffc0201f16 <vprintfmt+0x1b4>
    else if (lflag) {
ffffffffc0201f12:	14088163          	beqz	a7,ffffffffc0202054 <vprintfmt+0x2f2>
        return va_arg(*ap, unsigned long);
ffffffffc0201f16:	000a3603          	ld	a2,0(s4)
ffffffffc0201f1a:	46a1                	li	a3,8
ffffffffc0201f1c:	8a2e                	mv	s4,a1
ffffffffc0201f1e:	bf69                	j	ffffffffc0201eb8 <vprintfmt+0x156>
            putch('0', putdat);
ffffffffc0201f20:	03000513          	li	a0,48
ffffffffc0201f24:	85a6                	mv	a1,s1
ffffffffc0201f26:	e03e                	sd	a5,0(sp)
ffffffffc0201f28:	9902                	jalr	s2
            putch('x', putdat);
ffffffffc0201f2a:	85a6                	mv	a1,s1
ffffffffc0201f2c:	07800513          	li	a0,120
ffffffffc0201f30:	9902                	jalr	s2
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0201f32:	0a21                	addi	s4,s4,8
            goto number;
ffffffffc0201f34:	6782                	ld	a5,0(sp)
ffffffffc0201f36:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0201f38:	ff8a3603          	ld	a2,-8(s4)
            goto number;
ffffffffc0201f3c:	bfb5                	j	ffffffffc0201eb8 <vprintfmt+0x156>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0201f3e:	000a3403          	ld	s0,0(s4)
ffffffffc0201f42:	008a0713          	addi	a4,s4,8
ffffffffc0201f46:	e03a                	sd	a4,0(sp)
ffffffffc0201f48:	14040263          	beqz	s0,ffffffffc020208c <vprintfmt+0x32a>
            if (width > 0 && padc != '-') {
ffffffffc0201f4c:	0fb05763          	blez	s11,ffffffffc020203a <vprintfmt+0x2d8>
ffffffffc0201f50:	02d00693          	li	a3,45
ffffffffc0201f54:	0cd79163          	bne	a5,a3,ffffffffc0202016 <vprintfmt+0x2b4>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201f58:	00044783          	lbu	a5,0(s0)
ffffffffc0201f5c:	0007851b          	sext.w	a0,a5
ffffffffc0201f60:	cf85                	beqz	a5,ffffffffc0201f98 <vprintfmt+0x236>
ffffffffc0201f62:	00140a13          	addi	s4,s0,1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201f66:	05e00413          	li	s0,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201f6a:	000c4563          	bltz	s8,ffffffffc0201f74 <vprintfmt+0x212>
ffffffffc0201f6e:	3c7d                	addiw	s8,s8,-1
ffffffffc0201f70:	036c0263          	beq	s8,s6,ffffffffc0201f94 <vprintfmt+0x232>
                    putch('?', putdat);
ffffffffc0201f74:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201f76:	0e0c8e63          	beqz	s9,ffffffffc0202072 <vprintfmt+0x310>
ffffffffc0201f7a:	3781                	addiw	a5,a5,-32
ffffffffc0201f7c:	0ef47b63          	bgeu	s0,a5,ffffffffc0202072 <vprintfmt+0x310>
                    putch('?', putdat);
ffffffffc0201f80:	03f00513          	li	a0,63
ffffffffc0201f84:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201f86:	000a4783          	lbu	a5,0(s4)
ffffffffc0201f8a:	3dfd                	addiw	s11,s11,-1
ffffffffc0201f8c:	0a05                	addi	s4,s4,1
ffffffffc0201f8e:	0007851b          	sext.w	a0,a5
ffffffffc0201f92:	ffe1                	bnez	a5,ffffffffc0201f6a <vprintfmt+0x208>
            for (; width > 0; width --) {
ffffffffc0201f94:	01b05963          	blez	s11,ffffffffc0201fa6 <vprintfmt+0x244>
ffffffffc0201f98:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
ffffffffc0201f9a:	85a6                	mv	a1,s1
ffffffffc0201f9c:	02000513          	li	a0,32
ffffffffc0201fa0:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc0201fa2:	fe0d9be3          	bnez	s11,ffffffffc0201f98 <vprintfmt+0x236>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0201fa6:	6a02                	ld	s4,0(sp)
ffffffffc0201fa8:	bbd5                	j	ffffffffc0201d9c <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc0201faa:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201fac:	008a0c93          	addi	s9,s4,8
    if (lflag >= 2) {
ffffffffc0201fb0:	01174463          	blt	a4,a7,ffffffffc0201fb8 <vprintfmt+0x256>
    else if (lflag) {
ffffffffc0201fb4:	08088d63          	beqz	a7,ffffffffc020204e <vprintfmt+0x2ec>
        return va_arg(*ap, long);
ffffffffc0201fb8:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
ffffffffc0201fbc:	0a044d63          	bltz	s0,ffffffffc0202076 <vprintfmt+0x314>
            num = getint(&ap, lflag);
ffffffffc0201fc0:	8622                	mv	a2,s0
ffffffffc0201fc2:	8a66                	mv	s4,s9
ffffffffc0201fc4:	46a9                	li	a3,10
ffffffffc0201fc6:	bdcd                	j	ffffffffc0201eb8 <vprintfmt+0x156>
            err = va_arg(ap, int);
ffffffffc0201fc8:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0201fcc:	4719                	li	a4,6
            err = va_arg(ap, int);
ffffffffc0201fce:	0a21                	addi	s4,s4,8
            if (err < 0) {
ffffffffc0201fd0:	41f7d69b          	sraiw	a3,a5,0x1f
ffffffffc0201fd4:	8fb5                	xor	a5,a5,a3
ffffffffc0201fd6:	40d786bb          	subw	a3,a5,a3
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0201fda:	02d74163          	blt	a4,a3,ffffffffc0201ffc <vprintfmt+0x29a>
ffffffffc0201fde:	00369793          	slli	a5,a3,0x3
ffffffffc0201fe2:	97de                	add	a5,a5,s7
ffffffffc0201fe4:	639c                	ld	a5,0(a5)
ffffffffc0201fe6:	cb99                	beqz	a5,ffffffffc0201ffc <vprintfmt+0x29a>
                printfmt(putch, putdat, "%s", p);
ffffffffc0201fe8:	86be                	mv	a3,a5
ffffffffc0201fea:	00001617          	auipc	a2,0x1
ffffffffc0201fee:	1f660613          	addi	a2,a2,502 # ffffffffc02031e0 <specs.0+0x70>
ffffffffc0201ff2:	85a6                	mv	a1,s1
ffffffffc0201ff4:	854a                	mv	a0,s2
ffffffffc0201ff6:	0ce000ef          	jal	ra,ffffffffc02020c4 <printfmt>
ffffffffc0201ffa:	b34d                	j	ffffffffc0201d9c <vprintfmt+0x3a>
                printfmt(putch, putdat, "error %d", err);
ffffffffc0201ffc:	00001617          	auipc	a2,0x1
ffffffffc0202000:	1d460613          	addi	a2,a2,468 # ffffffffc02031d0 <specs.0+0x60>
ffffffffc0202004:	85a6                	mv	a1,s1
ffffffffc0202006:	854a                	mv	a0,s2
ffffffffc0202008:	0bc000ef          	jal	ra,ffffffffc02020c4 <printfmt>
ffffffffc020200c:	bb41                	j	ffffffffc0201d9c <vprintfmt+0x3a>
                p = "(null)";
ffffffffc020200e:	00001417          	auipc	s0,0x1
ffffffffc0202012:	1ba40413          	addi	s0,s0,442 # ffffffffc02031c8 <specs.0+0x58>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0202016:	85e2                	mv	a1,s8
ffffffffc0202018:	8522                	mv	a0,s0
ffffffffc020201a:	e43e                	sd	a5,8(sp)
ffffffffc020201c:	0fc000ef          	jal	ra,ffffffffc0202118 <strnlen>
ffffffffc0202020:	40ad8dbb          	subw	s11,s11,a0
ffffffffc0202024:	01b05b63          	blez	s11,ffffffffc020203a <vprintfmt+0x2d8>
                    putch(padc, putdat);
ffffffffc0202028:	67a2                	ld	a5,8(sp)
ffffffffc020202a:	00078a1b          	sext.w	s4,a5
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc020202e:	3dfd                	addiw	s11,s11,-1
                    putch(padc, putdat);
ffffffffc0202030:	85a6                	mv	a1,s1
ffffffffc0202032:	8552                	mv	a0,s4
ffffffffc0202034:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0202036:	fe0d9ce3          	bnez	s11,ffffffffc020202e <vprintfmt+0x2cc>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc020203a:	00044783          	lbu	a5,0(s0)
ffffffffc020203e:	00140a13          	addi	s4,s0,1
ffffffffc0202042:	0007851b          	sext.w	a0,a5
ffffffffc0202046:	d3a5                	beqz	a5,ffffffffc0201fa6 <vprintfmt+0x244>
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0202048:	05e00413          	li	s0,94
ffffffffc020204c:	bf39                	j	ffffffffc0201f6a <vprintfmt+0x208>
        return va_arg(*ap, int);
ffffffffc020204e:	000a2403          	lw	s0,0(s4)
ffffffffc0202052:	b7ad                	j	ffffffffc0201fbc <vprintfmt+0x25a>
        return va_arg(*ap, unsigned int);
ffffffffc0202054:	000a6603          	lwu	a2,0(s4)
ffffffffc0202058:	46a1                	li	a3,8
ffffffffc020205a:	8a2e                	mv	s4,a1
ffffffffc020205c:	bdb1                	j	ffffffffc0201eb8 <vprintfmt+0x156>
ffffffffc020205e:	000a6603          	lwu	a2,0(s4)
ffffffffc0202062:	46a9                	li	a3,10
ffffffffc0202064:	8a2e                	mv	s4,a1
ffffffffc0202066:	bd89                	j	ffffffffc0201eb8 <vprintfmt+0x156>
ffffffffc0202068:	000a6603          	lwu	a2,0(s4)
ffffffffc020206c:	46c1                	li	a3,16
ffffffffc020206e:	8a2e                	mv	s4,a1
ffffffffc0202070:	b5a1                	j	ffffffffc0201eb8 <vprintfmt+0x156>
                    putch(ch, putdat);
ffffffffc0202072:	9902                	jalr	s2
ffffffffc0202074:	bf09                	j	ffffffffc0201f86 <vprintfmt+0x224>
                putch('-', putdat);
ffffffffc0202076:	85a6                	mv	a1,s1
ffffffffc0202078:	02d00513          	li	a0,45
ffffffffc020207c:	e03e                	sd	a5,0(sp)
ffffffffc020207e:	9902                	jalr	s2
                num = -(long long)num;
ffffffffc0202080:	6782                	ld	a5,0(sp)
ffffffffc0202082:	8a66                	mv	s4,s9
ffffffffc0202084:	40800633          	neg	a2,s0
ffffffffc0202088:	46a9                	li	a3,10
ffffffffc020208a:	b53d                	j	ffffffffc0201eb8 <vprintfmt+0x156>
            if (width > 0 && padc != '-') {
ffffffffc020208c:	03b05163          	blez	s11,ffffffffc02020ae <vprintfmt+0x34c>
ffffffffc0202090:	02d00693          	li	a3,45
ffffffffc0202094:	f6d79de3          	bne	a5,a3,ffffffffc020200e <vprintfmt+0x2ac>
                p = "(null)";
ffffffffc0202098:	00001417          	auipc	s0,0x1
ffffffffc020209c:	13040413          	addi	s0,s0,304 # ffffffffc02031c8 <specs.0+0x58>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02020a0:	02800793          	li	a5,40
ffffffffc02020a4:	02800513          	li	a0,40
ffffffffc02020a8:	00140a13          	addi	s4,s0,1
ffffffffc02020ac:	bd6d                	j	ffffffffc0201f66 <vprintfmt+0x204>
ffffffffc02020ae:	00001a17          	auipc	s4,0x1
ffffffffc02020b2:	11ba0a13          	addi	s4,s4,283 # ffffffffc02031c9 <specs.0+0x59>
ffffffffc02020b6:	02800513          	li	a0,40
ffffffffc02020ba:	02800793          	li	a5,40
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc02020be:	05e00413          	li	s0,94
ffffffffc02020c2:	b565                	j	ffffffffc0201f6a <vprintfmt+0x208>

ffffffffc02020c4 <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc02020c4:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc02020c6:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc02020ca:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc02020cc:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc02020ce:	ec06                	sd	ra,24(sp)
ffffffffc02020d0:	f83a                	sd	a4,48(sp)
ffffffffc02020d2:	fc3e                	sd	a5,56(sp)
ffffffffc02020d4:	e0c2                	sd	a6,64(sp)
ffffffffc02020d6:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc02020d8:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc02020da:	c89ff0ef          	jal	ra,ffffffffc0201d62 <vprintfmt>
}
ffffffffc02020de:	60e2                	ld	ra,24(sp)
ffffffffc02020e0:	6161                	addi	sp,sp,80
ffffffffc02020e2:	8082                	ret

ffffffffc02020e4 <sbi_console_putchar>:
uint64_t SBI_REMOTE_SFENCE_VMA_ASID = 7;
uint64_t SBI_SHUTDOWN = 8;

uint64_t sbi_call(uint64_t sbi_type, uint64_t arg0, uint64_t arg1, uint64_t arg2) {
    uint64_t ret_val;
    __asm__ volatile (
ffffffffc02020e4:	4781                	li	a5,0
ffffffffc02020e6:	00005717          	auipc	a4,0x5
ffffffffc02020ea:	f2a73703          	ld	a4,-214(a4) # ffffffffc0207010 <SBI_CONSOLE_PUTCHAR>
ffffffffc02020ee:	88ba                	mv	a7,a4
ffffffffc02020f0:	852a                	mv	a0,a0
ffffffffc02020f2:	85be                	mv	a1,a5
ffffffffc02020f4:	863e                	mv	a2,a5
ffffffffc02020f6:	00000073          	ecall
ffffffffc02020fa:	87aa                	mv	a5,a0
    return ret_val;
}

void sbi_console_putchar(unsigned char ch) {
    sbi_call(SBI_CONSOLE_PUTCHAR, ch, 0, 0);
}
ffffffffc02020fc:	8082                	ret

ffffffffc02020fe <strlen>:
 * The strlen() function returns the length of string @s.
 * */
size_t
strlen(const char *s) {
    size_t cnt = 0;
    while (*s ++ != '\0') {
ffffffffc02020fe:	00054783          	lbu	a5,0(a0)
strlen(const char *s) {
ffffffffc0202102:	872a                	mv	a4,a0
    size_t cnt = 0;
ffffffffc0202104:	4501                	li	a0,0
    while (*s ++ != '\0') {
ffffffffc0202106:	cb81                	beqz	a5,ffffffffc0202116 <strlen+0x18>
        cnt ++;
ffffffffc0202108:	0505                	addi	a0,a0,1
    while (*s ++ != '\0') {
ffffffffc020210a:	00a707b3          	add	a5,a4,a0
ffffffffc020210e:	0007c783          	lbu	a5,0(a5)
ffffffffc0202112:	fbfd                	bnez	a5,ffffffffc0202108 <strlen+0xa>
ffffffffc0202114:	8082                	ret
    }
    return cnt;
}
ffffffffc0202116:	8082                	ret

ffffffffc0202118 <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
ffffffffc0202118:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
ffffffffc020211a:	e589                	bnez	a1,ffffffffc0202124 <strnlen+0xc>
ffffffffc020211c:	a811                	j	ffffffffc0202130 <strnlen+0x18>
        cnt ++;
ffffffffc020211e:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc0202120:	00f58863          	beq	a1,a5,ffffffffc0202130 <strnlen+0x18>
ffffffffc0202124:	00f50733          	add	a4,a0,a5
ffffffffc0202128:	00074703          	lbu	a4,0(a4)
ffffffffc020212c:	fb6d                	bnez	a4,ffffffffc020211e <strnlen+0x6>
ffffffffc020212e:	85be                	mv	a1,a5
    }
    return cnt;
}
ffffffffc0202130:	852e                	mv	a0,a1
ffffffffc0202132:	8082                	ret

ffffffffc0202134 <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0202134:	00054783          	lbu	a5,0(a0)
        s1 ++, s2 ++;
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0202138:	0005c703          	lbu	a4,0(a1)
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc020213c:	cb89                	beqz	a5,ffffffffc020214e <strcmp+0x1a>
        s1 ++, s2 ++;
ffffffffc020213e:	0505                	addi	a0,a0,1
ffffffffc0202140:	0585                	addi	a1,a1,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0202142:	fee789e3          	beq	a5,a4,ffffffffc0202134 <strcmp>
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0202146:	0007851b          	sext.w	a0,a5
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc020214a:	9d19                	subw	a0,a0,a4
ffffffffc020214c:	8082                	ret
ffffffffc020214e:	4501                	li	a0,0
ffffffffc0202150:	bfed                	j	ffffffffc020214a <strcmp+0x16>

ffffffffc0202152 <strncmp>:
 * the characters differ, until a terminating null-character is reached, or
 * until @n characters match in both strings, whichever happens first.
 * */
int
strncmp(const char *s1, const char *s2, size_t n) {
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0202152:	c20d                	beqz	a2,ffffffffc0202174 <strncmp+0x22>
ffffffffc0202154:	962e                	add	a2,a2,a1
ffffffffc0202156:	a031                	j	ffffffffc0202162 <strncmp+0x10>
        n --, s1 ++, s2 ++;
ffffffffc0202158:	0505                	addi	a0,a0,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc020215a:	00e79a63          	bne	a5,a4,ffffffffc020216e <strncmp+0x1c>
ffffffffc020215e:	00b60b63          	beq	a2,a1,ffffffffc0202174 <strncmp+0x22>
ffffffffc0202162:	00054783          	lbu	a5,0(a0)
        n --, s1 ++, s2 ++;
ffffffffc0202166:	0585                	addi	a1,a1,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0202168:	fff5c703          	lbu	a4,-1(a1)
ffffffffc020216c:	f7f5                	bnez	a5,ffffffffc0202158 <strncmp+0x6>
    }
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc020216e:	40e7853b          	subw	a0,a5,a4
}
ffffffffc0202172:	8082                	ret
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0202174:	4501                	li	a0,0
ffffffffc0202176:	8082                	ret

ffffffffc0202178 <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc0202178:	ca01                	beqz	a2,ffffffffc0202188 <memset+0x10>
ffffffffc020217a:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc020217c:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc020217e:	0785                	addi	a5,a5,1
ffffffffc0202180:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc0202184:	fec79de3          	bne	a5,a2,ffffffffc020217e <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc0202188:	8082                	ret
