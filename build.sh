#! /bin/bash
# Copyright (C) 2020 Starlight5234
# Copyright (C) 2020 Team StormBreaker
#

# For telegram posts
export CHANNEL_ID="$CHAT_ID"

# For telegram posts
export TELEGRAM_TOKEN="$BOT_API_KEY"

# To use GCC for compilation STORM_COMPILE_GCC="yes"
export STORM_COMPILE_GCC=""

# Only works if STORM_COMPILE_GCC not defined as "yes"
# Default is Team StormBreaker Clang 11
# setting this variable to "12" will clone latest clang 12 by @Kdrag0n
export STORM_CLANG_TARGET=""

# Set this to true if your device uses linkers
export STORM_COMPILE_LINKERS=""

# Your device (is used as branch name for cloning anykernel, stormbreaker org)
export DEVICE=""

# Your compilation config
export CONFIG=$DEVICE-perf_defconfig

# Your kernel dir, leave empty if build script is within kernel source
export STORM_TARGET_DIR="" 

# Add your any kernel link in case you don't use this one kthx
export STORM_ZIP_LINK="https://github.com/stormbreaker-project/AnyKernel3"

# Modify according to your branch in custom repo. PS: Bish add to SB repo
export STORM_ZIP_BRANCH=""

# Cleanup your AnyKernel3 directory in 2 style
# Default is git clean
# Second is using rm -rf ( only used for server with unlimited internet access )
export STORM_GIT_CLEAN_ZIP_DIR="yes"

# Experimental but a useful CI feature
# If using a CI where your build script is in a different repo 
# (made for spamming builds) and the actual source is in a 
# different repo uncomment and change to CLONE_KERNEL_TARGET_CI="yes"
# Prerequisites ( For being able to clone private repos )
# - Github API Personal Access Token ( add it to environment variable )
# - Setup your repo link
# export CLONE_KERNEL_TARGET_CI="no"
# export USER_PERSONAL_ACCESS_TOKEN="$GITHUB_TOKEN"
# export CLONE_KERNEL_CI_REPO=""
# export CLONE_KERNEL_CI_BRANCH=""

export KBUILD_BUILD_USER="StormbreakerCI-Bot"
export KBUILD_BUILD_HOST="Stormbreaker-HQ"
export JOBS=$(nproc --all)
export STORM_COMPILER_PATH="$HOME/toolchains"
export STORM_ZIP_DIR="$HOME/anykernel"

# To-do: Add code to move wlan driver modules
# Some stock ROMs/devices need this module

# 	!!!WARNING!!!
# DO NOT TOUCH BEYOND THIS
# 	!!!WARNING!!!

#======================== Inputs ===============================

export STORM_COMPILE_GCC="yes"

while [ "$1" != "" ]; do
    case $1 in
        -d | --device )         export DEVICE=$2 && export CONFIG=$DEVICE-perf_defconfig
                                ;;
        -c | --config )         export CONFIG=$2_defconfig
				;;
	-C | --storm-compile-clang )         
				export STORM_COMPILE_GCC="no" && export STORM_CLANG_TARGET=$2
				;;
	-l | --use-linkers )         
				export STORM_COMPILE_LINKERS="yes"
				;;
    esac
    shift
done

#=========================  Checks ============================

export red='\033[0;31m'
export yellow='\033[0;33m'
export white='\033[0m'
export green='\e[0;32m'

if [ -z "$DEVICE" ] ; then
	echo -e "$red>>Mention your device codename $white"
	exit 1
fi

if [ "$CLONE_KERNEL_TARGET_CI" == "yes" ] && [ -z "$CLONE_KERNEL_CI_REPO" ] ; then
	echo -e "$red>>Mention your device repo link $white"
	exit 1
fi

if [ -z "$STORM_ZIP_BRANCH" ] ; then
	export STORM_ZIP_BRANCH=${DEVICE}
fi

if [ -z "$STORM_TARGET_DIR" ] ; then
	echo -e "$yellow>>Assuming your current directory as working dir $white"
	export KERN_DIR=$(pwd)
else
	export KERN_DIR=$STORM_TARGET_DIR
fi

[ -d "$STORM_COMPILER_PATH" ] || mkdir -p $STORM_COMPILER_PATH

if [ -z "$STORM_CLANG_TARGET" ]; then
	export STORM_CLANG_TARGET="11"
fi

export TARGET_STORM_ZIP_BRANCH="-b $STORM_ZIP_BRANCH"

#======================== Clone stuff ==========================

if [ "$STORM_COMPILE_GCC" == "yes" ]; then

	if [ ! -d ${STORM_COMPILER_PATH}/gcc64 ] || [ ! -d ${STORM_COMPILER_PATH}/gcc32 ]; then
		rm -rf ${STORM_COMPILER_PATH}/gcc64 ${STORM_COMPILER_PATH}/gcc32
		git clone --depth=1 https://github.com/arter97/arm64-gcc ${STORM_COMPILER_PATH}/gcc64
		git clone --depth=1 https://github.com/arter97/arm32-gcc ${STORM_COMPILER_PATH}/gcc32
	fi
	
	export PATH="${STORM_COMPILER_PATH}/gcc64/bin:${STORM_COMPILER_PATH}/gcc32/bin:$PATH"
	export STRIP="${STORM_COMPILER_PATH}/gcc64/aarch64-elf/bin/strip"
	export STORM_COMPILER_NAME="Arter97's Latest GCC Compiler"

else
	if [ "$STORM_CLANG_TARGET" == "12" ]; then
		[ -d ${STORM_COMPILER_PATH}/clang12 ] || git clone --depth=1 https://github.com/kdrag0n/proton-clang.git ${STORM_COMPILER_PATH}/clang12
		
		export PATH="${STORM_COMPILER_PATH}/clang12/bin:$PATH"
		export STRIP="${STORM_COMPILER_PATH}/clang12/aarch64-linux-gnu/bin/strip"
		export STORM_COMPILER_NAME="Kdrag0n's Latest Proton Clang"
	else
		[ -d ${STORM_COMPILER_PATH}/clang11 ] || git clone --depth=1 https://github.com/starlight5234/clang_11.git ${STORM_COMPILER_PATH}/clang11
		
		export PATH="${STORM_COMPILER_PATH}/clang11/bin:$PATH"
		export STRIP="${STORM_COMPILER_PATH}/clang11/aarch64-linux-gnu/bin/strip"
		export STORM_COMPILER_NAME="StormBreaker Clang 11"
	fi
fi

clone_zipper(){

	if [ "$STORM_GIT_CLEAN_ZIP_DIR" == "no" ]; then
		rm -rf $STORM_ZIP_DIR && git clone $STORM_ZIP_LINK $TARGET_STORM_ZIP_BRANCH $STORM_ZIP_DIR
	else
		[ -d "$STORM_ZIP_DIR" ] || git clone $STORM_ZIP_LINK $TARGET_STORM_ZIP_BRANCH $STORM_ZIP_DIR
		cd $STORM_ZIP_DIR && git clean -fd
	fi

}

setup_linkers(){
	if [ "$STORM_COMPILE_GCC" == "yes" ]; then
		export LD_LIBRARY_PATH="${STORM_COMPILER_PATH}/gcc64/lib:$PATH"
	elif [ "$STORM_CLANG_TARGET" == "12" ]; then
		export LD_LIBRARY_PATH="${STORM_COMPILER_PATH}/clang-12/lib:$PATH" 
	else 
		export LD_LIBRARY_PATH="${STORM_COMPILER_PATH}/clang-11/lib:$PATH"
	fi
}

clone_kernel_ci_repo(){
	git clone $CLONE_KERNEL_CI_REPO $TARGET_CLONE_KERNEL_CI_BRANCH $STORM_TARGET_DIR
}

if [ "$STORM_COMPILE_LINKERS" == "yes" ]; then
	setup_linkers
fi

if [ "$CLONE_KERNEL_TARGET_CI" == "yes" ]; then
	
	if [ ! -z "$CLONE_KERNEL_CI_BRANCH" ];then
		export TARGET_CLONE_KERNEL_CI_BRANCH="-b $CLONE_KERNEL_CI_BRANCH"
	else
		echo -e "%$yellow>>Branch was not defined using default branch $white"
	fi
	clone_kernel_ci_repo

fi

#==============================================================
#=========================== Make =============================
#========================== Kernel ============================
#==============================================================

build_kernel() {
DATE=`date`
BUILD_START=$(date +"%s")
make O=out ARCH=arm64 "$CONFIG"

if [ "$STORM_COMPILE_GCC" == "yes" ]; then
	make -j$(nproc --all) O=out \
			      ARCH=arm64 \
			      CROSS_COMPILE=aarch64-elf- \
			      CROSS_COMPILE_ARM32=arm-eabi- |& tee -a $LOG
else
	make -j$(nproc --all) O=out \
			      ARCH=arm64 \
			      CC=clang \
			      CROSS_COMPILE=aarch64-linux-gnu- \
			      CROSS_COMPILE_ARM32=arm-linux-gnueabi- |& tee -a $LOG
fi

BUILD_END=$(date +"%s")
DIFF=$(($BUILD_END - $BUILD_START))
}

#==================== Make Flashable Zip ======================

function make_flashable() {

cd $STORM_ZIP_DIR
git clean -fd &> /dev/null
cp $KERN_IMG $STORM_ZIP_DIR/zImage
NAME="StormBreaker-Kernel"
DATE=$(date "+%d%m%Y-%I%M")
STORM_ZIP_NAME=${NAME}-${KERN_VER}-${DEVICE}-${DATE}.zip
EXCLUDE="Storm* *placeholder* .git"
zip -r9 "$STORM_ZIP_NAME" . -x $EXCLUDE &> /dev/null
ZIP=$STORM_ZIP_NAME
send_zip

}

#========================= Build Log ==========================

rm -rf $HOME/.tmp && mkdir $HOME/.tmp
export LOG=$HOME/.tmp/log.txt

#======================= Telegram Start =======================

# Upload buildlog to group
send_log()
{
	curl -F document=@"$LOG"  "https://api.telegram.org/bot$TELEGRAM_TOKEN/sendDocument" \
			-F chat_id=$CHANNEL_ID \
			-F caption="Build ran into errors after $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) seconds, plox check logs"
}

# Upload zip to channel
send_zip() 
{
	curl -F document=@"$ZIP"  "https://api.telegram.org/bot$TELEGRAM_TOKEN/sendDocument" \
			-F chat_id=$CHANNEL_ID \
			-F caption="Build Finished after $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) seconds"
}

# Send Updates
function send_info() {
	curl -s "https://api.telegram.org/bot$TELEGRAM_TOKEN/sendMessage" \
		-d "parse_mode=html" \
		-d text="${1}" \
		-d chat_id="${CHANNEL_ID}" \
		-d "disable_web_page_preview=true"
}

# Send a sticker
function sticker_welcome() {
    curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_TOKEN/sendSticker" \
        -d sticker="CAACAgUAAxkBAAIEy19DxNr5C-iHBs3Ggp5H_pX3KOwdAAIgAQACLPkBVtu34-6AeoBIGwQ" \
        -d chat_id=$CHANNEL_ID
}

#======================= Telegram End =========================

clone_zipper

COMMIT=$(git log --pretty=format:'"%h : %s"' -1)
BRANCH="$(git rev-parse --abbrev-ref HEAD)"
cd $KERN_DIR
KERN_IMG=$KERN_DIR/out/arch/arm64/boot/Image.gz-dtb
rm -rf $KERN_IMG
export KERN_VER=$(echo "$(make kernelversion)")

sticker_welcome
send_info "$(echo -e "======= <b>$DEVICE</b> =======\n
Build-Host         :- <b>$KBUILD_BUILD_HOST</b>
Build-User         :- <b>$KBUILD_BUILD_USER</b>
Build-System    :- <b>$(uname -n)</b>
With jobs           :- <b>$JOBS</b>
Build number   :- <b>$BUILD</b>\n
Version         :- <u><b>$KERN_VER</b></u>
Compiler      :- <i>$STORM_COMPILER_NAME</i>\n
on Branch   :- <b>$BRANCH</b>
Commit       :- <b>$COMMIT</b>\n")"

build_kernel

# Check if kernel img is there or not and make flashable accordingly

if ! [ -a "$KERN_IMG" ]; then
	send_log
	echo -e "$red>> Compilation failed after $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) seconds, plox check logs $white"
	exit 1
else
	make_flashable
	echo -e "$green>> Build Finished after $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) seconds $white"
fi
