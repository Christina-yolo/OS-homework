#ifndef __KERN_MM_BUDDY_PMM_TEST_H__
#define __KERN_MM_BUDDY_PMM_TEST_H__

#define BUDDY_TEST_POSITIVE         1
#define BUDDY_TEST_ALLOC_ZERO       2
#define BUDDY_TEST_INIT_ZERO        3
#define BUDDY_TEST_INIT_OVERLAP     4
#define BUDDY_TEST_INIT_OOB         5
#define BUDDY_TEST_FREE_ZERO        6
#define BUDDY_TEST_FREE_NULL        7
#define BUDDY_TEST_FREE_MISALIGNED  8
#define BUDDY_TEST_FREE_FOREIGN     9
#define BUDDY_TEST_FREE_MIDDLE     10
#define BUDDY_TEST_FREE_WRONG_N    11
#define BUDDY_TEST_FREE_TWICE      12

#ifdef BUDDY_TEST_MODE
/* 专用测试替换全局描述符上下文后，永不返回普通内核流程。 */
void buddy_test_run(void) __attribute__((noreturn));
#endif

#endif /* !__KERN_MM_BUDDY_PMM_TEST_H__ */
