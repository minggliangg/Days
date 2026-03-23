//
//  DaysApp.swift
//  Days
//
//  Created by Ming Liang Khong on 23/3/26.
//

import SwiftUI
import SwiftData
import WidgetKit

@main
struct DaysApp: App {
    @State private var container: ModelContainer?
    @State private var containerError: Error?
    @State private var deepLinkDestination: DeepLinkDestination?

    var body: some Scene {
        WindowGroup {
            Group {
                if let container = container {
                    ContentView()
                        .modelContainer(container)
                        .environment(\.deepLinkDestination, deepLinkDestination)
                        .onReceive(NotificationCenter.default.publisher(for: .clearDeepLink)) { _ in
                            deepLinkDestination = nil
                        }
                } else if let error = containerError {
                    ErrorView(error: error) {
                        containerError = nil
                        tryInitializeContainer()
                    }
                } else {
                    ProgressView("Loading...")
                        .task { tryInitializeContainer() }
                }
            }
            .onOpenURL { url in
                handleDeepLink(url)
            }
        }
    }

    private func tryInitializeContainer() {
        do {
            container = try SharedModelContainer.initializeContainer()
        } catch {
            containerError = error
        }
    }

    private func handleDeepLink(_ url: URL) {
        guard url.scheme == "days" else { return }

        switch url.host {
        case "add":
            deepLinkDestination = .add
        case "countdown":
            if let idString = url.pathComponents.last,
               let id = UUID(uuidString: idString) {
                deepLinkDestination = .countdown(id: id)
            }
        case "occasion":
            if let idString = url.pathComponents.last,
               let id = UUID(uuidString: idString) {
                deepLinkDestination = .occasion(id: id)
            }
        default:
            break
        }
    }
}

enum DeepLinkDestination: Equatable {
    case add
    case countdown(id: UUID)
    case occasion(id: UUID)
}

extension Notification.Name {
    static let clearDeepLink = Notification.Name("ClearDeepLink")
}

struct DeepLinkDestinationKey: EnvironmentKey {
    static let defaultValue: DeepLinkDestination? = nil
}

extension EnvironmentValues {
    var deepLinkDestination: DeepLinkDestination? {
        get { self[DeepLinkDestinationKey.self] }
        set { self[DeepLinkDestinationKey.self] = newValue }
    }
}

struct ErrorView: View {
    let error: Error
    let retry: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("Failed to Load Data")
                .font(.headline)
            Text(error.localizedDescription)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("Retry") {
                retry()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}
