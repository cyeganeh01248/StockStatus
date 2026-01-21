import Foundation
import Combine

class StockViewModel: ObservableObject {
    @Published var currentQuote: StockQuote?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private let updateManager = UpdateManager.shared
    private var cancellables = Set<AnyCancellable>()

    init() {
        // Subscribe to update manager
        updateManager.$currentQuote
            .receive(on: DispatchQueue.main)
            .assign(to: &$currentQuote)

        updateManager.$isUpdating
            .receive(on: DispatchQueue.main)
            .assign(to: &$isLoading)

        updateManager.$errorMessage
            .receive(on: DispatchQueue.main)
            .assign(to: &$errorMessage)
    }

    func refresh() {
        updateManager.refreshNow()
    }

    func switchSymbol(to symbol: String) {
        updateManager.switchSymbol(to: symbol)
    }
}
