import argparse
import json
import re
from collections import Counter

from souyun_api import poem


CJK_RE = re.compile(r"[\u4e00-\u9fff]")
STOP_CHARS = set(
    "之其而也以于在与及乃若因由为乎于焉矣者兮哉乎与"  # function chars
    "我你他她它吾汝尔彼此君臣民人山水风月日云天地"  # very common
)


def _extract_clauses(payload):
    clauses = []
    if isinstance(payload, dict):
        if "Clauses" in payload and isinstance(payload["Clauses"], list):
            for item in payload["Clauses"]:
                if isinstance(item, dict) and "Content" in item:
                    clauses.append(str(item["Content"]))
        for value in payload.values():
            clauses.extend(_extract_clauses(value))
    elif isinstance(payload, list):
        for item in payload:
            clauses.extend(_extract_clauses(item))
    return clauses


def _clean_text(text):
    chars = CJK_RE.findall(text)
    return "".join(chars)


def _build_bigrams(text):
    grams = []
    for i in range(len(text) - 1):
        a = text[i]
        b = text[i + 1]
        if a in STOP_CHARS or b in STOP_CHARS:
            continue
        grams.append(a + b)
    return grams


def build_reference(keyword, pages, scope, dynasty, poem_type, rhyme, topn):
    all_clauses = []
    for page in range(pages):
        data = poem(
            key=keyword,
            dynasty=dynasty,
            scope=scope,
            poem_type=poem_type,
            rhyme=rhyme,
            page=page,
            json_type=True,
        )
        all_clauses.extend(_extract_clauses(data))

    cleaned_lines = []
    for clause in all_clauses:
        cleaned = _clean_text(clause)
        if cleaned:
            cleaned_lines.append(cleaned)

    char_counter = Counter()
    bigram_counter = Counter()
    for line in cleaned_lines:
        char_counter.update([ch for ch in line if ch not in STOP_CHARS])
        bigram_counter.update(_build_bigrams(line))

    return {
        "keyword": keyword,
        "source_lines": len(cleaned_lines),
        "top_chars": [item for item, _ in char_counter.most_common(topn)],
        "top_bigrams": [item for item, _ in bigram_counter.most_common(topn)],
    }


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--keyword", required=True)
    parser.add_argument("--pages", type=int, default=2)
    parser.add_argument("--scope", default="All")
    parser.add_argument("--dynasty", default=None)
    parser.add_argument("--type", dest="poem_type", default=None)
    parser.add_argument("--rhyme", default=None)
    parser.add_argument("--top", type=int, default=30)
    parser.add_argument("--out", default="")
    args = parser.parse_args()

    result = build_reference(
        keyword=args.keyword,
        pages=args.pages,
        scope=args.scope,
        dynasty=args.dynasty,
        poem_type=args.poem_type,
        rhyme=args.rhyme,
        topn=args.top,
    )

    payload = json.dumps(result, ensure_ascii=False, indent=2)
    if args.out:
        with open(args.out, "w", encoding="utf-8") as handle:
            handle.write(payload)
    else:
        print(payload)


if __name__ == "__main__":
    main()
