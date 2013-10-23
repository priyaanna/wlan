#include <linux/version.h>
#if (LINUX_VERSION_CODE >= KERNEL_VERSION(3,5,0))
#include_next <linux/dma-buf.h>
#else

#if (LINUX_VERSION_CODE >= KERNEL_VERSION(3,0,0))
/*
 * Header file for dma buffer sharing framework.
 *
 * Copyright(C) 2011 Linaro Limited. All rights reserved.
 * Author: Sumit Semwal <sumit.semwal@ti.com>
 *
 * Many thanks to linaro-mm-sig list, and specially
 * Arnd Bergmann <arnd@arndb.de>, Rob Clark <rob@ti.com> and
 * Daniel Vetter <daniel@ffwll.ch> for their support in creation and
 * refining of this idea.
 *
 * This program is free software; you can redistribute it and/or modify it
 * under the terms of the GNU General Public License version 2 as published by
 * the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
 * more details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program.  If not, see <http://www.gnu.org/licenses/>.
 */
#ifndef __DMA_BUF_H__
#define __DMA_BUF_H__

#include <linux/file.h>
#include <linux/err.h>
#include <linux/scatterlist.h>
#include <linux/list.h>
#include <linux/dma-mapping.h>
#include <linux/fs.h>

struct device;
struct dma_buf;
struct dma_buf_attachment;

/**
 * struct dma_buf_ops - operations possible on struct dma_buf
 * @attach: [optional] allows different devices to 'attach' themselves to the
 *	    given buffer. It might return -EBUSY to signal that backing storage
 *	    is already allocated and incompatible with the requirements
 *	    of requesting device.
 * @detach: [optional] detach a given device from this buffer.
 * @map_dma_buf: returns list of scatter pages allocated, increases usecount
 *		 of the buffer. Requires atleast one attach to be called
 *		 before. Returned sg list should already be mapped into
 *		 _device_ address space. This call may sleep. May also return
 *		 -EINTR. Should return -EINVAL if attach hasn't been called yet.
 * @unmap_dma_buf: decreases usecount of buffer, might deallocate scatter
 *		   pages.
 * @release: release this buffer; to be called after the last dma_buf_put.
 * @begin_cpu_access: [optional] called before cpu access to invalidate cpu
 * 		      caches and allocate backing storage (if not yet done)
 * 		      respectively pin the objet into memory.
 * @end_cpu_access: [optional] called after cpu access to flush caches.
 * @kmap_atomic: maps a page from the buffer into kernel address
 * 		 space, users may not block until the subsequent unmap call.
 * 		 This callback must not sleep.
 * @kunmap_atomic: [optional] unmaps a atomically mapped page from the buffer.
 * 		   This Callback must not sleep.
 * @kmap: maps a page from the buffer into kernel address space.
 * @kunmap: [optional] unmaps a page from the buffer.
 * @mmap: used to expose the backing storage to userspace. Note that the
 * 	  mapping needs to be coherent - if the exporter doesn't directly
 * 	  support this, it needs to fake coherency by shooting down any ptes
 * 	  when transitioning away from the cpu domain.
 * @vmap: [optional] creates a virtual mapping for the buffer into kernel
 *	  address space. Same restrictions as for vmap and friends apply.
 * @vunmap: [optional] unmaps a vmap from the buffer
 */
struct dma_buf_ops {
	int (*attach)(struct dma_buf *, struct device *,
			struct dma_buf_attachment *);

	void (*detach)(struct dma_buf *, struct dma_buf_attachment *);

	/* For {map,unmap}_dma_buf below, any specific buffer attributes
	 * required should get added to device_dma_parameters accessible
	 * via dev->dma_params.
	 */
	struct sg_table * (*map_dma_buf)(struct dma_buf_attachment *,
						enum dma_data_direction);
	void (*unmap_dma_buf)(struct dma_buf_attachment *,
						struct sg_table *,
						enum dma_data_direction);
	/* TODO: Add try_map_dma_buf version, to return immed with -EBUSY
	 * if the call would block.
	 */

	/* after final dma_buf_put() */
	void (*release)(struct dma_buf *);

	int (*begin_cpu_access)(struct dma_buf *, size_t, size_t,
				enum dma_data_direction);
	void (*end_cpu_access)(struct dma_buf *, size_t, size_t,
			       enum dma_data_direction);
	void *(*kmap_atomic)(struct dma_buf *, unsigned long);
	void (*kunmap_atomic)(struct dma_buf *, unsigned long, void *);
	void *(*kmap)(struct dma_buf *, unsigned long);
	void (*kunmap)(struct dma_buf *, unsigned long, void *);

	int (*mmap)(struct dma_buf *, struct vm_area_struct *vma);

	void *(*vmap)(struct dma_buf *);
	void (*vunmap)(struct dma_buf *, void *vaddr);
};

/**
 * struct dma_buf - shared buffer object
 * @size: size of the buffer
 * @file: file pointer used for sharing buffers across, and for refcounting.
 * @attachments: list of dma_buf_attachment that denotes all devices attached.
 * @ops: dma_buf_ops associated with this buffer object.
 * @priv: exporter specific private data for this buffer object.
 */
struct dma_buf {
	size_t size;
	struct file *file;
	struct list_head attachments;
	const struct dma_buf_ops *ops;
	/* mutex to serialize list manipulation, attach/detach and vmap/unmap */
	struct mutex lock;
	unsigned vmapping_counter;
	void *vmap_ptr;
	void *priv;
};

/**
 * struct dma_buf_attachment - holds device-buffer attachment data
 * @dmabuf: buffer for this attachment.
 * @dev: device attached to the buffer.
 * @node: list of dma_buf_attachment.
 * @priv: exporter specific attachment data.
 *
 * This structure holds the attachment information between the dma_buf buffer
 * and its user device(s). The list contains one attachment struct per device
 * attached to the buffer.
 */
struct dma_buf_attachment {
	struct dma_buf *dmabuf;
	struct device *dev;
	struct list_head node;
	void *priv;
};

/**
 * get_dma_buf - convenience wrapper for get_file.
 * @dmabuf:	[in]	pointer to dma_buf
 *
 * Increments the reference count on the dma-buf, needed in case of drivers
 * that either need to create additional references to the dmabuf on the
 * kernel side.  For example, an exporter that needs to keep a dmabuf ptr
 * so that subsequent exports don't create a new dmabuf.
 */
#define get_dma_buf LINUX_BACKPORT(get_dma_buf)
static inline void get_dma_buf(struct dma_buf *dmabuf)
{
	get_file(dmabuf->file);
}

#define dma_buf_attach LINUX_BACKPORT(dma_buf_attach)
struct dma_buf_attachment *dma_buf_attach(struct dma_buf *dmabuf,
							struct device *dev);
#define dma_buf_detach LINUX_BACKPORT(dma_buf_detach)
void dma_buf_detach(struct dma_buf *dmabuf,
				struct dma_buf_attachment *dmabuf_attach);
#define dma_buf_export LINUX_BACKPORT(dma_buf_export)
struct dma_buf *dma_buf_export(void *priv, const struct dma_buf_ops *ops,
			       size_t size, int flags);
#define dma_buf_fd LINUX_BACKPORT(dma_buf_fd)
int dma_buf_fd(struct dma_buf *dmabuf, int flags);
#define dma_buf_get LINUX_BACKPORT(dma_buf_get)
struct dma_buf *dma_buf_get(int fd);
#define dma_buf_put LINUX_BACKPORT(dma_buf_put)
void dma_buf_put(struct dma_buf *dmabuf);

#define dma_buf_map_attachment LINUX_BACKPORT(dma_buf_map_attachment)
struct sg_table *dma_buf_map_attachment(struct dma_buf_attachment *,
					enum dma_data_direction);
#define dma_buf_unmap_attachment LINUX_BACKPORT(dma_buf_unmap_attachment)
void dma_buf_unmap_attachment(struct dma_buf_attachment *, struct sg_table *,
				enum dma_data_direction);
#define dma_buf_begin_cpu_access LINUX_BACKPORT(dma_buf_begin_cpu_access)
int dma_buf_begin_cpu_access(struct dma_buf *dma_buf, size_t start, size_t len,
			     enum dma_data_direction dir);
#define dma_buf_end_cpu_access LINUX_BACKPORT(dma_buf_end_cpu_access)
void dma_buf_end_cpu_access(struct dma_buf *dma_buf, size_t start, size_t len,
			    enum dma_data_direction dir);
#define dma_buf_kmap_atomic LINUX_BACKPORT(dma_buf_kmap_atomic)
void *dma_buf_kmap_atomic(struct dma_buf *, unsigned long);
#define dma_buf_kunmap_atomic LINUX_BACKPORT(dma_buf_kunmap_atomic)
void dma_buf_kunmap_atomic(struct dma_buf *, unsigned long, void *);
#define dma_buf_kmap LINUX_BACKPORT(dma_buf_kmap)
void *dma_buf_kmap(struct dma_buf *, unsigned long);
#define dma_buf_kunmap LINUX_BACKPORT(dma_buf_kunmap)
void dma_buf_kunmap(struct dma_buf *, unsigned long, void *);

#define dma_buf_mmap LINUX_BACKPORT(dma_buf_mmap)
int dma_buf_mmap(struct dma_buf *, struct vm_area_struct *,
		 unsigned long);
#define dma_buf_vmap LINUX_BACKPORT(dma_buf_vmap)
void *dma_buf_vmap(struct dma_buf *);
#define dma_buf_vunmap LINUX_BACKPORT(dma_buf_vunmap)
void dma_buf_vunmap(struct dma_buf *, void *vaddr);

#endif /* (LINUX_VERSION_CODE >= KERNEL_VERSION(3,0,0)) */
#endif /* __DMA_BUF_H__ */
#endif /* (LINUX_VERSION_CODE >= KERNEL_VERSION(3,3,0)) */
