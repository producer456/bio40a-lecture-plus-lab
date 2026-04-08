import Foundation
import SwiftUI

// MARK: - Search Result

struct SearchResult: Identifiable {
    let id = UUID()
    let chapterID: String
    let sectionID: String?
    let title: String
    let snippet: String
    let matchType: MatchType

    enum MatchType {
        case content
        case glossary
        case question
    }
}

// MARK: - Content Service

@Observable
final class ContentService {
    private(set) var chapters: [Chapter] = []
    private(set) var syllabus: SyllabusSchedule?
    private(set) var glossaryTerms: [GlossaryTerm] = []
    private(set) var allQuestions: [QuizQuestion] = []
    private(set) var flashcardDecks: [FlashcardDeck] = []

    init() {
        loadAll()
    }

    // MARK: - Loading

    private func loadAll() {
        // Load chapters
        for i in 1...11 {
            let filename = String(format: "ch%02d", i)
            if let chapter: Chapter = loadJSON(filename: filename) {
                chapters.append(chapter)
            }
        }
        syllabus = loadJSON(filename: "syllabus")
        glossaryTerms = loadJSON(filename: "glossary") ?? []
        allQuestions = loadJSON(filename: "questions") ?? []
        flashcardDecks = loadJSON(filename: "flashcards") ?? []
    }

    private func loadJSON<T: Decodable>(filename: String) -> T? {
        // Try Content subdirectory first (folder reference), then root
        let url: URL? = Bundle.main.url(forResource: filename, withExtension: "json", subdirectory: "Content")
            ?? Bundle.main.url(forResource: filename, withExtension: "json")
        guard let url else {
            print("[ContentService] Missing: \(filename).json")
            return nil
        }
        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            print("[ContentService] Decode error \(filename): \(error)")
            return nil
        }
    }

    // MARK: - Accessors

    func chapter(id: String) -> Chapter? {
        chapters.first { $0.id == id }
    }

    func questionsForChapter(_ chapterID: String) -> [QuizQuestion] {
        allQuestions.filter { $0.chapterID == chapterID }
    }

    func glossaryForChapter(_ chapterID: String) -> [GlossaryTerm] {
        glossaryTerms.filter { $0.chapterID == chapterID }
    }

    // MARK: - Search

    func searchContent(query: String) -> [SearchResult] {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else { return [] }
        let lowered = query.lowercased()
        var results: [SearchResult] = []

        for chapter in chapters {
            for section in chapter.sections {
                let allContent = section.content.joined(separator: " ")
                if section.title.lowercased().contains(lowered)
                    || allContent.lowercased().contains(lowered) {
                    let snippet = makeSnippet(from: allContent, matching: lowered)
                    results.append(SearchResult(
                        chapterID: chapter.id,
                        sectionID: section.id,
                        title: "\(chapter.title) - \(section.title)",
                        snippet: snippet,
                        matchType: .content
                    ))
                }
            }
        }

        for term in glossaryTerms {
            if term.term.lowercased().contains(lowered)
                || term.definition.lowercased().contains(lowered) {
                results.append(SearchResult(
                    chapterID: term.chapterID ?? "",
                    sectionID: nil,
                    title: term.term,
                    snippet: term.definition,
                    matchType: .glossary
                ))
            }
        }

        for question in allQuestions {
            if question.question.lowercased().contains(lowered) {
                results.append(SearchResult(
                    chapterID: question.chapterID ?? "",
                    sectionID: nil,
                    title: "Quiz Question",
                    snippet: question.question,
                    matchType: .question
                ))
            }
        }

        return results
    }

    private func makeSnippet(from text: String, matching query: String, window: Int = 120) -> String {
        let lower = text.lowercased()
        guard let range = lower.range(of: query) else {
            return String(text.prefix(window))
        }
        let matchStart = lower.distance(from: lower.startIndex, to: range.lowerBound)
        let snippetStart = max(0, matchStart - window / 2)
        let startIndex = text.index(text.startIndex, offsetBy: snippetStart)
        let endIndex = text.index(startIndex, offsetBy: min(window, text.distance(from: startIndex, to: text.endIndex)))
        var snippet = String(text[startIndex..<endIndex])
        if snippetStart > 0 { snippet = "..." + snippet }
        if endIndex < text.endIndex { snippet += "..." }
        return snippet
    }
}
