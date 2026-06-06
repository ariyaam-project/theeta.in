//
//  ShareViewController.swift
//  Share Extension
//
//  Receives content shared into Theta (e.g. an Instagram reel) and forwards it
//  to the host app via receive_sharing_intent.
//
import receive_sharing_intent

class ShareViewController: RSIShareViewController {

    // Return true to auto-redirect to the host app after capturing the share.
    override func shouldAutoRedirect() -> Bool {
        return true
    }
}
