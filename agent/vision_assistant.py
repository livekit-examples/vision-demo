import asyncio
import logging
from typing import Optional

from livekit.agents import (
    AutoSubscribe,
    JobContext,
    llm,
    multimodal,
)
from livekit.plugins import google, noise_cancellation
from livekit.rtc import Track, TrackKind, VideoStream

logger = logging.getLogger("vision-assistant")

SPEAKING_FRAME_RATE = 1.0  # frames per second when speaking
NOT_SPEAKING_FRAME_RATE = 0.5  # frames per second when not speaking
JPEG_QUALITY = 80

_SYSTEM_PROMPT = """
You are a helpful voice and video assistant. Your user is interacting with you via a smartphone app and may speak by using their microphone.

They may also, if they choose, share video with you.  This will be either their camera or their smartphone's screen. It is up to the user whether or not to share their video.

Your responses should be concise, friendly, and engaging. 

# App UX

You may provide tips about using the app to assist the user. The app has a simple interface with four buttons along the bottom, from left to right:
- A microphone button to enable or disable the user's microphone
- A camera button to enable or disable the user's camera
- A screen button to enable or disable the user's screen share
- An X button to end the call

When the user shares their camera, they will see the video feed in the app and can switch from the front to back camera by tapping the rotate camera button. 

When the user shares their screen, no video feed is shown but a recording status indicator will appear in their phone's status bar.

Note that the user may only share one video feed at a time, so if they start one the other will automatically end. 

Additionally, the user is free to move the app to the background. Both audio and screenshare will continue to work while in the background, although camera access will stop.

# Your background

If asked about yourself, you should identify yourself as "Viz", the helpful video assistant. You may reference the following background information, in addition to your capabilities previously listed:
- You were created by LiveKit (pronounced "live-kit", where "live" rhymes with "alive") as a free tech demo. 
- LiveKit is a leading proivider of open-source tools for building realtime AI applications, including their LiveKit Agents framework and their LiveKit WebRTC stack. Users can find out more at https://livekit.io.
- Your intelligence is provided by the Gemini Live API from Google.
"""


class VisionAssistant:
    def __init__(self):
        self.agent: Optional[multimodal.MultimodalAgent] = None
        self.model: Optional[google.beta.realtime.RealtimeModel] = None
        self._is_user_speaking: bool = False

    async def start(self, ctx: JobContext):
        """Initialize and start the vision assistant."""
        await ctx.connect(auto_subscribe=AutoSubscribe.SUBSCRIBE_ALL)
        participant = await ctx.wait_for_participant()

        chat_ctx = llm.ChatContext()
        self.model = google.beta.realtime.RealtimeModel(
            voice="Puck",
            temperature=0.8,
            instructions=_SYSTEM_PROMPT,
        )

        self.agent = multimodal.MultimodalAgent(
            model=self.model,
            chat_ctx=chat_ctx,
            noise_cancellation=noise_cancellation.BVC(),
        )
        self.agent.start(ctx.room, participant)

        # Add event handlers for user speaking state
        self.agent.on("user_started_speaking", self._on_user_started_speaking)
        self.agent.on("user_stopped_speaking", self._on_user_stopped_speaking)

        ctx.room.on(
            "track_subscribed",
            lambda track, pub, participant: asyncio.create_task(
                self._handle_video_track(track)
            )
            if track.kind == TrackKind.KIND_VIDEO
            else None,
        )

    async def _handle_video_track(self, track: Track):
        """Handle incoming video track and send frames to the model."""
        logger.info("Handling video track")
        video_stream = VideoStream(track)
        last_frame_time = 0
        frame_counter = 0

        async for event in video_stream:
            current_time = asyncio.get_event_loop().time()

            if current_time - last_frame_time < self._get_frame_interval():
                continue

            last_frame_time = current_time
            frame = event.frame

            frame_counter += 1

            try:
                self.model.sessions[0].push_video(frame)
                logger.info(f"Queued frame {frame_counter}")
            except Exception as e:
                logger.error(f"Error queuing frame {frame_counter}: {e}")

        await video_stream.aclose()

    def _get_frame_interval(self) -> float:
        """Get the interval between frames based on speaking state."""
        return 1.0 / (
            SPEAKING_FRAME_RATE if self._is_user_speaking else NOT_SPEAKING_FRAME_RATE
        )

    def _on_user_started_speaking(self):
        """Handler for when user starts speaking."""
        self._is_user_speaking = True
        logger.debug("User started speaking")

    def _on_user_stopped_speaking(self):
        """Handler for when user stops speaking."""
        self._is_user_speaking = False
        logger.debug("User stopped speaking")
