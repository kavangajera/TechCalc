from flask import Flask, request, jsonify
from differentiate import differentiate
from integrate import integrate

app = Flask(__name__)

@app.route('/differentiate', methods=['POST'])
def differentiate_route():
    data = request.json
    expression = data.get('expression')
    variable = data.get('variable')
    result = differentiate(expression, variable)
    return jsonify({'derivative': result})

@app.route('/integrate', methods=['POST'])
def integrate_route():
    data = request.json
    expression = data.get('expression')
    variable = data.get('variable')
    result = integrate(expression, variable)
    return jsonify({'integral': result})

if __name__ == '__main__':
    app.run(debug=True)
