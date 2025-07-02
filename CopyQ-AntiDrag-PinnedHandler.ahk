#Requires AutoHotkey v2.0
#SingleInstance Force
#Warn ; Enable warnings to catch potential issues

A_TitleMatchMode := 2 ; 设置标题匹配模式为2 (部分匹配)

; Script Name:      CopyQ-AntiDrag-PinnedHandler.ahk
; Author:           ssaerwgf
; Version:          2.0.2
; Last Updated:     2025-07-02
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

    - "Dialog Automation": Automatically handles CopyQ's "Cannot remove pinned item"
      dialog by sending 'Enter' and a follow-up command to potentially unpin the item.

    - "Auto-Close on Click-Away": Automatically closes the CopyQ window when the user clicks
      anywhere outside of it, helping to keep the workspace tidy.

    - "Dynamic Protection Mode": Features an intelligent protection system. After CopyQ is
      launched, the user's first click automatically activates the protection mode, enabling
      core features like Anti-Drag and Focus Redirection.

    - "Session-Level Protection Toggle": Allows the user to 'permanently' disable protection
      mode for the current session with a single right-click on the CopyQ window. This makes
      it easy to change settings or perform other direct interactions without script interference.

    - "Seamless Focus Management": Proactively prevents CopyQ from stealing focus. After closing
      CopyQ, the script intelligently restores focus to the last active window, ensuring an
      uninterrupted workflow.
   
    - "Status Notification System": Provides feedback on the protection mode's status (e.g.,
      'Enabled', 'Disabled for this session') via unobtrusive tooltips, keeping the user
      informed of the script's current state.
  
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

; --- 焦点管理和自动关闭配置 ---
global g_LastValidWindow := 0        ; 记录最后一个有效的非CopyQ窗口
global g_FocusRedirectActive := false ; 焦点重定向是否激活
global g_CopyQMonitorTimer := 0      ; CopyQ监控定时器
global FocusCheckInterval := 50      ; 焦点检查间隔（毫秒）

; --- 新的保护模式状态管理 ---
global g_ProtectionEnabled := false   ; 保护功能状态（默认关闭）
global g_SessionProtectionLocked := false ; 本次会话保护是否被锁定（右键点击后）
global g_FirstClickInSession := true  ; 是否是本次会话的第一次点击
global g_CurrentSessionID := 0         ; 当前会话ID

; ==============================================================================
; 初始化
; ==============================================================================

; 启动时立即记录当前窗口
RecordCurrentValidWindow()

; 启动CopyQ存在性监控
SetTimer(MonitorCopyQPresence, 250)

; ==============================================================================
; 核心功能函数
; ==============================================================================

; 记录当前有效窗口（非CopyQ、非系统窗口）
RecordCurrentValidWindow() {
    global g_LastValidWindow, CopyQExeName
    
    try {
        CurrentWin := WinGetID("A")
        if (!CurrentWin) {
            return
        }
        
        ProcessName := WinGetProcessName("ahk_id " CurrentWin)
        WinClass := WinGetClass("ahk_id " CurrentWin)
        
        ; 排除CopyQ和系统窗口
        if (ProcessName != CopyQExeName && 
            WinClass != "Shell_TrayWnd" && 
            WinClass != "Shell_SecondaryTrayWnd" && 
            WinClass != "WorkerW" && 
            WinClass != "Progman" &&
            WinClass != "#32770") {
            g_LastValidWindow := CurrentWin
        }
    } catch {
        ; 忽略错误
    }
}

; 监控CopyQ的存在并管理会话状态
MonitorCopyQPresence() {
    global g_FocusRedirectActive, g_CopyQMonitorTimer, CopyQExeName, FocusCheckInterval
    global g_CurrentSessionID, g_FirstClickInSession, g_SessionProtectionLocked, g_ProtectionEnabled
    
    static lastCopyQState := false
    currentCopyQState := WinExist("ahk_exe " CopyQExeName) ? true : false
    
    ; 检测CopyQ从关闭到打开的转换（新会话开始）
    if (!lastCopyQState && currentCopyQState) {
        ; 新会话开始
        g_CurrentSessionID := A_TickCount
        g_FirstClickInSession := true
        g_SessionProtectionLocked := false
        g_ProtectionEnabled := false  ; 新会话默认关闭保护
        
        ; 显示提示
        ToolTip("CopyQ已打开 - 保护模式: 关闭`n首次点击将自动开启保护")
        SetTimer(() => ToolTip(), -2000)
    }
    
    ; 更新焦点重定向状态
    if (currentCopyQState) {
        if (!g_FocusRedirectActive) {
            g_FocusRedirectActive := true
            g_CopyQMonitorTimer := SetTimer(RedirectFocusFromCopyQ, FocusCheckInterval)
        }
    } else {
        if (g_FocusRedirectActive) {
            g_FocusRedirectActive := false
            if (g_CopyQMonitorTimer) {
                SetTimer(g_CopyQMonitorTimer, 0)
                g_CopyQMonitorTimer := 0
            }
        }
    }
    
    lastCopyQState := currentCopyQState
}

; 焦点重定向核心函数
RedirectFocusFromCopyQ() {
    global g_LastValidWindow, CopyQExeName, g_ProtectionEnabled
    
    ; 只有在保护模式启用时才进行焦点重定向
    if (!g_ProtectionEnabled) {
        return
    }
    
    try {
        ActiveWin := WinGetID("A")
        if (!ActiveWin) {
            return
        }
        
        ActiveProcess := WinGetProcessName("ahk_id " ActiveWin)
        
        ; 如果当前活动窗口是CopyQ
        if (ActiveProcess == CopyQExeName) {
            ; 立即切换到最后记录的有效窗口
            if (g_LastValidWindow && WinExist("ahk_id " g_LastValidWindow)) {
                WinActivate("ahk_id " g_LastValidWindow)
            } else {
                ; 如果没有记录的窗口，尝试找到一个有效窗口
                FindAndActivateValidWindow()
            }
        } else {
            ; 如果不是CopyQ，更新有效窗口记录
            RecordCurrentValidWindow()
        }
    } catch {
        ; 忽略错误
    }
}

; 查找并激活一个有效窗口
FindAndActivateValidWindow() {
    global CopyQExeName, g_LastValidWindow
    
    Windows := WinGetList()
    
    for Hwnd in Windows {
        try {
            ProcessName := WinGetProcessName("ahk_id " Hwnd)
            WinClass := WinGetClass("ahk_id " Hwnd)
            WinTitle := WinGetTitle("ahk_id " Hwnd)
            
            if (ProcessName != CopyQExeName && 
                WinTitle != "" &&
                WinClass != "Shell_TrayWnd" && 
                WinClass != "WorkerW" && 
                WinClass != "Progman") {
                WinActivate("ahk_id " Hwnd)
                g_LastValidWindow := Hwnd
                break
            }
        } catch {
            continue
        }
    }
}

; 鼠标是否在CopyQ上的检测函数
MouseIsOverCopyQ() {
    global g_lastHoverWinID
    global g_lastHoverWinIsCopyQ
    global CopyQExeName

    local currentHoverWinID
    MouseGetPos(,, &currentHoverWinID)

    If (currentHoverWinID == g_lastHoverWinID && g_lastHoverWinID != 0) {
        Return g_lastHoverWinIsCopyQ
    }

    g_lastHoverWinID := currentHoverWinID
    g_lastHoverWinIsCopyQ := false

    If currentHoverWinID && DllCall("IsWindow", "Ptr", currentHoverWinID)
    {
        Try
        {
            local hoverWinExe := WinGetProcessName("ahk_id " currentHoverWinID)
            If (hoverWinExe == CopyQExeName) {
                g_lastHoverWinIsCopyQ := true
            }
        }
        Catch OSError As e
        {
            ; If an error occurs, assume it's not CopyQ
        }
    }
    
    Return g_lastHoverWinIsCopyQ
}

; ==============================================================================
; 全局左键处理
; ==============================================================================

~LButton::
{
    global CopyQExeName, g_LastValidWindow
    global g_LastClickTime, ClickCooldownMs
    global g_FirstClickInSession, g_SessionProtectionLocked, g_ProtectionEnabled
    
    ; 检查CopyQ是否存在
    CopyQExists := WinExist("ahk_exe " CopyQExeName)
    if (!CopyQExists) {
        return
    }
      
    ; 获取点击位置
    MouseGetPos(,, &ClickedWinID)
    if (!ClickedWinID) {
        return
    }
    
    try {
        ClickedProcess := WinGetProcessName("ahk_id " ClickedWinID)
        
        if (ClickedProcess == CopyQExeName) {
            ; 点击的是CopyQ窗口
            if (g_FirstClickInSession && !g_SessionProtectionLocked) {
                ; 这是本会话的第一次点击，开启保护
                g_ProtectionEnabled := true
                g_FirstClickInSession := false
                
                ToolTip("保护模式已自动开启`n右键点击可永久关闭")
                SetTimer(() => ToolTip(), -2000)
            }
        } else {
            ; 点击的不是CopyQ - 始终关闭CopyQ（不受保护模式影响）
            WinClass := WinGetClass("ahk_id " ClickedWinID)
            if (WinClass != "Shell_TrayWnd" && 
                WinClass != "Shell_SecondaryTrayWnd" && 
                WinClass != "WorkerW" && 
                WinClass != "Progman") {
                g_LastValidWindow := ClickedWinID
            }
            
            ; 延迟关闭CopyQ
            SetTimer(CloseCopyQDelayed, -100)
        }
    } catch {
        ; 忽略错误
    }
}

; 延迟关闭CopyQ
CloseCopyQDelayed() {
    global CopyQExeName
    
    if (CopyQWin := WinExist("ahk_exe " CopyQExeName)) {
        WinClose("ahk_id " CopyQWin)
    }
}

; ==============================================================================
; 右键点击处理 - 本会话永久关闭保护
; ==============================================================================

#HotIf MouseIsOverCopyQ()
~RButton::
{
    global g_SessionProtectionLocked, g_ProtectionEnabled
    
    if (!g_SessionProtectionLocked) {
        ; 锁定本会话的保护功能为关闭状态
        g_SessionProtectionLocked := true
        g_ProtectionEnabled := false
        
        ToolTip("本次会话保护已永久关闭`n可以正常操作CopyQ设置")
        SetTimer(() => ToolTip(), -3000)
    }
}
#HotIf

; ==============================================================================
; 防拖拽功能
; ==============================================================================

#HotIf MouseIsOverCopyQ()
$LButton::
{
    global g_LastClickTime, ClickCooldownMs
    global g_FirstClickInSession, g_SessionProtectionLocked, g_ProtectionEnabled
     
    ; 处理首次点击逻辑
    if (g_FirstClickInSession && !g_SessionProtectionLocked) {
        g_ProtectionEnabled := true
        g_FirstClickInSession := false
        
        ToolTip("保护模式已自动开启`n右键点击可永久关闭")
        SetTimer(() => ToolTip(), -2000)
    }
    
    ; 防拖拽逻辑
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
            
            local mainCopyQhWnd := WinExist(CopyQWinCriteriaForEscTarget)
            If mainCopyQhWnd
            {
                ControlSend "{Esc}",, "ahk_id " mainCopyQhWnd
            }
            Else If initialTargetWinID && DllCall("IsWindow", "Ptr", initialTargetWinID) 
            {
                If WinGetProcessName("ahk_id " initialTargetWinID) == CopyQExeName
                    ControlSend "{Esc}",, "ahk_id " initialTargetWinID
            }
            
            Return
        }
        Sleep DragCheckPollInterval
    }

    If !isDraggingAttempt
    {
        Click
        Return
    }
    Return
}
#HotIf

; ==============================================================================
; 后台对话框处理
; ==============================================================================

Loop {
    ; 等待对话框出现
    WinWait DialogCriteria
    TargetWinID := WinExist(DialogCriteria)

    If !TargetWinID {
        Continue
    }
    
    ; 记录原始活动窗口
    OriginalActiveWinID := WinActive("A")

    ; 激活对话框并处理
    WinActivate "ahk_id " TargetWinID
    
    ; 使用更短的超时时间（50ms），因为 WinActivate 是同步操作
    If WinWaitActive("ahk_id " TargetWinID, , 0.05) {
        ; 立即发送 Enter 键关闭对话框，无需延时
        Send "{Enter}"
        
        ; 使用更短的超时时间（200ms）等待对话框关闭
        If WinWaitClose("ahk_id " TargetWinID, , 0.2) {
            ; 对话框已关闭，立即查找并关闭 CopyQ 主窗口
            
            if (CopyQMainWin := WinExist("ahk_exe " CopyQExeName " " CopyQWinClass)) {
                ; 直接关闭，不等待
                WinClose("ahk_id " CopyQMainWin)
                
                ; 使用极短的超时（100ms）检查是否需要强制关闭
                if (!WinWaitClose("ahk_id " CopyQMainWin, , 0.1)) {
                    ; 立即强制关闭
                    WinKill("ahk_id " CopyQMainWin)
                }
            }
            
            ; 恢复原始活动窗口
            if (OriginalActiveWinID && WinExist("ahk_id " OriginalActiveWinID)) {
                try {
                    ; 使用不同的局部变量名，避免与其他函数中的变量冲突
                    origWinProcessName := WinGetProcessName("ahk_id " OriginalActiveWinID)
                    if (origWinProcessName != CopyQExeName) {
                        WinActivate "ahk_id " OriginalActiveWinID
                    }
                } catch {
                    ; 忽略错误
                }
            }
        } else {
            ; 对话框没有按预期关闭，立即恢复原窗口
            If OriginalActiveWinID && OriginalActiveWinID != TargetWinID && WinExist("ahk_id " OriginalActiveWinID) {
                WinActivate "ahk_id " OriginalActiveWinID
            }
        }
    } else {
        ; 无法激活对话框窗口，立即恢复原窗口
        If OriginalActiveWinID && OriginalActiveWinID != TargetWinID && WinExist("ahk_id " OriginalActiveWinID) {
            WinActivate "ahk_id " OriginalActiveWinID
        }
        Continue 
    }
}