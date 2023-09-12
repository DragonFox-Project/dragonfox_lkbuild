#!/bin/bash
#
# Copyright (C) 2012 The CyanogenMod Project
#           (C) 2017-2022 The LineageOS Project
#           (C) 2023 H258 & KrutosX
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

function execute_target () {
    KERNEL_ARCH=$TARGET_ARCH

    if [ -z "$BOARD_KERNEL_IMAGE_NAME" ]; then
        echo "error: BOARD_KERNEL_IMAGE_NAME not defined."
        return 255
    fi;

    if [ ! -d "$TARGET_KERNEL_SOURCE" ]; then
        echo "error: no kernel source found"
        return 255
    fi;

    KERNEL_VERSION=$(grep --color=never -s "^VERSION = " ${TARGET_KERNEL_SOURCE}/Makefile | cut -d " " -f 3)
    KERNEL_PATCHLEVEL=$(grep --color=never -s "^PATCHLEVEL = " ${TARGET_KERNEL_SOURCE}/Makefile | cut -d " " -f 3)

    if [ -z "$TARGET_KERNEL_NO_GCC" ]; then
        if [ ! -z "$KERNEL_VERSION" ]; then
            if [[ $KERNEL_VERSION -ge 5 ]]; then
                if [[ $KERNEL_PATCHLEVEL -ge 10 ]]; then
                    TARGET_KERNEL_NO_GCC=true
                fi;
            fi;
        fi;
    fi;

    if [ "$TARGET_KERNEL_NO_GCC" == "true" ]; then
        KERNEL_NO_GCC="true"
    fi;

    if [ -z "$TARGET_KERNEL_CLANG_VERSION" ]; then
        KERNEL_CLANG_VERSION=clang-r450784d
    else
        KERNEL_CLANG_VERSION="clang-${TARGET_KERNEL_CLANG_VERSION}"
    fi;

    if [ -z "$TARGET_KERNEL_CLANG_PATH" ]; then
        TARGET_KERNEL_CLANG_PATH=${LKBUILD_TOP}/prebuilts/clang/host/linux-x86/${KERNEL_CLANG_VERSION}
    fi;

    if [ "$KERNEL_NO_GCC" != "true" ]; then
        GCC_PREBUILTS="${LKBUILD_TOP}/prebuilts/gcc/linux-x86"
        # arm64 toolchain
        KERNEL_TOOLCHAIN_arm64="${GCC_PREBUILTS}/aarch64/aarch64-linux-android-4.9/bin"
        KERNEL_TOOLCHAIN_PREFIX_arm64="aarch64-linux-android-"
        # arm toolchain
        KERNEL_TOOLCHAIN_arm="${GCC_PREBUILTS}/arm/arm-linux-androideabi-4.9/bin"
        KERNEL_TOOLCHAIN_PREFIX_arm="arm-linux-androidkernel-"
        # x86 toolchain
        KERNEL_TOOLCHAIN_x86="${GCC_PREBUILTS}/x86/x86_64-linux-android-4.9/bin"
        KERNEL_TOOLCHAIN_PREFIX_x86="x86_64-linux-android-"

        TARGET_KERNEL_CROSS_COMPILE_PREFIX=$(echo -n ${TARGET_KERNEL_CROSS_COMPILE_PREFIX} | sed 's/^ *//;s/ *$//')

        if [ ! -z "$TARGET_KERNEL_CROSS_COMPILE_PREFIX" ]; then
            if [ -z "$KERNEL_TOOLCHAIN_PREFIX" ]; then
                KERNEL_TOOLCHAIN_PREFIX="${TARGET_KERNEL_CROSS_COMPILE_PREFIX}"
            fi;
        else
            if [ -z "$KERNEL_TOOLCHAIN" ]; then
                KERNEL_TOOLCHAIN="KERNEL_TOOLCHAIN_${KERNEL_ARCH}"
                KERNEL_TOOLCHAIN="${!KERNEL_TOOLCHAIN}"
            fi;
            if [ -z "$KERNEL_TOOLCHAIN_PREFIX" ]; then
                KERNEL_TOOLCHAIN_PREFIX="KERNEL_TOOLCHAIN_PREFIX_${KERNEL_ARCH}"
                KERNEL_TOOLCHAIN_PREFIX="${!KERNEL_TOOLCHAIN_PREFIX}"
            fi;
        fi;

        if [ -z "$KERNEL_TOOLCHAIN" ]; then
            KERNEL_TOOLCHAIN_PATH="${KERNEL_TOOLCHAIN_PREFIX}"
        else
            KERNEL_TOOLCHAIN_PATH="${KERNEL_TOOLCHAIN}/${KERNEL_TOOLCHAIN_PREFIX}"
        fi;

        # We need to add GCC toolchain to the path no matter what
        # for tools like `as`
        KERNEL_TOOLCHAIN_PATH_gcc="KERNEL_TOOLCHAIN_${KERNEL_ARCH}"
        KERNEL_TOOLCHAIN_PATH_gcc="${!KERNEL_TOOLCHAIN_PATH_gcc}"

        KERNEL_CROSS_COMPILE="CROSS_COMPILE=\"${KERNEL_TOOLCHAIN_PATH}\""

        # Needed for CONFIG_COMPAT_VDSO, safe to set for all arm64 builds
        if [ "$KERNEL_ARCH" == "arm64" ]; then
            KERNEL_CROSS_COMPILE+=" CROSS_COMPILE_ARM32=\"${KERNEL_TOOLCHAIN_arm}/${KERNEL_TOOLCHAIN_PREFIX_arm}\""
            KERNEL_CROSS_COMPILE+=" CROSS_COMPILE_COMPAT=\"${KERNEL_TOOLCHAIN_arm}/${KERNEL_TOOLCHAIN_PREFIX_arm}\""
        fi;

        KERNEL_MAKE_FLAGS=""

        if [ "${TARGET_KERNEL_CLANG_COMPILE}" == "false" ]; then
            if [ "$KERNEL_ARCH" == "arm" ]; then
                # Avoid "Unknown symbol _GLOBAL_OFFSET_TABLE_" errors
                KERNEL_MAKE_FLAGS+="CFLAGS_MODULE=\"-fno-pic\""
            fi;

            if [ "$KERNEL_ARCH" == "arm64" ]; then
                # Avoid "unsupported RELA relocation: 311" errors (R_AARCH64_ADR_GOT_PAGE)
                KERNEL_MAKE_FLAGS+="CFLAGS_MODULE=\"-fno-pic\""
            fi;
        fi;

        KERNEL_MAKE_FLAGS+=" CPATH=\"/usr/include:/usr/include/x86_64-linux-gnu\" HOSTLDFLAGS=\"-L/usr/lib/x86_64-linux-gnu -L/usr/lib64 -fuse-ld=lld\""

        OLDPATH=$PATH
        if [ "$KERNEL_ARCH" == "arm64" ]; then
            # Add 32-bit GCC to PATH so that arm-linux-androidkernel-as is available for CONFIG_COMPAT_VDSO
            export PATH="${LKBUILD_TOP}/prebuilts/tools-lineage/linux-x86/bin:${KERNEL_TOOLCHAIN_arm}:$PATH"
        else
            export PATH="${LKBUILD_TOP}/prebuilts/tools-lineage/linux-x86/bin:$PATH"
        fi;

        # Set the full path to the clang command and LLVM binutils
        KERNEL_MAKE_FLAGS+=" HOSTCC=${TARGET_KERNEL_CLANG_PATH}/bin/clang"
        KERNEL_MAKE_FLAGS+=" HOSTCXX=${TARGET_KERNEL_CLANG_PATH}/bin/clang++"

        if [ "${TARGET_KERNEL_CLANG_COMPILE}" != "false" ]; then
            if [ "${TARGET_KERNEL_LLVM_BINUTILS}" != "false" ]; then
                KERNEL_MAKE_FLAGS+=" LD=${TARGET_KERNEL_CLANG_PATH}/bin/ld.lld"
                KERNEL_MAKE_FLAGS+=" AR=${TARGET_KERNEL_CLANG_PATH}/bin/llvm-ar"
            fi;
        fi;
    else
        KERNEL_MAKE_FLAGS="HOSTCFLAGS=\"--sysroot=${LKBUILD_TOP}/prebuilts/gcc/linux-x86/host/x86_64-linux-glibc2.17-4.8/sysroot -I${LKBUILD_TOP}/prebuilts/kernel-build-tools/linux-x86/include\" HOSTLDFLAGS=\"--sysroot=${LKBUILD_TOP}/prebuilts/gcc/linux-x86/host/x86_64-linux-glibc2.17-4.8/sysroot -Wl,-rpath,${LKBUILD_TOP}/prebuilts/kernel-build-tools/linux-x86/lib64 -L ${LKBUILD_TOP}/prebuilts/kernel-build-tools/linux-x86/lib64 -fuse-ld=lld --rtlib=compiler-rt\""

        OLDPATH=$PATH
        export PATH="${LKBUILD_TOP}/prebuilts/tools-lineage/linux-x86/bin:${TARGET_KERNEL_CLANG_PATH}/bin:$PATH"
    fi;

    KERNEL_MAKE_FLAGS+=" LEX=${LKBUILD_TOP}/prebuilts/build-tools/linux-x86/bin/flex"
    KERNEL_MAKE_FLAGS+=" YACC=${LKBUILD_TOP}/prebuilts/build-tools/linux-x86/bin/bison"
    KERNEL_MAKE_FLAGS+=" M4=${LKBUILD_TOP}/prebuilts/build-tools/linux-x86/bin/m4"

    KERNEL_OUT="${LKBUILD_TOP}/out/${PRODUCT_DEVICE}/kernel_obj"
    TARGET_PREBUILT_INT_KERNEL=${KERNEL_OUT}/arch/${KERNEL_ARCH}/boot/${BOARD_KERNEL_IMAGE_NAME}
    KERNEL_MAKE_CMD=${LKBUILD_TOP}/prebuilts/build-tools/linux-x86/bin/make
    KERNEL_SRC=${TARGET_KERNEL_SOURCE}
    KERNEL_DEFCONFIG=${TARGET_KERNEL_CONFIG}
    KERNEL_DEFCONFIG_ARCH=${KERNEL_ARCH}

    # Use LLVM's substitutes for GNU binutils
    if [ "$TARGET_KERNEL_CLANG_COMPILE" != "false" ]; then
        if [ "$TARGET_KERNEL_LLVM_BINUTILS" != "false" ]; then
            KERNEL_MAKE_FLAGS+=" LLVM=1 LLVM_IAS=1"
        fi;
    fi;

    KERNEL_MAKE_FLAGS+=" ${TARGET_KERNEL_ADDITIONAL_FLAGS}"

    export OLD_LD_LIBRARY_PATH=$LD_LIBRARY_PATH

    if [ "$TARGET_KERNEL_CLANG_COMPILE" != "false" ]; then
        if [ "$KERNEL_NO_GCC" != "true" ]; then
            if [ "$KERNEL_ARCH" == "arm64" ]; then
                if [ -z "$KERNEL_CLANG_TRIPLE" ]; then
                    KERNEL_CLANG_TRIPLE="CLANG_TRIPLE=aarch64-linux-gnu-"
                fi;
            elif [ "$KERNEL_ARCH" == "arm" ]; then
                if [ -z "$KERNEL_CLANG_TRIPLE" ]; then
                    KERNEL_CLANG_TRIPLE="CLANG_TRIPLE=arm-linux-gnu-"
                fi;
            elif [ "$KERNEL_ARCH" == "x86" ]; then
                if [ -z "$KERNEL_CLANG_TRIPLE" ]; then
                    KERNEL_CLANG_TRIPLE="CLANG_TRIPLE=x86_64-linux-gnu-"
                fi;
            fi;
            export LD_LIBRARY_PATH="${TARGET_KERNEL_CLANG_PATH}/lib64:$LD_LIBRARY_PATH"
        fi;
        PATH="${TARGET_KERNEL_CLANG_PATH}/bin:$PATH"
        if [ -z "$KERNEL_CC" ]; then
            CLANG_EXTRA_FLAGS="--cuda-path=/dev/null"
            ${TARGET_KERNEL_CLANG_PATH}/bin/clang -v --hip-path=/dev/null >/dev/null 2>&1;
            if [ $? -eq 0 ]; then
                CLANG_EXTRA_FLAGS+=" --hip-path=/dev/null"
            fi;
            KERNEL_CC="CC=\"clang ${CLANG_EXTRA_FLAGS}\""
        fi;
    fi;

    if [ "$KERNEL_NO_GCC" != "true" ]; then
        PATH="${KERNEL_TOOLCHAIN_PATH_gcc}:$PATH"
    fi;

    # $1 - Kernel out
    # $2 - Target to build (e.g. defconfig)
    function internal-make-kernel-target () {
        bash -c "${KERNEL_MAKE_CMD} ${KERNEL_MAKE_FLAGS} -C ${KERNEL_SRC} O=$1 ARCH=${KERNEL_ARCH} ${KERNEL_CROSS_COMPILE} ${KERNEL_CLANG_TRIPLE} ${KERNEL_CC} $2 -j${LKBUILD_JOBS}"
    }

    # $1 - Target to build (e.g. defconfig)
    function make-kernel-target () {
        internal-make-kernel-target $KERNEL_OUT $1
    }

    mkdir -p $KERNEL_OUT

    echo "Building Kernel Config"
    make-kernel-target $KERNEL_DEFCONFIG

    if [ $? -ne 0 ]; then
        echo "error: subcommand failed"
        export PATH=$OLDPATH
        export LD_LIBRARY_PATH=$OLD_LD_LIBRARY_PATH
        return 255
    fi

    echo "Building Kernel Image (${BOARD_KERNEL_IMAGE_NAME})"
    make-kernel-target $BOARD_KERNEL_IMAGE_NAME

    if [ $? -ne 0 ]; then
        echo "error: subcommand failed"
        export PATH=$OLDPATH
        export LD_LIBRARY_PATH=$OLD_LD_LIBRARY_PATH
        return 255
    fi

    echo "Target Kernel Image: ${TARGET_PREBUILT_INT_KERNEL}"
    export PATH=$OLDPATH
    export LD_LIBRARY_PATH=$OLD_LD_LIBRARY_PATH
}
