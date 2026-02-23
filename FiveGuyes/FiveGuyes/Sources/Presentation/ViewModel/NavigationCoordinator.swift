//
//  NavigationCoordinator.swift
//  FiveGuyes
//
//  Created by zaehorang on 11/6/24.
//

import SwiftUI

enum ScreenRouteKey: Hashable {
    case mainHome
    case notiSetting
    case bookSettingsManager
    case totalCalendar
    case dailyProgress
    case completionCelebration
    case completionReviewUpdate
    case readingDateEdit
    case unfinishReading
}

enum BackNavigationMode {
    /// 현재 화면만 한 단계 뒤로 이동합니다.
    case pop
    /// 네비게이션 스택을 모두 비우고 홈으로 이동합니다.
    case popToRoot
    /// 뒤로 이동을 막습니다.
    case none
}

enum BackSwipePolicy {
    /// iOS 기본 스와이프(back) 동작을 허용합니다.
    case systemDefault
    /// 스와이프 back을 막습니다.
    case disabled
}

enum BackDecision {
    /// back 동작을 계속 진행합니다.
    case proceed
    /// back 동작을 중단합니다.
    case cancel
}

struct NavigationBackPolicy: Equatable {
    let backMode: BackNavigationMode
    let swipePolicy: BackSwipePolicy
    let showsBackButton: Bool

    /// 대부분 화면에서 쓰는 기본 정책입니다.
    static let standard = NavigationBackPolicy(
        backMode: .pop,
        swipePolicy: .systemDefault,
        showsBackButton: true
    )
}

enum Screens: Hashable {
    case mainHome
    case notiSetting(book: FGUserBook?)
    case bookSettingsManager
    case totalCalendar(books: [FGUserBook], today: Date)
    case dailyProgress(book: FGUserBook)
    case completionCelebration(book: FGUserBook)
    case completionReviewUpdate(book: FGUserBook)
    case readingDateEdit(book: FGUserBook)
    case unfinishReading(book: FGUserBook)

    var routeKey: ScreenRouteKey {
        switch self {
        case .mainHome:
            return .mainHome
        case .notiSetting:
            return .notiSetting
        case .bookSettingsManager:
            return .bookSettingsManager
        case .totalCalendar:
            return .totalCalendar
        case .dailyProgress:
            return .dailyProgress
        case .completionCelebration:
            return .completionCelebration
        case .completionReviewUpdate:
            return .completionReviewUpdate
        case .readingDateEdit:
            return .readingDateEdit
        case .unfinishReading:
            return .unfinishReading
        }
    }

    private var backPolicyException: NavigationBackPolicy? {
        switch self {
        case .mainHome:
            return NavigationBackPolicy(
                backMode: .none,
                swipePolicy: .disabled,
                showsBackButton: false
            )
        case .completionCelebration:
            return NavigationBackPolicy(
                backMode: .popToRoot,
                swipePolicy: .disabled,
                showsBackButton: true
            )
        case .completionReviewUpdate:
            return nil
        case .unfinishReading:
            return NavigationBackPolicy(
                backMode: .pop,
                swipePolicy: .systemDefault,
                showsBackButton: true
            )
        case .notiSetting:
            return nil
        case .bookSettingsManager:
            return NavigationBackPolicy(
                backMode: .pop,
                swipePolicy: .disabled,
                showsBackButton: true
            )
        case .totalCalendar:
            return nil
        case .dailyProgress:
            return nil
        case .readingDateEdit:
            return nil
        }
    }

    var defaultBackPolicy: NavigationBackPolicy {
        // 예외 화면이 아니면 공통 기본 정책을 씁니다.
        backPolicyException ?? .standard
    }
}

struct NavigationPathItem: Hashable {
    /// 같은 화면 타입이라도 "이번에 push된 인스턴스"를 구분하기 위한 ID입니다.
    let routeInstanceID: UUID
    let screen: Screens

    init(screen: Screens, routeInstanceID: UUID = UUID()) {
        self.routeInstanceID = routeInstanceID
        self.screen = screen
    }

    var routeKey: ScreenRouteKey {
        // 화면 전체 데이터 대신 routeKey로 화면 종류를 비교합니다.
        screen.routeKey
    }

    var defaultBackPolicy: NavigationBackPolicy {
        // 실제 back 동작 정책은 화면 타입에서 계산한 값을 그대로 사용합니다.
        screen.defaultBackPolicy
    }
}

@Observable
@MainActor
final class NavigationCoordinator {
    /// hook 적용 대상을 화면 인스턴스(routeInstanceID) 단위로 식별합니다.
    private struct BackHookTarget: Hashable {
        let routeInstanceID: UUID
        let routeKey: ScreenRouteKey
    }

    /// 화면별 back 진입/이탈 훅을 보관하는 등록 단위입니다.
    private struct BackHookRegistration {
        let owner: UUID
        let beforeBackAction: (() async -> BackDecision)?
        let onStepPopExitAction: (() async -> Void)?
    }

    private let appDependencies: AppDependencies
    var paths: [NavigationPathItem] = [] {
        didSet {
            // 모든 path 변경(back 버튼/제스처/직접 pop)은 이 지점에서 정합성 후처리를 통합합니다.
            handlePathTransition(from: oldValue, to: paths)
        }
    }

    /// top route target 기준 훅 저장소입니다. (target -> registration)
    private var backHookRegistrationsByTarget: [BackHookTarget: BackHookRegistration] = [:]
    /// owner가 현재 어느 target에 바인딩됐는지 역인덱스로 관리합니다. (owner -> target)
    private var hookTargetByOwner: [UUID: BackHookTarget] = [:]
    private var inFlightBackTargets: Set<BackHookTarget> = []
    private var suppressedStepHookTargets: Set<BackHookTarget> = []

    init(appDependencies: AppDependencies) {
        self.appDependencies = appDependencies
    }
}

// MARK: - Policy Surface
extension NavigationCoordinator {
    /// 현재 사용자에게 "실제로 적용되는" 최상단 화면의 back 정책입니다.
    /// 화면이 없으면 루트(mainHome) 정책을 기본값으로 사용합니다.
    var effectiveTopPolicy: NavigationBackPolicy {
        paths.last?.defaultBackPolicy ?? Screens.mainHome.defaultBackPolicy
    }

    /// 현재 top 화면에서 edge-swipe back을 켤지 말지 계산합니다.
    /// 스택이 비어 있거나 정책이 disabled면 스와이프를 막습니다.
    var isInteractivePopEnabled: Bool {
        !paths.isEmpty && effectiveTopPolicy.swipePolicy == .systemDefault
    }
}

// MARK: - Back Hook Surface
extension NavigationCoordinator {
    /// hook은 top route의 instance(routeInstanceID + routeKey)에만 바인딩해 stale hook을 차단합니다.
    func setTopBackHooks(
        owner: UUID,
        routeKey: ScreenRouteKey,
        beforeBackAction: (() async -> BackDecision)? = nil,
        onStepPopExitAction: (() async -> Void)? = nil
    ) {
        // top 화면이 기대한 route가 아니면 오래된 hook 등록을 제거합니다.
        guard let topPath = paths.last,
              topPath.routeKey == routeKey else {
            clearTopBackHooks(owner: owner)
            return
        }

        // 둘 다 nil이면 "hook 없음" 상태이므로 기존 등록을 정리합니다.
        guard beforeBackAction != nil || onStepPopExitAction != nil else {
            clearTopBackHooks(owner: owner)
            return
        }

        let target = backHookTarget(for: topPath)

        if let previousTarget = hookTargetByOwner[owner],
           previousTarget != target {
            backHookRegistrationsByTarget.removeValue(forKey: previousTarget)
            hookTargetByOwner.removeValue(forKey: owner)
        }

        if let existingOwner = backHookRegistrationsByTarget[target]?.owner,
           existingOwner != owner {
            hookTargetByOwner.removeValue(forKey: existingOwner)
        }

        backHookRegistrationsByTarget[target] = BackHookRegistration(
            owner: owner,
            beforeBackAction: beforeBackAction,
            onStepPopExitAction: onStepPopExitAction
        )
        hookTargetByOwner[owner] = target
    }

    func clearTopBackHooks(owner: UUID) {
        // owner가 등록한 target이 없으면 지울 것이 없습니다.
        guard let target = hookTargetByOwner.removeValue(forKey: owner) else {
            return
        }

        // 같은 owner가 등록한 항목일 때만 안전하게 삭제합니다.
        guard backHookRegistrationsByTarget[target]?.owner == owner else {
            return
        }

        backHookRegistrationsByTarget.removeValue(forKey: target)
    }
}

// MARK: - Back Execution
extension NavigationCoordinator {
    @discardableResult
    /// 처리 순서는 중복 방지(in-flight) -> before decision -> 정책(backMode) 집행입니다.
    func handleBackButtonTap() async -> Bool {
        // top 화면이 없으면 뒤로 갈 곳이 없습니다.
        guard let topPath = paths.last else {
            return false
        }

        let target = backHookTarget(for: topPath)
        // 같은 화면에서 back 처리 중이면 중복 실행을 막습니다.
        guard !inFlightBackTargets.contains(target) else {
            return false
        }

        inFlightBackTargets.insert(target)

        let beforeDecision = await resolveBeforeBackDecision(for: target)
        guard beforeDecision == .proceed else {
            inFlightBackTargets.remove(target)
            return false
        }

        let backMode = effectiveTopPolicy.backMode
        let navigated: Bool

        switch backMode {
        case .pop:
            navigated = pop()
        case .popToRoot:
            navigated = popToRoot()
        case .none:
            navigated = false
        }

        // 화면이 "진짜로 빠졌을 때"만 in-flight를 전이 처리에서 해제합니다.
        if !navigated || backMode == .none {
            inFlightBackTargets.remove(target)
        }

        return navigated
    }

    @discardableResult
    func push(_ screen: Screens, allowDuplicateRoute: Bool = false) -> Bool {
        // 중복 push 방지: 같은 종류 화면을 연속으로 쌓지 않게 막습니다.
        if !allowDuplicateRoute,
           let topPath = paths.last,
           topPath.routeKey == screen.routeKey {
            return false
        }

        paths.append(NavigationPathItem(screen: screen))
        return true
    }

    @discardableResult
    func pop() -> Bool {
        // 비어 있으면 pop할 대상이 없습니다.
        guard !paths.isEmpty else {
            return false
        }

        paths.removeLast()
        return true
    }

    @discardableResult
    /// root 이동은 모든 step target을 suppress로 표시해 step-pop 후행 hook 오작동을 방지합니다.
    func popToRoot() -> Bool {
        guard !paths.isEmpty else {
            return false
        }

        suppressedStepHookTargets.formUnion(
            paths.map { backHookTarget(for: $0) }
        )

        paths.removeAll()
        return true
    }
}

// MARK: - View Routing
extension NavigationCoordinator {
    @ViewBuilder
    func navigate(to screen: Screens) -> some View {
        switch screen {
        case .mainHome:
            MainHomeView(
                viewModel: MainHomeViewModel(
                    readingLibraryUseCase: appDependencies.readingLibraryUseCase,
                    homeNotificationUseCase: appDependencies.homeNotificationUseCase
                )
            )
        case .notiSetting(book: let book):
            NotiSettingView(
                userBook: book,
                viewModel: NotiSettingViewModel(
                    notificationSettingUseCase: appDependencies.notificationSettingUseCase
                )
            )
        case .bookSettingsManager:
            BookSettingsManagerView(
                viewModel: BookSettingsManagerViewModel(
                    readingPlanUseCase: appDependencies.readingPlanUseCase
                ),
                bookSearchViewModel: BookSearchViewModel(
                    bookSearchUseCase: appDependencies.bookSearchUseCase
                ),
                finishGoalViewModel: FinishGoalViewModel(
                    bookRegistrationUseCase: appDependencies.bookRegistrationUseCase,
                    readingGoalMetricsUseCase: appDependencies.readingGoalMetricsUseCase
                ),
                readingDateSettingViewModel: ReadingDateSettingViewModel(
                    readingGoalMetricsUseCase: appDependencies.readingGoalMetricsUseCase
                )
            )
        case .totalCalendar(books: let books, today: let today):
            MultiBookProgressView(
                currentReadingBooks: books,
                today: today
            )
        case .dailyProgress(book: let book):
            DailyProgressView(
                userBook: book,
                viewModel: DailyProgressViewModel(
                    dailyReadingUseCase: appDependencies.dailyReadingUseCase,
                    bookCompletionUseCase: appDependencies.bookCompletionUseCase
                )
            )
        case .completionCelebration(book: let book):
            CompletionCelebrationView(
                userBook: book,
                viewModel: CompletionCelebrationViewModel(
                    bookCompletionUseCase: appDependencies.bookCompletionUseCase
                )
            )
        case .completionReviewUpdate(book: let book):
            CompletionReviewView(
                isUpdateMode: true,
                userBook: book,
                viewModel: CompletionReviewViewModel(
                    bookCompletionUseCase: appDependencies.bookCompletionUseCase
                )
            )
        case .readingDateEdit(book: let book):
            ReadingDateEditView(
                userBook: book,
                viewModel: ReadingDateEditViewModel(
                    readingPlanUseCase: appDependencies.readingPlanUseCase
                ),
                readingDateSettingViewModel: ReadingDateSettingViewModel(
                    readingGoalMetricsUseCase: appDependencies.readingGoalMetricsUseCase
                )
            )
        case .unfinishReading(book: let book):
            UnfinishReadingView(
                userBook: book,
                viewModel: UnfinishReadingViewModel(
                    bookCompletionUseCase: appDependencies.bookCompletionUseCase
                )
            )
        }
    }
}

// MARK: - Path Transition Internals
private extension NavigationCoordinator {
    private func resolveBeforeBackDecision(for target: BackHookTarget) async -> BackDecision {
        guard let beforeBackAction = backHookRegistration(for: target)?.beforeBackAction else {
            return .proceed
        }

        return await beforeBackAction()
    }

    /// path 전이 후처리는 1) step-pop 판별 2) in-flight/suppress 해제 3) stale 상태 정리 4) step hook 실행 순서로 처리합니다.
    private func handlePathTransition(from oldPaths: [NavigationPathItem], to newPaths: [NavigationPathItem]) {
        let stepPoppedPath = stepPoppedPathItem(from: oldPaths, to: newPaths)
        let stepTarget = stepPoppedPath.map { backHookTarget(for: $0) }
        let stepExitHook = stepTarget.flatMap { backHookRegistration(for: $0)?.onStepPopExitAction }
        let isSuppressedStepHook = stepTarget.map { suppressedStepHookTargets.contains($0) } ?? false

        if let stepTarget {
            inFlightBackTargets.remove(stepTarget)
            suppressedStepHookTargets.remove(stepTarget)
        }

        let activeTargets = Set(newPaths.map { backHookTarget(for: $0) })
        backHookRegistrationsByTarget = backHookRegistrationsByTarget.filter {
            activeTargets.contains($0.key)
        }
        hookTargetByOwner = backHookRegistrationsByTarget.reduce(into: [:]) { result, entry in
            result[entry.value.owner] = entry.key
        }
        inFlightBackTargets = inFlightBackTargets.intersection(activeTargets)
        suppressedStepHookTargets = suppressedStepHookTargets.intersection(activeTargets)

        guard let stepExitHook, !isSuppressedStepHook else {
            return
        }

        Task {
            await stepExitHook()
        }
    }

    private func stepPoppedPathItem(
        from oldPaths: [NavigationPathItem],
        to newPaths: [NavigationPathItem]
    ) -> NavigationPathItem? {
        // 정확히 1개만 제거되고 prefix가 동일할 때만 "step-pop"으로 간주합니다.
        guard oldPaths.count == newPaths.count + 1 else {
            return nil
        }

        guard Array(oldPaths.dropLast()) == newPaths else {
            return nil
        }

        return oldPaths.last
    }

    private func backHookTarget(for pathItem: NavigationPathItem) -> BackHookTarget {
        BackHookTarget(
            routeInstanceID: pathItem.routeInstanceID,
            routeKey: pathItem.routeKey
        )
    }

    private func backHookRegistration(for target: BackHookTarget) -> BackHookRegistration? {
        backHookRegistrationsByTarget[target]
    }
}
