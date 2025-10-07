import Foundation

enum VideoListConfig {
    nonisolated private static let defaultGraphQLViewName = "public.video_cards_view"

    nonisolated static let placeholderImageName = "videoListPlaceholder"
    nonisolated static let cachePurgeDays: Int = 90

    nonisolated static func graphQLViewName(bundle: Bundle = .main) -> String {
        return Self.defaultGraphQLViewName
    }
}
