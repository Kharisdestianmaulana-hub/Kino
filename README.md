<div align="center">
  <img src="Logo.png" alt="Kino Logo" width="200" height="200"/>
  <h1>Kino</h1>
</div>

---

## English Version

Kino is a native macOS video editing application (NLE) built with SwiftUI, AVFoundation, and CoreImage. Designed with a clean, professional interface inspired by industry-standard tools, Kino provides an intuitive timeline, multi-track support, and seamless hardware-accelerated playback.

### Features
* **Multi-Track Timeline:** Add and stack unlimited video and audio tracks.
* **Auto-Overlay System:** Dragging clips over one another intelligently places them on higher tracks rather than destructive overwriting.
* **Smart Audio/Video Linking:** Dropping a media asset automatically extracts its audio and links the clips together. Unlinking is supported via context menus.
* **Real-time Playback:** AVFoundation-powered playback engine for smooth rendering of overlapping layers, opacity, and scale transformations.
* **Waveform Visualization:** Audio clips automatically generate and render true waveforms using AVAssetReader.
* **Thumbnail Caching:** Highly optimized media browser utilizing an in-memory thumbnail cache for lag-free scrolling.
* **Inspector & Canvas:** Visually manipulate video position, scale, and rotation through standard UI controls or direct canvas dragging.

### Architecture
Kino embraces modern Swift paradigms:
* `WorkspaceState` acts as the central source of truth (EnvironmentObject).
* Command Pattern (e.g. `MoveClipCommand`, `AddClipCommand`, `CompositeCommand`) for robust undo/redo functionality.
* Custom SwiftUI coordinate spaces for precise hit-testing and dragging on the timeline.

---

## Versi Indonesia

Kino adalah aplikasi editor video (NLE) native untuk macOS yang dibangun menggunakan SwiftUI, AVFoundation, dan CoreImage. Didesain dengan antarmuka profesional yang rapi terinspirasi dari alat standar industri, Kino menyediakan timeline yang intuitif, dukungan banyak track, serta pemutaran mulus dengan akselerasi perangkat keras.

### Fitur
* **Timeline Multi-Track:** Tambahkan dan tumpuk track video serta audio tanpa batas.
* **Sistem Auto-Overlay:** Menyeret klip menimpa klip lain akan memindahkannya ke track yang lebih tinggi secara cerdas tanpa menghapus klip di bawahnya.
* **Tautan Audio/Video Pintar:** Menaruh aset media ke timeline akan secara otomatis mengekstrak audionya dan mengikat kedua klip tersebut. Fitur pisah (Unlink) tersedia melalui menu klik kanan.
* **Pemutaran Real-time:** Mesin pemutar bertenaga AVFoundation untuk merender lapisan yang tumpang tindih, opasitas, dan transformasi skala secara mulus.
* **Visualisasi Waveform:** Klip audio secara otomatis membaca dan menampilkan gelombang suara asli dari file menggunakan AVAssetReader.
* **Cache Thumbnail:** Media browser yang sangat teroptimasi menggunakan cache thumbnail di dalam memori agar proses scroll bebas lag.
* **Inspector & Canvas:** Mengubah posisi, skala, dan rotasi video dapat dilakukan melalui kontrol standar di panel atau menggeser langsung dari kanvas.

### Arsitektur
Kino menerapkan paradigma Swift modern:
* `WorkspaceState` bertindak sebagai sumber kebenaran utama (EnvironmentObject).
* Pola Command (contohnya `MoveClipCommand`, `AddClipCommand`, `CompositeCommand`) yang memudahkan implementasi fitur undo/redo.
* Sistem koordinat kustom di SwiftUI untuk kalkulasi area klik dan geser di dalam timeline secara presisi.
