import Foundation

/// 이름으로 API 키를 읽는다. 키가 없거나 비어 있으면 `missing`을 던진다.
public protocol APIKeyProviding: Sendable {
    func key(named name: String) throws(APIKeyError) -> String
}

public enum APIKeyError: Error, Sendable {
    case missing(name: String)
}

/// Info.plist(xcconfig에서 치환된 값)에서 API 키를 읽는다.
public struct BundleAPIKeyStore: APIKeyProviding {
    private let values: [String: String]

    public init(bundle: Bundle = .main) {
        self.values = bundle.infoDictionary?.compactMapValues { $0 as? String } ?? [:]
    }

    public init(values: [String: String]) {
        self.values = values
    }

    /// 빈 값과 `$(…)` 형태는 xcconfig 치환이 안 된 자리표시자이므로 "없음"으로 본다.
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
