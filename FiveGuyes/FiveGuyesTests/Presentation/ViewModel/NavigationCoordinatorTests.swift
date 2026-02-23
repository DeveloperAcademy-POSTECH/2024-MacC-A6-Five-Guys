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

    @Test("unfinishReading은 allowDuplicateRoute=true일 때 연속 push 허용")
    func push_unfinishReading_allowDuplicateRoute_allowsAppend() throws {
        let coordinator = try makeCoordinator()
        let firstBookID = try #require(UUID(uuidString: "11111111-1111-1111-1111-111111111111"))
        let secondBookID = try #require(UUID(uuidString: "22222222-2222-2222-2222-222222222222"))
        let firstBook = makeBook(id: firstBookID)
        let secondBook = makeBook(id: secondBookID)

        let first = coordinator.push(.unfinishReading(book: firstBook))
        let second = coordinator.push(
            .unfinishReading(book: secondBook),
            allowDuplicateRoute: true
        )

        #expect(first)
        #expect(second)
        #expect(coordinator.paths.count == 2)

        let firstPath = try #require(coordinator.paths.first)
        let secondPath = try #require(coordinator.paths.last)
        let firstPushedBookID = try #require(unfinishReadingBookID(from: firstPath))
        let secondPushedBookID = try #require(unfinishReadingBookID(from: secondPath))

        #expect(firstPushedBookID == firstBookID)
        #expect(secondPushedBookID == secondBookID)
        #expect(firstPushedBookID != secondPushedBookID)
        #expect(firstPath.routeInstanceID != secondPath.routeInstanceID)
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
            .completionReviewUpdate(book: firstBook)
        )
        let second = coordinator.push(
            .completionReviewUpdate(book: secondBook)
        )
        let poppedToRoot = coordinator.popToRoot()

        #expect(first)
        #expect(!second)
        #expect(poppedToRoot)
        #expect(coordinator.paths.isEmpty)
    }

    @Test("루트 기본 정책은 back 숨김 + swipe 비활성")
    func root_defaultBackPolicy() throws {
        let coordinator = try makeCoordinator()

        #expect(coordinator.paths.isEmpty)
        #expect(coordinator.effectiveTopPolicy == Screens.mainHome.defaultBackPolicy)
        #expect(!coordinator.isInteractivePopEnabled)
    }

    @Test("route 기본 정책 매핑이 의도와 일치")
    func route_defaultBackPolicies_matchExpected() {
        let standardExpectedPolicy = NavigationBackPolicy.standard

        #expect(Screens.notiSetting(book: nil).defaultBackPolicy == standardExpectedPolicy)
        #expect(Screens.dailyProgress(book: makeBook()).defaultBackPolicy == standardExpectedPolicy)
        #expect(Screens.totalCalendar(books: [makeBook()], today: .now).defaultBackPolicy == standardExpectedPolicy)
        #expect(Screens.readingDateEdit(book: makeBook()).defaultBackPolicy == standardExpectedPolicy)
        #expect(Screens.completionReviewUpdate(book: makeBook()).defaultBackPolicy == standardExpectedPolicy)
        #expect(Screens.unfinishReading(book: makeBook()).defaultBackPolicy == standardExpectedPolicy)
        #expect(Screens.bookSettingsManager.defaultBackPolicy == NavigationBackPolicy(
            backMode: .pop,
            swipePolicy: .disabled,
            showsBackButton: true
        ))

        #expect(Screens.completionCelebration(book: makeBook()).defaultBackPolicy == NavigationBackPolicy(
            backMode: .popToRoot,
            swipePolicy: .disabled,
            showsBackButton: true
        ))
    }

    @Test("bookSettingsManager의 스와이프는 항상 비활성")
    func bookSettingsManager_swipeIsAlwaysDisabled() throws {
        let coordinator = try makeCoordinator()
        _ = coordinator.push(.bookSettingsManager)
        #expect(!coordinator.isInteractivePopEnabled)
    }

    @Test("완독 축하 -> 소감 작성에서 back은 완독 축하로 1단계 복귀")
    func completionReviewBack_fromCelebration_returnsToCelebration() async throws {
        let coordinator = try makeCoordinator()
        let book = makeBook()
        _ = coordinator.push(.completionCelebration(book: book))
        _ = coordinator.push(.completionReviewUpdate(book: book))

        let handled = await coordinator.handleBackButtonTap()

        #expect(handled)
        #expect(coordinator.paths.count == 1)
        #expect(coordinator.paths.last?.routeKey == .completionCelebration)
    }

    @Test("일반 스택에서 소감 작성 back은 직전 화면으로 1단계 복귀")
    func completionReviewBack_fromRegularStack_returnsToPreviousRoute() async throws {
        let coordinator = try makeCoordinator()
        let book = makeBook()
        _ = coordinator.push(.notiSetting(book: nil))
        _ = coordinator.push(.completionReviewUpdate(book: book))

        let handled = await coordinator.handleBackButtonTap()

        #expect(handled)
        #expect(coordinator.paths.count == 1)
        #expect(coordinator.paths.last?.routeKey == .notiSetting)
    }

    @Test("back 버튼: beforeBackAction이 cancel이면 pop되지 않음")
    func backButton_beforeBackActionCancel_doesNotPop() async throws {
        let coordinator = try makeCoordinator()
        let owner = UUID()
        _ = coordinator.push(.unfinishReading(book: makeBook()))

        coordinator.setTopBackHooks(
            owner: owner,
            routeKey: .unfinishReading,
            beforeBackAction: { .cancel }
        )

        let handled = await coordinator.handleBackButtonTap()

        #expect(!handled)
        #expect(coordinator.paths.count == 1)
    }

    @Test("back 버튼: cancel 이후 재시도는 정상 처리")
    func backButton_cancelThenRetry_canProceed() async throws {
        let coordinator = try makeCoordinator()
        let owner = UUID()
        _ = coordinator.push(.unfinishReading(book: makeBook()))

        coordinator.setTopBackHooks(
            owner: owner,
            routeKey: .unfinishReading,
            beforeBackAction: { .cancel }
        )

        let firstHandled = await coordinator.handleBackButtonTap()

        #expect(!firstHandled)
        #expect(coordinator.paths.count == 1)

        coordinator.setTopBackHooks(
            owner: owner,
            routeKey: .unfinishReading,
            beforeBackAction: { .proceed }
        )

        let secondHandled = await coordinator.handleBackButtonTap()

        #expect(secondHandled)
        #expect(coordinator.paths.isEmpty)
    }

    @Test("back 버튼: proceed면 step-pop 후 후행 훅이 1회 실행")
    func backButton_proceed_runsStepPopExitHookOnce() async throws {
        let coordinator = try makeCoordinator()
        let owner = UUID()
        var stepExitCallCount = 0
        _ = coordinator.push(.unfinishReading(book: makeBook()))

        coordinator.setTopBackHooks(
            owner: owner,
            routeKey: .unfinishReading,
            beforeBackAction: { .proceed },
            onStepPopExitAction: {
                stepExitCallCount += 1
            }
        )

        let handled = await coordinator.handleBackButtonTap()

        #expect(handled)
        #expect(coordinator.paths.isEmpty)

        let didRun = await waitUntil {
            stepExitCallCount == 1
        }
        #expect(didRun)
    }

    @Test("스와이프 path 감소(step-pop)에서도 후행 훅이 1회 실행")
    func swipeStepPop_runsStepPopExitHookOnce() async throws {
        let coordinator = try makeCoordinator()
        let owner = UUID()
        var stepExitCallCount = 0
        _ = coordinator.push(.notiSetting(book: nil))
        _ = coordinator.push(.unfinishReading(book: makeBook()))

        coordinator.setTopBackHooks(
            owner: owner,
            routeKey: .unfinishReading,
            onStepPopExitAction: {
                stepExitCallCount += 1
            }
        )

        let oldPaths = coordinator.paths
        coordinator.paths = Array(oldPaths.dropLast())

        #expect(coordinator.paths.count == 1)

        let didRun = await waitUntil {
            stepExitCallCount == 1
        }
        #expect(didRun)
    }

    @Test("popToRoot에서는 후행 훅이 실행되지 않음")
    func popToRoot_doesNotRunStepPopExitHook() async throws {
        let coordinator = try makeCoordinator()
        let owner = UUID()
        var stepExitCallCount = 0
        _ = coordinator.push(.notiSetting(book: nil))
        _ = coordinator.push(.unfinishReading(book: makeBook()))

        coordinator.setTopBackHooks(
            owner: owner,
            routeKey: .unfinishReading,
            onStepPopExitAction: {
                stepExitCallCount += 1
            }
        )

        _ = coordinator.popToRoot()

        #expect(coordinator.paths.isEmpty)

        let didRun = await waitUntil(timeoutNanoseconds: 150_000_000) {
            stepExitCallCount > 0
        }
        #expect(!didRun)
    }

    @Test("backMode=popToRoot에서도 후행 훅이 실행되지 않음")
    func backButton_popToRoot_doesNotRunStepPopExitHook() async throws {
        let coordinator = try makeCoordinator()
        let owner = UUID()
        var stepExitCallCount = 0
        _ = coordinator.push(.completionCelebration(book: makeBook()))

        coordinator.setTopBackHooks(
            owner: owner,
            routeKey: .completionCelebration,
            beforeBackAction: { .proceed },
            onStepPopExitAction: {
                stepExitCallCount += 1
            }
        )

        let handled = await coordinator.handleBackButtonTap()

        #expect(handled)
        #expect(coordinator.paths.isEmpty)

        let didRun = await waitUntil(timeoutNanoseconds: 150_000_000) {
            stepExitCallCount > 0
        }
        #expect(!didRun)
    }

    @Test("back in-flight 중복 트리거를 차단")
    func backButton_inFlightPreventsDuplicateTrigger() async throws {
        let coordinator = try makeCoordinator()
        let owner = UUID()
        let startedSignal = AsyncSignal()
        let gate = AsyncGate()
        _ = coordinator.push(.unfinishReading(book: makeBook()))

        coordinator.setTopBackHooks(
            owner: owner,
            routeKey: .unfinishReading,
            beforeBackAction: {
                await startedSignal.signal()
                await gate.wait()
                return .proceed
            }
        )

        let firstTask = Task {
            await coordinator.handleBackButtonTap()
        }
        await startedSignal.wait()

        let second = await coordinator.handleBackButtonTap()

        #expect(!second)

        await gate.open()
        let first = await firstTask.value

        #expect(first)
        #expect(coordinator.paths.isEmpty)
    }

    @Test("routeInstanceID가 바뀌면 기존 hook은 실행되지 않음")
    func routeInstanceMismatch_skipsStaleHook() async throws {
        let coordinator = try makeCoordinator()
        let owner = UUID()
        var stepExitCallCount = 0
        let book = makeBook()
        _ = coordinator.push(.unfinishReading(book: book))

        coordinator.setTopBackHooks(
            owner: owner,
            routeKey: .unfinishReading,
            onStepPopExitAction: {
                stepExitCallCount += 1
            }
        )

        coordinator.paths = [
            NavigationPathItem(screen: .unfinishReading(book: book))
        ]

        let handled = await coordinator.handleBackButtonTap()

        #expect(handled)
        #expect(coordinator.paths.isEmpty)

        let didRun = await waitUntil(timeoutNanoseconds: 150_000_000) {
            stepExitCallCount > 0
        }
        #expect(!didRun)
    }

    @Test("동일 target에 owner가 교체되면 최신 owner hook만 실행")
    func replaceOwner_sameTarget_runsLatestOwnerHookOnly() async throws {
        let coordinator = try makeCoordinator()
        let previousOwner = UUID()
        let latestOwner = UUID()
        var previousOwnerCallCount = 0
        var latestOwnerCallCount = 0
        _ = coordinator.push(.unfinishReading(book: makeBook()))

        coordinator.setTopBackHooks(
            owner: previousOwner,
            routeKey: .unfinishReading,
            onStepPopExitAction: {
                previousOwnerCallCount += 1
            }
        )
        coordinator.setTopBackHooks(
            owner: latestOwner,
            routeKey: .unfinishReading,
            onStepPopExitAction: {
                latestOwnerCallCount += 1
            }
        )

        let handled = await coordinator.handleBackButtonTap()

        #expect(handled)
        #expect(coordinator.paths.isEmpty)

        let latestDidRun = await waitUntil {
            latestOwnerCallCount == 1
        }
        #expect(latestDidRun)

        let previousDidRun = await waitUntil(timeoutNanoseconds: 150_000_000) {
            previousOwnerCallCount > 0
        }
        #expect(!previousDidRun)
    }

    @Test("이전 owner clear는 최신 owner hook 등록을 지우지 않음")
    func clearPreviousOwner_keepsLatestOwnerHook() async throws {
        let coordinator = try makeCoordinator()
        let previousOwner = UUID()
        let latestOwner = UUID()
        var previousOwnerCallCount = 0
        var latestOwnerCallCount = 0
        _ = coordinator.push(.unfinishReading(book: makeBook()))

        coordinator.setTopBackHooks(
            owner: previousOwner,
            routeKey: .unfinishReading,
            onStepPopExitAction: {
                previousOwnerCallCount += 1
            }
        )
        coordinator.setTopBackHooks(
            owner: latestOwner,
            routeKey: .unfinishReading,
            onStepPopExitAction: {
                latestOwnerCallCount += 1
            }
        )

        coordinator.clearTopBackHooks(owner: previousOwner)

        let handled = await coordinator.handleBackButtonTap()

        #expect(handled)
        #expect(coordinator.paths.isEmpty)

        let latestDidRun = await waitUntil {
            latestOwnerCallCount == 1
        }
        #expect(latestDidRun)

        let previousDidRun = await waitUntil(timeoutNanoseconds: 150_000_000) {
            previousOwnerCallCount > 0
        }
        #expect(!previousDidRun)
    }

    private func makeCoordinator() throws -> NavigationCoordinator {
        let schema = Schema([UserBookSchemaV2.UserBookV2.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        let dependencies = AppDependencies(modelContainer: container)
        return NavigationCoordinator(appDependencies: dependencies)
    }

    private func unfinishReadingBookID(from pathItem: NavigationPathItem) -> UUID? {
        guard case .unfinishReading(book: let book) = pathItem.screen else {
            return nil
        }
        return book.id
    }
}
