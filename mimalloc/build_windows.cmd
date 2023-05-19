@echo off

cl /c c\src\static.c /I c\include /Fomimalloc.obj /D_DEBUG /DEBUG
lib /OUT:mimalloc_windows_x64_debug.lib mimalloc.obj
cl /c c\src\static.c /I c\include /Fomimalloc.obj /O2
lib /OUT:mimalloc_windows_x64_release.lib mimalloc.obj

del mimalloc.obj