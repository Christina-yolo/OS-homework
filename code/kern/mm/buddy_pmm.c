#include <buddy_pmm.h>
#include <list.h>
#include <string.h>


//lab2 function2-3 2514207
/* Capacity describes all DRAM, not the (smaller) boot-time free range. */
#define BUDDY_CAPACITY ((PHYSICAL_MEMORY_END - DRAM_BASE) / PGSIZE)
enum {
    BUDDY_MAX_ORDER = 63 - __builtin_clzll(BUDDY_CAPACITY),
    BUDDY_ORDER_COUNT = BUDDY_MAX_ORDER + 1,
};

static list_entry_t free_lists[BUDDY_ORDER_COUNT];
static size_t nr_free;
/* Only an allocated block's head stores its original request. */
static size_t requested_n[BUDDY_CAPACITY];

static size_t
block_pages(unsigned int order) {
    return (size_t)1 << order;
}

/* Reject a foreign/misaligned pointer before any pointer subtraction. */
static size_t
page_index(struct Page *page) {
    assert(pages != NULL && npage > nbase);
    assert(npage - nbase <= BUDDY_CAPACITY);
    uintptr_t addr = (uintptr_t)page;
    uintptr_t start = (uintptr_t)pages;
    assert(page != NULL && addr >= start);
    uintptr_t offset = addr - start;
    assert(offset % sizeof(struct Page) == 0);
    size_t index = offset / sizeof(struct Page);
    assert(index < npage - nbase);
    return index;
}

/* The sentinel also handles requests whose rounded size exceeds capacity. */
static unsigned int
request_order(size_t n) {
    if (n > BUDDY_CAPACITY) {
        return BUDDY_ORDER_COUNT;
    }
    unsigned int order = 0;
    while (order < BUDDY_MAX_ORDER && block_pages(order) < n) {
        order++;
    }
    return block_pages(order) < n ? BUDDY_ORDER_COUNT : order;
}

static void
add_block(struct Page *base, unsigned int order) {
    base->property = block_pages(order);
    SetPageProperty(base);
    list_add(&free_lists[order], &base->page_link);
}

static void
remove_block(struct Page *base) {
    list_del_init(&base->page_link);
    ClearPageProperty(base);
    base->property = 0;
}

/* Caller accounts for newly freed pages exactly once, outside this helper. */
static void
merge_block(struct Page *base, unsigned int order) {
    size_t ppn = page2ppn(base);
    while (order < BUDDY_MAX_ORDER) {
        size_t size = block_pages(order);
        size_t buddy_ppn = ppn ^ size;
        /* Check the complete candidate before constructing its descriptor. */
        if (buddy_ppn < nbase || buddy_ppn >= npage ||
            size > npage - buddy_ppn) {
            break;
        }
        struct Page *buddy = pages + (buddy_ppn - nbase);
        if (PageReserved(buddy) || !PageProperty(buddy) ||
            buddy->property != size || requested_n[buddy_ppn - nbase] != 0) {
            break;
        }
        remove_block(buddy);
        if (buddy_ppn < ppn) {
            base = buddy;
            ppn = buddy_ppn;
        }
        order++;
    }
    add_block(base, order);
}

static void
buddy_init(void) {
    /* pages/npage need not be initialized yet. */
    for (unsigned int order = 0; order < BUDDY_ORDER_COUNT; order++) {
        list_init(&free_lists[order]);
    }
    nr_free = 0;
    memset(requested_n, 0, sizeof(requested_n));
}

static void
buddy_init_memmap(struct Page *base, size_t n) {
    assert(n > 0);
    size_t index = page_index(base);
    assert(n <= npage - nbase - index);
    /* Validate the entire handoff before touching any allocator state. */
    for (size_t i = 0; i < n; i++) {
        assert(PageReserved(base + i));
        assert(requested_n[index + i] == 0);
    }
    for (size_t i = 0; i < n; i++) {
        struct Page *page = base + i;
        page->flags = 0;
        page->property = 0;
        set_page_ref(page, 0);
        list_init(&page->page_link);
    }

    size_t remaining = n;
    while (remaining != 0) {
        size_t ppn = page2ppn(base);
        unsigned int order = BUDDY_MAX_ORDER;
        while (block_pages(order) > remaining ||
               (ppn & (block_pages(order) - 1)) != 0) {
            order--;
        }
        size_t size = block_pages(order);
        merge_block(base, order);
        base += size;
        remaining -= size;
    }
    nr_free += n;
}

static struct Page *
buddy_alloc_pages(size_t n) {
    assert(n > 0);
    unsigned int target = request_order(n);
    if (target == BUDDY_ORDER_COUNT || block_pages(target) > nr_free) {
        return NULL;
    }
    unsigned int order = target;
    while (order < BUDDY_ORDER_COUNT && list_empty(&free_lists[order])) {
        order++;
    }
    if (order == BUDDY_ORDER_COUNT) {
        return NULL;
    }

    struct Page *base = le2page(list_next(&free_lists[order]), page_link);
    remove_block(base);
    while (order > target) {
        order--;
        /* Keep the low half; the high half remains free. */
        add_block(base + block_pages(order), order);
    }
    size_t size = block_pages(target);
    size_t index = page_index(base);
    for (size_t i = 0; i < size; i++) {
        assert(!PageReserved(base + i) && !PageProperty(base + i));
        assert(requested_n[index + i] == 0);
        base[i].property = 0;
        set_page_ref(base + i, 0);
    }
    requested_n[index] = n;
    nr_free -= size;
    return base;
}

static void
buddy_free_pages(struct Page *base, size_t n) {
    assert(n > 0);
    size_t index = page_index(base);
    assert(requested_n[index] == n);
    unsigned int order = request_order(n);
    assert(order < BUDDY_ORDER_COUNT);
    size_t size = block_pages(order);
    assert(size <= npage - nbase - index);
    assert(((nbase + index) & (size - 1)) == 0);
    /* Validate all pages before clearing the allocation record or metadata. */
    for (size_t i = 0; i < size; i++) {
        assert(!PageReserved(base + i) && !PageProperty(base + i));
        assert(i == 0 || requested_n[index + i] == 0);
    }
    requested_n[index] = 0;
    for (size_t i = 0; i < size; i++) {
        base[i].flags = 0;
        base[i].property = 0;
        set_page_ref(base + i, 0);
        list_init(&base[i].page_link);
    }
    merge_block(base, order);
    nr_free += size;
}

static size_t
buddy_nr_free_pages(void) {
    return nr_free;
}

const struct pmm_manager buddy_pmm_manager = {
    .name = "buddy_pmm_manager",
    .init = buddy_init,
    .init_memmap = buddy_init_memmap,
    .alloc_pages = buddy_alloc_pages,
    .free_pages = buddy_free_pages,
    .nr_free_pages = buddy_nr_free_pages,
    .check = buddy_check,
};
