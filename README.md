# Orga - Secure macOS Vault Application

**Orga** is a secure, local-first file vault application built natively for macOS using SwiftUI. This app allows users to securely hide, manage, and encrypt sensitive files and folders, protecting them from unauthorized access.

This project is built as a portfolio piece to demonstrate modern app development practices on the Apple platform, focusing on security, data persistence, and a clean MVVM architecture.

---

## ✨ Features

* **Secure User Authentication:** Complete login and first-time password setup flow.
* **Keychain Integration:** Master password is securely stored in the macOS Keychain using the `KeychainAccess` library.
* **AES Encryption:** All files added to the vault are encrypted on disk using **AES-GCM** authenticated encryption provided by Apple's **CryptoKit**.
* **Vault Management:**
    * **Add Files & Folders:** Add multiple files and folders at once using a native `NSOpenPanel`.
    * **Delete from Vault:** Permanently delete selected items from the secure vault.
    * **Unhide (Restore):** Securely decrypt and restore selected items back to their original file path.
* **Data Persistence:** A robust data persistence layer using `FileManager` and **JSON encoding** manages a `manifest.json` file to track all vaulted items and their original locations.
* **Safe Deletion:** Includes a user prompt to delete original files after they have been successfully copied and encrypted.

## 🚀 Technologies Used

* **Language:** Swift
* **Framework:** SwiftUI (for the UI), AppKit (for `NSOpenPanel`), Combine (for data flow)
* **Architecture:** MVVM (Model-View-ViewModel)
* **Security:** CryptoKit (AES-GCM Encryption), Keychain Services
* **Tools:** Xcode, Git, Swift Package Manager (SPM)

## 🚧 Future Work

This project is in active development. Upcoming features include:
* **Touch ID Integration:** Using `LocalAuthentication` to unlock the vault.
* **Keyboard Shortcuts:** Adding shortcuts for core actions like `Cmd+H` (Hide) and `Cmd+Delete` (Delete).
* **UI Refinement:** Enhancing the user interface and animations.
* **File Preview:** Implementing "Quick Look" to preview files directly within the app without unhiding them.
