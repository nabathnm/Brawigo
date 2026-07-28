# 📱 Brawigo — Campus Marketplace & E-Commerce for Universitas Brawijaya

![Flutter](https://img.shields.io/badge/Flutter-%5E3.11.5-02569B?logo=flutter&logoColor=white) ![Dart](https://img.shields.io/badge/Dart-%5E3.0.0-0175C2?logo=dart&logoColor=white) ![Supabase](https://img.shields.io/badge/Supabase-Backend-3ECF8E?logo=supabase&logoColor=white) ![State Management](https://img.shields.io/badge/State%20Management-BLoC%20%5E9.1.1-6F42C1) ![Submission](https://img.shields.io/badge/Submission-Phase%202-00B4D8)

**Brawigo** adalah platform *Marketplace* & *Commerce* terpadu berbasis mobile dan web berteknologi Flutter yang dirancang secara eksklusif untuk mahasiswa dan civitas akademika **Universitas Brawijaya (UB)**. Platform ini menjembatani transaksi jual-beli barang bekas berkualitas (seperti buku kuliah, alat elektronik, dan perlengkapan kampus) maupun usaha wirausaha mahasiswa di lingkungan kampus dengan jaminan keamanan melalui verifikasi identitas resmi institusi.

---

## 📖 1. Penjelasan Aplikasi

Brawigo hadir dengan konsep **Eksklusivitas Kampus & Keamanan Transaksi**. Setiap anggota yang tergabung wajib mendaftar dan memverifikasi diri menggunakan email resmi kampus (`@student.ub.ac.id`), sehingga meminimalisir risiko penipuan dan menumbuhkan rasa percaya di dalam ekosistem kampus.

### ✨ Fitur Unggulan & Inovasi:
* 🔐 **Otentikasi Khusus Mahasiswa UB**: Sistem keamanan terintegrasi dengan **Supabase Auth** yang memvalidasi domain email *@student.ub.ac.id*, disertai aktivasi *inbox confirmation* dan enkripsi kredensial.
* 🎭 **Sistem Dwi-Peran (Dual Role: Buyer & Seller)**:
  * **Akun Seller (Penjual)**:
    * **Kelola Katalog & Galeri Multi-Foto**: Tambahkan dan perbarui informasi barang dengan spesifikasi mendetail, harga terstruktur, estimasi stok, lokasi pengambilan, serta pengelompokan urutan galeri foto (didukung langsung oleh Supabase Storage).
    * **Pratinjau Tampilan Pembeli (*Buyer View Preview*)**: Seller dapat menguji coba bagaimana tampilan detail produknya di mata calon pembeli melalui mode sakelar pratinjau yang intuitif.
    * **Pusat Manajemen Pesanan (Order Hub)**: Pantau seluruh alur pesanan masuk yang terbagi dalam tab **Orderan**, **Pendapatan Bersih**, dan **Riwayat Selesai**.
    * **Pelacakan Status COD (*Meetup Stepper*)**: Fitur khusus interaktif bagi mahasiswa yang melakukan transaksi COD (Cash On Delivery) / Bertemu di area kampus UB (misal: *Gedung F Filkom*, *Lobi Gedung A FT*), lengkap dengan status *checklist* kesiapan barang hingga konfirmasi kedatangan di lokasi.
  * **Akun Buyer (Pembeli)**:
    * Jelajahi katalog produk berdasarkan kategori dan pencarian cepat menggunakan bilah pencarian modern (*Custom Search Bar*) dengan filter responsif.
    * Dukungan berbagai kanal pembayaran: **QRIS**, **Transfer Bank**, serta **COD / Meetup di Area Kampus UB**.
* 🎨 **Desain Antarmuka Modern & Premium (*Rich Aesthetics*)**: Dibuat dengan palet warna biru khas universitas bersertakan animasi mikro interaktif (*micro-animations*), typography bergaya *Plus Jakarta Sans*, tata letak responsif, dan kartu transaksi bergaya elegan.
* ⚡ **BLoC State Management**: Pengolahan logika bisnis secara modular menggunakan BLoC/Cubit terdepan untuk menghadirkan kecepatan pemrosesan data, pemutakhiran UI seketika, dan penanganan error yang rapi.

---

## 🏗️ 2. Analisis Struktur Aplikasi & Arsitektur

Brawigo mengimplementasikan pendekatan **Clean Architecture** dipadukan dengan **Feature-Driven (Modular Domain) Packaging**. Arsitektur ini memisahkan lapisan UI, State Management, dan Lapisan Integrasi Data guna memudahkan pengujian, kolaborasi tim, dan skalabilitas proyek.

```text
brawigo/
│
├── lib/
│   ├── main.dart                          # Entry point aplikasi, setup Supabase Client, dan Environment Config
│   ├── brawigo.dart                       # Root Widget (BrawigoApp), konfigurasi ThemeData & MultiBlocProvider
│   │
│   ├── core/                              # Modul Core (Komponen komunal yang dapat diakses dari fitur manapun)
│   │   ├── services/                      # Helper tingkat sistem & service adapter standar
│   │   └── utils/
│   │       └── constants/
│   │           ├── brawigo_colors.dart    # Sistem warna modular (Color token untuk gradasi, primary, shade)
│   │           └── brawigo_sizes.dart     # Standarisasi ukuran spasi, radius border, dan elemen letak UI
│   │
│   └── features/                          # Pembagian Modul Utama (Domain Driven)
│       ├── auth/                          # 🔐 Modul Otentikasi & Manajemen Sesi Pengguna
│       │   ├── data/
│       │   │   └── datasource/
│       │   │       └── auth_service.dart  # Hubungan langsung ke API Supabase (Login, Register, Role Sinkronisasi)
│       │   ├── presentation/
│       │   │   ├── blocs/                 # AuthBloc, AuthEvent, AuthState (Pusat kendali logika sesi pengguna)
│       │   │   └── pages/                 # LoginPage, RegisterPage, AuthScreen (Tampilan input credential)
│       │   └── services/                  # Bridging logic tambahan untuk otentikasi
│       │
│       ├── marketplace/                   # 🛍️ Modul Perdagangan, Toko, & Transaksi Kampus
│       │   ├── data/                      # Lapisan pengambilan & sinkronisasi katalog produk
│       │   ├── presentation/
│       │   │   ├── bloc/                  # MarketplaceBloc (Logika penampilan katalog & kelola state produk)
│       │   │   ├── pages/
│       │   │   │   ├── main_screen.dart             # Scaffold utama penampung Navigasi Bawah (Bottom NavBar)
│       │   │   │   ├── marketplace_seller_page.dart # Dasbor beranda untuk Akun Seller (Pengelola Barang)
│       │   │   │   ├── marketplace_buyer_page.dart  # Dasbor katalog dan pencarian untuk Akun Buyer
│       │   │   │   ├── add_product_page.dart        # Formulir tambah produk beserta pengunggah foto
│       │   │   │   ├── update_product_page.dart     # Penyunting data produk, harga, dan manajemen stok
│       │   │   │   ├── product_detail_page.dart     # Halaman detail produk multi-galeri & mode pratinjau asli
│       │   │   │   ├── order_page.dart              # Halaman Order (Tab Pendapatan, Orderan QRIS/Transfer/COD, Riwayat)
│       │   │   │   └── order_detail_page.dart       # Tracker tahapan COD Meetup Stepper & Konfirmasi Pesanan
│       │   │   └── widgets/                     # Komponen antarmuka yang dapat dipakai ulang
│       │   │       ├── custom_search.dart       # Bilah pencarian produk & tombol filter gradasi interaktif
│       │   │       ├── header.dart              # Komponen header khas dengan logo & informasi salam
│       │   │       ├── seller_product_card.dart # Kartu item produk beresolusi tinggi untuk toko seller
│       │   │       └── ...
│       │
│       └── profile/                       # 👤 Modul Profil Pengguna & Informasi Civitas Academica
│           └── presentation/
│               └── pages/
│                   └── profile_page.dart  # Manajemen akun, statistik toko, dan tombol Sign Out
│
├── assets/                                # Penyimpanan berkas statis lokal
│   ├── images/                            # Avatar, ilustrasi umum, serta ikon vektor
│   │   ├── icon/                          # Kumpulan ikon aksi (find, filter, detail, hapus, edit)
│   │   └── navbar/                        # Ikon navigasi dinamis (beranda, pesan, order, profil, dan tombol +)
│   └── ...
│
├── pubspec.yaml                           # Definisi pustaka eksternal, konfigurasi aset, & SDK constraints
└── README.md                              # Dokumentasi resmi submission proyek
```

### 🧩 Penjelasan Lapisan (Layers):
1. **Presentation Layer (`presentation/`)**: Menampung seluruh kode visualisasi (Widgets/Pages) yang memetakan status (*State*) langsung ke layar ponsel atau browser menggunakan pola BLoC/Cubit.
2. **Business Logic Layer (`blocs/`)**: Menjembatani input aksi pengguna dari UI menuju *Services*. Memastikan tidak ada logika pemrosesan berat di dalam berkas UI.
3. **Data & Services Layer (`data/` & `services/`)**: Bertanggung jawab berinteraksi secara real-time dengan infrastruktur **Supabase Cloud** (Database PostgreSQL, Auth, dan Supabase Object Storage).

---

## 🔗 3. Link Clone Repository Khusus Submission Phase 2

Repository ini sengaja di-setting **Public** untuk memudahkan dewan juri, penilai, dan tim penguji dalam meninjau serta menjalankan submission pada **Phase 2**.

### 🚀 Tautan Resmi (GitHub Repository):
```url
https://github.com/nabathnm/Brawigo.git
```

### 🛠️ Langkah-Langkah Instalasi & Pengujian:

1. **Clone Repository ke Komputer Lokal:**
   ```bash
   git clone https://github.com/nabathnm/Brawigo.git
   cd Brawigo
   ```

2. **Unduh Seluruh Dependencies Flutter:**
   ```bash
   flutter pub get
   ```

3. **Konfigurasi Variabel Lingkungan (.env):**
   Pastikan file konfigurasi berkas rahasia `.env` (berisi *URL Supabase* dan *Anon Key*) telah terletak pada direktori akar (*root*) proyek, sesuai standar inisialisasi lingkungan Supabase.

4. **Jalankan Aplikasi pada Perangkat Pilihan:**
   ```bash
   # Untuk menjalankan pada peramban Web Chrome / Edge:
   flutter run -d chrome
   
   # Untuk menjalankan pada Emulator Android / Perangkat Asli:
   flutter run
   ```

---

## 🔑 4. Email Dummy untuk Akses Pengujian (Demo Accounts)

Untuk mematuhi protokol validasi email eksklusif UB (`@student.ub.ac.id`) sekaligus mempercepat proses penelaahan bagi **Evaluator / Juri Phase 2**, kami menyediakan dua tipe akun uji coba (*Dummy Accounts*) yang mewakili peran pengguna yang berbeda:

### 🛍️ Akun 1: Pembeli (*Buyer Demo Account*)
Gunakan akun ini untuk mengeksplorasi antarmuka pencarian produk, menelusuri katalog per kategori, melihat detail produk, serta meninjau simulasi pemesanan.
* **Email:** `buyer_demo@student.ub.ac.id`
* **Password:** `Brawigo2026!`

### 🏬 Akun 2: Penjual (*Seller Demo Account*)
Gunakan akun ini untuk menelaah fitur-fitur ekstensif wirausaha mahasiswa, seperti kelola stok toko, pengunggahan produk multi-foto, melihat pratinjau halaman produk, melongok Dasbor **Order & Pendapatan**, serta mencoba interaksi alur konfirmasi **Meetup COD Stepper** pada Halaman Detail Order.
* **Email:** `seller_demo@student.ub.ac.id`
* **Password:** `Brawigo2026!`

> [!NOTE]  
> **Catatan Penguji**: Apabila penguji ingin mendaftarkan akun baru secara langsung pada halaman Register di dalam aplikasi, pastikan alamat email yang Anda gunakan wajib berakhiran **`@student.ub.ac.id`** (contoh: `evaluators_phase2@student.ub.ac.id`) agar dapat lolos filter otorisasi sistem Brawigo.

---
*Developed by **Raion Androzon** for Phase 2 Submission.* 🚀🔥
