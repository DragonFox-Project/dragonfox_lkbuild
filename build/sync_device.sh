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

function sync () {
    if [ -d "${LKBUILD_TOP}/$2" ]; then
        return 0
    fi;
    git clone $1 ${LKBUILD_TOP}/$2 -b $3 --depth 1

}

function execute_target {
    target_sync_sources
}
