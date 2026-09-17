# Contributing to Kino 🎬

First off, thank you for considering contributing to Kino! 

Kino is a powerful macOS non-linear video editing application (NLE) built with modern Apple frameworks. Because this project is licensed under the **PolyForm Shield License 1.0.0**, the rules of contribution differ slightly from standard open-source (e.g., MIT or GPL) projects.

Please read this document carefully before submitting any Issues or Pull Requests.

---

## 📜 1. Understanding the License

The **PolyForm Shield License 1.0.0** allows you to:
- **View and Study:** You have full access to read the source code. This project serves as an excellent educational resource for learning SwiftUI, AVFoundation, CoreImage, and modern Swift Architecture.
- **Personal Use:** You may compile and run the application for your own personal use.

However, the license strictly **FORBIDS**:
- Creating a commercial competing product.
- Distributing modified versions as a service or substitute for the original software.

By contributing code to this repository via a Pull Request (PR), you agree that you are transferring the copyright of your submitted changes to the original maintainer, allowing them to include your changes in the official, licensed product.

---

## 🐛 2. Reporting Bugs

We welcome detailed bug reports! If you find a bug while running or exploring Kino, please follow these steps:

1. **Check Existing Issues:** Before opening a new issue, ensure the bug hasn't already been reported.
2. **Open a New Issue:** Use the GitHub Issue Tracker.
3. **Provide Context:**
   - **macOS Version:** (e.g., macOS 14.5 Sonoma)
   - **Device Specs:** (e.g., M2 MacBook Air, 16GB RAM)
   - **Steps to Reproduce:** Provide a clear, step-by-step guide to reproduce the crash or bug.
   - **Expected vs. Actual Behavior:** What did you expect to happen, and what actually happened?
   - **Logs/Crash Reports:** If the app crashed, please paste the Xcode crash log or stack trace.

---

## 💡 3. Suggesting Features

Got an idea to make Kino better? We’d love to hear it!
However, please keep in mind that Kino aims to be a lightweight, lightning-fast editor. We may not accept feature requests that bloat the application or deviate from the core roadmap.

- Use the **Discussions** tab or the **Issues** tracker with the label `enhancement`.
- Clearly explain *why* the feature is needed and *how* it would improve the user workflow.

---

## 🛠 4. Submitting Pull Requests

If you want to get your hands dirty and fix a bug yourself, follow these guidelines:

### What we accept:
- **Bug Fixes:** Fixes for crashes, UI glitches, or performance bottlenecks.
- **Code Refactoring:** Minor optimizations or cleaning up deprecated APIs.
- **Documentation:** Improvements to this README, inline code comments, or architectural docs.

### What we DO NOT accept (without prior discussion):
- **Massive Architectural Changes:** Do not rewrite the `PlaybackEngine` or `WorkspaceState` without discussing it first in an Issue.
- **New Core Features:** Please discuss new features before spending hours writing the code.
- **Monetization/Tracking:** No analytics, trackers, or commercial SDKs.

### PR Submission Process:
1. **Fork the Repository:** Create your own fork.
2. **Create a Branch:** `git checkout -b fix/your-bug-name` or `feature/your-feature-name`.
3. **Write Clean Code:** Ensure your code matches the existing Swift style (e.g., use of `@MainActor`, modern async/await, and proper encapsulation).
4. **Test Thoroughly:** Ensure that your changes do not break the timeline dragging physics or the AVFoundation rendering pipeline.
5. **Submit the PR:** Fill out the PR template, linking the Issue you are fixing.

---

## 🧠 5. Learning & Discussion

One of the primary goals of keeping this repository open under the PolyForm Shield License is **education**.

If you are learning Swift and have questions like:
- *"How does the `WaveformGenerator` read PCM data so fast?"*
- *"Why is `CoordinateSpace.named("Timeline")` used instead of global coordinates?"*
- *"How does `AVMutableVideoComposition` handle Z-Index stacking?"*

Feel free to open a thread in the **Discussions** tab! We encourage a healthy, respectful community where developers can learn from the architecture of Kino.

Thank you for exploring, learning, and contributing!
