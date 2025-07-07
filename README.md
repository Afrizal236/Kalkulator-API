# Kalkulator API RA

Aplikasi kalkulator Flutter yang canggih dengan dukungan mode scientific dan integrasi API untuk perhitungan matematika kompleks.

## Fitur Utama

### Mode Kalkulator
- **Mode Dasar**: Operasi aritmatika standar (+, -, *, /, %)
- **Mode Scientific**: Fungsi trigonometri, logaritma, eksponen, dan konstanta matematika

### Fungsi Matematika
- **Operasi Dasar**: Penjumlahan, pengurangan, perkalian, pembagian
- **Trigonometri**: sin, cos, tan (dengan dukungan mode derajat/radian)
- **Logaritma**: log (basis 10), ln (logaritma natural)
- **Eksponen**: e^x, x², x³
- **Akar**: √x
- **Konstanta**: π (pi), e (euler)

### Teknologi & Integrasi
- **API Integration**: Menggunakan MathJS API untuk perhitungan presisi tinggi
- **Fallback System**: Perhitungan lokal otomatis saat API tidak tersedia
- **Network Status**: Indikator status koneksi real-time
- **Error Handling**: Penanganan error yang robust dengan pesan informatif

## Instalasi

### Prasyarat
- Flutter SDK (versi 3.0.0 atau lebih baru)
- Dart SDK
- Android Studio / VS Code
- Koneksi internet (untuk fitur API)

### Langkah Instalasi

1. **Clone repository**
```bash
git clone [repository-url]
cd kalkulator-api-ra
```

2. **Install dependencies**
```bash
flutter pub get
```

3. **Jalankan aplikasi**
```bash
flutter run
```

## Dependencies

Tambahkan dependencies berikut ke `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  http: ^1.1.0
  
dev_dependencies:
  flutter_test:
    sdk: flutter
```

## Penggunaan

### Mode Dasar
1. Buka aplikasi untuk mengakses kalkulator dasar
2. Gunakan tombol numerik dan operator untuk perhitungan
3. Tekan `=` untuk mendapatkan hasil
4. Gunakan `C` untuk clear semua, `CE` untuk clear entry

### Mode Scientific
1. Tekan tombol `Sci` untuk beralih ke mode scientific
2. Pilih mode sudut (DEG/RAD) untuk fungsi trigonometri
3. Gunakan fungsi-fungsi matematika lanjutan:
   - **sin/cos/tan**: Masukkan nilai, lalu tekan fungsi trigonometri
   - **log/ln**: Logaritma basis 10 atau natural
   - **sqrt**: Akar kuadrat
   - **pow2/pow3**: Pangkat 2 atau 3
   - **pi/e**: Konstanta matematika

### Indikator Status
- **🔴 WiFi Off**: Mode offline (menggunakan perhitungan lokal)
- **🟢 Network**: Terhubung ke API
- **⏳ Loading**: Sedang memproses perhitungan

## Arsitektur Teknis

### API Integration
- **Primary**: MathJS API (`api.mathjs.org`)
- **Timeout**: 15 detik
- **Headers**: User-Agent, Accept, Content-Type

### Fallback System
Aplikasi secara otomatis beralih ke perhitungan lokal menggunakan `dart:math` ketika:
- Tidak ada koneksi internet
- API timeout
- API error/unavailable

### Error Handling
- Network exceptions
- HTTP errors
- Format validation
- Timeout handling
- Division by zero protection

## Struktur File

```
lib/
├── main.dart                 # Entry point dan widget utama
├── calculator_state.dart     # State management
├── api_service.dart         # HTTP service layer
└── utils/
    ├── math_functions.dart  # Local math calculations
    └── formatters.dart      # Number formatting utilities
```

## Konfigurasi Development

### SSL Certificate Bypass
> ⚠️ **Peringatan**: Fitur bypass SSL hanya untuk development

```dart
class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}
```

### Network Testing
Aplikasi melakukan test koneksi otomatis saat startup dan menyediakan tombol manual test di app bar.

## Fitur Tambahan

### UI/UX Features
- **Responsive Design**: Otomatis menyesuaikan dengan ukuran layar
- **Loading States**: Indikator visual saat proses perhitungan
- **Error Messages**: Pesan error yang user-friendly
- **Smooth Transitions**: Animasi halus antar mode

### Accessibility
- **Large Touch Targets**: Tombol berukuran optimal untuk touch
- **High Contrast**: Warna yang mudah dibaca
- **Screen Reader Support**: Compatible dengan assistive technology

## Troubleshooting

### Masalah Umum

**1. API Tidak Bisa Diakses**
- Pastikan koneksi internet stabil
- Cek status MathJS API
- Aplikasi akan otomatis menggunakan fallback calculation

**2. Error Saat Build**
- Jalankan `flutter clean` kemudian `flutter pub get`
- Pastikan Flutter SDK up to date

**3. SSL Certificate Error**
- Untuk production, hapus `MyHttpOverrides`
- Gunakan certificate yang valid

## Kontribusi

1. Fork repository
2. Buat feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to branch (`git push origin feature/AmazingFeature`)
5. Buka Pull Request

## Roadmap

- [ ] History perhitungan
- [ ] Custom themes
- [ ] Export hasil ke file
- [ ] Unit converter
- [ ] Graph plotting
- [ ] Voice input
- [ ] Gesture controls

## License

Distributed under the MIT License. See `LICENSE` for more information.

## Credits

- **MathJS API**: Untuk perhitungan matematika presisi tinggi
- **Flutter Team**: Framework yang luar biasa
- **Dart Math Library**: Fallback calculations

## Kontak

**Developer**: [Nama Anda]
**Email**: [email@example.com]
**Project Link**: [repository-url]

---

⭐ Jika project ini membantu, jangan lupa beri star di repository!
