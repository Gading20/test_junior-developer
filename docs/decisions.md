# Keputusan teknis

Format: keputusan, alasan, alternatif yang ditolak.

## Arsitektur feature-first

Pilihan: `core/` untuk kode lintas fitur, `features/courses/{data,domain,presentation}`, `features/lesson_player/presentation`.

Alasan: pembaca dapat menemukan semua kode kelas dalam satu cabang. Dependensi mengarah ke dalam: presentation → domain, data → domain. UI tidak mengimpor Dio.

Ditolak: layer-first (`models/`, `pages/`, `providers/` di root). Kode fitur tersebar dan sulit diikuti saat proyek bertambah.

## Entity merangkap model

Pilihan: `Course.fromJson` dan `Lesson.fromJson` langsung di entity.

Alasan: bentuk API identik dengan bentuk domain. DTO + mapper hanya menambah file dan boilerplate.

Ditolak: `freezed` dan `json_serializable`. Butuh code generation, menambah waktu build dan kompleksitas untuk proyek seukuran ini. Immutability tetap didapat lewat field final dan constructor const.

## Riverpod untuk state dan DI

Pilihan: `flutter_riverpod` untuk provider repository dan `AsyncValue`.

Alasan: satu mekanisme untuk inject dependency dan empat kondisi UI. Auto-retry dimatikan agar retry disengaja.

Ditolak: `setState` + `Http` langsung di widget (sulit diuji), BLoC/Cubit (boilerplate tambahan tanpa kebutuhan), `get_it` (tidak menyediakan state async).

## go_router

Pilihan: rute deklaratif dengan path parameter.

Alasan: deep link pelajaran bekerja, parameter tidak di-passing manual antar halaman.

Ditolak: `Navigator` imperatif. Penulisan URL tersebar di banyak widget. `pushReplacement` tetap dipakai untuk pergantian pelajaran agar tidak menumpuk player.

## Dio

Pilihan: Dio dengan timeout terpusat dan pemetaan `DioException` → `Failure`.

Alasan: kebutuhan membedakan offline, timeout, dan server error. Satu tempat mengubah pesan pengguna.

Ditolak: `http` package. Tidak punya struktur exception sekaya Dio untuk kebutuhan ini.

## Dua player, bukan satu

Pilihan: `video_player` untuk MP4 dengan kontrol khusus; `youtube_player_iframe` untuk YouTube.

Alasan: soal meminta kontrol khusus. YouTube tidak boleh diputar dengan mengekstrak stream; IFrame Player adalah cara resmi. Tutorial publik yang dipilih sebagian besar ada di YouTube.

Ditolak: `chewie` (kontrol bukan buatan sendiri), `youtube_player_flutter` (API lama dan ketergantungan webview yang lebih berat), memasukkan video YouTube ke `video_player` (melanggar ketentuan platform).

Konsekuensi: tampilan kontrol berbeda antara MP4 dan YouTube. Ini dicatat di `docs/limitations.md`.

## Satu arah visual dan token

Pilihan: teal + amber, netral hangat, Plus Jakarta Sans, lucide, border 1 px tanpa shadow.

Alasan: tampilan terlihat satu tangan, tidak seperti template default. Kontras teks dan target sentuh memenuhi praktik WCAG AA.

Ditolak: gradien ungu-biru, glassmorphism, ikon emoji, bayangan kartu berlebih, `intl`, `shimmer`. Tidak sesuai arah visual dan menambah dependensi tanpa manfaat.

## Mock JSON dengan kontrak nyata

Pilihan: `AppConfig.useMock` dan satu berkas JSON berbentuk envelope API.

Alasan: perpindahan ke backend nyata cukup mengganti flag dan `BASE_URL`. Parser dan repository tidak berubah.

Ditolak: hardcode data di Dart (tidak mendemonstrasikan parsing) dan server local (tidak portable).

## Verifikasi

Pilihan: pengujian unit + widget, bukan integration test penuh.

Alasan: perilaku kritis (Parsing, Failure, lifecycle, overflow, tap ganda) dapat diverifikasi tanpa perangkat. Pengujian di HP dilakukan manual untuk embed YouTube dan orientasi.

Ditolak: golden test. Akan rapuh terhadap perubahan font dan versi Flutter.

## Tombol keluar layar penuh

Pilihan: menyisipkan strip 56 dp di atas video pada layout fullscreen, lalu `PopScope` untuk tombol back perangkat.

Alasan: WebView YouTube adalah platform view native dan dapat melukis di atas widget Flutter. Tombol yang ditempatkan di atas video tidak terlihat dan tidak bisa ditekan di HP. Strip di luar area WebView membuat tombol tetap terlihat; back button memberi jalan keluar kedua.

Ditolak: overlay `Stack` di atas video (tertutup WebView), mengandalkan tombol fullscreen YouTube saja (tidak keluar dari mode fullscreen aplikasi).

## Perbaikan bug perpindahan pelajaran

Masalah: router dapat memakai ulang `State` untuk rute dengan pola sama. `VideoArea` menerima lesson baru lewat `didUpdateWidget`, tetapi controller lama tetap hidup.

Keputusan: `didUpdateWidget` mengganti `_videoKey`, mereset `_switching`, dan `ListView` diberi `ValueKey(courseId/lessonId)`. Controller lama dibuang, yang baru dibuat.

Ditolak: menambah `lessonId` ke `key` widget halaman saja. Tidak menjamin State lama dibuang bila router melakukan update in-place.
