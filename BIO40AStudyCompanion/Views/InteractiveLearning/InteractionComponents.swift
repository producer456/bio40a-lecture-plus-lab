import SwiftUI

// MARK: - Term Check Interaction
// Shows a definition, user picks which term it belongs to

struct TermCheckInteraction: View {
    let term: String
    let definition: String
    let options: [String]
    let answered: Bool
    let onAnswer: (Bool) -> Void
    let onContinue: () -> Void

    @State private var selected: String? = nil
    @State private var hasAnswered = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Which term matches this definition?")
                .font(.subheadline)
                .fontWeight(.semibold)

            Text(definition)
                .font(.callout)
                .italic()
                .padding()
                .background(.white.opacity(0.5), in: RoundedRectangle(cornerRadius: 10))

            ForEach(options, id: \.self) { option in
                Button {
                    guard !hasAnswered else { return }
                    selected = option
                    hasAnswered = true
                    onAnswer(option.lowercased() == term.lowercased())
                } label: {
                    HStack {
                        Text(option.capitalized)
                            .font(.subheadline)
                        Spacer()
                        if hasAnswered {
                            if option.lowercased() == term.lowercased() {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                            } else if option == selected {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.red)
                            }
                        }
                    }
                    .padding(12)
                    .background(optionBackground(option), in: RoundedRectangle(cornerRadius: 10))
                }
                .tint(.primary)
                .disabled(hasAnswered)
            }

            if hasAnswered {
                if selected?.lowercased() != term.lowercased() {
                    Text("The correct answer is **\(term)**")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }

                Button {
                    onContinue()
                } label: {
                    Text("Continue")
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity)
                        .padding(10)
                        .background(.blue, in: RoundedRectangle(cornerRadius: 10))
                        .foregroundStyle(.white)
                }
                .padding(.top, 4)
            }
        }
    }

    private func optionBackground(_ option: String) -> some ShapeStyle {
        if hasAnswered {
            if option.lowercased() == term.lowercased() {
                return AnyShapeStyle(.green.opacity(0.15))
            } else if option == selected {
                return AnyShapeStyle(.red.opacity(0.15))
            }
        } else if option == selected {
            return AnyShapeStyle(.blue.opacity(0.15))
        }
        return AnyShapeStyle(.gray.opacity(0.1))
    }
}

// MARK: - Quick Quiz Interaction
// Standard multiple choice from the section's review questions

struct QuickQuizInteraction: View {
    let question: QuizQuestion
    let answered: Bool
    let onAnswer: (Bool) -> Void
    let onContinue: () -> Void

    @State private var selected: Int? = nil
    @State private var hasAnswered = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(question.question)
                .font(.subheadline)
                .fontWeight(.semibold)

            ForEach(Array(question.choices.enumerated()), id: \.offset) { index, choice in
                Button {
                    guard !hasAnswered else { return }
                    selected = index
                    hasAnswered = true
                    onAnswer(index == question.correctAnswer)
                } label: {
                    HStack(alignment: .top) {
                        Text("\(["A", "B", "C", "D"].indices.contains(index) ? ["A", "B", "C", "D"][index] : "?")")
                            .fontWeight(.bold)
                            .frame(width: 20)
                        Text(choice)
                            .font(.subheadline)
                            .multilineTextAlignment(.leading)
                        Spacer()
                        if hasAnswered {
                            if index == question.correctAnswer {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                            } else if index == selected {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.red)
                            }
                        }
                    }
                    .padding(12)
                    .background(quizOptionBackground(index), in: RoundedRectangle(cornerRadius: 10))
                }
                .tint(.primary)
                .disabled(hasAnswered)
            }

            if hasAnswered {
                if let explanation = question.explanation, !explanation.isEmpty {
                    Text(explanation)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(8)
                        .background(.yellow.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
                }

                Button {
                    onContinue()
                } label: {
                    Text("Continue")
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity)
                        .padding(10)
                        .background(.blue, in: RoundedRectangle(cornerRadius: 10))
                        .foregroundStyle(.white)
                }
                .padding(.top, 4)
            }
        }
    }

    private func quizOptionBackground(_ index: Int) -> some ShapeStyle {
        if hasAnswered {
            if index == question.correctAnswer {
                return AnyShapeStyle(.green.opacity(0.15))
            } else if index == selected {
                return AnyShapeStyle(.red.opacity(0.15))
            }
        } else if index == selected {
            return AnyShapeStyle(.blue.opacity(0.15))
        }
        return AnyShapeStyle(.gray.opacity(0.1))
    }
}

// MARK: - Fill in the Blank Interaction
// Shows a sentence with a blank, user types the missing term

struct FillBlankInteraction: View {
    let term: String
    let sentence: String
    let answered: Bool
    let onAnswer: (Bool) -> Void
    let onContinue: () -> Void

    @State private var userInput = ""
    @State private var hasAnswered = false
    @State private var isCorrect = false
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Fill in the blank:")
                .font(.subheadline)
                .fontWeight(.semibold)

            Text(sentence)
                .font(.callout)
                .italic()
                .padding()
                .background(.white.opacity(0.5), in: RoundedRectangle(cornerRadius: 10))

            HStack {
                TextField("Type your answer...", text: $userInput)
                    .textFieldStyle(.roundedBorder)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .focused($isFocused)
                    .disabled(hasAnswered)
                    .submitLabel(.done)
                    .onSubmit { checkAnswer() }

                if !hasAnswered {
                    Button("Check") {
                        checkAnswer()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(userInput.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }

            if hasAnswered {
                HStack {
                    Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundStyle(isCorrect ? .green : .red)
                    Text(isCorrect ? "Correct!" : "The answer is: **\(term)**")
                        .font(.subheadline)
                }

                Button {
                    onContinue()
                } label: {
                    Text("Continue")
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity)
                        .padding(10)
                        .background(.blue, in: RoundedRectangle(cornerRadius: 10))
                        .foregroundStyle(.white)
                }
                .padding(.top, 4)
            }
        }
        .onAppear { isFocused = true }
    }

    private func checkAnswer() {
        let cleaned = userInput.trimmingCharacters(in: .whitespaces).lowercased()
        isCorrect = cleaned == term.lowercased()
        hasAnswered = true
        onAnswer(isCorrect)
    }
}

// MARK: - True or False Interaction
// Shows a statement, user decides if it's true or false

struct TrueOrFalseInteraction: View {
    let statement: String
    let isTrue: Bool
    let explanation: String
    let answered: Bool
    let onAnswer: (Bool) -> Void
    let onContinue: () -> Void

    @State private var selected: Bool? = nil
    @State private var hasAnswered = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("True or False?")
                .font(.subheadline)
                .fontWeight(.semibold)

            Text(statement)
                .font(.callout)
                .padding()
                .background(.white.opacity(0.5), in: RoundedRectangle(cornerRadius: 10))

            HStack(spacing: 12) {
                Button {
                    guard !hasAnswered else { return }
                    selected = true
                    hasAnswered = true
                    onAnswer(isTrue == true)
                } label: {
                    HStack {
                        Image(systemName: hasAnswered && isTrue ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(hasAnswered && isTrue ? .green : selected == true && !isTrue ? .red : .primary)
                        Text("True")
                            .fontWeight(.medium)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(12)
                    .background(tfBackground(forTrue: true), in: RoundedRectangle(cornerRadius: 10))
                }
                .tint(.primary)
                .disabled(hasAnswered)

                Button {
                    guard !hasAnswered else { return }
                    selected = false
                    hasAnswered = true
                    onAnswer(isTrue == false)
                } label: {
                    HStack {
                        Image(systemName: hasAnswered && !isTrue ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(hasAnswered && !isTrue ? .green : selected == false && isTrue ? .red : .primary)
                        Text("False")
                            .fontWeight(.medium)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(12)
                    .background(tfBackground(forTrue: false), in: RoundedRectangle(cornerRadius: 10))
                }
                .tint(.primary)
                .disabled(hasAnswered)
            }

            if hasAnswered {
                Text(explanation)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(8)
                    .background(.yellow.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))

                Button {
                    onContinue()
                } label: {
                    Text("Continue")
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity)
                        .padding(10)
                        .background(.blue, in: RoundedRectangle(cornerRadius: 10))
                        .foregroundStyle(.white)
                }
                .padding(.top, 4)
            }
        }
    }

    private func tfBackground(forTrue: Bool) -> some ShapeStyle {
        if hasAnswered {
            if forTrue == isTrue {
                return AnyShapeStyle(.green.opacity(0.15))
            } else if selected == forTrue {
                return AnyShapeStyle(.red.opacity(0.15))
            }
        }
        return AnyShapeStyle(.gray.opacity(0.1))
    }
}
