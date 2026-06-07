import Foundation

#if canImport(Sparkle)
import Sparkle
#endif

@MainActor
final class MarkwayUpdater: ObservableObject {
    #if canImport(Sparkle)
    private let controller: SPUStandardUpdaterController?
    #else
    private let controller: AnyObject? = nil
    #endif

    init() {
        #if canImport(Sparkle)
        if Self.hasUpdateConfiguration {
            controller = SPUStandardUpdaterController(
                startingUpdater: true,
                updaterDelegate: nil,
                userDriverDelegate: nil
            )
        } else {
            controller = nil
        }
        #endif
    }

    var canCheckForUpdates: Bool {
        controller != nil
    }

    func checkForUpdates() {
        #if canImport(Sparkle)
        controller?.checkForUpdates(nil)
        #endif
    }

    private static var hasUpdateConfiguration: Bool {
        let feedURL = Bundle.main.object(forInfoDictionaryKey: "SUFeedURL") as? String ?? ""
        let publicKey = Bundle.main.object(forInfoDictionaryKey: "SUPublicEDKey") as? String ?? ""
        return !feedURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !publicKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
