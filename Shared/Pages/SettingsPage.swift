import SwiftUI

struct SettingsPage: View {
    @ObservedObject var model = treeholeDataModel
    
    @State var showTreeHoleLogin = false
    @State var showTreeHoleActions = false
    
    var body: some View {
        List {
            Section("accounts_management") {
                uisAccount
                if model.loggedIn {
                    treeHoleAccount
                } else {
                    treeHoleAccountNotLogged
                }
                
            }
            
            Section("about") {
                Text("legal")
                Text("about")
            }
        }
        .navigationTitle("settings")
    }
    
    private var uisAccount: some View {
        HStack {
            Button(action: {  }) {
                Image(systemName: "person.crop.circle.fill.badge.checkmark")
                    .font(.system(size: 42))
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(Color.accentColor, Color.accentColor.opacity(0.3))
            }.padding()
            VStack(alignment: .leading, spacing: 3.0) {
                Text("uis_account")
                    .fontWeight(.semibold)
                Text("logged_in")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var treeHoleAccount: some View {
        HStack {
            Button(action: {
                showTreeHoleActions = true
            }) {
                Image(systemName: "person.crop.circle.fill.badge.checkmark")
                    .font(.system(size: 42))
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(Color.accentColor, Color.accentColor.opacity(0.3))
            }.padding()
            VStack(alignment: .leading, spacing: 3.0) {
                Text("fduhole_account")
                    .fontWeight(.semibold)
                Text("logged_in")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
        }
        .confirmationDialog("Accounts", isPresented: $showTreeHoleActions) {
            Button("logout", role: .destructive) {
                withAnimation {
                    model.loggedIn = false
                    networks.logout()
                }
            }
        }
    }
    
    private var treeHoleAccountNotLogged: some View {
        HStack {
            Button(action: { showTreeHoleLogin = true }) {
                Image(systemName: "person.crop.circle.fill.badge.plus")
                    .font(.system(size: 42))
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(Color.secondary, Color.secondary.opacity(0.3))
            }.padding()
            VStack(alignment: .leading, spacing: 3.0) {
                Text("fduhole_account")
                    .fontWeight(.semibold)
                Text("not_logged_in")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
        }
        .sheet(isPresented: $showTreeHoleLogin) {
            LoginPage(showLoginPage: $showTreeHoleLogin)
        }
    }
}

struct SettingsPage_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SettingsPage()
        }
    }
}