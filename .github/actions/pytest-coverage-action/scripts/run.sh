#!/bin/bash

set -e
set -o pipefail

# Install dependencies
python -m pip install --upgrade pip

# Check for auth variables and install dependencies accordingly
if [[ -n "$WORKLOAD_IDENTITY_PROVIDER" && -n "$SERVICE_ACCOUNT" ]]; then
  echo "Auth variables detected. Installing with Artifact Registry."
  python -m pip install keyring keyrings.google-artifactregistry-auth
  python -m pip install --extra-index-url https://us-central1-python.pkg.dev/etsy-xscitools-dev/experimentation-pypi/simple $(printf -- '-r %s ' requirements*.txt)
else
  echo "No auth variables detected. Installing from standard index."
  python -m pip install $(printf -- '-r %s ' requirements*.txt)
fi


python -m pip install pytest pytest-cov pytest-pythonpath

# Build and Run Unit test

pytest --cov-report=term --cov-config=.coveragerc --cov-fail-under="$COVERAGE_THRESHOLD"  -vv --show-capture=all  -o log_cli=true -o log_cli_level=DEBUG | sed 's|src/||g' | tee coverage.txt

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
