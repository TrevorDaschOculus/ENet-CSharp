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

if [ -z ${arch+x} ]; then 
  arch=("x86" "x64")
fi
if [ -z ${target+x} ]; then 
  target=("x86" "x86_64")
fi

export PLATFORM_TYPE="Windows"
export ARCHS=(${arch[@]})
export TARGETS=(${target[@]})

init_log_color

if [[ -z "${VCVARSALL_PATH}" ]]; then
  echo "VCVARSALL_PATH not defined"
  exit 1
fi

TOOLS_ROOT=$(realpath $0)
TOOLS_ROOT_WIN=$(wslpath -w ${TOOLS_ROOT})

echo TOOLS_ROOT=${TOOLS_ROOT}

OPENSSL_SRC_DIR="${TOOLS_ROOT}/../src"

function get_vc_platform() {
    local arch=$1
    case ${arch} in
    x86)
        echo "VC-WIN32"
        ;;
    x64)
        echo "VC-WIN64A"
        ;;
  esac
}

function configure_make() {

    ARCH=$1
    TARGET=$2

    log_info "configure windows start..."

    pushd .
    cd "${OPENSSL_SRC_DIR}"

    PREFIX_DIR="${TOOLS_ROOT_WIN}\\..\\out\\Windows\\${TARGET}\\"
    OUTPUT_ROOT=${TOOLS_ROOT}/../out/Windows/${TARGET}/

    if [ -d "${OUTPUT_ROOT}" ]; then
        rm -fr "${OUTPUT_ROOT}"
    fi
    mkdir -p "${OUTPUT_ROOT}"

    mkdir -p ${OUTPUT_ROOT}/log

    cmd.exe /c "$VCVARSALL_PATH" $ARCH

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

    local vcplatform=$(get_vc_platform $ARCH)

    cmd.exe /c perl ./Configure $vcplatform $CONFIG_PARAMS --prefix="${PREFIX_DIR}"

    log_info "make windows start..."

    cmd.exe /c "$VCVARSALL_PATH" $ARCH "&&" $MAKE clean > "${OUTPUT_ROOT}/log/windows.log" 2>/dev/null
    cmd.exe /c "$VCVARSALL_PATH" $ARCH "&&" $MAKE all >> "${OUTPUT_ROOT}/log/windows.log" 2>&1
    the_rc=$?
    if [ $the_rc -eq 0 ] ; then
        cmd.exe /c "$VCVARSALL_PATH" $ARCH "&&" $MAKE install_sw "||" $MAKE install_sw >> "${OUTPUT_ROOT}/log/windows.log" 2>&1
    fi

    popd
}

log_info "${PLATFORM_TYPE} openssl start..."

for ((i = 0; i < ${#ARCHS[@]}; i++)); do
    if [[ $# -eq 0 || "$1" == "${ARCHS[i]}" || "$1" == "${TARGETS[i]}" ]]; then
        configure_make "${ARCHS[i]}" "${TARGETS[i]}"
    fi
done

log_info "${PLATFORM_TYPE} openssl end..."
