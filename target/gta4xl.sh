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

PRODUCT_DEVICE="gta4xl"
PRODUCT_MANUFACTURER="samsung"

TARGET_ARCH="arm64"
TARGET_KERNEL_CONFIG="exynos9611-gta4xl_defconfig"

BOARD_KERNEL_IMAGE_NAME="Image"
TARGET_KERNEL_CLANG_VERSION="r450784d"
TARGET_KERNEL_NO_GCC=true

function target_sync_sources () {
    sync "https://github.com/Harder258/dragonfox_kernel_samsung_gta4xl" "kernel/samsung/gta4xl" "lineage-20"
}
