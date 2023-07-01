import SwiftUI

struct THBrowsePage: View {
    @ObservedObject private var settings = THSettings.shared
    @ObservedObject private var appModel = THModel.shared
    @EnvironmentObject private var model: THBrowseModel
    @EnvironmentObject private var nav: THNavigationModel
    
    var body: some View {
        THBackgroundList {
            THDivisionPicker()
            
            if !appModel.banners.isEmpty && settings.showBanners {
                BannerView(appModel.banners)
            }
            
            // Banned Notice
            if let bannedDate = model.bannedDate {
                BannedNotice(date: bannedDate)
            }
            
            // Pinned Holes
            if !model.division.pinned.isEmpty {
                Section {
                    Label("Pinned", systemImage: "pin.fill")
                        .bold()
                        .foregroundColor(.secondary)
                        .listRowSeparator(.hidden)
                        
                    
                    ForEach(model.division.pinned) { hole in
                        THHoleView(hole: hole)
                    }
                }
            }
            
            // Main Section
            Section {
                if !model.division.pinned.isEmpty { // only show lable when there is pinned section
                    Label("Main Section", systemImage: "text.bubble.fill")
                        .bold()
                        .foregroundColor(.secondary)
                        .listRowSeparator(.hidden)
                }
                
                AsyncCollection(model.filteredHoles, endReached: false,
                                action: model.loadMoreHoles) { hole in
                    let fold = settings.sensitiveContent == .fold && hole.nsfw
                    THHoleView(hole: hole, fold: fold)
                }
                .id(model.configId) // stop old loading task when config change
            }
        }
        .animation(.default, value: model.division)
        .navigationTitle(model.division.name)
        .refreshable {
            await model.refresh()
        }
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                THBrowseToolbar()
            }
        }
    }
}

fileprivate struct THDivisionPicker: View {
    @ObservedObject var appModel = THModel.shared
    @EnvironmentObject var model: THBrowseModel
    
    var body: some View {
        Picker("Division Selector", selection: $model.division) {
            ForEach(appModel.divisions) { division in
                Text(division.name)
                    .tag(division)
            }
        }
        .pickerStyle(.segmented)
        .listRowSeparator(.hidden)
    }
}

fileprivate struct THDatePicker: View {
    @EnvironmentObject var model: THBrowseModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                let dateBinding = Binding<Date>(
                    get: { model.baseDate ?? Date() },
                    set: { model.baseDate = $0 }
                )
                
                DatePicker("Start Date", selection: dateBinding, in: ...Date.now, displayedComponents: [.date])
                    .datePickerStyle(.graphical)
                
                if model.baseDate != nil {
                    Button("Clear Date", role: .destructive) {
                        model.baseDate = nil
                        dismiss()
                    }
                }
            }
        }
        .navigationTitle("Select Date")
        .navigationBarTitleDisplayMode(.inline)
    }
}

fileprivate struct THBrowseToolbar: View {
    @EnvironmentObject var model: THBrowseModel
    
    @State var showPostSheet = false
    @State var showDatePicker = false
    
    var body: some View {
        Group {
            postButton
            filterMenu
        }
        .sheet(isPresented: $showPostSheet) {
            THPostSheet(divisionId: model.division.id)
        }
        .sheet(isPresented: $showDatePicker) {
            THDatePicker()
        }
    }
    
    private var postButton: some View {
        Button {
            showPostSheet = true
        } label: {
            Image(systemName: "square.and.pencil")
        }
    }
    
    private var filterMenu: some View {
        Menu {
            Picker("Sort Options", selection: $model.sortOption) {
                Text("Last Updated")
                    .tag(THBrowseModel.SortOption.replyTime)
                Text("Last Created")
                    .tag(THBrowseModel.SortOption.createTime)
            }
            
            Button {
                showDatePicker = true
            } label: {
                Label("Select Date", systemImage: "clock.arrow.circlepath")
            }
        } label: {
            Image(systemName: "ellipsis.circle")
        }
    }
}

fileprivate struct BannedNotice: View {
    let date: Date
    @State private var collapse = false
    
    var body: some View {
        if collapse {
            EmptyView()
        } else {
            Section {
                HStack(alignment: .top) {
                    Image(systemName: "exclamationmark.circle.fill")
                    VStack(alignment: .leading) {
                        Text("You are banned in this division until \(date.formatted())")
                        Text("If you have any question, you may contact admin@fduhole.com")
                            .font(.footnote)
                    }
                    Spacer()
                    Button {
                        withAnimation {
                            collapse = true
                        }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                            .font(.footnote)
                    }
                }
                .padding()
                .foregroundColor(.red)
                .background(.red.opacity(0.15))
                .cornerRadius(7)
                .listRowSeparator(.hidden)
            }
        }
    }
}

fileprivate struct BannerView: View {
    let banners: [DXBanner]
    @State private var currentBanner: Int = 0
    
    @Environment(\.openURL) private var openURL
    @EnvironmentObject private var navigator: THNavigationModel
    private let timer = Timer.publish(every: 5, on: .main, in: .default).autoconnect()
    @ScaledMetric private var height: CGFloat = 40
    @ScaledMetric private var containerHeight: CGFloat = 70
    
    @ScaledMetric private var fontSize: CGFloat = 15
    
    init(_ banners: [DXBanner]) {
        self.banners = banners
    }
    
    private func updateBanner() {
        withAnimation {
            if currentBanner == banners.count {
                currentBanner = 0
            } else {
                currentBanner += 1
            }
        }
    }
    
    private func actionButton(_ action: String) {
        if let holeMatch = action.wholeMatch(of: /#(?<id>\d+)/),
           let holeId = Int(holeMatch.id) {
            let loader = THHoleLoader(holeId: holeId)
            navigator.path.append(loader)
        } else if let floorMatch = action.wholeMatch(of: /##(?<id>\d+)/),
                  let floorId = Int(floorMatch.id) {
            let loader = THHoleLoader(floorId: floorId)
            navigator.path.append(loader)
        } else if let url = URL(string: action) {
            openURL(url)
        }
    }
    
    var body: some View {
        TabView(selection: $currentBanner) {
            ForEach(Array(banners.enumerated()), id: \.offset) { index, banner in
                HStack {
                    Image(systemName: "bell.fill")
                        .foregroundColor(.accentColor)
                    Text(banner.title)
                        .multilineTextAlignment(.leading)
                        .lineLimit(3)
                    Spacer()
                    Button(banner.actionName) {
                        actionButton(banner.action)
                    }
                }
                .font(.system(size: fontSize))
                .frame(height: height)
                .padding()
                .background(.gray.opacity(0.1))
                .cornerRadius(15)
                .padding(.horizontal)
                .tag(index)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .frame(height: containerHeight)
        .listRowSeparator(.hidden)
        .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
        .lineLimit(nil)
        .onReceive(timer) { _ in
            updateBanner()
        }
    }
}
