@echo off

if "%~1"=="x86" (
  set PLATFORM=x86
) else (
  set PLATFORM=x64
)


REM Check if vcvarsal.bat has already run
if defined VCVARSALL_PATH (
	where /q MSBuild.exe
	if ERRORLEVEL 1 (
		goto :find
	)

	where /q nmake.exe
	if ERRORLEVEL 1 (
		goto :find
	)

	if defined VCVARSALL_PLATFORM (		
		if "%VCVARSALL_PLATFORM%"=="%PLATFORM%" (
			goto :done
		) else (
			# need to reapply vcvarsall for new platform
			goto :found
		)
	)
)

:find
REM Try to find vcvarsall.bat

for %%p in (
	"C:\Program Files (x86)\Microsoft Visual Studio\2019\Professional\VC\Auxiliary\Build\vcvarsall.bat" 
	"C:\Program Files (x86)\Microsoft Visual Studio\2017\Professional\VC\Auxiliary\Build\vcvarsall.bat"
	"C:\Program Files (x86)\Microsoft Visual Studio 14.0\VC\vcvarsall.bat"
	"C:\Program Files (x86)\Microsoft Visual Studio 12.0\VC\vcvarsall.bat") do (

	if exist "%%p" (
		set VCVARSALL_PATH=%%p
		goto :found
	)
)

echo "Failed to find vcvarsall.bat"
exit 1

:found

REM strip surrounding quotes
set VCVARSALL_PATH=%VCVARSALL_PATH:"=%
set VCVARSALL_PLATFORM=%PLATFORM%
call "%VCVARSALL_PATH%" %VCVARSALL_PLATFORM%

:done