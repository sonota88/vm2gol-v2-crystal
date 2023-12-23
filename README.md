This is a port of the compiler part of [Mini Ruccola (Ruby version)](https://github.com/sonota88/vm2gol-v2).

素朴な自作言語のコンパイラをCrystalに移植した  
https://memo88.hatenablog.com/entry/20210327_vm2gol_v2_crystal

```
  $ ./docker.sh build

  $ ./docker.sh run crystal version
Crystal 1.10.1 [c6f3552f5] (2023-10-13)

LLVM: 15.0.7
Default target: x86_64-unknown-linux-gnu

  $ ./test.sh all
```
