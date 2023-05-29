package main

import "core:fmt"
import mi "../mimalloc"

main :: proc() {
    fmt.println("Hello")

    a := mi.malloc(16)
    fmt.println(a)
    a = mi.realloc(a, 1000)
    fmt.println(a)
    mi.free(a)

    context.allocator = mi.global_allocator()
    b: [dynamic]int

    for i in 0 ..< 20 do append(&b, i)
    fmt.println(b)

    delete(b)

    {
        heap := mi.heap_new()
        defer mi.heap_destroy(heap)

        context.allocator = mi.heap_allocator(heap)

        c: [dynamic]f32
        for i in 0 ..< 100 do append(&c, 1.0 / f32(i))
        fmt.println(c)
    }

    // mi.stats_print()
    mi.option_enable(.show_stats)
}
