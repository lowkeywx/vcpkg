if(VCPKG_LIBRARY_LINKAGE STREQUAL "static")
    set(FIX_STATIC_DIFF fix_find_static_patch.diff)
endif(VCPKG_LIBRARY_LINKAGE STREQUAL "static")

vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO libuv/libuv
    REF v1.43.0
    SHA512 66ee11f8f6fc1313c432858572789cf67acd6364b29a06c73323ab20626e2d6e3d3dcea748cf5d9d4368b40ad7fe0d5fd35e9369c22e531db523703f005248d3
    HEAD_REF v1.x
    PATCHES
        ${FIX_STATIC_DIFF}
)

vcpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}"
    OPTIONS_DEBUG
        -DLIBUV_BUILD_TESTS=OFF
        -DLIBUV_BUILD_BENCH=OFF
)

vcpkg_cmake_install()
vcpkg_copy_pdbs()
vcpkg_cmake_config_fixup(CONFIG_PATH lib/cmake/libuv)

file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/share")
file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/include")

#file(INSTALL "${CMAKE_CURRENT_LIST_DIR}/vcpkg-cmake-wrapper.cmake" DESTINATION ${CURRENT_PACKAGES_DIR}/share/${PORT})
file(INSTALL "${SOURCE_PATH}/LICENSE" DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}" RENAME copyright)

