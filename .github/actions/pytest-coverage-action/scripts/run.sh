#!/bin/bash

set -e
set -o pipefail

# Install dependencies
cd "$WORK_DIR"
python -m pip install --upgrade pip

# Check for auth variables and install dependencies accordingly
if [[ -n "$WORKLOAD_IDENTITY_PROVIDER" && -n "$SERVICE_ACCOUNT" ]]; then
  echo "Auth variables detected. Installing with Artifact Registry."
  python -m pip install keyring keyrings.google-artifactregistry-auth
  python -m pip install --extra-index-url https://us-central1-python.pkg.dev/etsy-xscitools-dev/experimentation-pypi/simple -r requirements.txt
else
  echo "No auth variables detected. Installing from standard index."
  python -m pip install -r requirements.txt
fi

python -m pip install pytest pytest-cov

# Build and Run Unit test
pytest -v -rA \
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
