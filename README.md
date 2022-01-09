素朴な自作言語のコンパイラをCrystalに移植した  
https://memo88.hatenablog.com/entry/20210327_vm2gol_v2_crystal

```
Crystal 1.3.0 [a3ee70ca0] (2022-01-06)

LLVM: 10.0.0
Default target: x86_64-unknown-linux-gnu
```

```sh
docker build \
  --build-arg USER=$USER \
  --build-arg GROUP=$(id -gn) \
  -t vm2gol-v2-crystal:3 .
```
