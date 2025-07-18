from flask import Flask, request, send_file, jsonify
from flask_cors import CORS
from src.python.processing import Processing
from src.python.settings import PATH
from src.python.utils import get_time_window

app = Flask(__name__)
CORS(app, origins=["https://heat-islands-app.onrender.com"])

@app.route("/suhi", methods=["GET"])
def suhi_endpoint():
    city = request.args.get("city")

    try:
        start, end = get_time_window()
        processing = Processing(city, start, end)
        processing.process(PATH)

        return send_file(f'{PATH}/SUHIs.tif', as_attachment=True)

    except Exception as e:
        return jsonify({"error": str(e)}), 500

if __name__ == "__main__":
    app.run(debug=True)
