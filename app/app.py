from flask import Flask, jsonify
from prometheus_client import Counter, Histogram, generate_latest, CONTENT_TYPE_LATEST
import time
import os

app = Flask(__name__)

# Prometheus metrics
REQUEST_COUNT = Counter(
    "app_requests_total", "Total number of requests", ["endpoint", "method", "status"]
)
REQUEST_LATENCY = Histogram(
    "app_request_latency_seconds", "Request latency in seconds", ["endpoint"]
)

APP_VERSION = os.environ.get("APP_VERSION", "1.0.0")


@app.route("/")
def index():
    start = time.time()
    resp = jsonify({
        "message": "DevOps demo app is running",
        "version": APP_VERSION
    })
    REQUEST_LATENCY.labels(endpoint="/").observe(time.time() - start)
    REQUEST_COUNT.labels(endpoint="/", method="GET", status="200").inc()
    return resp


@app.route("/health")
def health():
    # Used by Kubernetes liveness/readiness probes
    REQUEST_COUNT.labels(endpoint="/health", method="GET", status="200").inc()
    return jsonify({"status": "healthy"}), 200


@app.route("/metrics")
def metrics():
    # Scraped by Prometheus
    return generate_latest(), 200, {"Content-Type": CONTENT_TYPE_LATEST}


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
