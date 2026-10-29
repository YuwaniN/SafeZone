import Foundation

@MainActor
final class GuideViewModel: ObservableObject {
    @Published var searchText = ""
    @Published private(set) var content: GuideContent

    init(container: AppContainer) {
        content = container.guideRepository.loadGuide()
    }

    var topics: [GuideTopic] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !query.isEmpty else { return content.topics }
        return content.topics.filter { topic in
            topic.title.lowercased().contains(query) ||
            topic.subtitle.lowercased().contains(query) ||
            topic.sections.contains { section in
                section.title.lowercased().contains(query) ||
                section.body.lowercased().contains(query) ||
                section.steps.contains { $0.lowercased().contains(query) }
            }
        }
    }

    var contacts: [EmergencyContact] {
        content.contacts
    }

    var isSearching: Bool {
        !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
