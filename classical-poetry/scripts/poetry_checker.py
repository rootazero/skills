import argparse
import os
import sys
from typing import cast

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
if SCRIPT_DIR not in sys.path:
    sys.path.insert(0, SCRIPT_DIR)

from yun.common.text_proceed import process_text
from yun.common.common import hanzi_to_pingze
from yun.shi.shi_rhythm import ShiRhythm
from yun.ci.ci_rhythm import CiRhythm
from souyun_api import couplet_words

REFERENCES_DIR = os.path.abspath(os.path.join(SCRIPT_DIR, os.pardir, "references"))


def _split_by_positions(text, positions):
    if not positions:
        return [text]
    parts = []
    start = 0
    for pos in positions:
        end = pos + 1
        parts.append(text[start:end])
        start = end
    if start < len(text):
        parts.append(text[start:])
    return parts


def _clean_text(text):
    cleaned, _ = process_text(text)
    return cleaned


def _split_lines(text):
    raw_lines = [line.strip() for line in text.splitlines() if line.strip()]
    if raw_lines:
        return [_clean_text(line) for line in raw_lines]
    cleaned, positions = process_text(text)
    return _split_by_positions(cleaned, positions)


def check_shi(text, yun_shu, is_trad):
    processed, comma_pos = process_text(text)
    length = len(processed)
    if (length % 10 != 0 and length % 14 != 0) or length < 20:
        return f"诗的字数不正确，可能有不能识别的生僻字，你输入了{length}字"
    process = ShiRhythm(yun_shu, processed, comma_pos, is_trad)
    res = process.main_shi()
    msgs = {
        1: "一句的长短不符合律诗的标准！请检查标点及字数。",
        2: "你输入的每一个韵脚都不在韵书里面，无法分析。",
    }
    if isinstance(res, int) and res in msgs:
        return msgs[res]
    return res


def check_ci(text, yun_shu, ci_pai, ci_pu, ci_format, is_trad):
    processed, comma_pos = process_text(text)
    comma_pos = cast(str, comma_pos)
    process = CiRhythm(yun_shu, ci_pai, processed, comma_pos, ci_format, ci_pu, is_trad)
    res = process.main_ci()
    length = len(processed)
    msgs = {
        0: "不能找到你输入的词牌。",
        1: f"格式与输入词牌不匹配，可能有不能识别的生僻字，你输入了{length}字。",
        2: "格式数字错误。",
        3: f"输入内容无法匹配已有词牌，请检查内容或将词谱更换为钦谱，你输入了{length}字。",
        4: "龙谱中没有该词谱，请切换为钦谱。",
    }
    if isinstance(res, int) and res in msgs:
        return msgs[res]
    return res


def _normalize_pattern(pattern):
    if not pattern:
        return []
    normalized = pattern.replace("／", "\n").replace("/", "\n").replace("|", "\n")
    lines = [line.strip() for line in normalized.splitlines() if line.strip()]
    return ["".join(ch for ch in line if ch in "平仄中") for line in lines]


def _load_qu_patterns():
    path = os.path.join(REFERENCES_DIR, "qu_patterns.md")
    if not os.path.exists(path):
        return {}
    with open(path, "r", encoding="utf-8") as handle:
        content = handle.read()
    patterns = {}
    name = None
    in_block = False
    buffer = []
    for line in content.splitlines():
        if line.startswith("## "):
            name = line[3:].strip()
            continue
        if line.strip().startswith("```"):
            if in_block and name:
                pattern = "\n".join(buffer).strip()
                if pattern:
                    patterns[name] = pattern
                buffer = []
                in_block = False
            else:
                in_block = True
            continue
        if in_block:
            buffer.append(line)
    if in_block and name and buffer:
        pattern = "\n".join(buffer).strip()
        if pattern:
            patterns[name] = pattern
    return patterns


def _pick_qu_pattern(qu_pai):
    patterns = _load_qu_patterns()
    if not qu_pai:
        return ""
    if qu_pai in patterns:
        return patterns[qu_pai]
    return ""


def _extract_words(payload):
    if isinstance(payload, list):
        if payload and isinstance(payload[0], str):
            return payload
        items = []
        for item in payload:
            items.extend(_extract_words(item))
        return items
    if isinstance(payload, dict):
        for value in payload.values():
            words = _extract_words(value)
            if words:
                return words
    return []


def check_qu(text, pattern, yun_shu, is_trad, qu_pai):
    if not pattern:
        pattern = _pick_qu_pattern(qu_pai)
    if not pattern:
        return "缺少曲格 pattern。请提供由平/仄/中组成的格律。"
    pattern_lines = _normalize_pattern(pattern)
    text_lines = _split_lines(text)
    if len(pattern_lines) != len(text_lines):
        return f"曲格行数不匹配：pattern {len(pattern_lines)} 行，文本 {len(text_lines)} 行。"
    report_lines = []
    for line_idx, (pat, line) in enumerate(zip(pattern_lines, text_lines), start=1):
        if len(pat) != len(line):
            return f"第{line_idx}行字数不匹配：pattern {len(pat)} 字，文本 {len(line)} 字。"
        marks = []
        for ch, rule in zip(line, pat):
            pz = hanzi_to_pingze(ch, yun_shu, is_trad)
            if pz == "0":
                marks.append("◎")
            elif pz == "3":
                marks.append("�")
            elif rule == "中":
                marks.append("〇")
            elif rule == "平":
                marks.append("〇" if pz == "1" else "●")
            elif rule == "仄":
                marks.append("〇" if pz == "2" else "●")
        report_lines.append(pat)
        report_lines.append(line)
        report_lines.append("".join(marks))
        report_lines.append("")
    return "\n".join(report_lines).rstrip()


def check_couplet(upper, lower, yun_shu, is_trad, auto_suggest):
    upper_clean = _clean_text(upper)
    lower_clean = _clean_text(lower)
    if len(upper_clean) != len(lower_clean):
        return f"上下联字数不一致：上联{len(upper_clean)}字，下联{len(lower_clean)}字。"
    marks = []
    issues = []
    auto_lower = list(lower_clean)
    for idx, (up, low) in enumerate(zip(upper_clean, lower_clean), start=1):
        up_pz = hanzi_to_pingze(up, yun_shu, is_trad)
        low_pz = hanzi_to_pingze(low, yun_shu, is_trad)
        if "3" in (up_pz, low_pz):
            marks.append("�")
            continue
        if "0" in (up_pz, low_pz):
            marks.append("◎")
            continue
        if (up_pz == "1" and low_pz == "2") or (up_pz == "2" and low_pz == "1"):
            marks.append("〇")
        else:
            marks.append("●")
            issues.append(f"第{idx}字平仄未对。")
            if auto_suggest:
                candidates = _extract_words(couplet_words(up))
                target = "2" if up_pz == "1" else "1"
                for cand in candidates:
                    if len(cand) != 1:
                        continue
                    cand_pz = hanzi_to_pingze(cand, yun_shu, is_trad)
                    if cand_pz == target:
                        auto_lower[idx - 1] = cand
                        break
    last_up = hanzi_to_pingze(upper_clean[-1], yun_shu, is_trad)
    last_low = hanzi_to_pingze(lower_clean[-1], yun_shu, is_trad)
    if last_up == "1":
        issues.append("上联句末应以仄收。")
    if last_low == "2":
        issues.append("下联句末应以平收。")
    report = []
    report.append(f"上联：{upper_clean}")
    report.append(f"下联：{lower_clean}")
    report.append(f"对仗：{''.join(marks)}")
    if issues:
        report.append("问题：" + " ".join(issues))
    if auto_suggest and auto_lower != list(lower_clean):
        report.append("自动替换：" + "".join(auto_lower))
    return "\n".join(report)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--mode", choices=["shi", "ci", "qu", "couplet"], required=True)
    parser.add_argument("--text", default="")
    parser.add_argument("--yun-shu", type=int, default=1)
    parser.add_argument("--trad", action="store_true")
    parser.add_argument("--ci-pai", default="")
    parser.add_argument("--ci-pu", type=int, default=1)
    parser.add_argument("--ci-format", default="")
    parser.add_argument("--pattern", default="")
    parser.add_argument("--qu-pai", default="")
    parser.add_argument("--upper", default="")
    parser.add_argument("--lower", default="")
    parser.add_argument("--suggest", default="")
    parser.add_argument("--auto-suggest", action="store_true")
    args = parser.parse_args()

    if args.suggest:
        suggestions = couplet_words(args.suggest)
        print(suggestions)
        return

    if args.mode == "shi":
        print(check_shi(args.text, args.yun_shu, args.trad))
        return
    if args.mode == "ci":
        print(
            check_ci(
                args.text,
                args.yun_shu,
                args.ci_pai,
                args.ci_pu,
                args.ci_format,
                args.trad,
            )
        )
        return
    if args.mode == "qu":
        print(check_qu(args.text, args.pattern, args.yun_shu, args.trad, args.qu_pai))
        return
    if args.mode == "couplet":
        print(
            check_couplet(
                args.upper, args.lower, args.yun_shu, args.trad, args.auto_suggest
            )
        )
        return


if __name__ == "__main__":
    main()
