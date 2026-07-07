---
tier: execution
model: sonnet
---

Generate integration or unit tests for a function or file, following the exact patterns of the project.

Target: $ARGUMENTS  (file path, function name, or "file.py::function_name")

## Steps

### 1. Parse the target
- If `$ARGUMENTS` is `path/to/file.py::function_name`, read that specific function
- If it's just a file path, read the whole file and identify the main functions/classes
- If it's a function name only, search for it: `grep -rn "def $ARGUMENTS" .`

### 2. Understand the function
Read the function and its direct dependencies:
- What does it do?
- What are the inputs and outputs?
- What external calls does it make (DB, Kafka, HTTP, file system)?
- What are the failure modes?

### 3. Find existing test patterns in this project
Search for tests in the same module:
```bash
find . -path "*/tests*" -name "test_$(basename $FILE_PATH)" 2>/dev/null
find . -path "*/tests*" -name "test_*$(dirname $FILE_PATH | xargs basename)*" 2>/dev/null
```
Read 1-2 existing test files in the same area to understand:
- What test framework is used (pytest, unittest)?
- How are fixtures defined and named?
- How are factories used (AgentFactory, UsersFactory, etc.)?
- How deep are mocks — do they mock at the module boundary or go deeper?
- What helper functions exist (e.g. `post()`, `mock_delay()`)?
- What assertion style is preferred?

### 4. Identify what to test
For each function, define test cases:
- **Happy path** — normal inputs, expected output
- **Edge cases** — empty, None, zero, boundary values
- **Error cases** — missing required fields, invalid types, external service failures
- **Integration** — if it touches DB or Kafka, test the actual side effect

Skip test cases that test the framework rather than your code. Don't add tests for lines that can't fail.

### 5. Generate the tests
Write the test file following the project's exact patterns:
- Use the same import style
- Use the same fixture names and factories
- Mock at the same layer as existing tests in this project
- Name tests: `test_<function_name>_<scenario>` (e.g. `test_emit_event_includes_tracking_uuid`)
- Each test should have ONE clear assertion focus

### 6. Output and placement
- Print the full test file
- State where it should be saved (follow the project's test directory structure)
- If a test file already exists for this module, show only the new test functions to append

### 7. Run the tests (if in a project with a test runner)
```bash
# Try to detect and run the tests
pytest <test_file_path> -v 2>/dev/null \
  || python -m pytest <test_file_path> -v 2>/dev/null \
  || echo "Run tests manually: pytest <test_file_path>"
```
If tests fail, read the error, fix the issue, and try once more.
