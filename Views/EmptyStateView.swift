import SwiftUI

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 8) {
            Text("今天可以偷个懒了")
                .font(.system(size: 16))
                .foregroundColor(.secondary)
            Text("☕️")
                .font(.system(size: 32))
        }
        .transition(.opacity.combined(with: .scale(scale: 0.9)))
    }
}

#Preview {
    EmptyStateView()
}
