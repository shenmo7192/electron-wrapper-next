#!/bin/bash

set -x

SELF=$(readlink -f "$0")
BUILD_DIR=${SELF%/*}
SRC_DIR=$BUILD_DIR
APP_DIR=$BUILD_DIR

## Writeable Envs
NODE_PATH=node
export PATH="$NODE_PATH:$PATH"
export ELECTRON_VERSION="28.3.3"

export PACKAGE="app.bsky.web"
export NAME="Bluesky"
export NAME_CN="Bluesky"
export VERSION="$ELECTRON_VERSION"
export ARCH="all"
export URL="icon.png::https://upload.wikimedia.org/wikipedia/commons/thumb/7/7a/Bluesky_Logo.svg/600px-Bluesky_Logo.svg.png"
export URL_PLAIN="https://upload.wikimedia.org/wikipedia/commons/thumb/7/7a/Bluesky_Logo.svg/600px-Bluesky_Logo.svg.png"
export DO_NOT_UNARCHIVE=1
# autostart,notification,trayicon,clipboard,account,bluetooth,camera,audio_record,installed_apps
export REQUIRED_PERMISSIONS=""

export HOMEPAGE="https://bsky.app/"
# export DEPENDS="libgconf-2-4, libgtk-3-0, libnotify4, libnss3, libxtst6, xdg-utils, libatspi2.0-0, libdrm2, libgbm1, libxcb-dri3-0, kde-cli-tools | kde-runtime | trash-cli | libglib2.0-bin | gvfs-bin, deepin-elf-verify"
export DEPENDS="com.electron"
export BUILD_DEPENDS="npm"
export SECTION="misc"
export PROVIDE=""
export DESC1="Electron wrapper for $HOMEPAGE"
export DESC2=""

#export INGREDIENTS=(nodejs)

    wget "${URL_PLAIN}" -O icon.png
    cp "$BUILD_DIR/templates/index.js" "$SRC_DIR/index.js"
    mkdir -p $APP_DIR/files/
    cp "$BUILD_DIR/templates/run.sh" "$APP_DIR/files/run.sh"
    cat "$BUILD_DIR/templates/package.json" | envsubst >"$SRC_DIR/package.json"

    pushd "$SRC_DIR"

#    export ELECTRON_MIRROR=https://registry.npmmirror.com/
    cnpm install 
    cnpm run build
    cp -RT out/linux-unpacked/resources $APP_DIR/files/resources
    mkdir -p "$APP_DIR/files/userscripts"
    cp "$BUILD_DIR"/*.js "$APP_DIR/files/userscripts/"

    popd

    rm -rf $APP_DIR/entries/icons/hicolor/**/apps/icon.png

    mkdir -p "$APP_DIR/entries/applications"
    cat <<EOF >$APP_DIR/entries/applications/$PACKAGE.desktop
[Desktop Entry]
Name=$NAME
Name[zh_CN]=$NAME_CN
Exec=env PACKAGE=$PACKAGE /opt/apps/$PACKAGE/files/run.sh %U
Terminal=false
Type=Application
Icon=$PACKAGE
StartupWMClass=$PACKAGE
Categories=Chat;
EOF




rm -vfr $APP_DIR/DEB
    mkdir -p $APP_DIR/DEB/DEBIAN
    mkdir -p $APP_DIR/DEB/opt/apps/$PACKAGE/
    cp -vr $APP_DIR/entries $APP_DIR/DEB/opt/apps/$PACKAGE/
    cp -vr $APP_DIR/files $APP_DIR/DEB/opt/apps/$PACKAGE/
    mkdir -p $APP_DIR/DEB/opt/apps/$PACKAGE/entries/icons/
    cp -v $APP_DIR/icon.png $APP_DIR/DEB/opt/apps/$PACKAGE/entries/icons/$PACKAGE.png
    cat <<EOF >$APP_DIR/DEB/DEBIAN/control
Package: $PACKAGE
Version: $VERSION
Priority: optional
Section: misc
Architecture: all
Maintainer: shenmo <shenmo@spark-app.store>
Installed-Size: 143 kB
Depends: com.electron, deepin-elf-verify (>= 1.1.10-1)
Homepage: $HOMEPAGE
Description: Electron wrapper for $HOMEPAGE

EOF
    cat <<EOF >$APP_DIR/DEB/opt/apps/$PACKAGE/info
{
  "appid": "$PACKAGE",
  "name": "$PACKAGE",
  "version": "$VERSION",
  "arch": ["amd64","arm64","mips64el","sw_64"],
  "permissions": {
    "autostart": false,
    "notification": false,
    "trayicon": false,
    "clipboard": false,
    "account": false,
    "bluetooth": false,
    "camera": false,
    "audio_record": false,
    "installed_apps": false
  }
}


EOF
    pushd $APP_DIR/DEB/
    dpkg-deb -Z xz -b . ..
    popd