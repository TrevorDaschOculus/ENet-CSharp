@echo off

pushd "%~dp0\.."

RMDIR /S /Q Unity\Plugins

call tools\build_windows.bat
call tools\build_linux.bat

if defined ANDROID_NDK_HOME (
	call tools\build_android.bat
) else if defined ANDROID_NDK (
	call tools\build_android.bat
)

popd
