#include <stdio.h>

#include "meta/types.h"
#include "meta/fns.h"

#define fn

#ifndef CLANGD_TU_a
#include "a.cpp"
#endif

#ifndef CLANGD_TU_b
#include "b.cpp"
#endif

#ifndef CLANGD_TU_main
#include "main.cpp"
#endif
