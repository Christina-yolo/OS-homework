#include <buddy_pmm_test.h>

/* 普通构建不编译专用入口和测试数组，避免改变真实池的元数据开销。 */
#ifdef BUDDY_TEST_MODE
#include <buddy_pmm.h>
#include <stdio.h>
#include <string.h>

#define TEST_CAPACITY ((PHYSICAL_MEMORY_END - DRAM_BASE) / PGSIZE)
#define SMALL_COUNT 32

static struct Page small_pool[SMALL_COUNT];
#if BUDDY_TEST_MODE == BUDDY_TEST_POSITIVE
/* 大数组仅用于高阶边界例子；不放到只有 8 KiB 的内核栈上。 */
static struct Page large_pool[TEST_CAPACITY];
static struct Page failed_before[SMALL_COUNT];
static struct Page *held[SMALL_COUNT];
#endif

/*
 * 测试目的：给每个例子建立独立初态，并检验 init 不依赖已就绪的 pages。
 * 准备条件：仅限可丢弃的专用启动；count 为有效描述符数量。
 * 操作：先置 pages=NULL、npage=0 调 init，再同步全局映射并初始化保留页。
 * 预期结果：尚无空闲页，每个描述符均保留；不恢复前一个例子的管理状态。
 * 为什么能检验：若 init 偷读 pages 会失败；同步 npage 后 page2ppn 才有意义。
 */
static void
reset_test_pool(size_t count) {
    assert(count > 0 && count <= TEST_CAPACITY);
    pages = NULL;
    npage = 0;
    buddy_pmm_manager.init();
    assert(nr_free_pages() == 0); // init 只能清空内部状态，不能访问描述符。
#if BUDDY_TEST_MODE == BUDDY_TEST_POSITIVE
    pages = count <= SMALL_COUNT ? small_pool : large_pool;
#else
    assert(count <= SMALL_COUNT);
    pages = small_pool;
#endif
    npage = nbase + count;
    memset(pages, 0, count * sizeof(struct Page));
    for (size_t i = 0; i < count; i++) {
        SetPageReserved(pages + i);
        list_init(&pages[i].page_link);
    }
}

#if BUDDY_TEST_MODE == BUDDY_TEST_POSITIVE
/*
 * 测试目的：从公开描述符检查空闲首页、覆盖范围、伙伴合并和真实页数。
 * 准备条件：expected 是例子独立算出的空闲页数，不访问分配器私有链表。
 * 操作：顺序扫描首页及其内部页，合计块大小，核对计数与伙伴状态。
 * 预期结果：块大小为 2 的幂、按绝对页号对齐、互不重叠且全部已登记。
 * 为什么能检验：例如 4 页块必须按 4 对齐；只数“有几个首页”会漏掉大小错误。
 */
static void
check_free_blocks(size_t expected) {
    size_t count = npage - nbase, total = 0, previous_end = 0;
    for (size_t i = 0; i < count; i++) {
        if (!PageProperty(pages + i)) {
            continue; // 非首页可能是空闲内部页，不能直接视为已分配页。
        }
        size_t size = pages[i].property;
        assert(size > 0 && (size & (size - 1)) == 0);
        assert(size <= count - i); // 先验证整个块，才能检查内部描述符。
        assert((nbase + i) % size == 0);
        assert(i >= previous_end); // 按地址扫描时，新块不能落入上一个块内。
        for (size_t j = 0; j < size; j++) {
            assert(!PageReserved(pages + i + j));
            assert(page_ref(pages + i + j) == 0);
            assert(j == 0 || !PageProperty(pages + i + j));
        }
        size_t partner = (nbase + i) ^ size;
        if (partner >= nbase && partner < npage && size <= npage - partner) {
            struct Page *buddy = pages + (partner - nbase);
            assert(!PageProperty(buddy) || buddy->property != size);
            // 如索引 0、4 各有一个空闲 4 页块，就应该已合并成 8 页。
        }
        previous_end = i + size;
        total += size;
    }
    assert(total == expected);
    assert(nr_free_pages() == expected); // 总数必须以物理页为单位，而非块数。
}

/*
 * 测试目的：检验一个实际返回块的范围、对齐、每页标志和引用计数。
 * 准备条件：actual 来自常数例子或独立整数推导，例如请求 3 的实际大小为 4。
 * 操作：先按整数地址验证描述符，再检查整个实际块，不写物理页数据。
 * 预期结果：实际块合法且对齐，每页 ref=0，没有保留或空闲首页标志。
 * 为什么能检验：只检查请求的 3 页会漏掉其实际占用的第 4 页。
 */
static void
check_allocated(struct Page *page, size_t actual) {
    assert(page != NULL);
    uintptr_t start = (uintptr_t)pages, addr = (uintptr_t)page;
    assert(addr >= start && (addr - start) % sizeof(struct Page) == 0);
    size_t index = (addr - start) / sizeof(struct Page);
    assert(index < npage - nbase);
    assert(actual <= npage - nbase - index);
    assert(page2ppn(page) % actual == 0);
    for (size_t i = 0; i < actual; i++) {
        assert(page_ref(page + i) == 0);
        assert(!PageReserved(page + i) && !PageProperty(page + i));
    }
}

/*
 * 测试目的：确认合法 NULL 失败不会悄悄破坏公开状态。
 * 准备条件：只用于至多 32 页的小池；request 必须是正整数且预期无法满足。
 * 操作：静态数组保存描述符副本，仅比较 ref、flags、property 和链表指针。
 * 预期结果：返回 NULL、计数和相关字段不变；后续由例子验证分配能力。
 * 为什么能检验：总数不变也可能链表已损坏；副本绝不用来恢复或伪造状态。
 */
static void
expect_null_unchanged(size_t request) {
    size_t count = npage - nbase, before = nr_free_pages();
    assert(count <= SMALL_COUNT && request > 0);
    memcpy(failed_before, pages, count * sizeof(struct Page));
    assert(alloc_pages(request) == NULL);
    assert(nr_free_pages() == before);
    for (size_t i = 0; i < count; i++) {
        assert(pages[i].ref == failed_before[i].ref);
        assert(pages[i].flags == failed_before[i].flags);
        assert(pages[i].property == failed_before[i].property);
        assert(pages[i].page_link.prev == failed_before[i].page_link.prev);
        assert(pages[i].page_link.next == failed_before[i].page_link.next);
    }
}

/*
 * 测试目的：逐页占满指定的可用页面，并按实际索引保存返回值。
 * 准备条件：小池中正好有 count 个空闲页；held 是静态的至多 32 项数组。
 * 操作：反复申请 1 页，检查返回值和计数，以真实索引判重并扫描剩余空闲块。
 * 预期结果：每页恰好取得一次；返回第一次取得的页，供唯一源块例子核对。
 * 为什么能检验：不假设同阶按低地址返回，之后可可靠辨认索引 1 和 2。
 */
static struct Page *
allocate_singles(size_t count) {
    assert(count <= SMALL_COUNT && nr_free_pages() == count);
    memset(held, 0, sizeof(held));
    struct Page *first = NULL;
    for (size_t i = 0; i < count; i++) {
        struct Page *page = alloc_pages(1);
        check_allocated(page, 1);
        size_t index = page - pages;
        assert(index < SMALL_COUNT && held[index] == NULL);
        held[index] = page;
        if (i == 0) {
            first = page;
        }
        check_free_blocks(count - i - 1);
    }
    return first;
}

/*
 * 测试目的：检验空池、不规则登记、多次登记及未登记空洞。
 * 准备条件：各例重新建立 16 页描述符池，实际绝对页号起点按 16 对齐。
 * 操作：登记 [1,14) 并逐页用尽；再分别试相邻区间和隔着空洞的两个区间。
 * 预期结果：13 页不丢不多；[0,4)+[4,8) 可申请 8 页，隔洞的两个 4 页不能。
 * 为什么能检验：总空闲 8 不等于有合法 8 页块；未交付页面必须保持保留。
 */
static void
test_initialization(void) {
    reset_test_pool(16);
    check_free_blocks(0);
    expect_null_unchanged(1);
    buddy_pmm_manager.init_memmap(pages + 1, 13);
    check_free_blocks(13);
    allocate_singles(13);
    expect_null_unchanged(1);
    for (size_t i = 0; i < 16; i++) {
        if (i >= 1 && i < 14) {
            assert(held[i] == pages + i); // 得到且仅得到登记的 13 个页面。
            free_pages(held[i], 1);
        } else {
            assert(held[i] == NULL && PageReserved(pages + i));
        }
    }
    check_free_blocks(13);
    cprintf("PASS initialization.empty_and_irregular (13 pages)\n");

    reset_test_pool(16);
    buddy_pmm_manager.init_memmap(pages, 4);
    check_free_blocks(4);
    buddy_pmm_manager.init_memmap(pages + 4, 4);
    check_free_blocks(8);
    struct Page *page = alloc_pages(8);
    check_allocated(page, 8);
    assert(page == pages); // 只交付了这个唯一的对齐 8 页块。
    check_free_blocks(0);
    free_pages(page, 8);
    check_free_blocks(8);
    cprintf("PASS initialization.adjacent_registrations\n");

    reset_test_pool(16);
    buddy_pmm_manager.init_memmap(pages, 4);
    buddy_pmm_manager.init_memmap(pages + 8, 4);
    check_free_blocks(8);
    expect_null_unchanged(8);
    struct Page *left = alloc_pages(4), *right = alloc_pages(4);
    check_allocated(left, 4);
    check_allocated(right, 4);
    assert(left != right);
    assert((left == pages && right == pages + 8) ||
           (left == pages + 8 && right == pages));
    check_free_blocks(0);
    free_pages(left, 4);
    free_pages(right, 4);
    check_free_blocks(8);
    for (size_t i = 0; i < 16; i++) {
        if ((i >= 4 && i < 8) || i >= 12) {
            assert(PageReserved(pages + i)); // 合并不能穿过保留空洞。
        }
    }
    cprintf("PASS initialization.holes (8 free, request 8 fails)\n");
}

/*
 * 测试目的：同时保留不同大小的请求，验证独立预期的取整、计数和互不重叠。
 * 准备条件：32 页池完整登记；请求 1、2、3、4、5、8，期望占 1、2、4、4、8、8。
 * 操作：逐次申请并两两比较实际区间，再按原请求释放。
 * 预期结果：一共占用 27 页，剩 5 页；释放后恢复 32 页。
 * 为什么能检验：3→4、5→8 由常数给出，未调用分配器自己的取整函数作答案。
 */
static void
test_allocation(void) {
    const size_t requests[] = {1, 2, 3, 4, 5, 8};
    const size_t actual[] = {1, 2, 4, 4, 8, 8};
    struct Page *blocks[6];
    reset_test_pool(32);
    buddy_pmm_manager.init_memmap(pages, 32);
    size_t expected = 32;
    for (size_t i = 0; i < 6; i++) {
        blocks[i] = alloc_pages(requests[i]);
        check_allocated(blocks[i], actual[i]);
        expected -= actual[i];
        check_free_blocks(expected);
        for (size_t j = 0; j < i; j++) {
            assert(blocks[i] + actual[i] <= blocks[j] ||
                   blocks[j] + actual[j] <= blocks[i]); // 比较实际占用，不能只比较首页。
        }
    }
    assert(expected == 5);
    for (size_t i = 6; i > 0; i--) {
        free_pages(blocks[i - 1], requests[i - 1]);
        expected += actual[i - 1];
        check_free_blocks(expected);
    }
    assert(expected == 32);
    cprintf("PASS allocation.rounding_range_and_overlap (1,2,3,4,5,8)\n");
}

/*
 * 测试目的：观察 8→4→2→1 拆分、不同释放顺序的逐级合并，区分相邻与伙伴。
 * 准备条件：第一例只有一个对齐 8 页源块；第二例为全部占用的 4 页池。
 * 操作：两轮不同次序归还单页；另只归还索引 1、2，尝试申请 2 页。
 * 预期结果：8 页能力恢复；索引 1、2 相邻却不能合并，全部归还后能申请 4 页。
 * 为什么能检验：nbase 按 4 对齐时，1 XOR 1=0、2 XOR 1=3，故 1 和 2 非伙伴。
 */
static void
test_split_and_merge(void) {
    const unsigned int order[] = {3, 0, 7, 1, 6, 2, 5, 4};
    for (size_t round = 0; round < 2; round++) {
        reset_test_pool(8);
        buddy_pmm_manager.init_memmap(pages, 8);
        assert(allocate_singles(8) == pages); // 唯一源块拆分时应保留低地址半块。
        for (size_t i = 0; i < 8; i++) {
            size_t index = round == 0 ? order[i] : 7 - i;
            free_pages(held[index], 1);
            check_free_blocks(i + 1);
        }
        struct Page *whole = alloc_pages(8);
        check_allocated(whole, 8);
        assert(whole == pages);
        check_free_blocks(0);
        free_pages(whole, 8);
        check_free_blocks(8);
    }
    cprintf("PASS merge.split_and_multilevel (two release orders)\n");

    reset_test_pool(4);
    buddy_pmm_manager.init_memmap(pages, 4);
    allocate_singles(4);
    free_pages(held[1], 1);
    free_pages(held[2], 1);
    check_free_blocks(2);
    expect_null_unchanged(2); // 空闲总数 2，但不存在按 2 对齐的完整伙伴块。
    free_pages(held[0], 1);
    free_pages(held[3], 1);
    check_free_blocks(4);
    struct Page *whole = alloc_pages(4);
    check_allocated(whole, 4);
    check_free_blocks(0);
    free_pages(whole, 4);
    check_free_blocks(4);
    cprintf("PASS merge.adjacent_non_buddies\n");
}

/*
 * 测试目的：覆盖所有可构造阶数（含最高阶）及 2^k 两侧的取整。
 * 准备条件：常规例子至多 32 页；高阶边界用由容量宏推导的静态描述符数组。
 * 操作：各阶仅登记一个对齐块，分别申请释放；用常数表检查 1/3/5/7/9/15/17。
 * 预期结果：每阶实际占用及对齐正确；如 7→8、9→16、15→16、17→32。
 * 为什么能检验：最高阶访问链表末项，可发现最大阶和链表长度混淆；1 是合法请求。
 */
static void
test_order_boundaries(void) {
    size_t largest = 1;
    while (largest <= TEST_CAPACITY / 2) {
        largest *= 2;
    }
    assert(nbase % largest == 0); // 当前 DRAM 起点允许构造最高阶完整对齐块。
    unsigned int order = 0;
    for (size_t size = 1; ; size *= 2, order++) {
        reset_test_pool(size <= SMALL_COUNT ? size : TEST_CAPACITY);
        buddy_pmm_manager.init_memmap(pages, size);
        check_free_blocks(size);
        struct Page *page = alloc_pages(size);
        check_allocated(page, size);
        assert(page == pages); // 此例始终只登记了一个源块。
        check_free_blocks(0);
        free_pages(page, size);
        check_free_blocks(size);
        cprintf("PASS boundaries.order=%u pages=%lu\n", order, (unsigned long)size);
        if (size == largest) {
            break;
        }
    }
    const size_t requests[] = {1, 3, 3, 5, 7, 9, 15, 17};
    const size_t actual[] = {1, 4, 4, 8, 8, 16, 16, 32};
    reset_test_pool(32);
    buddy_pmm_manager.init_memmap(pages, 32);
    for (size_t i = 0; i < sizeof(requests) / sizeof(requests[0]); i++) {
        struct Page *page = alloc_pages(requests[i]);
        check_allocated(page, actual[i]);
        check_free_blocks(32 - actual[i]);
        free_pages(page, requests[i]);
        check_free_blocks(32);
    }
    cprintf("PASS boundaries.power_neighbors (2^k-1 and 2^k+1)\n");
}

/*
 * 测试目的：检查反复取整申请和交错释放是否逐渐丢页或损坏大块能力。
 * 准备条件：32 页池，执行固定的 32 轮，不依赖随机数或其他分配器作模型。
 * 操作：每轮同时持有 3 页和 5 页请求，对应实际 4、8 页；交替释放顺序。
 * 预期结果：计数 32→28→20，每轮恢复 32；最后完整 32 页块仍可申请。
 * 为什么能检验：若按原请求 3/5 而非实际 4/8 记账或错误合并，循环和大块申请会暴露。
 */
static void
test_repeated_use(void) {
    reset_test_pool(32);
    buddy_pmm_manager.init_memmap(pages, 32);
    for (size_t round = 0; round < 32; round++) {
        struct Page *a = alloc_pages(3);
        check_allocated(a, 4);
        check_free_blocks(28);
        struct Page *b = alloc_pages(5);
        check_allocated(b, 8);
        assert(a + 4 <= b || b + 8 <= a);
        check_free_blocks(20);
        if (round % 2 == 0) {
            free_pages(a, 3);
            check_free_blocks(24);
            free_pages(b, 5);
        } else {
            free_pages(b, 5);
            check_free_blocks(28);
            free_pages(a, 3);
        }
        check_free_blocks(32);
    }
    struct Page *whole = alloc_pages(32);
    check_allocated(whole, 32);
    check_free_blocks(0);
    free_pages(whole, 32);
    check_free_blocks(32);
    cprintf("PASS reuse.rounds=32 (requests 3/5, restored 32-page block)\n");
}

/*
 * 测试目的：检验耗尽、碎片、超容量整数和描述符末端，并接入阶数/复用边界。
 * 准备条件：普通例子用 7/8/32 页小池；每个例子都从独立初态开始。
 * 操作：占满后试失败；只释放偶数索引形成碎片；申请 CAPACITY+1 和 size_t 最大值。
 * 预期结果：所有合法失败均为 NULL 且状态不变，随后仍可恢复原有分配能力。
 * 为什么能检验：8 页池空闲 0/2/4/6 共 4 页，却没有一对空闲伙伴，不能申请 2 页。
 */
static void
test_failure_and_boundaries(void) {
    reset_test_pool(8);
    buddy_pmm_manager.init_memmap(pages, 8);
    allocate_singles(8);
    expect_null_unchanged(1);
    for (size_t i = 0; i < 8; i++) {
        free_pages(held[i], 1);
    }
    check_free_blocks(8);
    struct Page *whole = alloc_pages(8);
    check_allocated(whole, 8);
    check_free_blocks(0);
    free_pages(whole, 8);
    check_free_blocks(8);
    cprintf("PASS failure.exhaustion_and_recovery\n");

    reset_test_pool(8);
    buddy_pmm_manager.init_memmap(pages, 8);
    allocate_singles(8);
    for (size_t i = 0; i < 8; i += 2) {
        free_pages(held[i], 1);
    }
    check_free_blocks(4);
    expect_null_unchanged(2);
    for (size_t i = 1; i < 8; i += 2) {
        free_pages(held[i], 1);
    }
    check_free_blocks(8);
    whole = alloc_pages(8);
    check_allocated(whole, 8);
    check_free_blocks(0);
    free_pages(whole, 8);
    check_free_blocks(8);
    cprintf("PASS failure.fragmentation (4 free, request 2 fails)\n");

    reset_test_pool(32);
    buddy_pmm_manager.init_memmap(pages, 32);
    expect_null_unchanged(33);
    expect_null_unchanged((size_t)TEST_CAPACITY + 1);
    expect_null_unchanged((size_t)-1); // 正整数上界，不能让向上取整溢出成 0。
    check_free_blocks(32);
    whole = alloc_pages(32);
    check_allocated(whole, 32);
    check_free_blocks(0);
    free_pages(whole, 32);
    check_free_blocks(32);
    cprintf("PASS boundaries.oversized_requests (33, CAPACITY+1, SIZE_MAX)\n");

    reset_test_pool(7);
    buddy_pmm_manager.init_memmap(pages + 6, 1);
    check_free_blocks(1);
    struct Page *tail = alloc_pages(1);
    check_allocated(tail, 1);
    assert(tail == pages + 6);
    check_free_blocks(0);
    free_pages(tail, 1); // 伙伴索引 6 XOR 1=7 在 npage 外，必须先停下再访问。
    check_free_blocks(1);
    expect_null_unchanged(2);
    for (size_t i = 0; i < 6; i++) {
        assert(PageReserved(pages + i));
    }
    tail = alloc_pages(1); // 失败之后，末端的唯一页面仍能正常再申请。
    check_allocated(tail, 1);
    check_free_blocks(0);
    free_pages(tail, 1);
    check_free_blocks(1);
    cprintf("PASS boundaries.descriptor_tail (7 descriptors, index 6)\n");

    test_order_boundaries();
    test_repeated_use();
}
#endif /* BUDDY_TEST_POSITIVE */

/*
 * 测试目的：分别验证 11 种非法调用确实被 Buddy 的对应断言拒绝。
 * 准备条件：每个 case 单独启动 QEMU，先完成合法初始化或申请，不预先解引用错指针。
 * 操作：打印 START 和模式名后只执行本例错误调用；若返回则明确打印失败标记。
 * 预期结果：START 后在 buddy_pmm.c 出现对应原因的断言诊断并停在 panic 循环。
 * 为什么能检验：例如申请 3 实占 4，但 free(p,4) 仍须拒绝；任意 panic/超时不算通过。
 */
static void
test_negative(unsigned int case_id) {
    static const char *const names[] = {
        "alloc_zero", "init_zero", "init_overlap", "init_oob", "free_zero",
        "free_null", "free_misaligned", "free_foreign", "free_middle",
        "free_wrong_n", "free_twice",
    };
    assert(case_id >= BUDDY_TEST_ALLOC_ZERO && case_id <= BUDDY_TEST_FREE_TWICE);
    reset_test_pool(8);
    struct Page *page = NULL;
    if (case_id != BUDDY_TEST_INIT_ZERO && case_id != BUDDY_TEST_INIT_OOB) {
        buddy_pmm_manager.init_memmap(pages, 8);
    }
    if (case_id == BUDDY_TEST_FREE_ZERO || case_id == BUDDY_TEST_FREE_TWICE) {
        page = alloc_pages(1);
        assert(page != NULL); // 准备必须在 START 前成功，不能把此断言算作预期断言。
    } else if (case_id == BUDDY_TEST_FREE_MIDDLE || case_id == BUDDY_TEST_FREE_WRONG_N) {
        page = alloc_pages(3);
        assert(page != NULL);
    }
    if (case_id == BUDDY_TEST_FREE_TWICE) {
        free_pages(page, 1);
    }
    const char *name = names[case_id - BUDDY_TEST_ALLOC_ZERO];
    cprintf("NEGATIVE START %s\n", name);
    switch (case_id) {
    case BUDDY_TEST_ALLOC_ZERO: alloc_pages(0); break;
    case BUDDY_TEST_INIT_ZERO: buddy_pmm_manager.init_memmap(pages, 0); break;
    case BUDDY_TEST_INIT_OVERLAP: buddy_pmm_manager.init_memmap(pages, 8); break;
    case BUDDY_TEST_INIT_OOB: buddy_pmm_manager.init_memmap(pages + 7, 2); break;
    case BUDDY_TEST_FREE_ZERO: free_pages(page, 0); break;
    case BUDDY_TEST_FREE_NULL: free_pages(NULL, 1); break;
    case BUDDY_TEST_FREE_MISALIGNED:
        free_pages((struct Page *)((uintptr_t)pages + 1), 1); break;
    case BUDDY_TEST_FREE_FOREIGN:
        free_pages((struct Page *)((uintptr_t)pages + 8 * sizeof(struct Page)), 1); break;
    case BUDDY_TEST_FREE_MIDDLE: free_pages(page + 1, 3); break;
    case BUDDY_TEST_FREE_WRONG_N: free_pages(page, 4); break;
    case BUDDY_TEST_FREE_TWICE: free_pages(page, 1); break;
    }
    cprintf("UNEXPECTED RETURN %s\n", name); // 错误调用若返回，就必须判失败。
}

/*
 * 测试目的：按编译期选择运行正向全集或唯一负向例，并隔离正常内核流程。
 * 准备条件：显式 Buddy 专用测试构建；pages 原上下文可被永久替换。
 * 操作：正向依次执行四组函数；负向只执行指定 case；随后原地等待退出 QEMU。
 * 预期结果：只有全部正向断言通过才有总 PASS；负向由外部核对断言诊断。
 * 为什么能检验：不恢复 pages 假装恢复真实池，也不让后续正常内核误用测试上下文。
 */
void
buddy_test_run(void) {
    assert(pmm_manager == &buddy_pmm_manager);
    assert(nbase % SMALL_COUNT == 0); // 当前页号起点使索引 0/4 等小例子满足绝对对齐。
#if BUDDY_TEST_MODE == BUDDY_TEST_POSITIVE
    cprintf("BUDDY TEST MODE positive (disposable descriptor pools)\n");
    test_initialization();
    test_allocation();
    test_split_and_merge();
    test_failure_and_boundaries();
    cprintf("BUDDY COURSE TESTS PASS\n");
#else
    test_negative(BUDDY_TEST_MODE);
#endif
    while (1) {
        /* 专用启动到此结束，由 Ctrl+A、x 退出；不返回 pmm_init。 */
    }
}
#endif /* BUDDY_TEST_MODE */
