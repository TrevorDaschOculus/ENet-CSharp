@echo off

if not defined ANDROID_NDK_HOME (
	if defined ANDROID_NDK (
		set ANDROID_NDK_HOME="%ANDROID_NDK%"
	) else (
	    echo ANDROID_NDK_HOME environment variable is not set
	    exit 1
	)
)

pushd "%~dp0\.."

for %%a in (armeabi-v7a arm64-v8a x86 x86_64) do (
	if not exist "third-party\openssl\out\Android\%%a\lib\libssl.so" (

		echo "OpenSSL not built for %%a, building now"

		cd third-party\openssl\tools
		call bash -c "dos2unix ./*.sh"
		REM We need to escape the double escape the path, once for assignment, and once for when it is used by Configure
		call bash -c "export ANDROID_NDK_ROOT=$(wslpath -a '%ANDROID_NDK_HOME%' | sed 's/ /\\\\\\ /g' | sed 's/(/\\\\\\(/g' | sed 's/)/\\\\\\)/g') && ./build-android-openssl.sh %%a"
		cd ..\..\..
	)
)

echo "Building ENet Android"
cd Source\Native
call %ANDROID_NDK_HOME%\ndk-build.cmd NDK_LIBS_OUT=../../Unity/Plugins/Android -e ENET_DEBUG=1 all
cd ..\..

popd