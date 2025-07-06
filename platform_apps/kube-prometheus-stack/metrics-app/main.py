# main.py
from fastapi import FastAPI, Request, Response, status
import time
import random
import os
from prometheus_client import Histogram, Counter, generate_latest, CONTENT_TYPE_LATEST

app = FastAPI()

# Load ENV-based delay configs
USER_MIN = float(os.getenv("USER_MIN", 0.1))
USER_MAX = float(os.getenv("USER_MAX", 0.4))
ORDER_MIN = float(os.getenv("ORDER_MIN", 0.1))
ORDER_MAX = float(os.getenv("ORDER_MAX", 0.6))
PAYMENT_MIN = float(os.getenv("PAYMENT_MIN", 0.2))
PAYMENT_MAX = float(os.getenv("PAYMENT_MAX", 0.5))

# Metrics
REQUEST_COUNT = Counter(
    'http_requests_total', 'Total HTTP requests', ['method', 'endpoint', 'http_status']
)

REQUEST_LATENCY = Histogram(
    'http_request_duration_seconds', 'HTTP request latency', ['method', 'endpoint']
)

# Middleware for metrics
@app.middleware("http")
async def metrics_middleware(request: Request, call_next):
    start_time = time.time()
    response = await call_next(request)
    request_latency = time.time() - start_time

    endpoint = request.url.path
    method = request.method
    status_code = response.status_code

    REQUEST_COUNT.labels(method=method, endpoint=endpoint, http_status=status_code).inc()
    REQUEST_LATENCY.labels(method=method, endpoint=endpoint).observe(request_latency)

    return response

# API endpoints
@app.get("/api/user")
def get_user():
    time.sleep(random.uniform(USER_MIN, USER_MAX))
    return {"user": "John Doe"}

@app.get("/api/order")
def get_order():
    time.sleep(random.uniform(ORDER_MIN, ORDER_MAX))
    return {"order": "order-123"}

@app.get("/api/payment")
def get_payment():
    # Simulate 20% error rate
    if random.random() < 0.2:
        return Response(content="Error", status_code=status.HTTP_500_INTERNAL_SERVER_ERROR)
    time.sleep(random.uniform(PAYMENT_MIN, PAYMENT_MAX))
    return {"payment": "paid"}

@app.get("/metrics")
def metrics():
    return Response(generate_latest(), media_type=CONTENT_TYPE_LATEST)

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
