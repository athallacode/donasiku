# Persiapan Tes SonarQube untuk Proyek Flutter (Donasiku)

Panduan ini berisi langkah-langkah persiapan untuk melakukan analisis statis (static code analysis) pada proyek Flutter Anda menggunakan SonarQube.

## 1. Persyaratan (Prerequisites)
Sebelum memulai tes SonarQube, pastikan sistem OS Anda memenuhi hal-hal berikut:
1. **Java Development Kit (JDK) 17+**: Dibutuhkan untuk menjalankan SonarScanner.
2. **SonarQube Server**: Anda harus memiliki Akses SonarQube Server. (Pilih salah satu)
   - SonarQube berjalan secara lokal (diunduh dari web official atau menggunakan Docker).
   - Akun SonarCloud (layanan berbasis web/cloud).
3. **SonarScanner CLI**: CLI dari SonarQube untuk menganalisis kode dan mengirimkannya ke server SonarQube. Unduh dan masukkan *path* bin-nya ke *Environment Variables* Windows (PATH).
4. *(Opsional untuk SonarQube Eksternal)* Plugin pendukung Dart/Flutter. Jika menggunakan SonarCloud, Flutter telah di-*support* penuh secara *default*. Namun jika menggunakan SonarQube lokal versi lama, Anda mungkin perlu menginstal plugin *SonarQube Flutter/Dart*.

## 2. Generate Laporan Tes & Code Coverage
Sebelum menjalankan SonarScanner, Anda perlu me-*generate* hasil *test* dan laporan *code coverage* dari proyek Flutter Anda (yang terletak di `d:\donasiku`). SonarScanner akan membaca file ini untuk diolah.

Buka Terminal (Bisa menggunakan PowerShell atau CMD) dan pastikan berada pada direktori proyek (`d:\donasiku`). Jalankan perintah ini:

```bash
# Pastikan library terinstall semua dengan baik
flutter pub get

# Jalankan unit test dan buat file code coverage 
flutter test --coverage
```

Setelah perintah ini dijalankan, sebuah folder bernama `coverage/` akan terbentuk dengan file `lcov.info` di dalamnya.

## 3. Membuat file Konfigurasi SonarQube
Buat berkas baru bernama `sonar-project.properties` di bagian *root* (direktori utama `d:\donasiku\`) proyek Anda. 

Anda dapat menggunakan konfigurasi di bawah ini sebagai template `sonar-project.properties` Anda:

```properties
# ---- Konfigurasi Proyek ----
# Nama Kunci (Project Key) harus unik, sesuaikan dengan Project Key yang diberikan oleh SonarQube
sonar.projectKey=donasiku-android-app

# Nama bebas yang akan ditampilkan di Dashboard SonarQube
sonar.projectName=Donasiku App

# Versi proyek
sonar.projectVersion=1.0.0

# ---- Konfigurasi Folder Source Code dan Test ----
# Lokasi source code Flutter
sonar.sources=lib
# Lokasi script unit testing
sonar.tests=test

# ---- Konfigurasi Laporan Code Coverage ----
# Path folder lcov hasil generate Flutter Test di Langkah Ke-2.
# Gunakan identifier sonar.dart bila menggunakan plugin Dart
sonar.dart.lcov.reportPaths=coverage/lcov.info

# ---- Konfigurasi Tambahan ----
# Abaikan file hasil auto-generate dari analisis linter karena tidak dibuat secara manual
sonar.exclusions=**/*.g.dart, **/*.freezed.dart, lib/generated_plugin_registrant.dart

# Mengatur Encoding File agar menghindari karakter rusak
sonar.sourceEncoding=UTF-8
```

*Catatan Penting: Apabila Anda menggunakan **SonarCloud** atau Server Spesifik di Perusahaan, Anda barangkali perlu menambahkan URL Host dan Organization:*
```properties
sonar.host.url=https://sonarcloud.io
sonar.organization=nama-organisasi-anda
```

## 4. Eksekusi SonarScanner
Langkah terakhir adalah menjalankan proses analisis (scanning). 
Pastikan Terminal Anda masih berada di dalam direktori `d:\donasiku` kemudian jalankan perintah pemindaian:

```bash
# Apabila SonarQube tidak menggunakan token / testing open-source:
sonar-scanner

# Apabila SonarQube memerlukan kredensial/token autentikasi (Ganti dengan Token Anda):
sonar-scanner -Dsonar.login="MASUKKAN_TOKEN_ANDA_DISINI"
```

## 5. Review Hasil di Dasbor (Dashboard)
Setelah eksekusi berhasil dan terminal menampilkan pesan `EXECUTION SUCCESS`, bukalah aplikasi peramban (browser) dan kunjungi dashboard SonarQube Anda (secara bawaan ada di `http://localhost:9000` apabila dideploy secara lokal).
Di sana, Anda dapat mengevaluasi matriks kesehatan kode seperti:
* **Bugs** (Indikasi masalah *error* kode),
* **Vulnerabilities** (Celah Keamanan Server/App),
* **Code Smells** (Kode kotor dan sulit untuk dirawat), dan 
* **Code Coverage** (Persentase unit test dari aplikasi Anda).
