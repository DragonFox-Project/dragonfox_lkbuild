#!/bin/bash
#
# Copyright (C) 2023 H258 & KrutosX
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

PRODUCT_DEVICE="spes"
PRODUCT_MANUFACTURER="xiaomi"

TARGET_ARCH="arm64"
TARGET_KERNEL_CONFIG="vendor/spes-perf_defconfig"

BOARD_KERNEL_IMAGE_NAME="Image.gz"
TARGET_KERNEL_CLANG_VERSION="r365631c"
TARGET_KERNEL_LLVM_BINUTILS=false

TARGET_KERNEL_SOURCE=kernel/xiaomi/sm6225

function target_sync_sources () {
    # sync URL PATH BRANCH
    # - synces git repo from url to path, using selected branch
    sync "https://github.com/mi-sdm680/android_kernel_xiaomi_sm6225" "kernel/xiaomi/sm6225" "spes-r-oss"
    sync "https://android.googlesource.com/platform/prebuilts/clang/host/linux-x86/" "clang-temp" "android11-gsi"
    mkdir -p prebuilts/clang/host/linux-x86/
    mv clang-temp/clang-r365631c prebuilts/clang/host/linux-x86/
    rm -rf clang-temp
}
