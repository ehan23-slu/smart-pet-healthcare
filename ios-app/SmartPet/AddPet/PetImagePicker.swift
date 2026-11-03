//
//  PetImage.swift
//  SmartPet
//

import SwiftUI
import PhotosUI

struct PetImagePicker: UIViewControllerRepresentable {
    // SwiftUI doesn't have built-in image picker,
    // need birdge to UIKIT through UIViewControllerRepresentable
    @Binding var selectedImageData: Data?

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    } // SwiftUI calls this to create a coordinator,
    // which listens for when the user finishes picking a photo

    func makeUIViewController(context: Context) -> PHPickerViewController {
        // PHPickerViewController, which is used to let users pick photos from their photo library
        var config = PHPickerConfiguration()
        // configuration defines how the picker behaves
        config.filter = .images
        config.selectionLimit = 1

        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    // class that conforms to the delegate protocol for the image picker
    // it bridges bewteen UIKit and SwiftUI
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: PetImagePicker

        init(_ parent: PetImagePicker) {
            self.parent = parent
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)

            guard let provider = results.first?.itemProvider,
                  provider.canLoadObject(ofClass: UIImage.self) else { return }

            provider.loadObject(ofClass: UIImage.self) { image, error in
                if let uiImage = image as? UIImage {
                    DispatchQueue.main.async {
                        self.parent.selectedImageData = uiImage.jpegData(compressionQuality: 0.8)
                    }
                }
            }
        }
    }
}
