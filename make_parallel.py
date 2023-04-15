import re
import os
import subprocess
import combine_images
import time

scheme_file = "contest.scm"
output_dir = "render-test"
# Equal to height segments in scheme file
num_processes = 2

segment_index_pattern = re.compile(r"^(\t| )*\(define height-segment-index \d+\)$", re.MULTILINE)
segment_count_pattern = re.compile(r"^(\t| )*\(define height-segments \d+\)$", re.MULTILINE)

base_file_text = ""
with open(scheme_file, "r") as base_file:
    base_file_text = base_file.read()

if not os.path.exists(output_dir):
    os.mkdir(output_dir)

started_processes: list[subprocess.Popen] = []

for i in range(num_processes):
    new_file_text = re.sub(segment_index_pattern, f"(define height-segment-index {i})", base_file_text)
    new_file_text = re.sub(segment_count_pattern, f"(define height-segments {num_processes})", new_file_text)

    new_file_name = os.path.join(output_dir, f"contest{i}.scm")
    with open(new_file_name, "w") as out_file:
        out_file.write(new_file_text)
    # Should properly close files
    progress_out_file = open(new_file_name + ".log", "w")
    new_process = subprocess.Popen(["python", "scheme", new_file_name, "--pillow-turtle", "--turtle-save-path", os.path.join(output_dir, f"output{i}")], stdout=progress_out_file)
    started_processes.append(new_process)

render_start_time = time.perf_counter()
print("Starting", num_processes, "processes")
for process in started_processes:
    process.wait()
render_end_time = time.perf_counter()
print(f"Rendering complete in {render_end_time - render_start_time} seconds")

combine_images.combine_images(num_processes, output_dir)
print("Images merged")