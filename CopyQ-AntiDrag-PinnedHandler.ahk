#Requires AutoHotkey v2.0
#SingleInstance Force
#Warn ; Enable warnings to catch potential issues

A_TitleMatchMode := 2 ; 设置标题匹配模式为2 (部分匹配)

; Script Name:      CopyQ-AntiDrag-PinnedHandler.ahk
; Author:           ssaerwgf
; Version:          1.0.0
; Last Updated:     2025-05-31
; License:          MIT License (https://opensource.org/licenses/MIT)
; Repository:       https://github.com/ssaerwgf/AHK-CopyQ-AntiDrag-PinnedHandler-ObsidianMDLogger
; Forum Thread:     https://www.autohotkey.com/boards/viewtopic.php?f=83&t=137459

/*
  Description:
    An AutoHotkey v2 script that provides enhancements and helper functionalities
    for the CopyQ clipboard manager, improving usability for common scenarios.
  
  Features:
    - "Anti-Drag": Sends an 'Esc' key command when a drag gesture (left mouse button
      pressed and moved) is detected over a CopyQ window, preventing accidental drags.
    - "Anti-Interference": Disables the native Ctrl+C (copy) command when a CopyQ
      window is active to prevent unintended behavior.
    - "Dialog Automation": Automatically handles CopyQ's "Cannot remove pinned item"
      dialog by sending 'Enter' and a follow-up command to potentially unpin the item.
  
  Dependencies:
    - AutoHotkey v2.0 or higher (Required)
    - CopyQ Clipboard Manager (Required, must be installed and running)
  
  Configuration:
    - This script is generally designed to work out-of-the-box with default CopyQ settings.
    - Internal variables (e.g., CopyQExeName, CopyQWinClass) can be reviewed if issues arise.
    - Refer to README.md on GitHub for any further details if needed.
*/


; --- 全局配置 ---
global CopyQExeName := "copyq.exe"
global CopyQWinClass := "ahk_class Qt653QWindowIcon" ; CopyQ 窗口通用的 ahk_class

; --- Script 1: LButton 拖拽发送 Esc 的配置 ---
global CopyQWinCriteriaForEscTarget := "ahk_exe " CopyQExeName " " CopyQWinClass ; 用于 Esc 的 CopyQ 窗口标准
global DragThreshold := 10      ; 鼠标移动阈值 (像素)
global DragCheckPollInterval := 15 ; 鼠标移动检查间隔 (毫秒)

; --- Script 1: MouseIsOverCopyQ 优化缓存状态 ---
global g_lastHoverWinID := 0
global g_lastHoverWinIsCopyQ := false

; --- Script 2: 对话框处理配置 ---
DialogWindowTitle := "不能移除已经固定的条目 - CopyQ"
DialogWindowAhkExe := "ahk_exe " CopyQExeName ; 使用全局的 CopyQExeName
DialogCriteria := DialogWindowTitle " " CopyQWinClass " " DialogWindowAhkExe ; 组合成完整标准

; ==============================================================================
; 函数定义 (来自 Script 1)
; ==============================================================================

MouseIsOverCopyQ() {
    ; Explicitly declare globals used
    global g_lastHoverWinID
    global g_lastHoverWinIsCopyQ
    global CopyQExeName ; <--- ***** IMPORTANT: Make global variable accessible *****

    local currentHoverWinID
    MouseGetPos(,, &currentHoverWinID)

    ; If mouse is over the same window as last time, return cached result
    If (currentHoverWinID == g_lastHoverWinID && g_lastHoverWinID != 0) {
        Return g_lastHoverWinIsCopyQ
    }

    ; Mouse is over a new window or first check
    g_lastHoverWinID := currentHoverWinID
    g_lastHoverWinIsCopyQ := false ; Default to false for the new window

    If currentHoverWinID && DllCall("IsWindow", "Ptr", currentHoverWinID)
    {
        Try
        {
            local hoverWinExe := WinGetProcessName("ahk_id " currentHoverWinID)
            If (hoverWinExe == CopyQExeName) {
                g_lastHoverWinIsCopyQ := true
            }
            ; If not CopyQ, or if CopyQExeName was empty due to scope issue (now fixed),
            ; g_lastHoverWinIsCopyQ remains false.
        }
        Catch OSError As e ; Catch potential errors, especially Access Denied
        {
            ; OutputDebug "WinGetProcessName failed for HWND " currentHoverWinID ". Error: " e.Message " (" e.Number ")"
            ; If an error occurs (e.g., Access Denied), we can't get the process name.
            ; Assume it's not CopyQ. g_lastHoverWinIsCopyQ remains false.
        }
    }
    ; If currentHoverWinID is 0 or window is invalid, g_lastHoverWinIsCopyQ also remains false.
    
    Return g_lastHoverWinIsCopyQ
}

IsCopyQActive() {
    global CopyQWinCriteriaForEscTarget ; 复用已有的 CopyQ 窗口判断标准
    Return WinActive(CopyQWinCriteriaForEscTarget)
}


; ==============================================================================
; 热键定义 (来自 Script 1)
; ==============================================================================

; 仅当鼠标悬停在 CopyQ 窗口上时激活此热键
#HotIf MouseIsOverCopyQ()
$LButton::
{
    local startX, startY, currentX, currentY
    local isDraggingAttempt := false
    local initialTargetWinID 

    MouseGetPos(&startX, &startY, &initialTargetWinID) 

    local LButtonIsStillDown := true

    Loop
    {
        If !GetKeyState("LButton", "P") {
            LButtonIsStillDown := false
            Break
        }

        MouseGetPos &currentX, &currentY
        local dX := Abs(currentX - startX)
        local dY := Abs(currentY - startY)

        If (dX > DragThreshold Or dY > DragThreshold)
        {
            isDraggingAttempt := true
            
            local mainCopyQhWnd := WinExist(CopyQWinCriteriaForEscTarget) ; 使用配置的窗口标准
            If mainCopyQhWnd
            {
                ControlSend "{Esc}",, "ahk_id " mainCopyQhWnd
            }
            Else If initialTargetWinID && DllCall("IsWindow", "Ptr", initialTargetWinID) 
            {
                If WinGetProcessName("ahk_id " initialTargetWinID) == CopyQExeName
                    ControlSend "{Esc}",, "ahk_id " initialTargetWinID
            }
            
            Return ; 检测到拖拽并发送 Esc，退出热键
        }
        Sleep DragCheckPollInterval
    }

    If !isDraggingAttempt ; 并且 LButtonIsStillDown 现在为 false (由于循环中断条件)
    {
        Click ; 执行普通点击
        Return
    }
    Return
}
#HotIf ; 关闭上下文敏感热键


#HotIf IsCopyQActive()
$^c:: ; 使用 $ 前缀确保 AHK 的键盘钩子被使用，并阻止原生功能
{
    Return ; 什么也不做，从而禁用复制功能
}
#HotIf ; 关闭 IsCopyQActive() 的上下文敏感，恢复全局热键

; ==============================================================================
; 后台对话框处理 (来自 Script 2) - 这部分代码将在脚本启动时自动运行
; ==============================================================================

Loop {
    ; 1. 等待对话框出现
    WinWait DialogCriteria ; 使用配置的对话框标准
    TargetWinID := WinExist(DialogCriteria) ; <--- 移除了 'local'

    If !TargetWinID {
        Continue ; 对话框在 WinWait 和 WinExist 之间消失了，重新等待
    }
    
    OriginalActiveWinID := WinActive("A") ; <--- 移除了 'local'

    ; 2. 激活对话框并发送 Enter
    WinActivate "ahk_id " TargetWinID
    If WinWaitActive("ahk_id " TargetWinID, , 0.2) { ; 超时缩短到 200ms
        Send "{Enter}"
        Sleep 20 ; 给 Send 和窗口响应的极短延时
    } Else {
        ; 激活失败，可能对话框自行关闭或出现问题
        If OriginalActiveWinID && OriginalActiveWinID != TargetWinID && WinExist("ahk_id " OriginalActiveWinID) {
            WinActivate "ahk_id " OriginalActiveWinID
        }
        Continue 
    }

    ; 3. 等待对话框关闭
If WinWaitClose("ahk_id " TargetWinID, , 0.7) { ; 超时缩短到 700ms
    ; 4. 假设焦点已自动回到 CopyQ 主窗口，直接发送 !c
    Sleep 50 ; 关键延时: 给主窗口极短的反应时间
    Send "! c"  ; Alt+Space, C
    Sleep 100 ; 给 CopyQ 处理命令的时间
} Else {
        ; 对话框未按预期关闭
        If WinActive("ahk_id " TargetWinID) && OriginalActiveWinID && OriginalActiveWinID != TargetWinID && WinExist("ahk_id " OriginalActiveWinID) {
            WinActivate "ahk_id " OriginalActiveWinID ; 尝试恢复焦点
        }
    }
    ; 循环回到 WinWait 等待下一次对话框
}

; 脚本末尾
Return