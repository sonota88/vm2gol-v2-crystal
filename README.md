素朴な自作言語のコンパイラをCrystalに移植した  
https://memo88.hatenablog.com/entry/20210327_vm2gol_v2_crystal

```sh
./docker_build.sh

./docker.sh run crystal version
  # Crystal 1.7.3 [d61a01e18] (2023-03-07)
  # 
  # LLVM: 13.0.1
  # Default target: x86_64-unknown-linux-gnu

./test.sh all
```
