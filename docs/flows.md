# Alur utama

## 1. Membuka daftar kelas

```mermaid
sequenceDiagram
    actor User
    participant UI as CourseListPage
    participant P as courseListProvider
    participant R as Repository
    participant D as Datasource

    User->>UI: Buka aplikasi
    UI->>P: watch(courseListProvider)
    P->>R: getCourses()
    R->>D: fetchCourses()
    D-->>R: List<Course>
    R-->>P: List<Course>
    P-->>UI: AsyncValue.data
    UI->>User: Kartu kelas
    Note over UI: loading → skeleton, empty → pesan, error → Failure + retry
```

## 2. Membuka pelajaran

```mermaid
flowchart TD
    A[Kartu kelas] --> B[Detail kelas]
    B --> C[Tombol Mulai belajar]
    B --> D[Tap pelajaran]
    C --> E[Halaman pemutar]
    D --> E
    E --> F{lessonId ditemukan?}
    F -- tidak --> G[Pesan: pelajaran tidak ditemukan]
    F -- ya --> H{videoUrl}
    H -- MP4 --> I[VideoArea + kontrol khusus]
    H -- YouTube --> J[YoutubeVideoArea + IFrame]
    H -- invalid --> K[Pesan: tautan tidak valid]
```

## 3. Pergantian pelajaran

```mermaid
sequenceDiagram
    actor User
    participant Page as LessonPlayerPage
    participant Router as GoRouter
    participant Old as VideoArea lama
    participant New as VideoArea baru

    User->>Page: Tap pelajaran lain
    Page->>Page: _switching = true (blok tap berikutnya)
    Page->>Old: isActive=false → pause
    Page->>Router: pushReplacement(rute baru)
    Router->>Old: dispose → pause + controller.dispose
    Router->>New: initState → controller baru
    Note over Old,New: Hanya satu video yang mungkin bersuara
```

Router dapat memperbarui State yang sama untuk pola rute identik. `didUpdateWidget` mengganti `_videoKey` dan mereset `_switching` agar controller lama tidak dipakai ulang.

## 4. Putaran kontrol MP4

```mermaid
flowchart LR
    A[Tap area video] --> B{Tampil?}
    B -- ya --> C[Sembunyikan kontrol]
    B -- tidak --> D[Tampilkan kontrol]
    D --> E[Play / pause / seek / speed / fullscreen]
    E --> F[VideoPlayerController]
```

Kontrol tidak punya timer auto-hide. Player yang dijeda tetap menunjukkan kontrolnya.

## 5. Daur hidup saat aplikasi ke latar belakang

```mermaid
stateDiagram-v2
    [*] -->Aktif: initState, controller dibuat
    Aktif --> Dijeda: paused / hidden / detached
    Dijeda --> Aktif: resumed (putar manual oleh pengguna)
    Aktif --> Dibersihkan: dispose
    Dijeda --> Dibersihkan: dispose
    Dibersihkan --> [*]: pause + dispose controller
```

Tidak ada autoplay setelah `resumed`: pengguna memutuskan kapan melanjutkan.

## 6. Layar penuh

`_setFullscreen(true)` mengunci orientasi landscape, menyembunyikan AppBar, dan memindahkan `VideoArea` ke body `Scaffold`. GlobalKey memindahkan elemen yang sama. Saat keluar atau halaman dibuang, orientasi dikembalikan ke portrait.

## 7. Retry

| Layar | Pemicu | Aksi |
|---|---|---|
| Daftar kelas | Tombol "Coba lagi" | `ref.invalidate(courseListProvider)` |
| Detail kelas | Tombol "Coba lagi" | `ref.invalidate(courseDetailProvider(id))` |
| MP4 gagal | Tombol "Coba lagi" | Controller lama dibuang, controller baru dibuat |
| YouTube gagal | "Buka di YouTube" | Membuka sumber di aplikasi/browser eksternal |

Auto-retry Riverpod sengaja dimatikan agar pengguna melihat pesan galat dan memilih sendiri.
