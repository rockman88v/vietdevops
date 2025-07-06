# client.py
import os
import time
import threading
import requests

API_HOST = os.getenv("API_HOST", "http://metrics-app:80")
USER_INTERVAL = float(os.getenv("USER_INTERVAL", "2"))
ORDER_INTERVAL = float(os.getenv("ORDER_INTERVAL", "3"))
PAYMENT_INTERVAL = float(os.getenv("PAYMENT_INTERVAL", "5"))

def loop_call(path, interval):
    while True:
        try:
            r = requests.get(f"{API_HOST}{path}", timeout=5)
            print(f"{path} -> {r.status_code}")
        except Exception as e:
            print(f"{path} -> ERROR: {e}")
        time.sleep(interval)

threading.Thread(target=loop_call, args=("/api/user", USER_INTERVAL), daemon=True).start()
threading.Thread(target=loop_call, args=("/api/order", ORDER_INTERVAL), daemon=True).start()
threading.Thread(target=loop_call, args=("/api/payment", PAYMENT_INTERVAL), daemon=True).start()

while True:
    time.sleep(60)
