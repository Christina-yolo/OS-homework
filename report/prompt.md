## 附：AI 协作 Prompt 记录

在本次 Lab3 中，我按照“功能模块化”的思路，分别针对模块一（汇编上下文切换）和模块二（C 语言中断/异常处理）设计了 Prompt，以约束 AI 的输出，防止其产生幻觉或破坏原有框架。

### 练习一：功能模块一（Trap 上下文恢复与 Trap 入口）

**Prompt 如下：**

> 我正在完成操作系统实验Lab3，当前需要实现功能模块一：Trap上下文恢复与Trap入口功能。
> 
> 先阅读项目中的相关源代码，充分理解现有的Trapframe内存布局、SAVE_ALL宏的实现方式以及RISC-V汇编调用约定，然后在现有代码基础上完成指定功能。
> 
> **一、需要读取的文件**
> 请优先阅读以下文件，不要在不了解现有代码的情况下直接编写实现：
> 1. `kern/trap/trapentry.S`：重点阅读已经实现的SAVE_ALL宏。查看__alltraps、__trapret和RESTORE_ALL的现有代码及预留位置。明确SAVE_ALL对通用寄存器、sp和CSR的保存顺序及偏移量。
> 2. `kern/trap/trap.h`：阅读struct pushregs和struct trapframe的定义。明确各个寄存器及CSR在Trapframe中的排列顺序。
> 3. `kern/trap/trap.c`：阅读trap(struct trapframe *tf)的函数定义及调用关系。理解C语言Trap处理函数如何接收Trapframe。
> 4. `Makefile`和`tools/function.mk`：了解项目使用的交叉编译工具链及汇编文件编译方式。
> 如果上述文件中存在其他与Trapframe或汇编宏实现直接相关的定义，也可以进一步阅读，但不要修改其他任何文件。
> 
> **二、需要实现的函数和汇编功能**
> 本模块只需要实现`kern/trap/trapentry.S`中的以下两个部分：
> 1. **RESTORE_ALL宏**
> * 功能：实现Trap上下文恢复功能，与现有的SAVE_ALL宏严格对应。
> * 具体要求：从当前内核栈顶的Trapframe中读取之前保存的处理器上下文。按照struct pushregs和struct trapframe的实际内存布局恢复通用寄存器。恢复保存的sstatus、sepc等CSR状态。正确恢复原始栈指针sp。保证所有需要恢复的寄存器都与SAVE_ALL中的保存位置一一对应。恢复完成后，为后续执行sret做好准备。
> * **特别注意**：SAVE_ALL对x2(sp)的保存方式与其他通用寄存器不同。SAVE_ALL通过 `csrw sscratch, sp` 暂存原始sp，随后分配Trapframe空间，最后通过 `csrrw s0, sscratch, x0` 取出原始sp并保存到Trapframe的 `2*REGBYTES(sp)` 位置。因此，RESTORE_ALL必须根据这一保存方式恢复原始sp，不能简单地将所有寄存器使用相同的LOAD方式恢复。
> 2. **__alltraps入口**
> * 功能：建立汇编 Trap 入口与 C 语言 `trap(struct trapframe *tf)` 之间的调用关系，使保存后的 Trap frame 能够按照 RISC-V 调用约定正确传递给 trap()。
> * 具体要求：首先执行已经提供的SAVE_ALL，保存当前Trap上下文。获取当前Trapframe的起始地址。按照RISC-V 64位函数调用约定，将Trapframe地址作为第一个参数传递给C函数。调用 `trap(struct trapframe *tf)`。保证调用过程中不会破坏后续恢复Trapframe所需要的信息。trap()返回后，能够顺利进入__trapret。由__trapret调用RESTORE_ALL，最后通过sret返回原执行流。
> 
> **三、实现约束和可用接口**
> 1. 必须使用RISC-V 64位汇编语法，符合当前项目的编译环境。
> 2. RESTORE_ALL必须严格按照SAVE_ALL的保存顺序和偏移量恢复寄存器，不能自行设计新的Trapframe布局。
> 3. Trapframe总共占用36个REGBYTES：32个通用寄存器位置；4个CSR保存位置。
> 4. CSR的保存顺序为：32*REGBYTES(sp)：sstatus；33*REGBYTES(sp)：sepc；34*REGBYTES(sp)：sbadaddr；35*REGBYTES(sp)：scause。
> 5. 恢复原始sp时，必须特别处理x2的保存位置，确保恢复后的sp指向Trap发生之前的栈位置。
> 6. __alltraps必须按照RISC-V ABI约定使用a0传递第一个参数，即当前Trapframe的起始地址。调用C函数时，必须保证栈指针满足RISC-V ABI的栈对齐要求。
> 7. sstatus和sepc必须恢复到对应的CSR中，不能仅恢复到普通通用寄存器。
> 8. 最终通过sret返回，不能使用普通的ret代替。
> 
> **四、修改限制与最终检查**
> 只允许修改`kern/trap/trapentry.S`中与本模块有关的RESTORE_ALL和__alltraps预留实现位置，不允许修改SAVE_ALL、struct pushregs、trap()函数签名或其他任何文件。
> 完成后请检查：LOAD偏移量是否一一对应、原始sp恢复过程是否正确、a0参数传递和函数调用过程是否规范、能否顺利进入__trapret并通过sret返回。请在项目文件里实际修改你的代码，完成后尝试编译并如实汇报结果。

---

### 练习二：功能模块二（中断与异常处理）

**Prompt 如下：**

> **任务**：在我现在打开的这个文件夹里面，即 `\\wsl.localhost\Ubuntu\home\jiangyuhan\OS-course\RISCV\labcodes\lab3_part1` 里直接按照如下prompt编写代码。完成 Lab3 功能模块二“中断与异常处理”，目标文件是 `kern/trap/trap.c`。模块一已经有实现，请沿用现有代码。
> 
> **操作要求**：必须修改项目实际文件，在 `//lab3 function2 2514207` 处补全实现。只允许补此模块及必需的头文件、内部宏和静态变量；不改已有其他函数、模块一汇编、Trap frame、内存管理器或评分测试。
> **输出要求**：代码保持准确简单。完成后简述修改和验证结果；可运行时执行 `make`、`make grade`，说明普通 QEMU 下的打印与关机表现，不能运行就明确说明。
> 
> **先阅读**实际的 `trap.c`、`trap.h`、`clock.c/h`、`libs/riscv.h`、`libs/sbi.h` 以及 `tools/test_lab3.c`、`tools/grade.sh`。
> - `struct trapframe` 含 `gpr` 和 `uintptr_t` 类型的 `status、epc、badvaddr、cause`；`epc` 会在返回时恢复到 `sepc`。
> - `trap_dispatch()` 已按 `cause` 最高位区分中断与异常；中断分类仍需去掉最高位标志。
> - 已有 `TICK_NUM=100`、`extern volatile size_t ticks`、`clock_set_next_event()`、`print_ticks()`、`print_trapframe(tf)`；`print_ticks()` 输出 `100 ticks`。
> - 原因宏使用 `libs/riscv.h` 的实际定义，包括 `IRQ_S_TIMER`、`IRQ_S_SOFT`、`CAUSE_ILLEGAL_INSTRUCTION`、`CAUSE_BREAKPOINT`。
> - `sbi_shutdown()` 在 `libs/sbi.h` 中声明，需要加入该头文件。
> - 当前工程未定义 `SHUTDOWN_AFTER`。新增可由编译宏覆盖的默认值 10，含义为打印 10 次统计信息后关机；这是本次约定值。
> 
> **必须实现下面两个非 static 函数，签名不变**：
> `void interrupt_handler(struct trapframe *tf);`
> `void exception_handler(struct trapframe *tf);`
> 不增加其他公开接口，不修改无关寄存器快照。
> 
> **1. interrupt_handler**
> - Pre-Condition：`tf` 有效，`cause` 提供中断原因；测试也可能直接传入不带最高位标志的原因码。
> - Post-Condition：完成对应分类处理；未关机时返回统一 Trap 流程，保持 `tf->epc` 不变。
> - Case 1：S 时钟中断时安排下一次事件，`ticks` 恰好增加一次。每累计 `TICK_NUM` 次调用现有 `print_ticks()`；累计打印达到 `SHUTDOWN_AFTER` 次时调用 `sbi_shutdown()`。打印次数须跨调用保留。
> - Case 2：对框架已有的软件、其他时钟和外部中断宏分类打印。S 软件中断须包含原文 `Supervisor software interrupt`。
> - Case 3：未知中断打印 `Unknown interrupt: cause <十进制原因码>`，再调用 `print_trapframe(tf)`；原因码 15 应输出 `Unknown interrupt: cause 15`。
> - Requirements：不在处理函数中主动开中断，不改时钟驱动和现有 `print_ticks()`。
> 
> **2. exception_handler**
> - Pre-Condition：`tf` 有效；非法指令和断点的 `epc` 指向可读取的实验指令。
> - Post-Condition：按异常原因处理；非法指令、断点处理后从下一条指令继续，其他异常保留现场并打印。
> - Case 1：非法指令输出以 `Illegal instruction at` 开头的信息及原指令地址，然后按实际指令长度更新 `tf->epc`。
> - Case 2：断点输出以 `Breakpoint at` 开头的信息及原指令地址，然后按实际指令长度更新 `tf->epc`。
> - Case 3：其他异常仅调用 `print_trapframe(tf)`，不读取其指令内存、不修改 `epc`。
> - Requirements：本实验处理 16/32 位指令，根据指令编码区分 2/4 字节，不按异常类型固定偏移。只在前两种情况读取前 16 位；地址打印保留 RV64 宽度。不要实现额外的异常恢复框架。