# test_junior-developer

Aplikasi Flutter **Simple E-Learning Platform** untuk siswa: daftar kelas, detail kelas, dan halaman belajar dengan pemutar video. Cocok untuk portofolio teknis: arsitektur feature-first, empat kondisi UI, dan lifecycle pemutar yang jelas.

## Yang sudah ada

- Daftar kelas: kartu, thumbnail cache, skeleton, empty, error, dan retry.
- Detail kelas: deskripsi, metadata, daftar pelajaran, tombol mulai belajar.
- Halaman belajar: video, kontrol khusus untuk MP4, daftar pelajaran, navigasi sebelumnya/berikutnya, layar penuh.
- 34 pelajaran dengan tutorial publik yang sesuai materi; sumber tercantum di `docs/video-sources.md`.
- Empat kondisi UI di semua layar data: loading, empty, error, data.
- Pesan berbeda untuk offline, timeout, server error, 404, dan JSON rusak.
- Satu video aktif: player dijeda saat halaman ditutup, pelajaran diganti, atau aplikasi ke latar belakang.
- Dua sumber video: MP4 melalui `video_player` dengan kontrol buatan sendiri, dan YouTube melalui IFrame Player resmi.

## Cara menjalankan

Butuh Flutter stable 3.50 dan Dart 3.14 atau lebih baru. JDK 17 diperlukan untuk build Android.

```bash
flutter pub get
flutter run
```

Spesifik perangkat:

```bash
flutter devices
flutter run -d <device-id>
```

Data default memakai mock: `lib/core/config/app_config.dart`, `AppConfig.useMock = true`.

Untuk API nyata, ubah flag tersebut ke `false` dan berikan alamat backend:

```bash
flutter run --dart-define=BASE_URL=https://api.contoh.com/v1
```

Kontrak endpoint ada di `docs/data-model.md`. Tidak perlu auth untuk aplikasi ini.

## Verifikasi

```bash
export PATH="$HOME/development/flutter/bin:$PATH"
dart format lib test
flutter analyze
flutter test
```

Jumlah tes: 36 (unit + widget). Jika `google_fonts` mencoba mengunduh font saat tes, tes sudah menonaktifkan runtime fetching.

## Struktur

```text
lib/
  core/
    config/       AppConfig: sakelar mock/real API dan BASE_URL
    error/        Failure + FailureType
    network/      Dio client, endpoint, pemetaan DioException
    router/       go_router, rute, fallback 404
    theme/        token warna, tipografi, spasi, radius
    widgets/      StateView, Skeleton, SectionHeader
  features/
    courses/
      data/       datasource mock/remote, parser JSON, repository
      domain/     entity Course, CourseDetail, Lesson
      presentation/  halaman, provider Riverpod, widget daftar
    lesson_player/
      presentation/  halaman pemutar, navigasi, kontrol, VideoArea, YoutubeVideoArea
assets/mock/api/courses.json
docs/
test/
```

Arsitektur dan alasan keputusan ada di `docs/system-design.md` dan `docs/decisions.md`.

## Dependensi utama

| Paket | Fungsi |
|---|---|
| `flutter_riverpod` | state + dependency injection |
| `go_router` | routing deklaratif dan parameter path |
| `dio` | HTTP client dan timeout terpusat |
| `video_player` | MP4 dengan kontrol khusus |
| `youtube_player_iframe` | YouTube resmi tanpa ekstraksi stream |
| `cached_network_image` | cache thumbnail |
| `google_fonts`, `lucide_icons_flutter` | tipografi dan satu set ikon |

## Keterbatasan singkat

- Tidak ada login, progres belajar, atau penyimpanan riwayat tontonan.
- Video YouTube bergantung pada koneksi, izin embed dari pembuat, dan kontrol player YouTube; kontrol khusus aplikasi hanya dipakai untuk MP4.
- Metadata tutorial diverifikasi dari hasil pencarian YouTube, bukan dari peninjauan penuh isi video.
- Detail lengkap ada di `docs/limitations.md`.
