import Foundation

public protocol APIKeyProviding: Sendable {
    func key(named name: String) throws(APIKeyError) -> String
}

public enum APIKeyError: Error, Sendable {
    case missing(name: String)
}

public struct BundleAPIKeyStore: APIKeyProviding {
    private let values: [String: String]

    public init(bundle: Bundle = .main) {
        self.values = bundle.infoDictionary?.reduce(into: [:]) { values, entry in
            if let value = entry.value as? String {
                values[entry.key] = value
            }
        } ?? [:]
    }

    public init(values: [String: String]) {
        self.values = values
    }

    public func key(named name: String) throws(APIKeyError) -> String {
        guard let rawValue = values[name] else {
            throw .missing(name: name)
        }

        let value = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty,
              !(value.hasPrefix("$(") && value.hasSuffix(")"))
        else {
            throw .missing(name: name)
        }

        return value
    }
}
