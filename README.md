# 🚀 HydroApp

แอปพลิเคชัน Flutter สำหรับจัดการระบบ Hydro พร้อมระบบ **Auto Update ผ่าน GitHub Releases**

---

## ✨ Features

* 📱 พัฒนาโดย Flutter รองรับ Android
* 🔄 ระบบ **Auto Update**
* 📦 ดาวน์โหลดและติดตั้งเวอร์ชันใหม่ได้ทันที
* ⚡ ตรวจสอบเวอร์ชันอัตโนมัติเมื่อเปิดแอป / กลับมา foreground

---

## ⚙️ Setup

### 1. แก้ไข GitHub Username

ไปที่ไฟล์:

```bash
lib/services/update_service.dart
```

แก้ไขบรรทัดนี้:

```dart
const _kOwner = 'YOUR_GITHUB_USERNAME'; // ← ใส่ username GitHub
```

---

### 2. Build APK

```bash
flutter build apk --release
```

ไฟล์จะอยู่ที่:

```bash
build/app/outputs/flutter-apk/app-release.apk
```

---

## 🚀 การปล่อยเวอร์ชัน (Release)

ทุกครั้งที่มีเวอร์ชันใหม่ ให้ไปที่ GitHub:

1. ไปที่ **Releases**
2. กด **New Release**

### 📌 ตั้งค่าดังนี้:

* **Tag version**:

  ```bash
  v0.0.2
  ```

  > ⚠️ ต้องขึ้นต้นด้วย `v` เสมอ

* **Attach files**:
  👉 อัปโหลดไฟล์ `.apk`

* **Release notes**:
  👉 เขียนรายละเอียดสิ่งที่เปลี่ยนแปลง

---

## 🔄 ระบบ Auto Update

แอปจะทำงานแบบนี้:

1. เปิดแอป / กลับมา foreground
2. เช็คเวอร์ชันล่าสุดจาก GitHub
3. ถ้ามีเวอร์ชันใหม่:

   * แสดง popup แจ้งเตือน
   * ผู้ใช้กดดาวน์โหลด
   * เปิด browser เพื่อโหลด `.apk`
   * ติดตั้งทับเวอร์ชันเดิมได้ทันที

---

## 📦 Versioning

ใช้รูปแบบ:

```
vMAJOR.MINOR.PATCH
```

ตัวอย่าง:

* `v0.0.1`
* `v0.0.2`
* `v1.0.0`

---

## 🛠 Tech Stack

* Flutter
* Dart
* GitHub Releases (สำหรับระบบอัปเดต)

---

## ⚠️ Notes

* ต้องเปิดให้ติดตั้งแอปจากแหล่งภายนอก (Unknown Sources)
* ผู้ใช้ต้องติดตั้งทับเอง (Android limitation)
* ตรวจสอบว่าไฟล์ `.apk` ถูกแนบใน release ทุกครั้ง

---

## 👨‍💻 Author

* GitHub: https://github.com/YOUR_GITHUB_USERNAME

---

> 💡 Tip: อย่าลืมอัปเดต version ในแอปทุกครั้งก่อน build
