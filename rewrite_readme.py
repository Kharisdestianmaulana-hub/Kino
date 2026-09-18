import re

with open("README.md", "r", encoding="utf-8") as f:
    content = f.read()

# 1. Fix hype words in header
content = content.replace("A native macOS video editor. Zero compromises.", "A native macOS video editor built for learning. Filesystem-first.")
content = content.replace("No Electron. No compromises.", "No cross-platform wrappers.")

# 2. English "What is Kino"
en_what_old = """## What is Kino

Kino is a non-linear video editor (NLE) built entirely in Swift for macOS. It uses SwiftUI for the interface, AVFoundation for media processing, and CoreImage for real-time compositing.

Most "native" editors are actually cross-platform compromises wrapped in a macOS skin. Kino is different. Every line of code was written specifically for macOS and Apple Silicon, taking full advantage of hardware-accelerated decoding, Metal-backed rendering, and the tight integration that only a true native app can provide.

Furthermore, Kino introduces a **Filesystem-First** and **Modular Feature Architecture**. It doesn't trap your media in hidden libraries, and it doesn't force bloatware. The lightweight "Core" provides a complete foundational editing workflow, while 14 advanced optional modules (like Professional Color, Audio Pro, and Advanced Subtitles) can be plugged in exactly when you need them.

The result is an editor that launches instantly, renders without stutter, and scales with your needs."""

en_what_new = """## What is Kino

Kino is a non-linear video editor (NLE) built entirely in Swift for macOS. It uses SwiftUI for the interface, AVFoundation for media processing, and CoreImage for compositing.

While professional NLEs like Final Cut Pro set the standard for native macOS performance, Kino differentiates itself through a filesystem-first approach, modular architecture, and an intentionally educational codebase. Every line of code is written specifically for macOS, taking advantage of hardware-accelerated decoding and Metal-backed rendering.

Furthermore, Kino introduces a **Filesystem-First** and **Modular Feature Architecture**. It doesn't trap your media in hidden libraries, and it doesn't force unnecessary features. The lightweight "Core" provides a foundational editing workflow, while 14 advanced optional modules (like Professional Color, Audio Pro, and Advanced Subtitles) can be plugged in when you need them.

The result is an editor designed for quick launch times, smooth rendering, and scalability."""
content = content.replace(en_what_old, en_what_new)

# 3. English "Why Kino"
en_why_old = """- **Truly native.** Not a web app in disguise. Not an Electron wrapper. Not a Qt port. Kino is 100% SwiftUI and AppKit, compiled directly for macOS. It behaves like a Mac app should: instant window snapping, native dark mode, proper menu bar integration, and full Retina support without extra configuration.
- **Lightweight & Modular.** The entire application binary is incredibly small. There are no bundled runtimes or background services consuming your RAM. Kino launches in under a second. With our modular architecture, you only install the advanced tools you actually use, ensuring the core editor never becomes slow or bloated.
- **Filesystem-First & Non-Destructive.** Source media belongs to you. Kino does not create hidden duplicate media libraries. Your original video, audio, and image files remain untouched in your chosen folders, and every timeline operation is strictly non-destructive.
- **Predictable.** Every edit operation goes through the Command Pattern. This means the application state is always deterministic. If something goes wrong, the undo stack knows exactly how to reverse it.
- **Educational.** The codebase is deliberately kept clean and approachable. If you are learning SwiftUI, AVFoundation, or macOS app architecture, this project serves as a real-world reference that goes far beyond tutorial-level complexity."""

en_why_new = """- **Native macOS Experience.** Built entirely with SwiftUI and AppKit, compiled directly for macOS. It integrates naturally with the OS, supporting native window management, dark mode, and Retina displays.
- **Lightweight & Modular.** The application binary is kept small. With our modular architecture, you only install the advanced tools you actually use, helping the core editor remain fast and focused.
- **Filesystem-First & Non-Destructive.** Source media belongs to you. Kino does not create hidden duplicate media libraries. Your original video, audio, and image files remain untouched in your chosen folders, and every timeline operation is strictly non-destructive. Under the hood, the `MediaService` uses Security-Scoped Bookmarks to maintain persistent references to your files across app launches without copying the raw data.
- **Predictable.** Every edit operation goes through the Command Pattern. This means the application state is deterministic. If something goes wrong, the undo stack knows exactly how to reverse it.
- **Educational.** The codebase is deliberately kept clean and approachable. If you are learning SwiftUI, AVFoundation, or macOS app architecture, this project serves as an open, real-world reference for building complex native applications."""
content = content.replace(en_why_old, en_why_new)

# 4. Indonesian "Apa itu Kino"
id_what_old = """## Apa itu Kino

Kino adalah aplikasi penyunting video non-linear (NLE) yang dibangun sepenuhnya dalam bahasa Swift untuk macOS. Kino menggunakan SwiftUI untuk antarmuka, AVFoundation untuk pemrosesan media, dan CoreImage untuk komposisi visual secara real-time.

Kebanyakan editor yang mengklaim "native" sebenarnya adalah kompromi lintas platform yang dibungkus tampilan macOS. Kino berbeda. Setiap baris kodenya ditulis secara spesifik untuk macOS dan Apple Silicon, memanfaatkan sepenuhnya akselerasi perangkat keras untuk decoding, rendering berbasis Metal, dan integrasi mendalam yang hanya bisa dilakukan oleh aplikasi native sejati.

Lebih dari itu, Kino memperkenalkan arsitektur **Filesystem-First** dan **Fitur Modular**. Aplikasi ini tidak mengurung aset media Anda di dalam pustaka tersembunyi, dan tidak memaksa Anda mengunduh fitur yang tidak terpakai. Bagian "Core" (Inti) yang super ringan menyediakan alur kerja pengeditan dasar yang lengkap, sementara 14 modul lanjutan opsional (seperti Warna Profesional, Audio Pro, dan Subtitle Lanjutan) dapat dipasang hanya ketika Anda membutuhkannya.

Hasilnya adalah editor yang terbuka dalam sekejap, merender tanpa patah-patah, dan dapat dikembangkan sesuai kebutuhan Anda."""

id_what_new = """## Apa itu Kino

Kino adalah aplikasi penyunting video non-linear (NLE) yang dibangun sepenuhnya dalam bahasa Swift untuk macOS. Kino menggunakan SwiftUI untuk antarmuka, AVFoundation untuk pemrosesan media, dan CoreImage untuk komposisi visual.

Meski editor profesional seperti Final Cut Pro telah menetapkan standar performa native di macOS, Kino membedakan dirinya melalui pendekatan filesystem-first, arsitektur modular, dan basis kode yang sengaja dibuat edukatif. Setiap baris kode ditulis spesifik untuk macOS, memanfaatkan akselerasi perangkat keras untuk decoding dan rendering berbasis Metal.

Lebih dari itu, Kino memperkenalkan arsitektur **Filesystem-First** dan **Fitur Modular**. Aplikasi ini tidak mengurung aset media Anda di dalam pustaka tersembunyi, dan tidak menyertakan fitur yang belum tentu terpakai secara bawaan. Bagian "Core" (Inti) menyediakan alur kerja pengeditan dasar, sementara 14 modul lanjutan opsional (seperti Warna Profesional, Audio Pro, dan Subtitle Lanjutan) dapat dipasang hanya ketika Anda membutuhkannya.

Hasilnya adalah editor yang dirancang untuk dapat terbuka dengan cepat, merender dengan mulus, dan berskala sesuai kebutuhan Anda."""
content = content.replace(id_what_old, id_what_new)

# 5. Indonesian "Mengapa Kino"
id_why_old = """- **Benar-benar native.** Bukan aplikasi web yang menyamar. Bukan wrapper Electron. Bukan port dari Qt. Kino adalah 100% SwiftUI dan AppKit, dikompilasi langsung untuk macOS. Perilakunya seperti aplikasi Mac seharusnya: window snapping instan, dark mode bawaan, integrasi menu bar yang benar, dan dukungan Retina penuh tanpa konfigurasi tambahan.
- **Ringan & Modular.** Seluruh binary aplikasi berukuran sangat kecil. Tidak ada runtime yang dibundel atau layanan latar belakang yang menghabiskan RAM Anda. Kino terbuka dalam waktu kurang dari satu detik. Melalui arsitektur modular, Anda hanya memasang fitur lanjutan yang benar-benar Anda pakai, memastikan editor utama tidak pernah menjadi lambat atau membengkak.
- **Filesystem-First & Non-Destruktif.** Aset media adalah milik Anda. Kino tidak pernah membuat salinan duplikat file media secara diam-diam. Video, audio, dan gambar asli tetap utuh di folder asli Anda, dan setiap proses editing pada timeline dijamin non-destruktif (tidak merusak file asli).
- **Dapat diprediksi.** Setiap operasi edit melewati Command Pattern. Artinya, state aplikasi selalu deterministik. Jika ada yang salah, tumpukan undo tahu persis cara membalikkannya.
- **Edukatif.** Basis kode sengaja dijaga agar tetap mudah dibaca. Jika Anda sedang belajar SwiftUI, AVFoundation, atau arsitektur aplikasi macOS, proyek ini berfungsi sebagai referensi dunia nyata yang jauh melampaui kompleksitas level tutorial."""

id_why_new = """- **Pengalaman Native macOS.** Dibangun sepenuhnya dengan SwiftUI dan AppKit, dikompilasi langsung untuk macOS. Aplikasi ini terintegrasi secara natural dengan OS, mendukung manajemen jendela bawaan, mode gelap, dan layar Retina.
- **Ringan & Modular.** Ukuran binary aplikasi dijaga agar tetap kecil. Melalui arsitektur modular, Anda hanya memasang fitur lanjutan yang benar-benar Anda pakai, membantu editor utama tetap cepat dan fokus pada hal esensial.
- **Filesystem-First & Non-Destruktif.** Aset media adalah milik Anda. Kino tidak pernah membuat salinan duplikat file media secara diam-diam. Video, audio, dan gambar asli tetap utuh di folder asli Anda, dan setiap proses editing pada timeline dijamin non-destruktif (tidak merusak file asli). Di balik layar, `MediaService` menggunakan *Security-Scoped Bookmarks* untuk menyimpan referensi persisten ke file Anda lintas sesi tanpa harus menyalin data mentahnya.
- **Dapat diprediksi.** Setiap operasi edit melewati Command Pattern. Artinya, state aplikasi selalu deterministik. Jika ada yang salah, tumpukan undo tahu persis cara membalikkannya.
- **Edukatif.** Basis kode sengaja dijaga agar tetap mudah dibaca. Jika Anda sedang belajar SwiftUI, AVFoundation, atau arsitektur aplikasi macOS, proyek ini berfungsi sebagai referensi terbuka di dunia nyata untuk membangun aplikasi native yang kompleks."""
content = content.replace(id_why_old, id_why_new)

# 6. Status labels in Roadmap
content = content.replace("| Done |", "| ✅ Stable |")
content = content.replace("| Planned |", "| 📋 Planned |")
content = content.replace("| Selesai |", "| ✅ Stable |")
content = content.replace("| Direncanakan |", "| 📋 Planned |")

# 7. Add Project Status & Limitations and Update ToC
en_limitations = """## Project Status & Limitations

Kino is currently moving towards its v1.0 release. It is being developed by a small team as an open, educational project, rather than a massive enterprise application.

- **Media Support**: While AVFoundation supports many formats, testing has been primarily limited to standard H.264/HEVC (`.mp4`, `.mov`) files. Professional formats (like ProRes or RAW) have not been extensively benchmarked.
- **Stability**: As an active project, you may encounter bugs. It is not yet recommended for mission-critical production work.

"""
id_limitations = """## Status Proyek & Keterbatasan Saat Ini

Kino saat ini sedang dalam perjalanan menuju rilis v1.0. Proyek ini dikembangkan dalam skala kecil sebagai wadah edukasi terbuka, bukan perangkat lunak perusahaan skala besar.

- **Dukungan Media**: Meski AVFoundation mendukung banyak format, pengujian sejauh ini masih terbatas pada file standar H.264/HEVC (`.mp4`, `.mov`). Format profesional (seperti ProRes atau RAW) belum melalui uji performa (benchmark) secara luas.
- **Stabilitas**: Karena masih dalam tahap pengembangan aktif, Anda mungkin akan menemui bug. Belum direkomendasikan untuk pekerjaan produksi yang sangat kritis.

"""

content = content.replace("## Roadmap\n", en_limitations + "## Roadmap\n")
content = content.replace("## Peta Jalan (Roadmap)\n", id_limitations + "## Peta Jalan (Roadmap)\n")

# Update ToC EN
toc_en_old = """  - [Keyboard Shortcuts](#keyboard-shortcuts)
  - [Roadmap](#roadmap)"""
toc_en_new = """  - [Keyboard Shortcuts](#keyboard-shortcuts)
  - [Project Status & Limitations](#project-status--limitations)
  - [Roadmap](#roadmap)"""
content = content.replace(toc_en_old, toc_en_new)

# Update ToC ID
toc_id_old = """  - [Pintasan Keyboard](#pintasan-keyboard)
  - [Peta Jalan](#peta-jalan-roadmap)"""
toc_id_new = """  - [Pintasan Keyboard](#pintasan-keyboard)
  - [Status Proyek & Keterbatasan Saat Ini](#status-proyek--keterbatasan-saat-ini)
  - [Peta Jalan](#peta-jalan-roadmap)"""
content = content.replace(toc_id_old, toc_id_new)

# 8. Mini-FAQ to License
en_license_add = """

**Mini-FAQ:**
- **Can I use this code for my own personal/commercial project?**
  Yes, as long as your project is NOT a competing video editing product or service."""
content = content.replace("See `LICENSE` for the full terms.", "See `LICENSE` for the full terms." + en_license_add)

id_license_add = """

**Mini-FAQ:**
- **Bolehkah saya pakai kode ini untuk project pribadi/komersial saya sendiri?**
  Boleh, selama proyek Anda BUKAN produk atau layanan aplikasi penyunting video pesaing."""
content = content.replace("Lihat `LICENSE` untuk ketentuan lengkapnya.", "Lihat `LICENSE` untuk ketentuan lengkapnya." + id_license_add)


with open("README.md", "w", encoding="utf-8") as f:
    f.write(content)
