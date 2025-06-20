#Requires AutoHotkey v2.0     ; 脚本要求 AutoHotkey v2.0 或更高版本
#SingleInstance Force         ; 强制脚本单实例运行 (如果已在运行则替换旧实例)

SetTitleMatchMode(2)          ; 标题匹配模式: 2 (窗口标题可以包含指定文本即可匹配)
SendMode("Input")             ; 按键发送模式: Input (通常更可靠且速度快)

; Script Name:      Personal_Hotkeys_and_ClipboardLogger.ahk
; Author:           ssaerwgf
; Version:          1.0.0
; Last Updated:     2025-05-31
; License:          MIT License (https://opensource.org/licenses/MIT)
; Repository:       https://github.com/ssaerwgf/AHK-CopyQ-AntiDrag-PinnedHandler-ObsidianMDLogger
; Forum Thread:     https://www.autohotkey.com/boards/viewtopic.php?f=83&t=137459

/*
  Description:
    A comprehensive AutoHotkey v2 script designed to enhance personal productivity through
    custom hotkeys, system tweaks, and an advanced clipboard logger with Obsidian integration.
 
  Features:
    - Custom global hotkeys for common tasks and application launching.
    - Desktop environment tweaks (e.g., disabling desktop icon zoom).
    - Specific application control (e.g., PotPlayer play/pause).
    - Enhanced key behaviors (e.g., smooth scrolling with PgUp/PgDn, custom arrow key repeat).
    - Advanced Clipboard Logger:
      - Automatically saves copied text to Markdown files.
      - Organizes history into daily logs (YYYY-MM-DD.md).
      - Supports path-based content filtering (e.g., ignore specific .png paths).
      - Offers deep integration with Obsidian via URI for quick log access from tray menu.
  
  Dependencies:
    - AutoHotkey v2.0 or higher (Required)
    - (Optional, for specific features)
      - PotPlayer
      - CapsWriter
      - Obsidian (for tray menu integration)
  
  Configuration:
    - CRITICAL: Users MUST configure paths for external tools (CapsWriter, network .bat files)
      and Obsidian integration details (Vault name, Vault base path) within the script.
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
;                      GLOBAL FLAGS FOR SINGLE-FIRE HOTKEYS
; ==============================================================================
; These flags ensure each hotkey action runs only once per press-and-hold.

Global g_printscreen_sent := False
Global g_f24_sent := False
Global g_shift_z_sent := False       ; For the context-sensitive +z
Global g_ctrl_slash_sent := False
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

; --- F24 ---
$F24::
{
    Global g_f24_sent ; Declare global
    If g_f24_sent
        Return
    g_f24_sent := True
    Send("^+!l")
}
$F24 Up::
{
    Global g_f24_sent ; Declare global
    g_f24_sent := False
}

; --- Shift+Z (Context-Sensitive for Rename) ---
#HotIf WinActive("ahk_class CabinetWClass") or WinActive("ahk_class Progman") or WinActive("ahk_class WorkerW")
    $+z::
    {
        Global g_shift_z_sent ; Declare global
        If g_shift_z_sent
            Return
        g_shift_z_sent := True
        SendInput("+{F10}")
        Sleep(150)
        SendInput("m")
        Return
    }
    $+z Up::
    {
        Global g_shift_z_sent ; Declare global
        g_shift_z_sent := False
    }
#HotIf

; --- Ctrl+/ ---
$^/::
{
    Global g_ctrl_slash_sent ; Declare global
    If g_ctrl_slash_sent
        Return
    g_ctrl_slash_sent := True
    Send("^n")
}
$^/ Up::
{
    Global g_ctrl_slash_sent ; Declare global
    g_ctrl_slash_sent := False
}

; --- Ctrl+Shift+Z (CapsWriter) ---
$^+z::
{
    Global g_ctrl_shift_z_sent ; Declare global
    If g_ctrl_shift_z_sent
        Return
    g_ctrl_shift_z_sent := True
    Run("D:\Extratools\CapsWriter-Offline-Windows-64bit\start_server.exe")
    Run("D:\Extratools\CapsWriter-Offline-Windows-64bit\start_client.exe")
    Sleep(1000)
    Send("!{Space}n")
    Sleep(300)
    Send("!{Space}n")
    Return
}
$^+z Up::
{
    Global g_ctrl_shift_z_sent ; Declare global
    g_ctrl_shift_z_sent := False
}

; --- Ctrl+Shift+X (Minimize Window) ---
$^+x::
{
    Global g_ctrl_shift_x_sent ; Declare global
    If g_ctrl_shift_x_sent
        Return
    g_ctrl_shift_x_sent := True
    Send("!{Space}")
    Sleep(100)
    Send("n")
    Return
}
$^+x Up::
{
    Global g_ctrl_shift_x_sent ; Declare global
    g_ctrl_shift_x_sent := False
}

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
$Enter:: ; Or e.g., $XButton1:: if XButton1 is your Enter mouse key
{
    Global g_enter_key_sent
    If g_enter_key_sent
        Return
    g_enter_key_sent := True
    Send("{Enter}")
}
$Enter Up:: ; Or $XButton1 Up::
{
    Global g_enter_key_sent
    g_enter_key_sent := False
}

; --- 保存 (Ctrl+S) ---
$^s:: ; Or e.g., $XButton2::
{
    Global g_ctrl_s_sent
    If g_ctrl_s_sent
        Return
    g_ctrl_s_sent := True
    Send("^s")
}
$^s Up:: ; Or $XButton2 Up::
{
    Global g_ctrl_s_sent
    g_ctrl_s_sent := False
}

; --- 粘贴 (Ctrl+V) ---
$^v::
{
    Global g_ctrl_v_sent
    If g_ctrl_v_sent
        Return
    g_ctrl_v_sent := True
    Send("^v")
}
$^v Up::
{
    Global g_ctrl_v_sent
    g_ctrl_v_sent := False
}

; --- 复制 (Ctrl+C) ---
$^c::
{
    Global g_ctrl_c_sent
    If g_ctrl_c_sent
        Return
    g_ctrl_c_sent := True
    Send("^c")
}
$^c Up::
{
    Global g_ctrl_c_sent
    g_ctrl_c_sent := False
}

; --- 全选 (Ctrl+A) ---
$^a::
{
    Global g_ctrl_a_sent
    If g_ctrl_a_sent
        Return
    g_ctrl_a_sent := True
    Send("^a")
}
$^a Up::
{
    Global g_ctrl_a_sent
    g_ctrl_a_sent := False
}

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

; ==============================================================================
;        高级剪贴板记录器 (Markdown格式, Obsidian集成, 带路径屏蔽)
; ==============================================================================
#Warn VarUnset, Off           ; (可选) 关闭未初始化变量的警告, 某些情况下可能需要

; --- 配置区域 (剪贴板记录器) ---
Global HistoryBaseFolderName := "History"                       ; [可配置] 历史日志存放的子文件夹名称 (在脚本所在目录)
Global SessionLogFileName := "Clipboard_CurrentSession.md"    ; [可配置] 当前会话日志的文件名 (在脚本所在目录)
Global LogTimestampsInEntry := True                           ; [可配置] 是否在每个日志条目中记录时间戳
Global EntryTimestampFormat := "HH:mm:ss"                     ; [可配置] 条目内时间戳的格式 (例如: "HH:mm:ss")
Global MinCharsToLog := 1                                     ; [可配置] 记录内容的最小字符数 (小于此长度的内容将被忽略)

; --- Obsidian 集成配置 ---
Global ObsidianVaultName := "AutoHotkeypeizhi"  ; <<< [重要] Obsidian Vault (仓库) 的实际名称! 请务必修改为你的名称。
Global ObsidianVaultBasePath := "D:\Extratools\disposition\AutoHotkeypeizhi" ; <<< [重要] Obsidian Vault (仓库) 根目录的完整路径! 请务必修改。
; <<< 注意: 确保 ObsidianVaultBasePath 的末尾不包含反斜杠 ( \ )!

; --- 状态变量 (剪贴板记录器) ---
Global FullHistoryFolderPath := ""      ; (内部使用) 历史日志文件夹的完整路径
Global FullSessionLogPath := ""         ; (内部使用) 当前会话日志文件的完整路径
Global LastLoggedClipboardContent := "" ; (内部使用) 用于存储上一次记录的剪贴板内容 (基于清理后的文本), 防止重复记录

; --- 初始化 (脚本启动时自动执行) ---
If !InitializeLogger() { ; 调用初始化函数
    Return ; 如果初始化失败, 则不继续执行后续的自动执行区段代码
}
SetupTrayMenu() ; 设置系统托盘菜单
OnClipboardChange(ClipboardChangeHandler, True) ; 监视剪贴板变化, True 表示立即调用一次处理函数
Return ; 结束自动执行区段 (重要! 防止后续函数被意外执行)

; ------------------------------------------------------------------------------
;                            剪贴板记录器 - 函数定义
; ------------------------------------------------------------------------------

InitializeLogger() { ; 初始化记录器: 创建文件夹, 初始化会话日志文件
    Global FullHistoryFolderPath, HistoryBaseFolderName, FullSessionLogPath, SessionLogFileName

    ; 初始化历史记录文件夹路径
    FullHistoryFolderPath := A_ScriptDir . "\" . HistoryBaseFolderName
    If !DirExist(FullHistoryFolderPath) { ; 如果文件夹不存在
        Try {
            DirCreate(FullHistoryFolderPath) ; 尝试创建文件夹
            If !DirExist(FullHistoryFolderPath) { ; 再次检查是否创建成功
                MsgBox("严重错误: 创建历史记录文件夹失败: " . FullHistoryFolderPath . "`n请检查权限或手动创建后重启脚本。", "剪贴板记录器 - 启动失败", 16)
                ExitApp ; 创建失败则退出脚本
            }
            MsgBox("提示: 历史记录文件夹 '" . HistoryBaseFolderName . "' 已自动创建于脚本目录。", "剪贴板记录器 - 初始化", 64)
        } Catch Error as e {
            MsgBox("严重错误: 创建历史记录文件夹时发生异常: " . FullHistoryFolderPath . "`n" . e.Message . "`n脚本即将退出。", "剪贴板记录器 - 启动失败", 16)
            ExitApp 
        }
    }

    ; 初始化当前会话日志文件路径
    FullSessionLogPath := A_ScriptDir . "\" . SessionLogFileName
    Try {
        ; 以写入模式打开会话日志 (会清空原有内容), 使用 UTF-8 编码
        local LogFileHandle := FileOpen(FullSessionLogPath, "w", "UTF-8")
        If (!IsObject(LogFileHandle)) {
            MsgBox("警告: 无法初始化/清空当前会话日志文件: " . FullSessionLogPath . "`n会话日志功能可能受影响。", "剪贴板记录器 - 会话日志警告", 48)
        } Else {
            ; 写入会话日志的 Markdown 头部信息
            LogFileHandle.Write("# Clipboard Session Log - Started: " . FormatTime(, "yyyy-MM-dd HH:mm:ss") . "`r`n`r`n")
            LogFileHandle.Close()
        }
    } Catch Error as e_session_init {
        MsgBox("警告: 初始化当前会话日志时发生异常: " . FullSessionLogPath . "`n" . e_session_init.Message . "`n会话日志功能可能受影响。", "剪贴板记录器 - 会话日志警告", 48)
    }
    Return True ; 初始化成功
}

EnsureHistoryFolderExists() { ; 确保历史记录文件夹存在 (供后续写入时调用)
    Global FullHistoryFolderPath
    If !DirExist(FullHistoryFolderPath) {
        Try {
            DirCreate(FullHistoryFolderPath)
            If !DirExist(FullHistoryFolderPath) {
                MsgBox("警告: 无法自动创建/访问历史记录文件夹: " . FullHistoryFolderPath . "`n后续历史记录可能失败。请检查权限。", "剪贴板记录器 - 文件夹问题", 48)
                Return False
            }
        } Catch Error as e {
            MsgBox("警告: 尝试创建历史记录文件夹时发生异常: " . FullHistoryFolderPath . "`n" . e.Message . "`n后续历史记录可能失败。", "剪贴板记录器 - 文件夹问题", 48)
            Return False
        }
    }
    Return True
}

ClipboardChangeHandler(Type) { ; 剪贴板内容变化时的处理函数
    ; Type 参数: 1=文本, 2=图片, 3=文件列表, 4=其他 (此脚本主要处理文本)
    Global FullHistoryFolderPath, FullSessionLogPath, LogTimestampsInEntry, EntryTimestampFormat, MinCharsToLog, LastLoggedClipboardContent

    If (Type = 1) { ; 仅处理文本类型的剪贴板内容
        local ClipText := ""      ; 用于存储原始剪贴板文本
        local attempts := 0       ; 读取剪贴板的尝试次数
        local maxAttempts := 5    ; 最大尝试次数
        local success := False    ; 标记是否成功读取

        ; 尝试多次读取剪贴板, 增加稳定性 (有时剪贴板可能暂时无法访问)
        while (attempts < maxAttempts && !success) {
            attempts++
            try {
                ClipText := A_Clipboard ; 获取剪贴板内容
                success := True         ; 如果没有错误, 则标记为成功
            } catch Error as e {
                if (attempts = maxAttempts) { ; 如果达到最大尝试次数仍失败
                    MsgBox("错误: 尝试 " . maxAttempts . " 次后仍无法读取剪贴板内容。`n最后错误: " . e.Message . "`n本次剪贴板变化将被忽略。", "剪贴板记录器 - 读取错误", 48)
                    Return ; 放弃处理本次变化
                }
                Sleep(150) ; 等待片刻后重试
            }
        }

        if (!success) {
            Return
            } ; 如果最终未能成功读取, 则直接返回

        ; !!! 关键步骤: 清理剪贴板内容, 去除首尾的空格、制表符等空白字符 !!!
        local CleanedClipText := Trim(ClipText)

        ; 如果清理后的内容为空字符串, 则直接返回, 不进行后续处理和记录
        if (StrLen(CleanedClipText) == 0) {
            Return
        }
        
        ; --- 路径规范化与屏蔽判断 ---
        local normalizedClipTextForCheck := CleanedClipText ; 后续的路径检查和规范化都基于这个清理后的文本

        ; 1. 移除可能存在的 "file:///" URI 前缀
        if (SubStr(normalizedClipTextForCheck, 1, 8) == "file:///") {
            normalizedClipTextForCheck := SubStr(normalizedClipTextForCheck, 9) ; 提取第9个字符之后的部分
        }
        ; 2. 将路径中的所有正斜杠 "/" 替换为反斜杠 "\", 以便统一比较
        normalizedClipTextForCheck := StrReplace(normalizedClipTextForCheck, "/", "\")

        ; --- 需要屏蔽的路径前缀定义 (请根据你的实际情况修改和添加) ---
        ; 注意: 这些路径使用反斜杠 '\', 并且应该与 normalizedClipTextForCheck 中的格式一致
        local pathToBlock1_Prefix := "D:\005_tools\PixPin\Temp\PixPin_"
        local pathToBlock2_Prefix := "D:\0000_bookmark\Picture_saving\000_收藏夹\Clip_" ; 示例: 包含中文和特定层级
        local pathToBlock3_Prefix := "D:\0000_bookmark\Picture_saving\PixPin_"       ; 示例: PixPin直接保存的路径
        
        ; --- 目标文件扩展名定义 (用于屏蔽判断) ---
        local targetExtension_WithDot := ".png" ; 目标扩展名, 包含点号, 使用小写
        local lenTargetExtension_WithDot := StrLen(targetExtension_WithDot) ; 计算扩展名长度 (例如 ".png" 是 4)

        ; --- 提取路径末尾的后缀部分 ---
        local currentExtractedSuffix := ""
        if (StrLen(normalizedClipTextForCheck) >= lenTargetExtension_WithDot) { ; 确保字符串长度足够提取后缀
            ; 从末尾提取 lenTargetExtension_WithDot 个字符 (例如, 对于 ".png", 提取最后4个字符)
            currentExtractedSuffix := SubStr(normalizedClipTextForCheck, -lenTargetExtension_WithDot)
        }

        ; ; --- (可选) 调试用的 ToolTip, 如果过滤仍有问题可以取消注释来查看比较的值 ---
        ; ToolTip("原始 ClipText: [" . ClipText . "]"
        ; . "`n清理后 CleanedClipText: [" . CleanedClipText . "]"
        ; . "`n用于检查的 Normalized Path: [" . normalizedClipTextForCheck . "]"
        ; . "`n提取的后缀 currentExtractedSuffix: [" . currentExtractedSuffix . "] (转小写后: [" . StrLower(currentExtractedSuffix) . "])"
        ; . "`n目标后缀 targetExtension_WithDot: [" . targetExtension_WithDot . "]", 0, 0, 3) ; 使用不同的 ToolTip ID
        ; Sleep(5000) ; 给足够的时间查看 ToolTip 内容
        ; ToolTip ,, , 3 ; 清除指定 ID 的 ToolTip
        ; ; --- 调试 ToolTip 结束 ---

        ; --- 判断是否应该屏蔽当前剪贴板内容 ---
        local shouldBlock := false ; 默认为不屏蔽
        if (currentExtractedSuffix != "") { ; 只有成功提取到后缀时才进行判断 (避免空后缀导致误判)
            ; 条件: 路径以任一预设前缀开头 AND 提取的后缀(转小写后)与目标扩展名匹配
            if ( (InStr(normalizedClipTextForCheck, pathToBlock1_Prefix) == 1 && StrLower(currentExtractedSuffix) == targetExtension_WithDot) ||
                 (InStr(normalizedClipTextForCheck, pathToBlock2_Prefix) == 1 && StrLower(currentExtractedSuffix) == targetExtension_WithDot) ||
                 (InStr(normalizedClipTextForCheck, pathToBlock3_Prefix) == 1 && StrLower(currentExtractedSuffix) == targetExtension_WithDot) )
            {
                shouldBlock := true ; 标记为需要屏蔽
            }
        }
        
        if (shouldBlock) { ; 如果标记为屏蔽
            Return ; 则直接返回, 不记录此条剪贴板内容
        }
        
        ; --- 检查是否与上次记录的内容重复 (基于清理后的文本) ---
        If (CleanedClipText == LastLoggedClipboardContent) {
            Return ; 如果内容与上次记录的相同, 则直接返回, 避免重复记录
        }

        ; --- 检查清理后的文本长度是否达到最小记录要求 ---
        If (StrLen(CleanedClipText) >= MinCharsToLog) { 
            
            local StringToAppend := "" ; 初始化要追加到日志文件的字符串

            ; --- 构建 Markdown 格式的日志条目 ---
            StringToAppend .= "`r`n---`r`n`r`n" ; 1. Markdown 分隔线 (新条目开始)

            If (LogTimestampsInEntry) { ; 2. 时间戳行 (如果启用)
                StringToAppend .= "*Copied at: " . Chr(96) . FormatTime(, EntryTimestampFormat) . Chr(96) . "*`r`n`r`n" ; 使用反引号 ` 标记时间
            }
            
            local StartCodeBlock := Chr(96) . Chr(96) . Chr(96) . "text" ; ```text
            local EndCodeBlock := Chr(96) . Chr(96) . Chr(96)      ; ```

            StringToAppend .= StartCodeBlock . "`r`n" ; 3. Markdown 代码块开始
            StringToAppend .= ClipText                 ;    粘贴原始剪贴板内容 (保留原始格式, 包括首尾空格和换行)
            StringToAppend .= "`r`n" . EndCodeBlock   ;    Markdown 代码块结束
            ; --- Markdown 格式构建结束 ---

            local HistoryLogSuccess := False
            If EnsureHistoryFolderExists() { ; 确保历史日志文件夹存在
                local CurrentDateStr := FormatTime(, "yyyy-MM-dd") ; 获取当前日期字符串 (用作文件名)
                local TodayLogFilePath := FullHistoryFolderPath . "\" . CurrentDateStr . ".md" ; 构建当日历史日志文件路径
                local IsNewDailyFile := !FileExist(TodayLogFilePath) ; 判断是否是新的一天 (文件是否已存在)
                Try {
                    local LogFileHandle := FileOpen(TodayLogFilePath, "a", "UTF-8") ; 以追加模式、UTF-8编码打开日志文件
                    If (IsObject(LogFileHandle)) {
                        If (IsNewDailyFile) { ; 如果是新的一天的日志文件
                            LogFileHandle.Write("# Daily Clipboard Log: " . CurrentDateStr . "`r`n`r`n") ; 写入每日日志的H1标题
                        }
                        LogFileHandle.Write(StringToAppend) ; 写入格式化后的剪贴板内容
                        LogFileHandle.Close()
                        HistoryLogSuccess := True
                    } Else {
                        MsgBox("错误: 未能打开历史日志文件进行写入: " . TodayLogFilePath, "剪贴板记录器 - 文件错误", 16)
                    }
                } Catch Error as e_hist {
                    MsgBox("错误: 写入历史日志文件失败: " . TodayLogFilePath . "`n详情: " . e_hist.Message, "剪贴板记录器 - 写入错误", 16)
                }
            }

            local SessionLogSuccess := False
            Try {
                local LogFileHandle := FileOpen(FullSessionLogPath, "a", "UTF-8") ; 以追加模式打开当前会话日志
                If (IsObject(LogFileHandle)) {
                    LogFileHandle.Write(StringToAppend) ; 写入内容
                    LogFileHandle.Close()
                    SessionLogSuccess := True
                } Else {
                    MsgBox("错误: 未能打开当前会话日志文件进行写入: " . FullSessionLogPath, "剪贴板记录器 - 文件错误", 16)
                }
            } Catch Error as e_sess {
                MsgBox("错误: 写入当前会话日志文件失败: " . FullSessionLogPath . "`n详情: " . e_sess.Message, "剪贴板记录器 - 写入错误", 16)
            }

            If (!HistoryLogSuccess && !SessionLogSuccess) {
                MsgBox("严重警告: 当前复制的内容未能记录到任何日志文件！请检查之前的错误信息。", "剪贴板记录器 - 完全记录失败", 16)
            }
            
            ; 更新上次记录的内容为当前清理后的文本, 用于下一次重复检查
            LastLoggedClipboardContent := CleanedClipText 
        }
    }
}

; ------------------------------------------------------------------------------
;                            剪贴板记录器 - 托盘菜单及辅助函数
; ------------------------------------------------------------------------------
SetupTrayMenu() { ; 设置脚本在系统托盘区的右键菜单
    Global FullHistoryFolderPath ; 确保能访问全局变量

    ; --- 设置自定义托盘图标 ---
    Try {
        ; 使用 TraySetIcon 函数设置自定义图标
        TraySetIcon("shell32.dll", 28) ; 使用 shell32.dll 中的图标，索引为 28 (一个剪贴板图标)
        
        ; 或者使用自定义 .ico 文件 (如果存在)
        local customIconPath := A_ScriptDir . "\my_clipboard_icon.ico"
        If FileExist(customIconPath) {
            TraySetIcon(customIconPath)
        }
    } Catch Error as e {
        MsgBox("设置托盘图标时发生错误: " . e.Message . "`n将使用默认AHK图标。", "托盘图标错误", 16)
    }
    ; --- 自定义托盘图标设置结束 ---

    A_TrayMenu.Delete() ; 清空默认的托盘菜单项

    A_TrayMenu.Add("在 Obsidian 中打开当前会话记录", ViewSessionLogInObsidian_MenuHandler)
    A_TrayMenu.Add("在 Obsidian 中打开今日历史记录", OpenTodayLogInObsidian_MenuHandler)
    A_TrayMenu.Add("打开历史记录文件夹", ViewLogFolder_MenuHandler)
    A_TrayMenu.Add() ; 添加分隔线
    A_TrayMenu.Add("退出剪贴板记录器", ExitLogger_MenuHandler)
    
    UpdateTrayToolTip() ; 更新托盘图标的提示文字
}

UrlEncode(str) { ; 简单的 URL 编码函数 (主要处理空格)
    str := StrReplace(str, " ", "%20")
    ; 如有需要, 可在此添加对其他特殊字符的替换, 例如:
    ; str := StrReplace(str, "#", "%23")
    ; str := StrReplace(str, "&", "%26")
    Return str
}

ViewSessionLogInObsidian_MenuHandler(*) { ; 菜单项处理: 在 Obsidian 中打开当前会话日志
    Global FullSessionLogPath, ObsidianVaultName, ObsidianVaultBasePath
    
    If (!ObsidianVaultName || !ObsidianVaultBasePath) {
        MsgBox("错误: Obsidian Vault 名称或基础路径未在脚本中配置。", "剪贴板记录器 - 配置错误", 16)
        Return
    }
    If (!DirExist(ObsidianVaultBasePath)) {
        MsgBox("错误: Obsidian Vault 基础路径 (" . ObsidianVaultBasePath . ") 不存在或无法访问。", "剪贴板记录器 - 配置错误", 16)
        Return
    }

    If FileExist(FullSessionLogPath) {
        ; 从 Obsidian Vault 基础路径计算相对路径
        local relativeFilePath := StrReplace(FullSessionLogPath, ObsidianVaultBasePath . "\", "") 
        relativeFilePath := StrReplace(relativeFilePath, "\", "/") ; Obsidian URI 需要使用正斜杠

        local encodedVaultName := UrlEncode(ObsidianVaultName)
        local encodedFilePath := UrlEncode(relativeFilePath) ; 文件路径也进行编码以防特殊字符
        
        local obsidianURI := "obsidian://open?vault=" . encodedVaultName . "&file=" . encodedFilePath
        Try {
            Run(obsidianURI) ; 尝试通过 URI 打开
        } Catch Error as e {
            MsgBox("错误: 无法在 Obsidian 中打开会话日志。"
                . "`nURI: " . obsidianURI
                . "`n错误: " . e.Message, "剪贴板记录器 - Obsidian错误", 16)
        }
    } Else {
        MsgBox("提示: 当前会话日志文件 (" . FullSessionLogPath . ") 尚未创建或无内容。", "剪贴板记录器", 64)
    }
}

OpenTodayLogInObsidian_MenuHandler(*) { ; 菜单项处理: 在 Obsidian 中打开今日历史日志
    Global FullHistoryFolderPath, ObsidianVaultName, ObsidianVaultBasePath
    
    If (!ObsidianVaultName || !ObsidianVaultBasePath) {
        MsgBox("错误: Obsidian Vault 名称或基础路径未在脚本中配置。", "剪贴板记录器 - 配置错误", 16)
        Return
    }
    If (!DirExist(ObsidianVaultBasePath)) {
        MsgBox("错误: Obsidian Vault 基础路径 (" . ObsidianVaultBasePath . ") 不存在或无法访问。", "剪贴板记录器 - 配置错误", 16)
        Return
    }

    If !EnsureHistoryFolderExists() {
        Return
        } ; 确保历史文件夹存在
    local CurrentDateStr := FormatTime(, "yyyy-MM-dd")
    local TodayLogFilePath := FullHistoryFolderPath . "\" . CurrentDateStr . ".md"

    If FileExist(TodayLogFilePath) {
        local relativeFilePath := StrReplace(TodayLogFilePath, ObsidianVaultBasePath . "\", "")
        relativeFilePath := StrReplace(relativeFilePath, "\", "/")

        local encodedVaultName := UrlEncode(ObsidianVaultName)
        local encodedFilePath := UrlEncode(relativeFilePath)
        
        local obsidianURI := "obsidian://open?vault=" . encodedVaultName . "&file=" . encodedFilePath
        Try {
            Run(obsidianURI)
        } Catch Error as e {
            MsgBox("错误: 无法在 Obsidian 中打开今日历史日志。"
                . "`nURI: " . obsidianURI
                . "`n错误: " . e.Message, "剪贴板记录器 - Obsidian错误", 16)
        }
    } Else {
        MsgBox("提示: 今日历史日志文件 (" . TodayLogFilePath . ") 尚未创建或无内容。", "剪贴板记录器", 64)
    }
}

ViewLogFolder_MenuHandler(*) { ; 菜单项处理: 打开历史日志存放的文件夹
    Global FullHistoryFolderPath
    If !EnsureHistoryFolderExists() {
        Return
        } ; 确保文件夹存在
    
    If DirExist(FullHistoryFolderPath) {
        Try {
            Run(FullHistoryFolderPath) ; 打开文件夹
        } Catch Error as e {
            MsgBox("错误: 打开历史日志文件夹失败: " . FullHistoryFolderPath . "`n" . e.Message, "剪贴板记录器 - 打开错误", 16)
        }
    } Else { ; 理论上 EnsureHistoryFolderExists 之后这里不应触发, 作为额外保险
        MsgBox("错误: 历史日志文件夹路径无效或无法访问: " . FullHistoryFolderPath, "剪贴板记录器 - 内部错误", 16)
    }
}

ExitLogger_MenuHandler(*) { ; 菜单项处理: 退出脚本
    ExitApp ; 退出当前 AutoHotkey 脚本应用程序
}

UpdateTrayToolTip() { ; 更新系统托盘图标的鼠标悬停提示文字
    A_TrayMenu.ToolTip := "剪贴板记录器 (运行中) - v" . A_AhkVersion ; 可以加入版本号等信息
}