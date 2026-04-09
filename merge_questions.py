#!/usr/bin/env python3
"""
Merge original questions.json with generated extra_questions.json
into a single questions.json for the BIO 40A Study Companion app.
"""

import json
import os

CONTENT_DIR = "/Users/admin/bio40a-lecture-plus-lab/BIO40AStudyCompanion/Resources/Content"
ORIGINAL_PATH = os.path.join(CONTENT_DIR, "questions.json")
EXTRA_PATH = os.path.join(CONTENT_DIR, "extra_questions.json")


def main():
    with open(ORIGINAL_PATH, "r") as f:
        original = json.load(f)
    print(f"Original questions: {len(original)}")

    with open(EXTRA_PATH, "r") as f:
        extra = json.load(f)
    print(f"Extra questions:    {len(extra)}")

    # Check for ID collisions
    orig_ids = {q["id"] for q in original}
    extra_ids = {q["id"] for q in extra}
    collisions = orig_ids & extra_ids
    if collisions:
        print(f"WARNING: {len(collisions)} ID collisions found: {collisions}")
        return

    merged = original + extra
    print(f"Merged total:       {len(merged)}")

    with open(ORIGINAL_PATH, "w") as f:
        json.dump(merged, f, indent=2, ensure_ascii=False)
    print(f"Written to {ORIGINAL_PATH}")

    # Per-chapter breakdown
    chapter_counts = {}
    for q in merged:
        ch = q["chapterID"]
        chapter_counts[ch] = chapter_counts.get(ch, 0) + 1
    print("\nPer chapter:")
    for ch, count in sorted(chapter_counts.items()):
        print(f"  {ch}: {count} questions")


if __name__ == "__main__":
    main()
