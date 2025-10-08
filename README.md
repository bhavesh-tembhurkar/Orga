# Orga - Secure macOS Vault Application

**Orga** is a secure, local-first file vault application built natively for macOS using SwiftUI. This app allows users to securely hide, manage, and encrypt sensitive files and folders, protecting them from unauthorized access.

This project demonstrates modern app development practices on the Apple platform, focusing on **security, data persistence, and a clean MVVM architecture**.

---

##  Features

* **Secure User Authentication:** Complete login and first-time password setup flow.
* **Keychain Integration:** Master password securely stored in the macOS Keychain using the `KeychainAccess` library.
* **AES Encryption:** All files are encrypted on disk using **AES-GCM** authenticated encryption via Apple's **CryptoKit**.
* **Vault Management:**
  * Add multiple files and folders at once using a native `NSOpenPanel`.
  * Permanently delete items from the vault.
  * Securely decrypt and restore files back to their original path.
* **Data Persistence:** Robust layer using `FileManager` + **JSON encoding** to manage a `manifest.json` file for vaulted items and original paths.
* **Touch ID Authentication:** Unlock the vault quickly and securely with macOS **Touch ID**.
* **Keyboard Shortcuts:** Handy shortcuts like `Cmd+H` (Hide), `Cmd+U` (Unhide), and `Cmd+Delete` (Delete).
* **UI & UX Enhancements:** A refined SwiftUI interface with smooth transitions and animations.
* **Safe Deletion:** Prompts users to delete original files after successful encryption.

---

##  Technologies Used

* **Language:** Swift  
* **Frameworks:** SwiftUI, AppKit, Combine  
* **Architecture:** MVVM (Model-View-ViewModel)  
* **Security:** CryptoKit (AES-GCM Encryption), Keychain Services  
* **Tools:** Xcode, Git, Swift Package Manager (SPM)

---

##  Demo

You can view the live demo of the application here: [Orga Live Demo] LInk : https://bhavesh-tembhurkar.github.io/my-portfolio/orga.html  


