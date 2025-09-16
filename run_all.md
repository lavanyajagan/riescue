# run_all.sh — Test Runner Guide

This script automates running **Riescued tests** across different **ISS backends** (`spike`, `whisper`) and **CPU configuration files**.

Each test run is isolated into its own working directory under `workdir/`, with logs saved per run.

---

## Directory Layout

- **Tests** are expected in:  
  `riescue/dtest_framework/tests/<test>.s`

- **Configs** are expected in:  
  `riescue/dtest_framework/lib/<config>.json`

- **Work directories & logs** are created under:  
  `workdir/<test>_<iss>_<configTag>/`

---

## Usage

```bash
./run_all.sh [TEST_NAME] [ISS] [CONFIG]
```

- All three arguments are **optional**.
- If you omit them, the script runs **all tests × all ISS × all configs**.
- If you supply one or more, the run is narrowed accordingly.

---

## Arguments

1. **TEST_NAME**  
   - Name of the test (without `.s` suffix).  
   - Must be one of the listed `tests` in the script.  

2. **ISS**  
   - Instruction Set Simulator backend.  
   - Must be one of:  
     - `spike`  
     - `whisper`

3. **CONFIG**  
   - JSON config file name (with or without `.json`).  
   - Must be one of the listed `configs` in the script.

---

## Examples

### Run everything
```bash
./run_all.sh
```

### Run a single test across all ISS/configs
```bash
./run_all.sh test_vs
```

### Run all tests, but only on whisper
```bash
./run_all.sh "" whisper
```

### Run a single config across all tests/ISS
```bash
./run_all.sh "" "" whisper_config
```

### Run a precise combination
```bash
./run_all.sh test_vs spike whisper_config.json
```

---

## Output

- Console prints a summary for each run:
  ```
  >>> Running test: test_vs | ISS: spike | CONFIG: whisper_config.json
   test_template: test_vs | ISS: spike | CONFIG: whisper_config.json | PASSED
  ```

- Detailed logs are written to:
  ```
  workdir/test_vs_spike_whisper_config/test_vs_run.log
  ```

---

## Notes

- If a test `.s` file or config file is missing, the script **skips** it.  
- Run directories are recreated fresh for each run.  
- Logs are redirected to files — console stays clean. 
