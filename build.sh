#!/bin/bash

# MIKASA CI | Powered by Drone | 2021 -

curl -X POST "https://api.telegram.org/bot1954371310:AAGP9vHjbOh-14RjLxkcx5wQ_JtO46fL7RU/sendMessage" -d "chat_id=-574138196&text=Start compiling 
$(date)"


export ARCH=arm64
export LLVM=1
export LLVM_IAS=1
export CROSS_COMPILE=aarch64-linux-gnu-
export CROSS_COMPILE_COMPAT=arm-linux-gnueabi-
export PATH="/drone/build-tools/proton-clang/bin:$PATH"
export KBUILD_BUILD_USER=apollo
export KBUILD_BUILD_HOST=MIKASA
export KJOBS="$((`grep -c '^processor' /proc/cpuinfo` * 2))"
VERSION="MIKASA-kernel-$(date '+%Y-%m%d-%H%M')"

echo
echo "Setting defconfig"
echo
if [ -f arch/arm64/configs/vendor/apollo_defconfig ]
then
    make CC=clang LLVM=1 LLVM_IAS=1 vendor/apollo_defconfig
else
    make CC=clang LLVM=1 LLVM_IAS=1 apollo_defconfig
fi

echo
echo "Compiling"
echo 
make CC=clang LLVM=1 LLVM_IAS=1 -j${KJOBS}

if  [ $? -eq 0 ]
then 
    curl -X POST "https://api.telegram.org/bot1954371310:AAGP9vHjbOh-14RjLxkcx5wQ_JtO46fL7RU/sendMessage" -d "chat_id=-574138196&text=Compiled successfully! 
$(date)"
else
    curl -X POST "https://api.telegram.org/bot1954371310:AAGP9vHjbOh-14RjLxkcx5wQ_JtO46fL7RU/sendMessage" -d "chat_id=-574138196&text=Failed to compile !
$(date)"
    exit 1
fi

echo
echo "Building Kernel Package"

echo
mkdir kernelzip
mkdir kernelzip/source
cp -rp ../build-tools/anykernel/* kernelzip/
cp arch/arm64/boot/Image kernelzip/source/
cp arch/arm64/boot/dts/vendor/qcom/kona-v2.1.dtb kernelzip/source/dtb
cd kernelzip
7z a -mx9 $VERSION-tmp.zip *
zipalign -v 4 $VERSION-tmp.zip ../$VERSION.zip
rm $VERSION-tmp.zip
cd ..
ls -al $VERSION.zip && md5sum $VERSION.zip

echo
echo "Uploading"
echo

curl -v -F "chat_id=-574138196" -F document=@${VERSION}.zip https://api.telegram.org/bot1954371310:AAGP9vHjbOh-14RjLxkcx5wQ_JtO46fL7RU/sendDocument

