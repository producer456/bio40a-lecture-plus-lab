#!/usr/bin/env python3
"""Parse OpenStax Anatomy & Physiology CNXML from GitHub into structured JSON.

Fetches module XML from openstax/osbooks-anatomy-physiology repo and extracts
properly structured glossary terms, review questions, and content paragraphs.
"""

import json
import os
import re
import subprocess
import sys
import time
import xml.etree.ElementTree as ET

OUTPUT_DIR = "BIO40AStudyCompanion/Resources/Content"

# Namespace used in CNXML documents
NS = {"cnx": "http://cnx.rice.edu/cnxml", "md": "http://cnx.rice.edu/mdml"}

# Chapter metadata: (chapter_number, title, module_ids, lectureWeek, labWeek)
CHAPTERS = [
    (1, "An Introduction to the Human Body",
     ["m45981", "m45983", "m45985", "m45986", "m45988", "m45989", "m45990", "m45991"],
     1, 1),
    (2, "The Chemical Level of Organization",
     ["m45996", "m45998", "m46000", "m46004", "m46006", "m46008"],
     2, 0),
    (3, "The Cellular Level of Organization",
     ["m46016", "m46021", "m46023", "m46073", "m46032", "m46034", "m46036"],
     3, 2),
    (4, "The Tissue Level of Organization",
     ["m46045", "m46046", "m46048", "m46049", "m46055", "m46057", "m46058"],
     5, 3),
    (5, "The Integumentary System",
     ["m46059", "m46060", "m46062", "m46064", "m46066"],
     6, 4),
    (6, "Bone Tissue and the Skeletal System",
     ["m46290", "m46341", "m46282", "m46281", "m46301", "m46342", "m46305", "m46295"],
     7, 6),
    (7, "Axial Skeleton",
     ["m46347", "m46344", "m46355", "m46352", "m46350", "m46348"],
     8, 7),
    (8, "The Appendicular Skeleton",
     ["m46370", "m46374", "m46368", "m46375", "m46364", "m46376"],
     8, 7),
    (9, "Joints",
     ["m46402", "m46383", "m46403", "m46381", "m46394", "m46398", "m46377", "m46388"],
     9, 10),
    (10, "Muscle Tissue",
     ["m46450", "m46473", "m46476", "m46447", "m46470", "m46480", "m46438", "m46404", "m46478", "m46407"],
     10, 9),
    (11, "The Muscular System",
     ["m46492", "m46487", "m46498", "m46484", "m46485", "m46495", "m46482"],
     11, 9),
]


def fetch_module_xml(module_id):
    """Fetch a CNXML module from the OpenStax GitHub repo."""
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
        # Decode base64
        b64 = result.stdout.strip()
        decoded = subprocess.run(["base64", "-d"], input=b64, capture_output=True, text=True)
        if decoded.returncode != 0:
            # Try base64 -D on older macOS
            decoded = subprocess.run(["base64", "-D"], input=b64, capture_output=True, text=True)
        return decoded.stdout
    except subprocess.TimeoutExpired:
        print(f"    WARNING: Timeout fetching {module_id}")
        return None


def get_text(element):
    """Recursively extract all text from an XML element, stripping tags."""
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
    """Clean up whitespace in extracted text."""
    text = re.sub(r'\s+', ' ', text).strip()
    return text


def parse_module(xml_text, ch_num, section_idx):
    """Parse a single CNXML module into structured data."""
    # Parse XML
    try:
        root = ET.fromstring(xml_text)
    except ET.ParseError as e:
        print(f"    XML parse error: {e}")
        return None

    ch_id = f"ch{ch_num:02d}"
    sec_id = f"{ch_id}_s{section_idx:02d}"

    # --- Title ---
    title_el = root.find("cnx:title", NS)
    title = get_text(title_el) if title_el is not None else "Untitled"

    # --- Learning Objectives ---
    objectives = []
    # Objectives are in metadata abstract's list items
    metadata = root.find("cnx:metadata", NS)
    if metadata is not None:
        abstract = metadata.find("md:abstract", NS)
        if abstract is not None:
            abstract_xml = ET.tostring(abstract, encoding='unicode')
            # Re-parse with cnx namespace for list/item
            # The abstract contains cnx:para and cnx:list elements
            for list_el in abstract.iter("{http://cnx.rice.edu/cnxml}list"):
                for item_el in list_el.iter("{http://cnx.rice.edu/cnxml}item"):
                    obj_text = clean_text(get_text(item_el))
                    if obj_text and len(obj_text) > 5:
                        objectives.append(obj_text.rstrip('.'))

    # --- Content paragraphs ---
    content_paras = []
    chapter_review = []
    content_el = root.find("cnx:content", NS)

    if content_el is not None:
        # Get top-level paragraphs (not inside summary/review sections)
        summary_section_ids = set()
        review_section_ids = set()

        # Find special sections
        for section in content_el.findall(".//cnx:section", NS):
            section_class = section.get("class", "")
            title_el_s = section.find("cnx:title", NS)
            section_title = get_text(title_el_s) if title_el_s is not None else ""

            if section_class == "summary" or "Chapter Review" in section_title:
                summary_section_ids.add(id(section))
                # Extract chapter review paragraphs
                for para in section.findall("cnx:para", NS):
                    text = clean_text(get_text(para))
                    if text:
                        chapter_review.append(text)
            elif section_class in ("multiple-choice", "free-response"):
                review_section_ids.add(id(section))

        # Collect all paragraphs that are NOT inside summary/review/free-response sections
        def collect_paras(element, skip_ids):
            for child in element:
                tag = child.tag.replace("{http://cnx.rice.edu/cnxml}", "")
                if tag == "section":
                    child_class = child.get("class", "")
                    if id(child) in skip_ids or child_class in ("summary", "multiple-choice", "free-response"):
                        continue
                    collect_paras(child, skip_ids)
                elif tag == "para":
                    text = clean_text(get_text(child))
                    if text and len(text) > 20:
                        content_paras.append(text)

        skip_all = summary_section_ids | review_section_ids
        collect_paras(content_el, skip_all)

    # --- Glossary terms ---
    glossary_terms = []
    glossary_el = root.find("cnx:glossary", NS)
    if glossary_el is not None:
        for defn in glossary_el.findall("cnx:definition", NS):
            term_el = defn.find("cnx:term", NS)
            meaning_el = defn.find("cnx:meaning", NS)
            if term_el is not None and meaning_el is not None:
                term_text = clean_text(get_text(term_el))
                meaning_text = clean_text(get_text(meaning_el))
                if term_text and meaning_text:
                    glossary_terms.append({
                        "term": term_text,
                        "definition": meaning_text,
                        "chapterID": ch_id,
                        "sectionID": sec_id,
                    })

    # --- Review Questions (multiple-choice only) ---
    review_questions = []
    if content_el is not None:
        for section in content_el.findall(".//cnx:section", NS):
            section_class = section.get("class", "")
            if section_class != "multiple-choice":
                continue

            for exercise in section.findall(".//cnx:exercise", NS):
                problem = exercise.find("cnx:problem", NS)
                solution = exercise.find("cnx:solution", NS)
                if problem is None or solution is None:
                    continue

                # Get question text from the para inside problem
                q_para = problem.find("cnx:para", NS)
                if q_para is None:
                    continue
                question_text = clean_text(get_text(q_para))

                # Get choices from list items
                choice_list = problem.find("cnx:list", NS)
                if choice_list is None:
                    continue
                choices = []
                for item in choice_list.findall("cnx:item", NS):
                    choice_text = clean_text(get_text(item))
                    if choice_text:
                        choices.append(choice_text)

                # Must have exactly 4 choices for standard MCQ
                if len(choices) != 4:
                    continue

                # Get answer letter from solution
                sol_para = solution.find("cnx:para", NS)
                if sol_para is None:
                    continue
                answer_text = clean_text(get_text(sol_para)).strip().upper()

                # Convert letter to 0-based index
                letter_map = {"A": 0, "B": 1, "C": 2, "D": 3}
                correct_idx = letter_map.get(answer_text, -1)
                if correct_idx == -1:
                    continue

                q_id = f"{sec_id}_q{len(review_questions):02d}"
                review_questions.append({
                    "id": q_id,
                    "question": question_text,
                    "choices": choices,
                    "correctAnswer": correct_idx,
                    "explanation": "",
                })

    return {
        "title": title,
        "objectives": objectives,
        "content": content_paras,
        "chapterReview": chapter_review,
        "glossary": glossary_terms,
        "reviewQuestions": review_questions,
        "sectionID": sec_id,
    }


def generate_syllabus_json():
    """Generate syllabus.json aligned with actual syllabi."""
    syllabus = {
        "lectureSchedule": [
            {"week": 1, "startDate": "2026-04-06", "topic": "Welcome & Anatomical Language", "chapters": ["ch01"], "assignments": [
                {"name": "Pre-lecture Work 1", "code": "P1", "dueDate": "2026-04-08T12:00:00-07:00", "type": "preLecture"},
                {"name": "Homework 1", "code": "H1", "dueDate": "2026-04-12T23:59:00-07:00", "type": "homework"}
            ]},
            {"week": 2, "startDate": "2026-04-13", "topic": "Chemistry of Life", "chapters": ["ch02"], "assignments": [
                {"name": "Pre-lecture Work 2", "code": "P2", "dueDate": "2026-04-13T12:00:00-07:00", "type": "preLecture"},
                {"name": "Homework 2", "code": "H2", "dueDate": "2026-04-19T23:59:00-07:00", "type": "homework"},
                {"name": "Quiz 1", "code": "Q1", "dueDate": "2026-04-15T14:00:00-07:00", "type": "quiz"}
            ]},
            {"week": 3, "startDate": "2026-04-20", "topic": "Cells", "chapters": ["ch03"], "assignments": [
                {"name": "Pre-lecture Work 3", "code": "P3", "dueDate": "2026-04-20T12:00:00-07:00", "type": "preLecture"},
                {"name": "Homework 3", "code": "H3", "dueDate": "2026-04-26T23:59:00-07:00", "type": "homework"},
                {"name": "Quiz 2", "code": "Q2", "dueDate": "2026-04-22T14:00:00-07:00", "type": "quiz"}
            ]},
            {"week": 4, "startDate": "2026-04-27", "topic": "Midterm 1", "chapters": ["ch01", "ch02", "ch03"], "assignments": [
                {"name": "Pre-lecture Work 4", "code": "P4", "dueDate": "2026-04-27T12:00:00-07:00", "type": "preLecture"},
                {"name": "Midterm 1", "code": "MT1", "dueDate": "2026-04-27T14:00:00-07:00", "type": "midterm"}
            ]},
            {"week": 5, "startDate": "2026-05-04", "topic": "Tissues & Integumentary Tissue", "chapters": ["ch04"], "assignments": [
                {"name": "Homework 4", "code": "H4", "dueDate": "2026-05-10T23:59:00-07:00", "type": "homework"},
                {"name": "Pre-lecture Work 5", "code": "P5", "dueDate": "2026-05-04T12:00:00-07:00", "type": "preLecture"},
                {"name": "Homework 5", "code": "H5", "dueDate": "2026-05-10T23:59:00-07:00", "type": "homework"},
                {"name": "Quiz 3", "code": "Q3", "dueDate": "2026-05-06T14:00:00-07:00", "type": "quiz"}
            ]},
            {"week": 6, "startDate": "2026-05-11", "topic": "Integumentary System", "chapters": ["ch05"], "assignments": [
                {"name": "Pre-lecture Work 6", "code": "P6", "dueDate": "2026-05-11T12:00:00-07:00", "type": "preLecture"},
                {"name": "Homework 6", "code": "H6", "dueDate": "2026-05-17T23:59:00-07:00", "type": "homework"},
                {"name": "Quiz 4", "code": "Q4", "dueDate": "2026-05-13T14:00:00-07:00", "type": "quiz"}
            ]},
            {"week": 7, "startDate": "2026-05-18", "topic": "Bone Tissue", "chapters": ["ch06"], "assignments": [
                {"name": "Pre-lecture Work 7", "code": "P7", "dueDate": "2026-05-18T12:00:00-07:00", "type": "preLecture"},
                {"name": "Homework 7", "code": "H7", "dueDate": "2026-05-24T23:59:00-07:00", "type": "homework"},
                {"name": "Midterm 2", "code": "MT2", "dueDate": "2026-05-20T14:00:00-07:00", "type": "midterm"}
            ]},
            {"week": 8, "startDate": "2026-05-25", "topic": "Skeletal System", "chapters": ["ch07", "ch08"], "assignments": [
                {"name": "Pre-lecture Work 8", "code": "P8", "dueDate": "2026-05-27T12:00:00-07:00", "type": "preLecture"},
                {"name": "Homework 8", "code": "H8", "dueDate": "2026-05-31T23:59:00-07:00", "type": "homework"}
            ]},
            {"week": 9, "startDate": "2026-06-01", "topic": "Joints", "chapters": ["ch09"], "assignments": [
                {"name": "Pre-lecture Work 9", "code": "P9", "dueDate": "2026-06-01T12:00:00-07:00", "type": "preLecture"},
                {"name": "Homework 9", "code": "H9", "dueDate": "2026-06-07T23:59:00-07:00", "type": "homework"},
                {"name": "Quiz 5", "code": "Q5", "dueDate": "2026-06-03T14:00:00-07:00", "type": "quiz"}
            ]},
            {"week": 10, "startDate": "2026-06-08", "topic": "Muscle Tissue & Muscular System", "chapters": ["ch10", "ch11"], "assignments": [
                {"name": "Pre-lecture Work 10", "code": "P10", "dueDate": "2026-06-08T12:00:00-07:00", "type": "preLecture"},
                {"name": "Homework 10", "code": "H10", "dueDate": "2026-06-14T23:59:00-07:00", "type": "homework"},
                {"name": "Quiz 6", "code": "Q6", "dueDate": "2026-06-10T14:00:00-07:00", "type": "quiz"}
            ]},
            {"week": 11, "startDate": "2026-06-15", "topic": "Muscular System Review", "chapters": ["ch11"], "assignments": [
                {"name": "Pre-lecture Work 11", "code": "P11", "dueDate": "2026-06-15T12:00:00-07:00", "type": "preLecture"},
                {"name": "Homework 11", "code": "H11", "dueDate": "2026-06-21T23:59:00-07:00", "type": "homework"},
                {"name": "Midterm 3", "code": "MT3", "dueDate": "2026-06-17T14:00:00-07:00", "type": "midterm"}
            ]},
            {"week": 12, "startDate": "2026-06-22", "topic": "Finals Week", "chapters": [], "assignments": [
                {"name": "Final Exam", "code": "FIN", "dueDate": "2026-06-24T14:00:00-07:00", "type": "final"}
            ]}
        ],
        "labSchedule": [
            {"week": 1, "startDate": "2026-04-06", "topic": "Lab Intro / Intro to Anatomy Language", "chapters": ["ch01"]},
            {"week": 2, "startDate": "2026-04-13", "topic": "Cells and Homeostasis", "chapters": ["ch03"]},
            {"week": 3, "startDate": "2026-04-20", "topic": "Homeostasis and Tissues", "chapters": ["ch04"]},
            {"week": 4, "startDate": "2026-04-27", "topic": "Integumentary System", "chapters": ["ch05"]},
            {"week": 5, "startDate": "2026-05-04", "topic": "In-class Assessment Activity"},
            {"week": 6, "startDate": "2026-05-11", "topic": "Skeletal System Part 1: Bone Tissue", "chapters": ["ch06"]},
            {"week": 7, "startDate": "2026-05-18", "topic": "Skeletal System Part 2: Skeletal Injuries", "chapters": ["ch07", "ch08"]},
            {"week": 8, "startDate": "2026-05-25", "topic": "Holiday / Open OH"},
            {"week": 9, "startDate": "2026-06-01", "topic": "Muscular Tissue and Health", "chapters": ["ch10", "ch11"]},
            {"week": 10, "startDate": "2026-06-08", "topic": "Joints and Exercise", "chapters": ["ch09"]},
            {"week": 11, "startDate": "2026-06-15", "topic": "In-class Assessment Activity"},
            {"week": 12, "startDate": "2026-06-22", "topic": "No Lab: Lecture Final Only"}
        ],
        "grading": {
            "lecture": {
                "lectureActivities": 0.12,
                "preLectureWork": 0.06,
                "homework": 0.15,
                "quizzes": 0.08,
                "midtermsAndFinal": 0.24,
                "totalWeight": 0.65
            },
            "lab": {
                "preLabs": 0.10,
                "labActivities": 0.10,
                "labAssessments": 0.15,
                "totalWeight": 0.35
            }
        },
        "importantDates": [
            {"date": "2026-04-06", "event": "First day of Spring Quarter"},
            {"date": "2026-04-17", "event": "Last day to add classes"},
            {"date": "2026-04-19", "event": "Last day to drop for full refund"},
            {"date": "2026-05-25", "event": "Memorial Day (college closed)"},
            {"date": "2026-05-29", "event": "Last day to drop with W"},
            {"date": "2026-06-19", "event": "Juneteenth Holiday (college closed)"},
            {"date": "2026-06-22", "event": "Final exams begin"},
            {"date": "2026-06-26", "event": "Last day of Spring Quarter"}
        ]
    }
    return syllabus


def main():
    os.makedirs(OUTPUT_DIR, exist_ok=True)

    all_glossary = []
    all_questions = []

    for ch_num, ch_title, module_ids, lec_week, lab_week in CHAPTERS:
        ch_id = f"ch{ch_num:02d}"
        print(f"\n=== Chapter {ch_num}: {ch_title} ({len(module_ids)} modules) ===")

        sections = []
        ch_glossary = []
        ch_questions = 0

        for sec_idx, mod_id in enumerate(module_ids):
            print(f"  Fetching {mod_id}...", end=" ", flush=True)
            xml_text = fetch_module_xml(mod_id)
            if xml_text is None:
                print("FAILED")
                continue

            parsed = parse_module(xml_text, ch_num, sec_idx)
            if parsed is None:
                print("PARSE ERROR")
                continue

            sec_data = {
                "id": parsed["sectionID"],
                "title": parsed["title"],
                "objectives": parsed["objectives"],
                "content": parsed["content"],
                "chapterReview": parsed["chapterReview"],
                "glossary": parsed["glossary"],
                "reviewQuestions": parsed["reviewQuestions"],
            }
            sections.append(sec_data)

            # Collect for aggregate files
            ch_glossary.extend(parsed["glossary"])
            for q in parsed["reviewQuestions"]:
                q_with_ids = dict(q)
                q_with_ids["chapterID"] = ch_id
                q_with_ids["sectionID"] = parsed["sectionID"]
                all_questions.append(q_with_ids)
            ch_questions += len(parsed["reviewQuestions"])

            print(f"OK: \"{parsed['title']}\" - {len(parsed['content'])} paras, "
                  f"{len(parsed['glossary'])} terms, {len(parsed['reviewQuestions'])} MCQs, "
                  f"{len(parsed['objectives'])} objectives")

            # Rate limit
            time.sleep(0.5)

        all_glossary.extend(ch_glossary)

        # Build chapter JSON
        chapter_data = {
            "id": ch_id,
            "number": ch_num,
            "title": ch_title,
            "weekMapping": {"lectureWeek": lec_week, "labWeek": lab_week},
            "sections": sections,
            "glossaryTerms": ch_glossary,
            "totalQuestions": ch_questions,
        }

        ch_path = os.path.join(OUTPUT_DIR, f"{ch_id}.json")
        with open(ch_path, 'w') as f:
            json.dump(chapter_data, f, indent=2)
        print(f"  -> Wrote {ch_path}: {len(sections)} sections, "
              f"{len(ch_glossary)} glossary terms, {ch_questions} questions")

    # --- Syllabus ---
    syllabus = generate_syllabus_json()
    with open(os.path.join(OUTPUT_DIR, "syllabus.json"), 'w') as f:
        json.dump(syllabus, f, indent=2)
    print(f"\nWrote syllabus.json")

    # --- Glossary (deduplicated, sorted) ---
    seen = set()
    unique_glossary = []
    for t in all_glossary:
        key = t["term"].lower().strip()
        if key not in seen and len(key) > 1:
            seen.add(key)
            unique_glossary.append(t)
    unique_glossary.sort(key=lambda t: t["term"].lower())
    with open(os.path.join(OUTPUT_DIR, "glossary.json"), 'w') as f:
        json.dump(unique_glossary, f, indent=2)
    print(f"Wrote glossary.json: {len(unique_glossary)} unique terms")

    # --- Flashcards (grouped by chapter) ---
    decks = {}
    for term in all_glossary:
        ch = term["chapterID"]
        if ch not in decks:
            decks[ch] = []
        decks[ch].append({
            "id": f"fc_{ch}_{len(decks[ch]):03d}",
            "term": term["term"],
            "definition": term["definition"],
            "chapterID": ch,
            "sectionID": term.get("sectionID", ""),
        })
    flashcard_decks = [{"chapterID": ch, "cards": cards} for ch, cards in sorted(decks.items())]
    total_cards = sum(len(d["cards"]) for d in flashcard_decks)
    with open(os.path.join(OUTPUT_DIR, "flashcards.json"), 'w') as f:
        json.dump(flashcard_decks, f, indent=2)
    print(f"Wrote flashcards.json: {total_cards} cards in {len(flashcard_decks)} decks")

    # --- Questions ---
    with open(os.path.join(OUTPUT_DIR, "questions.json"), 'w') as f:
        json.dump(all_questions, f, indent=2)
    print(f"Wrote questions.json: {len(all_questions)} questions")

    # --- Summary ---
    print(f"\n{'='*50}")
    print(f"SUMMARY")
    print(f"{'='*50}")
    print(f"Chapters processed: {len(CHAPTERS)}")
    print(f"Unique glossary terms: {len(unique_glossary)}")
    print(f"Total flashcards: {total_cards}")
    print(f"Total MCQ questions: {len(all_questions)}")
    print(f"\nPer-chapter breakdown:")
    for ch_num, ch_title, module_ids, _, _ in CHAPTERS:
        ch_id = f"ch{ch_num:02d}"
        ch_path = os.path.join(OUTPUT_DIR, f"{ch_id}.json")
        if os.path.exists(ch_path):
            with open(ch_path) as f:
                ch_data = json.load(f)
            n_terms = len(ch_data.get("glossaryTerms", []))
            n_qs = ch_data.get("totalQuestions", 0)
            n_secs = len(ch_data.get("sections", []))
            print(f"  Ch{ch_num:2d}: {n_secs} sections, {n_terms:3d} terms, {n_qs:3d} MCQs  - {ch_title}")


if __name__ == "__main__":
    main()
