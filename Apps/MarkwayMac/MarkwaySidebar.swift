import SwiftUI

struct MarkwaySidebar: View {
    @Environment(\.colorScheme) private var colorScheme
    @Binding var selectedSection: MarkwaySection?

    var body: some View {
        List(selection: $selectedSection) {
            Section {
                ForEach(MarkwaySection.allCases) { section in
                    Label(section.title, systemImage: section.symbolName)
                        .tag(section)
                }
            }
        }
        .listStyle(.sidebar)
        .scrollContentBackground(.hidden)
        .background(MarkwayTheme.sidebarBackground(colorScheme))
        .safeAreaInset(edge: .top, spacing: 8) {
            HStack {
                Image("MarkwayLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 156, height: 38, alignment: .leading)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 8)
            .background(MarkwayTheme.sidebarBackground(colorScheme))
        }
    }
}
