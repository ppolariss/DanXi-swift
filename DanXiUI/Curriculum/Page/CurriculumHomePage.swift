import SwiftUI
import BetterSafariView
import Utils
import ViewUtils
import DanXiKit

struct CurriculumHomePage: View {
    @ObservedObject private var model = CurriculumModel.shared
    
    var body: some View {
        AsyncContentView (action: { forceRefresh in
            if forceRefresh {
                try await model.loadRemote()
            } else {
                try await model.loadLocal()
            }
        }, content: {
            HomePageContent(courses: model.courses)
                .id("DKHomePageContent-View")
        }, loadingView: {
            if model.courses.isEmpty {
                ProgressView()
                    .eraseToAnyView()
            } else {
                HomePageContent(courses: model.courses)
                    .id("DKHomePageContent-View")
                    .eraseToAnyView()
            }
        }, failureView: nil)
        .navigationTitle("Curriculum Board")
    }
}

fileprivate struct HomePageContent: View {
    let courses: [CourseGroup]
    @State private var searchText = ""
    
    private var searchResults: [CourseGroup] {
        if searchText.isEmpty {
            return courses
        } else {
            return courses.filter { $0.name.localizedCaseInsensitiveContains(searchText) || $0.code.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    var body: some View {
        ScrollViewReader { proxy in
            List {
                EmptyView()
                    .id("dk-top")
                
                ForEach(searchResults) { course in
                    DetailLink(value: course) {
                        CourseView(courseGroup: course)
                            .navigationStyle()
                    }
                }
            }
            .onReceive(AppEvents.ScrollToTop.curriculum) {
                withAnimation {
                    proxy.scrollTo("dk-top")
                }
            }
        }
        .listStyle(.plain)
        .searchable(text: $searchText)
    }
}