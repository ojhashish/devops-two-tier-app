# backend/app.py
from flask import Flask, jsonify
from flask_cors import CORS # Added for CORS

app = Flask(__name__)
CORS(app) # Enable CORS for all origins (for local dev)

@app.route('/health')
def health_check():
    return jsonify({"status": "healthy"}), 200

@app.route('/api/message')
def get_message():
    return jsonify({"message": "Hello from the backend!"}), 200

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5001) # Backend listens on 5001



