# zig-cc

[低レイヤを知りたい人のための C コンパイラ作成入門](https://www.sigbus.info/compilerbook) を zig で実装する リポジトリ

## 文法

```
program = stmt*
stmt = expr ";"
     | "if" "(" expr ")" stmt ("else" stmt)?
     | "while" "(" expr ")" stmt
     | "for" "(" expr? ";" expr? ";" expr? ")" stmt
     | "{" stmt* "}"
expr = assign
assign = equality ("=" assign)?
equality = relational ("==" relational | "!=" relational)
relational = add ("<" add | "<=" add | ">" add | ">=" add)
add = mul ("+" mul | "-" mul)
mul = unary ("_" unary | "/" unary)
unary = ("+" | "-")? primary
primary = num | ident | "(" expr ")" | funcall
funcall = ident "(" (assign, ("," assign)_)? ")"
```

## 参考 web サイト

### zig の勉強

- [https://ziglearn.org/](https://ziglearn.org/)

### zig のリポジトリ

- [https://github.com/ziglang/zig](https://github.com/ziglang/zig)
- コンパイラそのものなので、参考になる気がする。

### zig 公式リファレンス

- [https://ziglang.org/documentation/master/](https://ziglang.org/documentation/master/)

### c compiler emulator

- [https://godbolt.org/](https://godbolt.org/)

## メモ

### zig で作成したオブジェクトファイルを c から呼び出す

```sh
$ zig build-obj src/foo.zig -fcompiler-rt
$ clang  -Wall -Wextra -std=c11 -pedantic -O3 -o main foo.o main.c
```
