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
# Modified by Trevor Dasch to add build openssl for Windows
#

set -u

source ./build-common.sh

export PLATFORM_TYPE="Windows"

init_log_color

if [[ -z "${VCVARSALL_PATH}" ]]; then
  echo "VCVARSALL_PATH not defined"
  exit 1
fi

TOOLS_ROOT=$(realpath $0)
TOOLS_ROOT_WIN=$(wslpath -w ${TOOLS_ROOT})

echo TOOLS_ROOT=${TOOLS_ROOT}

OPENSSL_SRC_DIR="${TOOLS_ROOT}/../src"

function configure_make() {

    log_info "configure windows start..."

    pushd .
    cd "${OPENSSL_SRC_DIR}"

    PREFIX_DIR="${TOOLS_ROOT_WIN}\\..\\out\\Windows\\"
    OUTPUT_ROOT=${TOOLS_ROOT}/../out/Windows/

    if [ -d "${OUTPUT_ROOT}" ]; then
        rm -fr "${OUTPUT_ROOT}"
    fi
    mkdir -p "${OUTPUT_ROOT}"

    mkdir -p ${OUTPUT_ROOT}/log

    cmd.exe /c "$VCVARSALL_PATH" x64

    # check if jom exists
    local has_jom=$(cmd.exe /c "jom -version >NUL 2>&1 && echo 1 || echo 0" | tr -d '\r')

    if [[ "$has_jom" -eq "1" ]]
    then
        MAKE="jom -j $(get_cpu_count)"
        CONFIG_PARAMS="-FS -MP1 -MT"
    else
        MAKE="nmake"
        CONFIG_PARAMS="-MT"
    fi

    cmd.exe /c perl ./Configure VC-WIN64A $CONFIG_PARAMS --prefix="${PREFIX_DIR}"

    log_info "make windows start..."

    cmd.exe /c "$VCVARSALL_PATH" x64 "&&" $MAKE clean > "${OUTPUT_ROOT}/log/windows.log" 2>/dev/null
    cmd.exe /c "$VCVARSALL_PATH" x64 "&&" $MAKE all >> "${OUTPUT_ROOT}/log/windows.log" 2>&1
    the_rc=$?
    if [ $the_rc -eq 0 ] ; then
        cmd.exe /c "$VCVARSALL_PATH" x64 "&&" $MAKE install_sw "||" $MAKE install_sw >> "${OUTPUT_ROOT}/log/windows.log" 2>&1
    fi

    popd
}

log_info "${PLATFORM_TYPE} openssl start..."

configure_make

log_info "${PLATFORM_TYPE} openssl end..."
