#!/bin/env python3

from time import perf_counter
from subprocess import run

files_to_test: list[str] = [
    "benchmark-begin.scm",
    "benchmark-function-no-begin.scm",
]

PER_FILE_LOOP_COUNT = 3

if __name__ == "__main__":
    all_durations = []
    for file in files_to_test:
        file_duration: list[int] = []
        for i in range(PER_FILE_LOOP_COUNT):
            time_start = perf_counter()
            run(["python3", "scheme", file])
            time_end = perf_counter()
            file_duration.append(time_end - time_start)
        avg_time = sum(file_duration) / len(file_duration)
        print(f"Average time for {file}: {avg_time}")
        all_durations.append(avg_time)
    print("*****Results******")
    for file, duration in zip(files_to_test, all_durations):
        print(f"{file}: {duration}")
##### Findings
# Define ~1% faster than let
# And ~2% faster than if
# Inner define ~83% faster than mu procedure defined outside
# Vector dotproduct with helper (cadr, caddr, etc.) 25% slower than without helpers
# Creating vector dotproduct function with macro is 2% faster than with no helper
# If statement faster than or and constructs