#!/bin/bash
zig build
./zig-out/bin/zig-cc "$1" > tmp.s
cc -o tmp tmp.s
./tmp
echo $?