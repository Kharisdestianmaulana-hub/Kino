<div align="center">
  <img src="Logo.png" alt="Kino Logo" width="200" height="200"/>
  <h1>Kino</h1>
</div>

---

## English Version

Kino is a powerful, native macOS non-linear video editing application (NLE) built completely from the ground up using modern Apple frameworks such as **SwiftUI**, **AVFoundation**, and **CoreImage**. 

Designed with a clean, professional, and dark-themed interface inspired by industry-standard tools like Final Cut Pro and Premiere Pro, Kino provides an intuitive timeline, multi-track support, and seamless hardware-accelerated playback. Our goal is to provide a fluid, lag-free editing experience by maximizing Apple Silicon performance.

### Key Features & Capabilities

* **Infinite Multi-Track Timeline:** Add, stack, and organize unlimited video and audio tracks. The rendering engine respects Z-index stacking natively, allowing complex composition.
* **Auto-Overlay System:** Dragging clips over one another intelligently places them on higher, unoccupied tracks rather than causing destructive overwriting of existing clips.
* **Smart Audio/Video Linking:** Dropping a media asset automatically extracts its audio track (if it exists) and creates linked clips. Linked clips move in tandem but can be manually unlinked via the context menu for J/L cuts.
* **Hardware-Accelerated Playback:** The `PlaybackEngine` is powered by `AVMutableComposition` and `AVMutableVideoComposition`, ensuring that overlapping layers, opacity blending, and scale transformations are rendered efficiently via the GPU.
* **True Audio Waveforms:** Audio clips automatically extract 16-bit PCM samples using `AVAssetReader` to generate and display true, accurate green waveforms, instantly letting you identify silent tracks.
* **Ultra-Fast Thumbnail Caching:** The media browser is heavily optimized. It utilizes a custom in-memory `ThumbnailCache` and intelligent GCD queues to ensure that scrolling through hundreds of 4K video assets remains completely lag-free.
* **Inspector & Canvas Manipulation:** Visually manipulate video properties. You can change X/Y position, scale, and rotation through standard UI controls in the Inspector panel, or by clicking and dragging the video directly in the Canvas view.
* **Non-Destructive Command Pattern:** Every action (moving, splitting, deleting) is encapsulated in a Command struct (`MoveClipCommand`, `CompositeCommand`), paving the way for a robust Undo/Redo architecture.

### Architecture Overview
Kino embraces modern Swift 6 paradigms:
* **State Management:** `WorkspaceState` acts as the central source of truth (using `@EnvironmentObject`), ensuring the UI stays perfectly synchronized with the underlying domain models.
* **Domain Layer:** Pure Swift structs (`Clip`, `Track`, `Sequence`, `MediaAsset`) handle business logic independently of the view layer.
* **Services:** Separated service classes (`TimelineService`, `MediaService`, `PlaybackEngine`) manage heavy lifting like file I/O, AVFoundation routing, and state mutations.
* **Custom Coordinate Systems:** Utilizes SwiftUI's `CoordinateSpace` for precise drop hit-testing and dragging calculations across the entire timeline grid.

### License & Contributing
This repository is licensed under the **PolyForm Shield License 1.0.0**. 
You are highly encouraged to read, study, and learn from this source code! However, you may not modify or distribute this code to create a competing product or service. Please refer to the `LICENSE` file for more details. 

For contribution guidelines, please see the `CONTRIBUTING.md` file.

---

## Versi Indonesia

Kino adalah aplikasi editor video non-linear (NLE) canggih yang dirancang khusus (native) untuk macOS. Aplikasi ini dibangun dari nol sepenuhnya menggunakan teknologi modern Apple seperti **SwiftUI**, **AVFoundation**, dan **CoreImage**.

Didesain dengan antarmuka bertema gelap yang profesional—terinspirasi dari standar industri perfileman seperti Final Cut Pro dan Premiere Pro—Kino menyediakan timeline yang intuitif, dukungan banyak track, serta pemutaran (playback) mulus yang memanfaatkan akselerasi perangkat keras secara maksimal (khususnya untuk Apple Silicon).

### Fitur Utama & Kemampuan

* **Timeline Multi-Track Tanpa Batas:** Tambahkan dan susun track video serta audio sesuka hati Anda. Mesin perender secara otomatis memproses urutan tumpukan (Z-index) sehingga memfasilitasi komposisi yang kompleks.
* **Sistem Auto-Overlay Cerdas:** Menyeret klip baru ke atas klip yang sudah ada tidak akan menghancurkan klip di bawahnya. Sistem akan secara otomatis mencarikan track kosong di atasnya (overlay).
* **Tautan Audio/Video Otomatis:** Saat file video ditarik ke timeline, Kino akan mengekstrak track audionya secara otomatis dan membuat kedua klip tersebut saling terikat (Linked Clips). Fitur pisah klip (Unlink) juga tersedia melalui klik kanan.
* **Pemutaran Real-time Bertenaga GPU:** Mengandalkan `AVMutableComposition` di dalam `PlaybackEngine`, memastikan lapisan video yang bertumpuk, transparansi, dan perubahan ukuran dirender dengan sangat efisien oleh kartu grafis.
* **Visualisasi Waveform Akurat:** Klip audio secara otomatis membaca data PCM 16-bit menggunakan `AVAssetReader` untuk menggambar gelombang suara hijau yang 100% nyata. Sangat berguna untuk mendeteksi video yang tidak memiliki suara.
* **Sistem Cache Thumbnail Super Cepat:** Panel Media Browser telah dioptimalkan secara ekstrim. Sistem menggunakan `ThumbnailCache` di memori agar proses scroll (menggulir) ratusan file video 4K tetap mulus tanpa lag sedikit pun.
* **Manipulasi Langsung di Canvas & Inspector:** Ubah posisi (X/Y), ukuran (skala), dan rotasi video menggunakan panel Inspector, atau cukup klik dan geser video secara langsung di layar Canvas.
* **Sistem Perintah (Command Pattern):** Setiap tindakan pengguna dibungkus dalam Command (`MoveClipCommand`, `CompositeCommand`) yang menjamin keamanan data dan siap untuk fitur Undo/Redo di masa mendatang.

### Gambaran Arsitektur
Kino sepenuhnya menerapkan konsep modern Swift:
* **Manajemen State:** Menggunakan `WorkspaceState` sebagai pusat data tunggal (`@EnvironmentObject`), memastikan antarmuka selalu sinkron dengan data di balik layar.
* **Lapisan Domain:** Struktur murni Swift (`Clip`, `Track`, `Sequence`) menangani logika tanpa bergantung pada antarmuka grafis.
* **Servis:** Modul terpisah (`TimelineService`, `MediaService`) menangani tugas berat seperti manajemen file dan sistem pemutaran AVFoundation.
* **Sistem Koordinat SwiftUI:** Menggunakan `CoordinateSpace` khusus untuk mengkalkulasi area klik dan titik lepas (drop) di seluruh area timeline dengan tingkat presisi tinggi.

### Lisensi & Kontribusi
Repositori ini dilisensikan di bawah **PolyForm Shield License 1.0.0**.
Anda sangat diperbolehkan dan dipersilakan untuk melihat, mempelajari, dan menelaah seluruh kode sumber (source code) aplikasi ini! Namun, Anda dilarang memodifikasi atau mendistribusikan kode ini untuk membuat produk atau layanan pesaing. Silakan baca file `LICENSE` untuk informasi hukum selengkapnya.

Jika Anda tertarik untuk berkontribusi (seperti melaporkan bug), silakan baca panduannya di file `CONTRIBUTING.md`.
