#!/bin/bash

flutter build ios

pushd build/ios/iphoneos
rm -rf Payload
mkdir -p Payload
mv Runner.app Payload/
zip -ry alwaysDRINK.ipa Payload
popd
