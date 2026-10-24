#include <default_pmm.h>
#include <best_fit_pmm.h>
#include <buddy_pmm.h>
#include <defs.h>
#include <error.h>
#include <memlayout.h>
#include <mmu.h>
#include <pmm.h>
#include <sbi.h>
#include <stdio.h>
#include <string.h>
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
#ifdef PMM_USE_BUDDY
    pmm_manager = &buddy_pmm_manager;
#else
    // 任务二：将管理器切换为 Best-Fit 
    pmm_manager = &best_fit_pmm_manager; //需改动
#endif
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
    return pmm_manager->alloc_pages(n);
}

// free_pages - call pmm->free_pages to free a continuous n*PAGESIZE memory
void free_pages(struct Page *base, size_t n) {
    pmm_manager->free_pages(base, n);
}

// nr_free_pages - call pmm->nr_free_pages to get the size (nr*PAGESIZE)
// of current free memory
size_t nr_free_pages(void) {
    return pmm_manager->nr_free_pages();
}

//lab2 function1 2510820

// init_free_pages - register the physical pages in [start_pa, end_pa) as free
// memory to the current pmm_manager. The range is clipped to the physical
// memory managed by the page descriptor array and rounded to page boundaries.
static void init_free_pages(uintptr_t start_pa, uintptr_t end_pa) {
    uintptr_t managed_start = (uintptr_t)nbase << PGSHIFT;
    uintptr_t managed_end = (uintptr_t)npage << PGSHIFT;

    if (start_pa < managed_start) {
        start_pa = managed_start;
    }
    if (end_pa > managed_end) {
        end_pa = managed_end;
    }
    start_pa = ROUNDUP(start_pa, PGSIZE);
    end_pa = ROUNDDOWN(end_pa, PGSIZE);
    if (start_pa >= end_pa) {
        return;
    }
    init_memmap(pa2page(start_pa), (end_pa - start_pa) >> PGSHIFT);
}

// page_init - detect physical memory from the device tree, create the page
// descriptor array and hand every free page to the current pmm_manager.
static void page_init(void) {
    extern char end[];

    uint64_t mem_base = get_memory_base();
    uint64_t mem_size = get_memory_size();

    // without valid device tree information the initialization cannot proceed
    if (mem_base == 0 || mem_size == 0) {
        panic("page_init: invalid memory information from device tree");
    }

    uintptr_t mem_start = (uintptr_t)mem_base;
    uintptr_t mem_end = mem_start + (uintptr_t)mem_size;
    if (mem_end <= mem_start) {
        panic("page_init: physical memory range overflow");
    }

    // only physical memory above DRAM_BASE is mapped by the boot page table
    if (mem_start < DRAM_BASE) {
        mem_start = DRAM_BASE;
    }
    if (mem_end > PHYSICAL_MEMORY_END) {
        mem_end = PHYSICAL_MEMORY_END;
    }
    if (mem_end <= mem_start) {
        panic("page_init: no usable physical memory");
    }

    // kernel virtual address = physical address + va_pa_offset
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;

    // npage is the physical page number just past the end of memory; the
    // descriptor array only covers pages with ppn in [nbase, npage)
    npage = PPN(mem_end);
    if (npage <= nbase) {
        panic("page_init: invalid npage");
    }

    // place the page descriptor array right after the kernel image
    pages = (struct Page *)ROUNDUP((uintptr_t)end, PGSIZE);

    size_t ndesc = npage - nbase;
    uintptr_t desc_pa = PADDR((uintptr_t)pages);
    uintptr_t desc_end_pa = desc_pa + ndesc * sizeof(struct Page);
    if (desc_end_pa > mem_end) {
        panic("page_init: page descriptors do not fit in physical memory");
    }

    // reserve every page first; init_memmap() clears the free ones
    for (size_t i = 0; i < ndesc; i++) {
        SetPageReserved(pages + i);
    }

    cprintf("Physical memory: [0x%016lx, 0x%016lx), npage = %lu, nbase = %lu\n",
            mem_start, mem_end, (unsigned long)npage, (unsigned long)nbase);
    cprintf("Page descriptors: 0x%016lx, %lu pages (%lu bytes)\n",
            (uintptr_t)pages, (unsigned long)ndesc,
            (unsigned long)(ndesc * sizeof(struct Page)));

    // occupied regions:
    //   [mem_start, KERNEL_BEGIN_PADDR)  : OpenSBI / boot firmware
    //   [KERNEL_BEGIN_PADDR, desc_end_pa): kernel image + page descriptors
    struct {
        uintptr_t start;
        uintptr_t end;
    } used[2] = {
        {mem_start, KERNEL_BEGIN_PADDR},
        {KERNEL_BEGIN_PADDR, desc_end_pa},
    };

    // register each gap between occupied regions separately
    uintptr_t cursor = mem_start;
    for (size_t i = 0; i < sizeof(used) / sizeof(used[0]); i++) {
        uintptr_t start = used[i].start;
        uintptr_t end = used[i].end;

        if (start < mem_start) {
            start = mem_start;
        }
        if (end > mem_end) {
            end = mem_end;
        }
        if (start >= end) {
            continue;
        }
        if (start > cursor) {
            init_free_pages(cursor, start);
        }
        if (end > cursor) {
            cursor = end;
        }
    }
    if (cursor < mem_end) {
        init_free_pages(cursor, mem_end);
    }

    cprintf("Free pages registered: %lu\n", (unsigned long)nr_free_pages());
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