import Foundation

struct AuthConfiguration {
    enum ConfigurationError: Error, LocalizedError, Equatable {
        case missingSupabaseURL
        case invalidSupabaseURL
        case missingSupabaseAnonKey
        case missingConfigurationFile
        case invalidConfigurationFormat

        var errorDescription: String? {
            switch self {
            case .missingSupabaseURL:
                return "Supabase URL is not configured."
            case .invalidSupabaseURL:
                return "Supabase URL is invalid."
            case .missingSupabaseAnonKey:
                return "Supabase anonymous key is not configured."
            case .missingConfigurationFile:
                return "Supabase configuration file is missing."
            case .invalidConfigurationFormat:
                return "Supabase configuration file is malformed."
            }
        }
    }

    let supabaseURL: URL
    let supabaseAnonKey: String

    init(supabaseURL: URL, supabaseAnonKey: String) {
        self.supabaseURL = supabaseURL
        self.supabaseAnonKey = supabaseAnonKey
    }

    static func load(
        bundle: Bundle = .main,
        processInfo: ProcessInfo = .processInfo
    ) throws -> AuthConfiguration {
        if let configuration = try configurationFromEnvironment(processInfo.environment) {
            return configuration
        }

        guard let resourceURL = locateConfiguration(in: bundle) else {
            throw ConfigurationError.missingConfigurationFile
        }

        let data = try Data(contentsOf: resourceURL)
        let propertyList = try PropertyListSerialization.propertyList(from: data, options: [], format: nil)

        guard let dictionary = propertyList as? [String: Any] else {
            throw ConfigurationError.invalidConfigurationFormat
        }

        guard let urlString = dictionary["SupabaseURL"] as? String, let url = validatedURL(from: urlString) else {
            throw ConfigurationError.invalidSupabaseURL
        }

        guard let anonKey = dictionary["SupabaseAnonKey"] as? String, anonKey.isEmpty == false else {
            throw ConfigurationError.missingSupabaseAnonKey
        }

        return AuthConfiguration(supabaseURL: url, supabaseAnonKey: anonKey)
    }

    private static func configurationFromEnvironment(_ environment: [String: String]) throws -> AuthConfiguration? {
        let urlValue = environment["SUPABASE_URL"]
        let keyValue = environment["SUPABASE_ANON_KEY"]

        guard urlValue != nil || keyValue != nil else {
            return nil
        }

        guard let urlString = urlValue, let url = validatedURL(from: urlString) else {
            throw ConfigurationError.invalidSupabaseURL
        }

        guard let anonKey = keyValue, anonKey.isEmpty == false else {
            throw ConfigurationError.missingSupabaseAnonKey
        }

        return AuthConfiguration(supabaseURL: url, supabaseAnonKey: anonKey)
    }

    private static func locateConfiguration(in bundle: Bundle) -> URL? {
        if let url = bundle.url(forResource: "SupabaseConfig", withExtension: "plist", subdirectory: "Config") {
            return url
        }
        return bundle.url(forResource: "SupabaseConfig", withExtension: "plist")
    }

    private static func validatedURL(from value: String) -> URL? {
        guard let url = URL(string: value), let scheme = url.scheme?.lowercased(), ["http", "https"].contains(scheme) else {
            return nil
        }
        return url
    }
}
