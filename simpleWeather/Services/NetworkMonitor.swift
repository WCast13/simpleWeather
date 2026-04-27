//
//  NetworkMonitor.swift
//  simpleWeather
//
//  Created by William Castellano on 2/12/26.
//

import Foundation
import Network

/// Monitor network connectivity status
@MainActor
@Observable
final class NetworkMonitor {
    // Singleton instance
    static let shared = NetworkMonitor()

    // Network status
    private(set) var isConnected: Bool = true
    private(set) var connectionType: NWInterface.InterfaceType?

    private let monitor: NWPathMonitor
    private let queue = DispatchQueue(label: "NetworkMonitor")

    // MARK: - Initialization

    init() {
        monitor = NWPathMonitor()
        startMonitoring()
    }

    deinit {
        monitor.cancel()
    }

    // MARK: - Public Methods

    /// Start monitoring network status
    func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                self?.isConnected = path.status == .satisfied

                // Determine connection type
                if path.usesInterfaceType(.wifi) {
                    self?.connectionType = .wifi
                } else if path.usesInterfaceType(.cellular) {
                    self?.connectionType = .cellular
                } else if path.usesInterfaceType(.wiredEthernet) {
                    self?.connectionType = .wiredEthernet
                } else {
                    self?.connectionType = nil
                }
            }
        }

        monitor.start(queue: queue)
    }

    /// Check if device is online
    var isOnline: Bool {
        return isConnected
    }

    /// Check if device is offline
    var isOffline: Bool {
        return !isConnected
    }
}
