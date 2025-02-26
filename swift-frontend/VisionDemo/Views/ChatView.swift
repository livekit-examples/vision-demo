import LiveKit
import LiveKitComponents
import SwiftUI

struct ChatView: View {
    @EnvironmentObject var chatContext: ChatContext
    @EnvironmentObject var room: Room
    @State private var animateActionBar = false

    var body: some View {
        ZStack(alignment: room.localParticipant.isCameraEnabled() ? .top : .center) {
            VStack(alignment: .center) {
                Spacer()

                CameraView()
                    .frame(
                        width: CGFloat(chatContext.cameraDimensions.width) / UIScreen.main.scale,
                        height: CGFloat(chatContext.cameraDimensions.height) / UIScreen.main.scale
                    )
                    .opacity(room.localParticipant.isCameraEnabled() ? 1 : 0)
                    .animation(.snappy, value: room.localParticipant.isCameraEnabled())

                ActionBarView()
                    .opacity(animateActionBar ? 1 : 0)
                    .offset(y: animateActionBar ? 0 : 10)
                    .animation(.easeOut(duration: 0.2), value: animateActionBar)
                    .onAppear {
                        animateActionBar = true
                    }
            }

            AgentView()
                .frame(
                    width: room.localParticipant.isCameraEnabled() ? 100 : UIScreen.main.bounds.width - 64,
                    height: room.localParticipant.isCameraEnabled() ? 100 : UIScreen.main.bounds.width - 64
                )
                .offset(y: room.localParticipant.isCameraEnabled() ? 0 : -40)
                .animation(.snappy, value: room.localParticipant.isCameraEnabled())
        }
    }
}
