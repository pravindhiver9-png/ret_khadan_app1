# रेत खदान प्रबंधन ऐप

Flutter आधारित Android ऐप का शुरुआती GitHub प्रोजेक्ट।

## अभी शामिल
- Minimal / soft-neomorphic UI
- Dashboard (शुरुआत में सभी आंकड़े शून्य और कोई demo entry नहीं)
- Hyva entry form: तारीख, समय, गाड़ी, टायर, मालिक, ड्राइवर, रेत, royalty, cash/online और बाकी
- Daily expense form
- Labour attendance with Day, Night, Half Day, Half Night, Full Day + Half Night, Day + Night, Half Day + Half Night, Holiday, Absent
- Labour payment / advance entry
- Local phone storage using SharedPreferences
- Basic record list, edit description and delete

## GitHub पर चलाने का तरीका
1. इस ZIP को extract करके GitHub repository में upload करें।
2. GitHub Actions में `Build Android APK` workflow चलाएं।
3. Workflow के Artifacts में `ret-khadan-release-apk` डाउनलोड करें।

## Local build
```bash
flutter pub get
flutter run
flutter build apk --release
```

## महत्वपूर्ण
यह पहला working prototype है। डेटा अभी उसी फोन में लोकल सेव होता है। Multi-user cloud sync, full Excel/PDF export, master labour list, wage-rate history, full record editing, backup/restore और advanced reports अगले चरण में जोड़ने होंगे।
