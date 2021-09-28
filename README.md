# Introduction
This is my kernel develop tools set.


## How start a vm:
```
 1. 一键部署kernel开发环境
        1.1 git clone linux qemu buildroot
        1.2 分别configure , make -j 20

 2. 提供2个方法快速启动vm:
       方法1：（函数名01结尾） 推荐这个方法！简单！gavin的方式！
               # qemu + buildroot + kernel
       方法2： （函数名02结尾）
               # qemu + kernel

```

## 目录结构:
```
root path:/data/sandbox
tree
   open_linux/
       buildroot/
       linux/
       qemu/
   sPkernel/
```


