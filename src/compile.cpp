#include <stdio.h>

#include "meta/types.h"
#include "meta/fns.h"

#define fn

#ifndef CLANGD_TL_a
#include "a.cpp"
#endif

#ifndef CLANGD_TL_b
#include "b.cpp"
#endif

#ifndef CLANGD_TL_main
#include "main.cpp"
#endif
