#!/bin/bash

set -e
set -o pipefail

# Install dependencies
cd "$WORK_DIR"
python -m pip install --upgrade pip

if [[ -n "$WORKLOAD_IDENTITY_PROVIDER" && -n "$SERVICE_ACCOUNT" ]]; then
  pip install keyrings.google
fi

pip install -r requirements.txt
pip install pytest pytest-cov

# Build and Run Unit test
pytest \
  --cov="$PACKAGE_NAME" \
  --cov-report=term \
  --cov-config=.coveragerc \
  --cov-fail-under="$COVERAGE_THRESHOLD" \
  -q | sed 's|src/||g' > coverage.txt

# Extract summary
echo "<!-- pytest-report for $PACKAGE_NAME -->" > summary.txt
COVERAGE=$(awk '/^TOTAL/ {print $(NF)}' coverage.txt | sed 's/%//')
if (( $(echo "$COVERAGE >= $COVERAGE_THRESHOLD" | bc -l) )); then
  echo "### ✅ Pytest & Coverage Report for $PACKAGE_NAME" >> summary.txt
else
  echo "### ❌ Pytest & Coverage Report for $PACKAGE_NAME" >> summary.txt
fi
echo '```' >> summary.txt
awk '/^Name.*Stmts.*Miss.*Cover/ {start=1} start' coverage.txt >> summary.txt
echo '```' >> summary.txt