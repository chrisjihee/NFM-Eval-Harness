# Troubleshooting

## Virtual Environment가 없음

증상:

```text
Missing virtual environment at .../.venv
```

해결:

```bash
./setup-main.sh
```

이후 실행:

```bash
source .venv/bin/activate
```

## Hugging Face 인증

증상:

- Gated model download가 실패합니다.
- `hf auth whoami`가 실패합니다.

해결:

```bash
./setup-post.sh
```

또는 수동으로:

```bash
source .venv/bin/activate
hf auth login
```

## Prompt Truncation Warning

증상:

```text
Left truncation applied. Original sequence length was ...
```

가능한 영향:

- Model이 전체 prompt를 보지 못했을 수 있습니다.
- `telelogs`, `teletables`, `telemath`, `3gpp_tsg_gen` 점수가 기대보다 낮게
  나올 수 있습니다.

다음 확인:

- 더 긴 context window를 지원하는 model/backend를 시도합니다.
- vLLM에서는 model이 지원한다면 `MAX_MODEL_LEN`을 설정합니다.
- Scoring logic을 바꾸기 전에 task prompt 구성부터 확인합니다.

## vLLM 설치 또는 Runtime 문제

증상:

- vLLM build가 실패합니다.
- CUDA/PyTorch version이 맞지 않습니다.
- Runtime worker가 crash합니다.

다음 확인:

```bash
source .venv/bin/activate
python - <<'PY'
import torch
print(torch.__version__)
print(torch.version.cuda)
print(torch.cuda.is_available())
print(torch.cuda.device_count())
PY
```

환경이 많이 꼬였다면 정리 후 다시 build합니다.

```bash
./reset-main.sh
./setup-main.sh
```

## Cloud Task가 Local Run을 재현하지 못함

예상 원인:

Codex Cloud는 GPU 서버의 local file, `.venv`, model cache, dataset extraction
상태를 가지고 있지 않습니다.

해결:

- Cloud task에 필요한 code와 경량 summary를 commit합니다.
- 큰 artifact는 git에 넣지 않습니다.
- Cloud에는 repo 파일 수정/review를 맡기고, benchmark는 local에서 실행합니다.
