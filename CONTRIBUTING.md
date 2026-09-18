# Contributing to Kino

Thank you for your interest in contributing to Kino. Kino is a high-performance, native macOS non-linear video editing application (NLE). 

Because Kino is licensed under the PolyForm Shield License 1.0.0, the rules of engagement differ from standard open-source projects (such as those under MIT or GPL). This document outlines the legal boundaries, architectural guidelines, and technical standards required for contributing.

Please read this document thoroughly before submitting any Issues or Pull Requests.

Before starting any development, you are **required** to read the relevant architecture documentation in the [`Docs/`](Docs/) folder (such as `Docs/ARCHITECTURE.md`, `Docs/MODULE_SYSTEM.md`, and `Docs/PRD.md`). Understanding the modular architecture is mandatory before writing code.

> **Note:** Kino is currently in active development heading towards its v1.0 release. Contributors should be prepared for ongoing architectural changes, shifting module APIs, and areas of the codebase that are not yet fully stabilized.

---

## 1. Licensing and Legal Compliance

Kino is distributed under the PolyForm Shield License 1.0.0. This license grants specific rights and imposes strict limitations:

### Permitted Actions
*   **Educational Study**: You have unrestricted access to read, analyze, and learn from the source code. The repository serves as a reference implementation for SwiftUI, AVFoundation, and CoreImage on macOS.
*   **Personal Use**: You may compile, build, and run the application on your own local machines for personal video editing purposes.
*   **Internal Modification**: You may modify the source code for your own personal use.

### Strictly Prohibited Actions
*   **Commercial Competition**: You may not create, distribute, or operate a commercial product that competes with Kino.
*   **Service Distribution**: You may not offer the software or modified versions of the software as a service to third parties.

### Contributor License Agreement (CLA)
By submitting a Pull Request to this repository, you explicitly agree that your contributions will be licensed under the PolyForm Shield License 1.0.0. You also grant the maintainers the irrevocable right to include, distribute, and modify your submitted code within the official Kino product.

---

## 2. Issue Reporting Guidelines

Detailed and reproducible issue reports are critical to maintaining the stability of Kino. When opening an issue, please use the provided templates and ensure the following information is included:

1.  **Environment Details**:
    *   macOS Version (e.g., macOS 14.5)
    *   Hardware Specifications (e.g., Apple M2, 16GB Unified Memory)
    *   Xcode Version (if compiling from source)
2.  **Reproduction Steps**: A deterministic, step-by-step list of actions required to reproduce the anomaly.
3.  **Expected vs. Actual Behavior**: A clear distinction between the intended outcome and the observed failure.
4.  **Diagnostic Logs**: If a crash occurs, provide the complete stack trace or Xcode crash log. Use markdown code blocks for readability.

---

## 3. Feature Requests

Kino adheres to a strict design philosophy focused on native macOS performance, minimal dependencies, and a clean, educational architecture. 

Before requesting a feature or starting development on one, please open a Discussion thread or an Issue labeled `enhancement`. 

Feature requests will be evaluated based on:
*   **Performance Impact**: Does this feature bloat the AVFoundation rendering pipeline?
*   **Native Integration**: Can this be built using AppKit/SwiftUI without relying on heavy third-party libraries?
*   **Core Roadmap Alignment**: Does this align with the immediate goals of the project?

---

## 4. Development and Architecture Standards

If your feature or bug fix has been approved in an Issue, you may begin development. Kino's architecture relies heavily on the Command Pattern and strict separation of concerns.

### Architectural Rules
1.  **State Modification via Commands**: Do not modify the `WorkspaceState` or `TimelineService` directly from the UI layer. All state mutations must be encapsulated within a class conforming to the `Command` protocol and executed via `CommandManager`. This guarantees deterministic Undo/Redo capabilities.
2.  **MainActor Concurrency**: UI state variables (`@Published`) must only be mutated on the main thread. Utilize Swift's `@MainActor` and structured concurrency (`async/await`) rigorously.
3.  **AVFoundation Compositing**: Modifying the `PlaybackEngine` requires a deep understanding of `AVMutableVideoCompositionLayerInstruction`. Do not introduce block-based CIFilters (`AVAsynchronousCIImageFilteringRequest`) that override the multi-track layering system unless you are implementing a custom `AVVideoCompositing` class.
4.  **Dependency Management**: Do not introduce Swift Package Manager (SPM) dependencies or CocoaPods unless explicitly approved by the maintainers. Kino aims for zero external dependencies.

### Code Style
*   Follow standard Swift API Design Guidelines.
*   Avoid forced unwrapping (`!`) unless absolutely necessary and mathematically proven safe.
*   Ensure all new properties and methods include descriptive docstrings using standard Swift markdown (`///`).

---

## 5. Pull Request Submission Process

To submit your code, follow this standardized workflow:

1.  **Fork and Branch**: Fork the repository and create a descriptive branch name (e.g., `fix/playback-flicker` or `feature/blade-tool-snap`).
2.  **Atomic Commits**: Keep your commits logical and atomic. Write descriptive commit messages explaining *why* a change was made, not just *what* was changed.
3.  **No Extraneous Files**: Ensure your PR does not contain IDE-specific files (e.g., `.DS_Store`, `xcuserdata`), debug binaries, or unrelated code reformatting.
4.  **Testing**: Build and run the application locally. Test edge cases, specifically verifying that the timeline dragging mechanics and video export pipelines remain intact.
5.  **Drafting the PR**: Submit the Pull Request against the `main` branch. Reference the Issue number it resolves in the PR description (e.g., "Resolves #42").

Code review may require multiple iterations. Please be patient and responsive to architectural feedback.

Thank you for your contributions to Kino.


---
---

# Berkontribusi ke Kino

Terima kasih atas ketertarikan Anda untuk berkontribusi ke Kino. Kino adalah aplikasi penyunting video non-linear (NLE) native macOS berperforma tinggi.

Karena Kino dilisensikan di bawah PolyForm Shield License 1.0.0, aturan mainnya berbeda dari proyek open-source standar (seperti yang berlisensi MIT atau GPL). Dokumen ini menguraikan batasan hukum, pedoman arsitektur, dan standar teknis yang diperlukan untuk berkontribusi.

Harap baca dokumen ini secara menyeluruh sebelum mengirimkan Issue atau Pull Request.

Sebelum memulai pengembangan apa pun, Anda **diwajibkan** untuk membaca dokumentasi arsitektur yang relevan di folder [`Docs/`](Docs/) (seperti `Docs/ARCHITECTURE.md`, `Docs/MODULE_SYSTEM.md`, dan `Docs/PRD.md`). Memahami arsitektur modular adalah syarat wajib sebelum mulai menulis kode.

> **Catatan:** Kino saat ini sedang dalam tahap pengembangan aktif menuju rilis v1.0. Kontributor harus siap dengan kemungkinan perubahan arsitektur yang terus berjalan, pergeseran API modul, dan area basis kode yang belum sepenuhnya stabil.

---

## 1. Lisensi dan Kepatuhan Hukum

Kino didistribusikan di bawah PolyForm Shield License 1.0.0. Lisensi ini memberikan hak spesifik dan memberlakukan batasan yang ketat:

### Tindakan yang Diizinkan
*   **Studi Edukasi**: Anda memiliki akses tanpa batas untuk membaca, menganalisis, dan belajar dari kode sumber. Repositori ini berfungsi sebagai implementasi referensi untuk SwiftUI, AVFoundation, dan CoreImage di macOS.
*   **Penggunaan Pribadi**: Anda boleh mengompilasi, mem-build, dan menjalankan aplikasi di mesin lokal Anda sendiri untuk keperluan penyuntingan video pribadi.
*   **Modifikasi Internal**: Anda boleh memodifikasi kode sumber untuk penggunaan pribadi Anda sendiri.

### Tindakan yang Dilarang Keras
*   **Kompetisi Komersial**: Anda tidak diperbolehkan membuat, mendistribusikan, atau mengoperasikan produk komersial yang bersaing dengan Kino.
*   **Distribusi Layanan**: Anda tidak diperbolehkan menawarkan perangkat lunak ini atau versi modifikasinya sebagai layanan (service) kepada pihak ketiga.

### Perjanjian Lisensi Kontributor (CLA)
Dengan mengirimkan Pull Request ke repositori ini, Anda secara eksplisit setuju bahwa kontribusi Anda akan dilisensikan di bawah PolyForm Shield License 1.0.0. Anda juga memberi hak tak dapat dicabut kepada pengelola (maintainers) untuk memasukkan, mendistribusikan, dan memodifikasi kode yang Anda kirimkan ke dalam produk resmi Kino.

---

## 2. Panduan Pelaporan Isu (Issue Reporting)

Laporan isu yang detail dan dapat direproduksi sangat penting untuk menjaga stabilitas Kino. Saat membuka isu, harap gunakan templat yang disediakan dan pastikan informasi berikut disertakan:

1.  **Detail Lingkungan**:
    *   Versi macOS (misalnya, macOS 14.5)
    *   Spesifikasi Perangkat Keras (misalnya, Apple M2, Memori Terpadu 16GB)
    *   Versi Xcode (jika melakukan kompilasi dari sumber)
2.  **Langkah Reproduksi**: Daftar tindakan langkah-demi-langkah yang deterministik yang diperlukan untuk mereproduksi anomali tersebut.
3.  **Perilaku yang Diharapkan vs. Aktual**: Perbedaan yang jelas antara hasil yang diharapkan dan kegagalan yang diamati.
4.  **Log Diagnostik**: Jika terjadi crash, berikan stack trace lengkap atau log crash Xcode. Gunakan blok kode markdown untuk kemudahan membaca.

---

## 3. Permintaan Fitur (Feature Requests)

Kino menganut filosofi desain yang ketat, berfokus pada performa native macOS, dependensi minimal, dan arsitektur yang bersih serta edukatif.

Sebelum meminta fitur atau mulai mengembangkan fitur baru, harap buka utas Diskusi (Discussion) atau Isu yang diberi label `enhancement`.

Permintaan fitur akan dievaluasi berdasarkan:
*   **Dampak Performa**: Apakah fitur ini membebani pipeline rendering AVFoundation?
*   **Integrasi Native**: Bisakah ini dibangun menggunakan AppKit/SwiftUI tanpa bergantung pada pustaka pihak ketiga yang berat?
*   **Penyelarasan Peta Jalan Inti**: Apakah ini sejalan dengan tujuan jangka pendek proyek?

---

## 4. Standar Pengembangan dan Arsitektur

Jika fitur atau perbaikan bug Anda telah disetujui di sebuah Isu, Anda dapat memulai pengembangan. Arsitektur Kino sangat bergantung pada Pola Command (Command Pattern) dan pemisahan tanggung jawab yang ketat.

### Aturan Arsitektural
1.  **Modifikasi State melalui Command**: Jangan memodifikasi `WorkspaceState` atau `TimelineService` secara langsung dari lapisan UI. Semua mutasi state harus dienkapsulasi di dalam kelas yang mematuhi protokol `Command` dan dieksekusi via `CommandManager`. Hal ini menjamin kemampuan Undo/Redo yang deterministik.
2.  **Konkurensi MainActor**: Variabel state UI (`@Published`) hanya boleh dimutasi di thread utama (main thread). Gunakan `@MainActor` dari Swift dan konkurensi terstruktur (`async/await`) secara disiplin.
3.  **Komposisi AVFoundation**: Memodifikasi `PlaybackEngine` membutuhkan pemahaman mendalam tentang `AVMutableVideoCompositionLayerInstruction`. Jangan perkenalkan CIFilter berbasis blok (`AVAsynchronousCIImageFilteringRequest`) yang menimpa sistem pelapisan multi-track kecuali Anda mengimplementasikan kelas `AVVideoCompositing` kustom.
4.  **Manajemen Dependensi**: Jangan perkenalkan dependensi Swift Package Manager (SPM) atau CocoaPods kecuali disetujui secara eksplisit oleh pengelola. Kino bertujuan untuk memiliki nol dependensi eksternal.

### Gaya Penulisan Kode (Code Style)
*   Ikuti Panduan Desain API Swift standar.
*   Hindari forced unwrapping (`!`) kecuali benar-benar diperlukan dan terbukti aman secara matematis.
*   Pastikan semua properti dan metode baru menyertakan docstring deskriptif menggunakan markdown standar Swift (`///`).

---

## 5. Proses Pengiriman Pull Request

Untuk mengirimkan kode Anda, ikuti alur kerja standar ini:

1.  **Fork dan Branch**: Lakukan Fork pada repositori dan buat nama branch yang deskriptif (misalnya, `fix/playback-flicker` atau `feature/blade-tool-snap`).
2.  **Commit Atomik**: Jaga agar commit Anda logis dan atomik. Tulis pesan commit deskriptif yang menjelaskan *mengapa* perubahan dilakukan, bukan hanya *apa* yang diubah.
3.  **Tanpa File Ekstra**: Pastikan PR Anda tidak berisi file khusus IDE (misalnya, `.DS_Store`, `xcuserdata`), binary debug, atau pemformatan ulang kode yang tidak terkait.
4.  **Pengujian (Testing)**: Build dan jalankan aplikasi secara lokal. Uji kasus ekstrem (edge cases), khususnya pastikan bahwa mekanika penarikan (dragging) di timeline dan pipeline ekspor video tetap berfungsi utuh.
5.  **Menyusun PR**: Kirimkan Pull Request ke branch `main`. Referensikan nomor Isu yang diselesaikan dalam deskripsi PR (misalnya, "Resolves #42").

Tinjauan kode (code review) mungkin membutuhkan beberapa iterasi. Harap bersabar dan responsif terhadap umpan balik arsitektural.

Terima kasih atas kontribusi Anda pada Kino.
