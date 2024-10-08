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


// UIViewControllerRepresentable을 사용해 UIImagePickerController 연결
struct CameraPickerView: UIViewControllerRepresentable {
    @ObservedObject var viewModel: PhotoPickerViewModel
    @Environment(\.presentationMode) var presentationMode

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: CameraPickerView

        init(_ parent: CameraPickerView) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.viewModel.photoModel.selectedImages.append(image) // 배열에 이미지 추가
            }
            parent.presentationMode.wrappedValue.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}


struct ImageTestingView: View {

    @StateObject private var viewModel = PhotoPickerViewModel()
    @State private var selectedItems: [PhotosPickerItem] = [] // 선택된 이미지 아이템
    @State private var isCameraPresented = false // 카메라 표시 상태

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
        
        // 카메라 버튼 추가
        Button("Open Camera") {
            isCameraPresented = true
        }
        .font(.headline)
        .padding()
        .background(Color.green)
        .foregroundColor(.white)
        .cornerRadius(8)
        .sheet(isPresented: $isCameraPresented) {
            CameraPickerView(viewModel: viewModel)
        }

    }
}

struct ImageTestingView_Previews: PreviewProvider {
    static var previews: some View {
        ImageTestingView()
    }
}
