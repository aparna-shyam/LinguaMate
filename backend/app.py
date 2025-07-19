# ===== COPY FROM HERE =====
from flask import Flask, request, jsonify
from flask_cors import CORS
from gtts import gTTS
import os
import base64

# 👇 THESE ARE DOUBLE UNDERSCORES (no spaces between)
app = Flask(__name__)  # Note: TWO underscores before and after
CORS(app)

@app.route('/correct', methods=['POST'])
def correct_text():
    data = request.get_json()
    user_text = data['message']
    
    corrected_text = f"Correction: {user_text}"
    explanation = "Sample explanation"
    suggestion = "Try: Bonjour!"
    
    tts = gTTS(text=corrected_text, lang='fr')
    tts.save("temp.mp3")
    
    with open("temp.mp3", "rb") as f:
        audio_base64 = base64.b64encode(f.read()).decode('utf-8')
    os.remove("temp.mp3")
    
    return jsonify({
        'corrected': corrected_text,
        'explanation': explanation,
        'suggestion': suggestion,
        'audio': audio_base64
    })

#  👇 AGAIN, DOUBLE UNDERSCORES!
if __name__ == '_main_':
    app.run(host='0.0.0.0', port=8000, debug=True)
# ===== END COPY =====