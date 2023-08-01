import SwiftUI

class CellViewModel: ObservableObject, Identifiable {
    let id = UUID()
    let message: String

    init(message: String) {
        self.message = message
    }

    func cellTapped() {}
}

struct CellView: View {
    @ObservedObject var viewModel: CellViewModel

    var body: some View {
        Button {
            viewModel.cellTapped()
        } label: {
            Text(viewModel.message)
                .font(.caption)
        }
    }
}

struct CellView_Previews: PreviewProvider {
    static var previews: some View {
        CellView(viewModel: CellViewModel(message: OSEntryLog.mock.formatted))
            .previewLayout(.sizeThatFits)
    }
}
