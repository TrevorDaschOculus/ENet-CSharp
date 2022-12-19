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
# Modified by Trevor Dasch to remove build-android-common.sh and unnecessary
# configuration steps for usage by ENet
#

set -u

source ./build-common.sh

TOOLS_ROOT=$(realpath $0)

echo TOOLS_ROOT=${TOOLS_ROOT}

if [ -z ${arch+x} ]; then 
  arch=("arm" "arm64" "x86" "x86_64")
fi
if [ -z ${abi+x} ]; then 
  abi=("armeabi-v7a" "arm64-v8a" "x86" "x86_64")
fi
if [ -z ${api+x} ]; then 
  api=23
fi

export PLATFORM_TYPE="Android"
export ARCHS=(${arch[@]})
export ABIS=(${abi[@]})
export API=${api}

if [[ -z ${ANDROID_NDK_ROOT} ]]; then
  echo "ANDROID_NDK_ROOT not defined"
  exit 1
fi

function get_host_os() {
    if [ $(uname -r | sed -n 's/.*\( *Microsoft *\).*/\1/ip') ]
    then
            echo "windows"
    else
            echo "linux"
    fi
}

function get_toolchain() {
  HOST_OS=$(get_host_os)

  HOST_ARCH=$(uname -m)
  case ${HOST_ARCH} in
  i?86) HOST_ARCH=x86 ;;
  x86_64 | amd64) HOST_ARCH=x86_64 ;;
  esac

  echo "${HOST_OS}-${HOST_ARCH}"
}

function get_build_host_internal() {
  local arch=$1
  case ${arch} in
  arm-v7a | arm-v7a-neon)
    echo "arm-linux-androideabi"
    ;;
  arm64-v8a)
    echo "aarch64-linux-android"
    ;;
  x86)
    echo "i686-linux-android"
    ;;
  x86-64)
    echo "x86_64-linux-android"
    ;;
  esac
}

function get_common_includes() {
  local toolchain=$(get_toolchain)
  echo "-I${ANDROID_NDK_ROOT}/toolchains/llvm/prebuilt/${toolchain}/sysroot/usr/include -I${ANDROID_NDK_ROOT}/toolchains/llvm/prebuilt/${toolchain}/sysroot/usr/local/include"
}
function get_common_linked_libraries() {
  local api=$1
  local arch=$2
  local toolchain=$(get_toolchain)
  local build_host=$(get_build_host_internal "$arch")
  echo "-L${ANDROID_NDK_ROOT}/toolchains/llvm/prebuilt/${toolchain}/${build_host}/lib -L${ANDROID_NDK_ROOT}/toolchains/llvm/prebuilt/${toolchain}/sysroot/usr/lib/${build_host}/${api} -L${ANDROID_NDK_ROOT}/toolchains/llvm/prebuilt/${toolchain}/lib"
}

function set_android_cpu_feature() {
  local name=$1
  local arch=$2
  local api=$3
  case ${arch} in
  arm-v7a | arm-v7a-neon)
    export CFLAGS="-march=armv7-a -mfpu=vfpv3-d16 -mfloat-abi=softfp -Wno-unused-function -fno-integrated-as -fstrict-aliasing -fPIC -DANDROID -Os -ffunction-sections -fdata-sections $(get_common_includes)"
    export CXXFLAGS="-std=c++14 -Os -ffunction-sections -fdata-sections"
    export LDFLAGS="-march=armv7-a -mfpu=vfpv3-d16 -mfloat-abi=softfp -Wl,--fix-cortex-a8 -Wl,--gc-sections -Os -ffunction-sections -fdata-sections $(get_common_linked_libraries ${api} ${arch})"
    export CPPFLAGS=${CFLAGS}
    ;;
  arm64-v8a)
    export CFLAGS="-march=armv8-a -Wno-unused-function -fno-integrated-as -fstrict-aliasing -fPIC -DANDROID -Os -ffunction-sections -fdata-sections $(get_common_includes)"
    export CXXFLAGS="-std=c++14 -Os -ffunction-sections -fdata-sections"
    export LDFLAGS="-march=armv8-a -Wl,--gc-sections -Os -ffunction-sections -fdata-sections $(get_common_linked_libraries ${api} ${arch})"
    export CPPFLAGS=${CFLAGS}
    ;;
  x86)
    export CFLAGS="-march=i686 -mtune=i686 -mssse3 -mfpmath=sse -m32 -Wno-unused-function -fno-integrated-as -fstrict-aliasing -fPIC -DANDROID -Os -ffunction-sections -fdata-sections $(get_common_includes)"
    export CXXFLAGS="-std=c++14 -Os -ffunction-sections -fdata-sections"
    export LDFLAGS="-march=i686 -Wl,--gc-sections -Os -ffunction-sections -fdata-sections $(get_common_linked_libraries ${api} ${arch})"
    export CPPFLAGS=${CFLAGS}
    ;;
  x86-64)
    export CFLAGS="-march=x86-64 -msse4.2 -mpopcnt -m64 -mtune=x86-64 -Wno-unused-function -fno-integrated-as -fstrict-aliasing -fPIC -DANDROID -Os -ffunction-sections -fdata-sections $(get_common_includes)"
    export CXXFLAGS="-std=c++14 -Os -ffunction-sections -fdata-sections"
    export LDFLAGS="-march=x86-64 -Wl,--gc-sections -Os -ffunction-sections -fdata-sections $(get_common_linked_libraries ${api} ${arch})"
    export CPPFLAGS=${CFLAGS}
    ;;
  esac
}

export PATH=${ANDROID_NDK_ROOT}/toolchains/llvm/prebuilt/$(get_toolchain)/bin:$PATH

export ANDROID_NDK_HOME=${ANDROID_NDK_ROOT}
echo ANDROID_NDK_HOME=$ANDROID_NDK_HOME

OPENSSL_SRC_DIR="${TOOLS_ROOT}/../src"

function configure_make() {

    ARCH=$1
    ABI=$2
    API=$3

    log_info "configure $ABI start..."

    pushd .
    cd "${OPENSSL_SRC_DIR}"

    PREFIX_DIR="${TOOLS_ROOT}/../out/Android/${ABI}/"
    if [ -d "${PREFIX_DIR}" ]; then
        rm -fr "${PREFIX_DIR}"
    fi
    mkdir -p "${PREFIX_DIR}"

    OUTPUT_ROOT=${TOOLS_ROOT}/../out/Android/${ABI}/
    mkdir -p ${OUTPUT_ROOT}/log

    set_android_cpu_feature "openssl" "$ABI" "$API"

    echo ./Configure "android-${ARCH}" --prefix="${PREFIX_DIR}"
    ./Configure "android-${ARCH}" --prefix="${PREFIX_DIR}"

    log_info "make $ABI start..."

    make clean >"${OUTPUT_ROOT}/log/${ABI}.log"
    make -j $(get_cpu_count) SHLIB_EXT='.so' all >>"${OUTPUT_ROOT}/log/${ABI}.log" 2>&1
    the_rc=$?
    if [ $the_rc -eq 0 ] ; then
        make -j $(get_cpu_count) SHLIB_EXT='.so' install_sw >>"${OUTPUT_ROOT}/log/${ABI}.log" 2>&1
        make -j $(get_cpu_count) install_ssldirs >>"${OUTPUT_ROOT}/log/${ABI}.log" 2>&1
    fi

    popd
}

log_info "${PLATFORM_TYPE} openssl start..."

for ((i = 0; i < ${#ARCHS[@]}; i++)); do
    if [[ $# -eq 0 || "$1" == "${ARCHS[i]}" || "$1" == "${ABIS[i]}" ]]; then
        configure_make "${ARCHS[i]}" "${ABIS[i]}" "${API}"
    fi
done

log_info "${PLATFORM_TYPE} openssl end..."
