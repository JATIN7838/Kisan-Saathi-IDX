import pyaudio
import wave,os
from openai import OpenAI
import dotenv
dotenv.load_dotenv()
FORMAT = pyaudio.paInt16
CHANNELS = 1
RATE = 48000
CHUNK = 1024
FILENAME = "audio.wav"


class VoiceRecorder:
    def __init__(self, api_key):
        self.audio = pyaudio.PyAudio()
        self.client=OpenAI(api_key=api_key)
        self.frames = []

    def start_recording(self):
        self.stream = self.audio.open(format=FORMAT, channels=CHANNELS, rate=RATE, input=True, frames_per_buffer=CHUNK)
        self.frames = []
        print("Recording started...")

    def stop_recording(self):
        self.stream.stop_stream()
        self.stream.close()
        print("Recording stopped.")
        with wave.open(FILENAME, "wb") as wf:
            wf.setnchannels(CHANNELS)
            wf.setsampwidth(self.audio.get_sample_size(FORMAT))
            wf.setframerate(RATE)
            wf.writeframes(b"".join(self.frames))
        print(f"Audio saved as {FILENAME}")

    def record_audio(self):
        try:
            data = self.stream.read(CHUNK, exception_on_overflow=False)
            self.frames.append(data)
        except Exception as e:
            print(f"Error during recording: {e}")

    def cleanup(self):
        self.audio.terminate()

    def translate_audio(self):
        with open(FILENAME, "rb") as audio_file:
            response = self.client.audio.translations.create(
                model="whisper-1",
                file=audio_file)
        os.remove(FILENAME)
        return response.text
