from fastapi import FastAPI
from pydantic import BaseModel
from fastapi.middleware.cors import CORSMiddleware
from transformers import MBartForConditionalGeneration, MBart50TokenizerFast
import torch

app = FastAPI()

# Enable CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# Load model and tokenizer
model_name = "facebook/mbart-large-50-many-to-many-mmt"
tokenizer = MBart50TokenizerFast.from_pretrained(model_name)
model = MBartForConditionalGeneration.from_pretrained(model_name)

# Request body model
class MessageRequest(BaseModel):
    message: str
    src_lang: str  # Source language code (like "en_XX")
    tgt_lang: str  # Target language code (like "fr_XX")

@app.post("/correct")
async def correct_message(request: MessageRequest):
    try:
        # Set source language
        tokenizer.src_lang = request.src_lang

        # Tokenize and translate
        encoded = tokenizer(request.message, return_tensors="pt")
        generated_tokens = model.generate(**encoded, forced_bos_token_id=tokenizer.lang_code_to_id[request.tgt_lang])
        translated_text = tokenizer.batch_decode(generated_tokens, skip_special_tokens=True)[0]

        return {
            "corrected": translated_text.strip(),
            "explanation": f"Translated from {request.src_lang} to {request.tgt_lang}",
            "suggestion": "Try using different tenses and grammar structures for practice."
        }
    except Exception as e:
        return {"error": str(e)}