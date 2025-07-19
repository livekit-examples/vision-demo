import AVFoundation
import Foundation
import LiveKit
import SwiftUI

@MainActor
class ChatContext: ObservableObject {
    @Published var room: Room = .init()
    @Published private(set) var isConnected: Bool = false
    @Published private(set) var agentParticipant: RemoteParticipant?

    var cameraDimensions: Dimensions {
#if os(visionOS)
        return Dimensions(width: 600, height: 400)
#else
        let screen = UIScreen.main
        let availableWidth = screen.bounds.width - 48
        let availableHeight = screen.bounds.height - 320

        let width = min(Int32(availableWidth * screen.scale), 1080)
        let height = min(Int32(availableHeight * screen.scale), 1920)

        return Dimensions(width: width & ~1, height: height & ~1)
#endif
    }

    init() {
        room.add(delegate: self)
    }

    func disconnect() async {
        await room.disconnect()
        room = Room()
        room.add(delegate: self)
        isConnected = false
        agentParticipant = nil
    }

    func connect(url: String, token: String) async throws {
        try await room.connect(url: url, token: token)
        try await room.localParticipant.setMicrophone(enabled: true)
        isConnected = true
    }

    private func updateAgent() {
        for participant in room.remoteParticipants.values where participant.kind == .agent {
            agentParticipant = participant
            return
        }

        agentParticipant = nil
    }

    weak var arCameraTrack: LocalTrackPublication?

    func setCamera(enabled: Bool) async throws {
#if os(visionOS)
        if enabled {
            let track = LocalVideoTrack.createARCameraTrack()
            arCameraTrack = try await room.localParticipant.publish(videoTrack: track)
        } else if let arCameraTrack {
            try await room.localParticipant.unpublish(publication: arCameraTrack)
            self.arCameraTrack = nil
        }

#else
        guard let device = AVCaptureDevice.devices().first(where: { $0.facingPosition == .back }) ?? AVCaptureDevice
            .devices().first
        else {
            throw NSError(domain: "CameraError", code: -1, userInfo: [NSLocalizedDescriptionKey: "No camera available"])
        }

        try await room.localParticipant.setCamera(
            enabled: enabled,
            captureOptions: CameraCaptureOptions(
                device: device,
                dimensions: Dimensions(width: cameraDimensions.height, height: cameraDimensions.width)
            )
        )
#endif
    }
}

extension ChatContext: RoomDelegate {
    nonisolated func room(_ room: Room, participantDidConnect participant: RemoteParticipant) {
        Task { @MainActor in
            if participant.kind == .agent, agentParticipant == nil {
                agentParticipant = participant
            }
        }
    }

    nonisolated func room(_ room: Room, participantDidDisconnect participant: RemoteParticipant) {
        Task { @MainActor in
            if participant == agentParticipant {
                updateAgent()
            }
        }
    }
}

struct ChatContextProvider<Content: View>: View {
    @StateObject private var context: ChatContext
    private let content: () -> Content

    init(@ViewBuilder content: @escaping () -> Content) {
        _context = StateObject(wrappedValue: ChatContext())
        self.content = content
    }

    var body: some View {
        content()
            .environmentObject(context)
            .environmentObject(context.room)
    }
}
