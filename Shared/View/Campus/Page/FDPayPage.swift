import SwiftUI
import UIKit

struct FDPayPage: View {
    @State private var qrCodeData: Data? = nil
    @State private var loading = false
    @State private var errorInfo = ""
    
    func loadCodeData() {
        Task {
            loading = true
            defer { loading = false }
            do {
                let qrcodeStr = try await FDECardAPI.getQRCodeString()
                
                // generate QR code data
                guard let filter = CIFilter(name: "CIQRCodeGenerator") else {
                    throw ParseError.invalidResponse
                }
                let data = qrcodeStr.data(using: .ascii, allowLossyConversion: false)
                filter.setValue(data, forKey: "inputMessage")
                guard let ciimage = filter.outputImage else {
                    throw ParseError.invalidResponse
                }
                let transform = CGAffineTransform(scaleX: 10, y: 10)
                let scaledCIImage = ciimage.transformed(by: transform)
                let uiImage = UIImage(ciImage: scaledCIImage)
                qrCodeData = uiImage.pngData()!
            } catch {
                errorInfo = error.localizedDescription
            }
        }
    }
    
    var body: some View {
        VStack {
            Group {
                if loading {
                    ProgressView()
                } else if let data = qrCodeData {
                    Image(uiImage: UIImage(data: data)!)
                        .resizable()
                } else {
                    Text("Error")
                }
            }
            .frame(width: 300, height: 300)
                
            
            Button {
                loadCodeData()
            } label: {
                Label("Refresh QR Code", systemImage: "arrow.clockwise")
            }
        }
        .navigationTitle("Fudan QR Code")
        .task {
            loadCodeData()
        }
    }
}

struct FDPayPage_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            FDPayPage()
        }
    }
}
