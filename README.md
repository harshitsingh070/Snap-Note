<div align="center">
  <img src="https://raw.githubusercontent.com/harshitsingh070/Snap-Note/main/assets/images/logo.png" alt="Snap Note Logo" width="150" height="150">
  <h1>Snap Note</h1>
  <p><h3>Capture. Extract. Remember.</h3></p>
  <p>Your intelligent companion for transforming visual notes into searchable digital text.</p>

  <p>
    <a href="https://github.com/harshitsingh070/Snap-Note/actions"><img src="https://github.com/harshitsingh070/Snap-Note/workflows/flutter/badge.svg" alt="Build Status"></a>
    <img src="https://img.shields.io/badge/Flutter-3.x.x-blue?logo=flutter" alt="Flutter Version">
    <img src="https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20%7C%20Web-lightgrey" alt="Platforms">
    <img src="https://img.shields.io/badge/License-MIT-green" alt="License">
  </p>
</div>

---

## ✨ Overview

Snap Note is a modern, cross-platform application designed to bridge the gap between physical visual information and searchable digital text. Whether it's handwritten notes, whiteboard diagrams, book pages, or receipts, Snap Note empowers you to effortlessly capture, extract, store, and retrieve information with cutting-edge on-device OCR technology and a clean, intuitive user interface.

<br>

---

## 🚀 Features

-   **📸 Visual Capture:**
    -   Seamlessly capture images from your device's camera or select from the gallery.
    -   Securely upload and store original images in Supabase Storage.

-   **🧠 Intelligent Text Extraction (OCR):**
    -   Powered by **Google ML Kit Text Recognition** for high-performance, on-device OCR.
    -   Recognizes both **printed** and **legible handwritten** text.
    -   Includes basic image pre-processing (grayscale) to potentially enhance accuracy.

-   **🔒 Secure & Scalable Backend:**
    -   Utilizes **Supabase** for robust user authentication (email/password).
    -   **PostgreSQL Database** for secure storage of note metadata (title, extracted text, image URL).
    -   **Row Level Security (RLS)** ensures strict data isolation – your notes are truly yours.
    -   **Signed URLs** for secure and temporary image access, even from private storage.

-   **🔍 Advanced Full-Text Search:**
    -   Leverages PostgreSQL's `TSVECTOR` and GIN indexes for lightning-fast search.
    -   Find any note by searching keywords in its **title** or **extracted text**.

-   **🗂️ Intuitive Note Management (CRUD):**
    -   Create, View, Edit, and Delete your visual notes with ease.
    -   Dynamic grid view for quick browsing of notes.

-   **🖼️ Immersive Image Viewer:**
    -   Tap any image to view it full-screen with **zoom and pan** capabilities for detailed inspection.

-   **👤 User Profile & Control:**
    -   Dedicated profile screen to view account details (email, user ID).
    -   Secure logout functionality.

-   **✨ Modern & Clean UI:**
    -   Inspired by **iOS aesthetics** for a minimalist, elegant, and highly responsive user experience.
    -   Consistent typography with **Google Fonts (Rubik)**.

---

## 🛠️ Technology Stack

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-Official_SDK-blue?style=for-the-badge&logo=flutter" alt="Flutter">
  <img src="https://img.shields.io/badge/Dart-Language-0175C2?style=for-the-badge&logo=dart" alt="Dart">
  <img src="https://img.shields.io/badge/Supabase-Backend%20as%20a%20Service-3FC087?style=for-the-badge&logo=supabase" alt="Supabase">
  <img src="https://img.shields.io/badge/PostgreSQL-Database-336791?style=for-the-badge&logo=postgresql" alt="PostgreSQL">
  <img src="https://img.shields.io/badge/Google%20ML%20Kit-OCR-4285F4?style=for-the-badge&logo=google" alt="Google ML Kit">
</p>

-   **Frontend:** Flutter (Dart)
    -   `provider` for state management
    -   `cached_network_image` for efficient image loading
    -   `google_fonts` for custom typography
    -   `flutter_dotenv` for secure environment variables
    -   `photo_view` for zoomable images
    -   `image` for image processing
    -   `path_provider` for file system access
    -   `intl` for date formatting
-   **Backend:** Supabase
    -   Authentication
    -   PostgreSQL Database
    -   Supabase Storage
-   **OCR:** Google ML Kit Text Recognition

---

## 🛣️ Future Enhancements

-   **Editable Extracted Text:** Direct editing of OCR output.
-   **Tagging & Categories:** Advanced note organization.
-   **Offline Support:** Create and access notes without internet.
-   **Multi-Page Notes:** Support for documents with multiple images.
-   **Export Options:** Export notes (e.g., to PDF, TXT).
-   **Reminder Functionality:** Set reminders linked to notes.
-   **Biometric Authentication:** For enhanced security.

---

## 🤝 Contributing

Contributions are welcome! If you find bugs or have feature ideas, please open an issue or submit a pull request.

---


<div align="center">
  <p>Made with ❤️ by [Harshit Singh]</p>
  <p><a href="mailto:harshitsingh2807@gmail.com">Contact Us</a></p>
</div>

<br>