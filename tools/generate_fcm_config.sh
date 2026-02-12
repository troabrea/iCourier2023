cd ~/Projects/Flutter/iCourier

flutterfire configure --project=icourier2023 \
  --platforms=android,ios \
  --android-package-name=com.barolit.taino \
  --ios-bundle-id=com.barolit.taino

mv lib/firebase_options.dart lib/apps/taino/firebase_options_taino.dart
cp ios/Runner/GoogleService-Info.plist ios/fbconfig/taino/GoogleService-Info.plist
mv android/app/google-services.json android/app/src/taino/google-services.json


#flutterfire configure --project=icourierapps-group3 \
# --platforms=android,ios \
# --android-package-name=com.barolit.cargowise \
# --ios-bundle-id=com.barolit.cargowise


