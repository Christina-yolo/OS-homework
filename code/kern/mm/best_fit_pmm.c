#include <pmm.h>
#include <list.h>
#include <string.h>
#include <best_fit_pmm.h>
#include <stdio.h>

//lab2 请补充你在lab2中的代码

// 空闲物理页管理结构。
// free_area_t 通常包含：
// 1. free_list：空闲块链表的头结点
// 2. nr_free：当前空闲物理页的总数量
static free_area_t free_area;

// 使用宏简化成员访问：
// free_list 等价于 free_area.free_list
// nr_free 等价于 free_area.nr_free
#define free_list (free_area.free_list)
#define nr_free (free_area.nr_free)

// 初始化最佳适配分配器。
static void
best_fit_init(void) {
    // 初始化空闲块链表，使其成为一个空的循环双向链表。
    list_init(&free_list);

    // 初始化空闲物理页数量为 0。
    // 后续发现并加入可用内存区域时，再累加空闲页数。
    nr_free = 0;
}

// 将一段连续的物理页加入空闲内存管理结构。
//
// 参数：
// base：这段连续物理页的起始页描述符
// n：这段内存包含的物理页数量
//
// 要求：这 n 个页在加入前必须都处于保留状态。
static void
best_fit_init_memmap(struct Page *base, size_t n) {
    // 要加入的内存区域必须至少包含一个物理页。
    assert(n > 0);

    // 从起始页开始，逐个初始化这段内存中的页描述符。
    struct Page *p = base;
    for (; p != base + n; p ++) {
        // 检查每个页原本都处于保留状态。
        assert(PageReserved(p));

        // 清除页描述符中的标志位和块大小属性。
        // flags 用于记录页的状态；
        // property 用于记录空闲块起始页对应的块大小。
        p->flags = p->property = 0;

        // 将页的引用计数清零。
        set_page_ref(p, 0);
    }

    // 将整段连续内存登记为一个空闲块。
    // 只有空闲块的起始页需要记录整个块的大小。
    base->property = n;

    // 设置起始页的 PageProperty 标志，
    // 表示 base 是一个空闲块的起始页。
    SetPageProperty(base);

    // 更新空闲物理页总数。
    nr_free += n;

    // 如果当前没有任何空闲块，直接将 base 插入空闲链表。
    if (list_empty(&free_list)) {
        list_add(&free_list, &(base->page_link));
    } else {
        // 遍历空闲块链表，按照页描述符地址从小到大的顺序插入。
        list_entry_t *le = &free_list;
        while ((le = list_next(le)) != &free_list) {
            // 根据链表节点 page_link，找到对应的页描述符。
            struct Page *page = le2page(le, page_link);

            // 如果新空闲块的起始地址小于当前空闲块，
            // 就将新空闲块插入当前节点之前。
            if (base < page) {
                list_add_before(le, &(base->page_link));
                break;
            } else if (list_next(le) == &free_list) {
                // 如果已经遍历到最后一个空闲块，
                // 就将新空闲块插入链表尾部。
                list_add(le, &(base->page_link));
            }
        }
    }
}

// 申请 n 个连续的物理页。
//
// Best-Fit（最佳适配）的核心思想：
// 遍历所有空闲块，找到能够容纳 n 页的最小空闲块，
// 尽可能减少分配后剩余空闲块的大小。
//
// 返回值：
// 成功时返回分配块的起始页描述符；
// 失败时返回 NULL。
static struct Page *
best_fit_alloc_pages(size_t n) {
    // 申请数量必须大于 0。
    assert(n > 0);

    // 如果所有空闲页加起来都不够，就直接分配失败。
    if (n > nr_free) {
        return NULL;
    }

    // page 用于保存最终选中的空闲块起始页。
    // 初始为 NULL，表示尚未找到合适的空闲块。
    struct Page *page = NULL;

    // 从空闲链表头结点开始遍历所有空闲块。
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list) {
        // 获取当前空闲块的起始页描述符。
        struct Page *p = le2page(le, page_link);

        // 当前块至少需要包含 n 页。
        // 如果还没有候选块，当前块可以成为候选；
        // 否则，只有当前块比已有候选块更小，才更新候选。
        if (p->property >= n && (page == NULL || p->property < page->property)) {
            page = p;
        }
    }

    // 如果找到了合适的空闲块，就执行分配。
    if (page != NULL) {
        // 保存原空闲块在链表中的前一个节点。
        // 如果分配后有剩余页，将把剩余块插入这个位置之后。
        list_entry_t *prev = list_prev(&(page->page_link));

        // 将被选中的整个空闲块暂时从链表中移除。
        list_del(&(page->page_link));

        // 如果原空闲块大于申请数量，说明还剩下一部分空闲页。
        if (page->property > n) {
            // 剩余空闲块紧接在已分配的 n 页之后。
            struct Page *p = page + n;

            // 记录剩余空闲块的页数。
            p->property = page->property - n;

            // 标记剩余块的起始页。
            SetPageProperty(p);

            // 将剩余块插回空闲链表。
            // prev 是原空闲块之前的节点，插入后仍保持链表地址有序。
            list_add(prev, &(p->page_link));
        }

        // 空闲页总数减少实际分配的 n 页。
        nr_free -= n;

        // 清除原起始页的空闲块标志。
        // page 此时将作为已分配块的起始页返回给调用者。
        ClearPageProperty(page);
    }

    // 返回分配块的起始页。
    // 如果遍历后没有找到大小足够的空闲块，则返回 NULL。
    return page;
}

// 释放从 base 开始的 n 个连续物理页。
//
// 释放后，将这些页重新登记为空闲块，
// 再尝试与地址相邻的前一个和后一个空闲块合并。
static void
best_fit_free_pages(struct Page *base, size_t n) {
    // 释放的页数必须大于 0。
    assert(n > 0);

    // 遍历即将释放的每个物理页。
    struct Page *p = base;
    for (; p != base + n; p ++) {
        // 释放的页不能是保留页，也不能已经是空闲块的起始页。
        // 这可以检查部分非法释放或重复释放情况。
        assert(!PageReserved(p) && !PageProperty(p));

        // 清除页的标志位。
        p->flags = 0;

        // 将页的引用计数重置为 0。
        set_page_ref(p, 0);
    }

    // 将释放的连续页登记为一个新的空闲块。
    base->property = n;

    // 设置空闲块起始页标志。
    SetPageProperty(base);

    // 增加空闲物理页总数。
    nr_free += n;

    // 将新空闲块按地址顺序插入空闲链表。
    if (list_empty(&free_list)) {
        // 如果链表为空，直接插入。
        list_add(&free_list, &(base->page_link));
    } else {
        // 遍历已有空闲块，找到合适的插入位置。
        list_entry_t *le = &free_list;
        while ((le = list_next(le)) != &free_list) {
            // 获取当前空闲块的起始页。
            struct Page *page = le2page(le, page_link);

            // 新块地址小于当前块时，插入当前块之前。
            if (base < page) {
                list_add_before(le, &(base->page_link));
                break;
            } else if (list_next(le) == &free_list) {
                // 如果当前块是最后一个空闲块，
                // 则将新块插入链表尾部。
                list_add(le, &(base->page_link));
            }
        }
    }

    // 向前合并：与前一个相邻空闲块合并
    // 获取新插入空闲块的前一个链表节点。
    list_entry_t *le = list_prev(&(base->page_link));

    // 如果前一个节点不是链表头结点，说明前面存在空闲块。
    if (le != &free_list) {
        // 获取前一个空闲块的起始页。
        p = le2page(le, page_link);

        // 判断前一个空闲块的末尾是否恰好是 base。
        // p + p->property 表示前一个空闲块的后一页。
        if (p + p->property == base) {
            // 两块物理地址连续，将当前块的页数加到前一块。
            p->property += base->property;

            // base 不再是独立空闲块的起始页，清除其标志。
            ClearPageProperty(base);

            // 从链表中删除原来的 base 节点。
            list_del(&(base->page_link));

            // 更新 base，使其指向合并后的整个空闲块起始页。
            base = p;
        }
    }

    // 向后合并：与后一个相邻空闲块合并
    // 获取当前空闲块的下一个链表节点。
    // 注意：如果发生过向前合并，base 已经指向合并后的起始页。
    le = list_next(&(base->page_link));

    // 如果后一个节点不是链表头结点，说明后面存在空闲块。
    if (le != &free_list) {
        // 获取后一个空闲块的起始页。
        p = le2page(le, page_link);

        // 判断当前空闲块的末尾是否恰好是后一个空闲块的起始页。
        if (base + base->property == p) {
            // 两个空闲块地址连续，将后一个块合并到当前块。
            base->property += p->property;

            // 后一个块不再是独立空闲块的起始页，清除其标志。
            ClearPageProperty(p);

            // 从空闲链表中删除后一个块的节点。
            list_del(&(p->page_link));
        }
    }
}

// 返回当前空闲物理页总数。
static size_t
best_fit_nr_free_pages(void) {
    return nr_free;
}


static void
basic_check(void) {
    struct Page *p0, *p1, *p2;
    p0 = p1 = p2 = NULL;
    assert((p0 = alloc_page()) != NULL);
    assert((p1 = alloc_page()) != NULL);
    assert((p2 = alloc_page()) != NULL);

    assert(p0 != p1 && p0 != p2 && p1 != p2);
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);

    assert(page2pa(p0) < npage * PGSIZE);
    assert(page2pa(p1) < npage * PGSIZE);
    assert(page2pa(p2) < npage * PGSIZE);

    list_entry_t free_list_store = free_list;
    list_init(&free_list);
    assert(list_empty(&free_list));

    unsigned int nr_free_store = nr_free;
    nr_free = 0;

    assert(alloc_page() == NULL);

    free_page(p0);
    free_page(p1);
    free_page(p2);
    assert(nr_free == 3);

    assert((p0 = alloc_page()) != NULL);
    assert((p1 = alloc_page()) != NULL);
    assert((p2 = alloc_page()) != NULL);

    assert(alloc_page() == NULL);

    free_page(p0);
    assert(!list_empty(&free_list));

    struct Page *p;
    assert((p = alloc_page()) == p0);
    assert(alloc_page() == NULL);

    assert(nr_free == 0);
    free_list = free_list_store;
    nr_free = nr_free_store;

    free_page(p);
    free_page(p1);
    free_page(p2);
}

// LAB2: below code is used to check the best fit allocation algorithm (your EXERCISE 1) 
// NOTICE: You SHOULD NOT CHANGE basic_check, default_check functions!
static void
best_fit_check(void) {
    int score = 0 ,sumscore = 6;
    int count = 0, total = 0;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list) {
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
        count ++, total += p->property;
    }
    assert(total == nr_free_pages());

    basic_check();

    #ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n",score, sumscore);
    #endif
    struct Page *p0 = alloc_pages(5), *p1, *p2;
    assert(p0 != NULL);
    assert(!PageProperty(p0));

    #ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n",score, sumscore);
    #endif
    list_entry_t free_list_store = free_list;
    list_init(&free_list);
    assert(list_empty(&free_list));
    assert(alloc_page() == NULL);

    #ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n",score, sumscore);
    #endif
    unsigned int nr_free_store = nr_free;
    nr_free = 0;

    // * - - * -
    free_pages(p0 + 1, 2);
    free_pages(p0 + 4, 1);
    assert(alloc_pages(4) == NULL);
    assert(PageProperty(p0 + 1) && p0[1].property == 2);
    // * - - * *
    assert((p1 = alloc_pages(1)) != NULL);
    assert(alloc_pages(2) != NULL);      // best fit feature
    assert(p0 + 4 == p1);

    #ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n",score, sumscore);
    #endif
    p2 = p0 + 1;
    free_pages(p0, 5);
    assert((p0 = alloc_pages(5)) != NULL);
    assert(alloc_page() == NULL);

    #ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n",score, sumscore);
    #endif
    assert(nr_free == 0);
    nr_free = nr_free_store;

    free_list = free_list_store;
    free_pages(p0, 5);

    le = &free_list;
    while ((le = list_next(le)) != &free_list) {
        struct Page *p = le2page(le, page_link);
        count --, total -= p->property;
    }
    assert(count == 0);
    assert(total == 0);
    #ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n",score, sumscore);
    #endif
}

// 声明并注册最佳适配物理内存管理器。
// 内核可以通过 pmm_manager 统一调用这些函数，
// 而不需要直接依赖 Best-Fit 算法的内部实现。
const struct pmm_manager best_fit_pmm_manager = {
    .name = "best_fit_pmm_manager",      // 分配器名称
    .init = best_fit_init,               // 初始化分配器
    .init_memmap = best_fit_init_memmap, // 将一段内存加入空闲管理结构
    .alloc_pages = best_fit_alloc_pages, // 分配连续物理页
    .free_pages = best_fit_free_pages,   // 释放连续物理页
    .nr_free_pages = best_fit_nr_free_pages, // 获取空闲物理页总数
    .check = best_fit_check,             // 运行分配器测试
};
