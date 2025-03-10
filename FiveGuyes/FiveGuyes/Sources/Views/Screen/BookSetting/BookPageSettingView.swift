//
//  BookPageSettingView.swift
//  FiveGuyes
//
//  Created by Shim Hyeonhee on 11/4/24.
//

import SwiftUI
import UIKit

struct BookPageSettingView: View {
    private enum FieldFocus {
        case firstField
        case secondField
    }
    
    @Environment(NavigationCoordinator.self) var navigationCoordinator: NavigationCoordinator
    @Environment(BookSettingInputModel.self) var bookSettingInputModel: BookSettingInputModel
    
    @State private var startPage = 1
    @State private var targetEndPage = 0
    
    @FocusState private var focusedField: FieldFocus?
    
    @StateObject private var toastViewModel = ToastViewModel()
    
    var body: some View {
        let title = bookSettingInputModel.selectedBook?.title ?? "제목 없음"
        
        VStack(spacing: 0) {
            VStack(alignment: .leading) {
                Text("<\(title)>\(title.subjectParticle())")
                    .lineLimit(nil) // 제목이 길어지면 줄바꿈 허용
                
                HStack(spacing: 8) {
                    Text("총")
                    // 첫 번째 텍스트 필드
                    pageNumberTextField(
                        page: $startPage,
                        isFocused: $focusedField,
                        field: .firstField
                    )
                    
                    Text("쪽 부터")
                    
                    // 두 번째 텍스트 필드
                    pageNumberTextField(
                        page: $targetEndPage,
                        isFocused: $focusedField,
                        field: .secondField
                    )
                    
                    Text("쪽이에요")
                    
                    Spacer()
                }
            }
            .fontStyle(.title2, weight: .semibold)
            .padding(.top, 34)
            .padding(.horizontal, 20)
            
            Spacer()
            
            if focusedField != nil {
                VStack(spacing: 22) {
                    ToastView(viewModel: toastViewModel)
                    
                    Button(action: nextButtonTapped) {
                        Text("다음")
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color.Colors.green1)
                            .foregroundStyle(Color.Fills.white)
                    }
                }
                .ignoresSafeArea(.keyboard, edges: .bottom)
            }
            
        }
        .fontStyle(.title2, weight: .semibold)
        .foregroundStyle(Color.Labels.primaryBlack1)
        .background(Color.Fills.white)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Text("다음")
                    .fontStyle(.body)
                    .foregroundStyle(Color.Labels.tertiaryBlack3)
            }
        }
        .onAppear {
            initializePageSettings()
            trackPageSettingScreen()
        }
    }
    
    // 텍스트 필드 생성 메서드
    private func pageNumberTextField(
        page: Binding<Int>,
        isFocused: FocusState<FieldFocus?>.Binding,
        field: FieldFocus
    ) -> some View {
        // UITextField를 SwiftUI로 래핑
        CustomTextFieldRepresentable(
            text: Binding(
                get: { String(page.wrappedValue) },
                set: { newValue in
                    if let intValue = Int(newValue) {
                        page.wrappedValue = intValue
                    }
                }
            ),
            isFocused: isFocused.wrappedValue == field
        )
        .frame(height: 40)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background {
            RoundedRectangle(cornerRadius: 8)
                .foregroundStyle(Color.Fills.lightGreen)
        }
    }
    
    private func nextButtonTapped() {
        if startPage >= 1 && (targetEndPage > startPage) {
            bookSettingInputModel.targetEndPage = targetEndPage
            bookSettingInputModel.startPage = startPage
            
            focusedField = nil
            bookSettingInputModel.nextPage()
            return
        }
        
        let message = (startPage < 0)
        ? "시작 페이지를 0보다 큰 페이지로 입력해주세요!"
        : (startPage > targetEndPage)
            ? "앗! 시작 페이지는 마지막 페이지를 초과할 수 없어요!"
            : "시작 페이지는 마지막 페이지와 같을 수 없어요!"
        
        toastViewModel.showToast(message: message)
    }
    
    private func initializePageSettings() {
        targetEndPage = bookSettingInputModel.startPage
        targetEndPage = bookSettingInputModel.targetEndPage
        
        focusedField = .secondField
    }
    
    private func trackPageSettingScreen() {
        Tracking.Screen.pageSetting.setTracking()
    }
}

// CustomTextField를 사용
// SwiftUI 내에서 UIKit을 사용하려면 UIViewRepresentable을 사용
struct CustomTextFieldRepresentable: UIViewRepresentable {
    @Binding var text: String
    var isFocused: Bool
    var keyboardType: UIKeyboardType = .numberPad
    private let font = UIFont.systemFont(ofSize: FontStyle.title2.size, weight: .semibold)
    private let textColor = UIColor(Color.Colors.green2)
    private let backgroundColor = UIColor(Color.Fills.lightGreen)
    private let cornerRadius: CGFloat = 8
    private let height: CGFloat = 40
    
    func makeUIView(context: Context) -> CustomTextField {
        let textField = CustomTextField()
        textField.delegate = context.coordinator
        textField.keyboardType = keyboardType
        configureTextField(textField)
        
        return textField
    }
    
    func updateUIView(_ uiView: CustomTextField, context: Context) {
        uiView.text = text
        
        if isFocused {
            uiView.becomeFirstResponder()
        } else {
            uiView.resignFirstResponder()
        }
    }
    
    func configureTextField(_ textField: CustomTextField) {
        textField.font = font
        textField.textColor = textColor
        textField.backgroundColor = backgroundColor
        textField.layer.cornerRadius = cornerRadius
        textField.layer.masksToBounds = true
        textField.textAlignment = .center
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.heightAnchor.constraint(equalToConstant: height).isActive = true
        
        textField.setContentHuggingPriority(.required, for: .horizontal)
        textField.setContentCompressionResistancePriority(.required, for: .horizontal)
    }
    
    class Coordinator: NSObject, UITextFieldDelegate {
        var parent: CustomTextFieldRepresentable

        init(parent: CustomTextFieldRepresentable) {
            self.parent = parent
        }

        func textFieldDidChangeSelection(_ textField: UITextField) {
            parent.text = textField.text ?? ""
        }
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(parent: self)
    }
}
