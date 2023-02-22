import SwiftUI

struct FDHomePage: View {
    var body: some View {
        NavigationStack {
            List {
                NavigationLink {
                    FDPayPage()
                } label: {
                    Label("Fudan QR Code", systemImage: "qrcode")
                }
                
                NavigationLink {
                    FDSportPage()
                } label: {
                    Label("PE Curriculum", systemImage: "figure.disc.sports")
                }

                NavigationLink {
                    FDBusPage()
                } label: {
                    Label("Bus Schedule", systemImage: "bus.fill")
                }
            }
            .navigationTitle("Campus Services")
        }
    }
}

struct FDHomePage_Previews: PreviewProvider {
    static var previews: some View {
        FDHomePage()
    }
}
