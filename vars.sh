#!/bin/bash
work_folder=`pwd`

src_folder="$work_folder/src_pkg"
build_folder="$work_folder/build" 
toolchain_folder="$work_folder/toolchain/nds32le-elf-glibc-v3"
build_day=`date +%Y-%m-%d`

export PATH="$toolchain_folder"/bin:$PATH
export LD_LIBRARY_PATH=