package mimalloc

/* ----------------------------------------------------------------------------
Copyright (c) 2018-2023, Microsoft Research, Daan Leijen
This is free software you can redistribute it and/or modify it under the
terms of the MIT license. A copy of the license can be found in the file
"LICENSE" at the root of this distribution.
-----------------------------------------------------------------------------*/

import "core:c"

#assert(size_of(uint) == size_of(c.size_t))

VERSION :: 212   // major + 2 digits minor

SMALL_WSIZE_MAX :: 128
SMALL_SIZE_MAX :: SMALL_WSIZE_MAX * size_of(rawptr)

// heap_t pointer
Heap :: distinct rawptr
// arena_id_t
Arena_Id :: distinct c.int

// block_visit_fun
block_visit_proc :: #type proc "c" (heap: Heap, area: ^Heap_Area, block: rawptr, block_size: uint, arg: rawptr) -> bool
// deferred_free_fun
deferred_free_proc :: #type proc "c" (force: bool, heartbeat: uint, arg: rawptr)
// output_fun
output_proc :: #type proc "c" (msg: cstring, arg: rawptr)
// error_fun
error_proc :: #type proc "c" (err: int, arg: rawptr)

// heap_area_t
// An area of heap space contains blocks of a single size.
Heap_Area :: struct {
    blocks: rawptr,// start of the area containing heap blocks
    reserved: uint,    // bytes reserved for this area (virtual)
    committed: uint,   // current available bytes for this area
    used: uint,  // number of allocated blocks
    block_size: uint,  // size in bytes of each block
    full_block_size: uint, // size in bytes of a full block including padding and metadata.
}

when ODIN_OS == .Windows {
	when ODIN_DEBUG {
		foreign import lib {
            "mimalloc_windows_x64_debug.lib",
            "system:Advapi32.lib",
        }
	} else {
	    foreign import lib {
            "mimalloc_windows_x64_release.lib",
            "system:Advapi32.lib",
        }
	}
} else when ODIN_OS == .Darwin {
    #panic("TODO")
} else when ODIN_OS == .Linux {
    #panic("TODO")
} else {
	#panic("OS currently not supported.")
}

@(default_calling_convention = "c", link_prefix = "mi_")
foreign lib {
    // ------------------------------------------------------
    // Standard malloc interface
    // ------------------------------------------------------

    malloc :: proc(size: uint) -> rawptr ---
    calloc :: proc(count: uint, size: uint) -> rawptr ---
    realloc :: proc(p: rawptr, newsize: uint) -> rawptr ---
    expand :: proc(p: rawptr, newsize: uint) -> rawptr ---

    free :: proc(p: rawptr) ---
    strdup :: proc(s: cstring) -> cstring ---
    strndup :: proc(s: cstring, n: uint) -> cstring ---
    realpath :: proc(fname: cstring, resolved_name: cstring) -> cstring ---


    // ------------------------------------------------------
    // Extended functionality
    // ------------------------------------------------------

    malloc_small :: proc(size: uint) -> rawptr ---
    zalloc_small :: proc(size: uint) -> rawptr ---
    zalloc :: proc(size: uint) -> rawptr ---

    mallocn :: proc(count: uint, size: uint) -> rawptr ---
    reallocn :: proc(p: rawptr, count: uint, size: uint) -> rawptr ---
    reallocf :: proc(p: rawptr, newsize: uint) -> rawptr ---

    usable_size :: proc(p: rawptr) -> uint ---
    good_size :: proc(size: uint) -> uint ---


    // ------------------------------------------------------
    // Internals
    // ------------------------------------------------------

    register_deferred_free :: proc(deferred_free: deferred_free_proc, arg: rawptr) ---
    register_output :: proc(out: output_proc, arg: rawptr) ---
    register_error :: proc(fun: error_proc, arg: rawptr) ---

    collect :: proc(force: bool) ---
    version :: proc() -> int---
    stats_reset :: proc() ---
    stats_merge :: proc() ---
    stats_print :: proc(out: rawptr = nil) ---   // backward compatibility: `out` is ignored and should be NULL
    stats_print_out :: proc(out: output_proc, arg: rawptr) ---

    process_init :: proc() ---
    thread_init :: proc() ---
    thread_done :: proc() ---
    thread_stats_print_out :: proc(out: output_proc, arg: rawptr) ---

    process_info :: proc(
        elapsed_msecs: ^uint,
        user_msecs: ^uint,
        system_msecs: ^uint,
        current_rss: ^uint,
        peak_rss: ^uint,
        current_commit: ^uint,
        peak_commit: ^uint,
        page_faults: ^uint) ---


    // -------------------------------------------------------------------------------------
    // Aligned allocation
    // Note that `alignment` always follows `size` for consistency with unaligned
    // allocation, but unfortunately this differs from `posix_memalign` and `aligned_alloc`.
    // -------------------------------------------------------------------------------------

    malloc_aligned :: proc(size: uint, alignment: uint) -> rawptr ---
    malloc_aligned_at :: proc(size: uint, alignment: uint, offset: uint) -> rawptr ---
    zalloc_aligned :: proc(size: uint, alignment: uint) -> rawptr ---
    zalloc_aligned_at :: proc(size: uint, alignment: uint, offset: uint) -> rawptr ---
    calloc_aligned :: proc(count: uint, size: uint, alignment: uint) -> rawptr ---
    calloc_aligned_at :: proc(count: uint, size: uint, alignment: uint, offset: uint) -> rawptr ---
    realloc_aligned :: proc(p: rawptr, newsize: uint, alignment: uint) -> rawptr ---
    realloc_aligned_at :: proc(p: rawptr, newsize: uint, alignment: uint, offset: uint) -> rawptr ---


    // -------------------------------------------------------------------------------------
    // Heaps: first-class, but can only allocate from the same thread that created it.
    // -------------------------------------------------------------------------------------

    heap_new :: proc() -> Heap ---
    // Safe delete a heap without freeing any still allocated blocks in that heap
    heap_delete :: proc(heap: Heap) ---
    heap_destroy :: proc(heap: Heap) ---
    heap_set_default :: proc(heap: Heap) -> Heap ---
    heap_get_default :: proc() -> Heap ---
    heap_get_backing :: proc() -> Heap ---
    heap_collect :: proc(heap: Heap, force: bool) ---

    heap_malloc :: proc(heap: Heap, size: uint) -> rawptr ---
    heap_zalloc :: proc(heap: Heap, size: uint) -> rawptr ---
    heap_calloc :: proc(heap: Heap, count: uint, size: uint) -> rawptr ---
    heap_mallocn :: proc(heap: Heap, count: uint, size: uint) -> rawptr ---
    heap_malloc_small :: proc(heap: Heap, size: uint) -> rawptr ---

    heap_realloc :: proc(heap: Heap, p: rawptr, newsize: uint) -> rawptr ---
    heap_reallocn :: proc(heap: Heap, p: rawptr, count: uint, size: uint) -> rawptr ---
    heap_reallocf :: proc(heap: Heap, p: rawptr, newsize: uint) -> rawptr ---

    heap_strdup :: proc(heap: Heap, s: cstring) -> cstring ---
    heap_strndup :: proc(heap: Heap, s: cstring, n: uint) -> cstring ---
    heap_realpath :: proc(heap: Heap, fname: cstring, resolved_name: cstring) -> cstring ---

    heap_malloc_aligned :: proc(heap: Heap, size: uint, alignment: uint) -> rawptr ---
    heap_malloc_aligned_at :: proc(heap: Heap, size: uint, alignment: uint, offset: uint) -> rawptr ---
    heap_zalloc_aligned :: proc(heap: Heap, size: uint, alignment: uint) -> rawptr ---
    heap_zalloc_aligned_at :: proc(heap: Heap, size: uint, alignment: uint, offset: uint) -> rawptr ---
    heap_calloc_aligned :: proc(heap: Heap, count: uint, size: uint, alignment: uint) -> rawptr ---
    heap_calloc_aligned_at :: proc(heap: Heap, count: uint, size: uint, alignment: uint, offset: uint) -> rawptr ---
    heap_realloc_aligned :: proc(heap: Heap, p: rawptr, newsize: uint, alignment: uint) -> rawptr ---
    heap_realloc_aligned_at :: proc(heap: Heap, p: rawptr, newsize: uint, alignment: uint, offset: uint) -> rawptr ---


    // --------------------------------------------------------------------------------
    // Zero initialized re-allocation.
    // Only valid on memory that was originally allocated with zero initialization too.
    // e.g. `calloc`, `zalloc`, `zalloc_aligned` etc.
    // see <https://github.com/microsoft/mimalloc/issues/63#issuecomment-508272992>
    // --------------------------------------------------------------------------------

    rezalloc :: proc(p: rawptr, newsize: uint) -> rawptr ---
    recalloc :: proc(p: rawptr, newcount: uint, size: uint) -> rawptr ---

    rezalloc_aligned :: proc(p: rawptr, newsize: uint, alignment: uint) -> rawptr ---
    rezalloc_aligned_at :: proc(p: rawptr, newsize: uint, alignment: uint, offset: uint) -> rawptr ---
    recalloc_aligned :: proc(p: rawptr, newcount: uint, size: uint, alignment: uint) -> rawptr ---
    recalloc_aligned_at :: proc(p: rawptr, newcount: uint, size: uint, alignment: uint, offset: uint) -> rawptr ---

    heap_rezalloc :: proc(heap: Heap, p: rawptr, newsize: uint) -> rawptr ---
    heap_recalloc :: proc(heap: Heap, p: rawptr, newcount: uint, size: uint) -> rawptr ---

    heap_rezalloc_aligned :: proc(heap: Heap, p: rawptr, newsize: uint, alignment: uint) -> rawptr ---
    heap_rezalloc_aligned_at :: proc(heap: Heap, p: rawptr, newsize: uint, alignment: uint, offset: uint) -> rawptr ---
    heap_recalloc_aligned :: proc(heap: Heap, p: rawptr, newcount: uint, size: uint, alignment: uint) -> rawptr ---
    heap_recalloc_aligned_at :: proc(heap: Heap, p: rawptr, newcount: uint, size: uint, alignment: uint, offset: uint) -> rawptr ---


    // ------------------------------------------------------
    // Analysis
    // ------------------------------------------------------

    heap_contains_block :: proc(heap: Heap, p: rawptr) -> bool ---
    heap_check_owned :: proc(heap: Heap, p: rawptr) -> bool ---
    check_owned :: proc(p: rawptr) -> bool ---

    heap_visit_blocks :: proc(heap: Heap, visit_all_blocks: bool, visitor: block_visit_proc, arg: rawptr) -> bool ---

    // Experimental
    is_in_heap_region :: proc(p: rawptr) -> bool ---
    is_redirected :: proc() -> bool ---

    reserve_huge_os_pages_interleave :: proc(pages: uint, numa_nodes: uint, timeout_msecs: uint) -> int ---
    reserve_huge_os_pages_at :: proc(pages: uint, numa_node: int, timeout_msecs: uint) -> int ---

    reserve_os_memory :: proc(size: uint, commit: bool, allow_large: bool) -> int---
    manage_os_memory :: proc(start: rawptr, size: uint, is_committed: bool, is_large: bool, is_zero: bool, numa_node: int) -> bool ---

    debug_show_arenas :: proc() ---

    // Experimental: heaps associated with specific memory arena's
    arena_area :: proc(arena_id: Arena_Id, size: ^uint) -> rawptr ---
    reserve_huge_os_pages_at_ex :: proc(pages: uint, numa_node: int, timeout_msecs: uint, exclusive: bool, arena_id: ^Arena_Id) -> int ---
    reserve_os_memory_ex :: proc(size: uint, commit: bool, allow_large: bool, exclusive: bool, arena_id: ^Arena_Id) -> int ---
    manage_os_memory_ex :: proc(start: rawptr, size: uint, is_committed: bool, is_large: bool, is_zero: bool, numa_node: int, exclusive: bool, arena_id: ^Arena_Id) -> bool---

    when VERSION >= 182 {
    	// Create a heap that only allocates in the specified arena
        heap_new_in_arena :: proc(arena_id: Arena_Id) -> 	Heap ---
    }

    // deprecated
    @(deprecated="reserve_huge_os_pages is deprecated.")
    reserve_huge_os_pages :: proc(pages: uint, max_secs: f64, pages_reserved: ^uint) -> int ---


    // ------------------------------------------------------
    // Options
    // ------------------------------------------------------

    option_is_enabled :: proc(option: Option) -> bool ---
    option_enable :: proc(option: Option) ---
    option_disable :: proc(option: Option) ---
    option_set_enabled :: proc(option: Option, enable: bool) ---
    option_set_enabled_default :: proc(option: Option, enable: bool) ---

    option_get :: proc(option: Option) -> int ---
    option_get_clamp :: proc(option: Option, min: int, max: int) -> int ---
    option_get_size :: proc(option: Option) -> uint ---
    option_set :: proc(option: Option, value: int) ---
    option_set_default :: proc(option: Option, value: int) ---
} // foreign lib

// option_t
Option :: enum c.int {
    // stable options
    show_errors,                // print error messages
    show_stats,                 // print statistics on termination
    verbose,                    // print verbose messages

    // the following options are experimental (see src/options.h)
    eager_commit,               // eager commit segments? (after `eager_commit_delay` segments) (=1)
    arena_eager_commit,         // eager commit arenas? Use 2 to enable just on overcommit systems (=2)
    purge_decommits,            // should a memory purge decommit (or only reset) (=1)
    allow_large_os_pages,       // allow large (2MiB) OS pages, implies eager commit
    reserve_huge_os_pages,      // reserve N huge OS pages (1GiB/page) at startup
    reserve_huge_os_pages_at,   // reserve huge OS pages at a specific NUMA node
    reserve_os_memory,          // reserve specified amount of OS memory in an arena at startup
    deprecated_segment_cache,
    deprecated_page_reset,
    abandoned_page_purge,       // immediately purge delayed purges on thread termination
    deprecated_segment_reset,
    eager_commit_delay,
    purge_delay,                // memory purging is delayed by N milli seconds use 0 for immediate purging or -1 for no purging at all.
    use_numa_nodes,             // 0 = use all available numa nodes, otherwise use at most N nodes.
    limit_os_alloc,             // 1 = do not use OS memory for allocation (but only programmatically reserved arenas)
    os_tag,                     // tag used for OS logging (macOS only for now)
    max_errors,                 // issue at most N error messages
    max_warnings,               // issue at most N warning messages
    max_segment_reclaim,
    destroy_on_exit,            // if set, release all memory on exit sometimes used for dynamic unloading but can be unsafe.
    arena_reserve,              // initial memory size in KiB for arena reservation (1GiB on 64-bit)
    arena_purge_mult,
    purge_extend_delay,
    _option_last,

    // legacy option names
    large_os_pages = allow_large_os_pages,
    eager_region_commit = arena_eager_commit,
    reset_decommits = purge_decommits,
    reset_delay = purge_delay,
    abandoned_page_reset = abandoned_page_purge,
}