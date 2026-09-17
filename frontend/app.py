"""
Flask Frontend Server for AeroMobility AI Environmental Intelligence System
Serves the web dashboard templates and static assets, proxying backend status checks.
"""

from flask import Flask, render_template, jsonify, request
import requests
import os

app = Flask(__name__, static_folder='static', template_folder='templates')

BACKEND_API_BASE = os.getenv("BACKEND_API_BASE", "http://127.0.0.1:8000")

@app.route('/')
def index():
    return render_template('index.html', backend_url=BACKEND_API_BASE)

@app.route('/health')
def health():
    try:
        res = requests.get(f"{BACKEND_API_BASE}/", timeout=3)
        return jsonify({"status": "online", "backend": res.json()})
    except Exception as e:
        return jsonify({"status": "offline", "error": str(e)}), 503

if __name__ == '__main__':
    print(f"Starting Flask Frontend Server on http://127.0.0.1:8080 (Connecting to FastAPI at {BACKEND_API_BASE}) ...")
    app.run(host='127.0.0.1', port=8080, debug=False)
