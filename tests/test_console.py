import subprocess
import time
import sys
from playwright.sync_api import sync_playwright

ROUTES = [
    "/",
    "/pricing",
    "/support",
    "/about",
    "/login",
    "/console",
    "/start",
    "/verify",
]


def run_checks():
    server = subprocess.Popen([sys.executable, "dev_server.py"], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    try:
        time.sleep(1)
        with sync_playwright() as p:
            browser = p.chromium.launch()
            context = browser.new_context()
            for route in ROUTES:
                page = context.new_page()
                errors = []
                page.on(
                    "console",
                    lambda msg: errors.append(msg) if msg.type in ("error", "warning") else None,
                )
                page.goto(f"http://localhost:8000{route}")
                if errors:
                    for msg in errors:
                        print(f"{route}: {msg.type} - {msg.text}")
                    raise SystemExit(f"JavaScript issues found on {route}")
            browser.close()
    finally:
        server.terminate()
        try:
            server.wait(timeout=5)
        except subprocess.TimeoutExpired:
            server.kill()


if __name__ == "__main__":
    run_checks()
