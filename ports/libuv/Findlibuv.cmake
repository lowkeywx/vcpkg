
# 如果 ${CURRENT_PACKAGES_DIR} 不行需要改成  get_filename_component(SEARCH_PATH "${CMAKE_CURRENT_LIST_FILE}" PATH)

find_path(LIBUV_INCLUDE_DIRS 
    NAMES
        uv.h
    HINTS
        ${CURRENT_PACKAGES_DIR}
)

find_library(LIBUV_LIBRARIES 
    NAMES
        libuv
    HINTS
        ${CURRENT_PACKAGES_DIR}
)

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(libuv REQUIRED_VARS LIBUV_INCLUDE_DIRS LIBUV_LIBRARIES)

