"""Fix mojibake do UTF-8 bytes bị đọc/save sai thành Latin-1 → UTF-8 lần 2.

Pattern: chuỗi 2+ ký tự non-ASCII liên tiếp (mojibake) sẽ được encode lại
sang Latin-1 và decode UTF-8 để khôi phục. Ký tự non-ASCII đơn lẻ
(Vietnamese đúng dạng NFC, vd 'ế') được giữ nguyên.

Cách dùng:
    python tool/fix_mojibake.py            # fix toàn bộ file có mojibake
    python tool/fix_mojibake.py --dry-run  # in danh sách thay đổi, không ghi
"""

from __future__ import annotations

import io
import re
import sys
from pathlib import Path

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
else:
    sys.stdout = io.TextIOWrapper(
        sys.stdout.buffer, encoding="utf-8", errors="replace"
    )

ROOT = Path(__file__).resolve().parent.parent
LIB = ROOT / "lib"

# Bỏ qua file data (đã đúng UTF-8 + URL có %XX nhìn giống mojibake)
SKIP_FILES = {
    LIB / "core" / "database_cn_pinyin_vie" / "HSK_Words.json",
}

# Sequence ≥ 2 chars non-ASCII liên tiếp. Bao gồm cả range CP1252 0x80-0x9F
# (đã được map sang Unicode > 0x100 khi save lại, vd '—' U+2014, '‰' U+2030).
_MOJIBAKE_CHARS = (
    r"\u0080-\u024F"
    r"\u02C6\u02DC"
    r"\u2013\u2014"
    r"\u2018\u2019\u201A\u201C\u201D\u201E"
    r"\u2020\u2021\u2022\u2026"
    r"\u2030\u2039\u203A"
    r"\u20AC\u2122"
    r"\u0152\u0153\u0160\u0161\u0178\u017D\u017E"
)
MOJIBAKE_RUN = re.compile(f"[{_MOJIBAKE_CHARS}]{{2,}}")

# CP1252 không định nghĩa 5 slot này → khi decode bytes lỗi đã giữ nguyên
# thành ký tự control. Khi encode ngược, ta map về chính byte gốc.
_CP1252_UNDEFINED = {0x81, 0x8D, 0x8F, 0x90, 0x9D}


def _encode_cp1252_lenient(s: str) -> bytes:
    """encode cp1252, cho phép giữ nguyên các byte tại slot undefined."""
    out = bytearray()
    for ch in s:
        cp = ord(ch)
        if cp < 0x80:
            out.append(cp)
        elif cp in _CP1252_UNDEFINED:
            out.append(cp)
        else:
            out.extend(ch.encode("cp1252"))  # có thể raise
    return bytes(out)


def _decode_chunk(chunk: str) -> str | None:
    """Encode chunk bằng cp1252 (lenient) rồi decode utf-8. None nếu fail."""
    try:
        raw = _encode_cp1252_lenient(chunk)
    except UnicodeEncodeError:
        return None
    try:
        fixed = raw.decode("utf-8", errors="strict")
    except UnicodeDecodeError:
        return None
    if len(fixed) >= len(chunk):
        return None
    return fixed


def try_decode_run(run: str) -> str:
    """Greedy từ trái, chọn prefix dài nhất decode được. Xử lý mojibake
    chen lẫn ký tự Vietnamese đúng (vd `Ä‘ư` → fix `Ä‘`, giữ `ư`)."""
    out: list[str] = []
    i = 0
    n = len(run)
    while i < n:
        replaced = False
        for j in range(n, i + 1, -1):
            sub = run[i:j]
            if len(sub) < 2:
                break
            fixed = _decode_chunk(sub)
            if fixed is not None:
                out.append(fixed)
                i = j
                replaced = True
                break
        if not replaced:
            out.append(run[i])
            i += 1
    return "".join(out)


def fix_text(text: str) -> tuple[str, int]:
    """Trả về (text đã fix, số cụm thay thế)."""
    count = 0

    def repl(m: re.Match[str]) -> str:
        nonlocal count
        original = m.group(0)
        fixed = try_decode_run(original)
        if fixed != original:
            count += 1
        return fixed

    return MOJIBAKE_RUN.sub(repl, text), count


def iter_target_files() -> list[Path]:
    files: list[Path] = []
    for pattern in ("**/*.dart", "**/*.arb", "**/*.md"):
        for path in LIB.rglob(pattern):
            if path in SKIP_FILES:
                continue
            files.append(path)
    return files


def main(argv: list[str]) -> int:
    dry_run = "--dry-run" in argv
    changed: list[tuple[Path, int]] = []

    for path in iter_target_files():
        try:
            original = path.read_text(encoding="utf-8")
        except UnicodeDecodeError:
            print(f"[SKIP non-UTF8] {path.relative_to(ROOT)}")
            continue

        fixed, count = fix_text(original)
        if count == 0 or fixed == original:
            continue

        changed.append((path, count))
        if not dry_run:
            path.write_text(fixed, encoding="utf-8", newline="\n")

    if not changed:
        print("Không tìm thấy mojibake.")
        return 0

    print(f"{'[DRY-RUN] ' if dry_run else ''}Đã fix {len(changed)} file:")
    for path, count in sorted(changed):
        print(f"  {count:>4} cụm  {path.relative_to(ROOT)}")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
