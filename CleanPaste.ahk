; CleanPaste — 按 Ctrl+Shift+V 时清洗剪贴板，再自动粘贴
;
; 剪贴板只写入纯文本，Word 因此只能按无格式方式粘贴。
; 要换热键，改下面这一行即可（AHK 修饰符：^ = Ctrl, + = Shift, ! = Alt, # = Win）。

#Requires AutoHotkey v2.0
#SingleInstance Force
SendMode "Input"

#Include lib\CleanText.ahk

A_IconTip := "CleanPaste：Ctrl+Shift+V 去格式粘贴"

^+v:: {
    ; 等修饰键松开再发 Ctrl+V，否则目标程序会收到 Ctrl+Shift+V
    KeyWait "Shift", "T0.4"
    KeyWait "Ctrl", "T0.4"

    raw := A_Clipboard
    out := CleanText(raw)

    ; 剪贴板不是文字（图片、文件）或清洗后为空时，退回普通粘贴
    if (out = "") {
        Send "^v"
        return
    }

    A_Clipboard := StrReplace(out, "`n", "`r`n")
    ClipWait(0.5)
    Send "^v"
}
