#!/bin/bash

cat <<EOF | cc -xc -c -o tmp2.o -
int ret3() { return 3; }
int ret5() { return 5; }
int add(int x, int y) { return x+y; }
int sub(int x, int y) { return x-y; }
int add6(int a, int b, int c, int d, int e, int f) {
  return a+b+c+d+e+f;
}
EOF

assert() {
    expected="$1"
    input="$2"

    ./zig-out/bin/zig-cc "$input" > tmp.s
    cc -o tmp tmp.s tmp2.o
    ./tmp
    actual="$?"

    if [ "$actual" = "$expected" ]; then
        echo "$input => $actual"
    else
        echo "$input => $expected expected, but got $actual"
        exit 1
    fi
}

assert 0 '0;'
assert 42 '42;'
assert 21 '5+20-4;'
assert 41 ' 12 + 34 - 5 ;'
assert 47 '5+6*7;'
assert 15 '5*(9-6);'
assert 4 '(3+5)/2;'
assert 10 '-10+20;'
# assert 10 '- -10;'
# assert 10 '- - +10;'

assert 0 '0==1;'
assert 1 '42==42;'
assert 1 '0!=1;'
assert 0 '42!=42;'

assert 1 '0<1;'
assert 0 '1<1;'
assert 0 '2<1;'
assert 1 '0<=1;'
assert 1 '1<=1;'
assert 0 '2<=1;'

assert 1 '1>0;'
assert 0 '1>1;'
assert 0 '1>2;'
assert 1 '1>=0;'
assert 1 '1>=1;'
assert 0 '1>=2;'

assert 1 '1==1;'
assert 1 'a=1;a;'
assert 2 'a=1;a+a;'
assert 123 'abc=123;abc;'
assert 246 'abc=123;abc + abc;'

assert 14 'a = 3;b = 5 * 6 - 8;return a + b / 2;'
assert 3 'a = 3;b = 5 * 6 - 8;return a;'

assert 3 'if(1) 2;if(1) 2;if(1) 2;if(1) 2;if(1) 3;'
assert 1 'if(1) 1;else 0;'
assert 0 'if(0) 1;else 0;'

assert 10 'i = 0; while(i < 10) i = i + 1; return i;'
assert 100 'for(i=0;i < 100;i = i + 1) i ; return i;'

assert 100 '{for(i=0;i < 100;i = i + 1) i ; return i;}'
assert 1 '{for(i=0;i < 100;i = i + 1) i ; i;}{1;}'
assert 100 '{for(i=0;i < 100;i = i + 1) i ; return i;}{1;}'

assert 3 '{ return ret3(); }'
assert 5 '{ return ret5(); }'
assert 8 '{ return add(3, 5); }'
assert 2 '{ return sub(5, 3); }'
assert 21 '{ return add6(1,2,3,4,5,6); }'
assert 66 '{ return add6(1,2,add6(3,4,5,6,7,8),9,10,11); }'
assert 136 '{ return add6(1,2,add6(3,add6(4,5,6,7,8,9),10,11,12,13),14,15,16); }'
echo OK