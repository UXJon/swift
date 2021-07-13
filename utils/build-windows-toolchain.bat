:: build-windows-toolchain.bat
::
:: This source file is part of the Swift.org open source project
::
:: Copyright (c) 2014 - 2021 Apple Inc. and the Swift project authors
:: Licensed under Apache License v2.0 with Runtime Library Exception
::
:: See https://swift.org/LICENSE.txt for license information
:: See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors

setlocal enableextensions enabledelayedexpansion
path %PATH%;%PYTHON_HOME%

:: Identify the SourceRoot
:: Normalize the SourceRoot to make it easier to read the output.
cd %~dp0\..\..
set SourceRoot=%CD%

:: Identify the BuildRoot
set BuildRoot=%SourceRoot%\build

md %BuildRoot%
subst T: /d
subst T: %BuildRoot% || (exit /b)
set BuildRoot=T:

:: Identify the InstallRoot
set InstallRoot=%BuildRoot%\Library\Developer\Toolchains\unknown-Asserts-development.xctoolchain\usr

:: Setup temporary directories
md %BuildRoot%\tmp
set TEMP=%BuildRoot%\tmp
set TMP=%BuildRoot%\tmp
set TMPDIR=%BuildRoot%\tmp

call :CloneDependencies || (exit /b)
:: call :CloneRepositories || (exit /b)

:: build zlib
cmake ^
  -B %BuildRoot%\zlib ^
  -D BUILD_SHARED_LIBS=NO ^
  -D BUILD_TESTING=NO ^
  -D CMAKE_BUILD_TYPE=%CMAKE_BUILD_TYPE% ^
  -D CMAKE_C_COMPILER=cl ^
  -D CMAKE_INSTALL_PREFIX=%BuildRoot%\Library\zlib-1.2.11\usr ^

  -D SKIP_INSTALL_FILES=YES ^

  -G Ninja ^
  -S %SourceRoot%\zlib || (exit /b)
cmake --build "%BUildRoot%\zlib" || (exit /b)
cmake --build "%BUildRoot%\zlib" --target install || (exit /b)

:: build libxml2
cmake ^
  -B %BuildRoot%\libxml2 ^
  -D BUILD_SHARED_LIBS=NO ^
  -D CMAKE_BUILD_TYPE=%CMAKE_BUILD_TYPE% ^
  -D CMAKE_C_COMPILER=cl ^
  -D CMAKE_INSTALL_PREFIX=%BuildRoot%\Library\libxml2-2.9.12\usr ^

  -D LIBXML2_WITH_ICONV=NO ^
  -D LIBXML2_WITH_ICU=NO ^
  -D LIBXML2_WITH_LZMA=NO ^
  -D LIBXML2_WITH_PYTHON=NO ^
  -D LIBXML2_WITH_TESTS=NO ^
  -D LIBXML2_WITH_THREADS=YES ^
  -D LIBXML2_WITH_ZLIB=NO ^

  -G Ninja ^
  -S %SourceRoot%\libxml2 || (exit /b)
cmake --build "%BUildRoot%\libxml2" || (exit /b)
cmake --build "%BUildRoot%\libxml2" --target install || (exit /b)

:: Clean up the module cache
rd /s /q %LocalAppData%\clang\ModuleCache

goto :end
endlocal

:CloneRepositories
setlocal enableextensions enabledelayedexpansion

if defined REPO_SCHEME set "args=--scheme %REPO_SCHEME%"

:: Always enable symbolic links
git config --global core.symlink true

:: Ensure that we have the files in the original line endings, the swift tests
:: depend on this being the case.
git -C "%SourceRoot%\swift" config --local core.autocrlf input
git -C "%SourceRoot%\swift" checkout-index --force --all

set "args=%args% --skip-repository swift"
set "args=%args% --skip-repository ninja"
set "args=%args% --skip-repository icu"
set "args=%args% --skip-repository swift-integration-tests"
set "args=%args% --skip-repository swift-xcode-playground-support"

call "%SourceRoot%\swift\utils\update-checkout.cmd" %args% --clone --skip-history --github-comment "%ghprbCommentBody%"

goto :eof
endlocal

:CloneDependencies
setlocal enableextensions enabledelayedexpansion

:: Always enable symbolic links
git config --global core.symlink true

git clone --quiet --no-tags --depth 1 --branch v1.2.11 https://github.com/madler/zlib
git clone --quiet --no-tags --depth 1 --branch v2.9.12 https://github.com/gnome/libxml2
git clone --quiet --no-tags --depth 1 --branch version-3.36.0 https://github.com/sqlite/sqlite
git clone --quiet --no-tags --depth 1 --branch maint/maint-67 https://github.com/unicode-org/icu

goto :eof
endlocal

:end
