//
//  ImageUploadingView.swift
//  FiveGuyes
//
//  Created by Shim Hyeonhee on 10/7/24.
//

import SwiftUI
import PhotosUI

// Model: 선택된 이미지를 관리하는 구조체
struct PhotoModel {
    var selectedImages: [UIImage] = []
}

// ViewModel: 비즈니스 로직과 데이터 처리를 담당
class PhotoPickerViewModel: ObservableObject {
    @Published var photoModel = PhotoModel()

    // PHPickerViewController를 보여주는 함수
    func presentPhotoPicker() -> PHPickerViewController {
        var configuration = PHPickerConfiguration()
        configuration.filter = .images
        configuration.selectionLimit = 0
        configuration.selection = .ordered

        //앞에서 피커의 설정이 담긴 PickerConfiguration 객체 셋팅 완료, 이제 이를 활용하여 PHImagePickerViewController 객체를 생성
        let picker = PHPickerViewController(configuration: configuration)
        
        //마지막으로, 위에서 만들어놓은 PHPickerViewController의 객체에 Delegate를 할당한후 반환
        picker.delegate = self
        return picker
    }
}

// 이미지 선택을 한 후 확인을 눌렀을 때 처리할 수 있는 Delegate를 피커를 활용하고 있는 ViewController에 상속
// delegate프로토콜 채택을 위한 PhotoPickerViewModel 확장 (기능분리)
extension PhotoPickerViewModel: PHPickerViewControllerDelegate {
    
    // 이미지를 선택했을 때 호출되는 delegate 메서드
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true, completion: nil)
        for result in results {
            guard let provider = result.itemProvider as? NSItemProvider, provider.canLoadObject(ofClass: UIImage.self) else {
                continue
            }
            
            // 비동기적으로 이미지를 불러옴
            provider.loadObject(ofClass: UIImage.self) { [weak self] (image, error) in
                DispatchQueue.main.async {
                    if let uiImage = image as? UIImage {
                        self?.photoModel.selectedImages.append(uiImage) // 배열에 이미지를 추가
                    }
                }
            }
        }
    }
}

// SwiftUI View: UI를 관리
struct ImageTestingView: View {
    
    // 앞에서 만들어준 반환된 뷰컨(뷰모델)을 viewModel에 할당
    @StateObject private var viewModel = PhotoPickerViewModel() // ViewModel 선언
    @State private var isPickerPresented = false

    var body: some View {
        VStack {
            // 선택된 이미지가 있으면 표시
            if !viewModel.photoModel.selectedImages.isEmpty {
                ScrollView(.horizontal) {  // 가로로 스크롤할 수 있도록 설정
                    HStack {
                        ForEach(viewModel.photoModel.selectedImages, id: \.self) { image in
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 100, height: 100)
                                .cornerRadius(8)
                        }
                    }
                }
            }
            else {
                Text("No image selected")
                    .font(.headline)
            }

            // Button("Select Photo") 버튼을 눌렀을 때, isPickerPresented가 true로 설정되고, 이에 따라 .sheet가 트리거됨.
            // 이 시점에 PhotoPickerView(viewModel: viewModel)가 프리젠트되어 PHPickerViewController가 표시됩니다.
            // 사진 선택 버튼
            Button("Select Photo") {
                isPickerPresented = true
            }
            .sheet(isPresented: $isPickerPresented) {
                PhotoPickerView(viewModel: viewModel) 
            }
        }
    }
}

// UIViewControllerRepresentable로 PHPickerViewController를 SwiftUI로 연결
struct PhotoPickerView: UIViewControllerRepresentable {
    @ObservedObject var viewModel: PhotoPickerViewModel

    func makeUIViewController(context: Context) -> PHPickerViewController {
        viewModel.presentPhotoPicker() // ViewModel에서 PHPickerViewController 생성
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {
        // 필요 시 업데이트
    }
}

// Preview
struct ImageTestingView_Previews: PreviewProvider {
    static var previews: some View {
        ImageTestingView()
    }
}
