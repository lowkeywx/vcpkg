set(X264_VERSION 164)

vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO mirror/x264
    REF 5db6aa6cab1b146e07b60cc1736a01f21da01154
    SHA512 d2cdd40d195fd6507abacc8b8810107567dff2c0a93424ba1eb00b544cb78a5430f00f9bcf8f19bd663ae77849225577da05bfcdb57948a8af9dc32a7c8b9ffd
    HEAD_REF stable
    PATCHES
        "uwp-cflags.patch"
)

if("gpl" IN_LIST FEATURES)
    set(OPTIONS "${OPTIONS} --enable-gpl")
else()
    set(OPTIONS "${OPTIONS} --disable-gpl")
endif()


vcpkg_find_acquire_program(NASM)
get_filename_component(NASM_EXE_PATH ${NASM} DIRECTORY)
vcpkg_add_to_path(${NASM_EXE_PATH})

vcpkg_cmake_get_vars(cmake_vars_file)
include("${cmake_vars_file}")

if(VCPKG_TARGET_IS_WINDOWS)
    z_vcpkg_determine_autotools_host_cpu(BUILD_ARCH)
    z_vcpkg_determine_autotools_target_cpu(HOST_ARCH)
    list(APPEND OPTIONS --build=${BUILD_ARCH}-pc-mingw32)
    list(APPEND OPTIONS --host=${HOST_ARCH}-pc-mingw32)
    set(ENV{AS} "${NASM}")
endif()

if(VCPKG_TARGET_IS_UWP)
    list(APPEND OPTIONS --extra-cflags=-DWINAPI_FAMILY=WINAPI_FAMILY_APP --extra-cflags=-D_WIN32_WINNT=0x0A00)
    list(APPEND OPTIONS --extra-ldflags=-APPCONTAINER --extra-ldflags=WindowsApp.lib)
    list(APPEND OPTIONS --disable-asm)
endif()

if(VCPKG_TARGET_IS_LINUX)
    list(APPEND OPTIONS --enable-pic)
endif()

if(VCPKG_TARGET_IS_IOS OR VCPKG_TARGET_IS_OSX)

    #交叉编译需要设置host
    if(VCPKG_TARGET_ARCHITECTURE STREQUAL "x86")
        set(X264_ARCH "i386")
        set(X264_HOTS "i386-apple-darwin")
    elseif (VCPKG_TARGET_ARCHITECTURE STREQUAL "x64")
        set(X264_ARCH "x86_64")
        set(X264_HOTS "x86_64-apple-darwin")
    elseif(VCPKG_TARGET_ARCHITECTURE STREQUAL "arm64")
        set(X264_ARCH "arm64")
        set(ASM_OPTION "-arch arm64")
        set(X264_HOTS "arm64-apple-darwin")
    else()
        set(X264_ARCH "armv7")
        set(ASM_OPTION "-arch arm")
        set(X264_HOTS "arm-apple-darwin")
    endif()

    if(VCPKG_TARGET_IS_IOS)
        #配置platform
        if (VCPKG_TARGET_ARCHITECTURE MATCHES "x86" OR VCPKG_TARGET_ARCHITECTURE MATCHES "x64")
            set(X264_USE_PLATFORM iphonesimulator)
            list(APPEND OPTIONS "--disable-asm")
        elseif (${VCPKG_TARGET_ARCHITECTURE} STREQUAL "arm" OR ${VCPKG_TARGET_ARCHITECTURE} STREQUAL "arm64")
            set(X264_USE_PLATFORM iphoneos)
        endif()
        #获取对应平台的sdk路径
        execute_process(COMMAND xcodebuild -version -sdk ${X264_USE_PLATFORM} Path
        OUTPUT_VARIABLE X264_USE_ISYSROOT
        ERROR_QUIET
        OUTPUT_STRIP_TRAILING_WHITESPACE)
        #配置环境变量和编译选项
        list(APPEND OPTIONS "--host=${X264_HOTS}")
        set(ENV{CFLAGS} "$ENV{CFLAGS} -isysroot ${X264_USE_ISYSROOT}")
    else()

        if((NOT VCPKG_TARGET_ARCHITECTURE MATCHES "^x" AND VCPKG_DETECTED_CMAKE_HOST_SYSTEM_PROCESSOR MATCHES "^x") OR 
        (NOT VCPKG_TARGET_ARCHITECTURE MATCHES "^arm" AND VCPKG_DETECTED_CMAKE_HOST_SYSTEM_PROCESSOR MATCHES "^arm"))
            execute_process(COMMAND xcodebuild -version -sdk macosx Path
            OUTPUT_VARIABLE X264_USE_ISYSROOT
            ERROR_QUIET
            OUTPUT_STRIP_TRAILING_WHITESPACE)
            list(APPEND OPTIONS "--host=${X264_HOTS}")
            set(ENV{CFLAGS} "$ENV{CFLAGS} -isysroot ${X264_USE_ISYSROOT}")
        endif()

    endif(VCPKG_TARGET_IS_IOS)    

    #set(ENV{ASFLAGS}  "$ENV{ASFLAGS} $ENV{CFLAGS}")
    set(ENV{LDFLAGS}  "$ENV{LDFLAGS} $ENV{CFLAGS}")
    set(ENV{AR} "${VCPKG_DETECTED_CMAKE_AR}")
    set(ENV{RANLIB} "${VCPKG_DETECTED_CMAKE_RANLIB}")
    #获取对应平台的工具链 CC
    execute_process(COMMAND xcrun --find clang
    OUTPUT_VARIABLE X264_USE_CC
    ERROR_QUIET
    OUTPUT_STRIP_TRAILING_WHITESPACE)
    set(ENV{CC} "${X264_USE_CC}")
    #arm架构需要借助gas-preprocessor配置汇编命令
    if(VCPKG_TARGET_ARCHITECTURE MATCHES "^(ARM|arm)")
        set(ENV{AS} "${SOURCE_PATH}/tools/gas-preprocessor.pl ${ASM_OPTION} -- $ENV{CC} $ENV{CFLAGS} -arch ${X264_ARCH} ${VCPKG_DETECTED_CMAKE_C_FLAGS}")        
    endif()

endif()

if(VCPKG_TARGET_IS_ANDROID)
    get_filename_component(X264_TOOLCHAIN "${VCPKG_DETECTED_CMAKE_C_COMPILER}" PATH)
    get_filename_component(X264_TOOLCHAIN "${X264_TOOLCHAIN}" PATH)
    z_vcpkg_determine_autotools_target_cpu(X264_TARGET_ARCH)
    set(API_LEVEL 21)
    if(VCPKG_TARGET_ARCHITECTURE MATCHES "^(ARM|arm)$")
        set(TARGET ${X264_TARGET_ARCH}-linux-androideabi)
        set(TARGET_CC_PRIFIX armv7a-linux-androideabi)
    else()
        set(TARGET ${X264_TARGET_ARCH}-linux-android)
        set(TARGET_CC_PRIFIX ${TARGET})
    endif()
    #message(FATAL_ERROR "aaa=${X264_TOOLCHAIN}/bin/${TARGET}-ar")
    list(APPEND OPTIONS "--host=${TARGET}")
    list(APPEND OPTIONS "--sysroot=${X264_TOOLCHAIN}/sysroot")
    list(APPEND OPTIONS --disable-asm)

    set(ENV{AR} "${X264_TOOLCHAIN}/bin/${TARGET}-ar")
    set(ENV{CC} "${X264_TOOLCHAIN}/bin/${TARGET_CC_PRIFIX}${API_LEVEL}-clang")
    set(ENV{CXX} "${X264_TOOLCHAIN}/bin/${TARGET_CC_PRIFIX}${API_LEVEL}-clang++}")
    set(ENV{LD} "${X264_TOOLCHAIN}/bin/${TARGET}-ld")
    set(ENV{RANLIB} "${X264_TOOLCHAIN}/bin/${TARGET}-ranlib")
    set(ENV{STRIP} "${X264_TOOLCHAIN}/bin/${TARGET}-strip")
endif()

vcpkg_configure_make(
    SOURCE_PATH ${SOURCE_PATH}
    NO_ADDITIONAL_PATHS
    OPTIONS
        ${OPTIONS}
        --enable-strip
        --disable-lavf
        --disable-swscale
        --disable-avs
        --disable-ffms
        --disable-gpac
        --disable-lsmash
        --disable-cli
    OPTIONS_DEBUG
        --enable-debug
)

vcpkg_install_make()

# fix ios asm file build bug
if((VCPKG_TARGET_IS_IOS OR VCPKG_TARGET_IS_OSX) AND VCPKG_TARGET_ARCHITECTURE MATCHES "^(ARM|arm)")
    foreach(buildtype IN ITEMS "debug" "release")
        if(NOT DEFINED VCPKG_BUILD_TYPE OR VCPKG_BUILD_TYPE STREQUAL "${buildtype}")
            # for ios arguments begine
            set(BUILD_DIR)
            set(LOGFILE_PATH)
            
            if(${buildtype} STREQUAL "debug")
                set(PACKAGES_DIR ${CURRENT_PACKAGES_DIR}/debug/lib)
                set(BUILD_DIR "${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-dbg")
                set(LOGFILE_PATH "build-${TARGET_TRIPLET}-dbg-asm") 
            else()
                set(PACKAGES_DIR ${CURRENT_PACKAGES_DIR}/lib)
                set(BUILD_DIR "${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-rel")
                set(LOGFILE_PATH "build-${TARGET_TRIPLET}-rel-asm") 
            endif()
            # for ios arguments end
            configure_file("${CMAKE_CURRENT_LIST_DIR}/asm-build.sh.in" "${BUILD_DIR}/asm-build.sh" @ONLY)
            vcpkg_execute_required_process(
                COMMAND ${SHELL} ./asm-build.sh
                WORKING_DIRECTORY ${BUILD_DIR}
                LOGNAME "${LOGFILE_PATH}"
            )

        endif()
    endforeach()
endif()

if(NOT VCPKG_TARGET_IS_UWP)
    #vcpkg_copy_tools(TOOL_NAMES x264 AUTO_CLEAN)
endif()

file(REMOVE_RECURSE ${CURRENT_PACKAGES_DIR}/debug/include)

if(VCPKG_TARGET_IS_WINDOWS)
    set(pcfile "${CURRENT_PACKAGES_DIR}/lib/pkgconfig/x264.pc")
    if(EXISTS "${pcfile}")
      vcpkg_replace_string("${pcfile}" "-lx264" "-llibx264")
    endif()
    if (NOT VCPKG_BUILD_TYPE OR VCPKG_BUILD_TYPE STREQUAL "debug")
      set(pcfile "${CURRENT_PACKAGES_DIR}/debug/lib/pkgconfig/x264.pc")
      if(EXISTS "${pcfile}")
        vcpkg_replace_string("${pcfile}" "-lx264" "-llibx264")
      endif()
    endif()
endif()

if(VCPKG_LIBRARY_LINKAGE STREQUAL "dynamic" AND VCPKG_TARGET_IS_WINDOWS AND NOT VCPKG_TARGET_IS_MINGW)
    file(RENAME ${CURRENT_PACKAGES_DIR}/lib/libx264.dll.lib ${CURRENT_PACKAGES_DIR}/lib/libx264.lib)

    if (NOT VCPKG_BUILD_TYPE)
        file(RENAME ${CURRENT_PACKAGES_DIR}/debug/lib/libx264.dll.lib ${CURRENT_PACKAGES_DIR}/debug/lib/libx264.lib)
    endif()
elseif(VCPKG_LIBRARY_LINKAGE STREQUAL "static")
    # force U_STATIC_IMPLEMENTATION macro
    file(READ ${CURRENT_PACKAGES_DIR}/include/x264.h HEADER_CONTENTS)
    string(REPLACE "defined(U_STATIC_IMPLEMENTATION)" "1" HEADER_CONTENTS "${HEADER_CONTENTS}")
    file(WRITE ${CURRENT_PACKAGES_DIR}/include/x264.h "${HEADER_CONTENTS}")

    file(REMOVE_RECURSE
        ${CURRENT_PACKAGES_DIR}/bin
        ${CURRENT_PACKAGES_DIR}/debug/bin
    )
endif()

vcpkg_fixup_pkgconfig()

vcpkg_copy_pdbs()

file(INSTALL ${SOURCE_PATH}/COPYING DESTINATION ${CURRENT_PACKAGES_DIR}/share/${PORT} RENAME copyright)
