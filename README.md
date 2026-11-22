# रेत खदान प्रबंधन (Ret Khadan Management)

Flutter app + GitHub Actions se APK build.

## APK kaise banayein (mobile se bhi ho jata hai)
1. GitHub par nayi repo banao (jaise `ret-khadan`).
2. Is zip ki **saari files** repo me upload karo (folders ke saath: `.github`, `assets`, `lib`, `native`, `pubspec.yaml`).
3. Repo ke **Actions** tab me "Build APK" chalega (ya "Run workflow" dabao). 5-8 minute lagte hain.
4. Run poora hone par neeche **Artifacts → RetKhadan-APK** download karo, zip kholo, `app-release.apk` install karo.

## Folder
- `assets/images/app_bg.jpg` – app background
- `assets/images/pdf_bg.jpg` – PDF background (A4)
- `assets/icon/app_icon.png` – app icon (build me automatically lag jata hai)
- `assets/fonts/` – NotoSansDevanagari Regular + Bold
- `native/MainActivity.kt` – PDF engine (Hindi sahi shape, text **selectable**)
- `lib/` – app code (home, hyva, royalty, expense, ui, store, pdf)

## PDF
A4, pdf_bg background, Hindi font embedded, text asli text hai (select / copy / search hota hai), nayi tarikh = naya page.
