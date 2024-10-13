//
//  TestingMetaView.swift
//  FiveGuyes
//
//  Created by 신혜연 on 10/7/24.
//

import CoreLocation
import ImageIO
import Photos
import SwiftUI

struct TestingMetaView: View {
    @State private var showImagePicker = false
    @State private var selectedImage: UIImage?
    @State private var imageMetadata: ImageMetadata?
    @State private var locationName: String?
    
    var body: some View {
        VStack {
            if let image = selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 300, height: 300)
            } else {
                Text("이미지가 선택되지 않았습니다.")
                    .padding()
            }
            
            if let metadata = imageMetadata {
                if let imageDate = metadata.imageDate {
                    let formattedDate = DateFormatter.formatDate(from: imageDate)
                    VStack {
                        Text(formattedDate)
                    }
                } else {
                    Text("EXIF 정보 없음")
                        .padding()
                }
                
                if let locationName = locationName {
                    Text(locationName)
                        .padding()
                } else {
                    Text("위치 정보 없음")
                        .padding()
                }
            } else {
                Text("메타데이터 없음")
                    .padding()
            }
            
            Button(action: {
                showImagePicker = true
            }, label: {
                Text("이미지 선택")
            })
            .sheet(isPresented: $showImagePicker) {
                LoadMetaDataView(selectedImage: $selectedImage, imageMetadata: $imageMetadata, locationName: $locationName)
            }
        }
    }
}

#Preview {
    TestingMetaView()
}
