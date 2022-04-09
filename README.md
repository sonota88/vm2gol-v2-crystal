素朴な自作言語のコンパイラをCrystalに移植した  
https://memo88.hatenablog.com/entry/20210327_vm2gol_v2_crystal

```sh
./docker_build.sh

./docker_run.sh crystal version
#=> Crystal 1.4.0 [ef05e26d6] (2022-04-06)
#=> 
#=> LLVM: 10.0.0
#=> Default target: x86_64-unknown-linux-gnu

./test.sh all
```
