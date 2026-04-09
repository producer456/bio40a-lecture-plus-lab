import Foundation
import SwiftUI

/// Evidence-based learning techniques from cognitive psychology research.
/// Each technique includes the science, A&P application, and a practical study mode.
struct LearningTechnique: Identifiable {
    let id: String
    let name: String
    let icon: String
    let color: Color
    let tagline: String
    let explanation: String
    let keyResearch: String
    let apApplication: String
    let howToUse: String
    let studyModeType: StudyModeType

    enum StudyModeType {
        case spacedRepetition
        case activeRecall
        case interleaving
        case elaboration
        case dualCoding
        case concreteExamples
        case chunking
        case feynman
        case metacognition
        case desirableDifficulty
        case bedtimeReview
        case none
    }
}

extension LearningTechnique {
    static let all: [LearningTechnique] = [
        LearningTechnique(
            id: "spaced_repetition",
            name: "Spaced Repetition",
            icon: "clock.arrow.2.circlepath",
            color: .blue,
            tagline: "Review at the right time, not all at once",
            explanation: "Reviewing material at gradually increasing intervals rather than cramming produces dramatically better long-term retention. Each retrieval event resets the forgetting curve, making the memory more durable. The optimal moment to review is just before you would have forgotten.",
            keyResearch: "Cepeda et al. (2006) analyzed 254 studies confirming distributed practice produces significantly better retention than massed practice. Students who space their study retain 2-3x more material after one month.",
            apApplication: "A&P has a massive volume of terms — bone names, muscle origins/insertions, physiological cascades. Learn the brachial plexus in week 3 and have it automatically resurface in weeks 4, 5, 7, and 11 so it sticks for your final.",
            howToUse: "Use the Flashcards feature — it uses the SM-2 spaced repetition algorithm to schedule reviews at optimal intervals. Cards you struggle with come back sooner; easy cards are pushed further out.",
            studyModeType: .spacedRepetition
        ),
        LearningTechnique(
            id: "active_recall",
            name: "Active Recall",
            icon: "brain.head.profile.fill",
            color: .green,
            tagline: "Don't re-read — test yourself",
            explanation: "Retrieving information from memory strengthens the memory trace far more than passively re-reading. The act of generating an answer — even if you struggle or get it wrong — is where real learning happens. Testing isn't just measuring learning; testing IS learning.",
            keyResearch: "Roediger & Karpicke (2006) showed students who practiced retrieval retained 80% after one week vs. 36% for re-readers. Even unsuccessful retrieval attempts followed by feedback enhance learning (Kornell et al., 2009).",
            apApplication: "Instead of re-reading the cardiac cycle chapter, close the book and diagram the sequence from memory: atrial systole → AV valves open → ventricular filling → ventricular systole → semilunar valves open. The struggle to reconstruct is where learning happens.",
            howToUse: "Use Practice Quizzes and the Interactive Learning mode. After reading a section, immediately try to answer questions about it before looking at the answers.",
            studyModeType: .activeRecall
        ),
        LearningTechnique(
            id: "interleaving",
            name: "Interleaving",
            icon: "arrow.triangle.swap",
            color: .purple,
            tagline: "Mix it up — don't study one topic at a time",
            explanation: "Mixing different topics during a study session produces superior long-term retention compared to studying one topic exhaustively before moving on. While blocking feels more fluent, interleaving forces you to discriminate between concepts — a skill you need on exams.",
            keyResearch: "Rohrer & Taylor (2007) showed interleaved practice led to 43% higher test scores than blocked practice. Students felt they learned less with interleaving, but actually learned more.",
            apApplication: "Rather than studying all upper extremity muscles in one block, mix in nerve innervation, blood supply, and skeletal questions. This mirrors clinical thinking — a patient presents and you must integrate across systems.",
            howToUse: "When taking Practice Quizzes, select multiple chapters and enable 'Focus on Weak Spots' to get a mixed review across topics. The app will interleave questions from different systems.",
            studyModeType: .interleaving
        ),
        LearningTechnique(
            id: "elaboration",
            name: "Elaborative Interrogation",
            icon: "questionmark.bubble.fill",
            color: .orange,
            tagline: "Always ask 'why?' and 'how?'",
            explanation: "Generating explanations by asking 'why' and 'how' questions creates richer, more connected memory traces. Rather than memorizing that the left ventricle has thicker walls, ask WHY — and connect it to systemic vs. pulmonary circulation pressures.",
            keyResearch: "Pressley et al. (1987) showed elaborative interrogation doubled retention compared to reading alone. The effect is strongest when learners have enough background to generate plausible explanations (McDaniel & Donnelly, 1996).",
            apApplication: "A&P is full of 'why' questions: Why are red blood cells biconcave? (Maximizes surface area for gas exchange.) Why does the SA node set heart rate? (Fastest intrinsic depolarization rate.) These causal connections make facts meaningful.",
            howToUse: "As you read through lessons, pause after each concept and ask yourself 'Why is this the case?' Try to explain the connection between structure and function before moving on.",
            studyModeType: .elaboration
        ),
        LearningTechnique(
            id: "dual_coding",
            name: "Dual Coding",
            icon: "text.below.photo.fill",
            color: .teal,
            tagline: "See it AND say it — two pathways to memory",
            explanation: "Information encoded in both verbal and visual formats creates two independent memory traces, making retrieval more likely. When you can both describe a concept in words AND visualize it as an image, you have two pathways to access that knowledge.",
            keyResearch: "Mayer (2009) showed people learn better from words and pictures together than from words alone. Paivio (1971) demonstrated the two codes are additive — each provides an independent retrieval route.",
            apApplication: "Anatomy is inherently visual-spatial. A student who can both describe the brachial plexus verbally ('roots, trunks, divisions, cords, branches') AND visualize its branching pattern has a major advantage over one who only reads the text.",
            howToUse: "When studying, try to draw or sketch what you're learning — even rough diagrams help. Upload photos of your drawings to Study Materials to review later.",
            studyModeType: .dualCoding
        ),
        LearningTechnique(
            id: "chunking",
            name: "Chunking",
            icon: "square.grid.3x3.fill",
            color: .indigo,
            tagline: "Break it into bite-sized pieces",
            explanation: "Working memory holds only about 4 items at once. Chunking groups individual items into meaningful units, expanding your effective capacity. An expert doesn't remember 12 cranial nerves as 12 separate items — they chunk them by function (sensory, motor, both).",
            keyResearch: "Miller (1956) introduced the concept. Chase & Simon (1973) showed chess masters chunk positions into familiar patterns. In medical education, experts organize anatomy into functional and regional schemas rather than isolated facts.",
            apApplication: "The 206 bones are overwhelming as a list but manageable when chunked: axial skeleton (80 bones: skull, vertebral column, thoracic cage) vs. appendicular skeleton (126 bones: upper limb, lower limb, girdles). Master one chunk before adding the next.",
            howToUse: "The Interactive Learning mode presents content in small chunks with checkpoints between them. Use this to master material in digestible pieces rather than reading entire chapters at once.",
            studyModeType: .chunking
        ),
        LearningTechnique(
            id: "feynman",
            name: "The Feynman Technique",
            icon: "text.bubble.fill",
            color: .red,
            tagline: "If you can't explain it simply, you don't understand it",
            explanation: "Explaining a concept in plain, simple language as if teaching someone with no background forces deep processing and reveals gaps in your understanding. When you stumble trying to explain, you've found exactly what you need to study.",
            keyResearch: "The 'protégé effect' (Chase et al., 2009) shows preparing to teach improves learning. Chi et al. (1989) showed self-explanation is one of the most powerful learning activities. Fiorella & Mayer (2013) confirmed that merely expecting to teach enhances learning.",
            apApplication: "Can you explain the action potential in words a high schooler would understand? 'The nerve cell is like a room with a locked door. Sodium ions are crowded outside. When a signal arrives, the door opens, sodium rushes in...' If you can't simplify it, you need to review.",
            howToUse: "After studying a topic, try writing or speaking an explanation in your own words. Use the notes field in your Assignment Log to capture your explanations.",
            studyModeType: .feynman
        ),
        LearningTechnique(
            id: "metacognition",
            name: "Metacognition",
            icon: "brain.fill",
            color: .pink,
            tagline: "Know what you know — and what you don't",
            explanation: "Metacognition is thinking about your own thinking — accurately monitoring what you know vs. don't know. Students often confuse familiarity ('I've seen this before') with actual knowledge ('I can explain and apply this'). This leads to studying what's already known while neglecting weak areas.",
            keyResearch: "Dunning & Kruger (1999) showed low performers dramatically overestimate their competence. Koriat & Bjork (2005) demonstrated that students confuse reading fluency with actual learning — re-reading feels productive but often isn't.",
            apApplication: "A&P students commonly re-read the endocrine chapter, the material feels familiar, and they conclude they 'know it.' But on the exam, they can't list anterior pituitary hormones. The Weak Spots feature helps calibrate your actual knowledge.",
            howToUse: "Check your Weak Spots dashboard regularly. Compare what you think you know with your actual quiz scores. Focus study time on topics where your confidence exceeds your performance.",
            studyModeType: .metacognition
        ),
        LearningTechnique(
            id: "desirable_difficulty",
            name: "Desirable Difficulties",
            icon: "figure.climbing",
            color: .brown,
            tagline: "Struggle is part of learning — embrace it",
            explanation: "Learning conditions that feel harder during study often produce better long-term retention. Students and instructors prefer 'easy' conditions (massed practice, immediate feedback) that feel productive but produce inferior results. The difficulty must be achievable — hard enough to require effort but not so hard as to cause frustration.",
            keyResearch: "Bjork & Bjork (2011) synthesized decades of research showing that conditions maximizing performance during learning often do NOT maximize long-term retention. The struggle is where the strengthening happens.",
            apApplication: "Generating muscle names from memory (hard) produces better retention than matching from a labeled diagram (easy). Predicting a hormone's effect before learning it (even guessing wrong) is more effective than reading the answer directly.",
            howToUse: "Use Fill in the Blank and free recall over multiple choice when possible. Don't peek at answers too quickly — give yourself 30-60 seconds to struggle before checking.",
            studyModeType: .desirableDifficulty
        ),
        LearningTechnique(
            id: "sleep",
            name: "Sleep & Learning",
            icon: "moon.zzz.fill",
            color: .indigo,
            tagline: "Your brain files memories while you sleep",
            explanation: "Sleep is not passive rest — it's active memory consolidation. During sleep, your hippocampus replays recently encoded memories and transfers them to long-term storage. A 30-minute evening review followed by sleep and a morning recall session is far more effective than a 3-hour cram session.",
            keyResearch: "Walker & Stickgold (2006) showed sleep after learning improves retention by 20-40%. Born & Wilhelm (2012) showed sleeping between study sessions is more effective than the same spacing without sleep. Even a 60-90 minute nap helps.",
            apApplication: "With A&P's massive content volume, your brain literally needs sleep to file it all away. Review today's lecture material briefly before bed, sleep on it, then do a quick recall session in the morning. You'll retain dramatically more.",
            howToUse: "Try a brief flashcard review session before bed. In the morning, test yourself on the same material. The app's spaced repetition will naturally support this pattern.",
            studyModeType: .bedtimeReview
        ),
    ]
}
