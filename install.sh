#!/bin/env sh
DF_PATH="$HOME/Games/Dwarf Fortress/df_47_05_linux_with_dfcrack_testing"
DFCRACK_PATH="$DF_PATH/dfcrack"
DFCRACK_LIBPATH="$DFCRACK_PATH/lib"

# mkdirs
mkdir -p "$DFCRACK_PATH"
mkdir -p "$DFCRACK_LIBPATH"

# copy libs over
cp ../Common/dist/linux/debug/libCommon.so "$DFCRACK_LIBPATH"
cp ../LuaCxx/dist/linux/debug/libLuaCxx_LuaJIT.so "$DFCRACK_LIBPATH"
cp dist/linux/debug/libDFCrack.so "$DFCRACK_LIBPATH"

# copy launch script over
cp run-dfcrack.sh "$DF_PATH"

# copy rest of scripts over
rsync -avm --include=* -f 'hide,! */' dfcrack/* "$DFCRACK_PATH"
