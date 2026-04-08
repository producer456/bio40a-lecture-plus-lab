#!/usr/bin/env python3
"""Parse OpenStax A&P 2e textbook .txt files into structured JSON for the BIO 40A app."""

import json
import os
import re
import sys

INPUT_DIR = "textbook-data"
OUTPUT_DIR = "BIO40AStudyCompanion/Resources/Content"

CHAPTER_MAP = {
    "ch01_intro_human_body": (1, "An Introduction to the Human Body"),
    "ch02_chemical_level": (2, "The Chemical Level of Organization"),
    "ch03_cellular_level": (3, "The Cellular Level of Organization"),
    "ch04_tissue_level": (4, "The Tissue Level of Organization"),
    "ch05_integumentary": (5, "The Integumentary System"),
    "ch06_bone_tissue": (6, "Bone Tissue and the Skeletal System"),
    "ch07_axial_skeleton": (7, "Axial Skeleton"),
    "ch08_appendicular_skeleton": (8, "The Appendicular Skeleton"),
    "ch09_joints": (9, "Joints"),
    "ch10_muscle_tissue": (10, "Muscle Tissue"),
    "ch11_muscular_system": (11, "The Muscular System"),
}

# Map chapters to syllabus weeks
WEEK_MAP = {
    1: {"lectureWeek": 1, "labWeek": 1},
    2: {"lectureWeek": 2, "labWeek": 2},
    3: {"lectureWeek": 3, "labWeek": 2},
    4: {"lectureWeek": 5, "labWeek": 3},
    5: {"lectureWeek": 6, "labWeek": 4},
    6: {"lectureWeek": 7, "labWeek": 6},
    7: {"lectureWeek": 8, "labWeek": 6},
    8: {"lectureWeek": 8, "labWeek": 7},
    9: {"lectureWeek": 9, "labWeek": 10},
    10: {"lectureWeek": 10, "labWeek": 9},
    11: {"lectureWeek": 11, "labWeek": 9},
}


def parse_review_questions(text):
    """Extract multiple choice review questions from section text."""
    questions = []

    parts = text.split("Review Questions")
    if len(parts) < 2:
        return questions

    rq_text = parts[1].split("CRITICAL THINKING")[0] if "CRITICAL THINKING" in parts[1] else parts[1]
    rq_text = rq_text.strip()

    # Strategy: find single-letter answers (A, B, C, or D standing alone) and work backwards.
    # The format is: question? choice1 choice2 choice3 choice4 ANSWER
    # Find all standalone answer letters: space + single letter + space (A-D)
    answer_positions = [(m.start(), m.group(1)) for m in re.finditer(r'\s([A-D])\s', rq_text + ' ')]

    for i, (ans_pos, ans_letter) in enumerate(answer_positions):
        # The question+choices block is from the end of previous answer to this answer
        if i == 0:
            block_start = 0
        else:
            block_start = answer_positions[i - 1][0] + 2  # skip past previous answer letter

        block = rq_text[block_start:ans_pos].strip()
        if len(block) < 20:
            continue

        # Find the question: everything up to and including ? or ________.
        q_match = re.search(r'^(.*?(?:\?|_{3,}\.?))\s*(.*)$', block, re.DOTALL)
        if not q_match:
            continue

        question_text = q_match.group(1).strip()
        choices_text = q_match.group(2).strip()

        if not question_text or not choices_text:
            continue

        # Split choices: they're space-separated phrases
        # Use a heuristic: choices are typically 1-6 words each
        # Try to find 4 choices by splitting on boundaries where a new choice starts
        # Choices often start with lowercase or "All of the above" / "Both" / "None"
        # Simple approach: split into roughly 4 equal parts by word count
        words = choices_text.split()
        if len(words) < 4:
            continue

        # Try to find natural choice boundaries
        # Look for patterns where choices are separated
        choices = []

        # Method 1: Try splitting by common patterns
        # If choices contain commas or semicolons as separators
        comma_split = [c.strip() for c in choices_text.split(',') if c.strip()]
        if len(comma_split) == 4:
            choices = comma_split
        else:
            # Method 2: Heuristic word-boundary splitting
            # Many choices are 1-4 words each; try to find 4 groups
            # Look for lowercase-start words after a lowercase word (new choice indicator)
            choice_starts = [0]
            for wi in range(1, len(words)):
                w = words[wi]
                prev = words[wi - 1]
                # New choice likely starts after a word that doesn't end in common prepositions
                if (len(choice_starts) < 4 and
                    not prev.endswith(('of', 'the', 'a', 'an', 'and', 'or', 'in', 'to', 'is', 'for', 'by', 'that', 'with', 'from'))):
                    # Roughly divide by word count
                    if wi >= len(words) * len(choice_starts) / 4:
                        choice_starts.append(wi)

            if len(choice_starts) >= 4:
                choice_starts = choice_starts[:4]
                for ci in range(4):
                    start = choice_starts[ci]
                    end = choice_starts[ci + 1] if ci + 1 < len(choice_starts) else len(words)
                    choices.append(' '.join(words[start:end]))

            # Method 3: If still not 4 choices, try equal division
            if len(choices) != 4:
                chunk = max(1, len(words) // 4)
                choices = []
                for ci in range(4):
                    start = ci * chunk
                    end = start + chunk if ci < 3 else len(words)
                    choices.append(' '.join(words[start:end]))

        if len(choices) == 4 and all(c.strip() for c in choices):
            answer_idx = ord(ans_letter) - ord('A')
            questions.append({
                "question": question_text,
                "choices": choices,
                "correctAnswer": answer_idx,
                "explanation": ""
            })

    return questions


def parse_glossary(text):
    """Extract glossary terms from end of section text."""
    terms = []
    # Glossary terms appear at the very end, as "term definition" pairs
    # They follow after the last Review Questions / Critical Thinking section

    # Find the glossary section (after critical thinking or review questions)
    markers = ["CRITICAL THINKING QUESTIONS", "Review Questions", "Chapter Review"]
    glossary_text = text
    for marker in markers:
        parts = text.rsplit(marker, 1)
        if len(parts) > 1:
            glossary_text = parts[1]

    # Glossary terms are typically at the very end, lowercase word(s) followed by definition
    # Pattern: term (1-4 lowercase words) followed by definition text
    # Look for the last chunk of text after all Q&A

    # Find where answers end (single letter lines like "A" or "D")
    lines_after = glossary_text

    # Simple heuristic: glossary terms are word(s) followed by a longer definition
    # Usually formatted as: "term definition text here"
    # We look for patterns where a short term (1-4 words) is followed by a longer explanation

    term_pattern = re.compile(
        r'(?:^|\s)([a-z][a-z\s\-]{1,50}?)\s+'
        r'((?:the |a |an |is |are |was |process |study |science |group |organ |smallest |steady |breaking |assembly |changes |increase |formation |ability |sum |adjustment )[^\n]{10,})',
        re.IGNORECASE
    )

    for match in term_pattern.finditer(lines_after):
        term = match.group(1).strip()
        definition = match.group(2).strip()
        if len(term) > 1 and len(definition) > 10 and len(term) < 60:
            terms.append({
                "term": term,
                "definition": definition
            })

    return terms


def extract_objectives(text):
    """Extract learning objectives from section text."""
    objectives = []
    obj_match = re.search(
        r'(?:By the end of this section, you will be able to:|you will be able to:)\s*(.*?)(?:\n[a-f0-9]{8}|\n[A-Z][a-z])',
        text, re.DOTALL
    )
    if obj_match:
        obj_text = obj_match.group(1)
        # Split by sentence-starting verbs
        objs = re.split(r'\s+(?=(?:Describe|Explain|Identify|Compare|Discuss|Analyze|List|Define|Name|Distinguish|Classify|Outline|Summarize|Evaluate|Demonstrate))', obj_text)
        objectives = [o.strip() for o in objs if o.strip() and len(o.strip()) > 5]
    return objectives


def extract_chapter_review(text):
    """Extract chapter review summary."""
    match = re.search(r'Chapter Review\s+(.*?)(?:Review Questions|Interactive Link|CRITICAL THINKING)', text, re.DOTALL)
    if match:
        review = match.group(1).strip()
        # Clean up
        review = re.sub(r'\s+', ' ', review)
        return review
    return ""


def extract_content(text):
    """Extract the main content text, cleaned up."""
    # Remove UUID patterns
    content = re.sub(r'[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}', '', text)
    # Remove module IDs like "m45981"
    content = re.sub(r'\bm\d{5}\b', '', content)
    # Remove credit lines
    content = re.sub(r'\(credit[^)]*\)', '', content)
    # Remove "LM ×" microscopy references
    content = re.sub(r'LM\s*×\s*\d+\.?', '', content)

    # Get content between objectives and Chapter Review
    obj_end = re.search(r'(?:By the end of this section.*?(?:\n[a-f0-9]{8}|\n[A-Z][a-z]))', content, re.DOTALL)
    review_start = content.find("Chapter Review")

    if review_start > 0:
        main_content = content[:review_start]
    else:
        main_content = content

    # Remove the title and objectives portion (first ~200 chars that repeat section name)
    # Find first substantial paragraph
    paragraphs = re.split(r'\s{3,}', main_content)
    clean_paragraphs = []
    for p in paragraphs:
        p = p.strip()
        p = re.sub(r'\s+', ' ', p)
        if len(p) > 50:
            clean_paragraphs.append(p)

    return clean_paragraphs


def parse_section(raw_text, chapter_num, section_idx):
    """Parse a single section from raw text."""
    # Get section title from first line
    title_match = re.match(r'\s*(.*?)(?:\s+m\d{5}|\s+[a-f0-9]{8})', raw_text)
    title = title_match.group(1).strip() if title_match else f"Section {section_idx}"
    # Clean duplicate title
    title = re.sub(r'^(.*?)\s+\1', r'\1', title)

    section_id = f"ch{chapter_num:02d}_s{section_idx:02d}"

    objectives = extract_objectives(raw_text)
    chapter_review = extract_chapter_review(raw_text)
    review_questions = parse_review_questions(raw_text)
    glossary = parse_glossary(raw_text)
    content = extract_content(raw_text)

    return {
        "id": section_id,
        "title": title,
        "objectives": objectives,
        "content": content,
        "chapterReview": chapter_review,
        "reviewQuestions": review_questions,
        "glossary": glossary
    }


def parse_chapter_file(filepath, chapter_num, chapter_title):
    """Parse a chapter .txt file into structured data."""
    with open(filepath, 'r') as f:
        raw = f.read()

    # Split by ## headers
    sections_raw = re.split(r'\n## ', raw)
    sections_raw = [s.strip() for s in sections_raw if s.strip()]

    sections = []
    all_glossary = []
    all_questions = []

    for idx, section_text in enumerate(sections_raw):
        section = parse_section(section_text, chapter_num, idx)
        sections.append(section)

        # Collect glossary terms with chapter tag
        for term in section["glossary"]:
            term_with_chapter = term.copy()
            term_with_chapter["chapterID"] = f"ch{chapter_num:02d}"
            term_with_chapter["sectionID"] = section["id"]
            all_glossary.append(term_with_chapter)

        # Collect questions with IDs
        for qi, q in enumerate(section["reviewQuestions"]):
            q_with_id = q.copy()
            q_with_id["id"] = f"{section['id']}_q{qi:02d}"
            q_with_id["chapterID"] = f"ch{chapter_num:02d}"
            q_with_id["sectionID"] = section["id"]
            all_questions.append(q_with_id)

    chapter = {
        "id": f"ch{chapter_num:02d}",
        "number": chapter_num,
        "title": chapter_title,
        "weekMapping": WEEK_MAP.get(chapter_num, {}),
        "sections": sections,
        "glossaryTerms": all_glossary,
        "totalQuestions": len(all_questions)
    }

    return chapter, all_glossary, all_questions


def generate_syllabus_json():
    """Generate syllabus.json from lecture and lab schedule data."""
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
            {"week": 5, "startDate": "2026-05-04", "topic": "In-class Assessment Activity", "chapters": []},
            {"week": 6, "startDate": "2026-05-11", "topic": "Skeletal System Part 1: Bone Tissue", "chapters": ["ch06"]},
            {"week": 7, "startDate": "2026-05-18", "topic": "Skeletal System Part 2: Skeletal Injuries", "chapters": ["ch07", "ch08"]},
            {"week": 8, "startDate": "2026-05-25", "topic": "Holiday / Open OH", "chapters": []},
            {"week": 9, "startDate": "2026-06-01", "topic": "Muscular Tissue and Health", "chapters": ["ch10", "ch11"]},
            {"week": 10, "startDate": "2026-06-08", "topic": "Joints and Exercise", "chapters": ["ch09"]},
            {"week": 11, "startDate": "2026-06-15", "topic": "In-class Assessment Activity", "chapters": []},
            {"week": 12, "startDate": "2026-06-22", "topic": "No Lab: Lecture Final Only", "chapters": []}
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
            {"date": "2026-05-23", "event": "Memorial Day Weekend begins"},
            {"date": "2026-05-29", "event": "Last day to drop with W"},
            {"date": "2026-06-19", "event": "Juneteenth Holiday"},
            {"date": "2026-06-26", "event": "Last day of Spring Quarter"}
        ]
    }
    return syllabus


def generate_flashcards(all_glossary):
    """Generate flashcard decks from glossary terms."""
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
            "sectionID": term.get("sectionID", "")
        })

    return [{"chapterID": ch, "cards": cards} for ch, cards in sorted(decks.items())]


def main():
    os.makedirs(OUTPUT_DIR, exist_ok=True)

    all_glossary = []
    all_questions = []
    all_chapters = []

    for filename, (ch_num, ch_title) in CHAPTER_MAP.items():
        filepath = os.path.join(INPUT_DIR, f"{filename}.txt")
        if not os.path.exists(filepath):
            print(f"  WARNING: {filepath} not found, skipping")
            continue

        print(f"Parsing Chapter {ch_num}: {ch_title}...")
        chapter, glossary, questions = parse_chapter_file(filepath, ch_num, ch_title)
        all_chapters.append(chapter)
        all_glossary.extend(glossary)
        all_questions.extend(questions)

        # Save individual chapter JSON
        ch_path = os.path.join(OUTPUT_DIR, f"ch{ch_num:02d}.json")
        with open(ch_path, 'w') as f:
            json.dump(chapter, f, indent=2)
        print(f"  -> {ch_path} ({len(chapter['sections'])} sections, {len(glossary)} terms, {len(questions)} questions)")

    # Save syllabus
    syllabus = generate_syllabus_json()
    syllabus_path = os.path.join(OUTPUT_DIR, "syllabus.json")
    with open(syllabus_path, 'w') as f:
        json.dump(syllabus, f, indent=2)
    print(f"\nSyllabus -> {syllabus_path}")

    # Save flashcards
    flashcards = generate_flashcards(all_glossary)
    fc_path = os.path.join(OUTPUT_DIR, "flashcards.json")
    with open(fc_path, 'w') as f:
        json.dump(flashcards, f, indent=2)
    print(f"Flashcards -> {fc_path} ({len(all_glossary)} total cards)")

    # Save all questions
    q_path = os.path.join(OUTPUT_DIR, "questions.json")
    with open(q_path, 'w') as f:
        json.dump(all_questions, f, indent=2)
    print(f"Questions -> {q_path} ({len(all_questions)} total)")

    # Save glossary index
    glossary_path = os.path.join(OUTPUT_DIR, "glossary.json")
    # Deduplicate by term name
    seen = set()
    unique_glossary = []
    for t in all_glossary:
        key = t["term"].lower().strip()
        if key not in seen:
            seen.add(key)
            unique_glossary.append(t)
    unique_glossary.sort(key=lambda t: t["term"].lower())
    with open(glossary_path, 'w') as f:
        json.dump(unique_glossary, f, indent=2)
    print(f"Glossary -> {glossary_path} ({len(unique_glossary)} unique terms)")

    print(f"\nDone! {len(all_chapters)} chapters processed.")


if __name__ == "__main__":
    main()
