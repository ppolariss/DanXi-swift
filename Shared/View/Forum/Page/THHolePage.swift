import SwiftUI

struct THHolePage: View {
    @StateObject var model: THHoleModel
    
    init(_ hole: THHole) {
        self._model = StateObject(wrappedValue: THHoleModel(hole: hole))
    }
    
    init(_ model: THHoleModel) {
        self._model = StateObject(wrappedValue: model)
    }
    
    var body: some View {
        ScrollViewReader { proxy in
            List {
                Section {
                    ForEach(model.filteredFloors) { floor in
                        THComplexFloor(floor, context: model)
                            .task {
                                if floor == model.floors.last {
                                    await model.loadMoreFloors()
                                }
                            }
                    }
                } header: {
                    HStack {
                        ForEach(model.hole.tags) { tag in
                            THTagView(tag: tag)
                        }
                    }
                } footer: {
                    if !model.endReached {
                        LoadingFooter(loading: $model.loading,
                                      errorDescription: (model.loadingError?.localizedDescription ?? ""),
                                      action: model.loadAllFloors)
                    }
                }
                .task {
                    if model.floors.isEmpty {
                        await model.loadMoreFloors()
                    }
                }
                .onAppear {
                    if model.scrollTarget != -1 {
                        proxy.scrollTo(model.scrollTarget, anchor: .top)
                    }
                }
                .onChange(of: model.scrollTarget) { target in
                    if target > 0 {
                        proxy.scrollTo(target, anchor: .top)
                    }
                }
            }
            .listStyle(.plain)
            .navigationTitle("#\(String(model.hole.id))")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    THHoleToolbar()
                }
            }
            .environmentObject(model)
        }
    }
}

struct THHoleToolbar: View {
    @EnvironmentObject var model: THHoleModel
    @Environment(\.editMode) var editMode
    
    @State var showDeleteAlert = false
    @State var showEditSheet = false
    @State var showReplySheet = false
    
    var body: some View {
        Group {
            replyButton
            favoriteButton
            menu
        }
    }
    
    private var replyButton: some View {
        Button {
            showReplySheet = true
        } label: {
            Image(systemName: "arrowshape.turn.up.left")
        }
        .sheet(isPresented: $showReplySheet) {
            Text("TODO: Reply Sheet")
        }
    }
    
    private var favoriteButton: some View {
        AsyncButton {
            try await model.toggleFavorite()
        } label: {
            Image(systemName: model.isFavorite ? "star.fill" : "star")
        }
    }
    
    private var menu: some View {
        Menu {
            Picker("Filter Options", selection: $model.filterOption) {
                Label("Show All", systemImage: "list.bullet")
                    .tag(THHoleModel.FilterOptions.all)
                
                Label("Show OP Only", systemImage: "person.fill")
                    .tag(THHoleModel.FilterOptions.posterOnly)
            }
            
            AsyncButton {
                await model.loadAllFloors()
            } label: {
                Label("Navigate to Bottom", systemImage: "arrow.down.to.line")
            }
            
            if DXModel.shared.isAdmin {
                Divider()
                
                AsyncButton {
                    try await model.deleteHole()
                } label: {
                    Label("Hide Hole", systemImage: "eye.slash.fill")
                }
                
                Button {
                    showEditSheet = true
                } label: {
                    Label("Edit Post Info", systemImage: "info.circle")
                }
            }
        } label: {
            Image(systemName: "ellipsis.circle")
        }
        .sheet(isPresented: $showEditSheet) {
            Text("TODO: EditSheet")
        }
        .alert("Confirm Delete Post", isPresented: $showDeleteAlert) {
            Button("Confirm", role: .destructive) {
                Task {
                    try await model.deleteHole()
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will affect all replies of this post")
        }
    }
}

struct THHoleBottomBar: View {
    var body: some View {
        Text("Hello")
    }
}
