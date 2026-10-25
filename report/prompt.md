完成操作系统实验的任务一：实现物理内存探测与页描述符初始化功能。

阅读并理解lab2文件夹中的 `kern/mm/pmm.c`、`kern/mm/default_pmm.c`、相关头文件和 Makefile，了解现有的内存管理代码及其实现的功能。

然后在 `kern/mm/pmm.c` 文件中合适位置实现 `static void page_init(void)`函数，
实现以下功能：

1. 根据设备树提供的物理内存信息获取物理内存的起始地址和大小。
2. 计算物理页的数量，初始化页描述符数组。
3. 把排除OpenSBI、内核镜像和描述符数组占用空间后的完整空闲页面使用已有的`init_memmap()` 函数交给当前pmm_manager管理，为后续页面分配提供正确的初始状态。
4. 对每个空闲区间正确进行页面对齐和边界检查，并使用已有的 init_memmap() 将有效空闲页交给当前 pmm_manager 管理；如果存在多个互不连续的空闲区间，应根据实际内存布局分别注册，不得把中间的已占用区域包含在空闲区间内。
5. 正确处理地址转换、内存边界和页对齐，避免把已经占用的内存当作空闲内存。

函数接口声明：

1. page_init() 不接收参数也不返回结果，由pmm.init()调用。
2. 成功返回时应正确设置va_pa_offset（记录内核虚拟地址与物理地址之间的转换关系）、npage（记录整个物理内存范围内有多少个物理页）和pages（指向页描述符数组，也就是每一页的登记册）
3. 输出探测到的物理内存范围，并完成当前物理内存管理器初始空闲区的注册

函数实现约束与可用资源：

1. 必须区分虚拟地址、物理地址、物理页号和Page描述符地址。
2. 正确处理内存范围与页对齐，不能把已经占用的内存当成空闲内存。
3. 设备树信息无效时终止初始化。
4. 无可用完整页面时不得调用init_memmap()。
5. 实现过程中可以使用get_memory_base()、get_memory_size()、panic()、cprintf()、init_memmap()、pa2page()、链接符号end、struct Page及相关全局变量，并使用框架提供的内存上界、地址转换、页面对齐和页面状态宏完成初始化。

修改过程需满足以下要求和限制：

1. 优先只增加完成任务所必需的代码，不要修改其他模块。
2. 不要修改 `default_pmm.c`和其他文件里所有已有的分配、释放、测试函数、宏文件以及数据结构。
3. 必须在项目文件里实际修改你的代码，而不是仅仅展示你的代码。
4. 完成后，检查代码并尝试编译、运行测试，确认实现是否正确，测试代码不要直接写在文件里。
5. 如果编译或测试失败，根据实际报错分析原因并修复。
6. 不要编造测试结果。如果无法运行，请告诉我具体原因和手动验证方法。

用简单易懂的话告诉我：你修改了哪些代码、每部分有什么作用、编译是否通过、运行测试是否通过。
最后把修改的地方单独给我写出来

---

我正在做操作系统实验 lab2 的物理内存分配模块，包含两个任务。请先阅读并理解现有框架，然后直接修改对应的文件：

**【第一阶段：阅读理解与框架分析】**

请先阅读以下文件：

1. kern/mm/pmm.h：理解 struct pmm_manager 的接口定义。
2. kern/mm/default_pmm.c：理解 First-Fit 的参考实现（空闲链表管理、块拆分与合并）。
3. kern/mm/best_fit_pmm.c：查看 basic_check() 和 best_fit_check() 这两个测试函数，分析它们对 Page 状态（如 PG_property 标志位、nr_free 计数）的硬性约定，不得修改这两个测试函数。

**【第二阶段：代码实现】**

任务一：在 kern/mm/pmm.c 中实现 static void page_init(void)

1. 确保 page_init 函数定义在 pmm_init() 之前，或者在文件开头加上 `static void page_init(void);` 的声明，解决隐式声明报错。
2. 使用 get_memory_base() 和 get_memory_size() 读取内存信息，无效则 panic()。
3. 根据 end 符号的虚拟地址用 PADDR(end) 算物理地址并向上页对齐，计算描述符数组的结束地址。
4. 设置好 npage、va_pa_offset 和 pages 指针。
5. 先把所有物理页标记为保留（SetPageReserved），再计算空闲区起点（描述符数组之后页对齐）和终点（内存末端向下页对齐）。
6. 如果 free_start < free_end，调用 init_memmap(pa2page(free_start), free_pages)。

任务二：在 kern/mm/best_fit_pmm.c 实现 Best-Fit

1. 参考 default_pmm.c 实现完整的函数：init, init_memmap, alloc_pages, free_pages, nr_free_pages, check。
2. 注册 const struct pmm_manager best_fit_pmm_manager。
3. 【核心要求】分配时，遍历完整链表，找“最小的、且 property >= n 的块”。
4. 在分配（拆分块）后要正确调用 ClearPageProperty 清除分配页的标志，设置剩余块的新块头标志；释放合并时同理。
5. 在 kern/mm/pmm.c 的 init_pmm_manager 中切换为 best_fit_pmm_manager。

---

# [PROMPT]

**任务**：在当前 RISC-V uCore Lab2 工程中实现页级 Buddy System，并接入内核。已有物理内存初始化和 Best-Fit，本次只新增 Buddy。先完成模块和基础自检，完整测试由第二份提示词完成。本文已包含必要的背景和设计约定，配合已有工程源码使用，不需要另附说明文件或历史验证记录。

文件分工如下，所有路径都相对工程根目录：

- `kern/mm/buddy_pmm.c`：初始化、分配、释放和空闲页计数。
- `kern/mm/buddy_pmm.h`：管理器和检查入口的声明。
- `kern/mm/buddy_pmm_check.c`：真实空闲池中的基础自检。
- `kern/mm/pmm.c`：只在管理器选择处做必要接入。
- `Makefile`、`tools/dev.sh`：接入 Buddy 的编译和运行参数，保留已有功能。

**操作要求**：

1. 必须在项目中修改实际文件，不能只给代码片段。先读下面列出的相关源码，核对已有接口，再开始实现。
2. 保留 page_init()、init_free_pages()、公共 Page 布局、First-Fit、Best-Fit、basic_check()、best_fit_check()、课程评分断言和组员注释。pmm.c 只做必要的头文件和管理器选择接入。
3. 实现、声明和检查分文件。允许增加辅助函数、内部宏和变量，辅助函数及内部状态设为 static，不改变公开接口。不使用 malloc/calloc，大数组不放内核栈，不安装新环境，不硬编码内核结束地址或空闲页数。

**输出要求**：根据下面 [RELY]、[GUARANTEE]、[SPECIFICATION] 的要求修改文件，接口以真实源码为准，不加入无关功能。实际编译和运行，在回复中说明修改的文件、运行命令、关键输出和真实结果，不需要另写验证文档。未运行项明确标注，不预先填写通过结果或编造调试过程。

# [RELY]

## 1. 当前工程与可信源码

- kern/mm/pmm.h、memlayout.h、pmm.c：接口、Page、地址转换和初始化。
- kern/mm/default_pmm.c、best_fit_pmm.c：现有分配器和原测试。
- libs/list.h、defs.h、riscv.h、kern/mm/mmu.h：链表、类型、内存起点和页大小。
- Makefile、tools/function.mk、tools/dev.sh、tools/test_lab2.c：构建、运行和课程检查。

路径均相对工程目录，接口以实际源码为准。

## 2. 已有资源和调用关系

下面是当前源码中与本任务直接有关的定义。使用已有头文件，不要重复定义：

```c
// kern/mm/mmu.h
#define PGSIZE 4096
#define PGSHIFT 12
// libs/riscv.h、kern/mm/memlayout.h
#define DRAM_BASE 0x80000000
#define PHYSICAL_MEMORY_END 0x88000000

struct Page {
    int ref;
    uint64_t flags;
    unsigned int property;
    list_entry_t page_link;
};

struct pmm_manager {
    const char *name;
    void (*init)(void);
    void (*init_memmap)(struct Page *base, size_t n);
    struct Page *(*alloc_pages)(size_t n);
    void (*free_pages)(struct Page *base, size_t n);
    size_t (*nr_free_pages)(void);
    void (*check)(void);
};

extern struct Page *pages;
extern size_t npage;
extern const size_t nbase;
extern const struct pmm_manager *pmm_manager;

struct Page *alloc_pages(size_t n);
void free_pages(struct Page *base, size_t n);
size_t nr_free_pages(void);
```

`pmm_manager` 有 init、init_memmap、alloc_pages、free_pages、nr_free_pages、check 六个接口。可以使用 page_ref()、set_page_ref()、page2ppn()、page2pa()、pa2page()、PageReserved 和 PageProperty 等页面标志宏，以及 libs/list.h 中的链表操作。

- 调用链为 kern_init → dtb_init → pmm_init → init_pmm_manager/init → page_init → init_memmap，之后由 check_alloc_page 调用管理器的 check。init() 先于 page_init()，不能假定 pages/npage 已就绪。
- nbase=DRAM_BASE/PGSIZE，npage 是页号上界，描述符数为 npage-nbase；page2ppn(p)=p-pages+nbase，page2pa(p)=page2ppn(p)<<PGSHIFT。合法物理页号范围为 [nbase,npage)，左端包含、右端不包含。Page 指针不是物理页数据地址。
- init_memmap(base,n) 的参数是连续物理页对应的描述符起点和页数，不是字节地址和字节数。
- 现有初始化负责排除内核、BSS 和描述符占用；交付区间可能不对齐、长度不是 2 的幂，也可能多次交付。

## 3. 已确定的设计约束

以下约定是本次需要实现的设计，不是已有函数：

- 第 k 阶有 2^k 页，用各阶空闲链表管理。容量 CAPACITY=(PHYSICAL_MEMORY_END-DRAM_BASE)/PGSIZE，最大阶为不超过容量的最大 2 的幂对应的阶数，链表数为最大阶加 1。描述符数量不能超过容量，这个容量不是当前空闲页数。
- 按绝对物理页号对齐。块大小为 b 页时，首页页号必须是 b 的倍数，伙伴页号为 page2ppn(base) XOR b。不能跨未登记区域或空洞合并。
- 请求 n 页，实际占用不小于 n 的最小 2 的幂页块。必须用原首页和原请求释放，例如申请 3 页实占 4 页，仍用 free_pages(p,3) 归还。不支持部分释放。
- 使用模块内部静态 requested_n[CAPACITY] 记录原请求，仅已分配首页保存 n，其余为 0。已分配块大小由原请求向上取整得到，不依赖已分配页的 property。不改公共 Page，数组放在 BSS，其占用由已有初始化排除，因此不同管理器的初始空闲页数可以不同。
- 只有空闲块首页带 PageProperty，property 为实际块页数；内部页不带首页标志。已分配页的 property 清零。空闲计数以实际页数为单位，不是块数。
- 同阶取链表首块，不保证最低地址；拆分时低地址半块继续用于分配，高地址半块保留为空闲。
- 只考虑单核启动时的串行调用，不要求增加并发机制。
- 空闲块只覆盖已登记区域，彼此及与已分配块之间不重叠，链表没有重复块，能够合并的空闲伙伴应已经合并。

## 4. 构建与评分现状

默认 Best-Fit；tools/dev.sh 使用现有工具链，也可通过 GCCPREFIX 或 RISCV_TOOL_CHAIN 指定工具链。kern/mm 的 C 文件自动收集。First-Fit、Best-Fit 和 Buddy 是并列管理器，一次启动只选一个。原课程检查要求选中 Best-Fit，且其内部测试包含部分释放等专属行为，不能用它替代 Buddy 测试。

# [GUARANTEE]

## 1. 新增分配模块

新增 kern/mm/buddy_pmm.c、buddy_pmm.h、buddy_pmm_check.c，分别放实现、声明、基础检查。实现以下函数：

```c
static void buddy_init(void);
static void buddy_init_memmap(struct Page *base, size_t n);
static struct Page *buddy_alloc_pages(size_t n);
static void buddy_free_pages(struct Page *base, size_t n);
static size_t buddy_nr_free_pages(void);
void buddy_check(void);

// kern/mm/pmm.c：修改现有函数
static void init_pmm_manager(void);
```

定义 const struct pmm_manager buddy_pmm_manager，名称为 "buddy_pmm_manager"，注册上面六个 Buddy 接口。头文件只公开管理器和检查入口。

## 2. 内核与构建接入

保留 init_pmm_manager(void) 的签名，选择管理器后打印真实名称并调用 init()。提供 PMM=best_fit（缺省）和 PMM=buddy，只有 Buddy 模式启用选择宏。

Best-Fit 保留 obj/、bin/ucore.img；Buddy 使用 obj/buddy/、bin/buddy/ucore.img，避免切换复用旧对象。非法 PMM 报错，Buddy 执行 grade 时明确拒绝。

```bash
./tools/dev.sh PMM=best_fit
./tools/dev.sh qemu PMM=best_fit
./tools/dev.sh grade
./tools/dev.sh PMM=buddy
./tools/dev.sh qemu PMM=buddy
```

# [SPECIFICATION]

## 1. buddy_init

**Pre-Condition**：管理器启动，描述符可能尚未建立。

**Post-Condition**：链表为空、空闲数为 0、申请记录清零，不访问 pages。

## 2. buddy_init_memmap

**Pre-Condition**：管理器已初始化，描述符数组已建立。正常调用要求 n>0，区间完整位于描述符数组内，全部页面仍保留。

**Post-Condition**：合法区间全部加入管理，空闲数恰增 n，保留此前登记和已有分配；空闲块满足对齐和伙伴合并约定。非法登记通过断言拒绝。

**Case 1：合法登记**：整个区间加入管理，引用计数清零，不丢尾页，不加入区间外页面。

**Case 2：多次登记**：保留旧状态，相邻区间满足伙伴条件时可以合并，中间有空洞时不能跨过空洞合并。

**Case 3：非法登记**：零长度、错误描述符指针、越界或包含已登记页面时断言拒绝，不能先改一部分状态再发现错误。

**Requirements**：修改前验证完整区间。指针尚未确认合法前，不对它做数组指针相减或解引用。

## 3. buddy_alloc_pages

**Pre-Condition**：管理器已初始化，正常请求 n>0，可以在空池上申请。

**Post-Condition**：成功时得到连续、对齐且不与已有分配重叠的块；失败返回 NULL，全部状态不变。

**Case 1：分配成功**：实际分配 b=ceil_pow2(n) 页，使用能够满足请求的最小可用阶，必要时拆分。每页 ref=0、没有保留或空闲首页标志，记录原请求，空闲数减 b。

**Case 2：无法满足请求**：请求或取整后的块超过容量、空闲不足，或者总量够但没有合适的连续块时返回 NULL。链表、描述符、记录和计数均保持不变。

**Case 3：零请求**：n 为 0 时断言拒绝。

**Requirements**：取整前检查容量和溢出，避免非法移位。不要求清零物理页数据。

## 4. buddy_free_pages

**Pre-Condition**：管理器已初始化，正常释放必须传尚未释放的原首页和原请求。例如申请 3 实占 4，释放仍传 3。

**Post-Condition**：验证后清除记录、重置页面元数据，归还实际 b 页并逐级合并；空闲数只加 b 一次。

**Case 1：不能合并**：归还整个实际块，加入对应阶，不影响其他分配。

**Case 2：能够合并**：只与同阶、空闲且互为伙伴的块逐级合并，直到不能继续，合并过程不重复增加计数。

**Case 3：非法释放**：零请求、空指针、描述符内部的错误地址、范围外指针、块中间页、部分释放、错请求数和重复释放，均通过断言拒绝。

**Requirements**：修改前验证描述符地址、记录、对齐和完整范围。伙伴整个范围检查合法后才能访问，不能把仅仅相邻的块当作伙伴。

## 5. buddy_nr_free_pages

**Pre-Condition**：管理器已初始化。

**Post-Condition**：无副作用返回空闲页总数，等于各空闲块实际页数之和。

## 6. buddy_check：本阶段基础自检

**Pre-Condition**：选中 Buddy，真实池已建立。

**Post-Condition**：资源足够时，完成 1 页和 3 页申请检查，扣减分别为 1、4，并核对范围、对齐、ref 和标志；按原请求释放后计数恢复。无法完成的项目明确标为跳过，不重建真实池。

**Case 1：资源足够**：完成对应申请和释放，实际检查通过后才输出基础 PASS。

**Case 2：资源不足**：无法完成某项检查时输出 SKIP 和原因，不能把跳过写成通过。

**Requirements**：只归还本函数申请的页面，不在正常启动触发预期 panic，不把基础自检当作完整验证。

## 7. init_pmm_manager 与模式接入

**Pre-Condition**：内核进入管理器选择阶段，描述符可能尚未建立。

**Post-Condition**：pmm_manager 指向选中的管理器，打印真实名称并调用其 init()；原 init→page_init→init_memmap→check 顺序保持不变。

**Case 1：默认或显式 Best-Fit**：使用原 Best-Fit，保留原课程检查行为。

**Case 2：显式 Buddy**：使用 buddy_pmm_manager，后续执行 Buddy 自己的检查。

## 8. 整体验证与记录

实际运行两模式构建和 QEMU、Best-Fit 原评分及模式切换，核对启动日志中 memory management 后的真实名称。另检查非法 PMM 值和 Buddy 下的 grade 是否被拒绝，这些构建参数检查不算分配器非法调用测试。QEMU 末尾循环是预期行为，取得关键输出后用 Ctrl+A、x 退出，只处理本次进程。失败按规格定位修复，在回复中分别说明构建、基础检查、原任务回归和尚待第二阶段覆盖的内容。

---

# [PROMPT]

**任务**：为已经完成模块和基础自检的 Buddy 分配器补充课程测试，检查初始化、分配、释放、伙伴合并、边界情况和非法调用。先执行第一份模块生成提示词，再在同一工程中执行本提示词。本文已包含测试所需的约定，配合已有源码使用，不依赖另附说明文件或历史验证记录。

文件分工如下，所有路径都相对工程根目录：

- `kern/mm/buddy_pmm_test.c`：独立测试池、正向测试和非法调用测试。
- `kern/mm/buddy_pmm_test.h`：测试入口和模式声明。
- `kern/mm/buddy_pmm_check.c`：在 buddy_check() 中接入专用测试，保留普通模式基础自检。
- `Makefile`：增加测试模式，并分开存放各模式的编译文件和镜像。
- `tools/dev.sh`：有需要时少量调整，让现有脚本能传入测试参数。

**操作要求**：

1. 必须在项目中修改实际文件，不能只给出测试代码。先读下列源码核对接口，预期结果按下面约定独立确定，不能照抄分配器内部计算结果。
2. 保留 page_init()、init_free_pages()、公共 Page 布局、原分配器、基础自检、basic_check()、best_fit_check() 和课程评分工具。使用普通 C、数组、循环和 assert，大数组静态存储，不用 malloc/calloc、随机模型或专门读取分配器内部状态的接口。允许增加 static 辅助函数、内部宏和变量，不改变公开接口。
3. 每个测试函数前用中文说明目的、准备、操作、预期及检验原理。出现失败先记录原因，确认是实现 bug 才最小修复，不改弱断言或跳过必测项。

**输出要求**：根据下面 [RELY]、[GUARANTEE]、[SPECIFICATION] 的要求完成测试，接口以真实源码为准，不加入无关功能。在回复中用表说明测试目的、预期、实际、命令和知识点，给出关键输出，不需要另写测试结果文档。区分通过、失败、预期断言和未执行，不预先填写结果或编造调试经历。

# [RELY]

**真实代码**：

- kern/mm/buddy_pmm.c、buddy_pmm.h、buddy_pmm_check.c：被测实现和基础检查。
- kern/mm/pmm.h、pmm.c、memlayout.h、mmu.h，libs/list.h、defs.h、riscv.h：实际接口、类型及页号转换。
- Makefile、tools/dev.sh、kern/debug/assert.h、kern/debug/panic.c：构建、运行和断言诊断。

**可以使用的定义和接口**：

```c
struct Page {
    int ref;
    uint64_t flags;
    unsigned int property;
    list_entry_t page_link;
};

struct pmm_manager {
    const char *name;
    void (*init)(void);
    void (*init_memmap)(struct Page *base, size_t n);
    struct Page *(*alloc_pages)(size_t n);
    void (*free_pages)(struct Page *base, size_t n);
    size_t (*nr_free_pages)(void);
    void (*check)(void);
};

extern struct Page *pages;
extern size_t npage;
extern const size_t nbase;
extern const struct pmm_manager *pmm_manager;
extern const struct pmm_manager buddy_pmm_manager;

struct Page *alloc_pages(size_t n);
void free_pages(struct Page *base, size_t n);
size_t nr_free_pages(void);
void buddy_check(void);
```

管理器的六个接口为 init、init_memmap、alloc_pages、free_pages、nr_free_pages、check。测试可调用真实管理器的初始化接口，以及公共申请、释放、计数函数。还可使用页面标志宏、page_ref()、set_page_ref()、page2ppn() 和现有链表操作，不重复定义已有结构体。

**已确定的行为**：

- 第 k 阶有 2^k 页，按绝对物理页号对齐，伙伴页号为页号 XOR 块页数。请求向上取整为不小于请求的最小 2 的幂，必须按原首页和原请求整块释放，不支持部分释放。申请 3 实占 4，释放仍传 3。
- npage 是页号上界，描述符数为 npage-nbase；nbase=DRAM_BASE/PGSIZE，page2ppn(p)=p-pages+nbase，合法页号范围为 [nbase,npage)，nbase 不改。PGSIZE=4096、DRAM_BASE=0x80000000、PHYSICAL_MEMORY_END=0x88000000，定义以对应头文件为准。容量由 (PHYSICAL_MEMORY_END-DRAM_BASE)/PGSIZE 推导，最大阶为不超过容量的最大 2 的幂对应的阶数，不硬编码实际空闲数。
- 只有空闲首页带 PageProperty，property 为实际块页数。成功分配的整个实际块每页 ref=0，没有保留或空闲首页标志。空闲计数按实际页数变化。
- 合法失败返回 NULL 且状态不变；非法调用断言拒绝。PageProperty=0 也可能是空闲内部页，不读取私有申请表作答案。
- 正常启动先调用管理器 init，再由 page_init/init_free_pages 交付保留页描述符，最后调用 check。init 不得访问尚未就绪的 pages。登记区间可能不对齐、不是 2 的幂，允许多次不重叠登记；登记参数是描述符起点和页数。只合并完整范围合法、非保留、同阶且互为伙伴的空闲块。
- 私有静态申请表及测试数组会增加 BSS，占用由原初始化自动排除。不要要求 Buddy 和 Best-Fit 初始空闲数相等，也不要修改初始化来凑页数。
- 默认管理器为 Best-Fit，显式 PMM=buddy 才选 Buddy。保留普通 Buddy 的基础自检，课程 grade 只用 Best-Fit。不能把 Best-Fit 中的部分释放测试直接套给 Buddy。
- 只考虑单核串行调用，不要求随机压力、多核或物理页内容读写测试，不声称验证了这些内容。
- 下文区间都是描述符索引，采用左闭右开写法，例如 [1,14) 表示索引 1 到 13，共 13 页。小例子从满足块对齐的位置开始；当前 nbase 满足所需对齐，测试中应检查这一点。
- panic 输出后停在循环中，不会自动退出。构建参数被拒绝不等于分配器负向测试已执行。

# [GUARANTEE]

**必须实现的测试入口和函数**：

```c
void buddy_test_run(void);
static void reset_test_pool(size_t count);
static void test_initialization(void);
static void test_allocation(void);
static void test_split_and_merge(void);
static void test_failure_and_boundaries(void);
static void test_negative(unsigned int case_id);

// 修改现有检查入口，增加测试模式分支
void buddy_check(void);
```

buddy_pmm_test.h 声明测试入口，可以声明其不返回普通流程的属性。其余辅助函数和状态设为 static，模式标识与 Makefile 保持一致。

**构建接入**：提供 BUDDY_TEST=none（缺省）、positive 和下表负向模式；非 none 只允许 PMM=buddy。非法模式或参数组合报错。各专用模式使用 obj/buddy/<模式>/、bin/buddy/<模式>/ucore.img，普通模式不编入专用入口和大数组。

```bash
./tools/dev.sh qemu PMM=buddy
./tools/dev.sh qemu PMM=buddy BUDDY_TEST=positive
./tools/dev.sh qemu PMM=buddy BUDDY_TEST=free_wrong_n
./tools/dev.sh grade PMM=best_fit
```

# [SPECIFICATION]

## 1. reset_test_pool：直观、独立的测试环境

**Pre-Condition**：仅用于专用测试启动，单核串行调用；count 大于 0 且不超过测试容量，不再需要上一个用例的分配状态。

**Post-Condition**：用静态 Page 数组作描述符，pages 指向测试数组，npage=nbase+count。真实管理器已初始化，页面全部保留、尚未登记，空闲数为 0。每例重新建立初态。

**Requirements**：常规池不超过 32 页，高阶边界可用容量推导的大数组；检查 init 在 pages/npage 未就绪时也能调用。只操作描述符，不写推导出的物理页。测试替换上下文后不返回正常内核流程，不用仅恢复 pages 的方式假装恢复分配器。

## 2. test_initialization

**Pre-Condition**：BUDDY_TEST=positive，每个子用例重新建立测试池。

**Post-Condition**：完成空池、不规则区间、多次登记和空洞检查，空闲数、可分配范围和保留页面均符合预期。

**Case 1：空池和不规则区间**：空池申请 1 页返回 NULL。另建至少 15 页的池，登记 [1,14) 后空闲 13 页，逐页恰好取得这 13 页，两侧仍保留。全部按原请求释放后恢复 13 页。

**Case 2：相邻区间分次登记**：登记 [0,4)、[4,8) 后空闲 8 页，能申请完整的 8 页块，释放后恢复。

**Case 3：中间有空洞**：另建池登记 [0,4)、[8,12)，中间仍保留。总空闲 8 页但申请 8 页失败，两个 4 页块仍可分别申请和释放。

## 3. test_allocation

**Pre-Condition**：BUDDY_TEST=positive，建立并登记对齐的 32 页池。

**Post-Condition**：同时申请 1、2、3、4、5、8 页，实占分别为 1、2、4、4、8、8 页，剩余 5 页。范围、对齐和计数正确，分配互不重叠。按原请求全部释放后恢复 32 页。

**Requirements**：检查整个实际块，包括取整多出的页面。每页 ref=0，没有保留或空闲首页标志，不要求特定返回地址。

## 4. test_split_and_merge

**Pre-Condition**：BUDDY_TEST=positive，每个子用例使用独立且对齐的测试池。

**Post-Condition**：证明大块能够拆分，合法伙伴能逐级合并，相邻非伙伴不会被错误合并。

**Case 1：拆分和合并**：将唯一的 8 页块拆成单页，以不同顺序释放，最后申请 8 页成功，不能只核对总数。

**Case 2：相邻但非伙伴**：4 页池分配完后，只释放索引 1、2 的页面，此时申请 2 页失败；全部归还后申请 4 页成功。

## 5. test_failure_and_boundaries

**Pre-Condition**：BUDDY_TEST=positive，每个子用例重新准备。常规用例使用小池，高阶用例可使用静态大池。

**Post-Condition**：完成耗尽、碎片、阶数、数值边界和反复使用检查，合法分配按原请求释放，失败不改变原状态。

**Case 1：耗尽与碎片**：逐页耗尽后再申请 1 页返回 NULL。另建 8 页池并分配完，只归还偶数索引页，空闲 4 页但申请 2 页失败；全归还后申请 8 页成功。

**Case 2：阶数和数值边界**：每个可构造阶均申请释放，包含 1 页和最大阶。覆盖有效正请求 2^k-1、2^k、2^k+1 的取整，以及分配恰好到描述符末端的情况。超过可支持块大小的请求应失败，CAPACITY+1 和 size_t 最大值返回 NULL；零请求另放负向测试。

**Case 3：失败状态不变**：在预期返回 NULL 前保存计数和小池 Page 字段，失败后比较，并检查后续分配能力。副本只用于比较，不写回去掩盖错误。

**Case 4：反复使用**：至少 32 轮同时申请 3 页和 5 页，再按原请求释放。每轮计数恢复，最后仍能申请原来的完整大块。

## 6. test_negative：非法调用逐例启动

**Pre-Condition**：case_id 对应有效负向模式。每例独立 QEMU，合法准备后打印 NEGATIVE START 和模式名，再调用错误接口。

**Post-Condition**：出现原因相符的 Buddy 断言并停在 panic 循环；若返回则打印 UNEXPECTED RETURN，判失败。

| 模式 | 错误调用与检查原因 |
| --- | --- |
| alloc_zero | alloc_pages(0)，零申请 |
| init_zero | init_memmap(base,0)，零登记 |
| init_overlap | 重复登记同一范围 |
| init_oob | 合法首页，长度越过描述符末端 |
| free_zero | 合法申请后 free_pages(p,0) |
| free_null | free_pages(NULL,1) |
| free_misaligned | 地址位于描述符内部 |
| free_foreign | 地址在当前描述符范围外 |
| free_middle | 申请 3 后用 p+1 释放 |
| free_wrong_n | 申请 3 后 free_pages(p,4) |
| free_twice | 同一分配释放两次 |

**Requirements**：错误指针只传参，不提前解引用。核对 START 后 Buddy 源码中的对应断言，不能把准备失败、任意 panic 或超时当通过；不声称检查了 panic 后恢复。

## 7. buddy_test_run

**Pre-Condition**：显式测试模式，确认镜像和管理器选择正确。

**Post-Condition**：执行选中的测试模式，结束后停在循环中，不返回普通内核流程。

**Case 1：positive**：执行全部四个正向测试函数，逐项通过才打印 PASS，全部完成后打印 BUDDY COURSE TESTS PASS。不以资源不足跳过必测项。

**Case 2：负向模式**：只调用对应的 test_negative() 用例，预期在断言处停止。

## 8. buddy_check

**Pre-Condition**：当前管理器为 Buddy，内核准备运行管理器检查。

**Post-Condition**：根据构建模式进入原基础自检或专用测试。

**Case 1：默认 none**：保留真实空闲池的基础检查，结束后归还申请的页面，继续原内核流程。

**Case 2：专用测试模式**：进入 buddy_test_run()，不再继续真实池基础检查或正常内核流程。

## 通用检查与实际运行

由常数或独立整数运算计算预期，不调用分配器自己的取整函数作为答案。正向用例扫描空闲首页，核对块大小为 2 的幂、对齐、范围、不重叠、内部页标志和空闲总数，并检查能合并的伙伴已合并。仅在唯一块例子要求特定地址，不假定同阶总取最低地址。

普通 Buddy、positive 和全部 11 个负向模式都要实际运行，在回复中给出对应关键输出。以下命令可逐例运行负向测试，每例看到 START 和对应断言后按 Ctrl+A、x，再进入下一例：

```bash
for mode in alloc_zero init_zero init_overlap init_oob free_zero free_null \
            free_misaligned free_foreign free_middle free_wrong_n free_twice; do
    ./tools/dev.sh qemu PMM=buddy BUDDY_TEST="$mode"
done
```

使用已有工具链，可通过 GCCPREFIX 或 RISCV_TOOL_CHAIN 指定位置。核对启动日志中的管理器名称和所用镜像，不能把不同模式的输出混在一起。还要检查非法模式、Best-Fit 开启专用测试、Buddy 执行 grade 时能否被拒绝，这些不计入 11 个分配器负向用例。

说明相邻非伙伴和总量足够却失败的原因。专用测试等完成标记或断言，不等 satp 输出；用 Ctrl+A、x 退出，只处理本次进程。最后回归普通 Buddy 和 Best-Fit 评分，在回复中分别说明结果。高阶测试只操作描述符，不代表真实空闲池能提供同样大小的物理块，有限用例通过也不代表所有情况正确。

---

我正在做操作系统实验 lab2 的扩展任务 Challenge：实现简化版的 SLUB 内存分配算法。

**【已有基础】**

我已经实现并切换到了 Buddy System（伙伴系统）页分配器，它提供了：

- alloc_pages(n)：分配 n 个物理页，返回 struct Page *。
- free_pages(page, n)：释放物理页。
- 页描述符 struct Page 位于 memlayout.h，包含 ref, flags, property, page_link。

**【SLUB 简化设计规格】**

请在 kern/mm/slub.c（新建）和 kern/mm/slub.h 中实现一个简易的两层架构分配器（不需要完全照搬 Linux，体现思想即可）：

1. 核心数据结构：
   - struct kmem_cache：代表一类固定大小的对象缓存（例如专门管 32 字节的 cache）。
   - 至少支持几种固定大小的缓存：如 16B, 32B, 64B, 128B。
   - 每个 cache 维护一个 freelist（空闲对象链表，使用指针串联空闲内存块）。
2. 接口要求：
   - void slub_init(void)：初始化各个固定大小的 cache。
   - void \*kmalloc(size_t size)：根据申请大小，匹配到合适的 cache。如果该 cache 没有空闲对象，则使用底层的 alloc_pages(1) 申请一个全新的物理页，将其切分成多个对象，串入 freelist，并从中返回一个对象。如果 size 超过最大的 cache 规格（或者超过一页 4KB），直接回退调用 alloc_pages 分配整页并返回页的物理地址。
   - void kfree(void \*ptr)：根据指针地址，判断它属于哪个 cache，将其重新挂回对应 cache 的 freelist（如果它在独立页中）。如果是超大对象，则直接调用 free_pages。
3. 约束与要求：
   - 为了简化，你可以用指针操作直接从页（4KB）的起始地址开始切分对象。
   - kmalloc 返回的是可以直接读写的虚拟地址。
   - 请编写清晰的结构体定义和注释，并在接入内核的 kern_init() 中调用 slub_init()。
   - 代码风格保持一致，使用 cprintf 打印必要调试信息。
   - 请直接生成 slub.h 和 slub.c 的完整代码。

请为刚才你生成的 SLUB 分配器编写一个测试函数 void slub_check(void)，可以放在 slub.c 末尾，并需要在 kern_init() 中调用它进行自测。

测试必须覆盖以下核心行为和边界情况，测试过程中使用 cprintf 打印结果，若断言失败使用 panic：

1. 基本分配与释放：
   - 连续分配多个相同大小的对象（如 5 个 32 字节），检查返回指针非空、且互不重叠。
   - 释放其中一个，再次申请同大小对象，检查是否复用了刚刚释放的地址。

2. 不同大小的对象：
   - 依次分配 16, 32, 64, 128 字节的对象，确保它们被分配到不同的 cache（不会互相干扰）。

3. 边界与异常情况：
   - 申请 0 字节：应返回 NULL 或安全处理。
   - 释放 NULL：kfree(NULL) 必须安全忽略，不能崩溃。
   - 分配超大对象（如 5000 字节，超过 4KB 页）：应当走回退路径（调用 alloc_pages），释放时也要正确调用 free_pages。

4. 压力测试：
   - 写一个循环，分配 100 个 64 字节对象，然后全部释放。检查这期间内核的底层页数量（nr_free_pages()）没有发生泄漏（即如果切分复用正常，底层的物理页不应该被无限消耗）。

请直接生成测试函数代码并说明如何集成。
