import SwiftUI

struct ConnectionView: View {
    @EnvironmentObject private var chatContext: ChatContext

    @State private var isConnecting: Bool = false
    private var tokenService: TokenService = .init()

    var body: some View {
        if chatContext.isConnected {
            ChatView()
        } else {
            VStack(spacing: 24) {
                Text("LiveKit Vision Demo")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text(
                    "A sample project showcasing the Gemini Multimodal Live API with realtime audio and video."
                )
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal)

                Button(action: {
                    Task {
                        isConnecting = true

                        let roomName = "room-\(Int.random(in: 1000 ... 9999))"
                        let participantName = "user-\(Int.random(in: 1000 ... 9999))"

                        do {
                            let connectionDetails = try await tokenService.fetchConnectionDetails(
                                roomName: roomName,
                                participantName: participantName
                            )

                            try await chatContext.connect(
                                url: connectionDetails.serverUrl,
                                token: connectionDetails.participantToken
                            )
                        } catch {
                            print("Connection error: \(error)")
                        }
                        isConnecting = false
                    }
                }) {
                    Text("Connect")
                        .font(.headline)
                        .frame(maxWidth: 280)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(isConnecting)

                Link("View Source", destination: URL(string: "https://github.com/livekit-examples/vision-demo")!)
                    .font(.caption)
                    .padding(.top, 8)
            }
            .padding()
        }
    }
}
