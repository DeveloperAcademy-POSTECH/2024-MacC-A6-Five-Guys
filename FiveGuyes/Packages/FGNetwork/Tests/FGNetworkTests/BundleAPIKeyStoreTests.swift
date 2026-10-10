import FGNetwork
import Testing

@Suite("BundleAPIKeyStore 테스트")
struct BundleAPIKeyStoreTests {
    @Test("문자열 키 값을 반환하며 앞뒤 공백을 제거")
    func key_validValue_returnsTrimmedValue() throws {
        let store = BundleAPIKeyStore(values: ["API_KEY": "  secret  "])

        #expect(try store.key(named: "API_KEY") == "secret")
    }

    @Test("키가 없으면 이름을 포함한 missing 오류")
    func key_missingValue_throwsMissing() {
        expectMissing(values: [:])
    }

    @Test("키가 빈 문자열이면 missing 오류")
    func key_emptyValue_throwsMissing() {
        expectMissing(values: ["API_KEY": ""])
    }

    @Test("키가 공백 문자열이면 missing 오류")
    func key_whitespaceValue_throwsMissing() {
        expectMissing(values: ["API_KEY": " \n "])
    }

    @Test("키가 미치환 자리표시자이면 missing 오류")
    func key_placeholderValue_throwsMissing() {
        expectMissing(values: ["API_KEY": "  $(API_KEY)  "])
    }

    private func expectMissing(values: [String: String]) {
        let store = BundleAPIKeyStore(values: values)

        do {
            _ = try store.key(named: "API_KEY")
            Issue.record("유효하지 않은 값에서 오류가 발생해야 합니다.")
        } catch {
            guard case let .missing(name) = error else {
                Issue.record("예상하지 못한 오류: \(error)")
                return
            }
            #expect(name == "API_KEY")
        }
    }
}
