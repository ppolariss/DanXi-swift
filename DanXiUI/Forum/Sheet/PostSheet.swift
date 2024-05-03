import SwiftUI
import ViewUtils
import DanXiKit

struct PostSheet: View {
    @ObservedObject private var divisionStore = DivisionStore.shared
    @EnvironmentObject private var navigator: AppNavigator
    
    @State var divisionId: Int
    @State private var content = ""
    @State private var tags: [String] = []
    @State private var runningImageUploadTask = 0
    
    var body: some View {
        Sheet("New Post") {
            let hole = try await ForumAPI.createHole(content: content, divisionId: divisionId, tags: tags)
            navigator.pushDetail(value: hole, replace: true) // navigate to hole page
            
            Task {
                try? await FavoriteStore.shared.refreshFavoriteIds()
                try? await SubscriptionStore.shared.refreshSubscriptionIds()
            }
        } content: {
            Section {
                Picker(selection: $divisionId,
                       label: Label("Select Division", systemImage: "rectangle.3.group")) {
                    ForEach(divisionStore.divisions) { division in
                        Text(division.name).tag(division.id)
                    }
                }
                .labelStyle(.titleOnly)
            }
            
            Section("Tags") {
                TagEditor($tags, maxSize: 5)
            }
            
            ForumEditor(content: $content, runningImageUploadTasks: $runningImageUploadTask, initiallyFocused: false)
        }
        .completed(!tags.isEmpty && !content.isEmpty && runningImageUploadTask <= 0)
        .warnDiscard(!tags.isEmpty || !content.isEmpty || runningImageUploadTask > 0)
    }
}