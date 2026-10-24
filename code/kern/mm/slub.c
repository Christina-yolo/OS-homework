#include <slub.h>
#include <stdio.h>
#include <string.h>

/* 简化版 SLUB 分配器。
 *
 * 设计要点：
 *   - 每个 kmem_cache 只服务一种固定大小的对象，用一条 freelist 串联所有
 *     空闲对象；空闲对象自身的起始 8 字节存放下一个空闲对象的地址
 *     （RISC-V 64 位下指针正好 8 字节，而最小对象 16 字节，足够容纳）。
 *   - 当 freelist 为空时，向 Buddy 申请一整页（4KB），从页起始地址按对象
 *     大小切分，逐个挂入 freelist。这些 slab 页即使全部空闲也不归还 Buddy，
 *     而是留作缓存复用——这正是 slab/SLUB 缓存的核心思想。
 *   - 超过 SLUB_MAX_SIZE 的请求直接回退为整页分配（alloc_pages）。
 *   - 释放时通过页描述符定位所属 cache：slab 页用 flags 的 bit2 标记，并把
 *     cache 索引存在 page->property 中；整页对象则把页数存在 property 中。
 */

/* flags 的 bit0/bit1 已被 PG_reserved / PG_property 占用，这里取空闲的 bit2。
 * Buddy 的 free_pages 只校验 bit0/bit1，且会把整页 flags 清零，二者不冲突。 */
#define PG_slab              2
#define SetPageSlab(page)    ((page)->flags |= (1UL << PG_slab))
#define ClearPageSlab(page)  ((page)->flags &= ~(1UL << PG_slab))
#define PageSlab(page)       (((page)->flags >> PG_slab) & 1)

/* 固定大小 cache 的索引，按对象大小递增排列。 */
enum {
    SLUB_CACHE_16 = 0,
    SLUB_CACHE_32,
    SLUB_CACHE_64,
    SLUB_CACHE_128,
    SLUB_CACHE_COUNT,
};

struct kmem_cache {
    const char *name;      // 调试用名字
    size_t size;           // 单个对象大小（字节）
    size_t objs_per_page;  // 一页可切分出的对象个数
    void *freelist;        // 空闲对象链表头
    size_t nr_slabs;       // 当前持有的 slab 页数（统计）
    size_t nr_inuse;       // 当前已分配出去的对象数（调试用）
};

static struct kmem_cache kmem_caches[SLUB_CACHE_COUNT];

/* 页 -> 内核虚拟地址：本实验内核用 “物理地址 + va_pa_offset” 直接映射。 */
static inline void *
slub_page2kva(struct Page *page) {
    return (void *)(page2pa(page) + va_pa_offset);
}

/* 选择第一个能装下 size 的 cache；超过最大规格返回 NULL。 */
static struct kmem_cache *
slub_cache_for_size(size_t size) {
    for (size_t i = 0; i < SLUB_CACHE_COUNT; i++) {
        if (size <= kmem_caches[i].size) {
            return &kmem_caches[i];
        }
    }
    return NULL;
}

/* 向 Buddy 申请一页，切分成对象后全部挂入 freelist。 */
static int
slab_grow(struct kmem_cache *cache) {
    struct Page *page = alloc_page();
    if (page == NULL) {
        return -1;
    }
    void *base = slub_page2kva(page);
    SetPageSlab(page);
    page->property = (unsigned int)(cache - kmem_caches);  // 记下所属 cache 索引

    for (size_t i = 0; i < cache->objs_per_page; i++) {
        void *obj = (char *)base + i * cache->size;
        *(void **)obj = cache->freelist;  // 空闲对象头部存下一空闲对象地址
        cache->freelist = obj;
    }
    cache->nr_slabs++;
    cprintf("slub: cache %-12s grown, %lu objects/page, %lu slabs now\n",
            cache->name, (unsigned long)cache->objs_per_page,
            (unsigned long)cache->nr_slabs);
    return 0;
}

/* 从 freelist 头部取出一个对象。 */
static void *
slab_alloc_object(struct kmem_cache *cache) {
    void *obj = cache->freelist;
    assert(obj != NULL);
    cache->freelist = *(void **)obj;
    cache->nr_inuse++;
    return obj;
}

/* 把一个对象放回 freelist 头部。 */
static void
slab_free_object(struct kmem_cache *cache, void *obj) {
    assert(cache->nr_inuse > 0);
    *(void **)obj = cache->freelist;
    cache->freelist = obj;
    cache->nr_inuse--;
}

void
slub_init(void) {
    static const struct {
        const char *name;
        size_t size;
    } specs[SLUB_CACHE_COUNT] = {
        {"kmalloc-16", 16},
        {"kmalloc-32", 32},
        {"kmalloc-64", 64},
        {"kmalloc-128", 128},
    };

    for (size_t i = 0; i < SLUB_CACHE_COUNT; i++) {
        assert(PGSIZE % specs[i].size == 0);
        kmem_caches[i].name = specs[i].name;
        kmem_caches[i].size = specs[i].size;
        kmem_caches[i].objs_per_page = PGSIZE / specs[i].size;
        kmem_caches[i].freelist = NULL;
        kmem_caches[i].nr_slabs = 0;
        kmem_caches[i].nr_inuse = 0;
    }
    cprintf("slub_init: %u caches ready (16/32/64/128 bytes), "
            "oversized (>%u) falls back to pages\n",
            (unsigned int)SLUB_CACHE_COUNT, (unsigned int)SLUB_MAX_SIZE);
}

void *
kmalloc(size_t size) {
    if (size == 0) {
        return NULL;
    }

    struct kmem_cache *cache = slub_cache_for_size(size);
    if (cache != NULL) {
        if (cache->freelist == NULL && slab_grow(cache) != 0) {
            return NULL;
        }
        return slab_alloc_object(cache);
    }

    /* 超大对象：整页回退。返回页对应的内核虚拟地址（可直接读写）。 */
    size_t n = ROUNDUP(size, PGSIZE) / PGSIZE;
    struct Page *page = alloc_pages(n);
    if (page == NULL) {
        return NULL;
    }
    page->property = (unsigned int)n;  // 记下页数，供 kfree 释放
    cprintf("slub: oversized %lu bytes -> %lu page(s)\n",
            (unsigned long)size, (unsigned long)n);
    return slub_page2kva(page);
}

void
kfree(void *ptr) {
    if (ptr == NULL) {
        return;
    }

    struct Page *page = pa2page(PADDR((uintptr_t)ptr));
    if (PageSlab(page)) {
        assert(page->property < SLUB_CACHE_COUNT);
        slab_free_object(&kmem_caches[page->property], ptr);
    } else {
        size_t n = page->property;
        assert(n > 0);
        free_pages(page, n);
    }
}

/* 返回指针所属 cache 的索引；超大对象（整页回退）或非法指针返回 -1。 */
static int
slub_ptr_cache_index(void *ptr) {
    if (ptr == NULL) {
        return -1;
    }
    struct Page *page = pa2page(PADDR((uintptr_t)ptr));
    if (!PageSlab(page)) {
        return -1;
    }
    return (int)page->property;
}

/* 用例 1：基本分配与释放。 */
static void
check_basic_alloc_free(void) {
    enum { kNum = 5 };
    void *objs[kNum];

    /* 连续分配 5 个 32 字节对象，均应成功。 */
    for (size_t i = 0; i < kNum; i++) {
        objs[i] = kmalloc(32);
        if (objs[i] == NULL) {
            panic("slub_check: kmalloc(32) returned NULL at #%lu",
                  (unsigned long)i);
        }
    }

    /* 互不重叠：指针两两不同，且 32 字节区间互不交叠。 */
    for (size_t i = 0; i < kNum; i++) {
        for (size_t j = i + 1; j < kNum; j++) {
            if (objs[i] == objs[j]) {
                panic("slub_check: kmalloc(32) returned duplicate pointer");
            }
            if (!((uintptr_t)objs[i] + 32 <= (uintptr_t)objs[j] ||
                  (uintptr_t)objs[j] + 32 <= (uintptr_t)objs[i])) {
                panic("slub_check: kmalloc(32) objects overlap");
            }
        }
    }

    /* 释放其中一个，再申请同大小对象，应复用刚释放的地址（freelist 后进先出）。 */
    void *freed = objs[2];
    kfree(freed);
    void *again = kmalloc(32);
    if (again != freed) {
        panic("slub_check: kfree+kmalloc did not reuse the freed object");
    }
    kfree(again);
    for (size_t i = 0; i < kNum; i++) {
        if (i != 2) {
            kfree(objs[i]);
        }
    }
    cprintf("slub_check: PASS basic alloc/free + reuse (5 x 32B)\n");
}

/* 用例 2：不同大小对象应落入各自 cache，互不干扰。 */
static void
check_different_caches(void) {
    void *p16 = kmalloc(16);
    void *p32 = kmalloc(32);
    void *p64 = kmalloc(64);
    void *p128 = kmalloc(128);
    if (p16 == NULL || p32 == NULL || p64 == NULL || p128 == NULL) {
        panic("slub_check: kmalloc returned NULL for 16/32/64/128");
    }

    /* 每个对象都应归属于自己规格对应的 cache。 */
    if (slub_ptr_cache_index(p16) != SLUB_CACHE_16 ||
        slub_ptr_cache_index(p32) != SLUB_CACHE_32 ||
        slub_ptr_cache_index(p64) != SLUB_CACHE_64 ||
        slub_ptr_cache_index(p128) != SLUB_CACHE_128) {
        panic("slub_check: objects not routed to their own caches");
    }

    /* 互不干扰：写入不同字节模式并回读。 */
    memset(p16, 0x11, 16);
    memset(p32, 0x22, 32);
    memset(p64, 0x33, 64);
    memset(p128, 0x44, 128);
    if (*(unsigned char *)p16 != 0x11 ||
        *(unsigned char *)p32 != 0x22 ||
        *(unsigned char *)p64 != 0x33 ||
        *(unsigned char *)p128 != 0x44) {
        panic("slub_check: caches interfere with each other");
    }

    kfree(p16);
    kfree(p32);
    kfree(p64);
    kfree(p128);
    cprintf("slub_check: PASS different caches (16/32/64/128B)\n");
}

/* 用例 3：边界与异常情况。 */
static void
check_boundary(void) {
    /* 申请 0 字节：应安全返回 NULL。 */
    if (kmalloc(0) != NULL) {
        panic("slub_check: kmalloc(0) should return NULL");
    }

    /* 释放 NULL：必须安全忽略，且之后系统仍可用。 */
    kfree(NULL);
    void *probe = kmalloc(16);
    if (probe == NULL) {
        panic("slub_check: allocation failed after kfree(NULL)");
    }
    kfree(probe);

    /* 超大对象（>128B）：走整页回退，释放时归还 Buddy，页数不泄漏。 */
    size_t before = nr_free_pages();

    void *big = kmalloc(2000);  // 单页回退
    if (big == NULL) {
        panic("slub_check: kmalloc(2000) returned NULL");
    }
    if (slub_ptr_cache_index(big) != -1) {
        panic("slub_check: 2000B object should fall back to pages");
    }
    memset(big, 0x5A, 2000);
    if (*(unsigned char *)big != 0x5A) {
        panic("slub_check: oversized object read-back failed");
    }
    kfree(big);

    void *huge = kmalloc(5000);  // 跨页回退（>4KB）
    if (huge == NULL) {
        panic("slub_check: kmalloc(5000) returned NULL");
    }
    if (slub_ptr_cache_index(huge) != -1) {
        panic("slub_check: 5000B object should fall back to pages");
    }
    memset(huge, 0x6B, 5000);
    if (*(unsigned char *)huge != 0x6B) {
        panic("slub_check: oversized object read-back failed");
    }
    kfree(huge);

    if (nr_free_pages() != before) {
        panic("slub_check: oversized objects leaked pages");
    }

    cprintf("slub_check: PASS boundary (0B, NULL, 2000B, 5000B)\n");
}

/* 用例 4：压力测试——100 个 64B 对象反复取放，页数应稳定、无泄漏。 */
static void
check_stress(void) {
    enum { kNum = 100 };
    void *objs[kNum];

    size_t before = nr_free_pages();
    for (int i = 0; i < kNum; i++) {
        objs[i] = kmalloc(64);
        if (objs[i] == NULL) {
            panic("slub_check: kmalloc(64) returned NULL at #%d", i);
        }
        memset(objs[i], i & 0xFF, 64);
    }
    /* 两两不同（不重叠）。 */
    for (int i = 0; i < kNum; i++) {
        for (int j = i + 1; j < kNum; j++) {
            if (objs[i] == objs[j]) {
                panic("slub_check: stress duplicate pointer");
            }
        }
    }
    for (int i = 0; i < kNum; i++) {
        if (*(unsigned char *)objs[i] != (unsigned char)(i & 0xFF)) {
            panic("slub_check: stress write/read-back failed at #%d", i);
        }
    }
    size_t held = nr_free_pages();  // 首次取满后，cache 持有的 slab 页已稳定
    void *first_last = objs[kNum - 1];  // 第一轮最后释放的对象，应是复用时的栈顶

    /* 全部释放：缓存对象不归还 Buddy，页数应保持不变。 */
    for (int i = 0; i < kNum; i++) {
        kfree(objs[i]);
    }
    if (nr_free_pages() != held) {
        panic("slub_check: freeing cached objects changed page count");
    }

    /* 再次申请 100 个：应完全复用已缓存对象，不再消耗新页。 */
    for (int i = 0; i < kNum; i++) {
        objs[i] = kmalloc(64);
        if (objs[i] == NULL) {
            panic("slub_check: second round kmalloc returned NULL at #%d", i);
        }
    }
    if (nr_free_pages() != held) {
        panic("slub_check: second round consumed extra pages (leak)");
    }
    if (objs[0] != first_last) {
        panic("slub_check: cached objects not reused (expected LIFO)");
    }
    for (int i = 0; i < kNum; i++) {
        kfree(objs[i]);
    }
    if (nr_free_pages() != held) {
        panic("slub_check: page count changed after second free");
    }

    cprintf("slub_check: PASS stress (100 x 64B, %lu slab page(s), no leak)\n",
            (unsigned long)kmem_caches[SLUB_CACHE_64].nr_slabs);
}

void
slub_check(void) {
    cprintf("slub_check: begin (free pages = %lu)\n",
            (unsigned long)nr_free_pages());

    check_basic_alloc_free();
    check_different_caches();
    check_boundary();
    check_stress();

    /* 全部用例结束后，各 cache 不应有未归还的对象。 */
    for (size_t i = 0; i < SLUB_CACHE_COUNT; i++) {
        if (kmem_caches[i].nr_inuse != 0) {
            panic("slub_check: cache %s leaks %lu object(s)",
                  kmem_caches[i].name,
                  (unsigned long)kmem_caches[i].nr_inuse);
        }
        cprintf("slub_check: cache %-12s slabs=%lu\n",
                kmem_caches[i].name,
                (unsigned long)kmem_caches[i].nr_slabs);
    }

    cprintf("slub_check: all tests passed (free pages = %lu)\n",
            (unsigned long)nr_free_pages());
}
