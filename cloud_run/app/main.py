# Copyright (C) 2025 Google Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may not
# use this file except in compliance with the License. You may obtain a copy of
# the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations under
# the License.

import os
import time
import logging
from flask import Flask, Response, request, jsonify
from typing import Iterator, Dict, Any

app = Flask(__name__)
logging.basicConfig(level=logging.INFO)

@app.route("/", methods=['POST'])
def hello_world() -> Response:
    """Handles POST requests and returns a streaming response."""
    try:
        data: Dict[str, Any] = request.get_json()
        if not isinstance(data, dict):
            logging.error(f"Invalid JSON payload: {data}")
            return jsonify({"error": "Invalid JSON payload"}), 400
    except Exception as e:
        logging.error(f"Error parsing JSON: {e}")
        return jsonify({"error": "Error parsing JSON"}), 400

    def generate() -> Iterator[str]:
        """Generates a streaming response."""
        for i in range(5):
            message = f"Hello {data.get('data', 'World')} {i}!\n"
            logging.info(f"Sending chunk: {message.strip()}")
            yield message
            time.sleep(1)

    return Response(generate(), mimetype='text/plain')

if __name__ == "__main__":
    app.run(debug=True, host="0.0.0.0", port=int(os.environ.get("PORT", 8080)))
