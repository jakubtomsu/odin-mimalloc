# odin-mimalloc
Odin bindngs for [mimalloc](https://github.com/microsoft/mimalloc)

mimalloc (pronounced "me-malloc") is a general purpose allocator with excellent performance characteristics.

WIP - only builds on windows and not all functions were tested.

# Usage
[Mimalloc API documentation](https://microsoft.github.io/mimalloc/)

Simply copy the `mimalloc` folder somewhere into your project. Then you can just import it:
```odin
import mi "mimalloc"
```
Now you can use all the mimalloc functions. No global init required.

How to override the default `context.allocator`:
```odin
context.allocator = mi.global_allocator()
```

Or with a custom heap:
```odin
heap := mi.heap_new()
context.allocator = mi.heap_allocator(heap)
// ...
mi.heap_destroy(heap)
// Here you might want to restore the context.allocator
```

