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

	for i in 0..<20 do append(&b, i)
	fmt.println(b)

	delete(b)
}