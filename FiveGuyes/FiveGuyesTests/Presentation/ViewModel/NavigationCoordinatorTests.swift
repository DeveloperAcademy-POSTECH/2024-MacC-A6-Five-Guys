//
//  NavigationCoordinatorTests.swift
//  FiveGuyesTests
//
//  Created by Codex on 2/18/26.
//

@testable import FiveGuyes
import Foundation
import SwiftData
import Testing

@Suite("NavigationCoordinator 테스트")
@MainActor
struct NavigationCoordinatorTests {
    @Test("동일 route 연속 push는 기본 정책에서 차단")
    func push_sameRoute_ignoredByDefault() throws {
        let coordinator = try makeCoordinator()

        let first = coordinator.push(.notiSetting(book: nil))
        let second = coordinator.push(.notiSetting(book: makeBook()))

        #expect(first)
        #expect(!second)
        #expect(coordinator.paths.count == 1)
    }

    @Test("서로 다른 route push는 허용")
    func push_differentRoutes_allowed() throws {
        let coordinator = try makeCoordinator()
        let book = makeBook()

        let first = coordinator.push(.notiSetting(book: nil))
        let second = coordinator.push(.dailyProgress(book: book))

        #expect(first)
        #expect(second)
        #expect(coordinator.paths.count == 2)
    }

    @Test("allowDuplicateRoute=true면 동일 route도 push 가능")
    func push_sameRoute_allowDuplicateRoute_allowsAppend() throws {
        let coordinator = try makeCoordinator()

        let first = coordinator.push(.notiSetting(book: nil))
        let second = coordinator.push(
            .notiSetting(book: nil),
            allowDuplicateRoute: true
        )

        #expect(first)
        #expect(second)
        #expect(coordinator.paths.count == 2)
    }

    @Test("빈 경로에서 pop은 false를 반환")
    func pop_emptyPath_returnsFalse() throws {
        let coordinator = try makeCoordinator()

        let popped = coordinator.pop()

        #expect(!popped)
        #expect(coordinator.paths.isEmpty)
    }

    @Test("경로가 있을 때 pop은 마지막 화면을 제거")
    func pop_nonEmptyPath_removesLast() throws {
        let coordinator = try makeCoordinator()
        let book = makeBook()
        _ = coordinator.push(.notiSetting(book: nil))
        _ = coordinator.push(.dailyProgress(book: book))

        let popped = coordinator.pop()

        #expect(popped)
        #expect(coordinator.paths.count == 1)
        #expect(coordinator.paths.first?.routeKey == .notiSetting)
    }

    @Test("빈 경로에서 popToRoot는 false를 반환")
    func popToRoot_emptyPath_returnsFalse() throws {
        let coordinator = try makeCoordinator()

        let poppedToRoot = coordinator.popToRoot()

        #expect(!poppedToRoot)
        #expect(coordinator.paths.isEmpty)
    }

    @Test("completionReview route 중복 push 차단과 root 복귀를 보장")
    func completionReviewRoute_guardAndPopToRoot() throws {
        let coordinator = try makeCoordinator()
        let firstBook = makeBook()
        let secondBook = makeBook()

        let first = coordinator.push(
            .completionReviewUpdate(book: firstBook, popToRootOnBack: true)
        )
        let second = coordinator.push(
            .completionReviewUpdate(book: secondBook, popToRootOnBack: false)
        )
        let poppedToRoot = coordinator.popToRoot()

        #expect(first)
        #expect(!second)
        #expect(poppedToRoot)
        #expect(coordinator.paths.isEmpty)
    }

    private func makeCoordinator() throws -> NavigationCoordinator {
        let schema = Schema([UserBookSchemaV2.UserBookV2.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        let dependencies = AppDependencies(modelContainer: container)
        return NavigationCoordinator(appDependencies: dependencies)
    }
}
