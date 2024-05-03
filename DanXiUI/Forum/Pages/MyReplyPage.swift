import SwiftUI
import ViewUtils
import DanXiKit

struct MyReplyPage: View {
    var body: some View {
        ForumList {
            AsyncCollection { floors in
                try await ForumAPI.listMyFloors(offset: floors.count)
            } content: { floor in
                Section {
                    DetailLink(value: HoleLoader(floor)) {
                        SimpleFloorView(floor: floor)
                    }
                    .listRowInsets(EdgeInsets(top: 10, leading: 12, bottom: 10, trailing: 12))
                }
            }
        }
        .navigationTitle("My Reply")
        .navigationBarTitleDisplayMode(.inline)
        .watermark()
    }
}