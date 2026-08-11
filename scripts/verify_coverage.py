#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-only
# Copyright (C) 2024-2026 TUTODECODE Association <contact@tutodecode.org>
# Script: Code Coverage Verification Tool

import sys
import os

MIN_COVERAGE_PERCENT = 40.0

def calculate_lcov_coverage(lcov_path):
    if not os.path.exists(lcov_path):
        print(f"⚠️ Warning: lcov.info file not found at {lcov_path}. Skipping coverage enforcement.")
        return 100.0

    lines_found = 0
    lines_hit = 0

    with open(lcov_path, "r", encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if line.startswith("LF:"):
                lines_found += int(line.split(":")[1])
            elif line.startswith("LH:"):
                lines_hit += int(line.split(":")[1])

    if lines_found == 0:
        print("⚠️ Warning: No instrumented lines found in lcov.info.")
        return 100.0

    percentage = (lines_hit / lines_found) * 100.0
    return percentage

def main():
    lcov_file = sys.argv[1] if len(sys.argv) > 1 else "coverage/lcov.info"
    percentage = calculate_lcov_coverage(lcov_file)

    print(f"📊 Code Coverage Result: {percentage:.2f}% (Threshold: {MIN_COVERAGE_PERCENT:.1f}%)")

    if percentage < MIN_COVERAGE_PERCENT:
        print(f"❌ Error: Test coverage ({percentage:.2f}%) is below the required threshold of {MIN_COVERAGE_PERCENT:.1f}%!")
        sys.exit(1)
    else:
        print(f"✅ Code coverage check passed successfully ({percentage:.2f}%).")
        sys.exit(0)

if __name__ == "__main__":
    main()
