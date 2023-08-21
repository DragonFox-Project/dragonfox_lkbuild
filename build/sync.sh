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

DEFAULT_REVISION="android-13.0.0_r61"

function sync () {
    if [ -d "${LKBUILD_TOP}/$2" ]; then
        return 0
    fi;

    if [ -z "$3" ]; then
        git clone $1 ${LKBUILD_TOP}/$2 -b $DEFAULT_REVISION --depth 1
    else
        git clone $1 ${LKBUILD_TOP}/$2 -b $3 --depth 1
    fi;
}

function execute_target () {
    sync "https://android.googlesource.com/platform/prebuilts/gcc/linux-x86/host/x86_64-linux-glibc2.17-4.8" "prebuilts/gcc/linux-x86/host/x86_64-linux-glibc2.17-4.8"
    sync "https://android.googlesource.com/kernel/prebuilts/build-tools" "prebuilts/kernel-build-tools" "android-13.0.0_r0.106"
    sync "https://github.com/LineageOS/android_prebuilts_tools-lineage" "prebuilts/tools-lineage" "lineage-20.0"
    sync "https://github.com/LineageOS/android_prebuilts_build-tools" "prebuilts/build-tools" "lineage-20.0"
    sync "https://android.googlesource.com/platform/prebuilts/clang/host/linux-x86" "prebuilts/clang/host/linux-x86"
}
