from fastapi import FastAPI
from pydantic import BaseModel
from fastapi.middleware.cors import CORSMiddleware
import requests
import os
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

HF_API_TOKEN = os.getenv("HF_API_TOKEN")

app = FastAPI()

# Enable CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# Request model
class MessageRequest(BaseModel):
    message: str
    src_lang: str  # Source language (like 'fr_XX')
    tgt_lang: str  # Target language (like 'en_XX')

@app.post("/correct")
async def correct_message(request: MessageRequest):
    model = "facebook/mbart-large-50-many-to-many-mmt"
    api_url = f"https://api-inference.huggingface.co/models/{model}"
    headers = {"Authorization": f"Bearer {HF_API_TOKEN}"}

    payload = {
        "inputs": request.message,
        "parameters": {
            "src_lang": request.src_lang,
            "tgt_lang": request.tgt_lang
        }
    }

    try:
        response = requests.post(api_url, headers=headers, json=payload)
        if response.status_code == 200:
            result = response.json()
            if result and isinstance(result, list) and 'translation_text' in result[0]:
                corrected_text = result[0]['translation_text']
                return {
                    "corrected": corrected_text.strip(),
                    "explanation": "Corrected using MBART model",
                    "suggestion": "Keep practicing for fluency!"
                }
            else:
                return {"error": "Model did not return expected result."}
        else:
            return {"error": response.json()}
    except Exception as e:
        return {"error": str(e)}