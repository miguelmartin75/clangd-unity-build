import os
import sys

CXX = os.environ.get("CXX")
assert CXX is not None, "CXX not in environ"
print("CXX=", CXX)

BUILD_DIR = os.environ.get("BUILD_DIR")
assert BUILD_DIR is not None, "BUILD_DIR not in environ"
print("BUILD_DIR=", BUILD_DIR)

def get_input_command_and_srcs(args: list[str] = sys.argv) -> tuple[list[str], list[str], list[str]]:
    in_cmd = args[1:]
    base_cmd = []
    srcs = []
    i = 0
    while i < len(in_cmd):
        if in_cmd[i] == "-o":
            i += 2
            continue
        elif in_cmd[i].endswith(".cpp"): # TODO: or .c
            srcs.append(in_cmd[i])
        else:
            base_cmd.append(in_cmd[i])

        i += 1
    return in_cmd, base_cmd, srcs
