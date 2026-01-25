import argparse
import json
import re
from collections import Counter
from typing import cast

from reference_builder import build_reference
from yun.common.text_proceed import process_text
from yun.shi.shi_rhythm import ShiRhythm
from yun.ci.ci_rhythm import CiRhythm


CJK_RE = re.compile(r"[\u4e00-\u9fff]")
COMMON_CHARS = set("山水风月日云天地人心夜秋春花江月明清寒长远高低千里万里")


def _clean_text(text):
    return "".join(CJK_RE.findall(text))


def _bigrams(text):
    return [text[i : i + 2] for i in range(len(text) - 1)]


def _theme_review(text, ref):
    cleaned = _clean_text(text)
    top_chars = set(ref.get("top_chars", []))
    top_bigrams = set(ref.get("top_bigrams", []))

    hit_chars = [ch for ch in cleaned if ch in top_chars]
    hit_bigrams = [bg for bg in _bigrams(cleaned) if bg in top_bigrams]

    suspicious = []
    for bg in _bigrams(cleaned):
        if bg in top_bigrams:
            continue
        a, b = bg[0], bg[1]
        if a in COMMON_CHARS or b in COMMON_CHARS:
            continue
        if a in top_chars or b in top_chars:
            continue
        suspicious.append(bg)

    return {
        "hit_chars": Counter(hit_chars).most_common(12),
        "hit_bigrams": Counter(hit_bigrams).most_common(12),
        "suspicious_bigrams": list(dict.fromkeys(suspicious))[:12],
    }


def _check_shi(text, yun_shu, is_trad):
    processed, comma_pos = process_text(text)
    length = len(processed)
    if (length % 10 != 0 and length % 14 != 0) or length < 20:
        return False, f"诗的字数不正确，你输入了{length}字。"
    process = ShiRhythm(yun_shu, processed, comma_pos, is_trad)
    res = process.main_shi()
    if isinstance(res, int):
        return False, f"格律校验失败：错误码 {res}。"
    ok = "●" not in res and "■" not in res
    return ok, res


def _check_ci(text, yun_shu, ci_pai, ci_pu, ci_format, is_trad):
    processed, comma_pos = process_text(text)
    comma_pos = cast(str, comma_pos)
    process = CiRhythm(yun_shu, ci_pai, processed, comma_pos, ci_format, ci_pu, is_trad)
    res = process.main_ci()
    if isinstance(res, int):
        return False, f"词牌校验失败：错误码 {res}。"
    ok = "●" not in res and "■" not in res
    return ok, res


def _meter_score(report):
    if not isinstance(report, str):
        return 0
    total = (
        report.count("〇")
        + report.count("◎")
        + report.count("□")
        + report.count("●")
        + report.count("■")
    )
    if total == 0:
        return 0
    good = report.count("〇") + report.count("◎") + report.count("□")
    score = int(round(100 * good / total))
    return max(0, min(100, score))


def _theme_score(review):
    hit_chars = review.get("hit_chars", [])
    hit_bigrams = review.get("hit_bigrams", [])
    suspicious = review.get("suspicious_bigrams", [])

    unique_chars = len({k for k, _ in hit_chars})
    unique_bigrams = len({k for k, _ in hit_bigrams})
    penalty = len(suspicious)

    score = 20 + unique_chars * 2 + unique_bigrams * 5 - penalty * 5
    return max(0, min(100, score))


def _grade(score):
    if score >= 85:
        return "A"
    if score >= 70:
        return "B"
    if score >= 55:
        return "C"
    return "D"


def _render_markdown(text, form, meter_ok, meter_report, theme_review):
    meter_score = _meter_score(meter_report)
    theme_score = _theme_score(theme_review)
    overall = int(round(meter_score * 0.3 + theme_score * 0.7))

    lines = ["## 诗稿", "", text.strip(), ""]
    lines += ["## 评分", ""]
    lines.append(f"- 格律分: {meter_score}/100 ({_grade(meter_score)})")
    lines.append(f"- 意境分: {theme_score}/100 ({_grade(theme_score)})")
    lines.append(f"- 综合分: {overall}/100 ({_grade(overall)})")
    lines.append("")

    lines += ["## 格律校验", "", meter_report.strip(), ""]
    lines += ["## 意境审核", ""]
    hits = [f"{k}({v})" for k, v in theme_review["hit_chars"]]
    big_hits = [f"{k}({v})" for k, v in theme_review["hit_bigrams"]]
    lines.append("- 主题字命中: " + ("、".join(hits) if hits else "无"))
    lines.append("- 主题词命中: " + ("、".join(big_hits) if big_hits else "无"))
    suspicious = theme_review["suspicious_bigrams"]
    lines.append("- 可疑搭配: " + ("、".join(suspicious) if suspicious else "无"))
    if not meter_ok:
        lines.append("- 建议: 先修正平仄与押韵，再优化语义与意境。")
    elif suspicious:
        lines.append("- 建议: 优先替换可疑搭配，保留主题意象与格律。")
    else:
        lines.append("- 建议: 意象命中正常，可微调语气与用典。")
    lines.append("")

    lines.append("## 结论")
    if not meter_ok:
        lines.append("- 格律未通过，需先修正平仄/押韵。")
    elif theme_score < 60:
        lines.append("- 主题意象偏弱，建议补充典型意象或用典。")
    else:
        lines.append("- 可以进入终稿润色阶段。")
    lines.append("")
    return "\n".join(lines)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--text", required=True)
    parser.add_argument("--theme", required=True)
    parser.add_argument("--mode", choices=["shi", "ci"], default="shi")
    parser.add_argument("--form", default="qilv")
    parser.add_argument("--yun-shu", type=int, default=1)
    parser.add_argument("--trad", action="store_true")
    parser.add_argument("--pages", type=int, default=2)
    parser.add_argument("--scope", default="Sentence")
    parser.add_argument("--dynasty", default=None)
    parser.add_argument("--type", dest="poem_type", default=None)
    parser.add_argument("--rhyme", default=None)
    parser.add_argument("--ci-pai", default="")
    parser.add_argument("--ci-pu", type=int, default=1)
    parser.add_argument("--ci-format", default="")
    parser.add_argument("--out", default="")
    args = parser.parse_args()

    ref = build_reference(
        args.theme, args.pages, args.scope, args.dynasty, args.poem_type, args.rhyme, 40
    )
    theme_review = _theme_review(args.text, ref)

    if args.mode == "ci":
        meter_ok, meter_report = _check_ci(
            args.text, args.yun_shu, args.ci_pai, args.ci_pu, args.ci_format, args.trad
        )
    else:
        meter_ok, meter_report = _check_shi(args.text, args.yun_shu, args.trad)

    md = _render_markdown(args.text, args.form, meter_ok, meter_report, theme_review)
    if args.out:
        with open(args.out, "w", encoding="utf-8") as handle:
            handle.write(md)
    else:
        print(md)


if __name__ == "__main__":
    main()
