#include <buddy_pmm.h>
#include <buddy_pmm_test.h>
#include <stdio.h>

/* Basic live-pool checks only; the independent full suite is a later task. */
static bool
check_request(size_t request, size_t actual) {
    size_t before = nr_free_pages();
    if (before < actual) {
        cprintf("buddy basic: SKIP request=%lu (need %lu free pages, have %lu)\n",
                (unsigned long)request, (unsigned long)actual,
                (unsigned long)before);
        return 0;
    }
    struct Page *page = alloc_pages(request);
    if (request == 1) {
        assert(page != NULL);
    }
    if (page == NULL) {
        assert(nr_free_pages() == before);
        cprintf("buddy basic: SKIP request=%lu (no aligned %lu-page block)\n",
                (unsigned long)request, (unsigned long)actual);
        return 0;
    }

    uintptr_t start = (uintptr_t)pages;
    uintptr_t addr = (uintptr_t)page;
    assert(addr >= start);
    assert((addr - start) % sizeof(struct Page) == 0);
    size_t index = (addr - start) / sizeof(struct Page);
    assert(npage > nbase && index < npage - nbase);
    assert(actual <= npage - nbase - index);
    assert((page2ppn(page) & (actual - 1)) == 0);
    assert(nr_free_pages() == before - actual);
    for (size_t i = 0; i < actual; i++) {
        assert(!PageReserved(page + i) && !PageProperty(page + i));
        assert(page_ref(page + i) == 0);
    }
    free_pages(page, request);
    assert(nr_free_pages() == before);
    cprintf("buddy basic: request=%lu actual=%lu PASS (free %lu -> %lu -> %lu)\n",
            (unsigned long)request, (unsigned long)actual,
            (unsigned long)before, (unsigned long)(before - actual),
            (unsigned long)nr_free_pages());
    return 1;
}

void
buddy_check(void) {
    assert(pmm_manager == &buddy_pmm_manager);
#ifdef BUDDY_TEST_MODE
    buddy_test_run();
#endif
    size_t before = nr_free_pages();
    bool single = check_request(1, 1);
    bool rounded = check_request(3, 4);
    assert(nr_free_pages() == before);
    if (single && rounded) {
        cprintf("buddy_check(): basic checks passed (full suite pending)\n");
    } else {
        cprintf("buddy_check(): basic checks incomplete (resource skips above)\n");
    }
}
