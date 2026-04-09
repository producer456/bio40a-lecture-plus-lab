#!/usr/bin/env python3
"""Extract figure images from OpenStax Anatomy & Physiology CNXML modules.

Downloads textbook images and creates Xcode asset catalog entries plus a
mapping JSON file for integration into the BIO 40A Study Companion app.
"""

import json
import os
import re
import subprocess
import sys
import time
import urllib.request
import xml.etree.ElementTree as ET

NS = {"cnx": "http://cnx.rice.edu/cnxml"}

ASSET_DIR = "BIO40AStudyCompanion/Resources/Assets.xcassets/TextbookImages"
CONTENT_DIR = "BIO40AStudyCompanion/Resources/Content"
IMAGES_JSON = os.path.join(CONTENT_DIR, "images.json")

# Same chapter/module list as parse_from_xml.py
CHAPTERS = [
    (1, "An Introduction to the Human Body",
     ["m45981", "m45983", "m45985", "m45986", "m45988", "m45989", "m45990", "m45991"]),
    (2, "The Chemical Level of Organization",
     ["m45996", "m45998", "m46000", "m46004", "m46006", "m46008"]),
    (3, "The Cellular Level of Organization",
     ["m46016", "m46021", "m46023", "m46073", "m46032", "m46034", "m46036"]),
    (4, "The Tissue Level of Organization",
     ["m46045", "m46046", "m46048", "m46049", "m46055", "m46057", "m46058"]),
    (5, "The Integumentary System",
     ["m46059", "m46060", "m46062", "m46064", "m46066"]),
    (6, "Bone Tissue and the Skeletal System",
     ["m46290", "m46341", "m46282", "m46281", "m46301", "m46342", "m46305", "m46295"]),
    (7, "Axial Skeleton",
     ["m46347", "m46344", "m46355", "m46352", "m46350", "m46348"]),
    (8, "The Appendicular Skeleton",
     ["m46370", "m46374", "m46368", "m46375", "m46364", "m46376"]),
    (9, "Joints",
     ["m46402", "m46383", "m46403", "m46381", "m46394", "m46398", "m46377", "m46388"]),
    (10, "Muscle Tissue",
     ["m46450", "m46473", "m46476", "m46447", "m46470", "m46480", "m46438", "m46404", "m46478", "m46407"]),
    (11, "The Muscular System",
     ["m46492", "m46487", "m46498", "m46484", "m46485", "m46495", "m46482"]),
]

# Skip patterns: photos of people, credit images, icons, decorative
SKIP_PATTERNS = [
    r'photo_of',
    r'Photo_of',
    r'portrait',
    r'Portrait',
    r'headshot',
    r'credit',
    r'OSC_',  # OpenStax College icons
]


def fetch_module_xml(module_id):
    """Fetch CNXML from GitHub via gh CLI."""
    cmd = [
        "gh", "api",
        f"repos/openstax/osbooks-anatomy-physiology/contents/modules/{module_id}/index.cnxml",
        "--jq", ".content"
    ]
    try:
        result = subprocess.run(cmd, capture_output=True, text=True, timeout=30)
        if result.returncode != 0:
            print(f"    WARNING: Failed to fetch {module_id}: {result.stderr.strip()}")
            return None
        b64 = result.stdout.strip()
        decoded = subprocess.run(["base64", "-d"], input=b64, capture_output=True, text=True)
        if decoded.returncode != 0:
            decoded = subprocess.run(["base64", "-D"], input=b64, capture_output=True, text=True)
        return decoded.stdout
    except subprocess.TimeoutExpired:
        print(f"    WARNING: Timeout fetching {module_id}")
        return None


def get_text(element):
    """Recursively extract all text from an XML element."""
    if element is None:
        return ""
    parts = []
    if element.text:
        parts.append(element.text)
    for child in element:
        parts.append(get_text(child))
        if child.tail:
            parts.append(child.tail)
    return "".join(parts)


def clean_text(text):
    """Clean whitespace."""
    return re.sub(r'\s+', ' ', text).strip()


def should_skip_image(filename):
    """Check if image should be skipped (decorative, credits, etc)."""
    for pattern in SKIP_PATTERNS:
        if re.search(pattern, filename, re.IGNORECASE):
            return True
    # Only allow jpg/png
    lower = filename.lower()
    if not (lower.endswith('.jpg') or lower.endswith('.jpeg') or lower.endswith('.png')):
        return True
    return False


def is_diagram_or_illustration(filename, caption):
    """Prefer anatomical diagrams and illustrations over photos of people."""
    caption_lower = caption.lower() if caption else ""
    filename_lower = filename.lower()
    # Positive signals for anatomical/scientific content
    good_words = ['anatomy', 'diagram', 'structure', 'system', 'cell', 'tissue',
                  'bone', 'muscle', 'organ', 'section', 'layer', 'view', 'cross',
                  'anterior', 'posterior', 'lateral', 'medial', 'superior', 'inferior',
                  'illustration', 'figure', 'level', 'region', 'cavity', 'membrane',
                  'joint', 'skeleton', 'skull', 'vertebra', 'rib', 'pelvis',
                  'cartilage', 'ligament', 'tendon', 'fiber', 'nerve', 'blood',
                  'skin', 'epidermis', 'dermis', 'microscopic', 'histology',
                  'chemical', 'molecule', 'atom', 'bond', 'reaction', 'protein',
                  'homeostasis', 'feedback', 'loop', 'pathway', 'process']
    score = 0
    for word in good_words:
        if word in caption_lower or word in filename_lower:
            score += 1
    return score


def extract_figures(xml_text, ch_num, section_idx):
    """Extract figure info from CNXML."""
    try:
        root = ET.fromstring(xml_text)
    except ET.ParseError:
        return []

    figures = []
    content_el = root.find("cnx:content", NS)
    if content_el is None:
        return []

    for figure in content_el.iter("{http://cnx.rice.edu/cnxml}figure"):
        # Find image elements inside figure
        for media in figure.iter("{http://cnx.rice.edu/cnxml}media"):
            for image in media.iter("{http://cnx.rice.edu/cnxml}image"):
                src = image.get("src", "")
                if not src:
                    continue
                filename = os.path.basename(src)
                if should_skip_image(filename):
                    continue

                # Get caption
                caption_el = figure.find("{http://cnx.rice.edu/cnxml}caption")
                caption = clean_text(get_text(caption_el)) if caption_el is not None else ""

                # Get the figure title if available
                title_el = figure.find("{http://cnx.rice.edu/cnxml}title")
                title = clean_text(get_text(title_el)) if title_el is not None else ""

                full_caption = title
                if caption:
                    full_caption = f"{title}: {caption}" if title else caption

                # Calculate relevance score
                score = is_diagram_or_illustration(filename, full_caption)

                figures.append({
                    "filename": filename,
                    "caption": full_caption,
                    "score": score,
                })

    return figures


def make_safe_name(filename):
    """Create a safe asset catalog name from a filename."""
    name = os.path.splitext(filename)[0]
    # Replace spaces and special chars with underscores
    name = re.sub(r'[^a-zA-Z0-9_]', '_', name)
    # Remove consecutive underscores
    name = re.sub(r'_+', '_', name)
    # Trim to reasonable length
    if len(name) > 60:
        name = name[:60]
    return name


def download_image(filename, safe_name):
    """Download image from GitHub raw and save to asset catalog."""
    url = f"https://raw.githubusercontent.com/openstax/osbooks-anatomy-physiology/main/media/{filename}"
    ext = os.path.splitext(filename)[1].lower()

    imageset_dir = os.path.join(ASSET_DIR, f"{safe_name}.imageset")
    os.makedirs(imageset_dir, exist_ok=True)

    dest_path = os.path.join(imageset_dir, filename)
    if os.path.exists(dest_path):
        return True  # Already downloaded

    try:
        req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
        with urllib.request.urlopen(req, timeout=30) as resp:
            data = resp.read()
        with open(dest_path, 'wb') as f:
            f.write(data)

        # Create Contents.json for the imageset
        contents = {
            "images": [
                {
                    "filename": filename,
                    "idiom": "universal",
                    "scale": "1x"
                }
            ],
            "info": {
                "author": "xcode",
                "version": 1
            }
        }
        with open(os.path.join(imageset_dir, "Contents.json"), 'w') as f:
            json.dump(contents, f, indent=2)

        return True
    except Exception as e:
        print(f"      Download failed for {filename}: {e}")
        return False


def main():
    # Create directories
    os.makedirs(ASSET_DIR, exist_ok=True)
    os.makedirs(CONTENT_DIR, exist_ok=True)

    # Create namespace Contents.json for TextbookImages folder
    root_contents = {
        "info": {
            "author": "xcode",
            "version": 1
        },
        "properties": {
            "provides-namespace": True
        }
    }
    with open(os.path.join(ASSET_DIR, "Contents.json"), 'w') as f:
        json.dump(root_contents, f, indent=2)

    images_map = {}
    total_downloaded = 0
    chapter_counts = {}

    for ch_num, ch_title, module_ids in CHAPTERS:
        ch_id = f"ch{ch_num:02d}"
        ch_count = 0
        print(f"\n=== Chapter {ch_num}: {ch_title} ===")

        for sec_idx, mod_id in enumerate(module_ids):
            sec_id = f"{ch_id}_s{sec_idx:02d}"
            print(f"  Fetching {mod_id} ({sec_id})...", end=" ", flush=True)

            xml_text = fetch_module_xml(mod_id)
            if xml_text is None:
                print("FAILED")
                time.sleep(0.5)
                continue

            figures = extract_figures(xml_text, ch_num, sec_idx)

            if not figures:
                print(f"no figures")
                time.sleep(0.5)
                continue

            # Sort by relevance score (higher = more relevant), take top 5
            figures.sort(key=lambda f: f["score"], reverse=True)
            selected = figures[:5]

            section_images = []
            for fig in selected:
                safe_name = make_safe_name(fig["filename"])
                print(f"\n    Downloading {fig['filename']}...", end=" ", flush=True)

                if download_image(fig["filename"], safe_name):
                    section_images.append({
                        "imageName": f"TextbookImages/{safe_name}",
                        "caption": fig["caption"],
                        "filename": fig["filename"]
                    })
                    total_downloaded += 1
                    ch_count += 1
                    print("OK", end="")
                else:
                    print("FAIL", end="")

                time.sleep(0.5)

            if section_images:
                images_map[sec_id] = section_images

            print(f"\n    -> {len(section_images)} images for {sec_id}")
            time.sleep(0.5)

        chapter_counts[ch_num] = ch_count
        print(f"  Chapter {ch_num} total: {ch_count} images")

    # Write images.json
    with open(IMAGES_JSON, 'w') as f:
        json.dump(images_map, f, indent=2)
    print(f"\nWrote {IMAGES_JSON}")

    # Summary
    print(f"\n{'='*50}")
    print(f"SUMMARY: {total_downloaded} total images downloaded")
    print(f"{'='*50}")
    for ch_num, ch_title, _ in CHAPTERS:
        count = chapter_counts.get(ch_num, 0)
        print(f"  Ch{ch_num:2d}: {count:3d} images  - {ch_title}")


if __name__ == "__main__":
    main()
