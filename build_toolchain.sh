#!/bin/bash
source vars.sh
#-------------------------------------------------------------------
src_clone ()
{
  echo '***** execute src_clone script *****'
	[ -d $src_folder ] && rm -rf $src_folder
	mkdir $src_folder

	cd $src_folder
  echo '--- clone binutil-2.30 source ---'
	git clone https://github.com/andestech/binutils.git \
					-b nds32-binutils-2.30-branch-open binutils-2.30
  echo '--- clone gcc (8.1.0) source ---'
	git clone https://github.com/andestech/gcc.git \
					-b nds32-8.1.0-upstream gcc-8.1.0

  echo '--- clone newlib source ---'
  git clone https://github.com/bminor/newlib.git
  
  #Generate host-tool
	cd gcc-8.1.0
	sh ./contrib/download_prerequisites

	cd $work_folder
  echo '***** src_clone finished ***** '
}
#-------------------------------------------------------------------
clean_build ()
{
  echo '***** execute clean_build script *****i*'  
  [ -d $toolchain_folder ] && rm -rf $toolchain_folder
	mkdir -p $toolchain_folder/nds32le-elf/sysroot/usr/include
	
	[ -d $build_folder ] && rm -rf $build_folder
	mkdir $build_folder
  echo '***** clean_build finished *****'
}
#-------------------------------------------------------------------
build_binutils()
{
  echo '=============== START build_binutils ================'
  if [ ! -d "$src_folder"/binutils-2.30 ];then
          echo "no binutils source code" 
          exit 1
  fi
  mkdir -p "$build_folder"/binutils

  cd "$build_folder"/binutils

  "$src_folder"/binutils-2.30/configure \
  --prefix=$toolchain_folder \
  --target=nds32le-elf \
  --with-arch=v3 \
  --disable-werror \
  --disable-nls \
  --with-sysroot=$toolchain_folder/nds32le-elf/sysroot

  make -j8
  make install

  cd $work_folder
  echo '===================== END build_binutils ================'
}
#-------------------------------------------------------------------
build_bootstrap_gcc()
{
  echo '=============== START build_bootstrap_gcc ================'
  if [ ! -d "$src_folder"/gcc-8.1.0 ];then
          echo "no gcc source code"
    exit 1
  fi
  mkdir -p "$build_folder"/gcc_1

  cd "$build_folder"/gcc_1

  "$src_folder"/gcc-8.1.0/configure \
  --target=nds32le-elf \
  --prefix=$toolchain_folder \
  --with-pkgversion="$build_day"_nds32le-elf-glibc \
  --disable-nls \
  --enable-languages=c,c++ \
  --with-arch=v3 \
  --with-cpu=n9 \
  --enable-default-relax=no \
  --enable-Os-default-ifc=no \
  --enable-Os-default-ex9=no \
  --with-newlib \
  --with-nds32-lib=newlib \
  --disable-libsanitizer \
  --disable-werror \
  --disable-multilib \
  --enable-shared \
  --enable-tls \
  CFLAGS="-O2 -g" \
  CXXFLAGS="-O2 -g" \
  --enable-checking=release \
  LDFLAGS=--static \
  CFLAGS_FOR_TARGET="-O2 -g" \
  CXXFLAGS_FOR_TARGET="-O2 -g" \
  LDFLAGS_FOR_TARGET=

  #--with-nds32-lib=newlib \

  CFLAGS="-O0 -g3" CXXFLAGS="-O0 -g3" \
  make -j8 all-gcc

  make install-gcc

  make configure-target-libgcc

  cd nds32le-elf/libgcc	
  make unwind.h
  make install-unwind_h

  cd $work_folder
  echo '=============== END build_bootstrap_gcc ================'
}
#-------------------------------------------------------------------
build_newlib()
{
  echo '=============== START build_newlib ================'

  mkdir -p "$build_folder"/newlib

  cd "$build_folder"/newlib

  "$src_folder"/newlib/configure \
    --target=nds32le-elf \
    --prefix=$toolchain_folder \
    --with-arch=v3 \
    --with-cpu=n9

  PATH=$toolchain_folder/bin:$PATH \
  make

  PATH=$toolchain_folder/bin:$PATH \
  make install

  cd $work_folder
  echo '=============== END build_newlib ================'
}
#-------------------------------------------------------------------
build_final_gcc()
{
	echo '=============== START build_final_gcc =================='
	if [ ! -d "$src_folder"/gcc-8.1.0 ];then
	       	echo "no gcc source code"
		exit 1
	fi
	mkdir -p "$build_folder"/final_gcc
	cd "$build_folder"/final_gcc

	PATH=$toolchain_folder/bin:$PATH \
	"$src_folder"/gcc-8.1.0/configure \
	--target=nds32le-elf \
	--prefix="$toolchain_folder" \
	--with-pkgversion="$build_day"_nds32le-elf-glibc-v3-4.x \
	--disable-nls \
	--enable-languages=c,c++ \
	--with-arch=v3 \
	--with-cpu=n9 \
	--enable-default-relax=no \
	--with-newlib \
	--with-nds32-lib=newlib \
	--disable-libsanitizer \
	--disable-multilib \
	--enable-shared \
	--enable-tls \
	--disable-libssp \
	--with-sysroot="$toolchain_folder"/nds32le-elf/sysroot \
	CFLAGS="-O2 -g" \
	CXXFLAGS="-O2 -g" \
	--enable-checking=release \
	LDFLAGS=--static \
	CFLAGS_FOR_TARGET="-O2 -g" \
	CXXFLAGS_FOR_TARGET="-O2 -g" \
	LDFLAGS_FOR_TARGET=

#--with-nds32-lib=newlib \
	

	PATH=$toolchain_folder/bin:$PATH \
	make -j8

	PATH=$toolchain_folder/bin:$PATH \
	make install


	# Copy all shared library which is created by gcc to sysroot folder
	find "$toolchain_folder"/nds32le-elf/lib -name "*.so*" \
	   | xargs -i cp -ar {} "$toolchain_folder"/nds32le-elf/sysroot/lib
	
	cd $work_folder
  echo '=============== END build_final_gcc =================='
}
#-------------------------------------------------------------------
# The directly execute scripts
case "$1" in
        src_clone)
                src_clone
                ;;
        clean_build)
                clean_build
                ;;
        build_binutils)
                build_binutils
                ;;  
        build_bootstrap_gcc)
                build_bootstrap_gcc
                ;;         
        build_newlib)
                build_newlib
                ;;        
        build_final_gcc)
                build_final_gcc
                ;;                                                       
        *)
                echo -n "Press [ENTER] to continue COMPLETE build script"
                read input
                src_clone
                clean_build
                build_binutils
                build_bootstrap_gcc
                build_newlib
                build_final_gcc
                ;;                               
esac
#-------------------------------------------------------------------
