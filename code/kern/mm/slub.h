#ifndef __KERN_MM_SLUB_H__
#define __KERN_MM_SLUB_H__

#include <pmm.h>

/* 简化版 SLUB 分配器（Challenge 扩展任务）。
 *
 * 二层架构：上层是按对象大小分类的 kmem_cache，下层是 Buddy 页分配器。
 * 每个 cache 用一条 freelist 串联所有空闲对象，取用/归还都是 O(1)。
 */

/* 支持的固定对象规格：16B / 32B / 64B / 128B。 */
#define SLUB_MIN_SIZE       16
#define SLUB_MAX_SIZE       128

void slub_init(void);       // 初始化各固定大小的 cache
void *kmalloc(size_t size); // 分配 size 字节，返回可直接读写的内核虚拟地址
void kfree(void *ptr);      // 释放 kmalloc 返回的指针
void slub_check(void);      // 自检：往返读写、整页回退、缓存复用

#endif /* !__KERN_MM_SLUB_H__ */
