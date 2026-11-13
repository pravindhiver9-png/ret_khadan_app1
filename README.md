# रेत खदान प्रबंधन ऐप

Flutter 3.50.0 के लिए प्रोजेक्ट। UI `material_ui` standalone package पर आधारित है; ऐप का रिकॉर्ड डेटा `shared_preferences` में फोन पर स्थानीय रूप से सेव होता है।

## शामिल फाइलें
- `lib/main.dart` — ऐप UI और मौजूदा रिकॉर्ड/फॉर्म फीचर्स
- `pubspec.yaml` — Flutter और package dependencies
- `test/widget_test.dart` — ऐप शुरू होने का widget test
- `.github/workflows/build.yml` — GitHub Actions से analyze, test और release APK build

## GitHub पर उपयोग
ZIP को extract करके इसके अंदर की सभी फाइलें repository के root में upload करें (अर्थात `pubspec.yaml` सीधे repository root में हो)। फिर `main` branch पर push करें या Actions में **Build Android APK** को manually चलाएं।

Workflow में Android platform files मौजूद न होने पर `flutter create --platforms=android .` चलाया जाता है।

सफल build के बाद Actions run के Artifacts से `ret-khadan-release-apk` डाउनलोड करें।

## Local commands
```bash
flutter pub get
flutter analyze
flutter test
flutter build apk --release
```

## डेटा
रिकॉर्ड SharedPreferences में इसी फोन पर सेव होते हैं। इस build में cloud sync, full Excel/PDF export, backup/restore और multi-device sync शामिल नहीं हैं।
