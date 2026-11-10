# CleanPaste

Paste from PDFs and AI answers into Word as clean plain text — one hotkey.

**English** | [中文](#中文)

Press `Ctrl+Shift+V` instead of `Ctrl+V`. CleanPaste strips the formatting off whatever is on the clipboard, then pastes it. Because only plain text is written to the clipboard, Word has no formatting left to carry over.

Your normal `Ctrl+V` is untouched, so copying formatted text from another Word document still works as before.

## What it fixes

| Source | Before | After |
| --- | --- | --- |
| PDF body text | One hard line break per visual line | Joined into real paragraphs |
| PDF hyphenation | `hyph-` + newline + `enated` | `hyphenated` |
| AI answers | `## Heading`, `**bold**`, `` `code` `` | Plain words only |
| AI links | `[docs](https://x.com)` | `docs` |
| Terminal output | `┌──┬──┐`, `\e[32m` color codes | Clean tab-separated text |

## Cleaning rules

Applied in this order:

1. **Newlines** — `CRLF`/`CR` normalized to `LF`
2. **ANSI escapes** — terminal color codes and OSC sequences removed
3. **Invisible characters** — zero-width chars, soft hyphens and BOM removed; full-width and non-breaking spaces become normal spaces
4. **Box-drawing characters** — `─│┌┐└┘├┤┬┴┼` and friends become tabs (column separators survive, border rows collapse into paragraph breaks)
5. **Markdown stripping**
   - Dropped entirely: code fences ```` ``` ````, horizontal rules
   - Markers removed, text kept: `#` headings, `>` quotes, `- * +` lists, `1.` numbering, `**` `__` `~~` inline emphasis, inline backticks, link syntax
   - Image syntax removed along with the image
6. **Paragraph boundaries** — PDF copies have no blank lines, so paragraphs are inferred from line length:
   - a line ending in `。！？.!?：:；;` ends a paragraph
   - a line shorter than half the typical line length (median) ends a paragraph
   - for very short text where line length tells you nothing, only sentence-ending punctuation breaks paragraphs
7. **Joining lines inside a paragraph**
   - CJK (including kana, Hangul and full-width punctuation) joins directly with no space
   - Latin text gets a single space
   - a trailing hyphen followed by a letter is joined without the hyphen

Paragraphs are separated by meaning, not by extra blank lines — each one becomes a single paragraph in Word.

## Known limits

These are left as-is:

- **Table structure** — PDF table columns are aligned with spaces; extra spaces get collapsed, but the result is not converted into a real Word table
- **Footnote markers** — `[1]`, `[2]` in body text are kept as-is, not removed or turned into superscripts
- **Formulas and symbols** — math symbols and super/subscripts depend on what the source put on the clipboard; untouched
- **Scanned PDFs** — these are images, no text can be copied; OCR first
- **Non-text clipboards** — copying an image or a file makes `Ctrl+Shift+V` fall back to a normal paste
- **Short one-line-per-paragraph text** — when every line has the same length there is no fold to detect, so they merge into one paragraph. That is inherent to guessing; `Ctrl+Z` undoes it

## Files

```
CleanPaste.ahk        hotkey entry point, 31 lines
lib/CleanText.ahk     cleaning rules, pure functions, testable on its own
```

## Install

Requires [AutoHotkey v2](https://www.autohotkey.com/) (built and tested against v2.0.31).

Run `CleanPaste.ahk` with AutoHotkey v2. To start it at login, put a shortcut to `AutoHotkey64.exe` with `CleanPaste.ahk` as its argument into:

```
%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\
```

## Changing the hotkey

Edit line 14 of `CleanPaste.ahk`. AutoHotkey modifiers: `^` = Ctrl, `+` = Shift, `!` = Alt, `#` = Win.

```ahk
^+v:: {    ; ← change this
```

Restart the script to apply (right-click the tray icon → Exit, then run it again).

---

# 中文

从 PDF 和 AI 回答里复制文字，按一个热键就以纯文本粘进 Word。

**中文** | [English](#cleanpaste)

按 `Ctrl+Shift+V` 代替 `Ctrl+V`。CleanPaste 会把剪贴板内容清洗成纯文字再自动粘贴。因为只往剪贴板写纯文本，Word 没有格式可带，粘贴结果一定是无格式的。

你原来的 `Ctrl+V` 完全不变，所以从 Word 复制带格式文字的正常场景不受影响。

## 用起来是什么效果

| 来源 | 清洗前 | 清洗后 |
| --- | --- | --- |
| PDF 正文 | 每行一个硬换行，句中断开 | 合并成整段 |
| PDF 断词 | `hyph-` + 换行 + `enated` | `hyphenated` |
| AI 回答 | `## 标题`、`**加粗**`、`` `代码` `` | 只剩文字 |
| AI 链接 | `[文档](https://x.com)` | `文档` |
| 终端输出 | `┌──┬──┐`、`\e[32m` 颜色码 | 干净的表格文字 |

## 清洗规则

处理顺序固定，从前往后：

1. **换行归一**：`CRLF`/`CR` 统一成 `LF`
2. **ANSI 转义**：去掉终端颜色码、OSC 序列
3. **不可见字符**：去掉零宽字符、软连字符、BOM；全角空格和不换行空格转普通空格
4. **框线字符**：`─│┌┐└┘├┤┬┴┼` 等转成制表符（表格列分隔保留，边框行退化成段落分隔）
5. **Markdown 剥离**：
   - 整行丢弃：围栏代码块标记 ```` ``` ````、水平分割线
   - 去掉标记保留文字：`#` 标题、`>` 引用、`- * +` 列表、`1.` 编号、`**` `__` `~~` 行内强调、行内反引号、链接语法
   - 图片语法整段删除
6. **段落边界**（PDF 复制没有空行，靠行长推断）：
   - 以句末标点 `。！？.!?：:；;` 结尾的行断段
   - 短于典型行长（中位数）一半的行断段
   - 文本太短、行长推不出结构时，只按句末标点断段
7. **段内换行合并**：
   - 中文（含日文假名、韩文、全角标点）行尾直接拼接
   - 英文行尾补一个空格
   - 行尾是连字符且下一行以字母开头时，去掉连字符直接拼

段落之间按原文的句义分，不额外插空行——每段在 Word 里就是一个段落。

## 已知边界

这些情况脚本**不会**处理，粘出来会保持原样：

- **表格结构**：PDF 表格复制后列对齐靠空格，脚本只压缩多余空格，不会还原成 Word 表格
- **脚注序号**：正文里的 `[1]`、`[2]` 保留，不会自动删除或改成上标
- **公式与特殊符号**：数学符号、上下标由剪贴板本身决定，脚本不动
- **扫描版 PDF**：那是图片，复制不出文字，需要先 OCR
- **无文字剪贴板**：复制的是图片或文件时，按 `Ctrl+Shift+V` 会退回普通粘贴
- **一行一段的短文本**（比如几行等长的短句）：行长看不出折行痕迹时会粘成一段，这是推断的固有局限，按 `Ctrl+Z` 可撤销

## 文件

```
CleanPaste.ahk        热键入口，31 行
lib/CleanText.ahk     清洗规则，纯函数，可单独测试
```

## 安装与自启

需要 [AutoHotkey v2](https://www.autohotkey.com/)（在 v2.0.31 上开发测试）。

用 AutoHotkey v2 运行 `CleanPaste.ahk`。要开机自启，把指向 `AutoHotkey64.exe`、参数为 `CleanPaste.ahk` 的快捷方式放进：

```
%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\
```

## 改热键

改 `CleanPaste.ahk` 第 14 行。AHK 修饰符：`^` = Ctrl，`+` = Shift，`!` = Alt，`#` = Win。

```ahk
^+v:: {    ; ← 改这里
```

改完重启脚本生效（托盘退出再双击运行）。
