#!/bin/bash
#
# Copyright 2016 leenjewel
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# Modified by Trevor Dasch and Michael Wilson to add build openssl for mac
#

set -u

source ./build-common.sh

export PLATFORM_TYPE="MacOS"

init_log_color

TOOLS_ROOT=$(realpath $0)

echo TOOLS_ROOT=${TOOLS_ROOT}

OPENSSL_SRC_DIR="${TOOLS_ROOT}/../src"

function configure_make() {

    log_info "configure mac start..."

    pushd .
    cd "${OPENSSL_SRC_DIR}"

    PREFIX_DIR="${TOOLS_ROOT}/../out/MacOS/"
    if [ -d "${PREFIX_DIR}" ]; then
        rm -fr "${PREFIX_DIR}"
    fi
    mkdir -p "${PREFIX_DIR}"

    OUTPUT_ROOT=${TOOLS_ROOT}/../out/MacOS/
    mkdir -p ${OUTPUT_ROOT}/log

    ./Configure darwin64-arm64-cc --prefix="${PREFIX_DIR}"

    log_info "make mac start..."

    make clean >"${OUTPUT_ROOT}/log/macos.log"
    make -j $(get_cpu_count) SHLIB_EXT='.dylib' all >>"${OUTPUT_ROOT}/log/macos.log" 2>&1
    the_rc=$?
    if [ $the_rc -eq 0 ] ; then
        make -j $(get_cpu_count) SHLIB_EXT='.dylib' install_sw >>"${OUTPUT_ROOT}/log/macos.log" 2>&1
        make -j $(get_cpu_count) install_ssldirs >>"${OUTPUT_ROOT}/log/macos.log" 2>&1
    fi

    popd
}

log_info "${PLATFORM_TYPE} openssl start..."

configure_make

log_info "${PLATFORM_TYPE} openssl end..."
