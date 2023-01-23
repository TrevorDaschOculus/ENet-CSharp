@echo off

pushd "%~dp0\.."

call tools\find_vcvarsall.bat

if not exist third-party\openssl\out\Windows\bin\libcrypto-1_1-x64.dll (
	echo "OpenSSL not built for Windows, building now"	
	cd third-party\openssl\tools
	call bash -c "dos2unix ./*.sh"
	call bash -c "export VCVARSALL_PATH='..\..\..\tools\find_vcvarsall.bat'; ./build-windows-openssl.sh"
	cd ..\..\..
)

echo "Configuring CMake Windows"
mkdir build_cmake_enet
cd build_cmake_enet

del CMakeCache.txt

call cmake -DOpenSSL_ROOT=..\third-party\openssl\out\Windows\ ..

echo "Building ENet Windows"
call MSBuild.exe enet.sln /t:Clean,Build /property:Configuration=Release
cd ..

copy third-party\openssl\out\Windows\bin\libcrypto-1_1-x64.dll Unity\Plugins\Windows\crypto.dll
copy third-party\openssl\out\Windows\bin\libssl-1_1-x64.dll Unity\Plugins\Windows\ssl.dll

popd