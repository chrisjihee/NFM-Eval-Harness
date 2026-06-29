# AGENTS.md

## Project Context

이 저장소는 NFM-LLM 평가 작업을 위해 GSMA Open Telco task를
LM-Evaluation-Harness 기반으로 실행하는 baseline harness입니다.

의미 있는 변경을 하기 전에는 아래 파일을 먼저 읽습니다.

- `README.md`
- `docs/PLAN.md`
- `docs/PROGRESS.md`
- `docs/EXPERIMENTS.md`
- `docs/ENVIRONMENT.md`
- `docs/TROUBLESHOOTING.md`
- `open_telco_lm_eval/README.md`

## Operating Model

- GitHub에 추적되는 파일을 Claude Code의 기준 문맥으로 봅니다.
- GPU 서버의 로컬 파일, dataset, Hugging Face cache, checkpoint, `/data`,
  `/mnt` 경로가 원격 에이전트에 있다고 가정하지 않습니다.
- GPU 평가, CUDA 디버깅, model cache 확인, 긴 benchmark 실행은 GPU 서버에서
  수행하거나, 로컬 실행용 명령을 준비합니다.
- repo 안에서 끝나는 작업에 집중합니다. 예: task 정의, parser 로직, 문서, 작은 테스트, PR 준비용 diff.

## Repository Conventions

- Custom task 정의는 `open_telco_lm_eval/tasks` 아래에 둡니다.
- `ot-lite` task는 `open_telco_lm_eval/tasks/open_telco_otlite`에 둡니다.
- `ot-full` task는 `open_telco_lm_eval/tasks/open_telco_otfull`에 둡니다.
- 새 framework를 추가하기보다 기존 YAML task 정의와 각 디렉토리의 `utils.py`
  수정으로 해결하는 것을 우선합니다.
- benchmark output은 git에 가볍게 유지합니다. Raw log, checkpoint, cache,
  큰 생성 산출물은 추적하지 않습니다.
- 의미 있는 실행 결과는 `docs/EXPERIMENTS.md`, `docs/PROGRESS.md`,
  `outputs/latest-summary.md`에 요약합니다.

## Common Commands

GPU 서버 환경 설정:

```bash
./setup-pre.sh
./setup-main.sh
./setup-post.sh
```

> **task name 규칙(RENAME, 2026-06).** 기본/권장 group = GSMA-compatible `open_telco_otlite_gsma` / `open_telco_otfull_gsma`
> (run script 기본값; 아래처럼 `TASKS`를 생략하면 이 기본값이 실행된다). legacy lm-eval/loglikelihood baseline은
> `_lm_eval_baseline` suffix로 보존(diagnostic only)되며 명시적으로 지정해야 한다. **bare `open_telco_otlite` / `open_telco_otfull`은
> rename되어 실행 불가** — run script가 fail-fast `exit 2`로 거부한다.

기본 `ot-lite` pack 실행(TASKS 생략 시 `open_telco_otlite_gsma`):

```bash
MODEL_NAME=google/gemma-3-4b-it ./run_open_telco_otlite.sh
```

기본 `ot-full` pack 실행(TASKS 생략 시 `open_telco_otfull_gsma`):

```bash
MODEL_NAME=google/gemma-3-4b-it ./run_open_telco_otfull.sh
```

vLLM backend로 실행(TASKS 생략 시 기본 `_gsma`):

```bash
BACKEND=vllm VLLM_VISIBLE_DEVICES=0 MODEL_NAME=google/gemma-3-4b-it ./run_open_telco_otlite.sh
```

legacy lm-eval baseline(diagnostic only, 명시적 지정):

```bash
MODEL_NAME=google/gemma-3-4b-it TASKS=open_telco_otlite_lm_eval_baseline ./run_open_telco_otlite.sh
```

## Completion Checklist

평가 동작에 영향을 주는 변경을 했다면:

- 관련 task README 또는 루트 문서를 갱신합니다.
- `docs/PROGRESS.md`에 짧은 진행 기록을 추가하거나 수정합니다.
- benchmark를 실행했다면 `docs/EXPERIMENTS.md`에 요약합니다.
- 최신 경량 결과는 `outputs/latest-summary.md`에 반영합니다.
- 환경별 이슈는 `docs/ENVIRONMENT.md` 또는 `docs/TROUBLESHOOTING.md`에 남깁니다.
