@echo off

pushd "%~dp0\.."

if not exist "third-party\openssl\out\Linux\lib\libssl.so" (
	echo "OpenSSL not built, building now"
	cd third-party\openssl\tools
	call bash -c "dos2unix ./*.sh"
	call bash -c "./build-linux-openssl.sh"
	cd ..\..\..
)

mkdir build_cmake_enet
cd build_cmake_enet

del CMakeCache.txt

echo "Configuring CMake Linux (Debug)"
call bash -c "cmake -DOpenSSL_ROOT=../third-party/openssl/out/Linux/ -DENET_DEBUG=ON .."

echo "Building ENet Linux (Debug)"
call bash -c "make clean"
call bash -c "make"

call bash -c "zip ../Unity/Plugins/Linux/libenet_debug.zip ../Unity/Plugins/Linux/libenet.so"

echo "Configuring CMake Linux"

del CMakeCache.txt

call bash -c "cmake -DOpenSSL_ROOT=../third-party/openssl/out/Linux/ .."

echo "Building ENet Linux"
call bash -c "make clean"
call bash -c "make"

cd ..

copy third-party\openssl\out\Linux\lib\libcrypto.so Unity\Plugins\Linux\libcrypto.so
copy third-party\openssl\out\Linux\lib\libssl.so Unity\Plugins\Linux\libssl.so

popd