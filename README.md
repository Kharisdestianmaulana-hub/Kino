<div align="center">
  <img src="Logo.png" alt="Kino Logo" width="180" height="180"/>
  <h1>Kino</h1>
  <strong>A native macOS video editor. Zero compromises.</strong>
  <br/><br/>

  ![Swift](https://img.shields.io/badge/Swift-6.0-F05138?style=flat&logo=swift&logoColor=white)
  ![Platform](https://img.shields.io/badge/Platform-macOS-000000?style=flat&logo=apple&logoColor=white)
  ![License](https://img.shields.io/badge/License-PolyForm%20Shield-blue?style=flat)
  ![Architecture](https://img.shields.io/badge/Architecture-SwiftUI%20%2B%20AVFoundation-purple?style=flat)

  <br/>
  <sub>Built from the ground up for Apple Silicon. No Electron. No compromises.</sub>
</div>

<br/>

<div align="center">
  <img src="Screenshots/Screenshot1.png" alt="Kino - Main Workspace" width="800"/>
  <br/><br/>
  <img src="Screenshots/Screenshot2.png" alt="Kino - Timeline Editing" width="800"/>
</div>

---

<details>
<summary><strong>Table of Contents</strong></summary>

- [English](#english)
  - [What is Kino](#what-is-kino)
  - [Why Kino](#why-kino)
  - [Features](#features)
  - [Architecture](#architecture)
  - [Getting Started](#getting-started)
  - [Keyboard Shortcuts](#keyboard-shortcuts)
  - [Roadmap](#roadmap)
  - [License](#license)
- [Bahasa Indonesia](#bahasa-indonesia)
  - [Apa itu Kino](#apa-itu-kino)
  - [Mengapa Kino](#mengapa-kino)
  - [Fitur](#fitur)
  - [Arsitektur](#arsitektur)
  - [Cara Memulai](#cara-memulai)
  - [Pintasan Keyboard](#pintasan-keyboard)
  - [Peta Jalan](#peta-jalan-roadmap)
  - [Lisensi](#lisensi)

</details>

---

# English

## What is Kino

Kino is a non-linear video editor (NLE) built entirely in Swift for macOS. It uses SwiftUI for the interface, AVFoundation for media processing, and CoreImage for real-time compositing.

Most "native" editors are actually cross-platform compromises wrapped in a macOS skin. Kino is different. Every line of code was written specifically for macOS and Apple Silicon, taking full advantage of hardware-accelerated decoding, Metal-backed rendering, and the tight integration that only a true native app can provide.

The result is an editor that launches instantly, renders without stutter, and handles 4K footage the way macOS was designed to.

## Why Kino

There are plenty of video editors out there. Here is why Kino exists:

- **Truly native.** Not a web app in disguise. Not an Electron wrapper. Not a Qt port. Kino is 100% SwiftUI and AppKit, compiled directly for macOS. It behaves like a Mac app should: instant window snapping, native dark mode, proper menu bar integration, and full Retina support without extra configuration.
- **Lightweight.** The entire application binary is under 5MB. There are no bundled runtimes, no embedded browsers, no background services consuming your RAM. Kino launches in under a second.
- **Predictable.** Every edit operation goes through the Command Pattern. This means the application state is always deterministic. If something goes wrong, the undo stack knows exactly how to reverse it.
- **Educational.** The codebase is intentionally kept readable. If you are learning SwiftUI, AVFoundation, or macOS app architecture, this project serves as a real-world reference that goes far beyond tutorial-level complexity.

## Features

| Feature | Description |
|---|---|
| **Multi-Track Timeline** | Unlimited video and audio tracks with proper Z-index compositing. Higher tracks visually occlude lower ones, just like Premiere Pro and Final Cut. |
| **Auto-Overlay** | Drop a clip on top of another and Kino automatically places it on a higher track instead of overwriting. No more accidental deletions. |
| **Linked Audio/Video** | Importing a video automatically extracts and links its audio track. Move them together, or right-click to unlink for precise J/L cuts. |
| **GPU Playback** | The playback engine wraps `AVMutableComposition` with custom `AVMutableVideoComposition` instructions for real-time opacity, scale, and transform blending. |
| **Real Waveforms** | Audio waveforms are generated from actual 16-bit PCM sample data via `AVAssetReader`, not random squiggly lines. Silent tracks show as flat lines so you know immediately. |
| **Thumbnail Cache** | A thread-safe in-memory cache ensures that scrolling through hundreds of media assets stays at 60fps. Thumbnails and waveforms are generated once, then served from memory. |
| **Inspector Panel** | Adjust position, scale, and rotation through precise sliders, or drag directly on the canvas for visual editing. |
| **Command Pattern** | Every timeline action is wrapped in a reversible command object (`MoveClipCommand`, `SplitClipCommand`, `CompositeCommand`), providing the foundation for full undo/redo history. |

## Architecture

Kino follows a clean, layered architecture that separates concerns strictly:

```
Kino/
  App/                  # Application entry point and lifecycle
  Core/
    Domain/             # Pure data models: Clip, Track, Sequence, MediaAsset
    Services/           # Business logic: PlaybackEngine, MediaService, TimelineService
    Commands/           # Command pattern: reversible actions for undo/redo
  UI/
    Timeline/           # Timeline rendering: ClipView, TrackView, TimelineRulerView
    Viewer/             # Video canvas with interactive transform handles
    Inspector/          # Property panel for clip manipulation
    MediaBrowser/       # Asset library with drag-and-drop support
    State/              # WorkspaceState - single source of truth
    Workspace/          # Main layout and export modal
```

**Key design decisions:**

- **Single Source of Truth.** `WorkspaceState` is an `@EnvironmentObject` that owns all project data. Every view reads from it; every mutation goes through it. No stale state, no sync bugs.
- **Domain Isolation.** `Clip`, `Track`, `Sequence`, and `MediaAsset` are plain Swift structs with zero UI dependencies. They can be serialized, tested, and reasoned about independently.
- **Service Layer.** `PlaybackEngine` handles all AVFoundation complexity. `MediaService` manages file access and bookmark resolution. `TimelineService` handles clip placement logic. Views never touch AVFoundation directly.
- **Coordinate Precision.** Timeline drag-and-drop uses named SwiftUI `CoordinateSpace` instances for pixel-accurate hit testing across nested scroll views.

## Getting Started

**Requirements:**
- macOS 12.0 Monterey or later
- Xcode 15.0 or later
- Apple Silicon recommended (Intel supported)

**Build and Run:**
1. Clone this repository
2. Open `Kino.xcodeproj` in Xcode
3. Select the "Kino" scheme and "My Mac" as the destination
4. Press `Cmd + R`

No SPM dependencies. No CocoaPods. No setup scripts. Just open and build.

## Keyboard Shortcuts

| Shortcut | Action |
|---|---|
| `Space` | Play / Pause |
| `Cmd + Z` | Undo |
| `Cmd + Shift + Z` | Redo |
| `Cmd + I` | Import Media |
| `Cmd + S` | Save Project |
| `Cmd + E` | Export Video |
| `Delete` | Delete Selected Clip |

## Roadmap

Kino is under active development. Here is what is planned for future releases:

| Status | Feature |
|---|---|
| Done | Multi-track timeline with drag-and-drop |
| Done | Linked audio/video clips |
| Done | Real-time waveform visualization |
| Done | Hardware-accelerated playback engine |
| Done | Video export pipeline |
| Done | Full undo/redo history |
| Done | Razor / Blade tool (Split clips) |
| Done | Clip edge trimming (Drag to resize) |
| Planned | Video transitions and effects |
| Planned | Text and title overlays |
| Planned | Audio volume keyframing |

## License

This project is licensed under the **PolyForm Shield License 1.0.0**.

You are free to read, study, and learn from this code. You may not use it to build a competing product or commercial service. See `LICENSE` for the full terms.

Interested in contributing? Read `CONTRIBUTING.md` for guidelines on bug reports, feature requests, and pull requests.

---
---

# Bahasa Indonesia

## Apa itu Kino

Kino adalah aplikasi penyunting video non-linear (NLE) yang dibangun sepenuhnya dalam bahasa Swift untuk macOS. Kino menggunakan SwiftUI untuk antarmuka, AVFoundation untuk pemrosesan media, dan CoreImage untuk komposisi visual secara real-time.

Kebanyakan editor yang mengklaim "native" sebenarnya adalah kompromi lintas platform yang dibungkus tampilan macOS. Kino berbeda. Setiap baris kodenya ditulis secara spesifik untuk macOS dan Apple Silicon, memanfaatkan sepenuhnya akselerasi perangkat keras untuk decoding, rendering berbasis Metal, dan integrasi mendalam yang hanya bisa dilakukan oleh aplikasi native sejati.

Hasilnya adalah editor yang terbuka dalam sekejap, merender tanpa patah-patah, dan menangani rekaman 4K sesuai kemampuan asli macOS.

## Mengapa Kino

Ada banyak editor video di luar sana. Berikut alasan Kino dibuat:

- **Benar-benar native.** Bukan aplikasi web yang menyamar. Bukan wrapper Electron. Bukan port dari Qt. Kino adalah 100% SwiftUI dan AppKit, dikompilasi langsung untuk macOS. Perilakunya seperti aplikasi Mac seharusnya: window snapping instan, dark mode bawaan, integrasi menu bar yang benar, dan dukungan Retina penuh tanpa konfigurasi tambahan.
- **Ringan.** Seluruh binary aplikasi berukuran di bawah 5MB. Tidak ada runtime yang dibundel, tidak ada browser tertanam, tidak ada layanan latar belakang yang menghabiskan RAM Anda. Kino terbuka dalam waktu kurang dari satu detik.
- **Dapat diprediksi.** Setiap operasi edit melewati Command Pattern. Artinya, state aplikasi selalu deterministik. Jika ada yang salah, tumpukan undo tahu persis cara membalikkannya.
- **Edukatif.** Basis kode sengaja dijaga agar tetap mudah dibaca. Jika Anda sedang belajar SwiftUI, AVFoundation, atau arsitektur aplikasi macOS, proyek ini berfungsi sebagai referensi dunia nyata yang jauh melampaui kompleksitas level tutorial.

## Fitur

| Fitur | Deskripsi |
|---|---|
| **Timeline Multi-Track** | Track video dan audio tanpa batas dengan komposisi Z-index yang benar. Track yang lebih tinggi menutupi track di bawahnya, persis seperti Premiere Pro dan Final Cut. |
| **Auto-Overlay** | Jatuhkan klip di atas klip lain dan Kino otomatis menempatkannya di track yang lebih tinggi, bukan menimpa. Tidak ada lagi penghapusan yang tidak disengaja. |
| **Tautan Audio/Video** | Mengimpor video otomatis mengekstrak dan menautkan track audionya. Gerakkan bersama-sama, atau klik kanan untuk memisahkan demi J/L cut yang presisi. |
| **Pemutaran GPU** | Mesin pemutar membungkus `AVMutableComposition` dengan instruksi `AVMutableVideoComposition` kustom untuk pencampuran opasitas, skala, dan transformasi secara real-time. |
| **Waveform Asli** | Gelombang suara dihasilkan dari data sampel PCM 16-bit asli melalui `AVAssetReader`, bukan garis acak. Track yang sunyi ditampilkan sebagai garis datar sehingga Anda langsung tahu. |
| **Cache Thumbnail** | Cache di memori yang thread-safe memastikan scroll ratusan aset media tetap 60fps. Thumbnail dan waveform dibuat sekali, lalu disajikan dari memori. |
| **Panel Inspector** | Sesuaikan posisi, skala, dan rotasi melalui slider yang presisi, atau geser langsung di kanvas untuk pengeditan visual. |
| **Pola Command** | Setiap aksi di timeline dibungkus dalam objek perintah yang dapat dibalik (`MoveClipCommand`, `SplitClipCommand`, `CompositeCommand`), menyediakan fondasi untuk riwayat undo/redo penuh. |

## Arsitektur

Kino mengikuti arsitektur berlapis yang bersih dengan pemisahan tanggung jawab secara ketat:

```
Kino/
  App/                  # Titik masuk aplikasi dan siklus hidup
  Core/
    Domain/             # Model data murni: Clip, Track, Sequence, MediaAsset
    Services/           # Logika bisnis: PlaybackEngine, MediaService, TimelineService
    Commands/           # Pola command: aksi reversibel untuk undo/redo
  UI/
    Timeline/           # Render timeline: ClipView, TrackView, TimelineRulerView
    Viewer/             # Kanvas video dengan handle transformasi interaktif
    Inspector/          # Panel properti untuk manipulasi klip
    MediaBrowser/       # Pustaka aset dengan dukungan drag-and-drop
    State/              # WorkspaceState - sumber kebenaran tunggal
    Workspace/          # Tata letak utama dan modal ekspor
```

**Keputusan desain utama:**

- **Sumber Kebenaran Tunggal.** `WorkspaceState` adalah `@EnvironmentObject` yang memiliki semua data proyek. Setiap view membaca darinya; setiap mutasi melewatinya. Tidak ada state basi, tidak ada bug sinkronisasi.
- **Isolasi Domain.** `Clip`, `Track`, `Sequence`, dan `MediaAsset` adalah struct Swift murni tanpa ketergantungan UI. Mereka bisa diserialisasi, diuji, dan dipahami secara independen.
- **Lapisan Servis.** `PlaybackEngine` menangani seluruh kompleksitas AVFoundation. `MediaService` mengelola akses file dan resolusi bookmark. `TimelineService` menangani logika penempatan klip. View tidak pernah menyentuh AVFoundation secara langsung.
- **Presisi Koordinat.** Drag-and-drop di timeline menggunakan instance `CoordinateSpace` bernama dari SwiftUI untuk hit testing yang akurat hingga tingkat piksel di dalam nested scroll view.

## Cara Memulai

**Persyaratan:**
- macOS 12.0 Monterey atau lebih baru
- Xcode 15.0 atau lebih baru
- Apple Silicon direkomendasikan (Intel tetap didukung)

**Build dan Jalankan:**
1. Clone repositori ini
2. Buka `Kino.xcodeproj` di Xcode
3. Pilih scheme "Kino" dan "My Mac" sebagai tujuan
4. Tekan `Cmd + R`

Tanpa dependensi SPM. Tanpa CocoaPods. Tanpa script setup. Cukup buka dan build.

## Pintasan Keyboard

| Pintasan | Aksi |
|---|---|
| `Space` | Putar / Jeda |
| `Cmd + Z` | Batalkan (Undo) |
| `Cmd + Shift + Z` | Ulangi (Redo) |
| `Cmd + I` | Impor Media |
| `Cmd + S` | Simpan Proyek |
| `Cmd + E` | Ekspor Video |
| `Delete` | Hapus Klip yang Dipilih |

## Peta Jalan (Roadmap)

Kino sedang dalam pengembangan aktif. Berikut rencana untuk rilis mendatang:

| Status | Fitur |
|---|---|
| Selesai | Timeline multi-track dengan drag-and-drop |
| Selesai | Klip audio/video yang tertaut |
| Selesai | Visualisasi waveform real-time |
| Selesai | Mesin playback terakselerasi perangkat keras |
| Selesai | Pipeline ekspor video |
| Selesai | Riwayat undo/redo penuh |
| Selesai | Alat pemotong / Razor tool (Split klip) |
| Selesai | Pemangkasan ujung klip (Clip trimming) |
| Direncanakan | Transisi dan efek video |
| Direncanakan | Overlay teks dan judul |
| Direncanakan | Keyframing volume audio |

## Lisensi

Proyek ini dilisensikan di bawah **PolyForm Shield License 1.0.0**.

Anda bebas membaca, mempelajari, dan mengambil ilmu dari kode ini. Anda tidak diperbolehkan menggunakannya untuk membangun produk pesaing atau layanan komersial. Lihat `LICENSE` untuk ketentuan lengkapnya.

Tertarik berkontribusi? Baca `CONTRIBUTING.md` untuk panduan mengenai laporan bug, permintaan fitur, dan pull request.
