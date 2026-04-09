#!/usr/bin/env python3
"""Merge images.json data into each chapter JSON file."""

import json
import os

CONTENT_DIR = "BIO40AStudyCompanion/Resources/Content"

def main():
    # Load images map
    with open(os.path.join(CONTENT_DIR, "images.json")) as f:
        images_map = json.load(f)

    # Update each chapter JSON
    for ch_num in range(1, 12):
        ch_id = f"ch{ch_num:02d}"
        ch_path = os.path.join(CONTENT_DIR, f"{ch_id}.json")
        with open(ch_path) as f:
            ch_data = json.load(f)

        updated = 0
        for section in ch_data["sections"]:
            sec_id = section["id"]
            if sec_id in images_map:
                section["images"] = [
                    {"imageName": img["imageName"], "caption": img["caption"]}
                    for img in images_map[sec_id]
                ]
                updated += 1
            else:
                section["images"] = []

        with open(ch_path, "w") as f:
            json.dump(ch_data, f, indent=2)
        print(f"{ch_id}: {updated} sections updated with images")

    print("Done!")

if __name__ == "__main__":
    main()
