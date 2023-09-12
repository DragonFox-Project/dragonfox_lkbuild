# Little Kernel Build

This is Little Kernel Build system made for building Linux kernels under DragonFox project

> Work in progress

# Building

## Syntax


For initializing build system variables
```
. envsetup.sh
```

The current build system supports 3 commands

To sync prebuilts, along with device sources (if defined by device target), use `breakfast`
```
$ breakfast <target>
````

For initializing device build, use `lunch`
```
$ lunch <target>
```


For building build target itself, use `mka`
```
$ mka <build_target>
```

> Current build targets are:
> kernel (Builds kernel image)

## Supported devices

> Currently supported devices are:
- gta4xl
- gta4xlwifi
- spes
