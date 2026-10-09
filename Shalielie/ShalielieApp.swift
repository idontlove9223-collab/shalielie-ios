import SwiftUI
import UIKit
import PhotosUI
import Photos
import UniformTypeIdentifiers

@main
struct ShalielieApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct ContentView: View {
    @State private var serverURL: String = UserDefaults.standard.string(forKey: "serverURL")
        ?? "http://shalielie.local:8765/patch"
    @State private var status: String = "选择一张 iPhone 拍摄的 HEIC 照片"
    @State private var busy: Bool = false
    @State private var showPicker: Bool = false

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("服务器地址")) {
                    TextField("http://192.168.1.23:8765/patch", text: $serverURL)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                }
                Section {
                    Button(action: { showPicker = true }) {
                        Label("从相册选择照片", systemImage: "photo.on.rectangle")
                    }
                    .disabled(busy)
                }
                Section(header: Text("状态")) {
                    Text(status)
                        .foregroundColor(colorForStatus)
                    if busy {
                        ProgressView()
                    }
                }
            }
            .navigationTitle("摄影风格")
            .sheet(isPresented: $showPicker) {
                PhotoPicker { item in
                    showPicker = false
                    if let item = item {
                        process(item)
                    }
                }
            }
            .onDisappear {
                UserDefaults.standard.set(serverURL, forKey: "serverURL")
            }
        }
    }

    private var colorForStatus: Color {
        if busy { return Color.secondary }
        if status.hasPrefix("已保存") { return Color.green }
        if status.hasPrefix("选择") || status.hasPrefix("等待") { return Color.primary }
        return Color.orange
    }

    func process(_ result: PHPickerResult) {
        let provider = result.itemProvider
        busy = true
        status = "读取照片原始数据..."
        provider.loadFileRepresentation(forTypeIdentifier: UTType.image.identifier) { url, error in
            guard let url = url, error == nil else {
                DispatchQueue.main.async {
                    busy = false
                    status = "读取照片失败：\(error?.localizedDescription ?? "未知错误")"
                }
                return
            }
            do {
                let data = try Data(contentsOf: url)
                DispatchQueue.main.async {
                    upload(data)
                }
            } catch {
                DispatchQueue.main.async {
                    busy = false
                    status = "读取照片数据失败，请换一张照片重试"
                }
            }
        }
    }

    func upload(_ data: Data) {
        let trimmed = serverURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: trimmed) else {
            busy = false
            status = "服务器地址无效，请检查后重试"
            return
        }
        var request = URLRequest(url: url)
        request.timeoutInterval = 300
        request.httpMethod = "POST"
        let boundary = "ShalielieBoundary" + UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)",
                         forHTTPHeaderField: "Content-Type")

        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"photo\"; filename=\"photo.HEIC\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/heic\r\n\r\n".data(using: .utf8)!)
        body.append(data)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body

        status = "发送到服务器处理..."
        URLSession.shared.dataTask(with: request) { respData, response, error in
            DispatchQueue.main.async {
                busy = false
                if let error = error {
                    status = "连接服务器失败：\(error.localizedDescription)"
                    return
                }
                guard let http = response as? HTTPURLResponse, let respData = respData else {
                    status = "服务器无响应"
                    return
                }
                if http.statusCode == 200 && !respData.isEmpty {
                    saveToLibrary(respData)
                } else {
                    let text = String(data: respData, encoding: .utf8)
                        ?? "处理失败（HTTP \(http.statusCode)）"
                    status = text
                }
            }
        }.resume()
    }

    func saveToLibrary(_ data: Data) {
        status = "保存到相册..."
        PHPhotoLibrary.requestAuthorization { auth in
            DispatchQueue.main.async {
                guard auth == .authorized || auth == .limited else {
                    status = "没有相册权限：请到 设置 → 隐私与安全性 → 照片 允许"
                    return
                }
                PHPhotoLibrary.shared().performChanges {
                    let creation = PHAssetCreationRequest.forAsset()
                    let options = PHAssetResourceCreationOptions()
                    options.uniformTypeIdentifier = UTType.heic.identifier
                    creation.addResource(with: .photo, data: data, options: options)
                } completionHandler: { success, error in
                    DispatchQueue.main.async {
                        if success {
                            status = "已保存到相册，去照片编辑里查看摄影风格效果"
                        } else {
                            status = "保存失败：\(error?.localizedDescription ?? "未知错误")"
                        }
                    }
                }
            }
        }
    }
}

struct PhotoPicker: UIViewControllerRepresentable {
    var onPick: (PHPickerResult?) -> Void

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: PhotoPicker
        init(_ parent: PhotoPicker) { self.parent = parent }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true) {
                self.parent.onPick(results.first)
            }
        }
    }
}
