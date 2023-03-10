@echo off

setlocal EnableDelayedExpansion

pushd "%~dp0\.."

set OUT_DIR=Windows\x86
set EXT=
set BUILD_PLATFORM=Win32
for %%p in (x86 x64) do (
	call tools\find_vcvarsall.bat %%p

	if "%%p"=="x64" (
		set OUT_DIR=Windows\x86_64
		set EXT=-x64
		set BUILD_PLATFORM=x64
	) else (
		set OUT_DIR=Windows\x86
		set EXT=
		set BUILD_PLATFORM=Win32
	)

	if not exist third-party\openssl\out\!OUT_DIR!\bin\libcrypto-1_1!EXT!.dll (
		echo "OpenSSL not built for Windows %%p, building now"	
		cd third-party\openssl\tools
		call bash -c "dos2unix ./*.sh"
		call bash -c "export VCVARSALL_PATH='..\..\..\tools\find_vcvarsall.bat'; ./build-windows-openssl.sh %%p"
		cd ..\..\..
	)

	echo "Configuring CMake Windows %%p"
	mkdir build_cmake_enet
	cd build_cmake_enet

	del CMakeCache.txt

	call cmake -A !BUILD_PLATFORM! -DOpenSSL_ROOT=..\third-party\openssl\out\!OUT_DIR!\ ..

	echo "Building ENet Windows %%p"
	call MSBuild.exe enet.sln /t:Clean,Build /property:Configuration=Release /property:Platform=!BUILD_PLATFORM!
	cd ..

	copy third-party\openssl\out\!OUT_DIR!\bin\libcrypto-1_1!EXT!.dll Unity\Plugins\!OUT_DIR!\
	copy third-party\openssl\out\!OUT_DIR!\bin\libssl-1_1!EXT!.dll Unity\Plugins\!OUT_DIR!\

)
popd