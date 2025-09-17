from flask import Flask, jsonify, render_template_string

app = Flask(__name__)

@app.route("/")
def home():
    html_content = """
    <!DOCTYPE html>
    <html>
    <head>
        <title>Docker Flask App</title>
        <style>
            body {
                font-family: Arial, sans-serif;
                text-align: center;
                background-color: #f4f4f4;
                margin: 0;
                padding: 0;
            }
            .container {
                margin-top: 100px;
            }
            h1 {
                color: #333;
            }
            p {
                font-size: 18px;
                color: #555;
            }
        </style>
    </head>
    <body>
        <div class="container">
            <h1>Hello from Docker! nth Time</h1>
            <p>This page is served using Flask inside Docker.</p>
        </div>
    </body>
    </html>
    """
    return render_template_string(html_content)

@app.route("/health")
def health():
    return jsonify(status="OK")

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=True)
