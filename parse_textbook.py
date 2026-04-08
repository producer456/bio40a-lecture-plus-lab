#!/usr/bin/env python3
"""Parse OpenStax A&P 2e textbook .txt files into structured JSON for the BIO 40A app.
Version 2: Complete rewrite with proper glossary, question, and section title parsing."""

import json
import os
import re

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

WEEK_MAP = {
    1: {"lectureWeek": 1, "labWeek": 1},
    2: {"lectureWeek": 2, "labWeek": 0},
    3: {"lectureWeek": 3, "labWeek": 2},
    4: {"lectureWeek": 5, "labWeek": 3},
    5: {"lectureWeek": 6, "labWeek": 4},
    6: {"lectureWeek": 7, "labWeek": 6},
    7: {"lectureWeek": 8, "labWeek": 7},
    8: {"lectureWeek": 8, "labWeek": 7},
    9: {"lectureWeek": 9, "labWeek": 10},
    10: {"lectureWeek": 10, "labWeek": 9},
    11: {"lectureWeek": 11, "labWeek": 9},
}


def extract_section_title(raw_text):
    """Extract the real section title from the beginning of section text.

    Format: 'Title Title m##### Title uuid ...'
    The title appears first, then repeats with a module ID like m45983.
    """
    # The title is the text before the first module ID (m followed by 5 digits)
    match = re.match(r'^\s*(.*?)\s+m\d{5}\s', raw_text)
    if match:
        title = match.group(1).strip()
        # The title often appears twice concatenated: "Overview of Anatomy and Physiology"
        # Check if title is a doubled version and deduplicate
        half = len(title) // 2
        if half > 3 and title[:half].strip() == title[half:].strip():
            title = title[:half].strip()
        return title

    # Fallback: take first line/sentence
    first_line = raw_text.strip().split('\n')[0][:100]
    return first_line.strip()


def extract_objectives(raw_text):
    """Extract learning objectives from section text."""
    objectives = []
    # Look for "By the end of this section, you will be able to:" or "After studying this chapter"
    patterns = [
        r'(?:By the end of this section, you will be able to:|you will be able to:)\s*(.*?)(?:[a-f0-9]{8}-[a-f0-9]{4}|[A-Z][a-z]{2,}\s+[a-z])',
        r'(?:Chapter Objectives.*?able to:)\s*(.*?)(?:[a-f0-9]{8}-[a-f0-9]{4}|Though|The )'
    ]

    for pattern in patterns:
        match = re.search(pattern, raw_text, re.DOTALL)
        if match:
            obj_text = match.group(1).strip()
            # Split by verb phrases that start objectives
            verbs = r'(?:Describe|Explain|Identify|Compare|Discuss|Analyze|List|Define|Name|Distinguish|Classify|Outline|Summarize|Evaluate|Demonstrate|Predict|Differentiate|Relate|Give|Provide|Specify|Recognize|State|Determine|Assess|Map|Label|Locate|Contrast|Calculate|Examine|Trace|Outline|Detail)'
            objs = re.split(rf'\s+(?={verbs})', obj_text)
            objectives = [o.strip().rstrip('.') for o in objs if o.strip() and len(o.strip()) > 10]
            if objectives:
                break

    return objectives


def extract_review_questions(raw_text):
    """Extract multiple choice review questions.

    Format: Question text? choice1 choice2 choice3 choice4 LETTER
    The answer is a single capital letter (A/B/C/D) standing alone.
    """
    questions = []

    # Find Review Questions section
    rq_idx = raw_text.find('Review Questions')
    if rq_idx < 0:
        return questions

    ct_idx = raw_text.find('CRITICAL THINKING')
    if ct_idx < 0:
        ct_idx = len(raw_text)

    rq_text = raw_text[rq_idx + len('Review Questions'):ct_idx].strip()
    if not rq_text:
        return questions

    # Strategy: Find answer letters (A, B, C, or D) that stand alone
    # These mark the end of each question block
    # Pattern: text ending in letter answer, space, then next question or end

    # Find all standalone answer letters: preceded by space, followed by space or end
    # We need to be careful not to match "A" in the middle of text
    answer_positions = []
    i = 0
    while i < len(rq_text):
        if rq_text[i] in 'ABCD':
            # Check if it's a standalone answer letter
            before_ok = (i == 0 or rq_text[i-1] == ' ')
            after_ok = (i == len(rq_text) - 1 or rq_text[i+1] == ' ')
            if before_ok and after_ok:
                # Check it's not part of a word (look at surrounding context)
                # Standalone answers are typically at the end of a choice list
                # Followed by either another question or end of text
                if i + 2 < len(rq_text):
                    next_char = rq_text[i+2] if i+2 < len(rq_text) else ''
                    # Next should be uppercase (start of new question) or end
                    if next_char.isupper() or next_char == '' or i + 2 >= len(rq_text):
                        answer_positions.append((i, rq_text[i]))
                elif i + 1 >= len(rq_text) - 1:
                    answer_positions.append((i, rq_text[i]))
            i += 1
        else:
            i += 1

    # Now extract question blocks between answers
    for qi, (ans_pos, ans_letter) in enumerate(answer_positions):
        if qi == 0:
            block_start = 0
        else:
            block_start = answer_positions[qi-1][0] + 2

        block = rq_text[block_start:ans_pos].strip()
        if len(block) < 15:
            continue

        # Find the question part (ends with ? or ________.)
        q_match = re.search(r'^(.*?(?:\?|_{2,}\.?))\s+(.+)$', block, re.DOTALL)
        if not q_match:
            continue

        question_text = re.sub(r'\s+', ' ', q_match.group(1).strip())
        choices_text = q_match.group(2).strip()

        if not question_text or not choices_text:
            continue

        # Parse 4 choices from the choices text
        # Strategy: Use knowledge that choices are complete phrases/terms
        # Try to find natural break points
        choices = smart_split_choices(choices_text)

        if len(choices) == 4 and all(len(c.strip()) > 0 for c in choices):
            answer_idx = ord(ans_letter) - ord('A')
            questions.append({
                "question": question_text,
                "choices": [c.strip() for c in choices],
                "correctAnswer": min(answer_idx, 3),
                "explanation": ""
            })

    return questions


def smart_split_choices(text):
    """Intelligently split a string of 4 concatenated multiple choice answers.

    Uses multiple heuristics to find the best split points.
    """
    words = text.split()
    n = len(words)

    if n < 4:
        return [text]

    # Heuristic 1: If there are exactly 4 words or short phrases separated naturally
    # Check for common patterns

    # Try comma-separated
    parts = [p.strip() for p in text.split(',') if p.strip()]
    if len(parts) == 4:
        return parts

    # Try semicolon-separated
    parts = [p.strip() for p in text.split(';') if p.strip()]
    if len(parts) == 4:
        return parts

    # Heuristic 2: Look for "All of the above", "None of the above", "Both A and B"
    # These are typically the last choice
    special_last = re.search(r'(All of the above|None of the above|Both \w+ and \w+|all of the above)$', text)

    # Heuristic 3: Find choice boundaries using capitalization and word patterns
    # In anatomy MCQ, choices often start with: lowercase noun, "a/an/the" + noun,
    # or are single technical terms

    # Best approach: try to divide words into 4 roughly equal groups
    # but respect word boundaries that look like choice boundaries

    # Score each word boundary as a potential choice split
    scores = [0.0] * (n - 1)

    for i in range(n - 1):
        w_before = words[i]
        w_after = words[i + 1]

        # Higher score = more likely to be a choice boundary

        # Word after starts with lowercase and word before doesn't end with common prepositions
        if w_before.lower() not in ('of', 'the', 'a', 'an', 'and', 'or', 'in', 'to', 'is', 'for', 'by', 'that', 'with', 'from', 'not', 'its', 'it', 'are', 'was', 'be', 'as', 'at', 'on', 'into', 'through', 'between', 'within', 'than', 'more', 'most', 'all', 'each', 'both', 'has', 'have', 'can', 'will', 'which', 'their', 'this', 'these', 'those'):
            scores[i] += 1.0

        # If word before ends a sentence fragment (period, no period but complete thought)
        if w_before.endswith('.') or w_before.endswith(','):
            scores[i] += 2.0

        # Positional preference: choices should be roughly equal length
        ideal_positions = [n * k / 4 for k in range(1, 4)]
        for pos in ideal_positions:
            dist = abs((i + 1) - pos)
            if dist < 2:
                scores[i] += 1.5 - dist * 0.5

    # Find top 3 split points
    scored_indices = sorted(range(len(scores)), key=lambda x: scores[x], reverse=True)

    # Take top 3 that are reasonably spaced
    splits = []
    for idx in scored_indices:
        if len(splits) >= 3:
            break
        # Ensure minimum spacing of 1 word per choice
        if all(abs(idx - s) >= 1 for s in splits):
            splits.append(idx)

    if len(splits) < 3:
        # Fallback: equal division
        chunk = max(1, n // 4)
        return [' '.join(words[i*chunk:(i+1)*chunk if i < 3 else n]) for i in range(4)]

    splits.sort()

    choices = [
        ' '.join(words[:splits[0]+1]),
        ' '.join(words[splits[0]+1:splits[1]+1]),
        ' '.join(words[splits[1]+1:splits[2]+1]),
        ' '.join(words[splits[2]+1:]),
    ]

    return choices


def extract_glossary_terms(raw_text):
    """Extract glossary terms from the end of a section.

    Glossary terms appear after the critical thinking Q&A (or review questions).
    Format: lowercase_term definition_starting_with_common_words
    Terms are short (1-4 words, lowercase), definitions are longer explanations.
    """
    terms = []

    # Find the glossary region: after critical thinking answers, or after review questions
    # The glossary is at the very end of the section text

    # Try to find where glossary starts
    # Strategy: Work backwards from the end. Glossary terms are lowercase words
    # followed by definitions. Find the transition point.

    # First, find the last "answer" to critical thinking (a long paragraph)
    # or the last answer letter from review questions

    text = raw_text.strip()

    # Find the end of critical thinking section by looking for the last
    # answer block, then the glossary terms follow

    # The glossary terms are always at the very end
    # They follow the pattern: term1 definition1 term2 definition2
    # where terms are 1-4 lowercase words and definitions explain them

    # Known A&P glossary term patterns (from OpenStax):
    # - Single word: "anatomy", "physiology", "homeostasis"
    # - Two words: "gross anatomy", "organ system", "negative feedback"
    # - Phrases: "microscopic anatomy", "serous membrane"

    # Find where glossary likely starts by looking for a sequence of
    # lowercase word(s) followed by definition-like text

    # Approach: scan from end, build terms backwards
    # A glossary term starts with a lowercase letter and is followed by
    # a definition that often contains words like "the", "a", "process", etc.

    # Better approach: find the last substantive paragraph (critical thinking answer),
    # then everything after it is glossary

    # Find critical thinking section
    ct_idx = text.rfind('CRITICAL THINKING QUESTIONS')
    rq_idx = text.rfind('Review Questions')

    if ct_idx > 0:
        after_section = text[ct_idx:]
    elif rq_idx > 0:
        after_section = text[rq_idx:]
    else:
        return terms

    # The glossary terms are the last portion - they consist of
    # lowercase-starting terms. Find where the last answer ends
    # and glossary begins.

    # Heuristic: Find the last sentence that ends with a period and
    # is followed by a lowercase word that starts a glossary entry

    # Split into "words" and look for the pattern
    # glossary_term definition_word definition_word... glossary_term definition...

    # A more robust approach: extract known glossary term patterns
    # Terms are lowercase, definitions contain specific marker words

    # Use a regex that matches: lowercase_term(s) followed by definition text
    # The definition typically starts with: "the ", "a ", "an ", "process ", "study ",
    # "science ", "group ", "organ ", "smallest ", "steady ", "breaking ",
    # "assembly ", "changes ", "increase ", "formation ", "ability ", "sum ",
    # or a gerund (-ing word), or a descriptive phrase

    glossary_pattern = re.compile(
        r'(?:^|\s)'
        r'([a-z][a-z\s\-\']{0,60}?)'  # term: 1+ lowercase words
        r'\s+'
        r'('  # definition start
            r'(?:'
                r'(?:the|a|an|one|two|three|four|five|six|seven|eight|nine|ten|'
                r'process|study|science|group|organ|smallest|steady|breaking|'
                r'assembly|changes|increase|increase|formation|ability|sum|'
                r'adjustment|living|type|region|describes|referring|relating|'
                r'condition|disease|disorder|structure|tissue|cell|bone|muscle|'
                r'joint|layer|membrane|system|part|area|term|state|form|'
                r'chemical|compound|molecule|protein|enzyme|hormone|receptor|'
                r'movement|contraction|relaxation|extension|flexion|'
                r'outer|inner|upper|lower|first|second|third|fourth|'
                r'large|small|thin|thick|flat|long|short|round|'
                r'having|being|making|producing|containing|consisting|'
                r'act|shaft|point|bundle|band|ring|sheet|cord|tube|'
                r'dense|loose|hard|soft|deep|superficial|'
                r'fibrous|cartilaginous|synovial|connective|epithelial|'
                r'pertaining|involuntary|voluntary|skeletal|smooth|cardiac|'
                r'functional|structural|mature|immature|'
                r'specialized|division|'
                r'most|also|network|pair|set|line|ridge|opening|'
                r'secretion|absorption|protection|support|'
                r'elongated|rounded|flattened|irregular|'
                r'prominent|narrow|broad|curved|'
                r'located|found|situated|'
                r'anterior|posterior|superior|inferior|medial|lateral|proximal|distal|dorsal|ventral|'
                r'in|on|at|to)\s'  # definition starts with these words
            r')'
            r'[^.]*?'  # rest of definition (up to reasonable length)
        r')'
    )

    # Find all potential glossary entries
    # Work on just the last portion of the section
    # Estimate: glossary is typically the last 20-30% of the section after CT questions

    # Get everything after the last recognizable answer
    # The answers to CT questions end with complete sentences

    # Simple approach: try to find glossary start by looking for
    # the first lowercase word that begins a glossary entry
    # after the last period-ending sentence in the CT section

    # Let's find all the content after CT answers end
    if ct_idx > 0:
        ct_section = text[ct_idx + len('CRITICAL THINKING QUESTIONS'):]
    else:
        ct_section = after_section

    # Find pairs of lowercase term + definition
    # Use a different approach: look for known term patterns
    # The glossary starts with a lowercase word, and after the last CT answer

    # Find the last sentence that looks like a CT answer (ends with period,
    # contains enough text) before glossary terms begin

    words_list = ct_section.split()
    glossary_start = None

    # Look through words for the transition from CT answers to glossary
    # CT answers contain mixed case sentences. Glossary terms start with lowercase.
    # The transition is: end of a sentence (period) -> lowercase term -> definition

    for i in range(len(words_list) - 2):
        w = words_list[i]
        next_w = words_list[i+1]

        # Period at end of word, followed by lowercase (potential glossary start)
        if w.endswith('.') and next_w[0].islower() and not next_w.startswith('http'):
            # Check if what follows looks like a glossary entry
            # A glossary term is typically 1-4 lowercase words
            # followed by a definition
            potential_term_words = []
            j = i + 1
            while j < len(words_list) and words_list[j][0].islower() and len(potential_term_words) < 5:
                if any(words_list[j].startswith(defword) for defword in
                       ['the', 'a', 'an', 'process', 'study', 'science', 'state',
                        'group', 'organ', 'smallest', 'steady', 'breaking',
                        'assembly', 'sum', 'living', 'type', 'region',
                        'condition', 'structure', 'tissue', 'cell', 'pertaining',
                        'involuntary', 'voluntary', 'describes', 'also', 'most',
                        'functional', 'structural', 'having', 'network', 'act',
                        'chemical', 'dense', 'in', 'on', 'outer', 'inner',
                        'located', 'found', 'one', 'two']):
                    break
                potential_term_words.append(words_list[j])
                j += 1

            if 1 <= len(potential_term_words) <= 4 and j < len(words_list):
                # This looks like a glossary start
                glossary_start = i + 1
                break

    if glossary_start is None:
        return terms

    # Now parse the glossary section
    glossary_text = ' '.join(words_list[glossary_start:])

    # Parse term-definition pairs
    # Strategy: terms are lowercase, definitions contain specific starting words
    # We build up terms word by word until we hit a definition-starting word

    gwords = glossary_text.split()
    current_term_words = []
    current_def_words = []
    parsing_def = False

    def is_def_start(word):
        """Check if this word likely starts a definition."""
        starters = {'the', 'a', 'an', 'process', 'study', 'science', 'state',
                    'group', 'organ', 'smallest', 'steady', 'breaking', 'sum',
                    'assembly', 'living', 'type', 'region', 'describes', 'also',
                    'condition', 'structure', 'tissue', 'cell', 'most',
                    'functional', 'structural', 'having', 'network', 'act',
                    'chemical', 'dense', 'in', 'on', 'outer', 'inner', 'one', 'two',
                    'located', 'found', 'pertaining', 'involuntary', 'voluntary',
                    'specialized', 'division', 'movement', 'contraction',
                    'referring', 'relating', 'secretion', 'elongated', 'rounded',
                    'prominent', 'narrow', 'broad', 'curved', 'mature', 'immature',
                    'pair', 'set', 'line', 'band', 'ring', 'sheet', 'cord',
                    'shaft', 'point', 'bundle', 'layer', 'membrane', 'system',
                    'part', 'area', 'term', 'form', 'compound', 'molecule',
                    'protein', 'joint', 'bone', 'muscle', 'anterior', 'posterior',
                    'superior', 'inferior', 'medial', 'lateral', 'proximal', 'distal',
                    'deep', 'superficial', 'large', 'small', 'thin', 'thick',
                    'flat', 'long', 'short', 'round', 'hard', 'soft',
                    'fibrous', 'cartilaginous', 'synovial', 'connective', 'epithelial',
                    'skeletal', 'smooth', 'cardiac', 'irregular', 'loose',
                    'first', 'second', 'third', 'fourth',
                    'upper', 'lower', 'any', 'abnormal'}
        return word.lower().rstrip('.,;:') in starters

    def save_term():
        if current_term_words and current_def_words:
            term = ' '.join(current_term_words)
            definition = ' '.join(current_def_words)
            # Clean up
            term = term.strip().rstrip('.,;:')
            definition = definition.strip()
            if len(term) > 1 and len(definition) > 10 and len(term) < 80:
                terms.append({"term": term, "definition": definition})

    for wi, word in enumerate(gwords):
        if not parsing_def:
            # We're building up a term
            if word[0].islower() or (current_term_words and word[0].isupper() and len(word) <= 3):
                # Check if this word starts a definition
                if current_term_words and is_def_start(word) and len(current_term_words) <= 5:
                    # This is the start of a definition
                    parsing_def = True
                    current_def_words = [word]
                else:
                    current_term_words.append(word)
            elif word[0].isupper() and not current_term_words:
                # Skip uppercase words at start (leftover from previous section)
                continue
            else:
                # Unexpected - might be start of definition
                if current_term_words and len(current_term_words) <= 5:
                    parsing_def = True
                    current_def_words = [word]
                else:
                    current_term_words = []
        else:
            # We're building up a definition
            # Check if a new term is starting (lowercase word after definition content)
            if (word[0].islower() and
                len(current_def_words) >= 3 and
                not is_def_start(word) and
                len(word) > 2):
                # Might be a new term starting
                # Look ahead to see if a definition follows
                lookahead_words = gwords[wi+1:wi+6] if wi+1 < len(gwords) else []
                new_term_candidate = [word]
                found_def_start = False

                for lw in lookahead_words:
                    if is_def_start(lw):
                        found_def_start = True
                        break
                    elif lw[0].islower():
                        new_term_candidate.append(lw)
                    else:
                        break

                if found_def_start and len(new_term_candidate) <= 4:
                    # Save current term and start new one
                    save_term()
                    current_term_words = [word]
                    current_def_words = []
                    parsing_def = False
                else:
                    current_def_words.append(word)
            else:
                current_def_words.append(word)

    # Save last term
    save_term()

    return terms


def extract_chapter_review(raw_text):
    """Extract the Chapter Review summary text."""
    match = re.search(r'Chapter Review\s+(.*?)(?:Interactive Link|Review Questions)', raw_text, re.DOTALL)
    if match:
        review = re.sub(r'\s+', ' ', match.group(1).strip())
        # Clean up any leftover figure references
        review = re.sub(r'\(\s*\)', '', review)
        return review
    return ""


def extract_main_content(raw_text):
    """Extract the main content paragraphs from a section."""
    # Remove UUIDs
    content = re.sub(r'[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}', '', raw_text)
    # Remove module IDs
    content = re.sub(r'\bm\d{5}\b', '', content)
    # Remove credit lines
    content = re.sub(r'\(credit[^)]*\)', '', content)
    # Clean empty figure references
    content = re.sub(r'\(\s*\)', '', content)
    # Remove LM × references
    content = re.sub(r'LM\s*×\s*\d+\.?', '', content)

    # Find where main content starts (after objectives) and ends (before Chapter Review)
    # Skip the title and objectives section

    # Find start of main content: after the UUID or after "able to:" objectives block
    obj_end = re.search(r'(?:[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12})', raw_text)
    if obj_end:
        start_pos = obj_end.end()
    else:
        start_pos = 0

    # Find end of main content
    review_pos = content.find('Chapter Review')
    interactive_pos = content.find('Interactive Link')

    end_pos = len(content)
    if review_pos > 0:
        end_pos = review_pos
    elif interactive_pos > 0:
        end_pos = interactive_pos

    main_text = content[start_pos:end_pos].strip()

    # Split into paragraphs (multiple spaces or clear paragraph breaks)
    # Since it's all one line, use double-space or sentence boundaries
    paragraphs = []

    # Split on natural paragraph boundaries
    # Look for places where a sentence ends and a new topic begins
    sentences = re.split(r'(?<=[.!?])\s+(?=[A-Z])', main_text)

    # Group sentences into paragraphs of ~3-5 sentences
    current_para = []
    for sent in sentences:
        sent = sent.strip()
        if not sent or len(sent) < 10:
            continue
        # Clean whitespace
        sent = re.sub(r'\s+', ' ', sent)
        current_para.append(sent)

        if len(current_para) >= 4:
            paragraphs.append(' '.join(current_para))
            current_para = []

    if current_para:
        paragraphs.append(' '.join(current_para))

    # Filter out very short paragraphs and ones that are just figure captions
    paragraphs = [p for p in paragraphs if len(p) > 50]

    return paragraphs


def parse_section(raw_text, chapter_num, section_idx):
    """Parse a single section."""
    title = extract_section_title(raw_text)
    section_id = f"ch{chapter_num:02d}_s{section_idx:02d}"

    objectives = extract_objectives(raw_text)
    chapter_review = extract_chapter_review(raw_text)
    review_questions = extract_review_questions(raw_text)
    glossary = extract_glossary_terms(raw_text)
    content = extract_main_content(raw_text)

    return {
        "id": section_id,
        "title": title,
        "objectives": objectives,
        "content": content,
        "chapterReview": chapter_review,
        "reviewQuestions": review_questions,
        "glossary": [{"term": g["term"], "definition": g["definition"]} for g in glossary]
    }


def parse_chapter_file(filepath, chapter_num, chapter_title):
    """Parse a chapter .txt file into structured data."""
    with open(filepath, 'r') as f:
        raw = f.read()

    sections_raw = re.split(r'\n## ', raw)
    sections_raw = [s.strip() for s in sections_raw if s.strip()]

    sections = []
    all_glossary = []
    all_questions = []

    for idx, section_text in enumerate(sections_raw):
        section = parse_section(section_text, chapter_num, idx)
        sections.append(section)

        for term in section["glossary"]:
            all_glossary.append({
                "term": term["term"],
                "definition": term["definition"],
                "chapterID": f"ch{chapter_num:02d}",
                "sectionID": section["id"]
            })

        for qi, q in enumerate(section["reviewQuestions"]):
            all_questions.append({
                "id": f"{section['id']}_q{qi:02d}",
                "question": q["question"],
                "choices": q["choices"],
                "correctAnswer": q["correctAnswer"],
                "explanation": q.get("explanation", ""),
                "chapterID": f"ch{chapter_num:02d}",
                "sectionID": section["id"]
            })

    chapter = {
        "id": f"ch{chapter_num:02d}",
        "number": chapter_num,
        "title": chapter_title,
        "weekMapping": WEEK_MAP.get(chapter_num, {"lectureWeek": 0, "labWeek": 0}),
        "sections": sections,
        "glossaryTerms": all_glossary,
        "totalQuestions": len(all_questions)
    }

    return chapter, all_glossary, all_questions


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

    for filename, (ch_num, ch_title) in CHAPTER_MAP.items():
        filepath = os.path.join(INPUT_DIR, f"{filename}.txt")
        if not os.path.exists(filepath):
            print(f"  WARNING: {filepath} not found")
            continue

        print(f"Parsing Ch {ch_num}: {ch_title}...")
        chapter, glossary, questions = parse_chapter_file(filepath, ch_num, ch_title)
        all_glossary.extend(glossary)
        all_questions.extend(questions)

        ch_path = os.path.join(OUTPUT_DIR, f"ch{ch_num:02d}.json")
        with open(ch_path, 'w') as f:
            json.dump(chapter, f, indent=2)

        # Report per section
        for sec in chapter["sections"]:
            print(f"  {sec['id']}: \"{sec['title']}\" - {len(sec['content'])} paragraphs, {len(sec['glossary'])} terms, {len(sec['reviewQuestions'])} questions, {len(sec['objectives'])} objectives")

    # Syllabus
    syllabus = generate_syllabus_json()
    with open(os.path.join(OUTPUT_DIR, "syllabus.json"), 'w') as f:
        json.dump(syllabus, f, indent=2)

    # Glossary (deduplicated)
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

    # Flashcards from glossary
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
    flashcard_decks = [{"chapterID": ch, "cards": cards} for ch, cards in sorted(decks.items())]
    with open(os.path.join(OUTPUT_DIR, "flashcards.json"), 'w') as f:
        json.dump(flashcard_decks, f, indent=2)

    # Questions
    with open(os.path.join(OUTPUT_DIR, "questions.json"), 'w') as f:
        json.dump(all_questions, f, indent=2)

    # Summary
    total_terms = sum(len(d["cards"]) for d in flashcard_decks)
    print(f"\n=== SUMMARY ===")
    print(f"Chapters: 11")
    print(f"Glossary terms: {len(unique_glossary)}")
    print(f"Flashcards: {total_terms}")
    print(f"Questions: {len(all_questions)}")


if __name__ == "__main__":
    main()
