1. สร้าง GitHub repo ชื่อ HydroApp แล้วแก้ไฟล์ update_service.dart บรรทัดนี้:
const _kOwner = 'YOUR_GITHUB_USERNAME';  // ← ใส่ username GitHub

2. Build APK
flutter build apk --release
ไฟล์อยู่ที่ build/app/outputs/flutter-apk/app-release.apk

3. ทุกครั้งที่ออก version ใหม่ ไป GitHub → Releases → New Release:
- Tag: v0.0.2 (ต้องขึ้นต้นด้วย v)
- Attach ไฟล์ .apk
- เขียน release notes

4. แอพจะเช็คอัตโนมัติ ทุกครั้งที่เปิด/กลับมา foreground ถ้ามี version ใหม่จะขึ้น popup ให้กด ดาวน์โหลด → เปิด browser โหลด APK →
ติดตั้งทับได้เลย
