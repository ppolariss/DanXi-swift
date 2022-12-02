import SwiftUI

struct ContentView: View {
    @ObservedObject var authDelegate = AuthDelegate.shared
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State var navigationTarget: NavigationTarget?
    
    enum NavigationTarget {
        case code, sport, treehole, curriculum, settings, about
    }
    
    var body: some View {
        NavigationSplitView {
            contentList
        } detail: {
            if let navigationTarget = navigationTarget {
                switch navigationTarget {
                case .code:
                    QRCodePage()
                case .sport:
                    SportPage()
                case .treehole:
                    TreeholePage()
                case .curriculum:
                    CourseMainPage()
                case .about:
                    AboutPage()
                case .settings:
                    SettingsPage()
                }
            } else {
                Text("Not Selected")
            }
        }
    }

    private var contentList: some View {
        List(selection: $navigationTarget) {
            Section("Campus Services") {
                Label("Fudan QR Code", systemImage: "qrcode")
                    .tag(NavigationTarget.code)
                Label("PE Curriculum", systemImage: "figure.disc.sports")
                    .tag(NavigationTarget.sport)
            }
            
            Section("DanXi Services") {
                if authDelegate.isLogged {
                    Label("Tree Hole", systemImage: "text.bubble")
                        .tag(NavigationTarget.treehole)

                    Label("Curriculum", systemImage: "books.vertical")
                        .tag(NavigationTarget.curriculum)
                    
                    LinkView(url: "https://canvas.fduhole.com", text: "Canvas", icon: "paintbrush.pointed")
                    
                    LinkView(url: "https://fdu-hotpot.top", text: "FDU Hotpot", icon: "figure.run")
                } else {
                    // TODO: refine this section
                    Text("Not Logged In")
                        .foregroundColor(.secondary)
                }
            }
            
            Section {
                Label("Settings", systemImage: "gearshape")
                    .tag(NavigationTarget.settings)
                
                Label("About", systemImage: "info.circle")
                    .tag(NavigationTarget.about)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("DanXi")
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        AuthDelegate.shared.isLogged = true
        
        return ContentView()
    }
}
