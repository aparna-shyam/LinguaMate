from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from fastapi.middleware.cors import CORSMiddleware
from transformers import MBartForConditionalGeneration, MBart50TokenizerFast
from gtts import gTTS
import base64
import os
import logging
from io import BytesIO

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI()

# Enable CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# Load translation model
try:
    logger.info("Loading translation model...")
    model_name = "facebook/mbart-large-50-many-to-many-mmt"
    tokenizer = MBart50TokenizerFast.from_pretrained(model_name)
    model = MBartForConditionalGeneration.from_pretrained(model_name)
    logger.info("Model loaded successfully")
except Exception as e:
    logger.error(f"Model loading failed: {e}")
    raise RuntimeError("Could not load translation model")

class TranslationRequest(BaseModel):
    message: str
    src_lang: str  # e.g., "en_XX"
    tgt_lang: str  # e.g., "fr_XX"

def generate_audio_base64(text: str, lang: str) -> str:
    """Generate audio and return as base64 string"""
    try:
        # Create in-memory file
        audio_bytes = BytesIO()
        
        # Generate speech
        tts = gTTS(text=text, lang=lang[:2])  # Convert "fr_XX" to "fr"
        tts.write_to_fp(audio_bytes)
        audio_bytes.seek(0)
        
        # Encode to base64
        return base64.b64encode(audio_bytes.getvalue()).decode('utf-8')
        
    except Exception as e:
        logger.error(f"Audio generation failed: {e}")
        return ""

@app.post("/translate")
async def translate_text(request: TranslationRequest):
    try:
        # Validate languages
        if (request.src_lang not in tokenizer.lang_code_to_id or 
            request.tgt_lang not in tokenizer.lang_code_to_id):
            raise HTTPException(
                status_code=400,
                detail="Invalid language codes. Check supported languages."
            )

        # Perform translation
        tokenizer.src_lang = request.src_lang
        inputs = tokenizer(request.message, return_tensors="pt")
        generated_tokens = model.generate(
            **inputs,
            forced_bos_token_id=tokenizer.lang_code_to_id[request.tgt_lang]
        )
        translated_text = tokenizer.batch_decode(generated_tokens, skip_special_tokens=True)[0]

        # Generate audio
        audio_base64 = generate_audio_base64(translated_text, request.tgt_lang)

        return {
            "translation": translated_text,
            "audio": audio_base64,
            "success": True
        }

    except Exception as e:
        logger.error(f"Translation failed: {e}")
        raise HTTPException(status_code=500, detail=str(e))

# Health check endpoint
@app.get("/health")
async def health_check():
    return {"status": "ok"}