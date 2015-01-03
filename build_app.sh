#!/bin/sh

# Copyright (C) 2015 Josh A. Beam
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
#   1. Redistributions of source code must retain the above copyright
#      notice, this list of conditions and the following disclaimer.
#   2. Redistributions in binary form must reproduce the above copyright
#      notice, this list of conditions and the following disclaimer in the
#      documentation and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE AUTHOR AS IS'' AND ANY EXPRESS OR
# IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
# OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
# IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
# PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
# OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
# WHETHER IN CONTACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
# OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
# ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

# remove the existing .app if necessary
if [ -d "CocoaOpenGL.app" ]; then
    rm -r CocoaOpenGL.app
fi

CONTENTS="CocoaOpenGL.app/Contents"
RESOURCES="$CONTENTS/Resources"
EN_LPROJ="$RESOURCES/en.lproj"

# create the required directories
mkdir -p $CONTENTS/MacOS
mkdir -p $EN_LPROJ

# create PkgInfo and Info.plist
/bin/echo -n "APPL????" > $CONTENTS/PkgInfo
cat << EOF > $CONTENTS/Info.plist
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleDevelopmentRegion</key>
	<string>en</string>
	<key>CFBundleExecutable</key>
	<string>CocoaOpenGL</string>
	<key>CFBundleIdentifier</key>
	<string>Josh-Beam.CocoaOpenGL</string>
	<key>CFBundleInfoDictionaryVersion</key>
	<string>6.0</string>
	<key>CFBundleName</key>
	<string>CocoaOpenGL</string>
	<key>CFBundlePackageType</key>
	<string>APPL</string>
	<key>CFBundleShortVersionString</key>
	<string>1.0</string>
	<key>CFBundleSignature</key>
	<string>????</string>
	<key>CFBundleVersion</key>
	<string>1</string>
	<key>LSMinimumSystemVersion</key>
	<string>10.7</string>
	<key>NSHumanReadableCopyright</key>
	<string>Copyright © 2011-2015 Josh A. Beam. All rights reserved.</string>
	<key>NSMainNibFile</key>
	<string>MainMenu</string>
	<key>NSPrincipalClass</key>
	<string>NSApplication</string>
</dict>
</plist>
EOF

# copy/generate en.lproj files
cp CocoaOpenGL/en.lproj/Credits.rtf $EN_LPROJ/
cp CocoaOpenGL/en.lproj/InfoPlist.strings $EN_LPROJ/
ibtool --compile $EN_LPROJ/MainMenu.nib CocoaOpenGL/en.lproj/MainMenu.xib

# copy the shaders and normalmap
cp CocoaOpenGL/shader.[fv]p $RESOURCES/
cp CocoaOpenGL/normalmap.png $RESOURCES/

# compile the executable
cd CocoaOpenGL && clang -ObjC -o ../$CONTENTS/MacOS/CocoaOpenGL -framework Cocoa -framework OpenGL -include CocoaOpenGL-Prefix.pch -Wno-objc-missing-super-calls *.[mc]
