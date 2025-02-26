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
    @State private var pulse = false
    @State private var animateVisualizer = false
    private let barSpacingFactor: CGFloat = 0.035
    private let barCount: CGFloat = 5

    var body: some View {
        GeometryReader { geometry in
            let totalSpacing = geometry.size.width * barSpacingFactor * (barCount + 2)
            let barWidth = (geometry.size.width - totalSpacing) / barCount

            ZStack {
                if let track = agent.firstAudioTrack {
                    BarAudioVisualizer(
                        audioTrack: track,
                        barColor: colorScheme == .dark ? .white : .black,
                        barCount: Int(barCount),
                        barSpacingFactor: barSpacingFactor,
                        barMinOpacity: 1
                    )
                    .frame(width: geometry.size.width, height: geometry.size.width)
                    .opacity(animateVisualizer ? 1 : 0)
                    .animation(.easeInOut(duration: 0.5), value: animateVisualizer)
                    .onAppear {
                        animateVisualizer = true
                    }

                    Circle()
                        .fill(colorScheme == .dark ? .white : .black)
                        .frame(width: barWidth, height: barWidth)
                        .opacity(animateVisualizer ? 0 : (pulse ? 1 : 0.2))
                        .animation(.easeInOut(duration: 0.5), value: animateVisualizer)
                        .onAppear {
                            withAnimation(Animation.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
                                pulse.toggle()
                            }
                        }
                } else {
                    Circle()
                        .fill(colorScheme == .dark ? .white : .black)
                        .frame(width: barWidth, height: barWidth)
                        .opacity(pulse ? 1 : 0.2)
                        .animation(.easeInOut(duration: 0.5), value: pulse)
                        .onAppear {
                            withAnimation(Animation.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
                                pulse.toggle()
                            }
                        }
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
