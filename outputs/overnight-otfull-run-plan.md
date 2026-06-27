# Overnight ot-full_gsma Run Plan (PASS 5) — 승인 대기

작성: 2026-06-27 · 입력: PASS 5 ot-lite_gsma 스크리닝 결과(`outputs/model-candidate-plan-extended.md`).
**상태: 사용자 승인 대기(ot-full 미실행).** 아래 최종 목록 + GPU 배치 확인 후 진행.

> 모든 weight는 ot-lite 스크리닝에서 이미 캐시됨 → ot-full은 **다운로드 없이 평가만**. 레시피: `HF_HUB_OFFLINE=1 + NCCL_SOCKET_IFNAME=lo + NCCL_IB_DISABLE=1 + enforce_eager + MAX_MODEL_LEN=8192 + GPU_MEMORY_UTILIZATION=0.9`(+ Mistral은 `tokenizer_mode=mistral`, Qwen thinking은 `enable_thinking=False`). 실행은 `run_open_telco_otfull.sh`(기본 task=`open_telco_otfull_gsma`, 16,866 docs).

## 타이밍 근거
- ot-full=16,866 samples(teleqna 10k MC[빠름] + 생성형 telemath500/telelogs864/3gpp2000[느림, 1024/256 budget] 지배). ot-lite=1,700.
- 앵커: gemma-3-4b ot-full(vLLM compiled)=543s. enforce_eager + 대형 모델 보정 → 추정: **8-14B 단일 ~40-70분, 24-33B tp=2 ~1.5-3시간**.
- A100 40GB ×6. **1모델=1GPU, tp=2=2GPU, 동시 tp=2 ≤3 lane**.

## 최종 목록 (committed 11 + reference; non-LB tail은 best-effort)

### Wave A — tp=2 LB (GPU 0-1 / 2-3 / 4-5 동시 3 lane) — committed
| # | model | LB key | public | ot-lite uw | extra | est |
|---|---|---|---:|---:|---|---|
| 1 | mistralai/Mistral-Small-24B-Instruct-2501 | mistral-small-24b | **0.5163** | (screen OK) | tokenizer_mode=mistral | ~2h |
| 2 | Qwen/Qwen2.5-32B-Instruct | qwen2.5-32b | 0.5067 | 0.503 | — | ~2.5h |
| 3 | google/gemma-3-27b-it | gemma3-27b | 0.5043 | (screen OK) | MAXLEN 8192(128K) | ~2h |

### Wave B — single-GPU LB (GPU 0-5, 6 동시) — committed
| # | model | LB key | public | ot-lite uw | extra |
|---|---|---|---:|---:|---|
| 4 | microsoft/phi-4 | phi-4-14b | 0.5045 | 0.5225 | — |
| 5 | Qwen/Qwen2.5-14B-Instruct | qwen2.5-14b | 0.4854 | 0.4890 | — |
| 6 | google/gemma-3-12b-it | gemma3-12b | 0.4638 | (PR#4 ot-lite) | MAXLEN 8192 |
| 7 | tiiuae/Falcon3-10B-Instruct | falcon3-10b | 0.4588 | (PR#4) | — |
| 8 | Qwen/Qwen2.5-7B-Instruct | qwen2.5-7b | 0.4579 | (PR#4) | — |
| 9 | google/gemma-2-9b-it | gemma2-9b | 0.4336 | 0.4494 | — |

### Wave C — single-GPU LB(잔여) + 강한 non-LB exotic — committed/best-effort
| # | model | LB key | public | ot-lite uw | extra | tier |
|---|---|---|---:|---:|---|---|
| 10 | mistralai/Mistral-Nemo-Instruct-2407 | mistral-nemo-12b | 0.4177 | 0.4340 | tokenizer_mode=mistral | committed |
| 11 | Qwen/Qwen3-8B | qwen3-8b | 0.4107 | 0.4624 | enable_thinking=False | committed |
| 12 | Qwen/Qwen3-30B-A3B-Instruct-2507-FP8 | — | — | 0.4753 | GMU 0.92 (1GPU FP8) | best-effort(non-LB) |

### reference (이미 완료, 재실행 불요)
- google/gemma-3-4b-it ot-full_gsma = 0.3926 (PR#4, public 동일 split).

### best-effort tail (시간 남으면; drop order = 아래 순서로 제외)
1. Qwen/Qwen3.5-9B (non-LB exotic, ot-lite 0.4460)
2. Qwen/Qwen3-14B (non-LB, PR#4 ot-lite 0.4678)

## GPU 스케줄 (queue)
1. **Wave A 먼저**: 3 tp=2 lane 동시(GPU 0-1=Mistral-Small-24B, 2-3=Qwen2.5-32B, 4-5=gemma-3-27b). ~2.5-3.5h.
2. **Wave B**: 6 단일 GPU 동시(phi-4/Qwen2.5-14B/gemma-3-12b/Falcon3-10B/Qwen2.5-7B/gemma-2-9b). ~1-1.5h.
3. **Wave C**: Mistral-Nemo/Qwen3-8B/Qwen3-30B-FP8(단일) + tail. ~1-1.5h.
- **현실 예상: ~6-8시간 → committed 11 + reference 완료 가능**. 시간 초과 시 non-LB tail(Wave C #12, tail 1-2)부터 drop.

## 실행 형태
- ot-full 런처(otlite용 `run_candidate.sh`의 otfull 버전): 동일 env + `run_open_telco_otfull.sh` 호출, `OUTPUT_PATH=results/otfull-gsma-<safe>`, 1모델=1GPU/tp=2. predownload는 캐시됨(offline-cached 즉시).
- OOM ladder: GMU 0.9→0.92, MAXLEN 8192→4096. 1회 재시도 후 skip+기록.
- crash 시 해당 모델 skip+log, 다음 진행(전체 중단 금지). 미완료 모델 명시.

## 비교/문서 (ot-full 후)
- LB: `compare_gsma_leaderboard.py --profile gsma --model <key> --local-result <otfull json> --out-md outputs/<key>-otfull-gsma-delta.md`.
- non-LB: internal(gemma-3-4b/Qwen2.5-7B/Qwen3-14B 대비).
- `outputs/overnight-otfull-results.md` + 트래커 갱신.

## 제외 (사유)
- openai/gpt-oss-20b(harmony 추론→단답 MC collapse artifact), google/gemma-4-E4B-it(vLLM 토크나이저 비호환), Qwen/Qwen3.6-27B-FP8(다운로드/로드 실패), deepseek-ai/DeepSeek-R1-Distill(collapse artifact), Ministral-8B(생성형 collapse·non-LB 약).

## 무결성
- "공식 GSMA 완전 재현" 미주장. MC engine 미정렬(자유 gen vs 제약 디코딩). non-LB는 public delta 금지. 기존 결과 미덮어쓰기(OUTPUT_PATH 분리). curated JSON만 commit(samples gitignore).
