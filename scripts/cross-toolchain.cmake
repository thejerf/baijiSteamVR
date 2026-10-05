set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_SYSTEM_PROCESSOR aarch64)

set(CMAKE_C_COMPILER   aarch64-linux-gnu-gcc)
set(CMAKE_CXX_COMPILER aarch64-linux-gnu-g++)
set(CMAKE_AR           aarch64-linux-gnu-ar)
set(CMAKE_RANLIB       aarch64-linux-gnu-ranlib)
set(CMAKE_STRIP        aarch64-linux-gnu-strip)
set(CMAKE_OBJCOPY      aarch64-linux-gnu-objcopy)

set(CMAKE_SYSROOT /sysroot)
set(CMAKE_FIND_ROOT_PATH /sysroot)

set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)

# Let CMake run aarch64 test binaries during configure via qemu.
set(CMAKE_CROSSCOMPILING_EMULATOR /usr/local/bin/qemu-aarch64-wrapper)

# pkg-config should look inside the sysroot only.
set(ENV{PKG_CONFIG_SYSROOT_DIR} /sysroot)
set(ENV{PKG_CONFIG_PATH} "/sysroot/usr/lib/aarch64-linux-gnu/pkgconfig:/sysroot/usr/share/pkgconfig")
