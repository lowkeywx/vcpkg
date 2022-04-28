set(VCPKG_TARGET_ARCHITECTURE arm64)
set(VCPKG_CRT_LINKAGE dynamic)
set(VCPKG_LIBRARY_LINKAGE static)

set(VCPKG_OSX_DEPLOYMENT_TARGET 10.12)
set(VCPKG_CMAKE_SYSTEM_NAME Darwin)
set(VCPKG_OSX_ARCHITECTURES arm64)
set(VCPKG_CXX_FLAGS "-fembed-bitcode")
set(VCPKG_C_FLAGS "-fembed-bitcode")
set(VCPKG_LINKER_FLAGS "-fembed-bitcode")
