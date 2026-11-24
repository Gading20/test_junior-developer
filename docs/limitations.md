# Keterbatasan dan catatan jujur

## Video dan materi

- Sumber tutorial dikurasi dari hasil pencarian YouTube pada 24 November 2026. Judul, kanal, dan durasi diverifikasi dari metadata; isi penuh 34 video tidak ditonton satu per satu.
- Beberapa video berbahasa Inggris atau memakai versi Flutter/Dart lama. Kanal dan bahasa dicantumkan di deskripsi pelajaran dan di `docs/video-sources.md`.
- Izin embed dan ketersediaan video berada di tangan pembuat. Jika embed gagal, pengguna dapat memakai tombol **Buka di YouTube**. Tombol ini gagal pula bila tidak ada browser/application handler.
- Nama instruktur pada data mock awal bersifat fiktif dan sudah diganti label "Kurasi tutorial publik". Ini bukan katalog kelas berbayar.
- Durasi pelajaran mengikuti durasi video sumber, sehingga tidak selalu bulat seperti data awal.

## Pemutar

- MP4 memakai kontrol khusus aplikasi; YouTube memakai kontrol IFrame resmi. Keduanya tidak identik. Tidak ada kontrol seragam lintas platform.
- Tidak ada autoplay. Setelah aplikasi kembali dari latar belakang, pengguna menekan play sendiri.
- Tidak ada progress tontonan, bookmark, resume posisi, subtitle kustom, rating, atau kecepatan putar untuk YouTube.
- Layar penuh YouTube memakai kontrol YouTube. Tombol keluar layar penuh berada pada strip 56 dp di atas video karena WebView native dapat menutupi overlay Flutter; area video dengan demikian tidak benar-benar penuh sampai ke tepi atas. Tombol back perangkat juga keluar dari layar penuh.
- Pengujian otomatis memakai `FakeVideoPlayerPlatform`; pemutaran nyata diverifikasi manual di perangkat.

## Data dan jaringan

- Endpoint nyata tidak disediakan. Kontrak API didokumentasikan tetapi belum diuji terhadap server sungguhan.
- Mock ditunda 400 ms agar skeleton terlihat; ini bukan latensi jaringan asli.
- Tidak ada caching response API, pagination, atau filter/pencarian kelas.
- `notFound` tidak bisa di-retry karena alamat yang sama akan menghasilkan hasil sama.

## Akun dan progres

- Tidak ada login, profil, role, atau pembayaran. Aplikasi hanya berbasis siswa dan bersifat statis.
- Tidak ada penyimpanan lokal untuk progres belajar; menutup aplikasi menghilangkan posisi tonton.

## Pengujian dan perangkat

- 37 tes otomatis berjalan di host Linux. Tidak ada integration test yang menjalankan YouTube di emulator.
- Verifikasi visual di Samsung SM A155F dilakukan manual dengan build debug. Screenshot membuktikan tampilan, bukan seluruh interaksi video.
- Emulator tidak tersedia; tablet dan rotasi diuji lewat ukuran widget test, bukan perangkat fisik.
- `flutter analyze` bersih pada commit terakhir. Tidak ada CI yang menjalankannya otomatis.

## Aksesibilitas

- Target sentuh minimal 48 dp dan skala teks 1,3x diuji pada 360 dp dan 640 dp.
- Kontras token warna mengikuti praktik WCAG AA, tetapi belum diukur dengan alat audit kontras otomatis untuk setiap pasangan warna.
- Label semantics belum ditambahkan ke setiap ikon dekoratif.
