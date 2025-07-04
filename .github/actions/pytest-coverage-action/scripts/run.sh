#!/bin/bash

set -e
set -o pipefail

# Install dependencies
python -m pip install --upgrade pip

if [[ -n "$WORKLOAD_IDENTITY_PROVIDER" && -n "$SERVICE_ACCOUNT" ]]; then
  python -m pip install keyring  keyrings.google-artifactregistry-auth
fi

python -m pip install -r requirements.txt
python -m pip install pytest pytest-cov pytest-pythonpath

# Build and Run Unit tests

#pytest
pytest --cov-report=term --cov-config=.coveragerc --cov-fail-under="$COVERAGE_THRESHOLD"  -q  | sed 's|src/||g' | tee coverage.txt

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