//
//  ImageTestingView_Photopicker.swift
//  FiveGuyes
//
//  Created by Shim Hyeonhee on 10/8/24.
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
}

struct ImageTestingView: View {

    @StateObject private var viewModel = PhotoPickerViewModel()
    @State private var selectedItems: [PhotosPickerItem] = [] // 선택된 이미지 아이템

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
            } else {
                Text("No image selected")
                    .font(.headline)
            }

            // PhotosPicker를 사용하여 이미지를 선택할 수 있음
            PhotosPicker(selection: $selectedItems, maxSelectionCount: 0, matching: .images) {
                Text("Select Photos")
                    .font(.headline)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .onChange(of: selectedItems) { newItems in
                // 이미지를 비동기적으로 가져옴
                for item in newItems {
                    item.loadTransferable(type: Data.self) { result in
                        DispatchQueue.main.async {
                            switch result {
                            case .success(let data):
                                if let data = data, let uiImage = UIImage(data: data) {
                                    viewModel.photoModel.selectedImages.append(uiImage) // 배열에 이미지 추가
                                }
                            case .failure(let error):
                                print("Error loading image: \\(error.localizedDescription)")
                            }
                        }
                    }
                }
            }
        }
    }
}

struct ImageTestingView_Previews: PreviewProvider {
    static var previews: some View {
        ImageTestingView()
    }
}
