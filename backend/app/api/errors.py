from flask import jsonify


def register_error_handlers(app):
    @app.errorhandler(400)
    def bad_request(error):
        return jsonify({"error": {"code": "bad_request", "message": str(error)}}), 400

    @app.errorhandler(ValueError)
    def invalid_value(error):
        return jsonify({"error": {"code": "invalid_value", "message": str(error)}}), 400

    @app.errorhandler(401)
    def unauthorized(error):
        return jsonify({"error": {"code": "unauthorized", "message": str(error)}}), 401

    @app.errorhandler(403)
    def forbidden(error):
        return jsonify({"error": {"code": "forbidden", "message": str(error)}}), 403

    @app.errorhandler(404)
    def not_found(error):
        return jsonify({"error": {"code": "not_found", "message": str(error)}}), 404

    @app.errorhandler(500)
    def server_error(error):
        return jsonify({"error": {"code": "server_error", "message": "Unexpected server error"}}), 500
