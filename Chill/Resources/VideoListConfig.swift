import Foundation

enum VideoListConfig {
    nonisolated private static let defaultGraphQLViewName = "public.video_cards_view"
    nonisolated private static let configurationFileName = "SupabaseConfig"
    nonisolated private static let configurationSubdirectory = "Config"

    nonisolated static let placeholderImageName = "videoListPlaceholder"
    nonisolated static let cachePurgeDays: Int = 90

    nonisolated static func graphQLViewName(bundle: Bundle = .main) -> String {
        guard let value = Self.configurationDictionary(from: bundle)["VideoCardsViewName"] as? String,
              value.isEmpty == false else {
            return Self.defaultGraphQLViewName
        }
        return value
    }

    nonisolated private static func configurationDictionary(from bundle: Bundle) -> [String: Any] {
        if let url = bundle.url(forResource: configurationFileName, withExtension: "plist", subdirectory: configurationSubdirectory),
           let data = try? Data(contentsOf: url),
           let plist = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil),
           let dict = plist as? [String: Any] {
            return dict
        }

        if let url = bundle.url(forResource: configurationFileName, withExtension: "plist"),
           let data = try? Data(contentsOf: url),
           let plist = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil),
           let dict = plist as? [String: Any] {
            return dict
        }

        return [:]
    }
}
