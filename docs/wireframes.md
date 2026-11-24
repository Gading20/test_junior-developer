# Wireframe

Skema layout, bukan screenshot. Ukuran mengacu pada layar 360 dp. Semua layar memakai token yang sama dari `lib/core/theme/tokens/`.

## 1. Daftar kelas — data

```text
┌──────────────────────────────┐
│ Daftar kelas                 │  AppBar
├──────────────────────────────┤
│ Belajar sesuai ritmemu       │  caption
│ 5 kelas tersedia             │
│                              │
│ ┌──────────────────────────┐ │
│ │ [thumbnail 16:9]         │ │
│ ├──────────────────────────┤ │
│ │ Flutter untuk Pemula     │ │  title, max 2 baris
│ │ Rani Kusuma · Pemula     │ │  caption
│ │ 8 pelajaran · 1j 51m     │ │  caption
│ └──────────────────────────┘ │
│            ↕ 12 dp           │
│ ┌──────────────────────────┐ │
│ │ kartu kelas berikutnya   │ │
│ └──────────────────────────┘ │
└──────────────────────────────┘
```

Grid dua kolom dipakai saat lebar ≥ 600 dp. Kartu tidak memakai shadow; pemisah berupa border 1 px.

## 2. Daftar kelas — empat kondisi

```text
LOADING              EMPTY                ERROR                 DATA
┌──────────┐         ┌──────────┐         ┌──────────┐          ┌──────────┐
│ ▭ ▭ ▭   │         │    ◻     │         │    ⚠     │          │ [kartu]  │
│ ▭▭▭▭▭  │         │ Belum ada │         │ Tidak ada│          │ [kartu]  │
│ ▭ ▭ ▭   │         │ kelas     │         │ internet │          │ [kartu]  │
│ ▭▭▭▭▭  │         │           │         │ [Coba    │          │          │
│          │         │           │         │  lagi]   │          │          │
└──────────┘         └──────────┘         └──────────┘          └──────────┘
```

Skeleton mengikuti bentuk kartu asli: thumbnail, dua baris judul, dua baris metadata. Error memakai pesan berbeda untuk offline, timeout, server, parsing, dan unknown.

## 3. Detail kelas

```text
┌──────────────────────────────┐
│ ←  Detail kelas              │
├──────────────────────────────┤
│ [thumbnail 16:9]             │
│ Flutter untuk Pemula         │  title L
│ Rani Kusuma · Pemula         │
│ 8 pelajaran · 1j 51m         │
│                              │
│ Deskripsi kelas...           │
│ [Selengkapnya]               │  bila teks panjang
│                              │
│ Daftar pelajaran      8      │  SectionHeader
│ 1  Memasang Flutter    12:00 │  LessonTile
│ ──────────────────────────── │
│ 2  Aplikasi Pertama   11:00 │
│ ──────────────────────────── │
│ ...                          │
├──────────────────────────────┤
│ [ Mulai belajar ]            │  tombol melekat di bawah
└──────────────────────────────┘
```

## 4. Halaman belajar — portrait

```text
┌──────────────────────────────┐
│ ←  Memasang Flutter...       │
├──────────────────────────────┤
│ ┌──────────────────────────┐ │
│ │       VIDEO 16:9         │ │  VideoArea
│ │  ▶  ───●───────  00:12   │ │  kontrol khusus / YouTube
│ └──────────────────────────┘ │
│ FLUTTER UNTUK PEMULA         │  caption
│ Memasang Flutter dan VS Code │  title L
│ Pelajaran 1 dari 8 · 12:00   │  caption
│                              │
│ Tentang pelajaran            │
│ Cek prasyarat, instalasi...  │
│                              │
│ [Sebelumnya] [Berikutnya]    │  teks, bukan panah saja
│ ──────────────────────────── │
│ Daftar pelajaran      8      │
│ › 1 Memasang Flutter  12:00  │  aktif
│ › 2 Aplikasi Pertama  11:00  │
│ ...                          │
└──────────────────────────────┘
```

Tiga kondisi tambahan pada stage video: loading (spinner), error dengan ikon + pesan + "Coba lagi", dan kontrol tersembunyi setelah tap.

## 5. Halaman belajar — layar penuh

```text
┌────────────────────────────────────────────┐
│ [⤡]                                       │  tombol keluar, kiri atas
│                                            │
│              VIDEO 16:9                    │  Scaffold body, tanpa AppBar
│                                            │
│              kontrol player                │
└────────────────────────────────────────────┘
```

GlobalKey memindahkan elemen player yang sama dari layout portrait ke layout ini. Orientasi dikunci landscape dan dikembalikan saat keluar.

## 6. Rute tidak ditemukan

```text
┌──────────────────────────────┐
│                              │
│    Halaman tidak ditemukan.  │
│                              │
│    [ Ke daftar kelas ]       │
│                              │
└──────────────────────────────┘
```

## Aturan tata letak

- Spasi: 4, 8, 12, 16, 24, 32 dp.
- Radius: 8 dp untuk tombol, 12 dp untuk kartu.
- Border 1 px sebagai pengganti shadow.
- Satu elemen dominan per layar; teks dan metadata rata kiri.
- Target sentuh ≥ 48 dp; aman pada skala teks 1,3x.
- Satu set ikon: `lucide_icons_flutter`.
