# NFM-Eval-Harness

> **Repository role:** This is the engineering/provenance repository for NFM-Eval-Harness.
> For INL handoff, onboarding, the 30-minute smoke test, and curated final results, use
> **`NFM-Eval-Harness-delivery`** as the canonical handoff package.
>
> **저장소 역할:** 이 저장소는 개발·실험·증빙을 보존하는 engineering/provenance 저장소입니다.
> 지능네트워크연구실 전달·인수·30분 smoke test·최종 결과 확인은 **`NFM-Eval-Harness-delivery`**를 정본으로 사용하세요.

`NFM-Eval-Harness`는 NFM-LLM baseline 평가를 위해 GSMA Open Telco benchmark
task를 실행하는 가벼운 evaluation harness입니다. Open Telco `ot-lite`와
`ot-full` dataset을 `lm-eval` custom task로 정의하고, GPU 서버에서 Hugging
Face 또는 vLLM backend로 평가를 실행하는 스크립트를 포함합니다.

## 저장소 구성

- `open_telco_lm_eval/tasks/open_telco_otlite`: `GSMA/ot-lite` task pack.
- `open_telco_lm_eval/tasks/open_telco_otfull`: `GSMA/ot-full` task pack.
- `run_open_telco_otlite.sh`: `ot-lite` 실행 스크립트. 기본 task는 `open_telco_otlite_gsma`입니다 (TASKS 생략 시).
- `run_open_telco_otfull.sh`: `ot-full` 실행 스크립트. 기본 task는 `open_telco_otfull_gsma`입니다 (TASKS 생략 시).
- `scripts/compare_gsma_leaderboard.py`: local 결과를 GSMA public leaderboard와 비교하는 스크립트.
- `setup-pre.sh`, `setup-main.sh`, `setup-post.sh`: GPU 서버 환경 준비 스크립트.
- `PLAN.md`: LM-Evaluation-Harness 기반 Open Telco 평가 계획과 배경.
- `PROGRESS.md`: 현재 상태와 다음 작업.
- `EXPERIMENTS.md`: benchmark 실행 요약 index.
- `ENVIRONMENT.md`: local/cloud 환경 메모.
- `TROUBLESHOOTING.md`: 반복되는 오류와 해결 방법.

## Quick Start

GPU 서버 환경 준비:

```bash
./setup-pre.sh
./setup-main.sh
./setup-post.sh
```

### 권장 실행 (GSMA-compatible 기본 profile)

run 스크립트의 기본 task는 `_gsma` profile이므로 **TASKS를 생략하면 자동으로 GSMA-compatible profile이 실행**됩니다. 이 profile은 7-task unweighted 평균을 사용하며 public leaderboard와 비교 가능합니다.

`ot-lite` (기본 = `open_telco_otlite_gsma`):

```bash
CONFIRM_FULL_RUN=1 MODEL_NAME=google/gemma-3-4b-it ./run_open_telco_otlite.sh
```

```bash
# 명시형 (위와 동일)
CONFIRM_FULL_RUN=1 MODEL_NAME=google/gemma-3-4b-it TASKS=open_telco_otlite_gsma ./run_open_telco_otlite.sh
```

`ot-full` (기본 = `open_telco_otfull_gsma`):

```bash
CONFIRM_FULL_RUN=1 MODEL_NAME=google/gemma-3-4b-it ./run_open_telco_otfull.sh
```

`ot-full` vLLM backend (multi-GPU tensor parallel):

```bash
CONFIRM_FULL_RUN=1 BACKEND=vllm VLLM_VISIBLE_DEVICES=0,1 TENSOR_PARALLEL_SIZE=2 \
  MODEL_NAME=google/gemma-3-4b-it ./run_open_telco_otfull.sh
```

> bounded smoke run은 `CONFIRM_FULL_RUN=1` 대신 `LIMIT=N`을 사용합니다. full run은 `CONFIRM_FULL_RUN=1`이 필수입니다.

### Profile 표

| Profile | 목적 | public leaderboard 비교 |
| --- | --- | --- |
| `open_telco_otlite_gsma` / `open_telco_otfull_gsma` | GSMA 공개 scoring contract에 정렬된 기본 profile | Yes |
| `open_telco_otlite_lm_eval_baseline` / `open_telco_otfull_lm_eval_baseline` | 기존 lm-eval/loglikelihood baseline | No, diagnostic only |
| `open_telco_*_mcgen` | MC-only scoring sensitivity 분석 | Partial, diagnostic only |

`_gsma` profile은 GSMA 공식 stack(Inspect AI 기반)의 완전 재현이 아니라 **GSMA 공개 scoring contract에 정렬된 profile**입니다.

### Legacy baseline 실행

이전 loglikelihood baseline은 삭제되지 않고 `_lm_eval_baseline`으로 rename되어 보존됩니다. diagnostic 용도로만 사용합니다.

```bash
CONFIRM_FULL_RUN=1 MODEL_NAME=google/gemma-3-4b-it TASKS=open_telco_otlite_lm_eval_baseline ./run_open_telco_otlite.sh
```

> 경고: 이 legacy baseline은 초기 loglikelihood 평가 보존본입니다. GSMA leaderboard와 직접 비교하지 마십시오. leaderboard 비교에는 `_gsma` profile을 사용하십시오.

참고: bare `open_telco_otlite` / `open_telco_otfull`은 더 이상 실행되지 않습니다 (run 스크립트가 fail-fast로 종료, exit 2). `_gsma` 또는 `_lm_eval_baseline` 중 하나를 명시하십시오.

### Public leaderboard 비교

```bash
python scripts/compare_gsma_leaderboard.py --profile gsma --model gemma3-4b \
  --local-result <local result json path> --out-md outputs/<name>.md
```

> public 비교 기준은 lm-eval group acc가 아니라 **7-task unweighted average**입니다.

PR#2 결과 (gemma3-4b): `open_telco_otlite_gsma` 0.3992 / `open_telco_otfull_gsma` 0.3926 ≈ public 0.397.

## 인수자 가이드 (INL handoff)

처음 받는 분은 `INL_HANDOFF.md`를 먼저 보세요. 아래는 30분 안에 끝나는 acceptance test입니다.

```bash
# 0) 환경 (GPU 서버)
./setup-pre.sh && ./setup-main.sh && ./setup-post.sh

# 1) GPU 없이 task 로딩 검증
make smoke

# 2) 1-sample bounded run (작은 모델로 파이프라인 확인)
LIMIT=1 MODEL_NAME=google/gemma-3-4b-it ./run_open_telco_otlite.sh
LIMIT=1 BACKEND=vllm VLLM_VISIBLE_DEVICES=0 MODEL_NAME=google/gemma-3-4b-it ./run_open_telco_otlite.sh

# 3) 비교 스크립트 사용법
python scripts/compare_gsma_leaderboard.py --help

# 4) 전달 readiness 점검(문서/secret/용량/tree)
make delivery-check
```

대표 full run / 비교는 위 Quick Start와 `INL_HANDOFF.md` 참조.

### 대형 모델 실행 시 운영 변수

| 변수 | 용도 |
|---|---|
| `BACKEND=vllm` / `TENSOR_PARALLEL_SIZE=2` / `VLLM_VISIBLE_DEVICES=a,b` | 24~33B 모델은 tp=2(2 GPU) |
| `MAX_MODEL_LEN=8192` | 128K-context 모델 KV cache 초과 방지(프롬프트는 ≤1024 tok) |
| `GPU_MEMORY_UTILIZATION=0.9` | 9B+ 모델 KV cache 확보(ot-lite 기본 0.5는 부족할 수 있음) |
| `EXTRA_MODEL_ARGS=enable_thinking=False` | Qwen3 계열 추론 억제(단답 MC) |
| `EXTRA_MODEL_ARGS=...,tokenizer_mode=mistral` | Mistral 계열 토크나이저 |
| `HF_HUB_OFFLINE=1` + `NCCL_SOCKET_IFNAME=lo NCCL_IB_DISABLE=1` | 호스트에 VM이 떠 있어 NCCL/HF-hub in-process가 hang할 때(상세 `INL_HANDOFF.md`/`outputs/overnight-otfull-results.md`) |

### 결과 해석 시 주의

- 모든 비교는 **7-task unweighted task mean** vs public **unweighted**. sample-weighted group acc와 혼동 금지.
- `_gsma`는 GSMA 공개 scoring contract에 정렬된 profile이며 **공식 GSMA 완전 재현이 아니다**(특히 MC는 자유 generation vs 공식 제약 디코딩으로 engine 미정렬).
- non-leaderboard 모델은 public delta를 만들지 않고 internal 비교만 한다. reasoning/harmony(예 gpt-oss, R1-Distill)·일부 멀티모달은 단답 MC engine과 비호환 → collapse=artifact(능력치 아님).

### 문서 map

| 문서 | 용도 |
|---|---|
| `INL_HANDOFF.md` | **인수자 시작점** — 설치/실행/읽는 순서/체크리스트 |
| `FINAL_DELIVERY_SUMMARY.md` | 한 장 요약(정체성·결과·한계) |
| `RESULTS_MANIFEST.md` | 전달 산출물(결과 JSON·비교 MD) 위치/공유 안전 여부 |
| `RELEASE_NOTES.md` | PR #1~#5 변경 이력 |
| `PACKAGING_CHECKLIST.md` | 전달 전 점검 + release tag 명령 |
| `outputs/overnight-otfull-results.md` | 최신 핵심 결과(ot-full 14종 full split) |
| `outputs/model-candidate-plan-extended.md` | 확장 후보 pool + ot-lite 결과 |
| `REPRODUCTION_NOTES.md` / `GSMA_SCORING_CONTRACT.md` | 재현 caveat / scoring contract |
| `TASK_MANIFEST.md` / `HANDOFF.md` / `AGENTS.md` | task별 상세 / 배경 / 작업 규칙 |

## Codex Local And Cloud Workflow

현재 GPU 서버 상태에 의존하는 작업은 Codex Local로 처리합니다. 예를 들어 CUDA,
실제 model 실행, local cache, dataset 추출, 긴 evaluation log 확인이 여기에
해당합니다.

Codex Cloud는 repo 안에서 끝나는 작업에 사용합니다. 예를 들어 task YAML 변경,
parser 수정, 문서화, 작은 script, review, PR 준비가 적합합니다. Cloud는
commit된 repo 파일을 기준으로 작업하며, GPU 서버의 로컬 상태에 접근할 수 있다고
가정하지 않습니다.

권장 handoff 흐름:

1. GPU 서버에서 local로 평가를 실행하거나 디버깅합니다.
2. 가벼운 결과 요약을 `EXPERIMENTS.md`, `outputs/latest-summary.md`,
   `outputs/run-index.jsonl`에 기록합니다.
3. 무엇이 바뀌었고 다음에 무엇을 해야 하는지 `PROGRESS.md`에 갱신합니다.
4. repo 상태를 commit하고 push합니다.
5. Codex Cloud에는 review, 정리, 문서화, PR 준비 같은 repo 중심 작업을 맡깁니다.

## 현재 범위

이 저장소는 내부 baseline harness입니다. 목적은 후보 NFM-LLM model과 domain
adaptation 변형 간 상대 비교입니다. Inspect AI 기반의 공식 GSMA leaderboard
stack을 완전히 동일하게 재현하는 것을 목표로 하지는 않습니다.
