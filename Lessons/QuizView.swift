import SwiftUI

struct QuizView: View {
    var lesson: Lesson
    var unit: Unit
    var unitIndex: Int

    @State private var generatingQuestions = false
    @State private var answers = [ProgressState.Answer]()
    @State private var showingAnswerForLastQuestion = false

    var body: some View {
        VStack {
            if let currentItem {
                VStack(spacing: 24) {
                    questionView(question: currentItem.question, answer: currentItem.answer)

                    nextButton
                }
                .padding(40)
                .id(currentItem.question)
                .transition(.slideLeftAndRight)
            } else if generatingQuestions {
                FunProgressView()
            } else {
                Text("No questions left")
                    .font(.funHeader)
                    .multilineTextAlignment(.center)
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.95, blendDuration: 0.1), value: currentItem?.question)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .task {
            generatingQuestions = true
            do {
                try await LessonStore.shared.ensureQuizGenerated(lessonId: lesson.id, unitIndex: unitIndex)
            } catch {
                print(error)
            }
            generatingQuestions = false
        }
        .onReceive(ProgressStore.shared.publisher.map { $0.quizResponses[unitID] ?? [] }) { answers in
            self.answers = answers
        }
    }

    private var unitID: ProgressState.UnitID {
        .init(lessonId: lesson.id, unitIndex: unitIndex)
    }

    private struct CurrentItem: Equatable {
        var question: Question
        var answer: ProgressState.Answer?
    }

    private var currentItem: CurrentItem? {
        let questions = (unit.quizQuestions ?? [])
        let answeredQuestions = Set(answers.map(\.question))

        if showingAnswerForLastQuestion, let lastAnswered = questions.last(where: { answeredQuestions.contains($0) }) {
            let lastAnswer = answers.first(where: { $0.question == lastAnswered })!
            return .init(question: lastAnswered, answer: lastAnswer)
        }
        // Show first unanswered:
        if let firstUnanswered = questions.first(where: { !answeredQuestions.contains($0) }) {
            return .init(question: firstUnanswered)
        }
        // No questions remaining
        return nil
    }

    @ViewBuilder private func questionView(question: Question, answer: ProgressState.Answer?) -> some View {
        if let mc = question.multipleChoice {
            MultipleChoiceQuestionView(question: question, multipleChoice: mc, existingAnswer: answer) { answer in
                showingAnswerForLastQuestion = true
                ProgressStore.shared.model.recordAnswer(answer, for: ProgressState.UnitID(lessonId: lesson.id, unitIndex: unitIndex))
            }
        }
    }

    @ViewBuilder private var nextButton: some View {
        FunButtonOnTouchdown(action: { showingAnswerForLastQuestion = false }, options: .init()) {
            Text("Continue")
        }
        .opacity(showingAnswerForLastQuestion ? 1 : 0)
        .accessibilityHidden(showingAnswerForLastQuestion ? false : true)
    }
}

extension AnyTransition {
    static let slideLeftAndRight = AnyTransition.opacity.combined(with: .asymmetric(insertion: .offset(x: 50), removal: .offset(x: -50)))
}

private struct MultipleChoiceQuestionView: View {
    var question: Question
    var multipleChoice: Question.MultipleChoice
    var existingAnswer: ProgressState.Answer?
    var onAnswered: (ProgressState.Answer) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text(multipleChoice.question)
                .multilineTextAlignment(.leading)
                .font(.funHeader)
                .lineSpacing(8)
            ForEach(multipleChoice.allChoices) { choice in
                let color = existingAnswer != nil ? (choice.isCorrect ? Color.green : Color.red) : Color.blue

                FunButtonOnTouchdown(action: {
                    onAnswered(.init(question: question, grade: choice.isCorrect ? 1 : 0, answer: choice.text))
                }, options: .init(multiline: true, color: color)) {
                    Text(choice.text)
                }
                .overlay {
                    if let existingAnswer, existingAnswer.answer == choice.text {
                        RoundedRectangle(cornerRadius: 10).strokeBorder(Color.white, lineWidth: 3)
                    }
                }
            }
        }
        .onChange(of: answeredCorrectly) { newValue in
            if let newValue {
                if newValue {
                    UINotificationFeedbackGenerator().notificationOccurred(newValue ? .success : .error)
                }
            }
        }
    }

    private var answeredCorrectly: Bool? {
        if let existingAnswer {
            return existingAnswer.grade > 0
        }
        return nil
    }
}

private struct QuestionChoice: Equatable, Identifiable {
    var id: String
    var text: String
    var isCorrect: Bool
}

private extension Question.MultipleChoice {
    var allChoices: [QuestionChoice] {
        var choices: [QuestionChoice] = incorrect.enumerated().map { QuestionChoice(id: "Incorrect:\($0.offset)", text: $0.element, isCorrect: false) }
        choices.append(QuestionChoice(id: "Correct", text: correct, isCorrect: true))
        var gen = SeededGenerator(string: question)
        choices.shuffle(using: &gen)
        return choices
    }
}

private extension View {
    @ViewBuilder func conditionalAlert(title: String, presented: Binding<Bool>) -> some View {
        self.alert(isPresented: presented) {
            Alert(title: Text(title))
        }
    }
}
