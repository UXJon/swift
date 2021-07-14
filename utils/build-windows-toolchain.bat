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
call :CloneRepositories || (exit /b)

:: TODO(compnerd) build ICU from source
curl.exe -OL "https://github.com/unicode-org/icu/releases/download/release-67-1/icu4c-67_1-Win64-MSVC2017.zip" || (exit /b)
"%ProgramFiles%\Git\usr\bin\unzip.exe" -o icuc-67_1-Win64-MSVC2017.zip -d %BuildRoot%\Library\icu-67.1

:: build zlib
cmake ^
  -B %BuildRoot%\zlib ^
  -D BUILD_SHARED_LIBS=NO ^
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

:: build curl
cmake ^
  -B %BuildRoot%\curl ^
  -D BUILD_SHARED_LIBS=NO ^
  -D BUILD_TESTING=NO ^
  -D CMAKE_BUILD_TYPE=%CMAKE_BUILD_TYPE% ^
  -D CMAKE_C_COMPILER=cl ^
  -D CMAKE_INSTALL_PREFIX=%BuildRoot%\Library\curl-7.77.0\usr ^

  -D BUILD_CURL_EXE=NO ^
  -D CMAKE_USE_OPENSSL=NO ^
  -D CURL_CA_PATH=none ^
  -D CMAKE_USE_SCHANNEL=YES ^
  -D CMAKE_USE_LIBSSH2=NO ^
  -D HAVE_POLL_FINE=NO ^
  -D CURL_DISABLE_LDAP=YES ^
  -D CURL_DISABLE_LDAPS=YES ^
  -D CURL_DISABLE_TELNET=YES ^
  -D CURL_DISABLE_DICT=YES ^
  -D CURL_DISABLE_FILE=YES ^
  -D CURL_DISABLE_TFTP=YES ^
  -D CURL_DISABLE_RTSP=YES ^
  -D CURL_DISABLE_PROXY=YES ^
  -D CURL_DISABLE_POP3=YES ^
  -D CURL_DISABLE_IMAP=YES ^
  -D CURL_DISABLE_SMTP=YES ^
  -D CURL_DISABLE_GOPHER=YES ^
  -D CURL_ZLIB=YES ^
  -D ENABLE_UNIX_SOCKETS=NO ^
  -D ENABLE_THREADED_RESOLVER=NO ^

  -D ZLIB_ROOT=%BuildRoot%\Library\zlib-1.2.11\usr ^

  -G Ninja ^
  -S %SourceRoot%\curl || (exit /b)
cmake --build "%BuildRoot%\curl" || (exit /b)
cmake --build "%BuildRoot%\curl" --target install || (exit /b)

cmake ^
  -B "%BuildRoot%\1" ^

  -C %SourceRoot%\swift\cmake\caches\Windows-x86_64.cmake ^

  -D CMAKE_BUILD_TYPE=%CMAKE_BUILD_TYPE% ^
  -D CMAKE_C_COMPILER=cl ^
  -D CMAKE_CXX_COMPILER=cl ^
  -D CMAKE_CXX_FLAGS="/GS- /Oy" ^
  -D CMAKE_INSTALL_PREFIX="%InstallRoot%" ^
  -D CMAKE_MT=mt ^

  -D CMAKE_EXE_LINKER_FLAGS="/INCREMENTAL:NO" ^
  -D CMAKE_SHARED_LINKER_FLAGS="/INCREMENTAL:NO" ^

  -D PACKAGE_VENDOR="swift.org" ^
  -D CLANG_VENDOR="swift.org" ^
  -D CLANG_VENDOR_UTI="org.swift" ^
  -D LLVM_APPEND_VC_REV=NO ^
  -D LLVM_VERSION_SUFFIX="" ^

  -D SWIFT_ENABLE_EXPERIMENTAL_CONCURRENCY=YES ^
  -D SWIFT_ENABLE_EXPERIMENTAL_DISTRIBUTED=YES ^
  -D SWIFT_ENABLE_EXPERIMENTAL_DIFFERENTIABLE_PROGRAMMING=YES ^

  -D LLVM_EXTERNAL_SWIFT_SOURCE_DIR="%SourceRoot%\swift" ^
  -D LLVM_EXTERNAL_CMARK_SOURCE_DIR="%SourceRoot%\cmark" ^
  -D PYTHON_HOME="%PYTHON_HOME%" ^
  -D PYTHON_EXECUTABLE="%PYTHON_HOME%\python.exe" ^
  -D SWIFT_PATH_TO_LIBDISPATCH_SOURCE="%SourceRoot%\swift-corelibs-libdispatch" ^
  -D SWIFT_WINDOWS_x86_64_ICU_UC_INCLUDE="%BuildRoot%\Library\icu-67.1\include\unicode" ^
  -D SWIFT_WINDOWS_x86_64_ICU_UC="%BuildRoot%\Library\icu-67.1\lib64\icuuc.lib" ^
  -D SWIFT_WINDOWS_x86_64_ICU_I18N_INCLUDE="%BuildRoot%\Library\icu-67.1\include" ^
  -D SWIFT_WINDOWS_x86_64_ICU_I18N="%BuildRoot%\Library\icu-67.1\lib64\icuin.lib" ^

  -G Ninja ^
  -S llvm-project\llvm || (exit /b)
cmake --build "%BuildRoot%\1" || (exit /b)
cmake --build "%BuildRoot%\1" --target install || (exit /b)

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

:: FIXME(compnerd) avoid the fresh clone
rd /s /q zlib libxml2 sqlite icu curl

git clone --quiet --no-tags --depth 1 --branch v1.2.11 https://github.com/madler/zlib
git clone --quiet --no-tags --depth 1 --branch v2.9.12 https://github.com/gnome/libxml2
git clone --quiet --no-tags --depth 1 --branch version-3.36.0 https://github.com/sqlite/sqlite
git clone --quiet --no-tags --depth 1 --branch maint/maint-67 https://github.com/unicode-org/icu
git clone --quiet --no-tags --depth 1 --branch curl-7_77_0 https://github.com/curl/curl

goto :eof
endlocal

:end
