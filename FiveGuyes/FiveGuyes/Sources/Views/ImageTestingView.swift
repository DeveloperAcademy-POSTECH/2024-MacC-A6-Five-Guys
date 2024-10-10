//
//  ImageTestingView.swift
//  FiveGuyes
//
//  Created by Shim Hyeonhee on 10/10/24.
//

import PhotosUI
import SwiftUI

struct ImageTestingView: View {
    @StateObject private var viewModel = PhotoPickerViewModel()  // ViewModel 인스턴스
    @State private var selectedItems: [PhotosPickerItem] = []    // 갤러리에서 선택한 항목
    @State private var isCameraPresented = false                 // 카메라 시트 표시 여부

    var body: some View {
        VStack {
            // 이미지가 있을 때 스크롤뷰로 표시
            if !viewModel.gallerySelectedPhotos.isEmpty || viewModel.cameraSelectedPhoto != nil {
                ScrollView(.horizontal) {
                    HStack {
                        // 선택된 갤러리 이미지들 표시
                        ForEach(viewModel.gallerySelectedPhotos, id: \.imageData) { photo in
                            if let uiImage = photo.uiImage {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 100, height: 100)
                                    .cornerRadius(8)
                            }
                        }
                        
                        // 카메라에서 선택한 이미지 표시
                        if let cameraPhoto = viewModel.cameraSelectedPhoto, let uiImage = cameraPhoto.uiImage {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 100, height: 100)
                                .cornerRadius(8)
                        }
                    }
                }
            } else {
                Text("선택된 이미지가 아직 없어요")
                    .font(.headline)
            }

            // 갤러리에서 사진 선택
            PhotosPicker(selection: $selectedItems, maxSelectionCount: 0, matching: .images) {
                Text("Select Photos")
                    .font(.headline)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .onChange(of: selectedItems) {
                viewModel.loadImagesFromPicker(selectedItems)
            }

            // 카메라 열기 버튼
            Button("Open Camera") {
                isCameraPresented = true
            }
            .font(.headline)
            .padding()
            .background(Color.green)
            .foregroundColor(.white)
            .cornerRadius(8)
            .sheet(isPresented: $isCameraPresented) {
                CameraPickerView(
                    selectedImage: .constant(nil),
                    onImagePicked: { image in
                        if let image = image {
                            viewModel.setCameraImage(image)
                        }
                    },
                    onCancel: {
                        print("카메라가 취소되었어요")
                    }
                )
            }
        }
    }
}
