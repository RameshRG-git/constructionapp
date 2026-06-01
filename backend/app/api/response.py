from flask import jsonify


def ok(data=None, status_code=200):
    payload = {} if data is None else data
    return jsonify(payload), status_code


def created(data=None):
    return ok(data, 201)
