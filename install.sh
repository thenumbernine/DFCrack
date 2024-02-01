#!/bin/env sh
DFCRACK_LIBPATH="/home/chris/Games/Dwarf Fortress/df_47_05_linux_with_dfcrack_testing/dfcrack/lib/"
cp ../Common/dist/linux/debug/libCommon.so "${DFCRACK_LIBPATH}"
cp ../LuaCxx/dist/linux/debug/libLuaCxx_LuaJIT.so "${DFCRACK_LIBPATH}"
cp dist/linux/debug/libDFCrack.so "${DFCRACK_LIBPATH}"
