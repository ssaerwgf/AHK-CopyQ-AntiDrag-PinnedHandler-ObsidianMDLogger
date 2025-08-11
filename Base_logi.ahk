#Requires AutoHotkey v2.0     ; 脚本要求 AutoHotkey v2.0 或更高版本
#SingleInstance Force         ; 强制脚本单实例运行 (如果已在运行则替换旧实例)

ProcessSetPriority("High")    ; v2语法：设置高优先级
SetTitleMatchMode(2)          ; 标题匹配模式: 2 (窗口标题可以包含指定文本即可匹配)
SendMode("Input")             ; 按键发送模式: Input (通常更可靠且速度快)

; Script Name:      Base_logi.ahk
; Author:           ssaerwgf
; Version:          1.0.0
; Last Updated:     2025-08-11
; License:          MIT License (https://opensource.org/licenses/MIT)
; Repository:       https://github.com/ssaerwgf/AHK-CopyQ-AntiDrag-PinnedHandler-ObsidianMDLogger
; Forum Thread:     https://www.autohotkey.com/boards/viewtopic.php?f=83&t=137459

/*
  Description:
    A comprehensive AutoHotkey v2 script designed to enhance personal productivity
    through automated application startup, system tweaks, and a suite of custom hotkeys.
    It manages helper tools like PasteEx and CapsWriter, provides quality-of-life
    improvements like disabling desktop icon zoom, and implements a robust set of
    hotkeys for frequent actions and application control.
 
  Features:
    - Automated Application Management: Automatically starts and manages essential helper
      applications like PasteEx and CapsWriter on script launch.
    - Custom Global Hotkeys: Defines single-fire hotkeys for common tasks, application
      launching, and network profile switching.
    - System & Desktop Tweaks: Disables the Ctrl+MouseWheel zoom feature on the desktop
      to prevent accidental icon resizing.
    - Specific Application Control: Includes a dedicated hotkey to play/pause PotPlayer
      without needing to focus its window.
    - Enhanced Key Behaviors: Implements smooth scrolling with PgUp/PgDn and sets a
      custom repeat rate for the Left/Right arrow keys for better control.
    - Single-Fire Hotkey Logic: Prevents accidental repeated actions from holding down a
      hotkey, ensuring commands like 'Minimize' or 'Rename' fire only once per press.
  
  Dependencies:
    - AutoHotkey v2.0 or higher (Required)
    - (Optional, for specific features)
      - PotPlayer (for the Alt+. play/pause hotkey)
      - CapsWriter (for the F24 hotkey and auto-start feature)
      - PasteEx (for the auto-start feature)
  
  Configuration:
    - CRITICAL: Users MUST configure the file paths for external tools and scripts
      (e.g., `PASTEEX_PATH`, `CAPSWRITER_PATH`, and the paths to the network `.bat` files)
      within the script.
    - Please see the README.md file on GitHub for detailed configuration instructions.
*/


; ==============================================================================
;                            桌面特性调整
; ==============================================================================

; --- 禁用桌面图标缩放 (Ctrl+鼠标滚轮) ---
; 定义桌面窗口的类名。通常是 "Progman" 或 "WorkerW"。
DesktopWindowClass := "ahk_class Progman"
; DesktopWindowClass := "ahk_class WorkerW" ; 如果 "Progman" 无效, 请取消注释此行并注释掉上一行

; 以下热键仅在桌面窗口激活时生效
#HotIf WinActive(DesktopWindowClass)
    ^WheelUp::Return   ; 拦截 Ctrl+滚轮向上, 不执行任何操作
    ^WheelDown::Return ; 拦截 Ctrl+滚轮向下, 不执行任何操作
#HotIf ; 结束上述热键的上下文敏感条件
; --- 结束禁用桌面图标缩放部分 ---

; ==============================================================================
;                         PasteEx 自动启动模块
; ==============================================================================

; 全局变量声明
Global PASTEEX_PATH := "D:\Extratools\PasteEx\PasteEx.exe"
Global g_pasteex_started := false  ; 标记 PasteEx 是否已成功启动

; 启动 PasteEx 的函数
StartPasteEx() {
    Global PASTEEX_PATH, g_pasteex_started
    
    ; 检查 PasteEx.exe 文件是否存在
    if (!FileExist(PASTEEX_PATH)) {
        MsgBox("警告: PasteEx.exe 不存在于指定路径:`n" . PASTEEX_PATH 
            . "`n请检查路径是否正确。", "PasteEx 启动失败", 48)
        return false
    }
    
    ; 检查 PasteEx 是否已经在运行
    if (ProcessExist("PasteEx.exe")) {
        ; 如果已经在运行，直接标记为成功并返回
        g_pasteex_started := true
        return true
    }
    
    ; 尝试启动 PasteEx
    try {
        Run(PASTEEX_PATH)
        
        ; 等待进程启动（最多等待 3 秒）
        startTime := A_TickCount
        Loop {
            Sleep(100)  ; 每 100ms 检查一次
            
            if (ProcessExist("PasteEx.exe")) {
                ; PasteEx 进程已存在，启动成功
                g_pasteex_started := true
                
                ; 额外等待一小段时间确保程序完全初始化
                Sleep(500)
                
                return true
            }
            
            ; 检查是否超时（3秒）
            if (A_TickCount - startTime > 3000) {
                break
            }
        }
        
        ; 如果循环结束还没检测到进程，说明启动失败
        MsgBox("警告: PasteEx 启动超时。`n程序可能需要更长时间启动，或启动失败。", 
            "PasteEx 启动警告", 48)
        return false
        
    } catch Error as e {
        MsgBox("错误: 启动 PasteEx 时发生异常:`n" . e.Message, "PasteEx 启动错误", 16)
        return false
    }
}

; 启动 PasteEx
if (StartPasteEx()) {
    ; 可选：显示成功提示（如果不需要可以注释掉）
    ; ToolTip("PasteEx 已成功启动")
    ; SetTimer(() => ToolTip(), -2000)  ; 2秒后清除 ToolTip
} else {
    ; PasteEx 启动失败的处理（错误信息已在函数内显示）
}

; ==============================================================================
;                         开机自动启动 CapsWriter
; ==============================================================================

; 全局变量声明
Global g_server_hwnd := 0
Global g_client_hwnd := 0
Global CAPSWRITER_PATH := "D:\Extratools\CapsWriter-Offline-Windows-64bit\"

CheckProcessIntegrity() {
    serverExists := ProcessExist("start_server.exe") ? 1 : 0
    clientExists := ProcessExist("start_client.exe") ? 2 : 0
    return serverExists + clientExists
}

GetProcessWindow(exeName) {
    ; 保存当前设置
    dhw := A_DetectHiddenWindows
    DetectHiddenWindows(true)
    
    hwnd := 0
    try {
        if (WinExist("ahk_exe " . exeName)) {
            hwnd := WinGetID("ahk_exe " . exeName)
        }
    } catch {
        hwnd := 0
    }
    
    ; 恢复原设置
    DetectHiddenWindows(dhw)
    return hwnd
}

IsWindowValid(hwnd) {
    if (!hwnd) {
        return false
    }
    
    dhw := A_DetectHiddenWindows
    DetectHiddenWindows(true)
    
    valid := false
    try {
        valid := WinExist("ahk_id " . hwnd) ? true : false
    } catch {
        valid := false
    }
    
    DetectHiddenWindows(dhw)
    return valid
}

CleanupAllProcesses() {
    Global g_server_hwnd, g_client_hwnd, g_visible
    
    ; 先尝试关闭窗口（如果存在）
    if (g_server_hwnd && IsWindowValid(g_server_hwnd)) {
        try {
            WinClose("ahk_id " . g_server_hwnd)
            Sleep(100)
        } catch {
            ; 忽略错误
        }
    }
    
    if (g_client_hwnd && IsWindowValid(g_client_hwnd)) {
        try {
            WinClose("ahk_id " . g_client_hwnd)
            Sleep(100)
        } catch {
            ; 忽略错误
        }
    }
    
    ; 强制结束进程（如果还在运行）
    Loop 3 {  ; 最多尝试3次
        serverKilled := false
        clientKilled := false
        
        if (ProcessExist("start_server.exe")) {
            try {
                ProcessClose("start_server.exe")
                serverKilled := true
            } catch {
                ; 继续尝试
            }
        }
        
        if (ProcessExist("start_client.exe")) {
            try {
                ProcessClose("start_client.exe")
                clientKilled := true
            } catch {
                ; 继续尝试
            }
        }
        
        ; 如果两个进程都不存在了，退出循环
        if (!ProcessExist("start_server.exe") && !ProcessExist("start_client.exe")) {
            break
        }
        
        Sleep(100)  ; 给系统一点时间
    }
    
    ; 重置全局变量
    g_server_hwnd := 0
    g_client_hwnd := 0
    g_visible := false
}

StartCapsWriter() {
    Global g_server_hwnd, g_client_hwnd, g_visible, CAPSWRITER_PATH
    
    ; 首先确保没有残留进程
    CleanupAllProcesses()
    Sleep(200)  ; 给系统充分的时间清理
    
    try {
        ; 启动服务器
        Run(CAPSWRITER_PATH . "start_server.exe")
        
        ; 等待服务器窗口出现
        serverStarted := false
        Loop 50 {  ; 最多等待1秒
            Sleep(20)
            if (hwnd := GetProcessWindow("start_server.exe")) {
                g_server_hwnd := hwnd
                serverStarted := true
                break
            }
        }
        
        if (!serverStarted) {
            throw Error("服务器启动失败")
        }
        
        ; 启动客户端
        Run(CAPSWRITER_PATH . "start_client.exe")
        
        ; 等待客户端窗口出现
        clientStarted := false
        Loop 50 {
            Sleep(20)
            if (hwnd := GetProcessWindow("start_client.exe")) {
                g_client_hwnd := hwnd
                clientStarted := true
                break
            }
        }
        
        if (!clientStarted) {
            throw Error("客户端启动失败")
        }
        
        ; 等待窗口完全初始化
        Sleep(100)
        
        ; 使用更可靠的方式隐藏两个窗口
        HideBothWindows()
        
        g_visible := false
        return true
        
    } catch Error as e {
        ; 如果启动失败，清理所有进程
        CleanupAllProcesses()
        return false
    }
}

; 新增的辅助函数：可靠地隐藏两个窗口
HideBothWindows() {
    Global g_server_hwnd, g_client_hwnd
    
    ; 尝试多种方式确保窗口被隐藏
    Loop 3 {  ; 最多尝试3次
        hiddenCount := 0
        
        ; 首先使用 DetectHiddenWindows true 来确保能找到窗口
        DetectHiddenWindows(true)
        
        ; 隐藏服务器窗口
        if (g_server_hwnd && WinExist("ahk_id " . g_server_hwnd)) {
            try {
                WinHide("ahk_id " . g_server_hwnd)
                hiddenCount++
            } catch {
                ; 继续尝试
            }
        }
        
        ; 隐藏客户端窗口
        if (g_client_hwnd && WinExist("ahk_id " . g_client_hwnd)) {
            try {
                WinHide("ahk_id " . g_client_hwnd)
                hiddenCount++
            } catch {
                ; 继续尝试
            }
        }
        
        ; 检查是否两个窗口都已隐藏
        DetectHiddenWindows(false)
        serverVisible := WinExist("ahk_id " . g_server_hwnd) ? true : false
        clientVisible := WinExist("ahk_id " . g_client_hwnd) ? true : false
        
        ; 如果两个窗口都不可见了，成功
        if (!serverVisible && !clientVisible) {
            break
        }
        
        Sleep(50)  ; 短暂等待后重试
    }
}

; 检查窗口和进程的完整性
CheckWindowAndProcessIntegrity() {
    Global g_server_hwnd, g_client_hwnd
    
    ; 首先检查进程
    serverProcessExists := ProcessExist("start_server.exe")
    clientProcessExists := ProcessExist("start_client.exe")
    
    ; 如果任一进程不存在，直接返回需要重启
    if (!serverProcessExists || !clientProcessExists) {
        return false
    }
    
    ; 检查现有句柄的有效性
    serverWindowValid := IsWindowValid(g_server_hwnd)
    clientWindowValid := IsWindowValid(g_client_hwnd)
    
    ; 如果句柄无效，尝试重新获取
    if (!serverWindowValid) {
        g_server_hwnd := GetProcessWindow("start_server.exe")
        serverWindowValid := IsWindowValid(g_server_hwnd)
    }
    
    if (!clientWindowValid) {
        g_client_hwnd := GetProcessWindow("start_client.exe")
        clientWindowValid := IsWindowValid(g_client_hwnd)
    }
    
    ; 返回两个窗口是否都有效
    return serverWindowValid && clientWindowValid
}

setupCapsWriter() {
    Global g_server_hwnd, g_client_hwnd, g_visible
    
    ; 检查进程和窗口的完整性
    windowsIntact := CheckWindowAndProcessIntegrity()
    
    ; 如果窗口不完整（包括进程不存在或窗口无效），清理并重启
    if (!windowsIntact) {
        CleanupAllProcesses()
        Sleep(200)
        StartCapsWriter()
        return
    }
    
    ; 如果进程正在运行且窗口完整，确保窗口保持隐藏状态
    DetectHiddenWindows(false)
    if (WinExist("ahk_id " . g_server_hwnd) || WinExist("ahk_id " . g_client_hwnd)) {
        ; 如果任何窗口可见，将其隐藏
        HideBothWindows()
        g_visible := false
    }
}

; ==============================================================================
;                     CapsWriter 延迟自动启动
; ==============================================================================

; 创建一个延迟启动的函数
DelayedCapsWriterStartup() {
    Global g_server_hwnd, g_client_hwnd, g_visible
    
    ; 等待系统稳定（可以显示提示）
    TrayTip("正在准备启动 CapsWriter...", "请稍候", 1)
    
    ; 检查并启动 CapsWriter
    windowsIntact := CheckWindowAndProcessIntegrity()
    if (!windowsIntact) {
        ; 如果窗口不完整，清理并启动
        CleanupAllProcesses()
        Sleep(200)
        
        ; 尝试启动，如果失败则重试
        success := StartCapsWriter()
        if (!success) {
            ; 第一次失败，再等待一会儿后重试
            Sleep(2000)
            CleanupAllProcesses()
            Sleep(200)
            success := StartCapsWriter()
            
            if (!success) {
                TrayTip("CapsWriter 启动失败", 
                    "请手动按 F24 键启动", 3)
            } else {
                TrayTip("CapsWriter 已启动", 
                    "程序已在后台运行", 2)
            }
        } else {
            TrayTip("CapsWriter 已启动", 
                "程序已在后台运行", 2)
        }
    } else {
        ; 窗口完整，确保处于隐藏状态
        HideBothWindows()
        g_visible := false
        TrayTip("CapsWriter 已在运行", 
            "窗口已隐藏", 2)
    }
}

; 设置延迟启动定时器
; 延迟 5 秒后启动（负数表示只运行一次）
SetTimer(DelayedCapsWriterStartup, -5000)

; 如果您想要更长的延迟，可以改为 10 秒或更多：
; SetTimer(DelayedCapsWriterStartup, -10000)

; ==============================================================================
;                      GLOBAL FLAGS FOR SINGLE-FIRE HOTKEYS
; ==============================================================================
; These flags ensure each hotkey action runs only once per press-and-hold.

Global g_printscreen_sent := False
Global g_f21_sent := False
Global g_f22_sent := False
Global g_f23_sent := False
Global g_f24_sent := False

Global g_ctrl_shift_z_sent := False
Global g_ctrl_shift_x_sent := False
Global g_ctrl_o_specific_sent := False ; For your specific ^o mapping
Global g_ctrl_shift_a_sent := False
Global g_ctrl_shift_s_sent := False
Global g_ctrl_shift_d_sent := False
Global g_alt_period_sent := False

; --- Flags for common actions you might map to mouse buttons ---
; If your mouse software sends these standard shortcuts, they often behave as single-fire.
; These are examples if you wanted to define them in AHK with single-fire logic.
Global g_enter_key_sent := False
Global g_ctrl_s_sent := False      ; Save
Global g_ctrl_v_sent := False      ; Paste
Global g_ctrl_c_sent := False      ; Copy
Global g_ctrl_a_sent := False      ; Select All
Global g_ctrl_o_generic_sent := False ; Generic Open

; ==============================================================================
;                            通用快捷键定义 (SINGLE-FIRE)
; ==============================================================================

; --- PrintScreen ---
$PrintScreen::
{
    Global g_printscreen_sent ; Declare global
    If g_printscreen_sent
        Return
    g_printscreen_sent := True
    Send("^+!p")
}
$PrintScreen Up::
{
    Global g_printscreen_sent ; Declare global
    g_printscreen_sent := False
}

; --- F21 (Shift+Enter) ---
$F21::
{
    Global g_f21_sent  ; 使用小写，与声明一致
    If g_f21_sent
        Return
    g_f21_sent := True
    Send("+{Enter}")
}
$F21 Up::
{
    Global g_f21_sent
    g_f21_sent := False
}

; --- F22 (Ctrl+F 查找) ---
$F22::
{
    Global g_f22_sent  ; 使用小写，与声明一致
    If g_f22_sent
        Return
    g_f22_sent := True
    Send("^f")
}
$F22 Up::
{
    Global g_f22_sent
    g_f22_sent := False
}

; --- F23 (Ctrl+N 新建) ---
$F23::
{
    Global g_f23_sent  ; 使用小写，与声明一致
    If g_f23_sent
        Return
    g_f23_sent := True
    Send("^n")
}
$F23 Up::
{
    Global g_f23_sent
    g_f23_sent := False
}

; --- F24 (CapsWriter) ---
$F24::
{
    Global g_f24_sent ; Declare global
    If g_f24_sent
        Return
    g_f24_sent := True
    setupCapsWriter()
    return
}
$F24 Up::
{
    Global g_f24_sent ; Declare global
    g_f24_sent := False
}

; --- Ctrl+Shift+Z (Minimize Window) ---
$^+z::
{
    Global g_ctrl_shift_z_sent ; Declare global
    If g_ctrl_shift_z_sent
        Return
    g_ctrl_shift_z_sent := True
    Send("!{Space}")
    Sleep(100)
    Send("n")
    Return
}
$^+z Up::
{
    Global g_ctrl_shift_z_sent ; Declare global
    g_ctrl_shift_z_sent := False
}

; --- Ctrl+Shift+X (Context-Sensitive for Rename) ---
#HotIf WinActive("ahk_class CabinetWClass") or WinActive("ahk_class Progman") or WinActive("ahk_class WorkerW")
    $^+x::
    {
        Global g_ctrl_shift_x_sent ; Declare global
        If g_ctrl_shift_x_sent
            Return
        g_ctrl_shift_x_sent := True
        SendInput("+{F10}")
        Sleep(150)
        SendInput("m")
        Return
    }
    $^+x Up::
    {
        Global g_ctrl_shift_x_sent ; Declare global
        g_ctrl_shift_x_sent := False
    }
#HotIf

; --- Ctrl+O (Specific mapping from your script) ---
$^o::
{
    Global g_ctrl_o_specific_sent ; Declare global
    If g_ctrl_o_specific_sent
        Return
    g_ctrl_o_specific_sent := True
    Send("^!+o")
}
$^o Up::
{
    Global g_ctrl_o_specific_sent ; Declare global
    g_ctrl_o_specific_sent := False
}

; --- 网络配置切换快捷键 ---
$^+a::
{
    Global g_ctrl_shift_a_sent ; Declare global
    If g_ctrl_shift_a_sent
        Return
    g_ctrl_shift_a_sent := True
    Run("D:\Extratools\disposition\gateway_ip_bat\Internal.bat")
}
$^+a Up::
{
    Global g_ctrl_shift_a_sent ; Declare global
    g_ctrl_shift_a_sent := False
}

$^+s::
{
    Global g_ctrl_shift_s_sent ; Declare global
    If g_ctrl_shift_s_sent
        Return
    g_ctrl_shift_s_sent := True
    Run("D:\Extratools\disposition\gateway_ip_bat\External.bat")
}
$^+s Up::
{
    Global g_ctrl_shift_s_sent ; Declare global
    g_ctrl_shift_s_sent := False
}

$^+d::
{
    Global g_ctrl_shift_d_sent ; Declare global
    If g_ctrl_shift_d_sent
        Return
    g_ctrl_shift_d_sent := True
    Run("D:\Extratools\disposition\gateway_ip_bat\DHCP.bat")
}
$^+d Up::
{
    Global g_ctrl_shift_d_sent ; Declare global
    g_ctrl_shift_d_sent := False
}

; ==============================================================================
;                  特定应用程序控制 (SINGLE-FIRE)
; ==============================================================================

$!.:: ; Alt + . 热键
{
    Global g_alt_period_sent ; Declare global
    If g_alt_period_sent
        Return
    g_alt_period_sent := True

    targetClass := "ahk_class PotPlayer64"
    idList := WinGetList(targetClass)

    if !IsObject(idList) || idList.Length = 0 {
        MsgBox("未找到任何 " . targetClass . " 窗口！")
        Return
    }
    WM_APPCOMMAND := 0x0319
    APPCOMMAND_MEDIA_PLAY_PAUSE := 14
    lParam := APPCOMMAND_MEDIA_PLAY_PAUSE << 16
    for hwnd in idList {
        try {
            if WinExist("ahk_id " hwnd) {
                DllCall("PostMessageW", "Ptr", hwnd, "UInt", WM_APPCOMMAND, "Ptr", 0, "Ptr", lParam)
            }
        } catch Error as e {
             MsgBox("向 PotPlayer 发送命令失败 (DllCall): " . e.Message . "`n窗口句柄: " . hwnd)
        }
    }
    Return
}
$!. Up::
{
    Global g_alt_period_sent ; Declare global
    g_alt_period_sent := False
}


; ==============================================================================
;        EXAMPLES: COMMON SHORTCUTS (SINGLE-FIRE) FOR MOUSE BUTTONS
; ==============================================================================

; --- 回车 (Enter) ---
#InputLevel 1  ; 设置下面热键的输入级别为 1
$Enter::
{
    Global g_enter_key_sent
    If g_enter_key_sent
        Return
    g_enter_key_sent := True
    
    ; Use SendLevel instead of changing InputLevel
    SendLevel(0)
    Send("{Enter}")
    SendLevel(1)
}
$Enter Up::
{
    Global g_enter_key_sent
    g_enter_key_sent := False
}
#InputLevel 0  ; 恢复默认级别

; --- 保存 (Ctrl+S) ---
#InputLevel 1  ; 设置下面热键的输入级别为 1
$^s::
{
    Global g_ctrl_s_sent
    If g_ctrl_s_sent
        Return
    g_ctrl_s_sent := True
    
    ; Use SendLevel instead of changing InputLevel
    SendLevel(0)
    Send("^s")
    SendLevel(1)
}
$^s Up::
{
    Global g_ctrl_s_sent
    g_ctrl_s_sent := False
}
#InputLevel 0  ; 恢复默认级别

; --- 粘贴 (Ctrl+V) ---
#InputLevel 1  ; 设置下面热键的输入级别为 1
$^v::
{
    Global g_ctrl_v_sent
    If g_ctrl_v_sent
        Return
    g_ctrl_v_sent := True
    
    ; Use SendLevel instead of changing InputLevel
    SendLevel(0)
    Send("^v")
    SendLevel(1)
}
$^v Up::
{
    Global g_ctrl_v_sent
    g_ctrl_v_sent := False
}
#InputLevel 0  ; 恢复默认级别

; --- 复制 (Ctrl+C) ---
#InputLevel 1  ; 设置下面热键的输入级别为 1
$^c::
{
    Global g_ctrl_c_sent
    If g_ctrl_c_sent
        Return
    g_ctrl_c_sent := True
    
    ; Use SendLevel instead of changing InputLevel
    SendLevel(0)
    Send("^c")
    SendLevel(1)
}
$^c Up::
{
    Global g_ctrl_c_sent
    g_ctrl_c_sent := False
}
#InputLevel 0  ; 恢复默认级别

; --- 全选 (Ctrl+A) ---
#InputLevel 1  ; 设置下面热键的输入级别为 1
$^a::
{
    Global g_ctrl_a_sent
    If g_ctrl_a_sent
        Return
    g_ctrl_a_sent := True
    
    ; Use SendLevel instead of changing InputLevel
    SendLevel(0)
    Send("^a")
    SendLevel(1)
}
$^a Up::
{
    Global g_ctrl_a_sent
    g_ctrl_a_sent := False
}
#InputLevel 0  ; 恢复默认级别


; ==============================================================================
;                            自定义按键行为增强
; ==============================================================================

; --- 平滑滚动功能 (PgUp/PgDn) V3 ---
Global scrollInterval := 120  ; [可配置] 平滑滚动的重复间隔 (毫秒), 数值越小滚动越快
Global isScrollingUp := false ; (内部使用) 标记是否正在向上滚动
Global isScrollingDown := false ; (内部使用) 标记是否正在向下滚动

PgUp:: ; PgUp 按下时
{
    Global isScrollingUp, scrollInterval
    if (isScrollingUp) {
        Return 
        } ; 防止键盘自动重复触发新的计时器
    isScrollingUp := true
    Send("{Blind}{WheelUp 1}") ; 立即发送一次小幅向上滚动
    SetTimer(ScrollUp, scrollInterval) ; 启动计时器持续滚动
    Return
}
PgUp Up:: ; PgUp 释放时
{
    Global isScrollingUp
    SetTimer(ScrollUp, 0) ; 关闭向上滚动的计时器
    isScrollingUp := false
    Return
}
ScrollUp() { ; 计时器调用的向上滚动函数
    Global isScrollingUp
    if !GetKeyState("PgUp", "P") { ; 安全检查: 如果按键物理上已释放
        SetTimer(ScrollUp, 0)
        isScrollingUp := false
        Return
    }
    Send("{Blind}{WheelUp 1}") ; 发送小幅向上滚动
}

PgDn:: ; PgDn 按下时 (逻辑同 PgUp)
{
    Global isScrollingDown, scrollInterval
    if (isScrollingDown) {
        Return
        }
    isScrollingDown := true
    Send("{Blind}{WheelDown 1}")
    SetTimer(ScrollDown, scrollInterval)
    Return
}
PgDn Up:: ; PgDn 释放时
{
    Global isScrollingDown
    SetTimer(ScrollDown, 0)
    isScrollingDown := false
    Return
}
ScrollDown() { ; 计时器调用的向下滚动函数
    Global isScrollingDown
    if !GetKeyState("PgDn", "P") {
        SetTimer(ScrollDown, 0)
        isScrollingDown := false
        Return
    }
    Send("{Blind}{WheelDown 1}")
}
; --- 平滑滚动功能结束 ---

; --- 左右箭头键自定义重复行为 ---
Global seekInterval := 600 ; [可配置] 按住左右箭头键时的重复间隔 (毫秒)
Global isRightTimerActive := false ; (内部使用) 右箭头键计时器是否激活
Global isLeftTimerActive := false  ; (内部使用) 左箭头键计时器是否激活

$*Right:: ; 右箭头键按下时 ($* 表示钩子且允许修饰键)
{
    Global isRightTimerActive, seekInterval
    if !isRightTimerActive { ; 如果计时器未运行
        isRightTimerActive := true
        Send("{Blind}{Right}") ; 立即发送一次
        SetTimer(SendRightKey, -seekInterval) ; 设置单次计时器以实现延迟重复
    }
    Return
}
$*Right Up:: ; 右箭头键释放时
{
    Global isRightTimerActive
    SetTimer(SendRightKey, 0) ; 取消计时器
    isRightTimerActive := false
    Return
}
SendRightKey() { ; 计时器调用的发送右箭头函数
    Global isRightTimerActive, seekInterval
    isRightTimerActive := false ; 重置标记，表示当前计时器已执行
    if GetKeyState("Right", "P") { ; 如果按键仍然被按住
        Send("{Blind}{Right}")
        isRightTimerActive := true ; 再次标记，准备下一个计时器
        SetTimer(SendRightKey, -seekInterval) ; 安排下一次重复
    }
}

$*Left:: ; 左箭头键按下时 (逻辑同右箭头)
{
    Global isLeftTimerActive, seekInterval
    if !isLeftTimerActive {
        isLeftTimerActive := true
        Send("{Blind}{Left}")
        SetTimer(SendLeftKey, -seekInterval)
    }
    Return
}
$*Left Up:: ; 左箭头键释放时
{
    Global isLeftTimerActive
    SetTimer(SendLeftKey, 0)
    isLeftTimerActive := false
    Return
}
SendLeftKey() { ; 计时器调用的发送左箭头函数
    Global isLeftTimerActive, seekInterval
    isLeftTimerActive := false
    if GetKeyState("Left", "P") {
        Send("{Blind}{Left}")
        isLeftTimerActive := true
        SetTimer(SendLeftKey, -seekInterval)
    }
}
; --- 左右箭头键自定义重复行为结束 ---