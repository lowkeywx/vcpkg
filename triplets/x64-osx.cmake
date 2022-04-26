set(VCPKG_TARGET_ARCHITECTURE x64)
set(VCPKG_CRT_LINKAGE dynamic)
set(VCPKG_LIBRARY_LINKAGE static)

set(VCPKG_CMAKE_SYSTEM_NAME Darwin)
set(VCPKG_OSX_ARCHITECTURES x86_64)
set(VCPKG_CXX_FLAGS "-fembed-bitcode -mmacosx-version-min=10.12")
set(VCPKG_C_FLAGS "-fembed-bitcode -mmacosx-version-min=10.12")
set(VCPKG_LINKER_FLAGS "-fembed-bitcode -mmacosx-version-min=10.12")

