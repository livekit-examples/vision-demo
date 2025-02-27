import logging

from dotenv import load_dotenv
from livekit.agents import (
    JobContext,
    WorkerOptions,
    cli,
)

from vision_assistant import VisionAssistant

load_dotenv()

logger = logging.getLogger("vision-assistant")
logger.setLevel(logging.INFO)

async def entrypoint(ctx: JobContext):
    assistant = VisionAssistant()
    await assistant.start(ctx)

if __name__ == "__main__":
    cli.run_app(WorkerOptions(entrypoint_fnc=entrypoint))
