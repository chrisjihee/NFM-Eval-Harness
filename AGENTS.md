# AGENTS.md

## Project Context

이 저장소는 NFM-LLM 평가 작업을 위해 GSMA Open Telco task를
LM-Evaluation-Harness 기반으로 실행하는 baseline harness입니다.

의미 있는 변경을 하기 전에는 아래 파일을 먼저 읽습니다.

- `README.md`
- `PLAN.md`
- `PROGRESS.md`
- `EXPERIMENTS.md`
- `ENVIRONMENT.md`
- `TROUBLESHOOTING.md`
- `open_telco_lm_eval/README.md`

## Operating Model

- GitHub에 추적되는 파일을 Codex Cloud의 기준 문맥으로 봅니다.
- GPU 서버의 로컬 파일, dataset, Hugging Face cache, checkpoint, `/data`,
  `/mnt` 경로가 Codex Cloud에 있다고 가정하지 않습니다.
- GPU 평가, CUDA 디버깅, model cache 확인, 긴 benchmark 실행은 GPU 서버에서
  Codex Local로 수행하거나, 로컬 실행용 명령을 준비합니다.
- Cloud task는 repo 안에서 끝나는 작업에 집중합니다. 예: task 정의, parser
  로직, 문서, 작은 테스트, PR 준비용 diff.

## Repository Conventions

- Custom task 정의는 `open_telco_lm_eval/tasks` 아래에 둡니다.
- `ot-lite` task는 `open_telco_lm_eval/tasks/open_telco_otlite`에 둡니다.
- `ot-full` task는 `open_telco_lm_eval/tasks/open_telco_otfull`에 둡니다.
- 새 framework를 추가하기보다 기존 YAML task 정의와 각 디렉토리의 `utils.py`
  수정으로 해결하는 것을 우선합니다.
- benchmark output은 git에 가볍게 유지합니다. Raw log, checkpoint, cache,
  큰 생성 산출물은 추적하지 않습니다.
- 의미 있는 실행 결과는 `EXPERIMENTS.md`, `PROGRESS.md`,
  `outputs/latest-summary.md`에 요약합니다.

## Common Commands

GPU 서버 환경 설정:

```bash
./setup-pre.sh
./setup-main.sh
./setup-post.sh
```

기본 `ot-lite` pack 실행:

```bash
MODEL_NAME=google/gemma-3-4b-it ./run_open_telco_otlite.sh
```

기본 `ot-full` pack 실행:

```bash
MODEL_NAME=google/gemma-3-4b-it ./run_open_telco_otfull.sh
```

vLLM backend로 실행:

```bash
BACKEND=vllm VLLM_VISIBLE_DEVICES=0 MODEL_NAME=google/gemma-3-4b-it ./run_open_telco_otlite.sh
```

## Completion Checklist

평가 동작에 영향을 주는 변경을 했다면:

- 관련 task README 또는 루트 문서를 갱신합니다.
- `PROGRESS.md`에 짧은 진행 기록을 추가하거나 수정합니다.
- benchmark를 실행했다면 `EXPERIMENTS.md`에 요약합니다.
- 최신 경량 결과는 `outputs/latest-summary.md`에 반영합니다.
- 환경별 이슈는 `ENVIRONMENT.md` 또는 `TROUBLESHOOTING.md`에 남깁니다.
