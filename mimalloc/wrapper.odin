package mimalloc

import "core:mem"

global_allocator_proc :: proc(
	allocator_data: rawptr,
	mode: mem.Allocator_Mode,
	size, alignment: int,
	old_memory: rawptr,
	old_size: int,
	location := #caller_location) -> ([]byte, mem.Allocator_Error) {

	switch mode {
	case .Alloc:
		ptr := zalloc_aligned(uint(size), uint(alignment))
		return mem.byte_slice(ptr, size), nil

	case .Free:
		free(old_memory)
		return nil, nil

	case .Free_All:
		return nil, .Mode_Not_Implemented

	case .Resize:
		ptr := realloc_aligned(old_memory, uint(size), uint(alignment))
		return mem.byte_slice(ptr, size), nil

	case .Query_Features:
		set := (^mem.Allocator_Mode_Set)(old_memory)
		if set != nil {
			set^ = {.Alloc, .Alloc_Non_Zeroed, .Resize, .Query_Features}
		}
		return nil, nil

	case .Query_Info:
		return nil, .Mode_Not_Implemented

	case .Alloc_Non_Zeroed:
		ptr := malloc_aligned(uint(size), uint(alignment))
		return mem.byte_slice(ptr, size), nil
	}

	return nil, nil
}

global_allocator :: proc() -> mem.Allocator {
	return {
		procedure = global_allocator_proc,
		data = nil,
	}
}