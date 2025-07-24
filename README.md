# Using clangd with Unity Builds

clangd has a restriction where it assumes that a single `.cpp` is self
contained and corresponds to one translation unit (i.e. a `.o` file). This does not
play well with unity builds where a single source file may not be self
contained (can compile by itself). However, `-include` and some pre-processor
tricks we can get around this limitation, which this repository exemplifies.

CMake supports Unity builds with clangd by creating a "normal" build for clangd
to process. In other words, your `.cpp` still need to be self-contained. That
is, you have to program the "standard" way in C++ which requires you to
`#include` what you use in each `.cpp` file. This is tedious compared to modern
languages.

For existing codebases, the CMake option is great. But, what if C/C++ could be
used more like a "modern" language (such as Swift), where all symbols are
available to you anywhere in the codebase and you were not required to
`#include` anything except within the unity build translation unit? This is
what other projects such as [File Pilot](https://youtu.be/bUOOaXf9qIM?si=ociqwGWgOEH8eKYv&t=1370) does. 

Here's how this example works (see the [src](./src) files):
1. Allocate a file for the unity build ([`src/compile.cpp`](./src/compile.cpp))
    - This file `#include`'s all relevant source files `.cpp` for the translation unit
    - For each include prefix it with an `#ifndef` guard, I use pattern `CLANGD_TL_<filename>`, e.g.
        ```cpp
        #ifndef CLANGD_TL_a
        #include a.cpp
        #endif
        ```
    - Dependencies in this example:
        - [`src/a.cpp`](./src/a.cpp) - depends on -> [`src/b.cpp`](./src/b.cpp)
        - [`src/main.cpp`](./src/main.cpp) - depends on -> [`src/b.cpp`](./src/b.cpp)
2. To handle dependencies, generate forward declarations of all types and functions
    - I define `fn` to nothing (`#define fn `) and prefix all functions I want to be shared across `.cpp` files with this macro
    - I grep (using `sed`) the following in [`./build.sh`](./build.sh):
        - `fn` which generates forward declarations in [`src/meta/fns.h`](./src/meta/fns.h`)
        - `struct` which generates forward declarations in [`src/meta/types.h`](./src/meta/types.h`)
3. Now the following compile commands should work:
    - Compile a single source file: `clang++ src/a.cpp -include src/compile.cpp -DCLANGD_TL_a`
    - 
3. Create a [compile_commands.json](./compile_commands.json) file, where

Enabling symbols to be available in any `.cpp` file does have some limitations, specifically:
- struct/class fields and member functions cannot be forward declared
    - To get around this, you can either:
        1. Order your `#include`'s in topological order and use a new `.cpp` for cyclical dependencies
        2. Declare all types isolated in `.cpp` files and `#include` them in the beginning, or 
        3. Use some preprocessor tricks
    - Personally, I think (1) is a good enough tradeoff for member functions

