# !/usr/bin/env bash

set -e

work_dir="$PWD"
sdk_dir="sdk"
targets="ar71xx-1806 ath79-1907 ramips-1806 ramips-1907 ipq806x-qsdk53 ipq_ipq40xx-qsdk11 ipq_ipq60xx-qsdk11 mvebu-1907 siflower-1806 ipq807x-2102"
dl_dir="/data/dl" 
build_log="build_log.txt"

usage() {
	cat <<-EOF
Usage: 
./builder.sh [option]
command:
    [-a]                # Compile all software packages with all targets.
    [-t] [target]       # Compile packages with single targets.
    [-d] [package_path] # Package path.
    [-v]                # Enable compile log.

All available target list:
    ar71xx-1806         # usb150/ar150/ar300m16/mifi/ar750/ar750s/x750/x1200
    ath79-1907          # usb150/ar150/ar300m/mifi/ar750/ar750s/x750/x300b/xe300/e750/x1200 openwrt-19.07.7 ath79 target
    ramips-1806         # mt300n-v2/mt300a/mt300n/n300/vixmini
    ramips-1907         # mt1300 mt300n-v2/mt300a/mt300n/n300/vixmini
    ipq806x-qsdk53      # b1300/s1300/ap1300/b2200
    ipq_ipq40xx-qsdk11  # b1300/s1300/ap1300/b2200 (version 3.201 and above)
    ipq_ipq60xx-qsdk11  # ax1800
    mvebu-1907          # mv1000
    siflower-1806       # sf1200/sft1200
    ipq807x-2102	# ax1800/axt1800 (version 4.x and above)

EOF
	exit 0
}

check_target_valid() {

    for target in $targets; do
        [ "$target" = "$COMPILE_TARGET" ] && return 1
    done

    return 0
}

check_package_valid() {
    local pkg_name

    [ ! -f "$1/Makefile" ] && return 0

    pkg_name=$(cat $1/Makefile|grep PKG_NAME)
    [ -n "$pkg_name" ] && return 1
    return 0
}

compile_all_target() {

    time=$(date '+%Y-%m-%d %T')

    local packages_dir=$(cd $COMPILE_DIR; pwd; cd ..)
    [ "${packages_dir: -1}" = "/" ] && packages_dir=${packages_dir%/*} # 如果var变量最后一个字符是/，需先去掉

    local packages_name="${packages_dir##*/}"
    local sdk_exist=0
    for target in $targets; do
        version="${target#*-}"
        target="${target%-*}"

        [ -d "$sdk_dir/$version/$target" ] && {
            echo "$time===========>> Compile '$sdk_dir/$version/$target' packages START <<===========" >> $build_log
            [ ! -e "$sdk_dir/$version/$target/package/$packages_name" ] && ln -sf $packages_dir $sdk_dir/$version/$target/package/$packages_name
            pushd $sdk_dir/$version/$target > /dev/null
            make $MAKE_PARAMETER
            popd > /dev/null
            echo "$time===========>> Compile '$sdk_dir/$version/$target' packages END <<===========" >> $build_log
            sdk_exist=1
        }
    done
    [ $sdk_exist = 0 ] && {
        printf "\nError: SDK not found. You need to download SDK first through download.sh script.\n\n"
    }
    exit 0
}

compile_single_target() {

    time=$(date '+%Y-%m-%d %T')

    local packages_dir=$(cd $COMPILE_DIR; pwd; cd ..)
    [ "${packages_dir: -1}" = "/" ] && packages_dir=${packages_dir%/*} # 如果var变量最后一个字符是/，需先去掉

    local packages_name="${packages_dir##*/}"
    local sdk_exist=0

    version="${COMPILE_TARGET#*-}"
    target="${COMPILE_TARGET%-*}"
    [ -d "$sdk_dir/$version/$target" ] && {
        echo "$time===========>> Compile '$sdk_dir/$version/$target' packages START <<===========" >> $build_log
        [ ! -e "$sdk_dir/$version/$target/package/$packages_name" ] && ln -sf $packages_dir $sdk_dir/$version/$target/package/$packages_name
        pushd $sdk_dir/$version/$target > /dev/null
        if [ $(check_package_valid "package/$packages_name"; echo $?) = 1 ]; then
            make package/$packages_name/{clean,compile} $MAKE_PARAMETER
        else
            make $MAKE_PARAMETER
        fi
        popd > /dev/null
        echo "$time===========>> Compile '$sdk_dir/$version/$target' packages END <<===========" >> $build_log
        sdk_exist=1
    }
    [ $sdk_exist = 0 ] && {
        printf "\nError: SDK not found. You need to download SDK first through download.sh script.\n\n"
    }
    exit 0
}

export COMFILE_ALL=0
export COMPILE_TARGET=""
export COMPILE_DIR=""
export COMPILE_VERBOSE=0
export MAKE_PARAMETER=""

while getopts "t:p:d:av" arg; do #字符后边有':'则表示有参数
	case "$arg" in
		a) export COMFILE_ALL=1;;
		t) export COMPILE_TARGET=$OPTARG;;
        d) export COMPILE_DIR=$OPTARG;;
        v) export COMPILE_VERBOSE=1;;
        \?) usage;;
	esac
done

[ $COMPILE_VERBOSE = 1 ] && export MAKE_PARAMETER="V=s"

[ -f "$build_log" ] && rm $build_log
[ -z "$1" ] && usage
[ -z "$COMPILE_DIR" ] && {
    printf "\nError: Please use '-d' parameter to set COMPILE_DIR.\n\n"
    usage
}

[ $COMFILE_ALL = 1 ] && compile_all_target

[ -z "$COMPILE_TARGET" ] && {
    printf "\nError: Please use '-t' parameter to set COMPILE_TARGET.\n\n"
    usage
}

[ $(check_target_valid; echo $?) = 0 ] && {
    printf "\nError: Target doesn't exist. Please select target from available target list.\n\n"
    usage
}

[ $COMFILE_ALL = 0 ] && compile_single_target





