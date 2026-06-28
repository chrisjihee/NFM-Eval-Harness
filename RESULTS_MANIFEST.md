# RESULTS MANIFEST — NFM-Eval-Harness (INL delivery)

기준: `main` (PR #1~#5 merged, `7129050`). 이 문서는 **전달 산출물(evidence)의 위치·추적 여부·공유 안전성**을 정리한 manifest다.
**점수 수치의 단일 출처(single source of truth)**는 아래 문서들이며, 본 manifest는 수치를 재기재하지 않는다.

- ot-full(full split) 결과/공식 delta 요약: `outputs/overnight-otfull-results.md`
- ot-lite 스크리닝(확장 후보) 요약: `outputs/model-candidate-plan-extended.md`
- 모든 run 1줄 인덱스: `outputs/run-index.jsonl` (40 entries) · 실행 요약: `EXPERIMENTS.md`
- 재현 caveat / scoring contract: `REPRODUCTION_NOTES.md`, `GSMA_SCORING_CONTRACT.md`

> 공유 안전성: 아래 tracked 항목은 **공개 prompt/정답을 포함하지 않는 집계 결과(JSON)와 비교표(MD)**다. per-sample dump·raw log·model weight·HF cache는 **추적 안 함 / 전달 안 함**(아래 §제외).

## 1. ot-full_gsma — full split (16,866 docs), 14종 + reference

| 구분 | result JSON 경로(dir) | compare MD (LB만) | tracked | 공유 안전 |
|---|---|---|---|---|
| LB | `results/otfull-gsma-{phi-4,qwen2.5-32b,mistral-small-24b,qwen2.5-14b,falcon3-10b,qwen2.5-7b,gemma2-9b,mistral-nemo-12b,gemma3-12b,gemma3-27b,qwen3-8b}/` | `outputs/<key>-otfull-gsma-delta.md` (11 + `gemma3-4b` ref) | ✅ `results_*.json` | ✅ |
| non-LB | `results/otfull-gsma-{qwen3-30b-a3b-fp8,qwen3-14b,qwen3.5-9b}/` | (없음 — public delta 미생성, internal only) | ✅ | ✅ |
| reference | `results/open_telco_otfull_gsma/google__gemma-3-4b-it/` (PR#2/#4) | `outputs/gemma3-4b-otfull-gsma-delta.md` | ✅ | ✅ |

수치·delta·제외 모델(gpt-oss/gemma-4-E4B/qwen3.6-fp8/R1-Distill) 설명은 `outputs/overnight-otfull-results.md` 참조.

## 2. ot-lite_gsma — 스크리닝/전달 reference

| 구분 | 경로 | tracked | 공유 안전 |
|---|---|---|---|
| PASS5 확장 11종 | `results/otlite-gsma-*/` | ✅ `results_*.json` | ✅ |
| PASS4 전달 6종 | `results/otlite-gsma-*/`, 비교 `outputs/*-otlite-gsma-delta.md` | ✅ | ✅ |
| reference(gemma3-4b) | `results/open_telco_otlite_gsma/` | ✅ | ✅ |

요약 표는 `outputs/model-candidate-plan-extended.md`(확장) / `FINAL_DELIVERY_SUMMARY.md`(전달).

## 3. 제외 / 비전달 (절대 포함하지 않음)

| 항목 | 상태 | 사유 |
|---|---|---|
| `results/**/samples_*.jsonl`, `*.log`, `*.tmp` | **not tracked / not delivered** | per-sample dump·raw log (`.gitignore`) |
| model weights / HF cache (`~/.cache/huggingface`) | **not tracked / not delivered** | 대용량·라이선스, evidence 아님 |
| `results/smoke-*/`, `results/conf-*/`, `*tp2-test*` | **not tracked** | 진단/smoke run (`.gitignore`) |
| `chat/`, `lm-eval-ls-task` | **not tracked** | 내부 dev 로그/터미널 덤프 (`.gitignore`) |
| 제외 모델(gpt-oss-20b, gemma-4-E4B-it, Qwen3.6-27B-FP8, DeepSeek-R1-Distill) | ot-full 미실행 | artifact/비호환 — `outputs/overnight-otfull-results.md` §제외 |

## 4. 정합성

- `outputs/run-index.jsonl`(40) ⊇ 위 tracked run들. `EXPERIMENTS.md` Run Index와 동일 run을 가리킨다.
- 용량 가드: `make delivery-check`(또는 `python scripts/check_tracked_file_sizes.py --max-mb 50`) — tracked 파일 50MB 초과 없음(model weight/cache 미포함 확인).
