素朴な自作言語のコンパイラをCrystalに移植した  
https://memo88.hatenablog.com/entry/20210327_vm2gol_v2_crystal

```
Crystal 1.0.0 [dd40a2442] (2021-03-22)

LLVM: 10.0.0
Default target: x86_64-unknown-linux-gnu
```

```sh
docker build \
  --build-arg USER=$USER \
  --build-arg GROUP=$(id -gn) \
  -t vm2gol-v2:crystal .
```
