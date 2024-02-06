@echo off

pushd "%~dp0\.."

if not exist "third-party\openssl\out\MacOS\lib\libssl.dylib" (
	echo "OpenSSL not built, building now"
	cd third-party\openssl\tools
	call bash -c "dos2unix ./*.sh"
	call bash -c "./build-mac-openssl.sh"
	cd ..\..\..
)

mkdir build_cmake_enet
cd build_cmake_enet

del CMakeCache.txt

echo "Configuring CMake Mac (Debug)"
call bash -c "cmake -DOpenSSL_ROOT=../third-party/openssl/out/MacOS/ -DENET_DEBUG=ON .."

echo "Building ENet Mac (Debug)"
call bash -c "make clean"
call bash -c "make"

call bash -c "zip ../Unity/Plugins/MacOS/libenet_debug.zip ../Unity/Plugins/MacOS/libenet.dylib"

echo "Configuring CMake MacOS"

del CMakeCache.txt

call bash -c "cmake -DOpenSSL_ROOT=../third-party/openssl/out/MacOS/ .."

echo "Building ENet MacOS"
call bash -c "make clean"
call bash -c "make"

cd ..

copy third-party\openssl\out\MacOS\lib\libcrypto.dylib Unity\Plugins\MacOS\libcrypto.dylib
copy third-party\openssl\out\MacOS\lib\libssl.dylib Unity\Plugins\MacOS\libssl.dylib

popd
