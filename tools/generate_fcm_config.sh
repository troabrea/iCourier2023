cd ~/Projects/Flutter/iCourier

flutterfire configure --project=icourierapps-group2 \
  --platforms=android,ios \
  --android-package-name=com.barolit.gopack \
  --ios-bundle-id=com.barolit.gopack

mv lib/firebase_options.dart lib/apps/gopack/firebase_options_gopack.dart
cp ios/Runner/GoogleService-Info.plist ios/fbconfig/gopack/GoogleService-Info.plist
mv android/app/google-services.json android/app/src/gopack/google-services.json


#flutterfire configure --project=icourierapps-group3 \
# --platforms=android,ios \
# --android-package-name=com.barolit.cargowise \
# --ios-bundle-id=com.barolit.cargowise


