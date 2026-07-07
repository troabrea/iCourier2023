cd ~/Projects/Flutter/iCourier

flutterfire configure --project=icourierapps-group3 \
  --platforms=android,ios \
  --android-package-name=com.barolit.brodpaq \
  --ios-bundle-id=com.barolit.brodpaq

mv lib/firebase_options.dart lib/apps/brodpaq/firebase_options_brodpaq.dart
cp ios/Runner/GoogleService-Info.plist ios/fbconfig/brodpaq/GoogleService-Info.plist
mv android/app/google-services.json android/app/src/brodpaq/google-services.json


#flutterfire configure --project=icourierapps-group3 \
# --platforms=android,ios \
# --android-package-name=com.barolit.cargowise \
# --ios-bundle-id=com.barolit.cargowise


