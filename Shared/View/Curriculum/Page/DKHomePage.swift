import SwiftUI
import BetterSafariView
import Utils

struct DKHomePage: View {
    var body: some View {
        AsyncContentView { () -> [DKCourseGroup] in
            try await DKModel.shared.loadAll()
            return DKModel.shared.courses.shuffled()
        } content: { courses in
            HomePageContent(courses: courses)
        }
    }
}

fileprivate struct HomePageContent: View {
    let courses: [DKCourseGroup]
    @State private var searchText = ""
    @State private var openURL: URL? = nil
    @StateObject var navigator = DKNavigator()
    
    private var searchResults: [DKCourseGroup] {
        if searchText.isEmpty {
            return courses
        } else {
            return courses.filter { $0.name.localizedCaseInsensitiveContains(searchText) || $0.code.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    var body: some View {
        NavigationStack(path: $navigator.path) {
            ScrollViewReader { proxy in
                List {
                    EmptyView()
                        .id("dk-top")
                    
                    ForEach(searchResults) { course in
                        NavigationLink(value: course) {
                            DKCourseView(courseGroup: course)
                        }
                    }
                }
                .onReceive(OnDoubleTapCurriculumTabBarItem, perform: {
                    if navigator.path.count > 0 {
                        navigator.path.removeLast(navigator.path.count)
                    } else {
                        withAnimation {
                            proxy.scrollTo("dk-top")
                        }
                    }
                })
            }
            .listStyle(.plain)
            .searchable(text: $searchText)
            .navigationTitle("Curriculum Board")
            .navigationDestination(for: DKCourseGroup.self) { course in
                DKCoursePage(courseGroup: course)
            }
#if !targetEnvironment(macCatalyst)
            .environment(\.openURL, OpenURLAction { url in
                openURL = url
                return .handled
            })
            .safariView(item: $openURL) { link in
                SafariView(url: link)
            }
#endif
        }
    }
}

class DKNavigator: ObservableObject {
    @Published var path = NavigationPath()
}
