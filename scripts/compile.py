#!/usr/bin/env -S uv run --script
#
# /// script
# requires-python = ">=3.12"
# dependencies = ["libclang"]
# ///

import os
import subprocess
import sys
import clang
from clang.cindex import Index, CursorKind

repo_root = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
sys.path.insert(0, repo_root)

from scripts.codegen import get_input_command_and_srcs, CXX, BUILD_DIR

in_cmd, base_cmd, srcs = get_input_command_and_srcs()

# TODO: output compile_commands.json
# TODO: 
# * for each struct, walk fields and generate a function
# * for each enum, create a lookup table

index = Index.create()
tu = index.parse(None, in_cmd)

# TODO
# for d in tu.cursor.walk_preorder():
#     if d.kind.is_declaration():
        # if d.kind == CursorKind.
        # print(d.spelling)

_ = subprocess.run([CXX] + in_cmd)
