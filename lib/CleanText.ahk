; CleanText.ahk — 把剪贴板文本清洗成"可直接粘进 Word 的纯段落"
;
; 处理顺序：换行归一 → 剥 ANSI/不可见字符 → 剥框线 → 剥 Markdown 标记
;          → 按行长判断段落边界 → 合并段内硬换行

CleanText(s) {
    BT := Chr(96)
    ESC := Chr(27)
    BOX := "─│┌┐└┘├┤┬┴┼═║╔╗╚╝╠╣╦╩╬━┃┏┓┗┛┣┫┳┻╋█▀▄░▒▓▌▐▁▔"
    STOP := "[。！？.!?：:；;]"

    ; --- 换行归一 ---
    s := StrReplace(s, "`r`n", "`n")
    s := StrReplace(s, "`r", "`n")

    ; --- 终端 ANSI / OSC 转义序列 ---
    s := RegExReplace(s, ESC "\[[0-9;?]*[ -/]*[@-~]", "")
    s := RegExReplace(s, ESC "\][^" Chr(7) ESC "]*(" Chr(7) "|" ESC "\\\\)?", "")

    ; --- 不可见字符与异常空格 ---
    for cp in [0x00AD, 0x200B, 0x200C, 0x200D, 0x2060, 0xFEFF]
        s := StrReplace(s, Chr(cp), "")
    s := StrReplace(s, Chr(0x00A0), " ")
    s := StrReplace(s, Chr(0x3000), " ")

    ; --- 逐行预清洗 ---
    ; 框线字符转成制表符：边框行退化成空行，内容行保留列分隔
    pre := []
    for line in StrSplit(s, "`n") {
        t := RegExReplace(line, "[" BOX "]", "`t")
        t := RegExReplace(t, "[ ]*`t[ ]*", "`t")
        t := RegExReplace(t, "`t+", "`t")
        t := RegExReplace(t, " {2,}", " ")
        pre.Push(Trim(t, " `t"))
    }

    ; --- 段落边界基准 ---
    ; PDF 抽出的文本没有空行，段末行明显短于正文行；
    ; 用行长中位数当基准，避免个别超长行把基准抬高
    lens := []
    allStop := true
    for t in pre {
        if (t = "" || InStr(t, "`t"))
            continue
        lens.Push(StrLen(t))
        if !RegExMatch(SubStr(t, -1), STOP)
            allStop := false
    }
    med := 0
    if (lens.Length > 0) {
        SortNums(lens)
        med := lens[(lens.Length + 1) // 2]
    }

    blocks := []
    cur := ""
    prevShort := false

    for t in pre {
        if (t = "") {
            prevShort := true
            continue
        }

        ; 围栏代码块标记行、水平分割线整行丢弃
        if RegExMatch(t, "^(?:" BT "{3,}|~{3,})")
            continue
        if (RegExMatch(t, "^(\*\s*){3,}$") || RegExMatch(t, "^(-\s*){3,}$") || RegExMatch(t, "^(_\s*){3,}$"))
            continue

        ; 行首块级标记：只去掉标记本身，但保留"块边界"语义
        isBlockStart := InStr(t, "`t") ? true : false
        if RegExMatch(t, "^#{1,6}\s+") {
            t := RegExReplace(t, "^#{1,6}\s+", "")
            isBlockStart := true
        } else if RegExMatch(t, "^>+\s?") {
            t := RegExReplace(t, "^>+\s?", "")
            isBlockStart := true
        } else if RegExMatch(t, "^[-*+•·▪◦‣]\s+") {
            t := RegExReplace(t, "^[-*+•·▪◦‣]\s+", "")
            isBlockStart := true
        } else if RegExMatch(t, "^\d+[.)]\s+") {
            t := RegExReplace(t, "^\d+[.)]\s+", "")
            isBlockStart := true
        }

        ; 行内标记
        t := RegExReplace(t, "!\[[^\]]*\]\([^)]*\)", "")
        t := RegExReplace(t, "\[([^\]]*)\]\([^)]*\)", "$1")
        t := RegExReplace(t, "\*\*(.+?)\*\*", "$1")
        t := RegExReplace(t, "__(.+?)__", "$1")
        t := RegExReplace(t, "~~(.+?)~~", "$1")
        t := RegExReplace(t, BT "([^" BT "]+?)" BT, "$1")
        t := RegExReplace(t, "(?<![\w*])\*(?![\s*])(.+?)(?<![\s*])\*(?![\w*])", "$1")
        t := RegExReplace(t, "(?<![\w_])_(?![\s_])(.+?)(?<![\s_])_(?![\w_])", "$1")
        t := RegExReplace(t, " {2,}", " ")
        t := Trim(t, " ")

        if (t = "")
            continue

        ; 该行之后是否断段：
        ;   1) 短于典型行长的一半 —— PDF 段末行、标题
        ;   2) 以句末标点结尾 —— Word 里逐段复制的文本
        endsHere := RegExMatch(SubStr(t, -1), STOP)
            || (med >= 12 && !InStr(t, "`t") && StrLen(t) < med * 0.5)

        if (cur = "" || isBlockStart || prevShort) {
            if (cur != "")
                blocks.Push(cur)
            cur := t
        } else {
            cur := JoinLines(cur, t)
        }
        prevShort := endsHere
    }

    if (cur != "")
        blocks.Push(cur)

    out := ""
    for i, b in blocks
        out .= (i > 1 ? "`n" : "") . b
    return out
}

; 合并段内硬换行：中文直接拼、英文补空格、行尾连字符去断词
JoinLines(a, b) {
    p := SubStr(a, -1)
    n := SubStr(b, 1, 1)

    if (p = "-" && RegExMatch(n, "[A-Za-z]"))
        return SubStr(a, 1, -1) . b
    if (IsCJK(p) || IsCJK(n))
        return a . b
    return a . " " . b
}

IsCJK(ch) {
    if (ch = "")
        return false
    c := Ord(ch)
    return (c >= 0x3400 && c <= 0x9FFF)
        || (c >= 0xF900 && c <= 0xFAFF)
        || (c >= 0x3000 && c <= 0x303F)
        || (c >= 0xFF00 && c <= 0xFFEF)
        || (c >= 0x3040 && c <= 0x30FF)
        || (c >= 0xAC00 && c <= 0xD7AF)
}

; AHK v2 没有内置排序，插入排序足够（行长列表只有几十项）
SortNums(arr) {
    i := 2
    while (i <= arr.Length) {
        v := arr[i]
        j := i - 1
        while (j >= 1 && arr[j] > v) {
            arr[j + 1] := arr[j]
            j--
        }
        arr[j + 1] := v
        i++
    }
}
