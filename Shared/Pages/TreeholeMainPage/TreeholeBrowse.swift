import SwiftUI

struct TreeholeBrowse: View {
    @ObservedObject var model = treeholeDataModel
    @EnvironmentObject var viewModel: TreeholeViewModel
    
    var body: some View {
        List {
            // pinned section
            Section {
                ForEach(viewModel.currentDivision.pinned) { hole in
                    HoleView(hole: hole)
                        .background(NavigationLink("", destination: HoleDetailPage(hole: hole)).opacity(0))
                }
            } header: {
                VStack(alignment: .leading) {
                    switchBar
                    if !viewModel.currentDivision.pinned.isEmpty {
                        Label("pinned", systemImage: "pin.fill")
                    }
                }
            }
            
            // main section
            Section {
                ForEach(viewModel.holes) { hole in
                    HoleView(hole: hole)
                        .background(NavigationLink("", destination: HoleDetailPage(hole: hole)).opacity(0))
                        .task {
                            if hole == viewModel.holes.last {
                                await viewModel.loadMoreHoles()
                            }
                        }
                }
            } header: {
                Label("main_section", systemImage: "text.bubble.fill")
            } footer: {
                spinner
            }
        }
        .listStyle(.grouped)
        .refreshable {
            await viewModel.refresh()
        }
    }
    
    private var switchBar: some View {
        Picker("division_selector", selection: $viewModel.currentDivisionId) {
            ForEach(model.divisions) { division in
                Text(division.name)
                    .tag(division.id)
            }
        }
        .pickerStyle(.segmented)
        .offset(x: 0, y: -40)
        .onChange(of: viewModel.currentDivisionId) { newValue in
            Task {
                let newDivision = model.divisions[newValue - 1]
                await viewModel.changeDivision(division: newDivision)
            }
        }
    }
    
    private var spinner: some View {
        HStack {
            Spacer()
            ProgressView()
            Spacer()
        }
    }
}