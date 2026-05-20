# Environment

이 repo는 Codex Local과 Codex Cloud를 나누어 쓰는 workflow를 전제로 합니다.

## Codex Local

GPU 서버에서 local로 실행해야 하는 작업:

- CUDA와 PyTorch 진단.
- Hugging Face model download/cache 확인.
- 실제 model을 대상으로 한 `lm_eval` 실행.
- vLLM 설치와 runtime debugging.
- Local dataset, 추출된 TeleTables asset, benchmark log 확인.

현재 local setup 가정:

- Python: `uv`로 설치한 `3.12`.
- CUDA toolkit: `$HOME/.local/cuda-12.8` 아래 설치된 `12.8`.
- PyTorch wheel: CUDA 12.8 index 사용.
- vLLM: `setup-main.sh`에서 build/install.
- Hugging Face auth: `setup-post.sh`에서 설정.

## Codex Cloud

Cloud 실행에 적합한 repo-only 작업:

- 문서화.
- YAML task 정의 수정.
- Parser/scoring code 수정.
- Model weight나 GPU가 필요 없는 작은 테스트.
- PR review와 정리.

Codex Cloud에서 접근 가능하다고 가정하면 안 되는 것:

- `/data`, `/mnt` 또는 다른 GPU 서버 파일시스템 경로.
- `.venv`, local package source, Hugging Face cache, download된 model.
- `.gitignored` raw output, log, checkpoint, 추출 dataset.
- Cloud secret으로 명시 설정하지 않은 private credential.

## 주요 경로

- Virtual environment: `.venv/`
- Download된 package source: `package-src/`
- Hugging Face cache symlink: `.cache_hf`
- 경량 결과 요약: `outputs/latest-summary.md`
- Handoff용 run index: `outputs/run-index.jsonl`
- 추적 중인 예시 full result: `results/`

## 환경 변수

실행 스크립트에서 자주 쓰는 변수:

- `MODEL_NAME`: Hugging Face model id.
- `BACKEND`: `hf` 또는 `vllm`.
- `DEVICE`: Hugging Face backend용 device. 예: `cuda:0`.
- `BATCH_SIZE`: 기본값은 `auto`.
- `OUTPUT_PATH`: 결과 저장 directory.
- `TASKS`: comma로 구분한 task 또는 group 이름.
- `DTYPE`: vLLM dtype. 기본값은 `bfloat16`.
- `TENSOR_PARALLEL_SIZE`: vLLM tensor parallel size.
- `DATA_PARALLEL_SIZE`: vLLM data parallel size.
- `GPU_MEMORY_UTILIZATION`: vLLM memory fraction.
- `MAX_MODEL_LEN`: 선택적 vLLM context length override.
- `VLLM_VISIBLE_DEVICES`: vLLM에 노출할 GPU.
- `TELETABLES_ROOT`: 더 풍부한 `ot-full` table prompt를 위해 사용할 수 있는
  추출된 TeleTables table tree 경로.
