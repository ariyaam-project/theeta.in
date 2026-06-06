import MobileCoreServices
import UIKit

class ShareViewController: UIViewController {
    private let pendingUrlsKey = "pendingInstagramShares"
    private var didHandleShare = false

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard !didHandleShare else { return }
        didHandleShare = true
        saveSharedText()
    }

    private func saveSharedText() {
        let providers = (extensionContext?.inputItems as? [NSExtensionItem] ?? [])
            .flatMap { $0.attachments ?? [] }
        let group = DispatchGroup()

        for provider in providers {
            let typeIdentifier: String
            if provider.hasItemConformingToTypeIdentifier(kUTTypeURL as String) {
                typeIdentifier = kUTTypeURL as String
            } else if provider.hasItemConformingToTypeIdentifier(kUTTypeText as String) {
                typeIdentifier = kUTTypeText as String
            } else {
                continue
            }

            group.enter()
            provider.loadItem(forTypeIdentifier: typeIdentifier, options: nil) { item, _ in
                var value: String?
                if let url = item as? URL {
                    value = url.absoluteString
                } else if let text = item as? String {
                    value = text
                }
                DispatchQueue.main.async { [weak self] in
                    if let value {
                        self?.appendToInbox([value])
                    }
                    group.leave()
                }
            }
        }

        group.notify(queue: .main) { [weak self] in
            self?.extensionContext?.completeRequest(returningItems: nil)
        }
    }

    private func appendToInbox(_ values: [String]) {
        guard let appGroupId = Bundle.main.object(forInfoDictionaryKey: "AppGroupId") as? String else {
            return
        }
        guard let defaults = UserDefaults(suiteName: appGroupId) else { return }
        var pending = defaults.stringArray(forKey: pendingUrlsKey) ?? []
        pending.append(contentsOf: values)
        defaults.set(Array(Set(pending)), forKey: pendingUrlsKey)
    }
}
