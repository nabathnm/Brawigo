# Kontribusi Brawigo (Flutter)

Dokumen ini sementara fokus pada poin penting dulu. Bagian lain menyusul.

## 1. Stack dan Konvensi Dasar

- Frontend: Flutter
- State Management: BLOC
- Backend Service: Supabase

---

## 2. Setup Lokal

Jalankan sekali setelah clone:

```bash
flutter pub get
# cp .env.example .env (jika menggunakan environment file)
````

Menjalankan project:

```bash
flutter run
```

Build APK:

```bash
flutter build apk
```

---

## 3. Struktur Folder (Disarankan)

```text
lib/
│
├── core/            # config, constants, utils
├── data/            # model, datasource (API/local)
├── features/    # fitur aplikasi (pages, widgets)
│
├── routes/          # routing
├── main.dart
```

---

## 4. Alur Kerja Git

Branch yang dipakai:

* **main**
* dev
* feature/nama-fitur
* fix/nama-bug
* docs/topik

### Flow kerja dasar:

1. Pindah ke branch dev dan ambil update terbaru:

```bash
git checkout dev
git pull origin dev
```

2. Buat branch baru dari dev:

```bash
git checkout -b feature/nama-fitur
```

3. Kerja dan commit kecil:

```bash
git add .
git commit -m "feat: deskripsi perubahan"
```

4. Sinkronisasi dengan dev:

```bash
git checkout dev
git pull origin dev
git checkout feature/nama-fitur
git merge dev
```

5. Jika conflict:

* Buka file yang conflict
* Hapus tanda `<<<<<<<`, `=======`, `>>>>>>>`
* Pilih kode yang benar

```bash
git add .
git commit -m "chore: resolve merge conflict"
```

6. Push & buat PR:

```bash
git push -u origin feature/nama-fitur
```

---

### Tips minim conflict:

* Selalu mulai dari dev terbaru
* 1 branch = 1 fitur kecil
* Hindari edit file yang sama tanpa koordinasi
* Sering pull sebelum lanjut coding
* Jangan force push ke branch orang lain

---

## 5. Standar Commit Message

Format:

```text
type: ringkasan singkat
```

Type yang dipakai:

* `feat`: fitur baru
* `fix`: bug
* `refactor`: perbaikan struktur tanpa ubah behavior
* `docs`: dokumentasi
* `chore`: config, dependency, dll

Contoh:

* `feat: tambah halaman login`
* `fix: perbaiki error parsing API`
* `refactor: rapikan struktur folder presentation`
* `chore: update dependency dio`

---

## 6. Standar Pull Request

Isi PR:

1. Ringkasan perubahan
2. Masalah yang diselesaikan
3. Cara test fitur

Checklist:

* [ ] Sudah update dari dev
* [ ] Tidak ada konflik
* [ ] Tidak ada file sensitif (API key, .env)
* [ ] Sudah dites di device/emulator

---

## 7. Konvensi Coding Flutter

### Penamaan

* File: `snake_case.dart`
* Class: `PascalCase`
* Variable: `camelCase`

### Widget

* Gunakan widget kecil (modular)
* Pisahkan UI dan logic
* Hindari widget terlalu panjang (>200 baris)

### Contoh:

```dart
class LoginPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LoginForm(),
    );
  }
}
```

---

## 8. Best Practice Tambahan

* Gunakan `const` sebisa mungkin
* Hindari rebuild berlebihan
* Gunakan state management dengan benar
* Pisahkan API service dari UI
* Gunakan environment variable untuk base URL API
