from time import sleep
from flask import Flask, render_template
import sys

logname = sys.argv[1]

app = Flask(__name__)

@app.route('/')
def index():
    return render_template('index.html')

@app.route('/stream')
def stream():
    def generate():
        with open(logname) as f:
            while True:
                yield f.read()
                sleep(1)

    return app.response_class(generate(), mimetype='text/plain')

app.run()