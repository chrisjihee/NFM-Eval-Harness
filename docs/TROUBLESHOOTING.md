# Troubleshooting notes

Last updated: 2026-06-27

> **Task name 정책 (rename).** 권장/기본 GSMA-compatible 그룹은
> `open_telco_otlite_gsma` / `open_telco_otfull_gsma`입니다(run 스크립트 기본값,
> `TASKS` 생략 시 실행). legacy lm-eval baseline은
> `open_telco_{otlite,otfull}_lm_eval_baseline`로 보존됩니다(diagnostic). bare
> `open_telco_otlite` / `open_telco_otfull`은 **실행 불가**입니다(run 스크립트가
> fail-fast로 거부). `*_mcgen`은 diagnostic(불변)입니다.

## 1. Public leaderboard score does not match local score

Expected. This repository is LM-Evaluation-Harness based, while the official GSMA stack is Inspect AI based.

Check:

- Are you running the GSMA-aligned group (`*_gsma`, default/recommended) or the legacy lm-eval baseline (`*_lm_eval_baseline`)?
- Are you comparing against the correct public row in `GSMA/leaderboard`?
- Is the model variant identical? Public row may say `gemma3-4b`; local may use `google/gemma-3-4b-it`.
- Is `--apply_chat_template` enabled or disabled?
- Are multiple-choice tasks scored by loglikelihood or generated answer extraction?
- Are generation parsers extracting correct answers?
- Is prompt truncation happening?

Use or add:

```bash
python scripts/compare_gsma_leaderboard.py --model gemma3-4b --local-result <result.json>
```

## 2. Left truncation warning

Known warning from previous HF run:

```text
Left truncation applied. Original sequence length was 2902, truncating to last 2024 tokens. Some content will be lost.
```

This may cause poor scores, especially for TeleLogs, TeleTables, and 3GPP excerpts.

Investigate:

- model/tokenizer max length inside lm-eval HF wrapper;
- whether `--model_args` should include a larger max length;
- whether the prompt is unnecessarily verbose;
- whether task context should be shortened or summarized;
- whether vLLM `MAX_MODEL_LEN` is set appropriately.

Do not ignore this warning in final result interpretation.

## 3. TeleMath score is extremely low

Possible causes:

- Model produces reasoning instead of final numeric answer.
- `until: ["\n"]` stops generation too early.
- `max_gen_toks` is too small.
- Parser fails on units, percentages, fractions, scientific notation, or formatted answers.
- Gold answer formatting differs from local parser expectations.

Inspect raw generations and improve `extract_telemath_answer` only when there is evidence.

## 4. TeleLogs score differs from leaderboard

Possible causes:

- Long prompt truncation.
- Model outputs explanation before C-label.
- Parser extracts the wrong C-label if multiple labels appear in explanation.
- Official prompt may present candidate labels differently.
- Official scorer may differ.

Inspect generated outputs for examples where the model is semantically correct but parser gives zero.

## 5. 3GPP TSG score is low

Possible causes:

- Generation task asks for JSON, but model outputs plain label or explanation.
- Parser is too strict.
- Working group label normalization misses edge cases.
- Official stack may use different document excerpt or choices.
- Multiple-choice variant and generation variant should be compared.

Try comparing the GSMA-aligned generation scorer against the legacy MC/loglikelihood
variant (bounded smoke shown; both are sub-tasks, so they run — only the bare
group names `open_telco_otlite` / `open_telco_otfull` are fail-fast):

```bash
# GSMA-aligned generation scorer (first-match WG regex)
TASKS=open_telco_3gpp_tsg_gsma LIMIT=5 MODEL_NAME=google/gemma-3-4b-it ./run_open_telco_otlite.sh
# legacy lm-eval generation sub-task (default scoring, frozen)
TASKS=open_telco_3gpp_tsg_gen_lm_eval_baseline LIMIT=5 MODEL_NAME=google/gemma-3-4b-it ./run_open_telco_otlite.sh
```

## 6. TeleTables score is low

Check whether table content is actually available.

If not, set:

```bash
export TELETABLES_ROOT=/path/to/extracted/TeleTables/tables
```

Without table content, the model may only see table metadata and choices, which is not a fair reproduction of full table understanding.

## 7. vLLM import works but generation fails

Inspect:

```bash
version-vllm-check.log
```

Possible causes:

- CUDA runtime/driver mismatch.
- Missing CUDA forward-compatibility library.
- GPU memory too low.
- `max_model_len` too large.
- unsupported model architecture in the installed vLLM version.

Try lowering memory pressure:

```bash
BACKEND=vllm \
VLLM_VISIBLE_DEVICES=0 \
GPU_MEMORY_UTILIZATION=0.5 \
MAX_MODEL_LEN=4096 \
MODEL_NAME=google/gemma-3-4b-it \
./run_open_telco_otlite.sh
```

## 8. Hugging Face gated model error

Run:

```bash
huggingface-cli whoami
```

or set a token:

```bash
export HF_TOKEN=...
```

Then retry.

## 9. Out-of-memory

Try:

```bash
BATCH_SIZE=1 MODEL_NAME=google/gemma-3-4b-it ./run_open_telco_otlite.sh
```

For vLLM:

```bash
BACKEND=vllm \
VLLM_VISIBLE_DEVICES=0 \
GPU_MEMORY_UTILIZATION=0.5 \
MAX_MODEL_LEN=4096 \
MODEL_NAME=google/gemma-3-4b-it \
./run_open_telco_otlite.sh
```

## 10. What to record after a fix

After any fix that affects evaluation:

- describe the fix in `PROGRESS.md`;
- record runs in `EXPERIMENTS.md`;
- update `outputs/latest-summary.md`;
- if it changes public-leaderboard alignment, update `REPRODUCTION_NOTES.md`.
