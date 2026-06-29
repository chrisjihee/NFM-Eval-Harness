# Overnight ot-full_gsma Results (PASS 5)

> **Historical / engineering note:** This file belongs to the engineering/provenance repository.
> For the current INL handoff package and curated final results, use `NFM-Eval-Harness-delivery`.
> Some commit hashes, result paths, or operational notes may reflect the state at the time this file was written.
>
> **역사/개발 메모:** 이 파일은 engineering/provenance 저장소의 문서입니다. 현재 INL 전달 정본과 최종 curated 결과는 `NFM-Eval-Harness-delivery`를 기준으로 확인하세요. 본문 일부 commit hash·result path·운영 메모는 작성 당시 상태를 반영할 수 있습니다.

실행: 2026-06-27 야간~2026-06-28 · 계획: `outputs/overnight-otfull-run-plan.md`(승인됨).
task: `open_telco_otfull_gsma` (16,866 docs, public 동일 split). unweighted task mean.

> 레시피(이 호스트 VM 이슈 대응): standalone `snapshot_download` 선캐시 + `HF_HUB_OFFLINE=1` + `NCCL_SOCKET_IFNAME=lo` + `NCCL_IB_DISABLE=1` + `enforce_eager` + `MAX_MODEL_LEN=8192` + `GPU_MEMORY_UTILIZATION=0.9`(Mistral=`tokenizer_mode=mistral`, Qwen thinking=`enable_thinking=False`). 전 모델 16,866 samples 확인.
> **"공식 GSMA 완전 재현" 미주장.** MC 4종 engine 미정렬(자유 single-letter gen vs 공식 제약 디코딩). non-LB는 public delta 금지(internal only).

## LB 모델 — public delta (full split)

| 모델 | engine | ot-full uw | public | Δ | per-task delta MD |
|---|---|---:|---:|---:|---|
| Qwen/Qwen2.5-32B-Instruct | tp=2 | **0.5050** | 0.5067 | **−0.002** | `qwen2.5-32b-otfull-gsma-delta.md` |
| microsoft/phi-4 | 1 GPU | **0.4959** | 0.5045 | −0.009 | `phi-4-14b-otfull-gsma-delta.md` |
| mistralai/Mistral-Small-24B-Instruct-2501 | tp=2 | **0.4958** | 0.5163 | −0.021 | `mistral-small-24b-otfull-gsma-delta.md` |
| Qwen/Qwen2.5-14B-Instruct | 1 GPU | 0.4791 | 0.4854 | −0.006 | `qwen2.5-14b-otfull-gsma-delta.md` |
| tiiuae/Falcon3-10B-Instruct | 1 GPU | 0.4598 | 0.4588 | **+0.001** | `falcon3-10b-otfull-gsma-delta.md` |
| Qwen/Qwen3-8B | 1 GPU | 0.4479 | 0.4107 | +0.037 | `qwen3-8b-otfull-gsma-delta.md` |
| Qwen/Qwen2.5-7B-Instruct | 1 GPU | 0.4460 | 0.4579 | −0.012 | `qwen2.5-7b-otfull-gsma-delta.md` |
| google/gemma-2-9b-it | 1 GPU | 0.4352 | 0.4336 | **+0.002** | `gemma2-9b-otfull-gsma-delta.md` |
| mistralai/Mistral-Nemo-Instruct-2407 | 1 GPU | 0.4318 | 0.4177 | +0.014 | `mistral-nemo-12b-otfull-gsma-delta.md` |
| google/gemma-3-12b-it | 1 GPU | 0.4264 | 0.4638 | −0.037 | `gemma3-12b-otfull-gsma-delta.md` |
| google/gemma-3-27b-it | tp=2 | 0.4573 | 0.5043 | −0.047 | `gemma3-27b-otfull-gsma-delta.md` |
| google/gemma-3-4b-it (reference, PR#4) | vllm | 0.3926 | 0.3970 | −0.004 | `gemma3-4b-otfull-gsma-delta.md` |

→ **LB 11종(+gemma3-4b ref) 전부 public을 full split에서 재현**: Δ −0.047 ~ +0.037. **비-gemma3 9종은 ±0.021 이내(6종 ±0.012 이내)**. gemma3 계열 2종만 −0.037(gemma3-12b)/−0.047(gemma3-27b)로 더 큼 — gemma 생성형(telemath/telelogs) emission 취약이 원인(MC는 정상, ot-lite에서도 동일 경향). qwen3-8b +0.037은 ot-lite(+0.052)와 동일(public row가 thinking/다른 설정일 가능성 — 정렬 아님). tp=2(32B/27B/24B)도 단일 GPU와 동등 동작.

## non-LB exotic — internal comparison (public delta 없음)

| 모델 | engine | ot-full uw | 비고 |
|---|---|---:|---|
| Qwen/Qwen3-30B-A3B-Instruct-2507-FP8 | 1 GPU FP8(sm80 emul) | 0.4590 | 30B MoE, text-gen, 강함 |
| Qwen/Qwen3-14B | 1 GPU (think-OFF) | 0.4622 | reference 비교군 |
| Qwen/Qwen3.5-9B | 1 GPU MM(think-OFF) | 0.4362 | 멀티모달 arch, text-only 정상 |

내부 비교 기준(ot-full uw): gemma-3-4b 0.3926 < 위 non-LB exotic 전부. Qwen3-30B-A3B-FP8(0.459)·Qwen3-14B(0.462)는 동급 LB(qwen2.5-14b 0.479, falcon3-10b 0.460)와 유사대.

## 운영 메모
- **타이밍**: ot-full(16,866) eager 모드 단일 GPU ~15-40분/모델(teleqna 10k MC는 빠른 배치, 생성형 telemath/telelogs/3gpp가 wall 지배). gemma3 계열은 생성형 단계가 특히 느림(long pole). tp=2도 동등.
- **tp=2 검증**: NCCL loopback fix로 multi-GPU 정상(Qwen2.5-32B/Mistral-Small-24B/gemma-3-27b tp=2 무hang).
- **제외(능력치 아님, ot-full 미실행)**: openai/gpt-oss-20b(harmony 추론→단답 MC collapse artifact), google/gemma-4-E4B-it(vLLM 토크나이저 비호환), Qwen/Qwen3.6-27B-FP8(다운로드/로드 실패), deepseek-ai/DeepSeek-R1-Distill(reasoning collapse artifact, PR#4).
- **결과**: `results/otfull-gsma-<model>/`(curated results_*.json만 추적). ot-lite 스크리닝은 `outputs/model-candidate-plan-extended.md`.
