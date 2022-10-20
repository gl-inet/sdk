# !/usr/bin/env bash
# set -e

work_dir="$PWD"
sdk_dir="sdk"
targets="ar71xx-1806 ath79-1907 ramips-1806 ramips-1907 ipq806x-qsdk53 ipq_ipq40xx-qsdk11 ipq_ipq60xx-qsdk11 mvebu-1907 siflower-1806 ipq807x-2102"

gl_inet_imagebuilder_url="https://github.com/gl-inet-builder"

usage() {
	cat <<-EOF
Usage: 
./download.sh [target]   # Download the appropriate SDK

All available target list:
    ar71xx-1806         # usb150/ar150/ar300m16/mifi/ar750/ar750s/x750/x1200
    ath79-1907          # usb150/ar150/ar300m/mifi/ar750/ar750s/x750/x300b/xe300/e750/x1200 openwrt-19.07.7 ath79 target
    ramips-1806         # mt300n-v2/mt300a/mt300n/n300/vixmini
    ramips-1907         # mt1300/mt300n-v2/mt300a/mt300n/n300/vixmini
    ipq806x-qsdk53      # b1300/s1300/ap1300/b2200
    ipq_ipq40xx-qsdk11  # b1300/s1300/ap1300/b2200 (version 3.201 and above)
    ipq_ipq60xx-qsdk11  # ax1800
    mvebu-1907          # mv1000
    siflower-1806       # sf1200/sft1200
    ipq807x-2102       # ax1800/axt1800 (version 4.x and above)

EOF
	exit 0
}

[ -z "$1" ] && usage

sdk_name=$1

download_sdk() {
    for i in $targets; do
        [ "$i" != "$sdk_name" ] && continue

        echo "Download $i SDK"
        version="${sdk_name#*-}"
        target="${sdk_name%-*}"

        # Download/Update OpenWrt SDK
        if [ ! -d "$sdk_dir/$version/$target" ]; then
            git clone $gl_inet_imagebuilder_url/openwrt-sdk-$sdk_name.git $sdk_dir/$version/$target
            [ "$target" != "ipq806x" ] && {
               pushd $sdk_dir/$version/$target > /dev/null
               ./scripts/feeds update
               ./scripts/feeds install uci curl libubus libubox libiwinfo libsqlite3 mqtt fcgi #install default depends packages
               make defconfig
               popd > /dev/null
               printf "\nUse 'builder.sh script to compile all your packages.\nRun './builder.sh' to get more help.\n\n"
            }
        else
            pushd $sdk_dir/$version/$target > /dev/null
            git pull
            popd > /dev/null
        fi
        exit 0
    done
}
download_sdk
printf "\nError: Can't found '$sdk_name' target. Please check available target list again!\n\n" && usage
