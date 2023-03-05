from flask import Flask, request, render_template

app = Flask(__name__)
boolean_value = False


@app.route('/', methods=['GET', 'POST'])
def index():
    return render_template('index.html', bool_value=boolean_value)


@app.route('/H', methods=['GET', 'POST'])
def index_h():
    global boolean_value
    if request.method == 'GET':
        boolean_value = True
    return render_template('index-h.html')


@app.route('/L', methods=['GET', 'POST'])
def index_l():
    global boolean_value
    if request.method == 'GET':
        boolean_value = False
    return render_template('index-l.html')


@app.before_request
def log_request_info():
    app.logger.info('Request: %s %s %s', request.method,
                    request.url, request.form)


@app.after_request
def add_header(response):
    response.cache_control.max_age = 0
    return response


if __name__ == '__main__':
    app.run(debug=True)
