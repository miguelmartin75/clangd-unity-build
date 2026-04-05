#!/usr/bin/env -S uv run --script

import json
import os
import subprocess
import sys
import clang
from pathlib import Path
from clang.cindex import Index, CursorKind #, PrintingPolicy

repo_root = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
sys.path.insert(0, repo_root)

from scripts.cxx import (
    CXX,
    BUILD_DIR,
    SRC_DIR,
    COMPILE_COMMANDS,
    LAZY,
    CODEGEN,
    ParsedCxxArgs,
    parse_cxx_args,
    get_sys_paths,
    expand_path,
    get_compile_commands,
    get_unity_src_deps,
)

sys_paths = get_sys_paths()
args = parse_cxx_args()
srcs = get_unity_src_deps(args=args, sys_paths=sys_paths)

if COMPILE_COMMANDS:
    compile_commands = get_compile_commands(args=args, repo_root=repo_root, srcs=srcs.local_srcs, compile_src=srcs.compile_src)
    existing = json.load(open("compile_commands.json")) if os.path.exists("compile_commands.json") else {}
    cc_by_file = {x["file"]: x for x in compile_commands}
    cc_by_file.update({x["file"]: x for x in existing})
    compile_commands = list(cc_by_file.values())
    with open("compile_commands.json", "w") as out_f:
        json.dump(compile_commands, out_f, indent=2)

if LAZY and not CODEGEN:
    print("[ERROR] need LAZY=1 (--lazy) and CODEGEN=1 (-g|--gen)", file=sys.stderr, flush=True)
    sys.exit(1)

if CODEGEN and not srcs.compile_src.startswith("tests/"):
    parse_args = args.args

    index = Index.create()
    tu = index.parse(None, parse_args)

    ck_type_spelling = {
        CursorKind.STRUCT_DECL: "struct",
        CursorKind.UNION_DECL: "union",
        CursorKind.CLASS_DECL: "class",
    }

    gen_dir = os.path.join(SRC_DIR, "gen")
    all_source_files = set()
    seen = set()
    proto_fns = []
    proto_types = []
    enum_infos = []
    for c in tu.cursor.walk_preorder():
        # skip generated files
        if c.location.file is not None and (c.location.file.name.startswith(gen_dir)):
            continue

        if c.location.file is not None and not c.location.file.name.startswith(SRC_DIR) and not "catch2" in c.location.file.name.lower():
            continue

        if c.location.file is not None:
            all_source_files.add(c.location.file.name)

        if c.kind.is_declaration():
            if c.spelling in seen:
                continue
            if c.is_anonymous():
                continue

            seen.add(c.spelling)
            if c.kind == CursorKind.FUNCTION_DECL:
                spelling = ""
                spelling += c.result_type.spelling
                fn_args = ", ".join(
                    f"{a.type.spelling}{f' {a.spelling}' if a.spelling else ''}"
                    for a in (c.get_arguments() or [])
                )
                proto = f"{c.result_type.spelling} {c.spelling}({fn_args});"
                proto_fns.append(proto)
            elif c.kind in ck_type_spelling:
                proto = f"{ck_type_spelling[c.kind]} {c.spelling};"
                proto_types.append(proto)
            elif c.kind == CursorKind.ENUM_DECL:
                info = {
                    "name": c.spelling,
                    "underlying": c.enum_type.spelling,
                    "scoped": c.is_scoped_enum(),
                    "values": [
                        {
                            "name": e.spelling,
                            "value": e.enum_value,
                            "comment": e.raw_comment,
                        }
                        for e in c.get_children()
                        if e.kind == CursorKind.ENUM_CONSTANT_DECL
                    ],
                }
                enum_infos.append(info)

            # useful props:
            # c.raw_comment

    # TODO: target?
    os.makedirs(os.path.join(SRC_DIR, "gen"), exist_ok=True)
    with open(os.path.join(SRC_DIR, "gen/fwd.h"), "w") as out_f:
        out_f.write("/** WARNING: this is generated code **/\n\n")
        out_f.write("/* types */\n")
        out_f.write("\n".join(proto_types))
        out_f.write("\n\n")
        out_f.write("/* functions */\n")
        out_f.write("\n".join(proto_fns))

    # TODO: target?
    with open(os.path.join(SRC_DIR, "gen/rtti.cpp"), "w") as out_f:
        out_f.write("/** WARNING: this is generated code **/\n\n")
        for enum in enum_infos:
            enum_name = enum["name"]
            enum_values = enum["values"]
            out_f.write(f"static const Rtti_Enum_Value {enum_name}_values[] = {{\n")
            for value in enum_values:
                out_f.write("    Rtti_Enum_Value{\n")
                out_f.write(f"""        .name = S8_LIT("{value["name"]}"),\n""")
                out_f.write(f"""        .value = {value["value"]}\n""")
                out_f.write("    },\n")
            out_f.write("};\n\n")

        if enum_infos:
            out_f.write("static const Rtti_Enum_Type rtti_enum_table_data[] = {\n")
            for enum in enum_infos:
                enum_name = enum["name"]
                out_f.write("    Rtti_Enum_Type{\n")
                out_f.write(f"""        .name = S8_LIT("{enum_name}"),\n""")
                out_f.write("        .values = Rtti_Enum_Value_Array{\n")
                out_f.write(f"            .data = {enum_name}_values,\n")
                out_f.write(f"            .len = sizeof({enum_name}_values) / sizeof(*{enum_name}_values)\n")
                out_f.write("        }\n")
                out_f.write("    },\n")
            out_f.write("};\n\n")
            out_f.write("static const Rtti_Enum_Type_Array rtti_enum_table = {\n")
            out_f.write("    .data = rtti_enum_table_data,\n")
            out_f.write("    .len = sizeof(rtti_enum_table_data) / sizeof(*rtti_enum_table_data)\n")
            out_f.write("};\n")
        else:
            out_f.write("static const Rtti_Enum_Type_Array rtti_enum_table = {\n")
            out_f.write("    .data = nullptr,\n")
            out_f.write("    .len = 0\n")
            out_f.write("};\n")

perform_compile = not LAZY
if LAZY:
    out_path = args.output_file
    if not os.path.exists(out_path):
        perform_compile = True
    else:
        out_mtime = os.path.getmtime(out_path)
        source_files_mtime = [os.path.getmtime(x) for x in all_source_files]
        if any(out_mtime < src_mtime for src_mtime in source_files_mtime):
            perform_compile = True
        else:
            print(f"{out_path} is up to date")

if perform_compile:
    result = subprocess.run([CXX] + args.args)  # compile
    sys.exit(result.returncode)
