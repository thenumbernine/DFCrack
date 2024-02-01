#!/bin/sh

DF_DIR=$(dirname "$0")
cd "${DF_DIR}"
export SDL_DISABLE_LOCK_KEYS=1 # Work around for bug in Debian/Ubuntu SDL patch.
#export SDL_VIDEO_CENTERED=1 # Centre the screen.  Messes up resizing.

# these are paths relative to dwarf fortress that should match up with the dfcrack paths in install.sh
LUA_PATH="./dfcrack/?.lua;./lua/?/?.lua;./?.lua"
LUA_CPATH="./dfcrack/lib/?.so;./lib/?.so"

# Disable bundled libstdc++
libcxx_orig="libs/libstdc++.so.6"
libcxx_backup="libs/libstdc++.so.6.backup"
if [ -z "${DFHACK_NO_RENAME_LIBSTDCXX:-}" ] && [ -e "$libcxx_orig" ] && [ ! -e "$libcxx_backup" ]; then
    mv "$libcxx_orig" "$libcxx_backup"
    cat <<EOF
NOTICE: $libcxx_orig has been moved to $libcxx_backup
for better compatibility. If you are using an older distro and this breaks,
run "cp $libcxx_backup $libcxx_orig", or add this to
(removed the rc file cuz) to affect future DFHack installations:

    export DFHACK_NO_RENAME_LIBSTDCXX=1

EOF
fi

if [ ! -t 0 ]; then
    stty() {
        return
    }
fi

# Save current terminal settings
old_tty_settings=$(stty -g)

# Use distro_fixes.sh from LNP if it exists
DISTROFIXES="distro_fixes.sh"
if [ -r "$DISTROFIXES" ]; then
    . "./$DISTROFIXES"
fi

# Now run

export LD_LIBRARY_PATH="./dfcrack/lib:./dfcrack:$LD_LIBRARY_PATH"

LIB="./dfcrack/lib/libDFCrack.so"
LIBSAN=""
if which objdump > /dev/null; then
  LIBSAN="$(objdump -p $LIB | sed -n 's/^.*NEEDED.*\(lib[a-z]san[a-z.0-9]*\).*$/\1/p' | head -n1):"
fi
PRELOAD_LIB="${PRELOAD_LIB:+$PRELOAD_LIB:}${LIBSAN}${LIB} ./dfcrack/lib/libLuaCxx_LuaJIT.so ./dfcrack/lib/libCommon.so"

setarch_arch=$(cat dfcrack/setarch.txt || printf i386)
if ! setarch "$setarch_arch" -R true 2>/dev/null; then
    echo "warn: architecture '$setarch_arch' not supported by setarch" >&2
    if [ "$setarch_arch" = "i386" ]; then
        setarch_arch=linux32
    else
        setarch_arch=linux64
    fi
    echo "using '$setarch_arch' instead. To silence this warning, edit" >&2
    echo "dfcrack/dfcrack_setarch.txt to contain an architecture that works on your system." >&2
fi

case "$1" in
  -g | --gdb)
    shift
    echo "set exec-wrapper env LD_LIBRARY_PATH='$LD_LIBRARY_PATH' LD_PRELOAD='$PRELOAD_LIB' MALLOC_PERTURB_=45" > gdbcmd.tmp
    gdb $DF_GDB_OPTS -x gdbcmd.tmp --args ./libs/Dwarf_Fortress "$@"
    rm gdbcmd.tmp
    ret=$?
    ;;
  -r | --remotegdb)
    shift
    if [ "$#" -gt 0 ]; then
      echo "****"
      echo "gdbserver doesn't support spaces in arguments."
      echo "If your world gen name has spaces you need to remove spaces from the name in data/init/world_gen.txt"
      echo "****"
    fi
    echo "set environment LD_LIBRARY_PATH $LD_LIBRARY_PATH" > gdbcmd.tmp
    echo "set environment LD_PRELOAD $PRELOAD_LIB" >> gdbcmd.tmp
    echo "set environment MALLOC_PERTURB_ 45" >> gdbcmd.tmp
    echo "set startup-with-shell off" >> gdbcmd.tmp
    echo "target extended-remote localhost:12345" >> gdbcmd.tmp
    echo "set remote exec-file ./libs/Dwarf_Fortress" >> gdbcmd.tmp
    # For some reason gdb ignores sysroot setting if it is from same file as
    # target extended-remote command
    echo "set sysroot /" > gdbcmd_sysroot.tmp
    gdb $DF_GDB_OPTS -x gdbcmd.tmp -x gdbcmd_sysroot.tmp --args ./libs/Dwarf_Fortress "$@"
    rm gdbcmd.tmp gdbcmd_sysroot.tmp
    ret=$?
    ;;
  -s | --gdbserver) # -s for server
    shift
    echo "Starting gdbserver in multi mode."
    echo "To exit the gdbserver you can enter 'monitor exit' command to gdb or use kill signal"
    gdbserver --multi localhost:12345
    ret=$?
    ;;
  -h | --helgrind)
    shift
    LD_PRELOAD="$PRELOAD_LIB" setarch "$setarch_arch" -R valgrind $DF_HELGRIND_OPTS --tool=helgrind --log-file=helgrind.log ./libs/Dwarf_Fortress "$@"
    ret=$?
    ;;
  -v | --valgrind)
    shift
    LD_PRELOAD="$PRELOAD_LIB" setarch "$setarch_arch" -R valgrind $DF_VALGRIND_OPTS --log-file=valgrind.log ./libs/Dwarf_Fortress "$@"
    ret=$?
    ;;
  -c | --callgrind)
    shift
    LD_PRELOAD="$PRELOAD_LIB" setarch "$setarch_arch" -R valgrind $DF_CALLGRIND_OPTS --tool=callgrind --separate-threads=yes --dump-instr=yes --instr-atstart=no --log-file=callgrind.log ./libs/Dwarf_Fortress "$@"
    ret=$?
    ;;
  --strace)
    shift
    strace -f setarch "$setarch_arch" -R env LD_PRELOAD="$PRELOAD_LIB" ./libs/Dwarf_Fortress "$@" 2> strace.log
    ret=$?
    ;;
  -x | --exec)
    exec setarch "$setarch_arch" -R env LD_PRELOAD="$PRELOAD_LIB" ./libs/Dwarf_Fortress "$@"
    # script does not resume
    ;;
  --sc | --sizecheck)
    #PRELOAD_LIB="${PRELOAD_LIB:+$PRELOAD_LIB:}./dfcrack/libsizecheck.so"
    MALLOC_PERTURB_=45 setarch "$setarch_arch" -R env LD_PRELOAD="$PRELOAD_LIB" ./libs/Dwarf_Fortress "$@"
    ret=$?
    ;;
  *)
    setarch "$setarch_arch" -R env LD_PRELOAD="$PRELOAD_LIB" ./libs/Dwarf_Fortress "$@"
    ret=$?
    ;;
esac

# Restore previous terminal settings
stty "$old_tty_settings"
tput sgr0
echo

if [ -n "$DF_POST_CMD" ]; then
    eval $DF_POST_CMD
fi

exit $ret
