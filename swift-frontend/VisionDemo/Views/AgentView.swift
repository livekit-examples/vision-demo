import LiveKit
import LiveKitComponents
import SwiftUI

struct AgentView: View {
    @EnvironmentObject var chatContext: ChatContext
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            if let agent = chatContext.agentParticipant {
                AgentAudioVisualizer(agent: agent)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct AgentAudioVisualizer: View {
    @EnvironmentObject var room: Room
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject var agent: RemoteParticipant
    
    private var barSpacing: CGFloat { room.localParticipant.isCameraEnabled() ? 4 : 12}

    var body: some View {
        GeometryReader { geometry in
            let availableWidth = geometry.size.width - (barSpacing * 2)
            let barWidth = (availableWidth - (4 * barSpacing)) / 5
            let computedSpacingFactor = barSpacing / availableWidth

            ZStack {
                if let track = agent.firstAudioTrack {
                    BarAudioVisualizer(
                        audioTrack: track,
                        barColor: colorScheme == .dark ? .white : .black,
                        barCount: 5,
                        barSpacingFactor: computedSpacingFactor,
                        barMinOpacity: 1
                    )
                    .frame(width: availableWidth, height: availableWidth)
                } else {
                    Circle()
                        .fill(.blue)
                        .frame(width: barWidth, height: barWidth)
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
    }
}

#Preview {
    AgentView()
        .environmentObject(ChatContext())
}
