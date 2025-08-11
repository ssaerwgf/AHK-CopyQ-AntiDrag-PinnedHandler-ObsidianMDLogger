# AutoHotkey v2 Productivity Suite

A comprehensive collection of AutoHotkey v2 scripts designed to enhance Windows productivity through intelligent automation, clipboard management, and input monitoring.

**Author:** ssaerwgf  
**License:** [MIT License](LICENSE)  
**Repository:** [https://github.com/ssaerwgf/AHK-CopyQ-AntiDrag-PinnedHandler-ObsidianMDLogger](https://github.com/ssaerwgf/AHK-CopyQ-AntiDrag-PinnedHandler-ObsidianMDLogger)  
**Forum Thread:** [AutoHotkey Community](https://www.autohotkey.com/boards/viewtopic.php?f=83&t=137459)

## 🎯 Overview

This repository contains three powerful AutoHotkey v2 scripts that work together to create a seamless productivity enhancement system:

1. **Base_logi.ahk** - Core productivity automation and hotkey management
2. **CopyQ-AntiDrag-PinnedHandler.ahk** - Enhanced CopyQ clipboard manager integration
3. **InputGuardian-InputTip-plugin.ahk** - Advanced text input versioning and clipboard history

## 📋 General Requirements

* **AutoHotkey v2.0 or higher** (Required) - Download from [autohotkey.com](https://www.autohotkey.com/)
* **Windows 10/11** (Recommended for full feature compatibility)

---

## 1. Base_logi.ahk - Core Productivity System

**Version:** 1.0.0  
**Last Updated:** 2025-08-11  
**Script Link:** [Base_logi.ahk](Base_logi.ahk)

### Description

The foundation script that provides comprehensive system automation, custom hotkeys, and application management. It serves as the core of your productivity enhancement system.

### ✨ Key Features

* **🚀 Automated Application Management**
  * Auto-starts PasteEx on script launch with robust error handling
  * Delayed auto-start for CapsWriter (5 seconds after script initialization)
  * Intelligent process integrity checking and recovery

* **🎮 Desktop Environment Tweaks**
  * Disables accidental desktop icon zooming (`Ctrl + Mouse Wheel`)
  * Prevents unintended desktop interactions

* **⌨️ Custom Global Hotkeys** (Single-fire mechanism prevents repeat on hold)
  * `PrintScreen` → `Ctrl+Shift+Alt+P`
  * `F21` → `Shift+Enter`
  * `F22` → `Ctrl+F` (Find)
  * `F23` → `Ctrl+N` (New)
  * `F24` → Toggle CapsWriter visibility
  * `Ctrl+Shift+Z` → Minimize window
  * `Ctrl+Shift+X` → Context-sensitive rename (Explorer/Desktop)
  * `Ctrl+O` → `Ctrl+Alt+Shift+O`
  
* **🌐 Network Profile Switching**
  * `Ctrl+Shift+A` → Internal network configuration
  * `Ctrl+Shift+S` → External network configuration
  * `Ctrl+Shift+D` → DHCP configuration

* **🎬 Application-Specific Controls**
  * `Alt+.` → Play/Pause all PotPlayer instances without focusing

* **🖱️ Enhanced Input Behaviors**
  * **Smooth Scrolling**: `PgUp`/`PgDn` provide butter-smooth continuous scrolling
  * **Custom Arrow Repeat**: Configurable repeat rate for `Left`/`Right` arrows
  * **Single-fire Protection**: Common shortcuts (`Enter`, `Ctrl+S/V/C/A`) protected from accidental repeats

### 🔧 Configuration

**CRITICAL**: Update these paths in the script before running:

1. **PasteEx Path** (Line ~56):
   ```autohotkey
   Global PASTEEX_PATH := "D:\Extratools\PasteEx\PasteEx.exe"
   ```

2. **CapsWriter Path** (Line ~134):
   ```autohotkey
   Global CAPSWRITER_PATH := "D:\Extratools\CapsWriter-Offline-Windows-64bit\"
   ```

3. **Network Batch Files** (Lines ~573-589):
   ```autohotkey
   Run("D:\Extratools\disposition\gateway_ip_bat\Internal.bat")
   Run("D:\Extratools\disposition\gateway_ip_bat\External.bat")
   Run("D:\Extratools\disposition\gateway_ip_bat\DHCP.bat")
   ```

4. **Scrolling & Key Repeat** (Optional):
   ```autohotkey
   Global scrollInterval := 120  ; Smooth scroll speed (ms)
   Global seekInterval := 600    ; Arrow key repeat interval (ms)
   ```

### 📦 Dependencies

* **Required**: AutoHotkey v2.0+
* **Optional** (for specific features):
  * PasteEx - Enhanced paste functionality
  * CapsWriter - Advanced text input
  * PotPlayer - Media control features
  * Network configuration batch files

---

## 2. CopyQ-AntiDrag-PinnedHandler.ahk - Intelligent Clipboard Management

**Version:** 2.0.3  
**Last Updated:** 2025-08-11  
**Script Link:** [CopyQ-AntiDrag-PinnedHandler.ahk](CopyQ-AntiDrag-PinnedHandler.ahk)

### Description

An intelligent enhancement layer for CopyQ clipboard manager that prevents common annoyances and provides multiple "hands-off" methods for window management.

### ✨ Key Features

* **🛡️ Dynamic Protection Mode**
  * Protection disabled by default for each new CopyQ session
  * First click automatically activates protection
  * Right-click permanently disables protection for current session

* **🚫 Anti-Drag Protection**
  * Prevents accidental item dragging within CopyQ
  * Sends `Esc` when drag gesture detected (configurable threshold)

* **🔄 Smart Auto-Close Behaviors**
  * **Click-Away**: Instantly closes when clicking outside CopyQ
  * **Mouse-Leave**: Auto-closes after cursor leaves window (200ms delay)
  * **Keyboard Trigger**: Press any key while hovering to close
  * **Dialog Automation**: Handles "Cannot remove pinned item" dialogs automatically

* **🎯 Focus Management**
  * Proactively redirects focus to last active application
  * Ensures CopyQ never steals focus from your workflow
  * Maintains workspace continuity

* **💬 Status Notification System**
  * Non-intrusive tooltips for protection status
  * Clear feedback on mode changes
  * Visual confirmation of actions

### 🔧 Configuration

The script works out-of-the-box with default CopyQ settings. Advanced users can adjust:

```autohotkey
; Core detection
global CopyQExeName := "copyq.exe"
global CopyQWinClass := "ahk_class Qt653QWindowIcon"

; Anti-drag sensitivity
global DragThreshold := 10           ; Pixels before drag detected
global DragCheckPollInterval := 15   ; Check interval (ms)

; Auto-close timing
global MouseLeaveCloseDelay := 200   ; Delay after mouse leaves (ms)
global FocusCheckInterval := 50      ; Focus redirect check (ms)
```

### 📦 Dependencies

* **Required**: 
  * AutoHotkey v2.0+
  * CopyQ Clipboard Manager

### 💡 Usage Tips

1. **First-time use**: CopyQ opens with protection OFF
2. **Quick enable**: Click once in CopyQ to activate protection
3. **Settings access**: Right-click to disable protection and access CopyQ settings
4. **Quick dismiss**: Move mouse away or press any key to close

---

## 3. InputGuardian Plugin for InputTip - Text Versioning & Clipboard History

**Version:** 1.0.0  
**Last Updated:** 2025-08-11  
**Script Link:** [InputGuardian-InputTip-plugin.ahk](InputGuardian-InputTip-plugin.ahk)

### Description

A sophisticated plugin for [InputTip](https://github.com/abgox/InputTip) that adds Git-style version control for your text input and maintains a comprehensive clipboard history. Think of it as having two digital assistants: a Librarian who versions your work, and a Historian who logs your references.

### ✨ Key Features

* **📚 The Librarian (Text Versioning)**
  * Automatic snapshots on input pause (3 seconds)
  * Proactive saves on Enter/Ctrl+Enter
  * Git-style diff tracking for all changes
  * Session-based organization by application
  * Context-aware switching between windows

* **📜 The Historian (Clipboard Logging)**
  * Captures all manual copies (Ctrl+C)
  * Daily Markdown logs with timestamps
  * Intelligent de-duplication
  * Path blocking for temporary files
  * Clean separation from automated captures

* **🧠 Intelligent Boundary Detection**
  * Knows when YOU copy vs when IT captures
  * Prevents clipboard pollution
  * Smart validation of input contexts
  * Failure recovery with exponential backoff

* **🔄 Advanced Queue System**
  * Asynchronous file writing
  * Automatic retry on failures
  * Memory caching as fallback
  * Health monitoring and auto-recovery

### 🔧 Configuration

Update the `IGConfig` class in the plugin file:

```autohotkey
class IGConfig {
    ; File paths
    static HistoryBasePath := A_ScriptDir . "\InputGuardian\History"
    static SessionsBasePath := A_ScriptDir . "\InputGuardian\Sessions"
    static LogPath := A_ScriptDir . "\InputGuardian\Logs"
    
    ; CopyQ integration (optional)
    static CopyQExePath := "D:\005_tools\CopyQ\copyq.exe"  ; Update this path
    static UseCopyQ := true
    
    ; Behavior settings
    static PauseDetectionTime := 3000   ; 3 seconds pause triggers save
    static MinTextLength := 1            ; Minimum characters to save
    static SnapshotCooldown := 2000     ; Cooldown between snapshots
    
    ; Path blocking for clipboard (screenshot tools, etc.)
    static PathBlockList := [
        {
            prefix: "D:\005_tools\PixPin\Temp\PixPin_",  ; Update these paths
            extension: ".png"
        },
        {
            prefix: "D:\0000_bookmark\Picture_saving\Clip_",
            extension: ".png"
        }
    ]
}
```

### 📦 Dependencies

* **Required**:
  * AutoHotkey v2.0+
  * [InputTip v2025.07.20+](https://github.com/abgox/InputTip) by abgox
* **Optional**:
  * CopyQ - Enhanced clipboard management
  * Obsidian - For viewing Markdown logs

### 📁 File Structure

```
InputGuardian/
├── History/          # Daily clipboard logs (YYYY-MM-DD.md)
├── Sessions/         # Text versioning sessions
│   ├── Temp/        # Current session preview
│   └── YYYY-MM-DD.md # Daily session logs with diffs
└── Logs/            # System logs
```

### 🚀 Installation

1. Install [InputTip](https://github.com/abgox/InputTip) first
2. Place `InputGuardian-InputTip-plugin.ahk` in InputTip's plugins folder
3. Configure paths in the IGConfig class
4. Run InputTip.ahk (the plugin loads automatically)

### 🏆 Acknowledgments

Special thanks to [abgox](https://github.com/abgox) for creating InputTip, which provides the essential foundation for this plugin through its caret detection and window management systems.

---

## 🎯 Quick Start Guide

### Basic Setup (Minimal Configuration)

1. **Install AutoHotkey v2.0+** from [autohotkey.com](https://www.autohotkey.com/)

2. **Run Base_logi.ahk** for core productivity features
   - Update tool paths if using PasteEx/CapsWriter
   - Works standalone for basic hotkeys

3. **Add CopyQ integration** (if using CopyQ)
   - Install [CopyQ](https://hluk.github.io/CopyQ/)
   - Run `CopyQ-AntiDrag-PinnedHandler.ahk`

4. **Enable advanced features** (optional)
   - Install [InputTip](https://github.com/abgox/InputTip)
   - Add InputGuardian plugin for text versioning

### Recommended Setup Order

```
1. Base_logi.ahk              (Core system)
   ↓
2. CopyQ + Handler script      (Clipboard enhancement)
   ↓
3. InputTip + InputGuardian    (Advanced text features)
```

---

## 🤝 Contributing

Contributions are welcome! Feel free to:
- Fork the repository
- Submit pull requests
- Open issues for bugs or feature requests
- Share your configuration tips

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🔗 Links

- **Repository**: [GitHub](https://github.com/ssaerwgf/AHK-CopyQ-AntiDrag-PinnedHandler-ObsidianMDLogger)
- **AutoHotkey Community**: [Forum Thread](https://www.autohotkey.com/boards/viewtopic.php?f=83&t=137459)
- **Dependencies**:
  - [AutoHotkey](https://www.autohotkey.com/)
  - [InputTip](https://github.com/abgox/InputTip) by abgox
  - [CopyQ](https://hluk.github.io/CopyQ/)

---

*Made with ❤️ for the AutoHotkey community*