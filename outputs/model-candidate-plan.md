# Model Candidate Plan — NFM-LLM baseline harness (delivery pass)

작성: 2026-06-27 · 대상 전달: 지능네트워크연구실(Intelligent Network Lab)

이 문서는 NFM-Eval-Harness `_gsma` profile(GSMA 공개 scoring contract 정렬, 기본 실행 경로)로
평가한 **후보 모델 목록과 접근성/실행 메타데이터**를 정리한다. 점수 결과 요약은
`FINAL_DELIVERY_SUMMARY.md`와 모델별 `outputs/*-otlite-gsma-delta.md`에 있다.

> 모든 평가는 **ot-lite_gsma full**(7-task, unweighted task mean)로 통일했다. 신규 모델의
> ot-full 신규 실행은 이번 범위 밖이다(ot-full 동일-split 직접비교는 기존 gemma-3-4b 결과로 유지).
> "공식 GSMA 완전 재현"이 아니라 **공개 scoring contract에 정렬된 내부 baseline harness**다.
> 특히 MC 4종은 engine 미정렬(자유 single-letter generation vs 공식 제약 디코딩)이다.

## 1. 후보 모델 표 (accessibility / metadata)

| model_id | key | 역할 | public avg | 접근 | GPU 구성 | thinking 처리 |
|---|---|---|---:|---|---|---|
| `Qwen/Qwen2.5-7B-Instruct` | qwen2.5-7b | leaderboard 재현 | 0.4579 | open | 1×A100 (vLLM) | N/A |
| `tiiuae/Falcon3-10B-Instruct` | falcon3-10b | leaderboard 재현 | 0.4588 | open | 1×A100 (vLLM) | N/A |
| `google/gemma-3-12b-it` | gemma3-12b | leaderboard 재현 | 0.4638 | gated (etri-lirs 승인됨) | 1×A100 (vLLM, `MAX_MODEL_LEN=8192`) | N/A |
| `Qwen/Qwen3-4B` | qwen3-4b | 내부 비교 | — | open | 1×A100 (vLLM) | `enable_thinking=False` |
| `Qwen/Qwen3-14B` | qwen3-14b | 내부 비교 | — | open | 2×A100 tp=2 (vLLM) | `enable_thinking=False` |
| `deepseek-ai/DeepSeek-R1-Distill-Qwen-14B` | r1-distill-14b | 내부 비교 | — | open | 2×A100 tp=2 (vLLM) | reasoning(아래 §3 참고) |

- public avg는 `GSMA/leaderboard` 데이터셋의 해당 row(7-task unweighted)다. 비-leaderboard 3모델은 public row가 없어 내부 비교만 한다.
- gemma-3-12b는 gated 모델이며 etri-lirs org 토큰으로 접근 확인했다(약관 수락 완료). 403 미발생.
- phi-4는 사용자 결정으로 미포함.

## 2. 실행 방법 (재현 명령)

모든 run은 가드된 run 스크립트(`CONFIRM_FULL_RUN=1`)를 경유했고 `TASKS`를 생략해
기본값 `open_telco_otlite_gsma`로 실행했다(`--apply_chat_template` 항상 ON). `OUTPUT_PATH`를
모델별로 분리해 기존 결과를 덮어쓰지 않았다.

```bash
# leaderboard 모델 예시 (단일 GPU vLLM)
CONFIRM_FULL_RUN=1 BACKEND=vllm VLLM_VISIBLE_DEVICES=0 \
  MODEL_NAME=Qwen/Qwen2.5-7B-Instruct \
  OUTPUT_PATH=results/otlite-gsma-qwen2.5-7b ./run_open_telco_otlite.sh

# gemma-3-12b: 128K 기본 context가 40GB 단일카드 KV cache를 초과 → MAX_MODEL_LEN로 캡
CONFIRM_FULL_RUN=1 BACKEND=vllm VLLM_VISIBLE_DEVICES=2 \
  MODEL_NAME=google/gemma-3-12b-it MAX_MODEL_LEN=8192 GPU_MEMORY_UTILIZATION=0.85 \
  OUTPUT_PATH=results/otlite-gsma-gemma3-12b ./run_open_telco_otlite.sh

# 14B 급: tensor-parallel 2장
CONFIRM_FULL_RUN=1 BACKEND=vllm VLLM_VISIBLE_DEVICES=4,5 TENSOR_PARALLEL_SIZE=2 \
  MODEL_NAME=Qwen/Qwen3-14B EXTRA_MODEL_ARGS=enable_thinking=False \
  OUTPUT_PATH=results/otlite-gsma-qwen3-14b ./run_open_telco_otlite.sh
```

- `EXTRA_MODEL_ARGS`(이번 pass에서 run 스크립트에 추가한 opt-in passthrough)로 thinking 모델에 `enable_thinking=False`를 주입한다. 미설정 시 no-op이라 기존 동작 불변.
- thinking 모델은 `LOG_SAMPLES=1`로 응답을 기록해 `<think>` 출력률(emission)을 검증했다.

## 3. thinking / reasoning 모델 정책

기본 결정(사용자): `enable_thinking=False` 시도 + LIMIT=20 emission gate(MC letter / boxed / WG ≥ 0.30).
미달 시 caveat와 함께 결과를 기록한다(점수를 능력치로 단정하지 않는다).

- **Qwen3-4B / Qwen3-14B**: `enable_thinking=False`가 chat template에서 정상 동작 → 응답 1700개 중 `<think>` **0개**. MC는 깨끗한 single-letter(`C`/`A`/`D`) 출력. 정상 측정.
- **DeepSeek-R1-Distill-Qwen-14B**: `enable_thinking=False`는 Qwen3 전용 규약이라 R1-Distill 계열은 **무시**한다. 해당 모델 chat template은 추론을 강제 시작시키므로, MC(자유 generation, `max_gen_toks:8`) 응답이 잘린 추론 산문(예: `"Okay, so I have this question about"`)으로 truncate되어 정답 letter에 도달하지 못한다. → MC 전 과목 ~0으로 **붕괴**. 이는 **"always-reasoning 모델 × 단답 MC 엔진" 구조적 비호환 artifact**이며 모델의 실제 능력치가 아니다. budget이 큰 생성형 과목(telemath 1024 / 3gpp 256)은 부분적으로 동작한다.

## 4. 한계 / 무결성

- MC 4종은 engine 미정렬(자유 generation vs 공식 제약 디코딩)이라 generation-vs-constrained **sensitivity** 측정이지 공식 재현이 아니다.
- public row의 provider/revision/runtime parity는 보장하지 않는다(leaderboard row label만 일치).
- 정답 하드코딩/데이터 누수/모델별 사후 튜닝 없음. default scoring 동결. 기존 결과 파일 미덮어쓰기.
