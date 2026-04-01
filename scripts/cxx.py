import subprocess
import os
import sys
from dataclasses import dataclass

@dataclass
class ParsedCxxArgs:
    args: list[str]
    base_cmd: list[str]  # no -o and no srcs
    srcs: list[str]
    output_file: str
    search_paths: list[str]


@dataclass
class UnitySrcDeps:
    compile_src: str
    src_deps: list[str]
    local_srcs: list[str]


VALID_EXTS = {".cpp", ".c", ".mm", ".m", ".cc"}

CXX = os.environ.get("CXX")
assert CXX is not None, "CXX not in environ"

BUILD_DIR = os.environ.get("BUILD_DIR")
assert BUILD_DIR is not None, "BUILD_DIR not in environ"

SRC_DIR = os.environ.get("SRC_DIR")
assert SRC_DIR is not None, "SRC_DIR not in environ"

COMPILE_COMMANDS = int(os.environ.get("COMPILE_COMMANDS", "0")) != 0
CODEGEN = int(os.environ.get("CODEGEN", "0")) != 0

def get_sys_paths():
    sys_path_cmd = f"{CXX} -E -v - < /dev/null 2>&1 | sed -n '/#include </,/End of search list./p'"
    sys_paths = [x.strip().split(" ")[0] for x in subprocess.run(sys_path_cmd, capture_output=True, shell=True).stdout.decode("utf-8").split("\n") if x][1:-1]
    return sys_paths

def expand_path(path: str, search_paths: list[str], sys_paths: list[str], curr_dir: str = ".") -> tuple[str, str, bool] | None:
    dirs_to_check = []
    if path.startswith('"'):
        dirs_to_check = [curr_dir] + search_paths
        path = path[1:-1]
    elif path.startswith('<'):
        dirs_to_check = sys_paths + search_paths
        path = path[1:-1]
    else:
        if os.path.exists(path):
            dir = os.path.dirname(path)
            return (path, dir, dir in sys_paths)
        return None

    for dir in dirs_to_check:
        p = os.path.join(dir, path)
        if os.path.exists(p):
            return (p, dir, dir in sys_paths)
    return None


def parse_cxx_args(argv: list[str] = sys.argv) -> ParsedCxxArgs:
    result = ParsedCxxArgs(
        args=[],
        base_cmd=[],
        srcs=[],
        output_file=None,
        search_paths=[],
    )
    result.args = argv[1:]
    i = 1
    while i < len(argv):
        if argv[i] == "-o":
            assert result.output_file is None, f"-o provided twice, check: {argv}"
            result.output_file = argv[i + 1]

            i += 2
        elif argv[i].startswith("-I"):
            if len(argv[i]) == 2:  # next arg
                result.search_paths.append(argv[i + 1])
                i += 2
            else:
                result.search_paths.append(argv[i][2:])
                i += 1
        elif any(argv[i].endswith(ext) for ext in VALID_EXTS):
            result.srcs.append(argv[i])
            i += 1
        else:
            result.base_cmd.append(argv[i])
            i += 1

    return result

def compile_cmd(src: str, args: ParsedCxxArgs, repo_root: str, srcs: list[str], compile_src: str) -> dict[str, str]:
    dummy_out_file = src.replace(SRC_DIR, BUILD_DIR) + ".o"
    tu_macro = f"-DCLANGD_TU_{src.replace("/", "_").replace(".", "_")}"
    command = CXX + " " + " ".join(args.base_cmd) 
    command += f" {tu_macro} -c {src} -include {compile_src} -o {dummy_out_file}"
    return {
        "directory": repo_root,
        "command": command,
        "file": src,
        "output": dummy_out_file,
    }

def get_compile_commands(args: ParsedCxxArgs, repo_root: str, srcs: list[str], compile_src: str):
    return [compile_cmd(x, args, repo_root, srcs, compile_src) for x in srcs]

def get_unity_src_deps(args: ParsedCxxArgs, sys_paths: list[str]) -> tuple[str, list[str]]:
    assert len(args.srcs) == 1 and "compile" in args.srcs[0], f"expected 1 unity src file, got: {args.srcs}"

    result = UnitySrcDeps(
        compile_src=None,
        src_deps=None,
        local_srcs=None,
    )
    result.compile_src = args.srcs[0]
    includes = [
        (i, x[len("#include"):].split("//")[0].split("/*")[0].strip())
        for i, x in enumerate(open(result.compile_src).readlines())
        if x.startswith("#include")
    ]
    result.src_deps = [expand_path(x, search_paths=args.search_paths, sys_paths=sys_paths) for _, x in includes]
    no_path = [incl for incl, x in zip(includes, result.src_deps) if x is None]
    if len(no_path) != 0:
        print("[WARN]: no path found for the following includes:")
        for lineno, incl in no_path:
            print(f"{result.compile_src}:{lineno}: {incl}")

    result.local_srcs = [x[0] for x in result.src_deps if x is not None and not x[-1] and SRC_DIR in x[1]]
    return result
