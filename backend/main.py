from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from fastapi.middleware.cors import CORSMiddleware
from transformers import pipeline
from gtts import gTTS
import base64
import logging
from io import BytesIO

# Configure loggingve
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

# Updated models (all publicly available)
MODELS = {
    "en": "vennify/t5-base-grammar-correction",
    "fr": "cmarkea/bloomz-560m-sft-chat",
    "es": "mrm8488/spanish-gpt2",
    "de": "oliverguhr/german-spelling-correction"
}

# Load all models
correctors = {}
try:
    logger.info("Loading language models...")
    for lang, model in MODELS.items():
        task = "text2text-generation" if lang != "es" else "text-generation"
        correctors[lang] = pipeline(
            task,
            model=model,
            device="cpu"
        )
    logger.info("All models loaded successfully")
except Exception as e:
    logger.error(f"Model loading failed: {e}")
    raise RuntimeError(f"Could not load models: {str(e)}")

class CorrectionRequest(BaseModel):
    text: str
    language: str  # "en", "fr", "es", or "de"

def generate_audio_base64(text: str, lang: str) -> str:
    """Generate audio and return as base64 string"""
    try:
        audio_bytes = BytesIO()
        tts = gTTS(text=text, lang=lang)
        tts.write_to_fp(audio_bytes)
        audio_bytes.seek(0)
        return base64.b64encode(audio_bytes.getvalue()).decode('utf-8')
    except Exception as e:
        logger.error(f"Audio generation failed: {e}")
        return ""

@app.post("/correct")
async def correct_text(request: CorrectionRequest):
    try:
        # Validate language
        if request.language not in correctors:
            raise HTTPException(
                status_code=400,
                detail=f"Unsupported language. Choose from: {list(MODELS.keys())}"
            )

        # Language-specific prompts
        prompts = {
            "en": f"grammar correction: {request.text}",
            "fr": f"Corrige la grammaire française: {request.text}",
            "es": f"Corrige la grammaire española: {request.text}",
            "de": f"Korrigiere die deutsche Grammatik: {request.text}"
        }

        # Get correction
        result = correctors[request.language](prompts[request.language], max_length=1024)
        corrected_text = result[0]['generated_text'] if request.language != "es" else result[0]['generated_text'].split('\n')[0]

        # Generate audio
        audio_base64 = generate_audio_base64(corrected_text, request.language)

        return {
            "original": request.text,
            "corrected": corrected_text,
            "audio": audio_base64,
            "success": True
        }

    except Exception as e:
        logger.error(f"Correction failed: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/languages")
async def get_supported_languages():
    return {"supported_languages": list(MODELS.keys())}

@app.get("/health")
async def health_check():
    return {"status": "ok"}