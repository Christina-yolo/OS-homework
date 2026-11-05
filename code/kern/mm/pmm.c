#include <default_pmm.h>
#include <best_fit_pmm.h>
#include <defs.h>
#include <error.h>
#include <memlayout.h>
#include <mmu.h>
#include <pmm.h>
#include <sbi.h>
#include <stdio.h>
#include <string.h>
#include <../sync/sync.h>
#include <riscv.h>
#include <dtb.h>

// virtual address of physical page array
struct Page *pages;
// amount of physical memory (in pages)
size_t npage = 0;
// the kernel image is mapped at VA=KERNBASE and PA=info.base
uint64_t va_pa_offset;
// memory starts at 0x80000000 in RISC-V
// DRAM_BASE defined in riscv.h as 0x80000000
const size_t nbase = DRAM_BASE / PGSIZE;

// virtual address of boot-time page directory
uintptr_t *satp_virtual = NULL;
// physical address of boot-time page directory
uintptr_t satp_physical;

// physical memory management
const struct pmm_manager *pmm_manager;


static void check_alloc_page(void);

// init_pmm_manager - initialize a pmm_manager instance
static void init_pmm_manager(void) {
    pmm_manager = &default_pmm_manager;
    cprintf("memory management: %s\n", pmm_manager->name);
    pmm_manager->init();
}

// init_memmap - call pmm->init_memmap to build Page struct for free memory
static void init_memmap(struct Page *base, size_t n) {
    pmm_manager->init_memmap(base, n);
}

// alloc_pages - call pmm->alloc_pages to allocate a continuous n*PAGESIZE
// memory
struct Page *alloc_pages(size_t n) {
    struct Page *page = NULL;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        page = pmm_manager->alloc_pages(n);
    }
    local_intr_restore(intr_flag);
    return page;
}

// free_pages - call pmm->free_pages to free a continuous n*PAGESIZE memory
void free_pages(struct Page *base, size_t n) {
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        pmm_manager->free_pages(base, n);
    }
    local_intr_restore(intr_flag);
}

// nr_free_pages - call pmm->nr_free_pages to get the size (nr*PAGESIZE)
// of current free memory
size_t nr_free_pages(void) {
    size_t ret;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        ret = pmm_manager->nr_free_pages();
    }
    local_intr_restore(intr_flag);
    return ret;
}

//lab2 请补充你在lab2中的代码

// init_free_pages - register the physical pages in [start_pa, end_pa) as free
// memory to the current pmm_manager. The range is clipped to the physical
// memory managed by the page descriptor array and rounded to page boundaries.
static void init_free_pages(uintptr_t start_pa, uintptr_t end_pa) { // 将指定物理地址范围内的完整空闲页注册给管理器
    uintptr_t managed_start = (uintptr_t)nbase << PGSHIFT; // 计算页描述符所管理的物理内存起始地址
    uintptr_t managed_end = (uintptr_t)npage << PGSHIFT; // 计算页描述符所管理的物理内存结束地址

    if (start_pa < managed_start) { // 如果起始地址超出管理范围的下界
        start_pa = managed_start; // 将起始地址限制在管理范围内
    }
    if (end_pa > managed_end) { // 如果结束地址超出管理范围的上界
        end_pa = managed_end; // 将结束地址限制在管理范围内
    }
    start_pa = ROUNDUP(start_pa, PGSIZE); // 将起始地址向上对齐到页边界
    end_pa = ROUNDDOWN(end_pa, PGSIZE); // 将结束地址向下对齐到页边界
    if (start_pa >= end_pa) { // 如果范围内不存在完整的物理页
        return; // 直接返回，不注册空闲页
    }
    init_memmap(pa2page(start_pa), (end_pa - start_pa) >> PGSHIFT); // 转换起始物理地址为 Page 指针，并计算页数后注册
}

// page_init - detect physical memory from the device tree, create the page
// descriptor array and hand every free page to the current pmm_manager.
static void page_init(void) { // 探测物理内存、创建页描述符，并将可用物理页注册给管理器
    extern char end[]; // 声明链接器提供的内核映像末尾符号

    uint64_t mem_base = get_memory_base(); // 从设备树读取物理内存的起始地址
    uint64_t mem_size = get_memory_size(); // 从设备树读取物理内存的总大小

    // without valid device tree information the initialization cannot proceed
    if (mem_base == 0 || mem_size == 0) { // 如果起始地址或内存大小为零，说明内存信息无效
        panic("page_init: invalid memory information from device tree"); // 输出错误并终止内核运行
    }

    uintptr_t mem_start = (uintptr_t)mem_base; // 将内存起始地址转换为 uintptr_t 类型
    uintptr_t mem_end = mem_start + (uintptr_t)mem_size; // 计算内存区域的结束地址，结束地址本身不包含在内
    if (mem_end <= mem_start) { // 如果结束地址不大于起始地址，说明范围异常或发生地址溢出
        panic("page_init: physical memory range overflow"); // 报告物理内存地址范围溢出
    }

    // only physical memory above DRAM_BASE is mapped by the boot page table
    if (mem_start < DRAM_BASE) { // 如果内存起点低于实验规定的 DRAM 起始地址
        mem_start = DRAM_BASE; // 将管理范围的起点限制为 DRAM_BASE
    }
    if (mem_end > PHYSICAL_MEMORY_END) { // 如果内存终点超过系统允许管理的物理内存上限
        mem_end = PHYSICAL_MEMORY_END; // 将管理范围的终点限制在 PHYSICAL_MEMORY_END
    }
    if (mem_end <= mem_start) { // 检查截断后是否仍存在有效内存范围
        panic("page_init: no usable physical memory"); // 没有可用物理内存时终止初始化
    }

    // kernel virtual address = physical address + va_pa_offset
    va_pa_offset = PHYSICAL_MEMORY_OFFSET; // 设置内核虚拟地址与物理地址之间的映射偏移量

    // npage is the physical page number just past the end of memory; the
    // descriptor array only covers pages with ppn in [nbase, npage)
    npage = PPN(mem_end); // 计算物理内存结束位置之后的页号
    if (npage <= nbase) { // 如果末尾页号不大于起始页号，说明没有有效的受管理页
        panic("page_init: invalid npage"); // 报告页号范围无效
    }

    // place the page descriptor array right after the kernel image
    pages = (struct Page *)ROUNDUP((uintptr_t)end, PGSIZE); // 将 Page 描述符数组放在内核映像末尾之后，并按页大小对齐

    size_t ndesc = npage - nbase; // 计算需要管理的物理页数量，即需要的 Page 描述符数量
    uintptr_t desc_pa = PADDR((uintptr_t)pages); // 将描述符数组的虚拟地址转换为物理地址
    uintptr_t desc_end_pa = desc_pa + ndesc * sizeof(struct Page); // 计算描述符数组占用区域的物理结束地址
    if (desc_end_pa > mem_end) { // 如果描述符数组超过了物理内存的末尾
        panic("page_init: page descriptors do not fit in physical memory"); // 报告描述符数组无法放入物理内存
    }

    // reserve every page first; init_memmap() clears the free ones
    for (size_t i = 0; i < ndesc; i++) { // 遍历全部受管理的物理页描述符
        SetPageReserved(pages + i); // 先将每个物理页标记为保留页，防止未检查的页被分配
    }

    cprintf("Physical memory: [0x%016lx, 0x%016lx), npage = %lu, nbase = %lu\n", // 输出物理内存的起止地址及页号信息
            mem_start, mem_end, (unsigned long)npage, (unsigned long)nbase); // 传入对应的地址、末尾页号和起始页号
    cprintf("Page descriptors: 0x%016lx, %lu pages (%lu bytes)\n", // 输出描述符数组的地址、数量和占用字节数
            (uintptr_t)pages, (unsigned long)ndesc, // 传入描述符数组虚拟地址和描述符数量
            (unsigned long)(ndesc * sizeof(struct Page))); // 传入整个描述符数组占用的总字节数

    // occupied regions:
    //   [mem_start, KERNEL_BEGIN_PADDR)  : OpenSBI / boot firmware
    //   [KERNEL_BEGIN_PADDR, desc_end_pa): kernel image + page descriptors
    struct { // 定义用于描述已占用物理内存区域的结构体类型
        uintptr_t start; // 已占用区域的起始物理地址
        uintptr_t end; // 已占用区域的结束物理地址，不包含该地址
    } used[2] = { // 创建两个已占用区域的数组

        {mem_start, KERNEL_BEGIN_PADDR}, // 第一个区域：假定为 OpenSBI 或启动固件占用区
        {KERNEL_BEGIN_PADDR, desc_end_pa}, // 第二个区域：内核映像与页描述符数组占用区
    };

    // register each gap between occupied regions separately
    uintptr_t cursor = mem_start; // 设置扫描位置，从物理内存管理范围的起点开始
    for (size_t i = 0; i < sizeof(used) / sizeof(used[0]); i++) { // 依次遍历两个已占用区域
        uintptr_t start = used[i].start; // 取得当前占用区域的起始地址
        uintptr_t end = used[i].end; // 取得当前占用区域的结束地址

        if (start < mem_start) { // 如果区域起点早于当前管理范围
            start = mem_start; // 将区域起点限制到管理范围内
        }
        if (end > mem_end) { // 如果区域终点超出管理范围
            end = mem_end; // 将区域终点限制到管理范围内
        }
        if (start >= end) { // 如果当前区域为空或地址范围无效
            continue; // 跳过该区域，继续检查下一项
        }
        if (start > cursor) { // 如果当前区域起点位于扫描位置之后，说明中间存在空隙
            init_free_pages(cursor, start); // 将扫描位置到当前占用区起点之间的完整页注册为空闲页
        }
        if (end > cursor) { // 如果当前占用区终点超过扫描位置
            cursor = end; // 将扫描位置推进到当前占用区末尾，跳过已占用内存
        }
    }
    if (cursor < mem_end) { // 如果扫描完所有占用区后仍有剩余物理内存
        init_free_pages(cursor, mem_end); // 将最后一段未占用的完整物理页注册为空闲页
    }

    cprintf("Free pages registered: %lu\n", (unsigned long)nr_free_pages()); // 输出注册完成后的空闲物理页数量
}


/* pmm_init - initialize the physical memory management */
void pmm_init(void) {
    // We need to alloc/free the physical memory (granularity is 4KB or other size).
    // So a framework of physical memory manager (struct pmm_manager)is defined in pmm.h
    // First we should init a physical memory manager(pmm) based on the framework.
    // Then pmm can alloc/free the physical memory.
    // Now the first_fit/best_fit/worst_fit/buddy_system pmm are available.
    init_pmm_manager();

    // detect physical memory space, reserve already used memory,
    // then use pmm->init_memmap to create free page list
    page_init();

    // use pmm->check to verify the correctness of the alloc/free function in a pmm
    check_alloc_page();

    extern char boot_page_table_sv39[];
    satp_virtual = (pte_t*)boot_page_table_sv39;
    satp_physical = PADDR(satp_virtual);
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
}

static void check_alloc_page(void) {
    pmm_manager->check();
    cprintf("check_alloc_page() succeeded!\n");
}
