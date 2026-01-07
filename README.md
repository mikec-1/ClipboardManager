# clipped

**Never lose a copied link again.**

clipped is a lightweight, native macOS application written in Swift. It sits quietly in your menu bar and keeps a history of everything you copy—text, code snippets, links, and more—so you can access them whenever you need them.

We've all been there: you copy something new, realizing a second too late that you just overwrote that important email address you needed. clipped fixes that.

## Features

* **Native & Fast:** Built 100% in Swift for macOS, no Electron bloat.
* **Unlimited History:** Keeps track of your clipboard history (customizable limit).
* **Searchable:** Quickly find that one link you copied three hours ago.
* **Clean UI:** Designed to look like it belongs on your Mac.
* **Privacy First:** Your clipboard data stays locally on your machine. It never leaves your computer.

## Installation

### Option 1: Build from Source
If you want to tweak the code or just see how it works:

1.  Clone the repository:
    ```bash
    git clone https://github.com/mikec-1/ClipboardManager.git
    ```
2.  Open `ClipManager.xcodeproj` in Xcode.
3.  Hit **Run** (Cmd+R) to build and start the app.

*(Note: You will need Xcode 14+ installed)*

### Option 2: Download
*Once we have a release ready, you can download the latest `.dmg` from the [Releases](https://github.com/mikec-1/ClipboardManager/releases) page.*

## How to Use

1.  **Copy as usual:** Use `Cmd+C` on any text, image, or file.
2.  **Open clipped:** Click the icon in the menu bar (or set up a custom hotkey).
3.  **Paste:** Select the item you want to restore. It’s automatically copied to your clipboard, ready to paste.

## Contributing

This is an open-source project, and I'd love to see what you can add to it!

* Found a bug? Open an [Issue](https://github.com/mikec-1/ClipboardManager/issues).
* Have a cool idea? Fork the repo and submit a Pull Request.

**Ideas for future updates:**
* [ ] Support for images and image previews
* [ ] Smart Search & Pinning
