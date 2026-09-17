<div align="center">
  <img src="Logo.png" alt="Kino Logo" width="200" height="200"/>
  <h1>Kino Video Editor</h1>
  <p><em>A lightning-fast, native macOS Non-Linear Editor (NLE) built for the Apple Silicon era.</em></p>
</div>

---

### Screenshots

<div align="center">
  <img src="Screenshots/Screenshot1.png" alt="Kino Editor - Main Workspace" width="800"/>
  <br/><br/>
  <img src="Screenshots/Screenshot2.png" alt="Kino Editor - Timeline & Playback" width="800"/>
</div>

---

## 🇬🇧 English Version

Kino is a powerful, highly optimized native macOS non-linear video editing application. It was built completely from the ground up using modern Apple frameworks such as **SwiftUI**, **AVFoundation**, and **CoreImage**. 

Unlike web-based editors or Electron wrappers, Kino is designed to squeeze every ounce of performance out of macOS and Apple Silicon. With a clean, professional, dark-themed interface inspired by industry standards like Final Cut Pro and Adobe Premiere Pro, Kino offers a robust timeline, infinite tracks, and hardware-accelerated rendering.

### 🌟 Key Features & Workflows

#### 1. Infinite Multi-Track Timeline
Kino moves away from rigid single-track constraints. You can add, stack, and organize unlimited video and audio tracks. The rendering engine natively respects the Z-index stacking order: clips on higher tracks (e.g., Video 3) will visually occlude clips on lower tracks (e.g., Video 1).

#### 2. Intelligent Auto-Overlay System
Say goodbye to destructive editing. When you drag a new video clip onto the timeline and drop it over an existing clip, Kino will intelligently calculate the space and automatically push the new clip to an unoccupied, higher track (overlay) instead of deleting or overwriting the clip underneath it.

#### 3. Smart Audio/Video Linking
Media assets are rarely silent. When you drop a video file onto the timeline, Kino's `MediaService` automatically extracts the embedded audio track. It then creates two separate clips (one video, one audio) and links them together via a `linkedClipID`. 
- **Move Together:** Dragging the video automatically drags the audio with it.
- **Unlink for J/L Cuts:** You can easily right-click and select "Unlink" to freely manipulate the audio and video independently.

#### 4. Hardware-Accelerated Playback Engine
At the heart of Kino lies the `PlaybackEngine`, a complex wrapper around `AVMutableComposition` and `AVPlayerItem`.
- It processes opacity blending, dynamic scaling, and transformations in real-time.
- It automatically handles silent tracks and dynamically protects against out-of-bounds `CMTimeRange` errors that crash standard AVFoundation setups.

#### 5. True Audio Waveform Visualization
Kino doesn't use fake, randomized waveform graphics. The `WaveformGenerator` uses `AVAssetReader` to delve deep into the raw media file, extracting 16-bit PCM audio samples. It then downsamples millions of data points efficiently using a stride algorithm to generate a 100% accurate, visually distinct green waveform for every audio clip on your timeline.

#### 6. In-Memory Thumbnail Caching
Scrolling through hundreds of 4K video assets can bring standard applications to their knees. Kino utilizes a custom, thread-safe `ThumbnailCache` coupled with Swift's asynchronous `Task` queues. Once a video thumbnail or waveform is generated, it is cached in memory, ensuring buttery-smooth 60fps scrolling across the entire app.

#### 7. Inspector & Interactive Canvas
Customize your media on the fly. You can alter the X/Y positioning, scale, and rotation of any video clip through traditional UI sliders in the Inspector panel, or you can simply click and drag the video directly within the Canvas window for visual precision.

#### 8. Command Pattern Architecture (Undo/Redo Ready)
Every single action inside the timeline (moving a clip, adding a track, splitting a media file) is strictly encapsulated within a Command Object (e.g., `MoveClipCommand`, `SplitClipCommand`, `CompositeCommand`). This strict adherence to the Command Pattern ensures state safety and provides the exact foundation needed for an infinite Undo/Redo history stack.

---

### 🏗 Architecture & Tech Stack
Kino is a testament to what is possible with modern Swift 6.
- **State Management:** Kino abandons messy callbacks and delegates in favor of SwiftUI's `@EnvironmentObject`. The `WorkspaceState` class acts as the single source of truth for the entire application.
- **Domain Layer Isolation:** Core business logic is contained within pure Swift structs (`Clip`, `Track`, `Sequence`, `MediaAsset`). They are entirely decoupled from the UI.
- **Service Layer:** Heavy I/O and multimedia tasks are separated into dedicated services like `TimelineService`, `MediaService`, and `PlaybackEngine`.
- **Custom Coordinate Spaces:** Drag-and-drop mechanics in the timeline are calculated using customized SwiftUI `CoordinateSpace` geometries, allowing for pixel-perfect frame dropping and intersection detection.

---

### ⚖️ License & Contributing
This repository is licensed under the **PolyForm Shield License 1.0.0**. 

**What does this mean?**
You are highly encouraged to read, study, clone, and learn from this source code! It serves as an open textbook for building complex AVFoundation architectures in SwiftUI. 
However, **you may not modify, distribute, or host this code to create a competing commercial product or service.** 

Please refer to the `LICENSE` file for full legal terminology. If you are interested in fixing bugs or contributing to the non-commercial improvement of this project, please read `CONTRIBUTING.md`.

---
---

## 🇮🇩 Versi Indonesia

Kino adalah aplikasi perangkat lunak penyunting video non-linear (NLE) yang sangat optimal dan dirancang khusus (native) untuk ekosistem macOS. Aplikasi ini dibangun dari nol menggunakan kerangka kerja (framework) modern Apple, yakni **SwiftUI**, **AVFoundation**, dan **CoreImage**.

Berbeda dengan editor video berbasis web atau aplikasi hasil bungkus (wrapper) Electron, Kino dirancang untuk memeras setiap tetes performa dari prosesor Apple Silicon dan macOS. Dengan antarmuka bertema gelap yang bersih dan profesional—terinspirasi dari standar industri seperti Final Cut Pro dan Adobe Premiere Pro—Kino menawarkan timeline yang tangguh, track tanpa batas, dan proses render yang diakselerasi oleh perangkat keras (GPU).

### 🌟 Fitur Utama & Alur Kerja

#### 1. Timeline Multi-Track Tanpa Batas
Kino membebaskan Anda dari batasan satu track konvensional. Anda dapat menambahkan, menumpuk, dan mengatur track video maupun audio dalam jumlah tak terbatas. Mesin render secara native menghormati urutan tumpukan (Z-index): klip di track yang lebih tinggi (misal: Video 3) akan secara visual menutupi klip di track bawahnya (misal: Video 1).

#### 2. Sistem Auto-Overlay Cerdas
Katakan selamat tinggal pada pengeditan destruktif. Ketika Anda menarik klip video baru ke timeline dan menjatuhkannya di atas klip yang sudah ada, Kino akan secara cerdas menghitung ruang kosong dan otomatis memindahkan klip baru tersebut ke track kosong di atasnya (overlay), alih-alih menghapus atau menimpa klip di bawahnya.

#### 3. Tautan Audio/Video Pintar (Smart Linking)
File media jarang sekali tidak memiliki suara. Saat Anda menaruh file video ke timeline, `MediaService` Kino akan secara otomatis mengekstrak track audio yang tertanam di dalamnya. Sistem lalu membuat dua klip terpisah (satu video, satu audio) dan mengikat keduanya menggunakan `linkedClipID`.
- **Bergerak Bersama:** Menggeser video akan otomatis membawa klip audionya.
- **Pisahkan untuk Potongan J/L (J/L Cuts):** Anda dapat dengan mudah melakukan klik kanan dan memilih "Unlink" untuk memanipulasi klip audio dan video secara terpisah.

#### 4. Mesin Pemutar Terakselerasi Perangkat Keras
Jantung dari Kino adalah `PlaybackEngine`, sebuah sistem kompleks yang membungkus `AVMutableComposition` dan `AVPlayerItem`.
- Sistem ini memproses pencampuran opasitas (transparansi), skala dinamis, dan transformasi secara seketika (real-time).
- Sistem ini juga otomatis menangani track yang hening/bisu dan melindungi aplikasi dari error durasi (`CMTimeRange`) yang sering membuat aplikasi AVFoundation biasa mengalami *crash*.

#### 5. Visualisasi Waveform Audio Asli
Kino tidak menggunakan grafik gelombang suara acak atau palsu. `WaveformGenerator` menggunakan `AVAssetReader` untuk menggali jauh ke dalam file media mentah, mengekstrak sampel audio PCM 16-bit. Sistem lalu menyusutkan jutaan titik data ini menggunakan algoritma lompatan (stride) yang efisien untuk menghasilkan gelombang hijau yang 100% akurat secara visual untuk setiap klip audio di timeline Anda.

#### 6. Sistem Cache Thumbnail di Memori
Menggulir (scrolling) ratusan aset video 4K dapat membuat aplikasi standar menjadi sangat lambat. Kino mengatasi hal ini dengan menggunakan `ThumbnailCache` kustom yang digabungkan dengan antrean `Task` asynchronous milik Swift. Setelah thumbnail video atau waveform audio dibuat, hasilnya disimpan di memori, memastikan proses scroll 60fps yang sangat mulus di seluruh bagian aplikasi.

#### 7. Inspector & Manipulasi Canvas Interaktif
Sesuaikan media Anda secara langsung. Anda dapat mengubah posisi X/Y, ukuran (skala), dan rotasi klip video apa pun melalui panel kontrol Inspector standar, atau Anda bisa langsung mengklik dan menggeser video secara interaktif di dalam layar Canvas untuk presisi visual yang instan.

#### 8. Arsitektur Pola Perintah (Siap untuk Undo/Redo)
Setiap tindakan di dalam timeline (memindahkan klip, menambah track, memotong media) dibungkus secara ketat di dalam Objek Perintah (contohnya: `MoveClipCommand`, `SplitClipCommand`, `CompositeCommand`). Kepatuhan ketat terhadap Pola Perintah (Command Pattern) ini memastikan keamanan data dan memberikan fondasi yang sangat kuat untuk mengimplementasikan riwayat Undo/Redo tanpa batas di masa mendatang.

---

### 🏗 Arsitektur & Teknologi (Tech Stack)
Kino adalah bukti nyata tentang apa yang bisa dicapai dengan bahasa Swift 6 modern.
- **Manajemen State (Kondisi):** Kino meninggalkan penggunaan callback dan delegate yang berantakan, dan beralih menggunakan `@EnvironmentObject` dari SwiftUI. Kelas `WorkspaceState` bertindak sebagai sumber kebenaran tunggal (Single Source of Truth) untuk seluruh aplikasi.
- **Isolasi Lapisan Domain:** Logika bisnis inti dibungkus dalam struct Swift murni (`Clip`, `Track`, `Sequence`, `MediaAsset`). Mereka sepenuhnya terpisah dari tampilan UI (antarmuka).
- **Lapisan Servis:** Tugas berat seperti baca-tulis file (I/O) dan pemrosesan multimedia dipisah ke dalam servis khusus seperti `TimelineService`, `MediaService`, dan `PlaybackEngine`.
- **Sistem Koordinat Kustom:** Mekanika seret-dan-lepas (drag-and-drop) di timeline dihitung menggunakan geometri `CoordinateSpace` kustom bawaan SwiftUI, memungkinkan deteksi persimpangan (intersection) antar frame dengan sangat akurat.

---

### ⚖️ Lisensi & Kontribusi
Repositori ini dilisensikan di bawah **PolyForm Shield License 1.0.0**.

**Apa artinya ini?**
Anda sangat dianjurkan untuk membaca, mempelajari, mengkloning, dan mengambil ilmu dari kode sumber ini! Proyek ini berfungsi sebagai buku teks terbuka untuk membangun arsitektur AVFoundation yang kompleks di dalam SwiftUI.
Namun, **Anda dilarang keras memodifikasi, mendistribusikan, atau menyalin kode ini untuk membuat produk komersial atau layanan pesaing.**

Silakan baca file `LICENSE` untuk terminologi hukum selengkapnya. Jika Anda tertarik untuk memperbaiki bug atau berkontribusi untuk perbaikan non-komersial pada proyek ini, silakan baca file `CONTRIBUTING.md`.
