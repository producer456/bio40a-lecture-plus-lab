#!/usr/bin/env python3
"""
Generate additional multiple-choice questions from glossary terms
for the BIO 40A Study Companion app.

For each glossary term, generates up to 3 question types:
  a) Definition match: "Which of the following best defines [term]?"
  b) Term identification: "[definition]. This describes which of the following?"
  c) True/False style MCQ: "Which statement about [term] is correct?"

Wrong answers are drawn from the SAME chapter when possible.
"""

import json
import random
import os

random.seed(42)  # reproducible output

GLOSSARY_PATH = "/Users/admin/bio40a-lecture-plus-lab/BIO40AStudyCompanion/Resources/Content/glossary.json"
OUTPUT_PATH = "/Users/admin/bio40a-lecture-plus-lab/BIO40AStudyCompanion/Resources/Content/extra_questions.json"


def load_glossary():
    with open(GLOSSARY_PATH, "r") as f:
        return json.load(f)


def group_by_chapter(glossary):
    chapters = {}
    for entry in glossary:
        ch = entry["chapterID"]
        chapters.setdefault(ch, []).append(entry)
    return chapters


def pick_distractors(pool, exclude_term, n=3):
    """Pick n random entries from pool whose term != exclude_term."""
    candidates = [e for e in pool if e["term"] != exclude_term]
    if len(candidates) < n:
        return candidates  # rare edge case
    return random.sample(candidates, n)


def make_definition_match(entry, distractors, qid):
    """Type A: Which of the following best defines [term]?"""
    correct_def = entry["definition"][0].upper() + entry["definition"][1:]
    choices_raw = [correct_def]
    for d in distractors:
        ddef = d["definition"][0].upper() + d["definition"][1:]
        choices_raw.append(ddef)
    # shuffle and track correct index
    indices = list(range(4))
    random.shuffle(indices)
    choices = [choices_raw[i] for i in indices]
    correct_answer = indices.index(0)

    return {
        "id": qid,
        "question": f"Which of the following best defines \"{entry['term']}\"?",
        "choices": choices,
        "correctAnswer": correct_answer,
        "explanation": "",
        "chapterID": entry["chapterID"],
        "sectionID": entry["sectionID"],
    }


def make_term_identification(entry, distractors, qid):
    """Type B: [definition]. This describes which of the following?"""
    definition_sentence = entry["definition"][0].upper() + entry["definition"][1:]
    if not definition_sentence.endswith("."):
        definition_sentence += "."

    correct_term = entry["term"]
    choices_raw = [correct_term]
    for d in distractors:
        choices_raw.append(d["term"])
    indices = list(range(4))
    random.shuffle(indices)
    choices = [choices_raw[i] for i in indices]
    correct_answer = indices.index(0)

    return {
        "id": qid,
        "question": f"{definition_sentence} This describes which of the following?",
        "choices": choices,
        "correctAnswer": correct_answer,
        "explanation": "",
        "chapterID": entry["chapterID"],
        "sectionID": entry["sectionID"],
    }


def make_true_false_mcq(entry, distractors, qid):
    """Type C: Which statement about [term] is correct?
    Correct choice = real definition. Wrong choices = other terms' definitions
    phrased as if they belong to this term."""
    term = entry["term"]
    correct_stmt = f"{term[0].upper()}{term[1:]} is defined as: {entry['definition']}."
    wrong_stmts = []
    for d in distractors:
        wrong_stmts.append(f"{term[0].upper()}{term[1:]} is defined as: {d['definition']}.")

    choices_raw = [correct_stmt] + wrong_stmts[:3]
    indices = list(range(len(choices_raw)))
    random.shuffle(indices)
    choices = [choices_raw[i] for i in indices]
    correct_answer = indices.index(0)

    return {
        "id": qid,
        "question": f"Which statement about \"{term}\" is correct?",
        "choices": choices,
        "correctAnswer": correct_answer,
        "explanation": "",
        "chapterID": entry["chapterID"],
        "sectionID": entry["sectionID"],
    }


def main():
    glossary = load_glossary()
    chapters = group_by_chapter(glossary)

    all_questions = []
    chapter_counts = {}

    for ch_id in sorted(chapters.keys()):
        terms = chapters[ch_id]
        ch_num = ch_id.replace("ch", "")
        counter = 0

        for entry in terms:
            distractors = pick_distractors(terms, entry["term"], n=3)
            if len(distractors) < 3:
                continue  # skip if not enough distractors in chapter

            # Type A
            counter += 1
            qid = f"gen_{ch_id}_{counter:03d}"
            all_questions.append(make_definition_match(entry, distractors, qid))

            # Type B
            counter += 1
            qid = f"gen_{ch_id}_{counter:03d}"
            all_questions.append(make_term_identification(entry, distractors, qid))

            # Type C
            counter += 1
            qid = f"gen_{ch_id}_{counter:03d}"
            all_questions.append(make_true_false_mcq(entry, distractors, qid))

        chapter_counts[ch_id] = counter

    with open(OUTPUT_PATH, "w") as f:
        json.dump(all_questions, f, indent=2, ensure_ascii=False)

    print(f"Generated {len(all_questions)} extra questions -> {OUTPUT_PATH}")
    print("Per chapter:")
    for ch, count in sorted(chapter_counts.items()):
        print(f"  {ch}: {count} questions")


if __name__ == "__main__":
    main()
