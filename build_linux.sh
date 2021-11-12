#!/bin/bash

compile_nv-codec-headers()
{
    pushd third_party/nv-codec-headers
    make PREFIX="./build" BINDDIR="./build"
    [ $? != 0 ] && echo "compile nv-codec-headers failed!" && exit 1
    make install PREFIX="./build" BINDDIR="./build"
    popd
}

compile_x264()
{
    pushd third_party/x264
    ./configure --enable-static --enable-pic --prefix="build"
    make -j$(nproc)
    [ $? != 0 ] && echo "compile x264 failed!" && exit 1
    make install
    popd
}

compile_x265()
{
    pushd third_party/x265/build/linux

    # 支持10/12 bit编码（额外编译2个10/12bit的静态库）
    mkdir -p 10bit 12bit
    pushd 10bit
    cmake ../../../source -DHIGH_BIT_DEPTH=ON -DEXPORT_C_API=OFF -DENABLE_SHARED=OFF -DENABLE_CLI=OFF
    make -j$(nproc)
    [ $? != 0 ] && echo "compile x265 failed!" && exit 1
    mv libx265.a libx265_main10.a
    popd

    pushd 12bit
    cmake ../../../source -DHIGH_BIT_DEPTH=ON -DEXPORT_C_API=OFF -DENABLE_SHARED=OFF -DENABLE_CLI=OFF -DMAIN12=ON
    make -j$(nproc)
    [ $? != 0 ] && echo "compile x265 failed!" && exit 1
    mv libx265.a libx265_main12.a
    popd

    cmake -G "Unix Makefiles" -DCMAKE_INSTALL_PREFIX="build" -DENABLE_SHARED=OFF \
    -DEXTRA_LIB="x265_main10.a;x265_main12.a;dl" \
    -DEXTRA_LINK_FLAGS="-L./10bit -L./12bit" \
    -DLINKED_10BIT=ON -DLINKED_12BIT=ON ../../source
    make -j$(nproc)
    [ $? != 0 ] && echo "compile x265 failed!" && exit 1

    # 融合8/10/12bit的静态库为一个
    mv libx265.a libx265_main.a
    ar -M <<EOF
CREATE libx265.a
ADDLIB libx265_main.a
ADDLIB ./10bit/libx265_main10.a
ADDLIB ./12bit/libx265_main12.a
SAVE
END
EOF
    make install
    sed '/private/ s/$/ -lpthread/' -i x265.pc
    popd
}

compile_xavs()
{
    pushd third_party/xavs
    ./configure --enable-pic --prefix="build"
    make -j$(nproc)
    [ $? != 0 ] && echo "compile xavs failed!" && exit 1
    make install
    popd
}

compile_xavs2()
{
    pushd third_party/xavs2/build/linux
    ./configure --enable-static --enable-pic --prefix="build"
    make -j$(nproc)
    [ $? != 0 ] && echo "compile xavs2 failed!" && exit 1
    make install
    popd
}

compile_davs2()
{
    pushd third_party/davs2/build/linux
    ./configure --enable-pic --prefix="build"
    make -j$(nproc)
    [ $? != 0 ] && echo "compile davs2 failed!" && exit 1
    make install
    popd
}

# 编译第三方编解码库
compile_nv-codec-headers
compile_x264
compile_x265
compile_xavs
compile_xavs2
compile_davs2

# 定义路径及编译选项变量
NV_PATH="third_party/nv-codec-headers"
X264_PATH="third_party/x264"
X265_PATH="third_party/x265"
XAVS_PATH="third_party/xavs"
XAVS2_PATH="third_party/xavs2"
DAVS2_PATH="third_party/davs2"

EXTRA_CFLAGS="-I/usr/local/cuda/include -I$NV_PATH/include -I$X264_PATH/build/include -I$X265_PATH/build/linux/build/include \
-I$XAVS_PATH/build/include -I$XAVS2_PATH/build/linux/build/include -I$DAVS2_PATH/build/linux/build/include"

EXTRA_LDFLAGS="-L/usr/local/cuda/lib64 -L$X264_PATH/build/lib -L$X265_PATH/build/linux/build/lib -L$XAVS_PATH/build/lib \
-L$XAVS2_PATH/build/linux/build/lib -L$DAVS2_PATH/build/linux/build/lib"

# 依赖本地自定义的nv-codec-headers、libx264、libx265、libxavs、libxavs2、libdavs2进行配置（以静态库方式链接）
PKG_CONFIG_PATH="$NV_PATH:$X264_PATH:$X265_PATH/build/linux/:$XAVS2_PATH/build/linux/:$DAVS2_PATH/build/linux/" \
./configure --prefix="build" --enable-shared --enable-static \
--enable-gpl --enable-libx264 --enable-libx265 --enable-libxavs --enable-libxavs2 --enable-libdavs2 --disable-postproc \
--enable-cuda-nvcc --enable-cuvid --enable-nvenc --enable-nonfree \
--extra-cflags="$EXTRA_CFLAGS" \
--extra-ldflags="$EXTRA_LDFLAGS" \
--pkg-config-flags="--static"

make -j$(nproc)
[ $? != 0 ] && echo "compile FFmpeg failed!" && exit 1
make install

# 打包
pushd build
mkdir -p ffmpeg/lib
cp -r include ./ffmpeg/
cp ./lib/lib*.so ./ffmpeg/lib/

tar zcf ffmpeg-linux-x86_64-`date +%y%m%d`.tar.gz ffmpeg
rm -rf ffmpeg
popd

echo "************************************************************************************************"
echo "[FFmpeg压缩包] build/ffmpeg-linux-x86_64-`date +%y%m%d`.tar.gz "
echo "************************************************************************************************"
