package:

## General packages
    xserver:
        name: xorg
        version: '>= 1:7.7'

    # Window managers
    kde:
        name: kde-full
        version: '>= 5:102'

    gnome:
        name: gnome
        version: '>= 1:3.14'

    # Display managers
    gdm:
        name: gdm3
        version: '>= 3.18.3'

    lightdm:
        name: lightdm
        version: '>= 1.26.0'

    # X utilities
    xvfb:
        {% if grains["os_family"] in ["RedHat"] -%}
        name: xorg-x11-server-Xvfb
        {% elif grains["os_family"] in ["Debian"] -%}
        name: xvfb
        {% else -%}
        name: '{{ "ERROR: unsupported os family {}".format(grains["os_family"]) }}'
        {% endif -%}
        version: '>= 1.20.4'

    x11-apps:
        {% if grains["os_family"] in ["RedHat"] -%}
        name: xorg-x11-apps
        {% elif grains["os_family"] in ["Debian"] -%}
        name: x11-apps
        {% else -%}
        name: '{{ "ERROR: unsupported os family {}".format(grains["os_family"]) }}'
        {% endif -%}
        version: '>= 7.5'

    x11-utils:
        {% if grains["os_family"] in ["RedHat"] -%}
        name: xorg-x11-utils
        {% elif grains["os_family"] in ["Debian"] -%}
        name: x11-utils
        {% else -%}
        name: '{{ "ERROR: unsupported os family {}".format(grains["os_family"]) }}'
        {% endif -%}
        version: '>= 7.5'

    # Miscellaneous utilities
    git:
        name: git
        version: '>= 2.7.4'

    x11vnc:
        name: x11vnc
        version: '>= 0.9.10'

    pkgconfig:
        {% if grains["os_family"] in ["RedHat"] -%}
        name: pkgconf-pkg-config
        {% elif grains["os_family"] in ["Debian"] -%}
        name: pkgconf
        {% else -%}
        name: '{{ "ERROR: unsupported os family {}".format(grains["os_family"]) }}'
        {% endif -%}
        version: '>= 1.6.0'

    # Miscellaneous libraries
    libunwind:
        {% if grains["os_family"] in ["RedHat"] -%}
        name: libunwind
        {% elif grains["os_family"] in ["Debian"] -%}
        name: libunwind8
        {% else -%}
        name: '{{ "ERROR: unsupported os family {}".format(grains["os_family"]) }}'
        {% endif -%}
        version: '>= 1.2.0'

    libipt:
        {% if grains["os_family"] in ["RedHat"] -%}
        name: libipt
        {% elif grains["os_family"] in ["Debian"] -%}
        name: libipt2
        {% else -%}
        name: '{{ "ERROR: unsupported os family {}".format(grains["os_family"]) }}'
        {% endif -%}
        version: '>= 2.0'

    libpixman:
        {% if grains["os_family"] in ["RedHat"] -%}
        name: pixman
        {% elif grains["os_family"] in ["Debian"] -%}
        name: libpixman-1-0
        {% else -%}
        name: '{{ "ERROR: unsupported os family {}".format(grains["os_family"]) }}'
        {% endif -%}
        version: '>= 0.34.0'

## Development libraries
    binutils.devel:
        {% if grains["os_family"] in ["RedHat"] -%}
        name: binutils-devel
        {% elif grains["os_family"] in ["Debian"] -%}
        name: binutils-dev
        {% else -%}
        name: '{{ "ERROR: unsupported os family {}".format(grains["os_family"]) }}'
        {% endif -%}
        version: '>= 2.26.1'

    libunwind.devel:
        {% if grains["os_family"] in ["RedHat"] -%}
        name: libunwind-devel
        {% elif grains["os_family"] in ["Debian"] -%}
        name: libunwind-dev
        {% else -%}
        name: '{{ "ERROR: unsupported os family {}".format(grains["os_family"]) }}'
        {% endif -%}
        version: '>= 1.2.0'

    libipt.devel:
        {% if grains["os_family"] in ["RedHat"] -%}
        name: libipt-devel
        {% elif grains["os_family"] in ["Debian"] -%}
        name: libipt-dev
        {% else -%}
        name: '{{ "ERROR: unsupported os family {}".format(grains["os_family"]) }}'
        {% endif -%}
        version: '>= 2.0'

    glib2.devel:
        {% if grains["os_family"] in ["RedHat"] -%}
        name: glib2-devel
        {% elif grains["os_family"] in ["Debian"] -%}
        name: libglib2.0-dev
        {% else -%}
        name: '{{ "ERROR: unsupported os family {}".format(grains["os_family"]) }}'
        {% endif -%}
        version: '>= 2.48'

    libpixman.devel:
        {% if grains["os_family"] in ["RedHat"] -%}
        name: pixman-devel
        {% elif grains["os_family"] in ["Debian"] -%}
        name: libpixman-1-dev
        {% else -%}
        name: '{{ "ERROR: unsupported os family {}".format(grains["os_family"]) }}'
        {% endif -%}
        version: '>= 0.34.0'

## Debugging packages
    binutils:
        name: binutils
        version: '>= 2.26.1'

    lld:
        {% if grains["os"] in ["Ubuntu"] -%}
        name: lld-6.0
        {% else -%}
        name: lld
        {% endif -%}
        version: '>= 6.0'

    # GNU Compilers and Debuggers
    gcc:
        name: gcc
        version: '>= 8.3.0'

    gdb:
        name: gdb
        version: '>= 7.11.1'

    gdbserver:
        name: gdbserver
        version: '>= 7.11.1'

    # LLVM Compilers and Debuggers
    llvm:
        name: llvm
        version: '>= 7.0'

    clang:
        name: clang
        version: '>= 7.0'

    lldb:
        name: lldb
        version: '>= 7.0'

    # Miscellaneous Debugging tools
    strace:
        name: strace
        version: '>= 4.11'

    ltrace:
        name: ltrace
        version: '>= 0.7.3'

    valgrind:
        name: valgrind
        version: '>= 3.15.0'

    libtool:
        name: libtool
        version: '>= 2.4.6'

    automake:
        name: automake
        version: '>= 1.15'

    autoconf:
        name: autoconf
        version: '>= 2.69'

    bison:
        name: bison
        version: '>= 3.0.4'

    flex:
        name: flex
        version: '>= 2.6.0'

    # Python packages
    python-clang:
        name: python-clang
        version: '>= 7.0'

    python-lldb:
        name: python-lldb
        version: '>= 7.0'

## Symbol packages
    libc.symbols:
        {% if grains["os_family"] in ["RedHat"] -%}
        name: glibc-debuginfo
        {% elif grains["os_family"] in ["Debian"] -%}
        name: libc6-dbg
        {% else -%}
        name: '{{ "ERROR: unsupported os family {}".format(grains["os_family"]) }}'
        {% endif -%}
        version: '>= 2.23'

    libc++.symbols:
        {% if grains["os_family"] in ["RedHat"] -%}
        name: libstdc++-debuginfo
        {% elif grains["os"] in ["Ubuntu"] and grains["osmajorrelease"] == 16 -%}
        name: libstdc++6-5-dbg
        {% elif grains["os_family"] in ["Debian"] -%}
        name: libstdc++6-8-dbg
        {% else -%}
        name: '{{ "ERROR: unsupported os family {}".format(grains["os_family"]) }}'
        {% endif -%}
        version: '>= 5.4.0'
