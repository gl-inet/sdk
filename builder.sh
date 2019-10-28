# !/usr/bin/env bash

# For GL.iNET internal use only.

set -e

work_dir="$PWD"
sdk_dir="sdk"
ipk_dir=""
targets="ar71xx-1806 ramips-1806 ipq806x-qsdk53 mvebu-1907"
dl_dir="/data/dl"
build_log="build_log.txt"

packages_dir=$1
cmd=$2
target=$3

usage() {
	cat <<-EOF
Usage: 
./builder.sh [packages_path] [commnad]
command:
    [-a]            # Compile all software packages with all targets
    [-t] [target]   # Compile all software packages with single targets

All available target list:
    ar71xx-1806     # usb150/ar150/ar300m16/mifi/ar750/ar750s/x1200
    ramips-1806     # mt300n-v2/mt300a/mt300n/n300/vixmini
    ipq806x-qsdk53  # b1300/s1300
    mvebu-1907      # mv1000

EOF
	exit 0
}

compile_all_target() {

    [ -z "$1" ] && usage

    time=$(date '+%Y-%m-%d %T')

    local packages_dir=$(cd $1; pwd; cd ..)
    [ "${packages_dir: -1}" = "/" ] && packages_dir=${packages_dir%/*} # 如果var变量最后一个字符是/，需先去掉

    local packages_name="${packages_dir##*/}"

    for target in $targets; do
        version="${target#*-}"
        target="${target%-*}"

        [ -d "$sdk_dir/$version/$target" ] && {
            echo "$time===========>> Compile '$sdk_dir/$version/$target' packages START <<===========" >> $build_log
            [ ! -e "$sdk_dir/$version/$target/package/$packages_name" ] && ln -sf $packages_dir $sdk_dir/$version/$target/package/$packages_name
            pushd $sdk_dir/$version/$target > /dev/null
            make V=s
            popd > /dev/null
            echo "$time===========>> Compile '$sdk_dir/$version/$target' packages END <<===========" >> $build_log
        }
    done
    exit 0
}

compile_single_target() {

    [ -z "$1" ] && usage

    time=$(date '+%Y-%m-%d %T')

    local packages_dir=$(cd $1; pwd; cd ..)
    [ "${packages_dir: -1}" = "/" ] && packages_dir=${packages_dir%/*} # 如果var变量最后一个字符是/，需先去掉

    local packages_name="${packages_dir##*/}"
    version="${target#*-}"
    target="${target%-*}"
    [ -d "$sdk_dir/$version/$target" ] && {
        echo "$time===========>> Compile '$sdk_dir/$version/$target' packages START <<===========" >> $build_log
        [ ! -e "$sdk_dir/$version/$target/package/$packages_name" ] && ln -sf $packages_dir $sdk_dir/$version/$target/package/$packages_name
        pushd $sdk_dir/$version/$target > /dev/null
        make V=s
        popd > /dev/null
        echo "$time===========>> Compile '$sdk_dir/$version/$target' packages END <<===========" >> $build_log
    }
    exit 0
}

[ -z "$cmd" ] && usage
[ -f "$build_log" ] && rm $build_log
[ ! -d "$packages_dir" ] && echo "error: Can not found '$packages_dir' directory. Please check again." && usage
[ "$cmd" = "-a" ] && compile_all_target $packages_dir
[ "$cmd" = "-t" ] && {
    [ -z "$target" ] && echo "error: Can not found '$target' target. Please check again." && usage
    compile_single_target $packages_dir
}

usage

