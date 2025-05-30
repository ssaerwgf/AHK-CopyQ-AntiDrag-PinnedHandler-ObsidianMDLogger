# ssaerwgf's AutoHotkey v2 Productivity Scripts

Welcome! This repository contains a collection of AutoHotkey v2 scripts designed to enhance productivity and streamline common tasks on Windows.

**Author:** ssaerwgf
**License:** [MIT License](LICENSE) (Applies to all scripts in this repository)

## General Requirements

* **AutoHotkey v2.0 or higher:** All scripts require a compatible version of AutoHotkey to be installed. You can download it from [autohotkey.com](https://www.autohotkey.com/).

---

## 1. Personal_Hotkeys_and_ClipboardLogger.ahk

**Version:** 1.0.0 (2025-06-01)
**Script Link:** [Personal_Hotkeys_and_ClipboardLogger.ahk](Personal_Hotkeys_and_ClipboardLogger.ahk)

### Description

A comprehensive AutoHotkey v2 script designed to enhance personal productivity. It features custom global hotkeys, desktop environment tweaks, specific application control, enhanced key behaviors, and an advanced clipboard logger with Markdown formatting and Obsidian integration.

### Key Features

* **Desktop Environment Tweaks:**
  * Disables desktop icon zooming via `Ctrl + Mouse Wheel` when the desktop is active.
* **Custom Global Hotkeys (Single-fire, press-and-hold does not repeat action unless specified):**
  * `PrintScreen`: Remapped to send `Ctrl+Shift+Alt+P`.
  * `F24`: Remapped to send `Ctrl+Shift+Alt+L`.
  * `Shift + Z` (Context-sensitive): Triggers file/folder rename in File Explorer or on the Desktop.
  * `Ctrl + /`: Sends `Ctrl+N`.
  * `Ctrl + Shift + Z`: Launches CapsWriter server and client, then sends `Alt+Space, n` twice.
  * `Ctrl + Shift + X`: Sends `Alt+Space, n` (typically minimizes the active window).
  * `Ctrl + O`: Sends `Ctrl+Alt+Shift+O`.
  * **Network Configuration Switching:**
    * `Ctrl + Shift + A`: Runs `Internal.bat` for internal network settings.
    * `Ctrl + Shift + S`: Runs `External.bat` for external network settings.
    * `Ctrl + Shift + D`: Runs `DHCP.bat` to switch to DHCP.
  * **Common Editing Hotkeys (Single-fire):**
    * `Enter`: Sends `Enter`.
    * `Ctrl + S`: Sends `Ctrl+S` (Save).
    * `Ctrl + V`: Sends `Ctrl+V` (Paste).
    * `Ctrl + C`: Sends `Ctrl+C` (Copy).
    * `Ctrl + A`: Sends `Ctrl+A` (Select All).
* **Specific Application Control:**
  * `Alt + .` (Period): Sends Play/Pause command to all open PotPlayer64 windows.
* **Enhanced Key Behaviors:**
  * **Smooth Scrolling:** `PgUp`/`PgDn` keys provide smooth, continuous scrolling when held down. Scroll speed is configurable within the script.
  * **Custom Arrow Key Repeat:** `Left`/`Right` arrow keys have a custom repeat rate when held down. Repeat interval is configurable.
* **Advanced Clipboard Logger:**
  * **Markdown Formatting:** Saves clipboard history as Markdown files.
  * **Daily Logs:** Creates a new log file for each day in a `History` subfolder (e.g., `YYYY-MM-DD.md`).
  * **Session Log:** Maintains a `Clipboard_CurrentSession.md` log for the current script session.
  * **Path-Based Content Filtering:** Ignores clipboard entries that are specific `.png` file paths matching predefined prefixes (useful for screenshot tool temporary files).
  * **Content Deduplication:** Avoids logging identical consecutive clipboard entries.
  * **Minimum Length Filter:** Ignores very short clipboard entries.
  * **Timestamping:** Optionally logs the time of copy for each entry.
  * **Obsidian Integration:**
    * Tray menu options to open the current session log or today's history log directly in Obsidian using `obsidian://` URI.
    * Tray menu option to open the `History` folder.
  * **Customizable Tray Icon and Menu.**

### Dependencies

* AutoHotkey v2.0+
* **(Optional, for specific features):**
  * PotPlayer (for `Alt + .` hotkey)
  * CapsWriter (for `Ctrl + Shift + Z` hotkey)
  * Obsidian (for direct log opening from tray menu)

### Configuration (Important!)

Before running this script, you **MUST** review and potentially update the following sections within the script file (`Personal_Hotkeys_and_ClipboardLogger.ahk`):

1. **External Tool Paths:**
   * Search for `Run("D:\Extratools\CapsWriter-Offline-Windows-64bit\start_server.exe")` and similar lines for `CapsWriter` and the network `.bat` files (`Internal.bat`, `External.bat`, `DHCP.bat`). Update these paths to match your system.
2. **Clipboard Logger - Path Blocking:**
   * Search for `local pathToBlock1_Prefix := "D:\005_tools\PixPin\Temp\PixPin_"` and similar.
   * Adjust these `pathToBlockX_Prefix` variables and `targetExtension_WithDot` if you use different screenshot tools or want to block other specific file paths from being logged.
3. **Clipboard Logger - Obsidian Integration:**
   * Search for `Global ObsidianVaultName := "AutoHotkeypeizhi"`. **Change this to your Obsidian vault's name.**
   * Search for `Global ObsidianVaultBasePath := "D:\Extratools\disposition\AutoHotkeypeizhi"`. **Change this to the absolute path of your Obsidian vault's root folder.** Ensure there is no trailing backslash.
   * **Crucial:** The script assumes that the `History` folder and `Clipboard_CurrentSession.md` file (created by the script in its own directory) will reside *within* your Obsidian vault structure if you want the "Open in Obsidian" functionality to work seamlessly. If your script directory is outside your vault, you may need to adjust how `relativeFilePath` is calculated in `ViewSessionLogInObsidian_MenuHandler` and `OpenTodayLogInObsidian_MenuHandler` or ensure the `HistoryBaseFolderName` and `SessionLogFileName` point to locations inside your vault.
4. **Other Clipboard Logger Settings (Optional Customization):**
   * `HistoryBaseFolderName`, `SessionLogFileName`, `LogTimestampsInEntry`, `EntryTimestampFormat`, `MinCharsToLog`.
5. **Smooth Scrolling / Arrow Key Repeat (Optional Customization):**
   * `scrollInterval` for `PgUp`/`PgDn`.
   * `seekInterval` for `Left`/`Right` arrow keys.

### Usage

1. Ensure AutoHotkey v2.0+ is installed.
2. Download `Personal_Hotkeys_and_ClipboardLogger.ahk`.
3. **Carefully review and perform the necessary configurations mentioned above.**
4. Double-click the `.ahk` file to run it. A tray icon will appear, providing access to clipboard logger functions.

---

## 2. CopyQ_Helper.ahk

**Version:** 1.0.0 (2025-06-01)
**Script Link:** [CopyQ_Helper.ahk](CopyQ_Helper.ahk)

### Description

An AutoHotkey v2 script providing enhancements and helper functionalities for the CopyQ clipboard manager.

### Key Features

* **Simulate Drag-Disable for CopyQ Items:**
  * When the mouse cursor is over a CopyQ window, pressing and dragging the left mouse button beyond a small threshold will send an `Esc` key command to the CopyQ window. This can prevent accidental item dragging or close pop-up menus/previews within CopyQ.
* **Disable `Ctrl+C` in Active CopyQ:**
  * Prevents the native `Ctrl+C` (copy) command from functioning when a CopyQ window is the active window. This can avoid unintended interactions if `Ctrl+C` has special meaning within CopyQ or to prevent copying items from CopyQ back into CopyQ itself accidentally.
* **Auto-handle "Cannot Remove Pinned Item" Dialog:**
  * Automatically detects and handles the "Cannot remove pinned item" dialog box in CopyQ.
  * It sends `Enter` to dismiss the dialog, then sends `Alt+Space, c` (a common sequence to trigger CopyQ's "Clear" or similar action on the selected item after the dialog, effectively attempting to unpin and then potentially remove).

### Dependencies

* AutoHotkey v2.0+
* CopyQ Clipboard Manager (must be installed and running).

### Configuration (Mostly Internal)

This script is generally designed to work out-of-the-box if CopyQ is installed with default settings. However, you can review these variables at the top of the script if needed:

* `CopyQExeName`: Default is `copyq.exe`.
* `CopyQWinClass`: Default is `ahk_class Qt653QWindowIcon`. This might change with CopyQ versions. Use Window Spy (comes with AutoHotkey) to verify if issues arise.
* `DragThreshold`, `DragCheckPollInterval`: For the LButton drag feature.
* `DialogWindowTitle`: The exact title of the dialog to be handled.

### Usage

1. Ensure AutoHotkey v2.0+ and CopyQ are installed and running.
2. Download `CopyQ_Helper.ahk`.
3. Double-click the `.ahk` file to run it. The script runs in the background without a tray icon by default.

---

## Contribution

Feel free to fork this repository, submit pull requests, or open issues for bugs, suggestions, or feature requests.
