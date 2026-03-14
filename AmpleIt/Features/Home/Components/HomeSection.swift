import SwiftUI

struct HomeSection<Content: View>: View {
    let title: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(title)
                    .font(.title3.weight(.semibold))
                Spacer()
                Button("See all") {}
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            content
        }
    }
}
