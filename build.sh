#!/bin/bash

mkdir -p build

mkdir -p src/meta
cat src/*.cpp | sed -n 's/^fn \(.*\){/\1;/p' > src/meta/fns.h
cat src/*.cpp | sed -n 's/^struct \(.*\){/struct \1;/p' > src/meta/types.h

sed "s|\"directory\": \"\$PWD\"|\"directory\": \"${PWD}\"|g" compile_commands_template.json > compile_commands.json
clang++ -Isrc src/compile.cpp -o build/main
