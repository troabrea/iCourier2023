cd ~/Projects/Flutter/iCourier

flutterfire configure --project=icourierapps-group2 \
  --platforms=android,ios \
  --android-package-name=com.barolit.tupaq \
  --ios-bundle-id=com.barolit.tupaq

mv lib/firebase_options.dart lib/apps/tupaq/firebase_options_tupaq.dart
cp ios/Runner/GoogleService-Info.plist ios/fbconfig/tupaq/GoogleService-Info.plist
mv android/app/google-services.json android/app/src/tupaq/google-services.json


#flutterfire configure --project=icourierapps-group3 \
# --platforms=android,ios \
# --android-package-name=com.barolit.cargowise \
# --ios-bundle-id=com.barolit.cargowise


