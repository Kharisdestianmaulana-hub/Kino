# Contributing to Kino

Thank you for your interest in contributing to Kino. Kino is a high-performance, native macOS non-linear video editing application (NLE). 

Because Kino is licensed under the PolyForm Shield License 1.0.0, the rules of engagement differ from standard open-source projects (such as those under MIT or GPL). This document outlines the legal boundaries, architectural guidelines, and technical standards required for contributing.

Please read this document thoroughly before submitting any Issues or Pull Requests.

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

Kino adheres to a strict design philosophy: native performance, minimal dependencies, and no electron/web-wrapper compromises. 

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
