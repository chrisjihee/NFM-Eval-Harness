# NFM-Eval-Harness

> **Repository role:** This is the engineering/provenance repository for NFM-Eval-Harness.
> For INL handoff, onboarding, the smoke test, and curated final results, use
> **`NFM-Eval-Harness-delivery`** as the canonical handoff package.
>
> **저장소 역할:** 이 저장소는 개발·실험·증빙을 보존하는 engineering/provenance 저장소입니다.
> 지능네트워크연구실 전달·인수·smoke test·최종 결과 확인은 **`NFM-Eval-Harness-delivery`**를 정본으로 사용하세요.

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
- `docs/PLAN.md`: LM-Evaluation-Harness 기반 Open Telco 평가 계획과 배경.
- `docs/PROGRESS.md`: 현재 상태와 다음 작업.
- `docs/EXPERIMENTS.md`: benchmark 실행 요약 index.
- `docs/ENVIRONMENT.md`: 환경·`lm_eval` pin·재설치 절차.
- `docs/TROUBLESHOOTING.md`: 반복되는 오류와 해결 방법.

## Quick Start

GPU 서버 환경 준비:

```bash
./setup-pre.sh
./setup-main.sh
./setup-post.sh
```

### 권장 실행 (GSMA-compatible 기본 profile)

run 스크립트의 기본 task는 `_gsma` profile이므로 **TASKS를 생략하면 자동으로 GSMA-compatible profile이 실행**됩니다. 이 profile은 7-task unweighted 평균을 사용하며 public leaderboard와 비교 가능합니다. 기본 backend는 **vLLM**입니다(run 스크립트가 `MAX_MODEL_LEN=8192`·`GPU_MEMORY_UTILIZATION=0.9`를 기본 적용). HF backend(`BACKEND=hf`)는 긴 생성형 입력을 left-truncation 하므로 경량/대체용입니다.

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
> `--local-result`는 **전체 run(LIMIT 없이) 결과 JSON**이어야 합니다 — `LIMIT=N` smoke 결과는
> task당 표본이 적어 acc가 0/1 noise가 되어 delta가 무의미하며, 이 경우 스크립트가 상단에
> BOUNDED/SMOKE 경고를 출력합니다.

PR#2 결과 (gemma3-4b): `open_telco_otlite_gsma` 0.3992 / `open_telco_otfull_gsma` 0.3926 ≈ public 0.397.

## 인수자 가이드 (INL handoff)

처음 받는 분은 **`NFM-Eval-Harness-delivery`** 저장소를 먼저 보세요. 아래는 빠른 acceptance test입니다(아래 `python` 예시는 `.venv` 활성 상태를 가정).

```bash
# 0) 환경 (GPU 서버)
./setup-pre.sh && ./setup-main.sh && ./setup-post.sh

# 1) GPU 없이 task 로딩 검증
make smoke

# 2) 1-sample bounded run (작은 모델로 파이프라인 확인; 기본 backend = vLLM)
LIMIT=1 MODEL_NAME=google/gemma-3-4b-it ./run_open_telco_otlite.sh
# (경량/빠른 파이프라인 확인은 HF backend)
LIMIT=1 BACKEND=hf MODEL_NAME=google/gemma-3-4b-it ./run_open_telco_otlite.sh

# 3) 비교 스크립트 사용법 (.venv 미활성 시에도 안전하도록 .venv/bin 사용)
.venv/bin/python scripts/compare_gsma_leaderboard.py --help

# 4) 전달 readiness 점검(문서/secret/용량/tree)
make delivery-check
```

대표 full run / 비교는 위 Quick Start와 `NFM-Eval-Harness-delivery` 참조.

### 대형 모델 실행 시 운영 변수

| 변수 | 용도 |
|---|---|
| `BACKEND=vllm` / `TENSOR_PARALLEL_SIZE=2` / `VLLM_VISIBLE_DEVICES=a,b` | 24~33B 모델은 tp=2(2 GPU) |
| `MAX_MODEL_LEN=8192` | **run 스크립트 기본값**. 128K-context 모델 KV cache 초과 방지(bundled task 프롬프트는 8192 미만) |
| `GPU_MEMORY_UTILIZATION=0.9` | **run 스크립트 기본값**. 9B+ 모델 KV cache 확보 |
| `EXTRA_MODEL_ARGS=enable_thinking=False` | Qwen3 계열 추론 억제(단답 MC) |
| `EXTRA_MODEL_ARGS=...,tokenizer_mode=mistral` | Mistral 계열 토크나이저 |
| `HF_HUB_OFFLINE=1` + `NCCL_SOCKET_IFNAME=lo NCCL_IB_DISABLE=1` | 호스트에 VM이 떠 있어 NCCL/HF-hub in-process가 hang할 때(상세 `docs/HANDOFF.md`/`outputs/overnight-otfull-results.md`) |

### 결과 해석 시 주의

- 모든 비교는 **7-task unweighted task mean** vs public **unweighted**. sample-weighted group acc와 혼동 금지.
- `_gsma`는 GSMA 공개 scoring contract에 정렬된 profile이며 **공식 GSMA 완전 재현이 아니다**(특히 MC는 자유 generation vs 공식 제약 디코딩으로 engine 미정렬).
- non-leaderboard 모델은 public delta를 만들지 않고 internal 비교만 한다. reasoning/harmony(예 gpt-oss, R1-Distill)·일부 멀티모달은 단답 MC engine과 비호환 → collapse=artifact(능력치 아님).

### 문서 map

| 문서 | 용도 |
|---|---|
| `START_HERE_ENGINEERING.md` | **엔지니어링 저장소 시작점** — 역할·읽는 순서·링크 |
| `outputs/overnight-otfull-results.md` | 최신 핵심 결과(ot-full 14종 full split) |
| `outputs/model-candidate-plan-extended.md` | 확장 후보 pool + ot-lite 결과 |
| `docs/REPRODUCTION_NOTES.md` / `docs/GSMA_SCORING_CONTRACT.md` | 재현 caveat / scoring contract |
| `docs/TASK_MANIFEST.md` / `docs/HANDOFF.md` / `CLAUDE.md` | task별 상세 / 배경 / 작업 규칙 |
| `docs/EXPERIMENTS.md` / `docs/PROGRESS.md` | 실행 이력 / 현재 상태 |
| `docs/ENVIRONMENT.md` / `docs/TROUBLESHOOTING.md` | 환경 설정 / 장애 회피 |

## 현재 범위

이 저장소는 내부 baseline harness입니다. 목적은 후보 NFM-LLM model과 domain
adaptation 변형 간 상대 비교입니다. Inspect AI 기반의 공식 GSMA leaderboard
stack을 완전히 동일하게 재현하는 것을 목표로 하지는 않습니다.
