from fastapi import FastAPI
from pydantic import BaseModel
from fastapi.middleware.cors import CORSMiddleware
from transformers import MBartForConditionalGeneration, MBart50TokenizerFast
from gtts import gTTS
import base64
import os

app = FastAPI()

# Enable CORS (allow Flutter app to connect)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Allows all origins (change in production)
    allow_methods=["*"],
    allow_headers=["*"],
)

# Load translation model (MBart-50)
model_name = "facebook/mbart-large-50-many-to-many-mmt"
tokenizer = MBart50TokenizerFast.from_pretrained(model_name)
model = MBartForConditionalGeneration.from_pretrained(model_name)

# Request model (what Flutter sends)
class MessageRequest(BaseModel):
    message: str  # User input (e.g., "Hello")
    src_lang: str  # Source language (e.g., "en_XX")
    tgt_lang: str  # Target language (e.g., "fr_XX")

# Generate audio from text
def generate_audio(text: str, lang: str) -> str:
    tts = gTTS(text=text, lang=lang[:2])  # Convert "fr_XX" → "fr"
    tts.save("temp.mp3")
    with open("temp.mp3", "rb") as f:
        audio_base64 = base64.b64encode(f.read()).decode('utf-8')
    os.remove("temp.mp3")
    return audio_base64

# Main endpoint (same as your Flutter app expects)
@app.post("/correct")
async def correct_message(request: MessageRequest):
    try:
        # Translate the text
        tokenizer.src_lang = request.src_lang  # This was the line with the error
        encoded = tokenizer(request.message, return_tensors="pt")
        generated_tokens = model.generate(**encoded, forced_bos_token_id=tokenizer.lang_code_to_id[request.tgt_lang])
        translated_text = tokenizer.batch_decode(generated_tokens, skip_special_tokens=True)[0]
        
        # Generate audio
        audio_base64 = generate_audio(translated_text, request.tgt_lang)

        return {
            "corrected": translated_text.strip(),
            "explanation": f"Translated from {request.src_lang} to {request.tgt_lang}",
            "suggestion": "Try using this in a full sentence!",
            "audio": audio_base64  # Base64 MP3 audio
        }
    except Exception as e:
        return {"error": str(e)}