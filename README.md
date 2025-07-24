# Using clangd with Unity Builds

clangd has a restriction where it assumes that a single `.cpp` is self
contained and corresponds to one translation unit (i.e. a `.o` file), see
[issue #45 on clangd](https://github.com/clangd/clangd/issues/45). This does
not play well with unity builds where a single source file may not be self
contained (can compile by itself). However, using clang's `-include` CLI
argument and some pre-processor tricks we can get around this limitation, which
this repository exemplifies.

CMake supports Unity builds with clangd by creating a "normal" build for clangd
to process. In other words, your `.cpp` still need to be self-contained. That
is, you have to program the "standard" way in C++ which requires you to
`#include` what you use in each `.cpp` file. This is tedious compared to modern
languages.

For existing codebases, the CMake option is great. But, what if C/C++ could be
used more like a "modern" language (such as Swift), where all symbols are
available to you anywhere in the codebase and you were not required to
`#include` anything except within the unity build translation unit? This is
what some projects such as [File
Pilot](https://youtu.be/bUOOaXf9qIM?si=ociqwGWgOEH8eKYv&t=1370) does. This is
achieved by this by forward declaring everything in an automatic manner with
codegen, equivalent to using grep/sed using prefixes to define the search
patterns.

Here's how this example works (see the [`src`](./src) and the [`./build.sh`](./build.sh) script):
1. Allocate a file for the unity build ([`src/compile.cpp`](./src/compile.cpp))
    - Include the forward declarations of each symbol before included each `.cpp` file
    - Include each `.cpp` belonging to the translation unit
    - For each `#include "<filename>.cpp"`, surround it with an `#ifndef` guard, I use pattern `CLANGD_TU_<filename>`, e.g.
        ```cpp
        #ifndef CLANGD_TU_a
        #include a.cpp
        #endif
        ```
    - The guard is defined for clangd's `clang_commands.json` compile command (see [`compile_commands_template.json`](./compile_commands_template.json)),
      such that duplicate symbol errors are not generated
    - Dependencies in this example:
        - [`src/b.cpp`](./src/b.cpp) -> [`src/a.cpp`](./src/a.cpp)
        - [`src/main.cpp`](./src/main.cpp) -> [`src/b.cpp`](./src/b.cpp)
2. To handle dependencies, generate forward declarations of all types and functions
    - Define `fn` to nothing (`#define fn `) and prefix all functions you want to be shared within the Translation Unit (all the `.cpp` files)
    - grep (`sed` is used instead) the following in [`./build.sh`](./build.sh):
        - `fn` which generates forward declarations in [`src/meta/fns.h`](./src/meta/fns.h`)
        - `struct` which generates forward declarations in [`src/meta/types.h`](./src/meta/types.h`)
3. Now the following compile commands should work:
    - Compile the full program: `clang++ src/compile.cpp -o build/main`
    - Compile a single source file (for clangd): `clang++ src/a.cpp -include src/compile.cpp -DCLANGD_TU_a`
4. Create a [compile_commands.json](./compile_commands.json) file, where the
   each command is the above. Be sure to use absolute directories in the file.
    - [`./build.sh`](./build.sh) will automatically generate the `compile_commands.json` file from [`compile_commands_template.json`](./compile_commands_template.json)

Enabling symbols to be available in any `.cpp` file does have some limitations, specifically:
- struct/class fields and member functions cannot be forward declared, as such these symbols cannot have cyclical dependencies between files
    - To resolve this, you simply need to resolve the cyclical dependency, which can be solved via:
        1. Order your `#include`'s in topological order and use a new `.cpp` for cyclical dependencies
        2. Declare all types isolated in one or more `.cpp` files and `#include` them in the beginning, or 
            - In other words, this is a system to define a correct topo order + DAG for dependencies
    - Personally, I think doing 1/2 is a good enough tradeoff for member functions
