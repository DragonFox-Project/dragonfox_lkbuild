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

LKBUILD_VERSION="0.1"
LKBUILD_JOBS=$(nproc --all)
export LKBUILD_TOP=$(pwd)

function lunch () {
    cd $LKBUILD_TOP
    vars_cleanup

    if [ -z "$1" ]; then
        echo "error: no device selected"
        return 255
    fi;

    if [ -f "./target/$1.sh" ]; then
        source "./target/$1.sh"
    else
        echo "error: target does not exist"
        return 255
    fi;

    if [ -z "$TARGET_KERNEL_SOURCE" ]; then
        TARGET_KERNEL_SOURCE="kernel/${PRODUCT_MANUFACTURER}/${PRODUCT_DEVICE}"
    fi;

    # Welcome message
    echo "--- LKBuild v${LKBUILD_VERSION} ---"
    echo "Device: $1"
    echo "Target kernel config: ${TARGET_KERNEL_CONFIG}"
    echo "Target kernel source: ${TARGET_KERNEL_SOURCE}"
    echo "Jobs: ${LKBUILD_JOBS}"
    echo "---"

    export LKBUILD_TARGET=$1
}

function mka () {
    cd $LKBUILD_TOP

    if [ -z "$LKBUILD_TARGET" ]; then
        echo "error: no device selected"
        echo "error: select device using lunch"
        return 255
    fi;

    if [ -f "./target/$LKBUILD_TARGET.sh" ]; then
        source "./target/$LKBUILD_TARGET.sh"
    else
        echo "error: target does not exist"
        echo "error: select proper target using lunch"
        return 255
    fi;

    if [ -z "$1" ]; then
        echo "error: select build target"
        return 255
    fi;

    if [ -z "$TARGET_KERNEL_SOURCE" ]; then
        TARGET_KERNEL_SOURCE="kernel/${PRODUCT_MANUFACTURER}/${PRODUCT_DEVICE}"
    fi;

    # Welcome message
    echo "--- LKBuild v${LKBUILD_VERSION} ---"
    echo "Device: $LKBUILD_TARGET"
    echo "Target kernel config: ${TARGET_KERNEL_CONFIG}"
    echo "Target kernel source: ${TARGET_KERNEL_SOURCE}"
    echo "Jobs: ${LKBUILD_JOBS}"
    echo "---"

    if [ -f "./build/$1.sh" ]; then
        source "./build/$1.sh"
        if ! execute_target; then
            echo "error: build target failed"
            echo --- LKBuild ---
            echo "Build failed!"
            return 255
        fi
    else
        echo "error: unknown build target"
        return 255
    fi;

    echo --- LKBuild ---
    echo Build finished
}

function breakfast () {
    if [ -z "$1" ]; then
        echo "error: no device selected"
        return 255
    fi;

    LKBUILD_TARGET=$1
    mka sync
    mka sync_device
}

function vars_cleanup () {
    unset $(compgen -v | grep -i "TARGET_")
    unset $(compgen -v | grep -i "BOARD_")
    unset $(compgen -v | grep -i "PRODUCT_")
}
