#Requires AutoHotkey v2.0

; 防止直接运行插件文件
if (A_ScriptName = "InputGuardian.plugin.ahk") {
    MsgBox("请不要直接运行插件文件！`n`n请运行 InputTip.ahk 主程序", "InputGuardian", "Icon!")
    ExitApp()
}

SetTimer(() => InputGuardian.CheckAndInit(), -2000)

; Script Name:      InputGuardian-InputTip-plugin.ahk (InputGuardian Plugin for InputTip)
; Author:           ssaerwgf (逐浪承光启新途)
; Version:          1.0.0
; Last Updated:     2025-08-11
; License:          MIT License (https://opensource.org/licenses/MIT)
; Repository:       https://github.com/ssaerwgf/AHK-CopyQ-AntiDrag-PinnedHandler-ObsidianMDLogger
; Forum Thread:     https://www.autohotkey.com/boards/viewtopic.php?f=83&t=137459
;
; Based on InputTip by abgox
; InputTip Repository: https://github.com/abgox/InputTip
; InputTip License: MIT License
; InputTip Author: abgox (https://github.com/abgox)

/*
  NOTICE:
    This is a plugin for InputTip (https://github.com/abgox/InputTip), an input
    method status management tool created by abgox. InputGuardian extends InputTip's
    functionality by adding text input history management and clipboard monitoring
    features.
    
    This plugin requires InputTip v2025.07.20 to be installed and running.
    It will not function as a standalone application.

  ACKNOWLEDGMENTS:
    Special thanks to abgox for creating InputTip, which provides the essential
    foundation for this plugin through its caret detection and window management
    systems.

  DESCRIPTION:
    InputGuardian is a productivity plugin that fuses two powerful concepts into 
    a unified, intelligent system: a version control for your thoughts (InputGuardian) 
    and a history for your clipboard (ClipSidian).
    
    Think of it as a silent digital archivist with two distinct roles:
    1. The 'Librarian' (InputGuardian): Silently versions your work in any text field,
       capturing snapshots whenever you pause or submit. It's the safety net that
       protects your writing from being lost.
    2. The 'Historian' (ClipSidian): Diligently records everything you *intentionally*
       copy (Ctrl+C), creating a searchable daily log of reference materials.

    The system's core ingenuity lies in its ability to distinguish between these two 
    actions. It knows when *it* is performing an automatic backup versus when *you* 
    are deliberately copying something, ensuring your clipboard history remains pure 
    and relevant.

  FEATURES:
    - Dual-Track Architecture:
        - InputGuardian (The Librarian): Creates a versioned history of your writing
          sessions, organized by application and time, complete with Git-style diffs
          to track every change.
        - ClipSidian (The Historian): Maintains a clean, chronological log of everything
          you manually copy, stored in daily, easy-to-read Markdown files.

    - Intelligent Boundary System:
        - Saves a snapshot when you pause to think (no keyboard/mouse activity for a set time).
        - Proactively saves the final version when you press Enter or Ctrl+Enter.

    - Intelligent Clipboard Management:
        - Capture Isolation: Prevents the script's own automated capture sequences from 
          polluting the clipboard history.
        - De-duplication: Avoids logging identical, consecutively copied content.
        - Path Blocking: Allows specific file paths to be excluded from the clipboard log.

    - Deep System Integration:
        - Context-Aware Operation: Automatically detects when the user switches between 
          applications or windows.
        - InputTip Whitelist: Inherits the window whitelisting from InputTip, ensuring 
          it only runs where intended.
        - Optional CopyQ Integration: Prevents cluttering the CopyQ history during 
          automated text capture operations.

  DEPENDENCIES:
    - AutoHotkey v2.0 or higher (Required)
    - InputTip v2025.07.20 (Required): https://github.com/abgox/InputTip
      This plugin relies on InputTip's core functionalities:
        * returnCanShowSymbol() - for caret detection
        * GetCaretPosEx() - for cursor position
        * validateMatch() - for window whitelist validation
        * app_ShowSymbol/app_HideSymbol - for application filtering
    - CopyQ Clipboard Manager (Optional): Enhanced clipboard management

  INSTALLATION:
    1. Install InputTip from https://github.com/abgox/InputTip
    2. Place this plugin file (InputGuardian.plugin.ahk) in the InputTip plugins folder
    3. Configure the plugin settings in the IGConfig class below
    4. Run InputTip.ahk (the plugin will load automatically)

  CONFIGURATION:
    All primary settings are centralized within the `IGConfig` class below.
    Users can easily configure:
        - File paths for Session logs, History logs, and general logs
        - The full path to the `copyq.exe` executable
        - Behavioral thresholds like minimum text length and pause detection time
        - The `PathBlockList` to exclude specific clipboard content
        - `DebugMode` for verbose logging
    
    Please see the repository README for detailed configuration instructions.

  COPYRIGHT AND LICENSE:
    Copyright (c) 2025 ssaerwgf
    
    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:
    
    The above copyright notice and this permission notice shall be included in all
    copies or substantial portions of the Software.
    
    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
    SOFTWARE.
*/

; --- 插件配置 ---
class IGConfig {
    ; InputGuardian配置
    static HistoryBasePath := A_ScriptDir . "\InputGuardian\History"
    static SessionsBasePath := A_ScriptDir . "\InputGuardian\Sessions"
    static LogPath := A_ScriptDir . "\InputGuardian\Logs"
    static MinTextLength := 1
    static MinKeyPressCount := 1
    static SnapshotCooldown := 2000
    static CopyQExePath := "D:\005_tools\CopyQ\copyq.exe"  ; <- 修改为你的 CopyQ 路径
    static UseCopyQ := true
    static DebugMode := false
    static CopyQResponseTimeout := 100
    static PauseDetectionTime := 3000  ; 3秒检测输入暂停
    static MinActivityCount := 1       ; 最小活动数（键盘+鼠标）
    
    ; ClipSidian配置（整合自原文件）
    static LogTimestampsInEntry := true
    static EntryTimestampFormat := "HH:mm:ss"
    
    ; 路径屏蔽配置（来自ClipSidian）
    static PathBlockList := [
        {
            prefix: "D:\005_tools\PixPin\Temp\PixPin_",  ; <- 修改为你的截图工具临时目录1/3
            extension: ".png"
        },
        {
            prefix: "D:\0000_bookmark\Picture_saving\000_收藏夹\Clip_",  ; <- 修改为你的截图工具临时目录2/3
            extension: ".png"
        },
        {
            prefix: "D:\0000_bookmark\Picture_saving\PixPin_",  ; <- 修改为你的截图工具临时目录3/3
            extension: ".png"
        }
    ]
}


; === 全局捕获状态管理器 ===
class GlobalCaptureManager {
    static isCapturing := false
    static captureSource := ""
    static captureStartTime := 0
    static captureTimeout := 5000
    
    ; 统一的开始捕获方法
    static BeginCapture(source) {
        ; 检查是否有超时的捕获任务
        if (this.isCapturing) {
            if (A_TickCount - this.captureStartTime > this.captureTimeout) {
                IGLogger.Log("WARN", Format("捕获超时 ({1})，强制重置", this.captureSource))
                this.EndCapture(false)
            } else {
                IGLogger.Log("WARN", Format("捕获进行中 ({1})，拒绝新请求 ({2})", 
                    this.captureSource, source))
                return false
            }
        }
        
        ; 设置捕获状态
        this.isCapturing := true
        this.captureSource := source
        this.captureStartTime := A_TickCount
        
        IGLogger.Log("DEBUG", Format("开始捕获: {1}", source))
        return true
    }
    
    ; 统一的结束捕获方法
    static EndCapture(success := true) {
        if (!this.isCapturing) {
            return
        }
        
        duration := A_TickCount - this.captureStartTime
        IGLogger.Log("DEBUG", Format("结束捕获 ({1})，耗时: {2}ms，结果: {3}", 
            this.captureSource, duration, success ? "成功" : "失败"))
        
        ; 重置状态
        this.isCapturing := false
        this.captureSource := ""
        this.captureStartTime := 0
    }
}


class UnifiedClipboardManager {
    static lastClipboardContent := ""
    static lastCapturedContent := ""  ; 新增：记录最后捕获的内容
    static captureContentHash := ""  ; 新增：内容哈希值
    
    static Init() {
        OnClipboardChange(ObjBindMethod(this, "OnClipboardChange"), 1)
        IGLogger.Log("INFO", "剪贴板监听器已注册")
    }
    
    ; 计算内容哈希的辅助方法
    static CalculateHash(text) {
        hash := 0
        Loop Parse, text {
            hash := ((hash << 5) - hash + Ord(A_LoopField)) & 0xFFFFFFFF
        }
        return Format("{:08X}", hash)
    }
    
    ; 改进的剪贴板变化处理
    static OnClipboardChange(Type) {
        if (Type != 1) {
            return
        }
        
        ; 使用全局捕获管理器检查状态
        if (GlobalCaptureManager.isCapturing) {
            IGLogger.Log("DEBUG", Format("检测到 {1} 捕获，跳过剪贴板历史", 
                GlobalCaptureManager.captureSource))
            return
        }
        
        ; 获取剪贴板内容
        clipText := ""
        try {
            clipText := A_Clipboard
        } catch {
            return
        }
        
        ; 计算当前内容的哈希
        currentHash := this.CalculateHash(clipText)
        
        ; 多重检查，确保不是自己捕获的内容
        if (clipText == this.lastCapturedContent || 
            currentHash == this.captureContentHash ||
            clipText == this.lastClipboardContent) {
            IGLogger.Log("DEBUG", "检测到重复内容或自捕获内容，跳过")
            return
        }
        
        ; 时间窗口检查（增加到500ms，更保险）
        if (A_TickCount - GlobalCaptureManager.captureStartTime < 500) {
            IGLogger.Log("DEBUG", "在捕获时间窗口内，可能是延迟事件，跳过")
            return
        }
        
        this.lastClipboardContent := clipText
        
        ; 确认是用户的主动复制
        IntegratedClipboardHandler.ProcessUserCopy(clipText)
    }
}

class CopyQHelper {
    static isDisabled := false
    static lastDisableTime := 0
    
    ; 添加缺失的RunCommand方法
    static RunCommand(command) {
        if (!IGConfig.UseCopyQ || !FileExist(IGConfig.CopyQExePath)) {
            return false
        }
        
        try {
            ; 使用更可靠的方式执行命令
            Run(IGConfig.CopyQExePath . " " . command, , "Hide")
            Sleep(IGConfig.CopyQResponseTimeout)
            return true
        } catch as e {
            IGLogger.Log("WARN", "CopyQ 命令执行失败: " . command . " - " . e.Message)
            return false
        }
    }
    
    ; 修改后的Disable方法
    static Disable() {
        if (this.isDisabled) {
            IGLogger.Log("DEBUG", "CopyQ已经处于禁用状态，跳过")
            return true
        }
        
        ; 防止过于频繁的操作
        if (A_TickCount - this.lastDisableTime < 50) {
            IGLogger.Log("DEBUG", "距离上次操作太近，延迟执行")
            Sleep(50)
        }
        
        success := this.RunCommand("disable")
        if (success) {
            this.isDisabled := true
            this.lastDisableTime := A_TickCount
            IGLogger.Log("DEBUG", "CopyQ监控已禁用")
        }
        return success
    }
    
    ; 修改后的Enable方法
    static Enable() {
        if (!this.isDisabled) {
            IGLogger.Log("DEBUG", "CopyQ已经处于启用状态，跳过")
            return true
        }
        
        ; 给一个最小延迟，确保操作完成
        Sleep(20)
        
        success := this.RunCommand("enable")
        if (success) {
            this.isDisabled := false
            IGLogger.Log("DEBUG", "CopyQ监控已启用")
        }
        return success
    }
}

; 整合的剪贴板处理器（原ClipSidian功能）
class IntegratedClipboardHandler {
    static LastLoggedContent := ""
    static FullHistoryFolderPath := ""
    
    ; 初始化
    static Init() {
        this.FullHistoryFolderPath := IGConfig.HistoryBasePath
        
        ; 确保历史文件夹存在
        if (!DirExist(this.FullHistoryFolderPath)) {
            try {
                DirCreate(this.FullHistoryFolderPath)
                IGLogger.Log("INFO", "创建剪贴板历史文件夹: " . this.FullHistoryFolderPath)
            } catch as e {
                IGLogger.Log("ERROR", "创建历史文件夹失败: " . e.Message)
            }
        }
    }
    
    ; 处理用户主动复制的内容
    static ProcessUserCopy(clipText) {
        IGLogger.Log("DEBUG", "=== 剪贴板处理开始 ===")
        IGLogger.Log("DEBUG", Format("原始文本长度: {1}", StrLen(clipText)))
        IGLogger.Log("DEBUG", Format("原始文本前50字符: [{1}]", SubStr(clipText, 1, 50)))

        IGLogger.Log("DEBUG", Format("处理用户复制，长度: {1}, 时间戳: {2}", 
            StrLen(clipText), A_TickCount))
        
        ; 清理文本
        cleanedText := Trim(clipText)
        if (StrLen(cleanedText) == 0) {
            return
        }
        IGLogger.Log("DEBUG", Format("清理后文本: [{1}]", cleanedText))
        
        ; 路径屏蔽判断 - 修正逻辑
        IGLogger.Log("DEBUG", "准备进行路径屏蔽判断...")
        if (this.ShouldBlockPath(cleanedText)) {
            IGLogger.Log("INFO", Format("路径被屏蔽，跳过记录: {1}", cleanedText))
            return  ; 立即返回，不再执行后续操作
        }
        
        IGLogger.Log("DEBUG", "路径检查通过，继续处理")
        
        ; 检查长度要求
        if (StrLen(cleanedText) >= IGConfig.MinTextLength) {
            this.LogToHistory(clipText, cleanedText)
            this.LastLoggedContent := cleanedText
            IGLogger.Log("SUCCESS", Format("用户剪贴板内容已记录，长度: {1}", StrLen(clipText)))
        }
    }
    
    ; 路径屏蔽判断（保留原ClipSidian逻辑）
    static ShouldBlockPath(text) {
        IGLogger.Log("DEBUG", Format("ShouldBlockPath 被调用，文本: [{1}]", text))
        
        ; 规范化路径检查
        normalizedPath := text
        
        ; 移除可能的file:///前缀
        if (SubStr(normalizedPath, 1, 8) == "file:///") {
            normalizedPath := SubStr(normalizedPath, 9)
            IGLogger.Log("DEBUG", "移除了file:///前缀")
        }
        
        ; 统一路径分隔符
        normalizedPath := StrReplace(normalizedPath, "/", "\")
        IGLogger.Log("DEBUG", Format("规范化后的路径: [{1}]", normalizedPath))
        
        ; 检查每个屏蔽规则
        for rule in IGConfig.PathBlockList {
            IGLogger.Log("DEBUG", Format("检查规则 - 前缀: [{1}], 扩展名: [{2}]", 
                rule.prefix, rule.HasProp("extension") ? rule.extension : "无"))
            
            ; 规范化规则前缀（移除多余的反斜杠）
            normalizedPrefix := StrReplace(rule.prefix, "\\", "\")

            ; 检查是否以指定前缀开头
            if (InStr(normalizedPath, normalizedPrefix) == 1) {
                IGLogger.Log("DEBUG", "前缀匹配成功")
                
                ; 检查扩展名
                if (rule.HasProp("extension") && rule.extension != "") {
                    extLen := StrLen(rule.extension)
                    if (StrLen(normalizedPath) >= extLen) {
                        ; 直接获取最后 extLen 个字符
                        extractedExt := SubStr(normalizedPath, StrLen(normalizedPath) - extLen + 1)
                        IGLogger.Log("DEBUG", Format("提取的扩展名: [{1}]", extractedExt))
                        IGLogger.Log("DEBUG", Format("期望的扩展名: [{1}]", rule.extension))
                        IGLogger.Log("DEBUG", Format("扩展名匹配结果: {1}", StrLower(extractedExt) == StrLower(rule.extension)))
                        
                        if (StrLower(extractedExt) == StrLower(rule.extension)) {
                            IGLogger.Log("INFO", Format("路径符合屏蔽规则: {1}", normalizedPath))
                            return true  ; 应该屏蔽
                        }
                    }
                } else {
                    ; 如果没有指定扩展名，只要前缀匹配就屏蔽
                    IGLogger.Log("INFO", Format("路径符合屏蔽规则（仅前缀）: {1}", normalizedPath))
                    return true
                }
            }
        }
        
        IGLogger.Log("DEBUG", "路径不符合任何屏蔽规则")
        return false
    }
    
    ; 记录到历史文件（保留原ClipSidian的Markdown格式）
    static LogToHistory(originalText, cleanedText) {
        dateStr := FormatTime(, "yyyy-MM-dd")
        historyFile := this.FullHistoryFolderPath . "\" . dateStr . ".md"
        
        ; 定义代码块标记
        codeBlock := Chr(96) . Chr(96) . Chr(96)
        
        ; 构建Markdown格式条目
        entry := "`r`n---`r`n`r`n"
        
        if (IGConfig.LogTimestampsInEntry) {
            timeStr := FormatTime(, IGConfig.EntryTimestampFormat)
            entry .= "*Copied at: " . Chr(96) . timeStr . Chr(96) . "*`r`n`r`n"
        }
        
        entry .= codeBlock . "text`r`n"
        entry .= originalText
        entry .= "`r`n" . codeBlock
        
        try {
            ; 如果是新文件，添加标题
            isNewFile := !FileExist(historyFile)
            
            if (isNewFile) {
                header := "# Daily Clipboard Log: " . dateStr . "`r`n`r`n"
                FileAppend(header, historyFile, "UTF-8")
            }
            
            ; 追加内容
            FileAppend(entry, historyFile, "UTF-8")
            
            IGLogger.Log("SUCCESS", Format("剪贴板历史已记录，长度: {1}", StrLen(originalText)))
        } catch as e {
            IGLogger.Log("ERROR", "记录剪贴板历史失败: " . e.Message)
        }
    }
}

; 触发策略管理器
class IGTriggerStrategy {
    static priorities := Map(
        "user_submit", 1,     ; 用户主动提交优先级最高
        "input_pause", 2     ; 输入暂停
    )
    
    static lastTriggerTime := 0
    static lastTriggerType := ""
    
    static ShouldTrigger(triggerType, context) {
        currentTime := A_TickCount
        
        ; 冷却时间检查（保持不变）
        if (currentTime - this.lastTriggerTime < IGConfig.SnapshotCooldown) {
            lastPriority := this.priorities.Get(this.lastTriggerType, 999)
            currentPriority := this.priorities.Get(triggerType, 999)
            
            if (currentPriority >= lastPriority) {
                IGLogger.Log("DEBUG", Format("拒绝触发 {1}，冷却中", triggerType))
                return false
            }
        }
        
        ; 对于用户主动提交，采用不同的验证策略
        if (triggerType == "user_submit") {
            ; 如果上下文中已经包含捕获的文本，检查文本内容
            if (context.HasProp("text")) {
                ; 确保有实质内容（不只是空白字符）
                cleanText := Trim(context.text)
                if (StrLen(cleanText) == 0) {
                    IGLogger.Log("DEBUG", "用户主动保存但内容为空，跳过")
                    return false
                }
            }
            
            ; 用户主动保存，且有内容，直接通过
            this.lastTriggerTime := currentTime
            this.lastTriggerType := triggerType
            return true
        }
        
        ; 其他触发类型（如 input_pause）仍然需要检查按键数
        if (context.HasProp("keyPressCount") && 
            context.keyPressCount < IGConfig.MinKeyPressCount) {
            IGLogger.Log("DEBUG", Format("按键数不足 {1}/{2}", 
                context.keyPressCount, IGConfig.MinKeyPressCount))
            return false
        }
        
        this.lastTriggerTime := currentTime
        this.lastTriggerType := triggerType
        return true
    }
}

; 专门用于光标恢复的PostMessage实现类
class CursorRestorer {
    ; 主恢复方法
    static RestoreCursor(savedX, savedY) {
        ; 获取当前窗口信息
        hwnd := WinExist("A")
        if (!hwnd) {
            IGLogger.Log("ERROR", "无法获取活动窗口句柄")
            return false
        }
        
        ; 将屏幕坐标转换为客户区坐标
        clientCoords := this.ScreenToClient(hwnd, savedX, savedY)
        if (!clientCoords.success) {
            IGLogger.Log("ERROR", "坐标转换失败")
            return false
        }
        
        ; 发送点击消息
        return this.SendMouseClick(hwnd, clientCoords.x, clientCoords.y)
    }
    
    ; 坐标转换方法
    static ScreenToClient(hwnd, screenX, screenY) {
        ; 创建POINT结构体
        point := Buffer(8)
        NumPut("Int", screenX, point, 0)
        NumPut("Int", screenY, point, 4)
        
        ; 调用Windows API进行坐标转换
        success := DllCall("User32.dll\ScreenToClient", "Ptr", hwnd, "Ptr", point)
        
        if (success) {
            return {
                success: true,
                x: NumGet(point, 0, "Int"),
                y: NumGet(point, 4, "Int")
            }
        } else {
            return {success: false, x: 0, y: 0}
        }
    }
    
    ; 发送鼠标点击消息
    static SendMouseClick(hwnd, clientX, clientY) {
        ; 打包坐标到lParam
        ; 低16位是X坐标，高16位是Y坐标
        lParam := (clientY << 16) | (clientX & 0xFFFF)
        
        ; 发送鼠标按下消息
        ; WM_LBUTTONDOWN = 0x0201
        ; wParam = 1 表示左键按下
        result1 := PostMessage(0x0201, 1, lParam, , "ahk_id " hwnd)
        
        ; 短暂延迟，确保消息被处理
        Sleep(100)
        
        ; 发送鼠标释放消息
        ; WM_LBUTTONUP = 0x0202
        ; wParam = 0 表示没有键按下
        result2 := PostMessage(0x0202, 0, lParam, , "ahk_id " hwnd)
        
        return result1 && result2
    }
}

; --- 主插件类 ---
class InputGuardian {
    static instance := ""
    static isRunning := false
    static initialized := false
    
    ; 组件
    static boundaryMonitor := ""
    static versionControl := ""

    static checkInitTimer := ""
    static checkInitFunc := ""
    
    ; 检查当前窗口是否在InputTip白名单中
    static IsInWhiteList() {
        try {
            ; 获取当前窗口信息
            exe_name := ProcessGetName(WinGetPID("A"))
            exe_title := WinGetTitle("A")
            
            ; 复用InputTip的validateMatch函数
            if (IsSet(validateMatch) && IsSet(app_ShowSymbol)) {
                ; 首先检查是否在黑名单中
                if (IsSet(app_HideSymbol) && validateMatch(exe_name, exe_title, app_HideSymbol)) {
                    IGLogger.Log("DEBUG", Format("窗口在黑名单中: {1} - {2}", exe_name, exe_title))
                    return false
                }
                
                ; 然后检查是否在白名单中
                isInWhite := validateMatch(exe_name, exe_title, app_ShowSymbol)
                IGLogger.Log("DEBUG", Format("白名单检查: {1} - {2} = {3}", 
                    exe_name, exe_title, isInWhite ? "通过" : "失败"))
                return isInWhite
            }
            
            ; 如果无法访问白名单系统，默认返回false
            IGLogger.Log("WARN", "无法访问InputTip白名单系统")
            return false
        } catch as e {
            IGLogger.Log("ERROR", "白名单检查失败: " . e.Message)
            return false
        }
    }

    static CheckAndInit() {

        ; 如果没有预创建的函数引用，创建它
        if (!this.checkInitFunc) {
            this.checkInitFunc := ObjBindMethod(this, "CheckAndInit")
        }


        ; 立即初始化日志系统（如果需要的话）
        if (!IGLogger.initialized) {
            ; 确保基础目录存在
            if (!DirExist(A_ScriptDir . "\InputGuardian")) {
                DirCreate(A_ScriptDir . "\InputGuardian")
            }
            IGLogger.Init()
            IGLogger.Log("INFO", "========== InputGuardian 整合版插件初始化开始 ==========")
            IGLogger.Log("INFO", "版本: 4.0.0 - 包含ClipSidian功能")
            IGLogger.Log("INFO", "脚本目录: " . A_ScriptDir)
        }
        
        if (!this.VerifyInputTipEnvironment()) {
            IGLogger.Log("ERROR", "InputTip环境不完整，插件无法启动")
            IGLogger.ShowStatus("InputGuardian: 环境检查失败，请确保InputTip正常运行", 5000)
            return false
        }
        
        ; 核心检查
        if (!IsSet(returnCanShowSymbol) || Type(returnCanShowSymbol) != "Func") {
            IGLogger.Log("DEBUG", "等待 returnCanShowSymbol 函数可用")
            ; 使用改进的定时器管理
            this.SetCheckInitTimer()
            return false
        }
        
        ; 快速功能测试
        try {
            local left := 0, top := 0, right := 0, bottom := 0
            returnCanShowSymbol(&left, &top, &right, &bottom)
            
            ; 清除定时器（如果存在）
            this.ClearCheckInitTimer()
            
            this.InitializeComponents()
            IGLogger.Log("SUCCESS", "InputGuardian 初始化完成")
            
            SetTimer(() => this.Start(), -1000)
            return true
        } catch as e {
            IGLogger.Log("WARN", "等待InputTip就绪: " . e.Message)
            this.SetCheckInitTimer()
            return false
        }
    }

    ; 添加辅助方法
    static SetCheckInitTimer() {
        ; 确保不会重复创建定时器
        if (!this.checkInitTimer) {
            this.checkInitTimer := this.checkInitFunc
            SetTimer(this.checkInitTimer, -1000)
        }
    }

    static ClearCheckInitTimer() {
        if (this.checkInitTimer) {
            SetTimer(this.checkInitTimer, 0)
            this.checkInitTimer := ""
        }
    }

    static InitializeComponents() {
        this.EnsureDirectories()
        
        ; 初始化各组件
        this.boundaryMonitor := IGBoundaryMonitor()
        this.versionControl := IGVersionControl()
        
        ; 初始化剪贴板处理器
        IntegratedClipboardHandler.Init()

        UnifiedClipboardManager.Init()

        ; 在所有组件初始化后设置清理定时器
        SetTimer(() => IGVersionControl.CleanupFailedWrites(), 600000)  ; 每10分钟清理一次

        SetTimer(() => IGVersionControl.FlushMemoryCache(), 300000)  ; 每5分钟尝试刷新缓存
        
        this.initialized := true
        
        IGLogger.Log("SUCCESS", "所有组件初始化完成，包含自动清理机制")
    }
        
    ; 启动监控
    static Start() {
        if (this.isRunning) {
            return
        }
        
        ; 检查当前窗口是否在白名单中
        if (!this.IsInWhiteList()) {
            IGLogger.Log("INFO", "当前窗口不在白名单中，延迟启动监控")
            ; 设置定时器，等待切换到白名单窗口
            SetTimer(() => this.CheckAndStartMonitoring(), 1000)
            return
        }

        this.isRunning := true
        this.boundaryMonitor.Start()
        
        IGLogger.ShowStatus("InputGuardian已启动（含剪贴板监控）", 2000)
    }

    static CheckAndStartMonitoring() {
        if (this.isRunning) {
            SetTimer(, 0)  ; 停止定时器
            return
        }
        
        if (this.IsInWhiteList()) {
            SetTimer(, 0)  ; 停止定时器
            this.isRunning := true
            this.boundaryMonitor.Start()
            IGLogger.ShowStatus("InputGuardian已启动（进入白名单窗口）", 2000)
        }
    }

    
    ; 停止监控
    static Stop() {
        if (!this.isRunning) {
            return
        }
        
        this.isRunning := false
        this.boundaryMonitor.Stop()
        
        IGLogger.ShowStatus("InputGuardian已停止", 2000)
    }

    static VerifyInputTipEnvironment() {
        ; 验证必要的InputTip函数
        requiredFunctions := ["returnCanShowSymbol", "GetCaretPosEx", "isCN", "validateMatch"]
        
        for funcName in requiredFunctions {
            if (!IsSet(%funcName%) || Type(%funcName%) != "Func") {
                IGLogger.Log("ERROR", funcName . " 函数不可用")
                return false
            }
        }
        
        ; 验证全局变量
        requiredVars := ["exe_name", "exe_str", "modeList", "screenList", "app_ShowSymbol", "app_HideSymbol"]
        for varName in requiredVars {
            if (!IsSet(%varName%)) {
                IGLogger.Log("ERROR", varName . " 变量不可用")
                return false
            }
        }
        
        IGLogger.Log("SUCCESS", "InputTip环境验证通过（包括白名单系统）")
        return true
    }
    
    static OnBoundaryDetected(eventType, context) {
        ; 增强的日志记录
        IGLogger.Log("DEBUG", Format("边界事件详情 - 类型: {1}, 按键数: {2}, 窗口: {3}", 
            eventType, 
            context.HasProp("keyPressCount") ? context.keyPressCount : "N/A",
            context.HasProp("windowTitle") ? context.windowTitle : "未知"))

        ; 检查白名单
        if (!this.IsInWhiteList()) {
            IGLogger.Log("DEBUG", "当前窗口不在白名单中，跳过处理")
            return
        }

        try {
            ; 确保在输入框中
            if (!this.IsInTextInput()) {
                IGLogger.Log("INFO", Format("边界事件 {1} 触发时不在输入框中，跳过", eventType))
                return
            }

            IGLogger.Log("INFO", Format("处理边界事件: {1}", eventType))

            ; 获取光标边界信息
            if (!context.HasProp("cursorBounds")) {
                cursorBounds := this.GetCursorBounds()
                if (cursorBounds.valid) {
                    context.cursorBounds := cursorBounds
                }
            }
            
            ; 应用触发策略
            if (!IGTriggerStrategy.ShouldTrigger(eventType, context)) {
                return
            }
            
            ; 处理已包含文本的情况
            if (context.HasProp("text") && StrLen(context.text) > 0) {
                this.versionControl.ProcessSnapshot(context.text, context)
                
                preview := SubStr(context.text, 1, 50)
                if (StrLen(context.text) > 50) {
                    preview .= "..."
                }
                IGLogger.ShowStatus(Format("已捕获 [{1}]: {2}", eventType, preview), 2000)
                return
            }
            
            ; 检查输入活动
            if (context.HasProp("keyPressCount") && 
                context.keyPressCount < IGConfig.MinKeyPressCount) {
                IGLogger.Log("DEBUG", "输入活动不足")
                return
            }

            ; 执行文本捕获
            capturedText := this.boundaryMonitor.CaptureText()

            if (StrLen(capturedText) > 0) {
                this.versionControl.ProcessSnapshot(capturedText, context)
                
                preview := SubStr(capturedText, 1, 50)
                if (StrLen(capturedText) > 50) {
                    preview .= "..."
                }
                IGLogger.ShowStatus(Format("已捕获 [{1}]: {2}", eventType, preview), 2000)
            }
        } catch as e {
            IGLogger.Log("ERROR", Format("处理边界事件失败: {1}", e.Message))
        }
    }

    ; 确保目录存在
    static EnsureDirectories() {
        dirs := [
            IGConfig.HistoryBasePath,
            IGConfig.SessionsBasePath,
            IGConfig.SessionsBasePath . "\Temp",
            IGConfig.LogPath
        ]
        
        ; 记录要创建的目录
        IGLogger.Log("INFO", "开始创建必要目录...")
        
        for dir in dirs {
            if (!DirExist(dir)) {
                try {
                    ; 创建目录
                    DirCreate(dir)
                    IGLogger.Log("INFO", "创建目录: " . dir)
                    
                    ; 验证创建成功
                    if (!DirExist(dir)) {
                        IGLogger.Log("ERROR", "目录创建失败（未抛出异常）: " . dir)
                        
                        ; 尝试使用备用路径
                        if (InStr(dir, "\Temp")) {
                            ; 对于Temp目录，使用脚本目录作为备用
                            fallbackDir := A_ScriptDir . "\InputGuardian_Temp"
                            try {
                                DirCreate(fallbackDir)
                                IGLogger.Log("WARN", "使用备用Temp目录: " . fallbackDir)
                                ; 更新配置中的路径
                                IGConfig.SessionsBasePath := A_ScriptDir . "\InputGuardian"
                            } catch {
                                IGLogger.Log("ERROR", "备用目录也创建失败")
                            }
                        }
                        continue
                    }
                    
                    ; 测试写入权限
                    testFile := dir . "\permission_test.tmp"
                    try {
                        FileAppend("test", testFile, "UTF-8")
                        FileDelete(testFile)
                        IGLogger.Log("DEBUG", "目录权限测试通过: " . dir)
                    } catch as permError {
                        IGLogger.Log("ERROR", "目录没有写入权限: " . dir . " - " . permError.Message)
                        
                        ; 如果是权限问题，尝试在用户文档目录创建
                        if (InStr(permError.Message, "Access") || InStr(permError.Message, "denied")) {
                            userDir := A_MyDocuments . "\InputGuardian"
                            if (!DirExist(userDir)) {
                                try {
                                    DirCreate(userDir)
                                    IGLogger.Log("INFO", "使用用户文档目录: " . userDir)
                                    
                                    ; 更新相应的配置路径
                                    if (InStr(dir, "History")) {
                                        IGConfig.HistoryBasePath := userDir . "\History"
                                    } else if (InStr(dir, "Sessions")) {
                                        IGConfig.SessionsBasePath := userDir . "\Sessions"
                                    } else if (InStr(dir, "Logs")) {
                                        IGConfig.LogPath := userDir . "\Logs"
                                    }
                                } catch {
                                    IGLogger.Log("ERROR", "无法在用户文档目录创建文件夹")
                                }
                            }
                        }
                    }
                } catch as e {
                    IGLogger.Log("ERROR", "创建目录失败: " . dir . " - " . e.Message)
                    
                    ; 记录详细的错误信息
                    if (InStr(e.Message, "Access") || InStr(e.Message, "denied")) {
                        IGLogger.Log("ERROR", "可能是权限问题，请以管理员身份运行或选择其他目录")
                    } else if (InStr(e.Message, "disk")) {
                        IGLogger.Log("ERROR", "可能是磁盘空间不足")
                    }
                }
            } else {
                IGLogger.Log("DEBUG", "目录已存在: " . dir)
            }
        }
        
        IGLogger.Log("INFO", "目录初始化完成")
    }
    
    static IsInTextInput() {
        local left := 0, top := 0, right := 0, bottom := 0
        ; 直接使用InputTip的核心功能
        return returnCanShowSymbol(&left, &top, &right, &bottom) && left > 0
    }

    static GetCursorBounds() {
        local left := 0, top := 0, right := 0, bottom := 0
        if (returnCanShowSymbol(&left, &top, &right, &bottom) && left > 0) {
            return {
                x: left,
                y: top,
                width: right - left,
                height: bottom - top,
                valid: true
            }
        }
        return {valid: false}
    }
    
    ; 新增：获取统计信息（包括剪贴板历史）
    static GetStatistics() {
        stats := this.boundaryMonitor.GetStatistics()
        
        ; 添加剪贴板历史统计
        try {
            dateStr := FormatTime(, "yyyy-MM-dd")
            historyFile := IGConfig.HistoryBasePath . "\" . dateStr . ".md"
            if (FileExist(historyFile)) {
                content := FileRead(historyFile, "UTF-8")
                ; 计算条目数（通过计算分隔线数量）
                count := 0
                pos := 1
                while (pos := InStr(content, "`r`n---`r`n", , pos)) {
                    count++
                    pos++
                }
                stats["今日剪贴板记录"] := count
            } else {
                stats["今日剪贴板记录"] := 0
            }
        } catch {
            stats["今日剪贴板记录"] := "无法读取"
        }
        
        return stats
    }
}

; --- 边界监控器（保持原有完整功能） ---
class IGBoundaryMonitor {
    lastMouseClickTime := 0
    mouseClickCount := 0
    lastFocusedWindow := ""      ; 真正拥有输入焦点的窗口
    lastFocusedTitle := ""       ; 焦点窗口的标题

    hotkeysEnabled := false  ; 跟踪热键当前状态

    ; 监控器
    windowMonitor := ""
    pauseMonitor := ""
    
    ; 状态
    lastKeyPressTime := 0
    keyPressCount := 0
    inputHook := ""

    ; === 失败冷却相关属性 ===
    captureFailureCount := 0        ; 连续失败次数
    lastCaptureFailureTime := 0     ; 上次失败时间
    isInFailureCooldown := false    ; 是否在失败冷却期
    failureCooldownEndTime := 0     ; 冷却结束时间
    failureNotificationGui := ""    ; 失败提示GUI

    ; === 定时器管理系统 ===
    activeTimers := Map()  ; 存储所有活动的定时器

    ; 失败冷却配置
    static FailureCooldownDurations := Map(
        1, 2000,    ; 首次失败：2秒
        2, 5000,    ; 第二次失败：5秒
        3, 10000    ; 三次及以上：10秒
    )

    stats := Map(
        "主动提交", 0,
        "输入暂停", 0
    )
    
    ; 启动监控
    Start() {
        IGLogger.Log("INFO", "启动边界监控器")
        
        ; 初始化增强监控功能
        this.InitializeEnhancedMonitoring()

        ; 设置输入钩子
        this.inputHook := InputHook("V")
        this.inputHook.KeyOpt("{All}", "N")
        this.inputHook.OnChar := ObjBindMethod(this, "OnKeyPress")
        this.inputHook.Start()
        
        ; 注册鼠标按键监听
        Hotkey("~LButton", ObjBindMethod(this, "OnMouseClick"), "On")
        Hotkey("~RButton", ObjBindMethod(this, "OnMouseClick"), "On")
        Hotkey("~MButton", ObjBindMethod(this, "OnMouseClick"), "On")

        ; 不再在这里直接注册热键，而是先创建热键但保持禁用状态
        try {
            ; 创建热键但初始状态为禁用
            Hotkey("Enter", ObjBindMethod(this, "OnSubmitKey"), "Off")
            Hotkey("^Enter", ObjBindMethod(this, "OnSubmitKey"), "Off")
            
            ; 根据当前窗口状态决定是否启用
            this.UpdateHotkeyState()
        } catch as e {
            IGLogger.Log("ERROR", "创建热键失败: " . e.Message)
        }
        
        ; 设置定时器
        this.windowMonitor := ObjBindMethod(this, "CheckWindowChange")
        SetTimer(this.windowMonitor, 500)
        
        this.pauseMonitor := ObjBindMethod(this, "CheckPauseTimeout")
        SetTimer(this.pauseMonitor, 1000)
               
        ; 初始化状态
        this.keyPressCount := 0
    }
    
    ; 停止监控
    Stop() {
        IGLogger.Log("INFO", "停止边界监控器")

        ; 停止所有定时器
        this.StopAllTimers()
        
        ; 停止输入钩子
        if (this.inputHook) {
            this.inputHook.Stop()
        }
        
        ; 禁用鼠标监听
        try {
            Hotkey("~LButton", "Off")
            Hotkey("~RButton", "Off") 
            Hotkey("~MButton", "Off")
        } catch {
            ; 忽略错误
        }
        
        ; 确保热键被禁用
        this.UpdateHotkeyState()
        
        ; 停止定时器
        if (this.windowMonitor) {
            SetTimer(this.windowMonitor, 0)
        }
        if (this.pauseMonitor) {  ; 改名
            SetTimer(this.pauseMonitor, 0)
        }
        this.StopAllTimers()
    }

    InitializeEnhancedMonitoring() {
        ; 初始化暂停状态
        this.pauseState := {
            hasTriggered: false,
            lastActivityCount: 0
        }
        
        ; 设置智能验证标志
        this.enableSmartValidation := true
        
        IGLogger.Log("INFO", "增强型边界监控已初始化（仅输入暂停检测）")
    }

    CaptureText() {
        capturedText := ""

        ; 使用全局捕获管理器
        if (!GlobalCaptureManager.BeginCapture("CaptureText")) {
            return ""
        }

        this.isLocalCapturing := true
        this.lastCaptureStartTime := A_TickCount

        ; 在方法开始就进行严格验证
        if (!InputGuardian.IsInTextInput()) {
            IGLogger.Log("WARN", "CaptureText: 不在输入框中，中止捕获")
            this.isLocalCapturing := false  ; 重置标志
            return ""
        }

        ; 验证窗口一致性
        currentHwnd := WinGetID("A")
        if (this.lastFocusedWindow && currentHwnd != this.lastFocusedWindow) {
            IGLogger.Log("WARN", "CaptureText: 当前窗口与记录窗口不一致")
            ; 尝试激活正确的窗口
            try {
                WinActivate("ahk_id " . this.lastFocusedWindow)
                if (!WinWaitActive("ahk_id " . this.lastFocusedWindow, , 0.1)) {
                    return ""
                }
            } catch {
                return ""
            }
        }

        ; 增强的窗口状态验证
        if (!WinExist("ahk_id " . currentHwnd)) {
            IGLogger.Log("ERROR", "当前窗口已不存在")
            return ""
        }

        ; 验证窗口是否可以接收输入
        if (!WinActive("ahk_id " . currentHwnd)) {
            IGLogger.Log("WARN", "窗口不是活动状态")
            ; 尝试激活
            try {
                WinActivate("ahk_id " . currentHwnd)
                if (!WinWaitActive("ahk_id " . currentHwnd, , 0.2)) {
                    IGLogger.Log("ERROR", "无法激活窗口")
                    return ""
                }
            } catch {
                return ""
            }
        }

        ; 检查冷却期
        if (this.isInFailureCooldown && A_TickCount < this.failureCooldownEndTime) {
            IGLogger.Log("INFO", "捕获功能在冷却期中，跳过本次捕获")
            return ""
        }
        
        ; 保存光标状态并进行二次验证
        local cursorInfo := this.SaveCursorState()
        if (!cursorInfo.valid) {
            IGLogger.Log("WARN", "无法获取有效的光标位置")
            return ""
        }
        
        ; 移除对宽度和高度的严格验证
        ; 因为宽度为0是正常的情况
        ; 只验证高度，因为高度为0确实是异常的
        if (cursorInfo.height <= 0) {
            IGLogger.Log("WARN", "光标高度异常")
            return ""
        }
                       
        try {
            ; 清空剪贴板（不保存原内容）
            A_Clipboard := ""
            
            ; 处理 CopyQ（如果启用）
            if (IGConfig.UseCopyQ) {
                CopyQHelper.Disable()
                Sleep(30)  ; 确保disable生效
            }
           
            ; 执行全选和复制
            SendInput("^a")
            Sleep(50)
            SendInput("^c")
            
            ; 等待剪贴板内容
            endTime := A_TickCount + 500
            while (A_Clipboard == "" && A_TickCount < endTime) {
                Sleep(10)
            }
            
            ; 获取捕获的文本
            capturedText := A_Clipboard

            ; 立即清空剪贴板
            A_Clipboard := ""

            ; 恢复光标位置
            CursorRestorer.RestoreCursor(cursorInfo.clickX, cursorInfo.clickY)
            
            ; 处理结果
            if (capturedText == "") {
                this.HandleCaptureFailure("timeout")
            } else {
                this.HandleCaptureSuccess()
            }
            
            return capturedText
            
        } catch as e {
            this.HandleCaptureFailure("exception")
            IGLogger.Log("ERROR", "捕获过程异常: " . e.Message)
            return ""
        } finally {
            ; 使用 try-catch 确保每个清理步骤都能执行
            try {
                GlobalCaptureManager.EndCapture(capturedText != "")
            } catch {
                ; 忽略错误，继续清理
            }
            
            this.isLocalCapturing := false
                        
            if (IGConfig.UseCopyQ) {
                Sleep(20)
                try {
                    CopyQHelper.Enable()
                } catch {
                    ; 忽略错误
                }
            }
        }
    }

    OnMouseClick(ThisHotkey := "") {  ; Accept the hotkey parameter
        this.lastMouseClickTime := A_TickCount
        this.mouseClickCount++
        this.ResetPauseState()
        IGLogger.Log("DEBUG", Format("鼠标点击 ({1})，总活动数: {2}", 
            ThisHotkey, this.keyPressCount + this.mouseClickCount))
    }

    ; 保存光标状态的辅助方法
    SaveCursorState() {
        local left := 0, top := 0, right := 0, bottom := 0
        
        if (returnCanShowSymbol(&left, &top, &right, &bottom)) {
            ; 只要有基本的位置信息就认为有效
            ; 不再要求 right > left，因为宽度为0是正常的
            if (left > 0 && top > 0) {
                ; 计算点击位置
                ; 如果宽度为0，点击位置就在left位置稍右一点
                clickX := (right > left) ? right : left + 1
                clickY := top + (bottom - top) / 2
                
                return {
                    valid: true,
                    left: left,
                    top: top,
                    right: right,
                    bottom: bottom,
                    clickX: clickX,
                    clickY: clickY,
                    width: right - left,
                    height: bottom - top
                }
            }
        }
        
        return {valid: false}
    }

    CheckWindowChange() {
        try {
            ; 获取当前焦点窗口信息
            focusInfo := this.GetRealInputFocus()
            if (!focusInfo.valid) {
                return
            }
            
            ; 检查是否是真正的窗口切换
            if (focusInfo.hwnd != this.lastFocusedWindow) {
                ; 记录窗口切换信息
                IGLogger.Log("INFO", Format("窗口切换: {1} -> {2}", 
                    this.lastFocusedTitle, focusInfo.title))
                
                ; 更新窗口状态
                this.lastFocusedWindow := focusInfo.hwnd
                this.lastFocusedTitle := focusInfo.title
                
                ; 重置按键计数
                this.keyPressCount := 0
                this.mouseClickCount := 0
                
                ; 只在白名单窗口处理上下文切换
                if (InputGuardian.IsInWhiteList()) {
                    context := {
                        processName: focusInfo.process,
                        windowTitle: focusInfo.title,
                        triggerType: "window_switch"
                    }
                    ; 仅通知版本控制系统进行上下文切换，不触发捕获
                    InputGuardian.versionControl.HandleContextSwitch(context)
                }
            }
            
            ; 更新热键状态
            this.UpdateHotkeyState()
        } catch as e {
            IGLogger.Log("ERROR", "窗口监控错误: " . e.Message)
        }
    }
   
    ; 获取真正的输入焦点
    GetRealInputFocus() {
        ; 方法1：使用GetGUIThreadInfo获取真正的焦点窗口
        ; 这是最可靠的方法，能获取实际接收键盘输入的窗口
        
        ; 创建GUITHREADINFO结构体
        cbSize := 48  ; 结构体大小
        info := Buffer(cbSize, 0)
        NumPut("UInt", cbSize, info, 0)
        
        ; 获取前台线程信息
        foregroundThread := DllCall("GetWindowThreadProcessId", 
            "Ptr", DllCall("GetForegroundWindow"), 
            "Ptr", 0, 
            "UInt")
        
        ; 获取GUI线程信息
        if (DllCall("GetGUIThreadInfo", "UInt", foregroundThread, "Ptr", info)) {
            ; 提取焦点窗口句柄
            hwndFocus := NumGet(info, 16, "Ptr")  ; hwndFocus字段的偏移量
            
            if (hwndFocus) {
                ; 获取窗口信息
                title := ""
                try {
                    title := WinGetTitle("ahk_id " . hwndFocus)
                } catch {
                    title := "未知窗口"
                }
                
                ; 获取窗口类名和进程名
                className := ""
                processName := ""
                try {
                    className := WinGetClass("ahk_id " . hwndFocus)
                    processName := WinGetProcessName("ahk_id " . hwndFocus)
                } catch {
                    ; 忽略错误
                }
                
                return {
                    valid: true,
                    hwnd: hwndFocus,
                    title: title,
                    class: className,
                    process: processName,
                    isInputControl: this.IsInputControl(hwndFocus, className)
                }
            }
        }
        
        ; 方法2：备用方案 - 使用传统方法
        try {
            activeWin := WinGetID("A")
            if (activeWin) {
                return {
                    valid: true,
                    hwnd: activeWin,
                    title: WinGetTitle("ahk_id " . activeWin),
                    class: WinGetClass("ahk_id " . activeWin),
                    process: WinGetProcessName("ahk_id " . activeWin),
                    isInputControl: false
                }
            }
        } catch {
            ; 忽略错误
        }
        
        return {valid: false}
    }

    ; 辅助方法：判断是否是输入控件
    IsInputControl(hwnd, className) {
        ; 常见的输入控件类名
        inputClasses := [
            "Edit",           ; 标准编辑框
            "RichEdit",       ; 富文本编辑框
            "Scintilla",      ; 代码编辑器控件
            "Chrome_RenderWidgetHostHWND",  ; Chrome输入框
            "Internet Explorer_Server",      ; IE内核输入框
            "ConsoleWindowClass"             ; 控制台窗口
        ]
        
        for inputClass in inputClasses {
            if (InStr(className, inputClass)) {
                return true
            }
        }
        
        return false
    }
           
    CheckPauseTimeout() {
        ; 基础验证 - 包含鼠标点击
        totalActivityCount := this.keyPressCount + this.mouseClickCount
        if (!InputGuardian.IsInWhiteList() || totalActivityCount < IGConfig.MinActivityCount) {
            this.ResetPauseState()
            return
        }
        
        ; 计算最后活动时间（键盘或鼠标）
        lastActivityTime := Max(this.lastKeyPressTime, this.lastMouseClickTime)
        pauseTime := A_TickCount - lastActivityTime
        
        ; 检查是否已经触发过
        if (!this.HasProp("pauseState")) {
            this.pauseState := {
                hasTriggered: false,
                lastActivityCount: 0
            }
        }
        
        ; 检测用户是否重新开始活动
        if (totalActivityCount > this.pauseState.lastActivityCount) {
            this.ResetPauseState()
            this.pauseState.lastActivityCount := totalActivityCount  ; 先重置状态，再更新计数
            return
        }
        
        ; 如果暂停超过3秒且尚未触发
        if (pauseTime >= IGConfig.PauseDetectionTime && !this.pauseState.hasTriggered) {
            this.ExecutePauseActions(pauseTime)
            this.pauseState.hasTriggered := true
        }
    }

    ; 执行暂停动作
    ExecutePauseActions(pauseTime) {
        IGLogger.Log("INFO", Format("触发输入暂停事件 (暂停{1}ms，键盘:{2}，鼠标:{3})", 
            pauseTime, this.keyPressCount, this.mouseClickCount))
        
        ; 构建事件上下文
        context := {
            triggerType: "input_pause",
            keyPressCount: this.keyPressCount,
            mouseClickCount: this.mouseClickCount,
            totalActivityCount: this.keyPressCount + this.mouseClickCount,
            pauseTime: pauseTime,
            windowTitle: WinGetTitle("A"),
            processName: WinGetProcessName("A")
        }
        
        ; 触发事件处理
        InputGuardian.OnBoundaryDetected("input_pause", context)
        this.stats["输入暂停"]++
        
        ; 暂停后清零计数
        this.keyPressCount := 0
        this.mouseClickCount := 0
    }

    ; 重置空闲状态
    ResetPauseState() {
        if (this.HasProp("pauseState")) {
            IGLogger.Log("DEBUG", "重置暂停检测状态")
            this.pauseState.hasTriggered := false
            this.pauseState.lastActivityCount := 0
        }
    }
       
    ; 按键处理
    OnKeyPress(ih, char) {
        this.keyPressCount++
        this.lastKeyPressTime := A_TickCount
        this.ResetPauseState()
        IGLogger.Log("DEBUG", Format("按键: {1}, 总数: {2}", char, this.keyPressCount))
    }
    
    ; 增强版的边界监控器方法
    OnSubmitKey(ThisHotkey) {
        IGLogger.Log("INFO", Format("触发提交键: {1}", ThisHotkey))

        ; 双重检查：即使热键被触发，也要验证是否应该处理
        if (!this.hotkeysEnabled || !InputGuardian.IsInWhiteList()) {
            IGLogger.Log("WARN", "热键在非白名单窗口被触发，忽略")
            this.SendOriginalKey(ThisHotkey)
            return
        }
        
        ; 验证是否在输入框中
        if (!InputGuardian.IsInTextInput()) {
            IGLogger.Log("DEBUG", "提交键触发但不在输入框中")
            this.SendOriginalKey(ThisHotkey)
            return
        }
        
        ; 获取并验证光标信息（只做一次）
        cursorInfo := this.SaveCursorState()
        if (!cursorInfo.valid) {
            this.SendOriginalKey(ThisHotkey)
            return
        }

        currentTime := A_TickCount
        
        ; 防重复机制
        static lastSubmitTime := 0
        static submitCooldown := 300
        
        if (currentTime - lastSubmitTime < submitCooldown) {
            this.SendOriginalKey(ThisHotkey)
            return
        }
        
        lastSubmitTime := currentTime
        
        ; 使用专门的PostMessage捕获方法
        capturedText := this.CaptureTextWithPostMessage(cursorInfo)
        
        ; 立即发送原始按键
        this.SendOriginalKey(ThisHotkey)
        
        ; 创建上下文时包含捕获的文本
        context := {
            triggerType: "user_submit",
            hotkey: ThisHotkey,
            text: capturedText,  ; 关键：在这里包含文本
            windowTitle: WinGetTitle("A"),
            processName: WinGetProcessName("A"),
            keyPressCount: this.keyPressCount,  ; 仍然记录，用于统计
            timestamp: currentTime,
            cursorInfo: cursorInfo
        }
        
        ; 触发事件处理（让 ShouldTrigger 基于文本内容决定）
        InputGuardian.OnBoundaryDetected("user_submit", context)
        
        ; 只有在成功处理后才更新统计
        if (StrLen(capturedText) > 0) {
            this.stats["主动提交"]++
        }
        
        ; 重置计数
        this.keyPressCount := 0
        this.mouseClickCount := 0
    }

    SendOriginalKey(hotkey) {
        switch hotkey {
            case "Enter":
                Send("{Enter}")
            case "^Enter":
                Send("^{Enter}")
            case "^s":
                Send("^s")
            default:
                ; 对于未知的热键，尝试直接发送
                Send("{" . hotkey . "}")
        }
    }

    ; 专门使用PostMessage的捕获方法
    CaptureTextWithPostMessage(cursorInfo) {
        ; 使用全局捕获管理器
        if (!GlobalCaptureManager.BeginCapture("CaptureTextWithPostMessage")) {
            return ""
        }

        if (this.isInFailureCooldown && A_TickCount < this.failureCooldownEndTime) {
            IGLogger.Log("INFO", "捕获功能在冷却期中")
            GlobalCaptureManager.EndCapture(false)  ; 确保结束捕获状态
            return ""
        }
        
        capturedText := ""  ; 在 try 块外声明
        
        try {
            ; 清空剪贴板
            A_Clipboard := ""
            
            ; CopyQ处理 - 必须在复制操作之前！
            if (IGConfig.UseCopyQ) {
                CopyQHelper.Disable()
                Sleep(30)
            }
            
            ; 记录捕获的内容哈希（用于去重）
            UnifiedClipboardManager.captureContentHash := ""
            
            ; 执行全选复制
            SendInput("^a")
            Sleep(30)
            SendInput("^c")
            
            ; 使用PostMessage恢复光标
            CursorRestorer.RestoreCursor(cursorInfo.clickX, cursorInfo.clickY)
            
            ; 等待剪贴板
            endTime := A_TickCount + 300
            while (A_Clipboard == "" && A_TickCount < endTime) {
                Sleep(10)
            }
            
            ; 获取捕获的文本
            capturedText := A_Clipboard
            
            ; 更新记录的内容和哈希
            if (capturedText != "") {
                UnifiedClipboardManager.lastCapturedContent := capturedText
                UnifiedClipboardManager.captureContentHash := UnifiedClipboardManager.CalculateHash(capturedText)
            }
            
            ; 立即清空剪贴板
            A_Clipboard := ""

            if (capturedText == "") {
                this.HandleCaptureFailure("timeout")
            } else {
                this.HandleCaptureSuccess()
            }
            
            return capturedText
        } catch as e {
            this.HandleCaptureFailure("exception")
            return ""
        } finally {
            ; 使用全局捕获管理器
            GlobalCaptureManager.EndCapture(capturedText != "")

            ; 重新启用 CopyQ
            if (IGConfig.UseCopyQ) {
                Sleep(20)  ; 给一点延迟确保状态正确
                CopyQHelper.Enable()
            }
        }
    }
    
    GetStatistics() {
        ; 计算总捕获数
        totalCaptures := 0
        for key, value in this.stats {
            ; 只累加数字类型的值
            if (Type(value) == "Integer" || Type(value) == "Float") {
                totalCaptures += value
            }
        }
        this.stats["总捕获数"] := totalCaptures
        
        ; 添加更多有用的统计信息
        if (this.inputHook) {
            this.stats["监控状态"] := "运行中"
        } else {
            this.stats["监控状态"] := "已停止"
        }
        
        ; 记录统计日志
        IGLogger.Log("INFO", "获取统计信息:")
        for key, value in this.stats {
            IGLogger.Log("INFO", Format("  {1}: {2}", key, value))
        }
        
        return this.stats
    }

    ; 处理捕获成功
    HandleCaptureSuccess() {
        if (this.captureFailureCount > 0) {
            IGLogger.Log("SUCCESS", Format("捕获恢复正常（之前失败{}次）", this.captureFailureCount))
            this.captureFailureCount := 0
            
            ; 如果有失败提示在显示，移除它
            if (this.failureNotificationGui) {
                try this.failureNotificationGui.Destroy()
                this.failureNotificationGui := ""
            }
        }
    }

    ; 处理捕获失败
    HandleCaptureFailure(reason) {
        this.captureFailureCount++
        this.lastCaptureFailureTime := A_TickCount
        
        ; 确定冷却时间
        cooldownDuration := IGBoundaryMonitor.FailureCooldownDurations.Get(
            Min(this.captureFailureCount, 3), 
            10000
        )
        
        IGLogger.Log("WARN", Format("捕获失败 #{1}，原因：{2}，冷却{3}秒", 
            this.captureFailureCount, reason, cooldownDuration/1000))
        
        ; 进入冷却期
        this.EnterFailureCooldown(cooldownDuration, reason)
    }

    ; 进入失败冷却期
    EnterFailureCooldown(duration, reason) {
        this.isInFailureCooldown := true
        this.failureCooldownEndTime := A_TickCount + duration
        
        ; 显示非侵入式提示
        this.ShowFailureNotification(duration, reason)
        
        ; 设置定时器在冷却结束时清理
        SetTimer(() => this.CheckCooldownExpiry(), -duration)
    }

    ; 退出失败冷却期
    ExitFailureCooldown() {
        this.isInFailureCooldown := false
        IGLogger.Log("INFO", "捕获功能冷却结束，恢复正常")
        
        ; 移除提示
        if (this.failureNotificationGui) {
            try this.failureNotificationGui.Destroy()
            this.failureNotificationGui := ""
        }
        
        ; 如果失败次数过多，重置计数器
        if (this.captureFailureCount >= 3) {
            this.captureFailureCount := 0
        }
    }

    ; 显示失败通知
    ShowFailureNotification(cooldownDuration, reason) {
        ; 如果已有提示，先移除
        if (this.failureNotificationGui) {
            ; 先停止所有相关定时器
            this.StopAllTimersForGui(this.failureNotificationGui)
            try this.failureNotificationGui.Destroy()
        }
        
        ; 创建小巧的提示窗口
        notification := Gui("+AlwaysOnTop -Caption +ToolWindow +E0x20")
        notification.BackColor := "FF6B6B"
        notification.MarginX := 15
        notification.MarginY := 10
        
        ; 构建提示消息
        message := "捕获暂停"
        if (reason = "timeout") {
            message .= "（响应超时）"
        } else if (reason = "exception") {
            message .= "（系统异常）"
        }
        message .= Format(" - {}秒", Round(cooldownDuration/1000))
        
        text := notification.Add("Text", "cWhite", message)
        text.SetFont("s9 w600", "Microsoft YaHei UI")
        
        ; 在输入框附近显示
        local left := 0, top := 0, right := 0, bottom := 0
        if (returnCanShowSymbol(&left, &top, &right, &bottom) && left > 0) {
            notification.Show(Format("x{} y{} NoActivate", right + 10, top - 40))
        } else {
            ; 在屏幕右下角显示
            notification.Show("x" A_ScreenWidth - 200 " y" A_ScreenHeight - 100 " NoActivate")
        }
        
        ; 设置半透明
        WinSetTransparent(220, notification)
        
        ; 保存引用
        this.failureNotificationGui := notification
        
        ; 启动倒计时更新
        this.StartCountdownUpdate(notification, text, cooldownDuration)
    }

    ; 新增方法：停止特定 GUI 相关的所有定时器
    StopAllTimersForGui(guiObj) {
        guiId := ObjPtr(guiObj)
        keysToDelete := []
        
        for timerId, timerInfo in this.activeTimers {
            if (InStr(timerId, "countdown_" . guiId)) {
                SetTimer(timerInfo.func, 0)
                keysToDelete.Push(timerId)
            }
        }
        
        for key in keysToDelete {
            this.activeTimers.Delete(key)
        }
    }

    ; 更新倒计时显示
    StartCountdownUpdate(guiObj, textControl, totalDuration) {
        ; 生成唯一的定时器ID
        timerId := "countdown_" . ObjPtr(guiObj)
        
        ; 清理之前的定时器（如果存在）
        this.StopTimer(timerId)
        
        ; 创建定时器上下文，避免闭包问题
        timerContext := {
            guiObj: guiObj,
            textControl: textControl,
            totalDuration: totalDuration,
            startTime: A_TickCount,
            timerId: timerId
        }
        
        ; 创建定时器函数
        timerFunc := this.DoCountdownUpdateSafe.Bind(this, timerContext)
        
        ; 存储定时器引用
        this.activeTimers.Set(timerId, {
            func: timerFunc,
            context: timerContext
        })
        
        ; 启动定时器
        SetTimer(timerFunc, 500)
    }

    ; 新增：安全的倒计时更新方法
    DoCountdownUpdateSafe(context) {
        ; 验证GUI对象是否仍然有效
        if (!IsObject(context.guiObj)) {
            this.StopTimer(context.timerId)
            return
        }
        
        ; 安全地尝试更新
        try {
            elapsed := A_TickCount - context.startTime
            remaining := context.totalDuration - elapsed
            
            if (remaining <= 0) {
                this.StopTimer(context.timerId)
                return
            }
            
            ; 更新显示
            remainingSeconds := Ceil(remaining / 1000)
            context.textControl.Text := Format("捕获暂停 - {}秒", remainingSeconds)
            
            ; 最后一秒闪烁效果
            if (remainingSeconds == 1) {
                WinSetTransparent(150, context.guiObj)
                Sleep(200)
                WinSetTransparent(220, context.guiObj)
            }
        } catch {
            ; GUI已被销毁或出现其他错误，停止定时器
            this.StopTimer(context.timerId)
        }
    }

    ; 新增：统一的定时器停止方法
    StopTimer(timerId) {
        if (!this.activeTimers.Has(timerId)) {
            return
        }
        
        timerInfo := this.activeTimers.Get(timerId)
        SetTimer(timerInfo.func, 0)
        this.activeTimers.Delete(timerId)
        
        IGLogger.Log("DEBUG", Format("定时器已停止: {1}", timerId))
    }

    ; 新增：停止所有定时器
    StopAllTimers() {
        for timerId, timerInfo in this.activeTimers {
            SetTimer(timerInfo.func, 0)
        }
        this.activeTimers.Clear()
        
        IGLogger.Log("DEBUG", "所有定时器已停止")
    }

    ; 检查冷却期是否结束
    CheckCooldownExpiry() {
        if (A_TickCount >= this.failureCooldownEndTime) {
            this.ExitFailureCooldown()
        }
    }

    VerifyInTextInput() {
        ; 组合多重验证
        if (!InputGuardian.IsInWhiteList()) {
            return false
        }
        
        if (!InputGuardian.IsInTextInput()) {
            return false
        }
        
        ; 可选：额外验证光标位置
        local cursorBounds := InputGuardian.GetCursorBounds()
        if (!cursorBounds.valid) {
            return false
        }
        
        return true
    }

    ; 获取详细的调试信息
    GetDebugContext() {
        return {
            keyPressCount: this.keyPressCount,
            lastKeyPressTime: this.lastKeyPressTime,
            idleTime: A_TickCount - this.lastKeyPressTime,
            windowHwnd: this.lastFocusedWindow,
            windowTitle: this.lastFocusedTitle,
            isInWhitelist: InputGuardian.IsInWhiteList(),
            isInTextInput: InputGuardian.IsInTextInput(),
            isInFailureCooldown: this.isInFailureCooldown,
        }
    }


    ; 新增方法：动态管理热键状态
    UpdateHotkeyState() {
        ; 检查当前窗口是否在白名单中
        shouldEnable := InputGuardian.IsInWhiteList()
        
        ; 避免重复操作
        if (shouldEnable == this.hotkeysEnabled) {
            return
        }
        
        if (shouldEnable) {
            ; 启用热键
            try {
                Hotkey("Enter", ObjBindMethod(this, "OnSubmitKey"), "On")
                Hotkey("^Enter", ObjBindMethod(this, "OnSubmitKey"), "On")
                this.hotkeysEnabled := true
                IGLogger.Log("DEBUG", "热键已启用（进入白名单窗口）")
            } catch as e {
                IGLogger.Log("ERROR", "启用热键失败: " . e.Message)
                ; 通知用户
                if (InStr(e.Message, "already exists")) {
                    MsgBox("InputGuardian: Enter键热键被其他程序占用，自动保存功能可能受限", "警告")
                }
            }
        } else {
            ; 禁用热键
            try {
                Hotkey("Enter", "Off")
                Hotkey("^Enter", "Off")
                this.hotkeysEnabled := false
                IGLogger.Log("DEBUG", "热键已禁用（离开白名单窗口）")
            } catch as e {
                IGLogger.Log("WARN", "禁用热键时出现问题: " . e.Message)
            }
        }
    }

    ; 增强的捕获方法包装器
    CaptureTextSafely(context := "") {
        ; 多层验证确保安全
        if (!this.VerifyInTextInput()) {
            IGLogger.Log("WARN", Format("CaptureTextSafely[{1}]: 输入框验证失败", context))
            return ""
        }
        
        ; 验证窗口状态
        if (!this.VerifyWindowState()) {
            IGLogger.Log("WARN", Format("CaptureTextSafely[{1}]: 窗口状态验证失败", context))
            return ""
        }
        
        ; 验证时机合理性
        if (!this.VerifyCaptureTiming()) {
            IGLogger.Log("WARN", Format("CaptureTextSafely[{1}]: 时机验证失败", context))
            return ""
        }
        
        ; 执行实际捕获
        return this.CaptureText()
    }

    ; 新增方法：验证窗口状态
    VerifyWindowState() {
        ; 确保窗口存在且可访问
        if (!this.lastFocusedWindow) {
            return false
        }
        
        if (!WinExist("ahk_id " . this.lastFocusedWindow)) {
            return false
        }
        
        ; 确保窗口不是最小化状态
        if (WinGetMinMax("ahk_id " . this.lastFocusedWindow) == -1) {
            return false
        }
        
        return true
    }

    ; 新增方法：验证捕获时机
    VerifyCaptureTiming() {
        ; 避免在短时间内重复捕获
        static lastCaptureTime := 0
        currentTime := A_TickCount
        
        if (currentTime - lastCaptureTime < 100) {  ; 100ms内不重复捕获
            return false
        }
        
        lastCaptureTime := currentTime
        return true
    }
}

class SimpleMutex {
    isLocked := false
    
    Lock() {
        ; 使用 Critical 确保原子操作
        Critical("On")
        if (this.isLocked) {
            Critical("Off")
            return false
        }
        this.isLocked := true
        Critical("Off")
        return true
    }
    
    Unlock() {
        Critical("On")
        this.isLocked := false
        Critical("Off")
    }
}

; --- 可追溯性版本管理（优化的追加模式版本） ---
class IGVersionControl {
    ; 预创建的函数引用，避免重复创建匿名函数
    static processNextTaskFunc := ""
    static retryTaskFunc := ""
    static continueProcessingFunc := ""
    
    ; 定时器状态跟踪
    static activeTimerId := ""
    static timerType := ""  ; "process", "retry", "continue"

    ; 性能监控
    static queueStats := {
        totalProcessed: 0,
        totalFailed: 0,
        currentRetries: 0,
        peakQueueSize: 0,
        lastProcessTime: 0
    }

    ; 静态属性，所有实例共享
    static queueMutex := SimpleMutex()
    static writeQueue := []              ; 写入任务队列
    static isProcessingQueue := false    ; 标记是否正在处理队列
    static queueTimer := ""              ; 队列处理定时器
    static maxRetries := 3               ; 每个写入任务的最大重试次数
    static retryDelay := 100             ; 重试延迟（毫秒）


    static pendingTasks := []
    static retryTimerActive := false

    ; 增加队列锁定机制
    static queueLock := false
    static queueProcessingPromise := ""  ; 用于跟踪当前处理任务

    ; 当前活动的上下文信息
    currentContext := {
        key: "",           ; 上下文标识符 (processName + windowTitle)
        processName: "",
        windowTitle: "",
        filePath: "",      ; 当前上下文对应的文件路径
        lastContent: "",   ; 上次的内容，用于计算diff
        sessionStart: "",  ; 会话开始时间
        changeCount: 0,    ; 变更次数计数
        isFinalized: false ; 标记上下文是否已结算
    }
    
    ; 临时文件相关属性
    tempFilePath := ""
    tempFileUpdateTimer := ""
    tempFileUpdatePending := false
    
    ; 提交触发配置
    static CommitTriggers := {
        idleTime: 3000,         ; 3秒无输入触发提交
        sentenceEnd: true,      ; 句子结束触发提交
        paragraphEnd: true,     ; 段落结束触发提交
        minChangeSize: 10       ; 最小变更字符数
    }
    
    static LargeTextThreshold := 100000  ; 大文本阈值
    

    ; 错误恢复相关的静态属性
    static failedWrites := Map()         ; 记录失败的写入，避免重复尝试
    static recoveryStrategies := [       ; 恢复策略列表，按优先级排序
        {
            name: "原始文件备份",
            method: "CreateBackupFile"
        },
        {
            name: "临时目录",
            method: "SaveToTempDir"
        },
        {
            name: "内存缓存",
            method: "CacheInMemory"
        },
        {
            name: "用户文档目录",
            method: "SaveToDocuments"
        }
    ]
    static memoryCache := []             ; 内存缓存，作为最后的手段
    static maxMemoryCacheSize := 50      ; 最多缓存50条记录

    ; 构造函数 - 初始化临时文件路径
    __New() {
        ; 确保 Temp 目录存在
        this.EnsureTempDir()
        ; 设置临时文件路径
        this.tempFilePath := IGConfig.SessionsBasePath . "\Temp\current_session.md"
    }
    
    ; 确保临时目录存在
    EnsureTempDir() {
        tempDir := IGConfig.SessionsBasePath . "\Temp"
        
        ; 首先检查父目录
        parentDir := IGConfig.SessionsBasePath
        if (!DirExist(parentDir)) {
            try {
                DirCreate(parentDir)
                IGLogger.Log("INFO", "创建父目录: " . parentDir)
            } catch as e {
                IGLogger.Log("ERROR", "无法创建父目录: " . e.Message)
                return false
            }
        }
        
        ; 然后创建Temp子目录
        if (!DirExist(tempDir)) {
            try {
                DirCreate(tempDir)
                IGLogger.Log("INFO", "创建临时目录: " . tempDir)
                
                ; 验证目录是否真的创建成功
                if (!DirExist(tempDir)) {
                    IGLogger.Log("ERROR", "临时目录创建失败但没有抛出异常")
                    return false
                }
                
                ; 测试写入权限
                testFile := tempDir . "\test.tmp"
                try {
                    FileAppend("test", testFile)
                    FileDelete(testFile)
                    IGLogger.Log("DEBUG", "临时目录写入权限测试通过")
                } catch {
                    IGLogger.Log("ERROR", "临时目录没有写入权限")
                    return false
                }
            } catch as e {
                IGLogger.Log("ERROR", "创建临时目录失败: " . tempDir . " - " . e.Message)
                return false
            }
        }
        return true
    }

    ; 处理新快照 - 核心方法（使用追加模式优化）
    ProcessSnapshot(text, context) {
        try {
            IGLogger.Log("INFO", "处理新快照，触发类型: " . context.triggerType)
            
            ; 1. 检查是否需要切换上下文
            contextKey := this.GenerateContextKey(context)
            
            if (contextKey != this.currentContext.key) {
                ; 上下文改变，需要先结算当前上下文
                if (this.currentContext.key != "" && !this.currentContext.isFinalized) {
                    this.FinalizeCurrentContext()
                }
                
                ; 切换到新的上下文
                this.SwitchContext(context)
                
                ; 如果有初始内容，创建第一个记录
                if (StrLen(text) > 0) {
                    this.CreateInitialRecord(text)
                }
            } else {
                ; 2. 同一上下文内，检查内容是否有变化
                if (text == this.currentContext.lastContent) {
                    IGLogger.Log("DEBUG", "内容无变化，跳过")
                    return
                }
                
                ; 3. 追加变化记录（核心的追加逻辑）
                this.AppendChangeRecord(text)
            }
            
            ; 4. 更新当前内容
            this.currentContext.lastContent := text
            this.currentContext.changeCount++
            
            ; 5. 更新临时文件
            this.UpdateTempFile()
            
        } catch as e {
            IGLogger.Log("ERROR", "快照处理失败: " . e.Message)
        }
    }
    
    ; 创建初始记录（新上下文的第一次记录）
    CreateInitialRecord(text) {
        timeStr := FormatTime(, "HH:mm:ss")
        codeBlock := Chr(96) . Chr(96) . Chr(96)
        
        ; 构建初始内容
        content := "`n## " . this.GetContextHeader() . "`n`n"
        content .= "### 相对上次的变化`n"
        content .= "<details>`n"
        content .= "<summary>点击展开历史变化</summary>`n`n"
        
        ; 第一次的内容全部标记为新增
        content .= "[" . timeStr . "]`n"
        content .= codeBlock . "diff`n"
        
        lines := StrSplit(text, "`n")
        for line in lines {
            if (StrLen(line) > 0) {
                content .= "+" . line . "`n"
            }
        }
        content .= codeBlock . "`n"
        
        ; 这里不关闭 details，保持开放以便后续追加
        
        ; 追加到文件
        try {
            FileAppend(content, this.currentContext.filePath, "UTF-8")
            IGLogger.Log("SUCCESS", "创建新上下文初始记录")
        } catch as e {
            IGLogger.Log("ERROR", "写入初始记录失败: " . e.Message)
        }
    }
    
    ; 追加变化记录（核心的追加逻辑）
    AppendChangeRecord(newText) {
        ; 计算差异
        diff := this.ComputeDiff(this.currentContext.lastContent, newText)
        if (diff.hunks.Length == 0) {
            IGLogger.Log("DEBUG", "无实质性变化，跳过记录")
            return
        }
        
        ; 生成差异记录
        timeStr := FormatTime(, "HH:mm:ss")
        codeBlock := Chr(96) . Chr(96) . Chr(96)
        
        ; 构建要追加的内容
        appendContent := "`n[" . timeStr . "]`n"
        appendContent .= codeBlock . "diff`n"
        appendContent .= this.FormatDiffSimple(diff)
        appendContent .= "`n" . codeBlock . "`n"
        
        ; 将写入任务加入队列，而不是直接写入
        IGVersionControl.QueueFileWrite({
            type: "append",
            content: appendContent,
            filePath: this.currentContext.filePath,
            context: this.currentContext.key,
            timestamp: A_TickCount,
            retryCount: 0
        })
        
        IGLogger.Log("DEBUG", "变化记录已加入写入队列")
    }
    
    ; 将写入任务加入队列
    static QueueFileWrite(task) {
        ; 使用 Critical 确保原子操作
        Critical("On")
        
        try {
            ; 检查队列大小
            if (this.writeQueue.Length > 100) {
                IGLogger.Log("WARN", "写入队列过长，丢弃最旧的任务")
                this.writeQueue.RemoveAt(1)
            }
            
            ; 添加任务到队列
            this.writeQueue.Push(task)
            IGLogger.Log("DEBUG", Format("写入任务已加入队列，当前队列长度: {1}", this.writeQueue.Length))
            
            ; 检查是否需要启动处理
            needsProcessing := !this.isProcessingQueue
            
            if (needsProcessing) {
                this.isProcessingQueue := true
                ; 异步启动处理
                SetTimer(this.processNextTaskFunc, -1)
            }
        } finally {
            Critical("Off")
        }
    }

    ; 添加静态初始化
    static __New() {
        ; 预创建所有需要的函数引用
        this.processNextTaskFunc := ObjBindMethod(this, "ProcessNextTask")
        this.retryTaskFunc := ObjBindMethod(this, "RetryCurrentTask")
        this.continueProcessingFunc := ObjBindMethod(this, "ContinueProcessing")
        
        ; 初始化性能监控定时器
        SetTimer(ObjBindMethod(this, "MonitorQueueHealth"), 30000)  ; 每30秒检查一次
    }
    
    static ProcessPendingTasks() {
        this.retryTimerActive := false
        
        ; 处理所有待处理任务
        while (this.pendingTasks.Length > 0 && !this.queueLock) {
            task := this.pendingTasks.RemoveAt(1)
            this.QueueFileWrite(task)
        }
        
        ; 如果还有剩余任务，继续设置定时器
        if (this.pendingTasks.Length > 0) {
            this.retryTimerActive := true
            SetTimer(() => this.ProcessPendingTasks(), -100)
        }
    }

    ; 开始处理队列
    static StartQueueProcessing() {
        ; 使用原子操作防止重复启动
        if (this.isProcessingQueue) {
            return
        }
        
        ; 立即设置标志，防止并发启动
        this.isProcessingQueue := true
        
        ; 异步处理第一个任务
        SetTimer(() => this.ProcessNextTask(), -1)
    }
    
    static GetNextTask() {
        ; 首先检查队列是否为空
        if (this.writeQueue.Length == 0) {
            return ""
        }
        
        ; 使用 Critical 确保操作的原子性
        ; 这样可以防止在获取任务时其他线程修改队列
        Critical("On")
        try {
            ; 获取第一个任务
            task := this.writeQueue[1]
            ; 从队列中移除（注意：这里还没有真正移除）
            ; 实际的移除应该在任务成功处理后进行
            return task
        } catch as e {
            IGLogger.Log("ERROR", "获取任务失败: " . e.Message)
            return ""
        } finally {
            Critical("Off")
        }
    }

    ; 处理队列中的下一个任务
    static ProcessNextTask() {
        startTime := A_TickCount
        this.activeTimerId := ""
        
        ; 先查看任务，不移除
        task := this.PeekQueue()
        if (!task) {
            IGLogger.Log("DEBUG", "队列已清空")
            this.isProcessingQueue := false
            return
        }
        
        ; 更新统计
        this.queueStats.peakQueueSize := Max(this.queueStats.peakQueueSize, 
                                             this.writeQueue.Length)
        
        ; 执行写入
        success := this.ExecuteFileWrite(task)
        
        ; 记录处理时间
        this.queueStats.lastProcessTime := A_TickCount - startTime
        
        if (success) {
            ; 只有在成功时才移除任务
            Critical("On")
            try {
                if (this.writeQueue.Length > 0) {
                    this.writeQueue.RemoveAt(1)
                }
            } finally {
                Critical("Off")
            }
            this.HandleSuccess(task)
        } else {
            this.HandleFailure(task)
        }
    }
    
    ; 处理成功的情况
    static HandleSuccess(task) {
        ; 更新统计
        this.queueStats.totalProcessed++
        this.queueStats.currentRetries := 0
        
        IGLogger.Log("DEBUG", Format("任务成功，队列剩余: {1}", 
                                    this.writeQueue.Length))
        
        ; 继续处理下一个任务
        this.ScheduleNextTask(10)  ; 10ms 延迟
    }

    ; 处理失败的情况
    static HandleFailure(task) {
        task.retryCount++
        this.queueStats.currentRetries++
        
        if (task.retryCount < this.maxRetries) {
            ; 计算退避延迟（指数退避）
            delay := this.CalculateBackoffDelay(task.retryCount)
            
            IGLogger.Log("WARN", Format("任务失败，将在 {1}ms 后重试（第{2}次）", 
                                       delay, task.retryCount))
            
            ; 将任务保留在队列前端
            this.ScheduleNextTask(delay)
        } else {
            ; 超过最大重试次数
            this.queueStats.totalFailed++
            this.queueStats.currentRetries := 0
            
            IGLogger.Log("ERROR", "任务彻底失败，已达最大重试次数")
            
            ; 处理失败恢复
            this.HandleWriteFailure(task)
            
            ; 移除失败的任务
            this.writeQueue.RemoveAt(1)
            
            ; 继续处理其他任务
            if (this.writeQueue.Length > 0) {
                this.ScheduleNextTask(100)  ; 失败后给更长的恢复时间
            } else {
                this.isProcessingQueue := false
            }
        }
    }

    ; 统一的任务调度方法
    static ScheduleNextTask(delay) {
        ; 取消之前的定时器（如果存在）
        if (this.activeTimerId) {
            SetTimer(this.activeTimerId, 0)
        }
        
        ; 检查队列健康状况
        if (this.IsQueueUnhealthy()) {
            IGLogger.Log("WARN", "队列状态异常，暂停处理")
            this.PauseQueueProcessing()
            return
        }
        
        ; 使用预创建的函数引用
        this.activeTimerId := this.processNextTaskFunc
        SetTimer(this.activeTimerId, -delay)
    }

    ; 计算指数退避延迟
    static CalculateBackoffDelay(retryCount) {
        ; 基础延迟 100ms，每次重试翻倍，最大 5 秒
        baseDelay := 100
        maxDelay := 5000
        
        delay := baseDelay * (2 ** (retryCount - 1))
        return Min(delay, maxDelay)
    }

    static PeekQueue() {
        if (this.writeQueue.Length == 0) {
            return ""
        }
        
        try {
            return this.writeQueue[1]  ; 只返回任务，不移除
        } catch {
            return ""
        }
    }

    ; 检查队列健康状况
    static IsQueueUnhealthy() {
        ; 检查各种异常指标
        if (this.queueStats.currentRetries > 10) {
            return true  ; 连续重试次数过多
        }
        
        if (this.writeQueue.Length > 500) {
            return true  ; 队列过长
        }
        
        if (this.queueStats.lastProcessTime > 1000) {
            return true  ; 单次处理时间过长
        }
        
        ; 计算失败率
        total := this.queueStats.totalProcessed + this.queueStats.totalFailed
        if (total > 100) {
            failureRate := this.queueStats.totalFailed / total
            if (failureRate > 0.5) {
                return true  ; 失败率超过 50%
            }
        }
        
        return false
    }

    static PauseQueueProcessing() {
        this.isProcessingQueue := false
        
        ; 通知用户
        TrayTip("InputGuardian 警告", 
               "文件写入队列遇到问题，已暂停处理。`n" .
               "请检查磁盘空间和文件权限。", 
               "Icon!")
        
        ; 设置恢复定时器
        SetTimer(ObjBindMethod(this, "TryResumeProcessing"), -30000)  ; 30秒后尝试恢复
    }
    
    ; 尝试恢复处理
    static TryResumeProcessing() {
        IGLogger.Log("INFO", "尝试恢复队列处理")
        
        ; 重置一些统计
        this.queueStats.currentRetries := 0
        
        ; 如果队列中还有任务，重新开始处理
        if (this.writeQueue.Length > 0 && !this.isProcessingQueue) {
            this.StartQueueProcessing()
        }
    }
    
    ; 监控队列健康状况
    static MonitorQueueHealth() {
        if (!this.isProcessingQueue && this.writeQueue.Length > 0) {
            IGLogger.Log("WARN", Format("检测到队列停滞，{1}个任务等待处理", 
                                    this.writeQueue.Length))
            
            ; 尝试重新启动处理
            this.StartQueueProcessing()
        }
        
        ; 定期清理统计数据，防止溢出
        if (this.queueStats.totalProcessed > 1000000) {
            this.queueStats.totalProcessed := 0  ; Fixed: Use := for assignment
            this.queueStats.totalFailed := 0     ; Fixed: Use := for assignment
        }
    }
    
    ; 获取队列状态报告
    static GetQueueStatus() {
        status := "队列状态报告：`n"
        status .= Format("- 当前队列长度: {1}`n", this.writeQueue.Length)
        status .= Format("- 历史最大长度: {1}`n", this.queueStats.peakQueueSize)
        status .= Format("- 总处理任务数: {1}`n", this.queueStats.totalProcessed)
        status .= Format("- 总失败任务数: {1}`n", this.queueStats.totalFailed)
        status .= Format("- 当前重试次数: {1}`n", this.queueStats.currentRetries)
        status .= Format("- 处理状态: {1}`n", this.isProcessingQueue ? "运行中" : "停止")
        
        ; 计算成功率
        total := this.queueStats.totalProcessed + this.queueStats.totalFailed
        if (total > 0) {
            successRate := Round(this.queueStats.totalProcessed / total * 100, 2)
            status .= Format("- 成功率: {1}%`n", successRate)
        }
        
        return status
    }

    ; 执行实际的文件写入
    static ExecuteFileWrite(task) {
        file := ""
        try {
            file := FileOpen(task.filePath, "a", "UTF-8")
            file.Write(task.content)
            return true
        } catch as e {
            IGLogger.Log("ERROR", Format("文件写入异常: {1}", e.Message))
            return false
        } finally {
            ; 无条件尝试关闭文件（如果存在）
            if (file) {
                try {
                    file.Close()
                } catch {
                    ; 记录关闭失败，而不是忽略
                    IGLogger.Log("WARN", "文件句柄关闭失败")
                }
            }
        }
    }

    ; 处理上下文切换（不涉及内容捕获）
    HandleContextSwitch(context) {
        contextKey := this.GenerateContextKey(context)
        
        ; 只有在上下文真正改变时才处理
        if (contextKey != this.currentContext.key) {
            ; 如果当前上下文有内容且未结算，先结算
            if (this.currentContext.key != "" && 
                !this.currentContext.isFinalized && 
                this.currentContext.lastContent != "") {
                this.FinalizeCurrentContext()
            }
            
            ; 切换到新上下文（但不创建初始记录）
            IGLogger.Log("INFO", "上下文切换: " . contextKey)
            
            ; 更新上下文信息
            this.currentContext.key := contextKey
            this.currentContext.processName := context.processName
            this.currentContext.windowTitle := context.windowTitle
            this.currentContext.sessionStart := A_Now
            this.currentContext.lastContent := ""
            this.currentContext.changeCount := 0
            this.currentContext.isFinalized := false
            
            ; 确定文件路径
            dateStr := FormatTime(, "yyyy-MM-dd")
            this.currentContext.filePath := IGConfig.SessionsBasePath . "\" . dateStr . ".md"
            
            ; 更新临时文件
            this.UpdateTempFile()
        }
    }


    ; 结算当前上下文（在上下文切换时调用）
    FinalizeCurrentContext() {
        if (this.currentContext.isFinalized || this.currentContext.key == "") {
            return
        }
        
        IGLogger.Log("INFO", "结算当前上下文: " . this.currentContext.key)
        
        timeStr := FormatTime(, "HH:mm:ss")
        codeBlock := Chr(96) . Chr(96) . Chr(96)
        
        ; 构建结算内容
        finalizeContent := "`n<!-- DIFF_INSERTION_POINT -->`n"  ; 标记差异记录结束
        finalizeContent .= "</details>`n`n"  ; 关闭折叠区域
        
        ; 添加最终内容快照
        finalizeContent .= "### [" . timeStr . "] 内容快照`n"
        finalizeContent .= codeBlock . "text`n"
        if (this.currentContext.lastContent != "") {
            finalizeContent .= this.currentContext.lastContent
        } else {
            finalizeContent .= "（无内容）"
        }
        finalizeContent .= "`n" . codeBlock
        finalizeContent .= "`n<!-- SNAPSHOT_END -->`n`n"
        finalizeContent .= "---`n"
        
        ; 追加结算内容
        try {
            FileAppend(finalizeContent, this.currentContext.filePath, "UTF-8")
            this.currentContext.isFinalized := true
            IGLogger.Log("SUCCESS", "上下文结算完成")
        } catch as e {
            IGLogger.Log("ERROR", "结算上下文失败: " . e.Message)
        }
    }
    
    ; 处理追加失败的情况
    HandleAppendFailure(error, content) {
        ; 策略1：尝试创建备份文件
        backupFile := this.currentContext.filePath . ".recovery"
        try {
            FileAppend(content, backupFile, "UTF-8")
            IGLogger.Log("WARN", "内容已保存到恢复文件: " . backupFile)
        } catch {
            ; 策略2：保存到临时目录
            recoveryFile := A_Temp . "\InputGuardian_recovery_" . A_TickCount . ".txt"
            try {
                FileAppend(content, recoveryFile, "UTF-8")
                IGLogger.Log("WARN", "内容已保存到: " . recoveryFile)
            } catch {
                IGLogger.Log("ERROR", "无法保存恢复数据")
            }
        }
    }
    
    ; 更新临时文件
    UpdateTempFile() {
        if (!this.currentContext.key) {
            return
        }
        
        ; 标记需要更新
        this.tempFileUpdatePending := true
        
        ; 如果已有定时器在运行，不创建新的
        if (this.tempFileUpdateTimer) {
            return
        }
        
        ; 延迟500ms执行实际更新，避免频繁写入
        this.tempFileUpdateTimer := SetTimer(() => this.DoUpdateTempFile(), -500)
    }
    
    ; 实际执行临时文件更新
    DoUpdateTempFile() {
        this.tempFileUpdateTimer := ""
        
        if (!this.tempFileUpdatePending) {
            return
        }
        
        this.tempFileUpdatePending := false
        
        try {
            ; 确保临时目录存在
            if (!this.EnsureTempDir()) {
                return
            }
            
            ; 生成临时文件内容，展示当前状态
            content := "# 当前输入会话`n`n"
            content .= Format("**应用**: {1}`n", this.currentContext.processName)
            content .= Format("**窗口**: {1}`n", this.currentContext.windowTitle)
            content .= Format("**开始时间**: {1}`n", 
                FormatTime(this.currentContext.sessionStart, "yyyy-MM-dd HH:mm:ss"))
            content .= Format("**最后更新**: {1}`n", 
                FormatTime(, "HH:mm:ss"))
            content .= Format("**变更次数**: {1}`n`n", this.currentContext.changeCount)
            
            ; 添加一些统计信息
            stats := this.GetSessionStats()
            content .= Format("**当前会话**: {1}`n", this.currentContext.key)
            content .= Format("**今日会话数**: {1}`n", stats.sessions)
            content .= Format("**今日变更数**: {1}`n`n", stats.changes)
            
            ; 定义代码块标记（三个反引号）
            codeBlock := Chr(96) . Chr(96) . Chr(96)
            
            ; 当前内容（这是用户最关心的）
            content .= "## 当前内容`n"
            content .= codeBlock . "`n"
            if (this.currentContext.lastContent) {
                content .= this.currentContext.lastContent
            } else {
                content .= "（暂无内容）"
            }
            content .= "`n" . codeBlock . "`n`n"
            
            ; 添加提示信息
            content .= "## 历史记录`n"
            content .= "查看完整历史和变化过程，请打开今日会话文件：`n"
            content .= Format("📁 `{1}.md`n", FormatTime(, "yyyy-MM-dd"))
            content .= "`n💡 提示：历史文件中包含了所有输入变化的详细记录"
            
            ; 写入临时文件（覆盖模式）
            if (FileExist(this.tempFilePath)) {
                FileDelete(this.tempFilePath)
            }
            
            FileAppend(content, this.tempFilePath, "UTF-8")
            IGLogger.Log("DEBUG", "临时文件更新成功")
            
        } catch as e {
            IGLogger.Log("ERROR", "更新临时文件失败: " . e.Message)
        }
    }
    
    ; 生成上下文标识符
    GenerateContextKey(context) {
        ; 清理标题中的动态部分（如未保存标记*）
        cleanTitle := RegExReplace(context.windowTitle, "[\*\s]+$", "")
        return context.processName . " - " . cleanTitle
    }
    
    ; 切换上下文
    SwitchContext(context) {
        IGLogger.Log("INFO", "切换上下文: " . this.GenerateContextKey(context))
        
        ; 更新上下文信息
        this.currentContext.key := this.GenerateContextKey(context)
        this.currentContext.processName := context.processName
        this.currentContext.windowTitle := context.windowTitle
        this.currentContext.sessionStart := A_Now
        this.currentContext.lastContent := ""
        this.currentContext.changeCount := 0
        this.currentContext.isFinalized := false
        
        ; 确定文件路径
        dateStr := FormatTime(, "yyyy-MM-dd")
        this.currentContext.filePath := IGConfig.SessionsBasePath . "\" . dateStr . ".md"
        
        ; 如果是新文件，添加日期标题
        if (!FileExist(this.currentContext.filePath)) {
            header := "# InputGuardian 会话记录 - " . dateStr . "`n`n"
            FileAppend(header, this.currentContext.filePath, "UTF-8")
        }
        
        ; 立即更新临时文件
        this.UpdateTempFile()
    }
    
    ; 获取上下文标题
    GetContextHeader() {
        timeStr := FormatTime(this.currentContext.sessionStart, "HH:mm:ss")
        return "[" . timeStr . "] " . this.currentContext.key
    }
    
    ; 简化的diff格式化（保持原有实现）
    FormatDiffSimple(diff) {
        output := ""
        
        for hunk in diff.hunks {
            ; 显示上下文行号
            if (hunk.oldLines.Length > 0 || hunk.newLines.Length > 0) {
                output .= Format("@@ -{1},{2} +{3},{4} @@`n", 
                    hunk.oldStart, 
                    hunk.oldLines.Length,
                    hunk.newStart,
                    hunk.newLines.Length)
            }
            
            ; 根据类型显示内容
            switch hunk.type {
                case "add":
                    for line in hunk.newLines {
                        output .= "+" . line . "`n"
                    }
                case "delete":
                    for line in hunk.oldLines {
                        output .= "-" . line . "`n"
                    }
                case "modify":
                    ; 显示删除的行
                    for line in hunk.oldLines {
                        output .= "-" . line . "`n"
                    }
                    ; 显示新增的行
                    for line in hunk.newLines {
                        output .= "+" . line . "`n"
                    }
            }
        }
        
        return RTrim(output, "`n")
    }
    
    ; Myers差分算法实现（保持原有实现）
    ComputeDiff(oldText, newText) {
        if (oldText == newText) {
            return {hunks: []}
        }
        
        oldLines := StrSplit(oldText, "`n")
        newLines := StrSplit(newText, "`n")
        
        ; 对超大文本使用简化算法
        if (oldLines.Length * newLines.Length > IGVersionControl.LargeTextThreshold) {
            IGLogger.Log("INFO", Format("文本过大（{1}x{2}），使用简化算法", 
                oldLines.Length, newLines.Length))
            return this.ComputeDiffSimplified(oldLines, newLines)
        }
        
        ; 使用LCS找到所有公共行
        lcs := this.FindLCS(oldLines, newLines)

        ; 基于LCS生成diff
        diff := {hunks: []}
        oldIdx := 1
        newIdx := 1
        
        for point in lcs {
            if (oldIdx < point.oldIndex || newIdx < point.newIndex) {
                hunk := {
                    oldStart: oldIdx,
                    oldLines: [],
                    newStart: newIdx,
                    newLines: []
                }
                
                while (oldIdx < point.oldIndex) {
                    hunk.oldLines.Push(oldLines[oldIdx])
                    oldIdx++
                }
                while (newIdx < point.newIndex) {
                    hunk.newLines.Push(newLines[newIdx])
                    newIdx++
                }
                
                if (hunk.oldLines.Length > 0 && hunk.newLines.Length > 0) {
                    hunk.type := "modify"
                } else if (hunk.oldLines.Length > 0) {
                    hunk.type := "delete"
                } else {
                    hunk.type := "add"
                }
                
                diff.hunks.Push(hunk)
            }
            
            oldIdx++
            newIdx++
        }
        
        ; 处理末尾的差异
        if (oldIdx <= oldLines.Length || newIdx <= newLines.Length) {
            hunk := {
                oldStart: oldIdx,
                oldLines: [],
                newStart: newIdx,
                newLines: []
            }
            
            while (oldIdx <= oldLines.Length) {
                hunk.oldLines.Push(oldLines[oldIdx])
                oldIdx++
            }
            
            while (newIdx <= newLines.Length) {
                hunk.newLines.Push(newLines[newIdx])
                newIdx++
            }
            
            if (hunk.oldLines.Length > 0 && hunk.newLines.Length > 0) {
                hunk.type := "modify"
            } else if (hunk.oldLines.Length > 0) {
                hunk.type := "delete"
            } else {
                hunk.type := "add"
            }
            
            diff.hunks.Push(hunk)
        }
        
        return diff
    }

    ; 简化的diff算法（保持原有实现，用于大文本）
    ComputeDiffSimplified(oldLines, newLines) {
        diff := {hunks: []}
        
        ; 建立行哈希索引
        oldHash := Map()
        for i, line in oldLines {
            hash := this.HashLine(line)
            if (!oldHash.Has(hash)) {
                oldHash.Set(hash, [])
            }
            oldHash.Get(hash).Push(i)
        }
        
        ; 快速匹配
        matched := Map()
        matchedNew := Map()
        
        for j, newLine in newLines {
            hash := this.HashLine(newLine)
            if (oldHash.Has(hash)) {
                candidates := oldHash.Get(hash)
                bestMatch := 0
                minDistance := 999999
                
                for idx in candidates {
                    if (!matched.Has(idx)) {
                        distance := Abs(idx - j)
                        if (distance < minDistance) {
                            minDistance := distance
                            bestMatch := idx
                        }
                    }
                }
                
                if (bestMatch > 0) {
                    matched.Set(bestMatch, j)
                    matchedNew.Set(j, bestMatch)
                }
            }
        }
        
        ; 基于匹配生成差异
        oldIdx := 1
        newIdx := 1
        
        matchPoints := []
        for oldLine, newLine in matched {
            matchPoints.Push({old: oldLine, new: newLine})
        }
        
        matchPoints := this.SortMatchPoints(matchPoints)
        
        for match in matchPoints {
            if (oldIdx < match.old || newIdx < match.new) {
                hunk := {
                    oldStart: oldIdx,
                    oldLines: [],
                    newStart: newIdx,
                    newLines: []
                }
                
                while (oldIdx < match.old && oldIdx <= oldLines.Length) {
                    hunk.oldLines.Push(oldLines[oldIdx])
                    oldIdx++
                }
                
                while (newIdx < match.new && newIdx <= newLines.Length) {
                    hunk.newLines.Push(newLines[newIdx])
                    newIdx++
                }
                
                if (hunk.oldLines.Length > 0 && hunk.newLines.Length > 0) {
                    hunk.type := "modify"
                } else if (hunk.oldLines.Length > 0) {
                    hunk.type := "delete"
                } else if (hunk.newLines.Length > 0) {
                    hunk.type := "add"
                }
                
                if (hunk.oldLines.Length > 0 || hunk.newLines.Length > 0) {
                    diff.hunks.Push(hunk)
                }
            }
            
            oldIdx := match.old + 1
            newIdx := match.new + 1
        }
        
        if (oldIdx <= oldLines.Length || newIdx <= newLines.Length) {
            hunk := {
                oldStart: oldIdx,
                oldLines: [],
                newStart: newIdx,
                newLines: []
            }
            
            while (oldIdx <= oldLines.Length) {
                hunk.oldLines.Push(oldLines[oldIdx])
                oldIdx++
            }
            
            while (newIdx <= newLines.Length) {
                hunk.newLines.Push(newLines[newIdx])
                newIdx++
            }
            
            if (hunk.oldLines.Length > 0 && hunk.newLines.Length > 0) {
                hunk.type := "modify"
            } else if (hunk.oldLines.Length > 0) {
                hunk.type := "delete"
            } else {
                hunk.type := "add"
            }
            
            if (hunk.oldLines.Length > 0 || hunk.newLines.Length > 0) {
                diff.hunks.Push(hunk)
            }
        }
        
        return diff
    }

    ; LCS算法实现（保持原有实现）
    FindLCS(oldLines, newLines) {
        m := oldLines.Length
        n := newLines.Length
        
        dp := []
        Loop m + 1 {
            row := []
            Loop n + 1 {
                row.Push(0)
            }
            dp.Push(row)
        }
        
        Loop m {
            i := A_Index
            Loop n {
                j := A_Index
                if (oldLines[i] == newLines[j]) {
                    dp[i + 1][j + 1] := dp[i][j] + 1
                } else {
                    dp[i + 1][j + 1] := Max(dp[i + 1][j], dp[i][j + 1])
                }
            }
        }
        
        lcs := []
        i := m
        j := n
        
        while (i > 0 && j > 0) {
            if (oldLines[i] == newLines[j]) {
                lcs.InsertAt(1, {oldIndex: i, newIndex: j, line: oldLines[i]})
                i--
                j--
            } else if (dp[i][j] > dp[i + 1][j]) {
                i--
            } else {
                j--
            }
        }
        
        return lcs
    }

    ; 辅助方法（保持原有实现）
    HashLine(line) {
        hash := StrLen(line)
        maxChars := Min(50, StrLen(line))
        Loop Parse, SubStr(line, 1, maxChars) {
            hash := ((hash << 3) + Ord(A_LoopField)) & 0xFFFFFF
        }
        return hash
    }

    SortMatchPoints(points) {
        n := points.Length
        Loop n - 1 {
            i := A_Index
            Loop n - i {
                j := A_Index
                if (points[j].old > points[j + 1].old) {
                    temp := points[j]
                    points[j] := points[j + 1]
                    points[j + 1] := temp
                }
            }
        }
        return points
    }

    ; 获取会话统计（优化以支持新格式）
    GetSessionStats() {
        if (!this.currentContext.filePath || !FileExist(this.currentContext.filePath)) {
            return {sessions: 0, changes: 0}
        }
        
        try {
            content := FileRead(this.currentContext.filePath, "UTF-8")
            
            ; 统计会话数（## 开头的行）
            sessions := 0
            pos := 1
            while (pos := InStr(content, "`n## [", , pos)) {
                sessions++
                pos++
            }
            
            ; 统计变更数（通过时间戳标记）
            changes := 0
            pos := 1
            while (pos := RegExMatch(content, "`n\[\d{2}:\d{2}:\d{2}\]`n", , pos)) {
                changes++
                pos++
            }
            
            return {
                sessions: sessions,
                changes: changes,
                currentContext: this.currentContext.key
            }
        } catch {
            return {sessions: 0, changes: 0}
        }
    }
    
    ; 获取临时文件路径（供外部使用）
    GetTempFilePath() {
        return this.tempFilePath
    }
    
    ; 公共方法：强制结算当前上下文（供外部调用）
    ForceFinalize() {
        if (this.currentContext.key != "" && !this.currentContext.isFinalized) {
            this.FinalizeCurrentContext()
            return true
        }
        return false
    }

    ; 改进后的错误处理方法
    static HandleWriteFailure(task) {
        ; 生成任务的唯一标识
        taskId := task.filePath . "_" . task.timestamp
        
        ; 检查是否已经尝试过恢复这个任务
        if (this.failedWrites.Has(taskId)) {
            IGLogger.Log("WARN", "该写入任务已经尝试过恢复，跳过")
            return false
        }
        
        ; 标记为已尝试
        this.failedWrites.Set(taskId, {
            attempts: 0,
            lastAttempt: A_TickCount
        })
        
        ; 尝试每个恢复策略
        for strategy in this.recoveryStrategies {
            IGLogger.Log("INFO", Format("尝试恢复策略: {1}", strategy.name))
            
            ; 调用对应的恢复方法
            methodName := strategy.method
            if (this.HasMethod(methodName)) {
                try {
                    success := this.%methodName%(task)
                    if (success) {
                        IGLogger.Log("SUCCESS", Format("恢复策略成功: {1}", strategy.name))
                        return true
                    }
                } catch as e {
                    IGLogger.Log("ERROR", Format("恢复策略失败 [{1}]: {2}", 
                        strategy.name, e.Message))
                }
            }
        }
        
        ; 所有策略都失败了
        IGLogger.Log("ERROR", "所有恢复策略都失败了")
        this.NotifyUserOfFailure(task)
        return false
    }
    
    ; 恢复策略1：创建备份文件
    static CreateBackupFile(task) {
        ; 生成备份文件名（包含时间戳避免冲突）
        timestamp := FormatTime(A_Now, "yyyyMMdd_HHmmss")
        backupFile := task.filePath . ".backup_" . timestamp
        
        ; 检查备份文件是否已存在
        if (FileExist(backupFile)) {
            throw Error("备份文件已存在")
        }
        
        ; 尝试创建备份文件
        try {
            FileAppend(task.content, backupFile, "UTF-8")
            
            ; 记录备份信息
            this.LogRecoverySuccess("备份文件", backupFile, task)
            return true
        } catch as e {
            ; 如果连备份文件都无法创建，说明可能是磁盘空间或权限问题
            throw Error("无法创建备份文件: " . e.Message)
        }
    }
    
    ; 恢复策略2：保存到系统临时目录
    static SaveToTempDir(task) {
        tempFile := A_Temp . "\InputGuardian_recovery_" . A_TickCount . ".txt"
        
        try {
            ; 估算需要的空间（UTF-8 编码，最坏情况每个字符 3 字节）
            requiredSpace := StrLen(task.content) * 3
            
            ; 检查临时目录的可用空间
            if (!this.CheckDiskSpace(A_Temp, requiredSpace)) {
                throw Error("临时目录空间不足")
            }
            
            FileAppend(task.content, tempFile, "UTF-8")
            this.LogRecoverySuccess("临时文件", tempFile, task)
            return true
        } catch as e {
            throw Error("无法写入临时目录: " . e.Message)
        }
    }
    
    ; 恢复策略3：缓存到内存
    static CacheInMemory(task) {
        ; 计算当前缓存的总大小
        totalSize := 0
        for cache in this.memoryCache {
            ; 估算实际字节大小（UTF-8编码）
            totalSize += StrLen(cache.content) * 3
        }


        ; 新增：单个缓存项的大小限制（1MB）
        maxItemSize := 1024 * 1024
        if (StrLen(task.content) > maxItemSize) {
            IGLogger.Log("WARN", "内容过大，无法缓存到内存")
            return false
        }
        
        ; 如果缓存太大（比如超过 10MB），先清理一些
        maxSizeBytes := 10 * 1024 * 1024  ; 10MB
        while (totalSize > maxSizeBytes && this.memoryCache.Length > 0) {
            removed := this.memoryCache.RemoveAt(1)
            totalSize -= StrLen(removed.content) * 3
            IGLogger.Log("WARN", "内存缓存超过大小限制，移除最旧的记录")
        }
        
        ; 检查条目数量
        if (this.memoryCache.Length >= this.maxMemoryCacheSize) {
            this.memoryCache.RemoveAt(1)
            IGLogger.Log("WARN", "内存缓存已满，移除最旧的记录")
        }
        
        ; 添加到内存缓存
        this.memoryCache.Push({
            content: task.content,
            filePath: task.filePath,
            timestamp: A_TickCount,
            context: task.context
        })
        
        IGLogger.Log("WARN", Format("内容已缓存到内存（当前缓存数: {1}）", 
            this.memoryCache.Length))
        
        ; 设置定时器，稍后尝试将缓存写入文件
        SetTimer(() => this.FlushMemoryCache(), -60000)  ; 1分钟后尝试
        
        return true
    }
    
    ; 恢复策略4：保存到用户文档目录
    static SaveToDocuments(task) {
        ; 在用户文档目录创建恢复文件夹
        recoveryDir := A_MyDocuments . "\InputGuardian_Recovery"
        
        if (!DirExist(recoveryDir)) {
            try {
                DirCreate(recoveryDir)
            } catch {
                throw Error("无法创建恢复目录")
            }
        }
        
        ; 生成恢复文件名
        timestamp := FormatTime(A_Now, "yyyyMMdd_HHmmss")
        recoveryFile := recoveryDir . "\recovery_" . timestamp . ".txt"
        
        try {
            FileAppend(task.content, recoveryFile, "UTF-8")
            this.LogRecoverySuccess("文档目录", recoveryFile, task)
            return true
        } catch as e {
            throw Error("无法写入文档目录: " . e.Message)
        }
    }
    
    ; 辅助方法：检查磁盘空间
    static CheckDiskSpace(path, requiredBytes) {
        ; 从路径中提取驱动器盘符
        ; 例如："D:\InputGuardian\file.txt" -> "D:"
        driveLetter := ""
        
        ; 处理不同格式的路径
        if (SubStr(path, 2, 1) == ":") {
            ; 标准路径格式，如 "D:\folder\file"
            driveLetter := SubStr(path, 1, 2)  ; 获取 "D:"
        } else if (SubStr(path, 1, 2) == "\\") {
            ; 网络路径，暂时返回 true（需要不同的处理方式）
            IGLogger.Log("WARN", "网络路径暂不支持磁盘空间检查: " . path)
            return true
        } else {
            ; 相对路径，使用当前工作目录的驱动器
            driveLetter := SubStr(A_WorkingDir, 1, 2)
        }
        
        ; 确保驱动器路径以反斜杠结尾
        drivePath := driveLetter . "\"
        
        ; 创建缓冲区来接收磁盘空间信息
        ; GetDiskFreeSpaceEx 返回三个 64 位整数（各占 8 字节）
        lpFreeBytesAvailable := Buffer(8, 0)     ; 当前用户可用的字节数
        lpTotalNumberOfBytes := Buffer(8, 0)     ; 磁盘总容量
        lpTotalNumberOfFreeBytes := Buffer(8, 0) ; 磁盘总剩余空间
        
        ; 调用 Windows API
        success := DllCall("Kernel32.dll\GetDiskFreeSpaceEx",
            "Str", drivePath,                    ; 驱动器路径
            "Ptr", lpFreeBytesAvailable,         ; 可用空间缓冲区
            "Ptr", lpTotalNumberOfBytes,         ; 总空间缓冲区  
            "Ptr", lpTotalNumberOfFreeBytes,     ; 总剩余空间缓冲区
            "Int")
        
        if (!success) {
            ; API 调用失败
            lastError := DllCall("GetLastError")
            IGLogger.Log("ERROR", Format("无法获取磁盘空间信息 [{}]: 错误代码 {}", 
                drivePath, lastError))
            
            ; 如果无法获取信息，保守起见返回 true，让操作继续
            return true
        }
        
        ; 从缓冲区读取可用空间（64位整数）
        ; 注意：AutoHotkey v2 的 NumGet 默认读取的是有符号整数
        ; 对于大于 2GB 的空间，需要正确处理
        availableBytes := NumGet(lpFreeBytesAvailable, 0, "UInt64")
        
        ; 记录详细信息用于调试
        if (IGConfig.DebugMode) {
            totalBytes := NumGet(lpTotalNumberOfBytes, 0, "UInt64")
            totalFreeBytes := NumGet(lpTotalNumberOfFreeBytes, 0, "UInt64")
            
            IGLogger.Log("DEBUG", Format("磁盘空间检查 [{}]:", drivePath))
            IGLogger.Log("DEBUG", Format("  - 总容量: {} GB", Round(totalBytes / 1073741824, 2)))
            IGLogger.Log("DEBUG", Format("  - 可用空间: {} MB", Round(availableBytes / 1048576, 2)))
            IGLogger.Log("DEBUG", Format("  - 需要空间: {} KB", Round(requiredBytes / 1024, 2)))
        }
        
        ; 添加安全余量（至少保留 100MB 可用空间）
        safetyMargin := 100 * 1024 * 1024  ; 100MB
        
        ; 检查可用空间是否足够
        hasEnoughSpace := availableBytes > (requiredBytes + safetyMargin)
        
        if (!hasEnoughSpace) {
            IGLogger.Log("WARN", Format("磁盘空间不足 [{}]: 可用 {} MB, 需要 {} MB", 
                drivePath,
                Round(availableBytes / 1048576, 2),
                Round((requiredBytes + safetyMargin) / 1048576, 2)))
        }
        
        return hasEnoughSpace
    }
    
    ; 记录恢复成功信息
    static LogRecoverySuccess(method, location, task) {
        message := Format("写入恢复成功`n方法: {1}`n位置: {2}`n原始路径: {3}", 
            method, location, task.filePath)
        IGLogger.Log("SUCCESS", message)
        
        ; 创建恢复信息文件，告诉用户如何找回数据
        infoFile := task.filePath . ".recovery_info.txt"
        try {
            info := "InputGuardian 写入恢复信息`n"
            info .= "========================`n`n"
            info .= "原始文件写入失败，数据已保存到：`n"
            info .= location . "`n`n"
            info .= "时间: " . FormatTime(A_Now, "yyyy-MM-dd HH:mm:ss") . "`n"
            info .= "恢复方法: " . method . "`n`n"
            info .= "请手动将恢复文件的内容合并到原始文件中。"
            
            FileAppend(info, infoFile, "UTF-8")
        } catch {
            ; 忽略信息文件创建失败
        }
    }
    
    ; 通知用户写入失败
    static NotifyUserOfFailure(task) {
        ; 这里可以显示一个 GUI 通知或系统托盘提示
        ; 暂时只记录日志
        IGLogger.Log("CRITICAL", 
            "重要：数据写入完全失败！`n" .
            "文件: " . task.filePath . "`n" .
            "请检查磁盘空间和文件权限。")
    }
    
    ; 定期尝试将内存缓存写入文件
    static FlushMemoryCache() {
        if (this.memoryCache.Length == 0) {
            return
        }
        
        IGLogger.Log("INFO", Format("尝试将{1}条缓存记录写入文件", this.memoryCache.Length))
        
        ; 尝试写入每条缓存记录
        successCount := 0
        i := this.memoryCache.Length
        
        while (i > 0) {
            cache := this.memoryCache[i]
            
            ; 尝试写入原始文件
            try {
                FileAppend(cache.content, cache.filePath, "UTF-8")
                this.memoryCache.RemoveAt(i)
                successCount++
            } catch {
                ; 写入失败，保留在缓存中
            }
            
            i--
        }
        
        if (successCount > 0) {
            IGLogger.Log("SUCCESS", Format("成功从缓存恢复{1}条记录", successCount))
        }
        
        ; 如果还有剩余缓存，稍后再试
        if (this.memoryCache.Length > 0) {
            SetTimer(() => this.FlushMemoryCache(), -300000)  ; 5分钟后再试
        }
    }
    
    ; 清理过期的失败记录（避免内存泄漏）
    static CleanupFailedWrites() {
        currentTime := A_TickCount
        keysToDelete := []
        
        ; 找出超过1小时的记录
        for key, info in this.failedWrites {
            if (currentTime - info.lastAttempt > 3600000) {  ; 1小时
                keysToDelete.Push(key)
            }
        }
        
        ; 删除过期记录
        for key in keysToDelete {
            this.failedWrites.Delete(key)
        }
        
        if (keysToDelete.Length > 0) {
            IGLogger.Log("DEBUG", Format("清理了{1}条过期的失败记录", keysToDelete.Length))
        }
    }
}

; --- 日志系统 ---
class IGLogger {
    static logFile := ""
    static logLevel := "INFO"
    static initialized := false
    static maxLogSize := 10 * 1024 * 1024  ; 10MB
    
    ; 初始化日志系统
    static Init() {
        if (this.initialized) {
            return
        }
        
        ; 确保日志目录存在
        if (!DirExist(IGConfig.LogPath)) {
            try {
                DirCreate(IGConfig.LogPath)
            } catch {
                ; 如果创建失败，使用脚本目录
                IGConfig.LogPath := A_ScriptDir
            }
        }
        
        ; 设置日志文件路径
        dateStr := FormatTime(, "yyyy-MM-dd")
        this.logFile := IGConfig.LogPath . "\InputGuardian_" . dateStr . ".log"
        
        ; 检查并轮转日志文件
        this.RotateLogIfNeeded()
        
        ; 写入启动信息
        this.WriteLog("========================================")
        this.WriteLog("InputGuardian 整合版日志系统启动")
        this.WriteLog("时间: " . FormatTime(, "yyyy-MM-dd HH:mm:ss"))
        this.WriteLog("版本: 4.0.0 - 包含ClipSidian功能")
        this.WriteLog("========================================")
        
        this.CleanOldLogs(7)

        this.initialized := true
    }
    
    ; 记录日志
    static Log(level, message) {
        ; 如果未初始化，尝试初始化
        if (!this.initialized) {
            this.Init()
        }
        
        ; 日志级别过滤
        levels := Map("DEBUG", 0, "INFO", 1, "WARN", 2, "ERROR", 3, "SUCCESS", 1)
        
        currentLevel := levels.Has(this.logLevel) ? levels[this.logLevel] : 1
        messageLevel := levels.Has(level) ? levels[level] : 1
        
        if (messageLevel < currentLevel && level != "SUCCESS") {
            return
        }
        
        ; 格式化日志消息
        timestamp := FormatTime(, "HH:mm:ss")
        logLine := Format("[{1}] [{2}] {3}", timestamp, level, message)
        
        ; 写入日志文件
        this.WriteLog(logLine)
        
        ; 调试模式下输出到调试控制台
        if (IGConfig.DebugMode) {
            OutputDebug(logLine)
        }
    }
    
    ; 写入日志文件
    static WriteLog(text) {
        if (!this.logFile) {
            return
        }
        
        try {
            FileAppend(text . "`n", this.logFile, "UTF-8")
        } catch as e {
            ; 如果写入失败，输出到调试控制台
            OutputDebug("日志写入失败: " . e.Message)
        }
    }
    
    ; 显示状态提示
    static ShowStatus(message, duration := 2000) {
        ; 仅记录到日志，不显示
        this.Log("STATUS", message)
    }
    
    ; 日志轮转
    static RotateLogIfNeeded() {
        if (!this.logFile || !FileExist(this.logFile)) {
            return
        }
        
        try {
            ; 获取文件大小
            fileInfo := FileGetSize(this.logFile)
            
            ; 如果超过最大大小，重命名旧文件
            if (fileInfo > this.maxLogSize) {
                timestamp := FormatTime(, "yyyyMMdd_HHmmss")
                backupName := StrReplace(this.logFile, ".log", "_" . timestamp . ".log")
                FileMove(this.logFile, backupName)
            }
        } catch {
            ; 忽略错误
        }
    }
    
    ; 清理旧日志
    static CleanOldLogs(daysToKeep := 7) {
        if (!DirExist(IGConfig.LogPath)) {
            return
        }
        
        ; 计算截止日期
        cutoffDate := DateAdd(A_Now, -daysToKeep, "Days")
        
        ; 遍历日志文件
        Loop Files, IGConfig.LogPath . "\InputGuardian_*.log" {
            try {
                ; 从文件名提取日期
                if (RegExMatch(A_LoopFileName, "InputGuardian_(\d{4}-\d{2}-\d{2})", &match)) {
                    fileDate := match[1]
                    fileDate := StrReplace(fileDate, "-", "")
                    
                    ; 如果文件太旧，删除它
                    if (fileDate < FormatTime(cutoffDate, "yyyyMMdd")) {
                        FileDelete(A_LoopFileFullPath)
                        this.Log("INFO", "删除旧日志: " . A_LoopFileName)
                    }
                }
            } catch {
                ; 忽略错误
            }
        }
    }
    
    ; 获取当前日志文件路径
    static GetLogFile() {
        return this.logFile
    }
    
    ; 设置日志级别
    static SetLogLevel(level) {
        validLevels := ["DEBUG", "INFO", "WARN", "ERROR"]
        
        for validLevel in validLevels {
            if (level = validLevel) {
                this.logLevel := level
                this.Log("INFO", "日志级别设置为: " . level)
                return true
            }
        }
        
        return false
    }
}  