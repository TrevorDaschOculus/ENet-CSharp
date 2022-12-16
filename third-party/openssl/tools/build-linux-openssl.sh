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
# Modified by Trevor Dasch to add build openssl for linux
#

set -u

source ./build-common.sh

export PLATFORM_TYPE="Linux"

init_log_color

TOOLS_ROOT=$(realpath $0)

echo TOOLS_ROOT=${TOOLS_ROOT}

OPENSSL_SRC_DIR="${TOOLS_ROOT}/../src"

function configure_make() {

    log_info "configure linux start..."

    pushd .
    cd "${OPENSSL_SRC_DIR}"

    PREFIX_DIR="${TOOLS_ROOT}/../out/Linux/"
    if [ -d "${PREFIX_DIR}" ]; then
        rm -fr "${PREFIX_DIR}"
    fi
    mkdir -p "${PREFIX_DIR}"

    OUTPUT_ROOT=${TOOLS_ROOT}/../out/Linux/
    mkdir -p ${OUTPUT_ROOT}/log

    ./Configure linux-x86_64-clang --prefix="${PREFIX_DIR}"

    log_info "make linux start..."

    make clean >"${OUTPUT_ROOT}/log/linux.log"
    make SHLIB_EXT='.so' all >>"${OUTPUT_ROOT}/log/linux.log" 2>&1
    the_rc=$?
    if [ $the_rc -eq 0 ] ; then
        make SHLIB_EXT='.so' install_sw >>"${OUTPUT_ROOT}/log/linux.log" 2>&1
        make install_ssldirs >>"${OUTPUT_ROOT}/log/linux.log" 2>&1
    fi

    popd
}

log_info "${PLATFORM_TYPE} openssl start..."

configure_make

log_info "${PLATFORM_TYPE} openssl end..."
