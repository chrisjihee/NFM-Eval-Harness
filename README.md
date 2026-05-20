# NFM-Eval-Harness

`NFM-Eval-Harness`는 NFM-LLM baseline 평가를 위해 GSMA Open Telco benchmark
task를 실행하는 가벼운 evaluation harness입니다. Open Telco `ot-lite`와
`ot-full` dataset을 `lm-eval` custom task로 정의하고, GPU 서버에서 Hugging
Face 또는 vLLM backend로 평가를 실행하는 스크립트를 포함합니다.

## 저장소 구성

- `open_telco_lm_eval/tasks/open_telco_otlite`: `GSMA/ot-lite` task pack.
- `open_telco_lm_eval/tasks/open_telco_otfull`: `GSMA/ot-full` task pack.
- `run_open_telco_otlite.sh`: `ot-lite` group 기본 실행 스크립트.
- `run_open_telco_otfull.sh`: `ot-full` group 기본 실행 스크립트.
- `setup-pre.sh`, `setup-main.sh`, `setup-post.sh`: GPU 서버 환경 준비 스크립트.
- `PLAN.md`: LM-Evaluation-Harness 기반 Open Telco 평가 계획과 배경.
- `PROGRESS.md`: 현재 상태와 다음 작업.
- `EXPERIMENTS.md`: benchmark 실행 요약 index.
- `ENVIRONMENT.md`: local/cloud 환경 메모.
- `TROUBLESHOOTING.md`: 반복되는 오류와 해결 방법.

## Quick Start

GPU 서버에서:

```bash
./setup-pre.sh
./setup-main.sh
./setup-post.sh
```

`ot-lite` 실행:

```bash
MODEL_NAME=google/gemma-3-4b-it ./run_open_telco_otlite.sh
```

`ot-full` 실행:

```bash
MODEL_NAME=google/gemma-3-4b-it ./run_open_telco_otfull.sh
```

Hugging Face backend 대신 vLLM 사용:

```bash
BACKEND=vllm VLLM_VISIBLE_DEVICES=0 MODEL_NAME=google/gemma-3-4b-it ./run_open_telco_otlite.sh
```

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
