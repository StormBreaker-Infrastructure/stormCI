# Team StormBreaker Kernel Build Script #
-------------------------------------------

Usage: Download this script, setup all variables and then ```bash build.sh```

-------------------------------------------

### Setting up script for personal usage ###


- Script is easy to setup just open the script and read the lines till the warning.(Only modify rest code if you understand what you are doing)

- The anykernel will be cloned from Team StormBreaker Org with $DEVICE as your default
  branch name. You can override this with var ```STORM_ZIP_BRANCH``` on Line 34

- If you wanna define any variable via environment variables just setup a input var on CI.
  For example, say I wanna define whether to use GCC or Clang as my compiler using environment
  variable, then just set
  ```export STORM_COMPILE_GCC=""``` TO

  ```export STORM_COMPILE_GCC="$ENV_VAR_COMPILER"```
  and then add a yes or no to your ENV_VAR_COMPILER in CI secrets/environment variables
  
- If you want to use this script from ```X``` repo and your kernel repo is in ```Y``` then uncomment & set
  ```CLONE_KERNEL_TARGET_CI``` to "yes" on Line 43 and define rest mentioned variables on L35 and L36
  
  ### Note ###
  - To clone private repos you should be familiar with Github Personal Access Tokens

- If you have multiple defconfigs to compile (multi device supported repos/common kernels) you can just do

  ```./build.sh -d codename -c configname```
  
  here the ```codename``` is branch used for cloning AnyKernel3 by @Osm0sis and ```configname``` is the name
  of your defconfig without _defconfig e.g to compile vince_defconfig use ```-c vince```

- Additional flags present in the script is ```-C``` and ```-l```
  - ```-C``` is used to define clang as compiler (default compiler is GCC) [Can be changed on L13-L18]
  - ```-C 12``` can be used to use latest Proton clang 12 by @Kdrag0n
  - ```-l``` is used if your device needs linkers for compilation [Can be defined from script on L19]

### NOTE ###
- To avoid unneccessary cloning of toolchains (for people with limited internet access) please check your paths properly within the clone 
  functions on L126-L152. By default gcc64 and gcc32 is cloned from @Arter97 and placed in ```toolchains/gcc64``` & ```toolchains/gcc32```
  and for clang it'll clone clang 12 and clang 11 to ```toolchains/clang-12``` and ```toolchains/clang-11``` respectively in your home directory
