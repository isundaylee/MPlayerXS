#!/bin/sh

rm -Rf MPlayerX.app
rm -Rf MPlayerX.zip
rm -Rf ../../releases/MPlayerX.zip

cp -r ../MPlayerX/build/Release/MPlayerX.app ./MPlayerX.app

zip -r MPlayerX.zip MPlayerX.app > /dev/null

ruby GetTime.rb "./MPlayerX.zip"
echo

ruby GetBundleVersion.rb "./MPlayerX.app"
echo

ruby GetFileSize.rb "./MPlayerX.zip"
echo

echo "Sign:"
ruby "../Sparkle.framework/Extras/Signing Tools/sign_update.rb" "./MPlayerX.zip" "../Sparkle.framework/Extras/Signing Tools/dsa_priv.pem"

mv MPlayerX.zip ../../releases/

rm -Rf MPlayerX.app
rm -Rf ../MPlayerX/build/Release/MPlayerX.app