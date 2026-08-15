from typing import Dict, Set, Optional

added_lines: Dict[str, Set[int]] = {}
current_file: Optional[str] = None
coverage: Dict[str, Dict[str, int]] = {}
current_lcov_file: Optional[str] = None
with open("coverage/lcov.info", "r") as f:
    for line in f:
        line = line.strip()
        if line.startswith("SF:"):
            file_path = line[3:]
            for tracked_file in added_lines:
                if file_path.endswith(tracked_file):
                    current_lcov_file = tracked_file
                    break
            else:
                current_lcov_file = None
        elif line.startswith("DA:") and current_lcov_file:
            parts = line[3:].split(",")
            line_num = int(parts[0])
            hit = int(parts[1]) > 0
            if line_num in added_lines[current_lcov_file]:
                if current_lcov_file not in coverage:
                    coverage[current_lcov_file] = {"hit": 0, "total": 0}
                coverage[current_lcov_file]["total"] += 1
                if hit: coverage[current_lcov_file]["hit"] += 1

total_hits = 0
total_lines = 0
for file, cov in coverage.items():
    if cov["total"] > 0:
        total_hits += cov["hit"]
        total_lines += cov["total"]

if total_lines > 0:
    print(f"TOTAL NEW CODE COVERAGE: {(total_hits/total_lines)*100:.2f}% ({total_hits}/{total_lines})")
