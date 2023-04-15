import os
import subprocess

RENDER_DIR = "render-100x100"
for listing in os.listdir(RENDER_DIR):
    if not os.path.isfile(os.path.join(RENDER_DIR, listing)):
        continue
    subprocess.run(["python", "scheme", "--pillow-turtle", "--turtle-save-path", "output")
