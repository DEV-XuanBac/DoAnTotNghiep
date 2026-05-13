"""Đếm số chuỗi UI hard-code chứa ký tự Vietnamese trong lib/."""

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

VI_CHARS = (
    "àáảãạăắằẳẵặâấầẩẫậèéẻẽẹêếềểễệ"
    "ìíỉĩịòóỏõọôốồổỗộơớờởỡợùúủũụ"
    "ưứừửữựỳýỷỹỵđ"
    "ÀÁẢÃẠĂẮẰẲẴẶÂẤẦẨẪẬÈÉẺẼẸÊẾỀỂỄỆ"
    "ÌÍỈĨỊÒÓỎÕỌÔỐỒỔỖỘƠỚỜỞỠỢÙÚỦŨỤ"
    "ƯỨỪỬỮỰỲÝỶỸỴĐ"
)
PATTERN = re.compile(r"'[^']*[" + VI_CHARS + r"][^']*'")

total = 0
file_count = 0
top_files: list[tuple[int, Path]] = []

for path in Path("lib").rglob("*.dart"):
    try:
        text = path.read_text(encoding="utf-8")
    except UnicodeDecodeError:
        continue
    matches = PATTERN.findall(text)
    if matches:
        file_count += 1
        total += len(matches)
        top_files.append((len(matches), path))

top_files.sort(reverse=True)
print(f"Tổng: {total} chuỗi Vietnamese trong {file_count} file dart\n")
print("Top 15 file:")
for count, path in top_files[:15]:
    print(f"  {count:>4}  {path}")
