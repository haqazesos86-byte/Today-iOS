import SwiftUI

struct DividerView: View {
    var body: some View {
        Rectangle()
            .fill(Color.tertiaryLabel.opacity(0.3))
            .frame(height: 0.5)
            .padding(.vertical, 4)
    }
}

#Preview {
    DividerView()
}
