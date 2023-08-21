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

    if [ -z "$TARGET_KERNEL_CLANG_VERSION" ]; then
        KERNEL_CLANG_VERSION=clang-r450784d
    else
        KERNEL_CLANG_VERSION="clang-${TARGET_KERNEL_CLANG_VERSION}"
    fi;

    if [ -z "$TARGET_KERNEL_CLANG_PATH" ]; then
        TARGET_KERNEL_CLANG_PATH=${LKBUILD_TOP}/prebuilts/clang/host/linux-x86/${KERNEL_CLANG_VERSION}
    fi;

    KERNEL_MAKE_FLAGS="HOSTCFLAGS=\"--sysroot=${LKBUILD_TOP}/prebuilts/gcc/linux-x86/host/x86_64-linux-glibc2.17-4.8/sysroot -I${LKBUILD_TOP}/prebuilts/kernel-build-tools/linux-x86/include\" HOSTLDFLAGS=\"--sysroot=${LKBUILD_TOP}/prebuilts/gcc/linux-x86/host/x86_64-linux-glibc2.17-4.8/sysroot -Wl,-rpath,${LKBUILD_TOP}/prebuilts/kernel-build-tools/linux-x86/lib64 -L ${LKBUILD_TOP}/prebuilts/kernel-build-tools/linux-x86/lib64 -fuse-ld=lld --rtlib=compiler-rt\""

    OLDPATH=$PATH
    export PATH="${LKBUILD_TOP}/prebuilts/tools-lineage/linux-x86/bin:${TARGET_KERNEL_CLANG_PATH}/bin:$PATH"

    KERNEL_MAKE_FLAGS+=" LEX=${LKBUILD_TOP}/prebuilts/build-tools/linux-x86/bin/flex"
    KERNEL_MAKE_FLAGS+=" YACC=${LKBUILD_TOP}/prebuilts/build-tools/linux-x86/bin/bison"
    KERNEL_MAKE_FLAGS+=" M4=${LKBUILD_TOP}/prebuilts/build-tools/linux-x86/bin/m4"

    KERNEL_OUT="${LKBUILD_TOP}/out/${PRODUCT_DEVICE}/kernel_obj"
    TARGET_PREBUILT_INT_KERNEL=${KERNEL_OUT}/arch/${KERNEL_ARCH}/boot/${BOARD_KERNEL_IMAGE_NAME}
    KERNEL_MAKE_CMD=${LKBUILD_TOP}/prebuilts/build-tools/linux-x86/bin/make
    KERNEL_SRC=${TARGET_KERNEL_SOURCE}
    KERNEL_DEFCONFIG=${TARGET_KERNEL_CONFIG}
    KERNEL_DEFCONFIG_ARCH=${KERNEL_ARCH}
    KERNEL_MAKE_FLAGS+=" LLVM=1 LLVM_IAS=1"
    KERNEL_MAKE_FLAGS+=" ${TARGET_KERNEL_ADDITIONAL_FLAGS}"

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
        return 255
    fi

    echo "Building Kernel Image (${BOARD_KERNEL_IMAGE_NAME})"
    make-kernel-target $BOARD_KERNEL_IMAGE_NAME

    if [ $? -ne 0 ]; then
        echo "error: subcommand failed"
        return 255
    fi

    echo "Target Kernel Image: ${TARGET_PREBUILT_INT_KERNEL}"
    export PATH=$OLDPATH
}
