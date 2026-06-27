# Extended Model Candidate Plan (PASS 5)

작성: 2026-06-27 · 전달: 지능네트워크연구실 · 입력 spec: `.omc/specs/deep-interview-extended-candidates.md`

확장 후보 pool. 모든 행은 **live 검증**: HF `model_info`(repo/size/license/gated), `config.json`(architecture/quant/max_pos), `GSMA/leaderboard` 데이터셋(정확 row명/public avg), vLLM 0.23.0 `ModelRegistry`(arch 지원). 평가는 `open_telco_otlite_gsma`(스크리닝)→선별 `open_telco_otfull_gsma`(overnight).

> 무결성: "공식 GSMA 완전 재현" 미주장. MC 4종 engine 미정렬(자유 single-letter gen vs 공식 제약 디코딩). non-LB는 **public delta 금지**(internal only). collapse=artifact. 기존 결과 미덮어쓰기(OUTPUT_PATH 분리).

## 검증 요약 (핵심 발견)
- **vLLM 0.23.0은 exotic arch 전부 등록**: `Qwen3_5ForConditionalGeneration`, `Qwen3_5MoeForConditionalGeneration`, `Gemma4ForConditionalGeneration`/`Gemma4ForCausalLM`, `GptOssForCausalLM`, `Qwen3MoeForCausalLM` 모두 supported → **load 가능**(환경 변경 불필요). 남은 위험은 런타임 numerics(FP8/MXFP4 sm80 emul)와 행동(단답 MC collapse)뿐 → smoke로 확인.
- **gated 전부 접근 OK**(no 403): gemma-2-9b/27b, gemma-3-27b, Llama-3.1-8B (etri-lirs 토큰).
- **Qwen `-Base` 미접미사 = instruct**(사용자 확인): Qwen3.5-9B/Qwen3.6-27B는 instruct. `*-Instruct` 명시형은 repo 없음(NOT-FOUND).
- naming 주의: leaderboard `--model` key는 dataset row명에 매칭(로컬 dict 아님). 아래 key는 전부 정확 row 검증 완료.

## 후보 표 (bucket A~I)

부호: smoke `s` / ot-lite `L` / ot-full 후보 `F`(§load-gate 통과 hard precondition). 멀티모달=MM(text-only smoke 확인). FP8/MXFP4는 sm80에서 emulated.

### A. 평가 완료 (reference; ot-lite_gsma 보유, PR#4)
| model | LB key | public | ot-lite uw(보유) |
|---|---|---:|---:|
| google/gemma-3-4b-it | gemma3-4b | 0.3970 | 0.3992 |
| Qwen/Qwen2.5-7B-Instruct | qwen2.5-7b | 0.4579 | 0.4544 |
| tiiuae/Falcon3-10B-Instruct | falcon3-10b | 0.4588 | 0.4791 |
| google/gemma-3-12b-it | gemma3-12b | 0.4638 | 0.4277 |
| Qwen/Qwen3-4B | — | — | 0.4463 |
| Qwen/Qwen3-14B | — | — | 0.4678 |

### B. 10B급 leaderboard
| model | key | public | size | arch(vLLM) | gpu | extra | flags |
|---|---|---:|---|---|---|---|---|
| mistralai/Mistral-Nemo-Instruct-2407 | mistral-nemo-12b | 0.4177 | 12.2B dense | MistralForCausalLM✓ | 1 | — | L,F |
| google/gemma-2-9b-it | gemma2-9b | 0.4336 | 9.2B dense | Gemma2ForCausalLM✓ | 1 | — | L,F |
| Qwen/Qwen3-8B | qwen3-8b | 0.4107 | 8.2B dense | Qwen3ForCausalLM✓ | 1 | enable_thinking=False | L,F |
| Qwen/Qwen2.5-14B-Instruct | qwen2.5-14b | 0.4854 | 14.8B dense | Qwen2ForCausalLM✓ | 1 | — | L,F(예비) |

### C. 10B급 non-leaderboard
| model | size | arch(vLLM) | gpu | 위험 | flags |
|---|---|---|---|---|---|
| Qwen/Qwen3.5-9B | 9.7B | Qwen3_5ForConditionalGeneration✓ MM | 1 | MM+thinking | s,L |
| meta-llama/Llama-3.1-8B-Instruct | 8.0B | LlamaForCausalLM✓ | 1(maxlen 8192) | gated(OK) | L |
| mistralai/Ministral-8B-Instruct-2410 | 8.0B | MistralForCausalLM✓ | 1 | — | L |
| google/gemma-4-E4B-it | 8.0B | Gemma4ForConditionalGeneration✓ MM | 1 | MM(any-to-any) | s,L |

### D. 20B급 leaderboard
| model | key | public | size | arch(vLLM) | gpu | flags |
|---|---|---:|---|---|---|---|
| microsoft/phi-4 | phi-4-14b(0.5045)/phi-4(0.4441) | — | 14.7B dense | Phi3ForCausalLM✓ | 1 | L,F |
| mistralai/Mistral-Small-24B-Instruct-2501 | mistral-small-24b | **0.5163** | 23.6B dense | Mistral✓ | tp=2,maxlen8192 | L,F |
| mistralai/Mistral-Small-Instruct-2409 | mistral-small-22b | 0.4666 | 22.2B | Mistral✓ | tp=2 | (옵션) |

### E. 20B급 non-leaderboard
| model | size | arch(vLLM) | gpu | 위험 | flags |
|---|---|---|---|---|---|
| mistralai/Mistral-Small-3.2-24B-Instruct-2506 | 24.0B | Mistral3✓ (MM) | tp=2,maxlen8192 | MM | L,F(tail) |
| Qwen/Qwen3.6-27B-FP8 | 27.8B FP8 | Qwen3_5ForConditionalGeneration✓ MM+fp8 | 1(gmu↑+cap) | MM+FP8(sm80 emul) | s,L |
| openai/gpt-oss-20b | 21.5B MXFP4 | GptOssForCausalLM✓ mxfp4 | 1(maxlen cap) | harmony+MXFP4 | s만 |

### F. 30B급 leaderboard
| model | key | public | size | arch(vLLM) | gpu | flags |
|---|---|---:|---|---|---|---|
| Qwen/Qwen2.5-32B-Instruct | qwen2.5-32b | 0.5067 | 32.8B dense | Qwen2ForCausalLM✓ | tp=2,maxlen8192 | L,F |
| google/gemma-3-27b-it | gemma3-27b | 0.5043 | 27.4B dense | Gemma3ForConditionalGeneration✓ | tp=2,maxlen8192 | L,F |
| Qwen/Qwen3-32B | qwen3-32b | 0.4677 | 32.8B dense | Qwen3ForCausalLM✓ | tp=2 | enable_thinking=False / L(예비) |
| google/gemma-2-27b-it | gemma2-27b | 0.4585 | 27.2B dense | Gemma2ForCausalLM✓ | tp=2 | (옵션) |

### G. 30B급 non-leaderboard
| model | size | arch(vLLM) | gpu | 위험 | flags |
|---|---|---|---|---|---|
| Qwen/Qwen3-30B-A3B-Instruct-2507-FP8 | 30.5B MoE(A3B) FP8 | Qwen3MoeForCausalLM✓ fp8 text-gen | 1(~30GB)/tp2, maxlen8192(262K) | FP8(sm80 emul) | s,L,F(tail) |
| Qwen/Qwen3.6-27B | 27.8B | Qwen3_5ForConditionalGeneration✓ MM | tp=2,maxlen8192 | MM | s,L |
| google/gemma-4-31B-it | 32.7B | Gemma4ForConditionalGeneration✓ MM | tp=2,maxlen8192 | MM | s,L(예비) |

### H. creative/optional
| model | key | public | size | arch | gpu | flags |
|---|---|---:|---|---|---|---|
| mistralai/Mixtral-8x7B-Instruct-v0.1 | mixtral-8x7b | 0.3490 | 46.7B MoE(~13B act) | MixtralForCausalLM✓ | tp=3 | (자원 여유 시) |

### I. SKIP (사유)
| model | skip_reason |
|---|---|
| Qwen/Qwen3.5-9B-Instruct, Qwen3-8B-Instruct-2507, Qwen3.6-27B-Instruct, Qwen3.6-35B-A3B-Instruct | repo not found (un-suffixed가 instruct) |
| Qwen/Qwen3.5-9B-FP8 | not found |
| mistralai/Mixtral-8x22B-Instruct-v0.1 (140.6B) | too large for overnight (tp≥6) |
| openai/gpt-oss-120b (LB 0.5827) | too large / format |
| deepseek-ai/DeepSeek-R1-Distill-Qwen-14B | MC collapse artifact 확정(PR#4) |

## 실행 / GPU 정책
- A100 40GB ×6. **1 모델 = 1 GPU 전유**(packing 금지; otfull GMU 0.7 기준 14B도 카드 포화). tp=2는 2 GPU/모델, **동시 ≤3 lane**.
- 128K+ context 모델(Llama-3.1/gemma-3-27b/Qwen3-30B-FP8 262K)은 `MAX_MODEL_LEN=8192`로 KV cap(우리 prompt ≤1024 tok).
- thinking 계열(Qwen3-8B/32B, Qwen3.5/3.6) `EXTRA_MODEL_ARGS=enable_thinking=False`(미적용 시 default+caveat).
- FP8/MXFP4는 sm80 native 미지원→emulated. smoke에서 **load AND throughput**(ot-lite < ~30min) 확인 후에만 `[F]` 승격. gpt-oss는 환경변경 신호 시 즉시 skip+isolated-env proposal.
- 결과 `results/otlite-gsma-<safe>/` 분리, curated `results_*.json`만 추적(`samples_*.jsonl`·`*.log` gitignore).

## 결과 — ot-lite_gsma 스크리닝 (신규 11모델, 2026-06-27)

unweighted task mean. LB는 정확 row public delta, non-LB는 internal. 전 모델 위 레시피로 실행.

| 모델 | size | uw | public | Δ | bucket |
|---|---|---:|---:|---:|---|
| microsoft/phi-4 | 14.7B | **0.5225** | 0.5045 | +0.018 | 20B LB |
| Qwen/Qwen2.5-32B-Instruct (tp2) | 32.8B | **0.5030** | 0.5067 | −0.004 | 30B LB |
| mistralai/Mistral-Small-24B-Instruct-2501 (tp2) | 23.6B | **0.5013** | 0.5163 | −0.015 | 20B LB |
| Qwen/Qwen2.5-14B-Instruct | 14.8B | 0.4890 | 0.4854 | +0.004 | 10B LB |
| Qwen/Qwen3-30B-A3B-Instruct-2507-FP8 | 30.5B MoE | 0.4753 | — | — | 30B non-LB exotic |
| Qwen/Qwen3-8B | 8.2B | 0.4624 | 0.4107 | +0.052 | 10B LB |
| google/gemma-3-27b-it (tp2) | 27.4B | 0.4563 | 0.5043 | −0.048 | 30B LB (gen emission 약) |
| google/gemma-2-9b-it | 9.2B | 0.4494 | 0.4336 | +0.016 | 10B LB |
| Qwen/Qwen3.5-9B | 9.7B MM | 0.4460 | — | — | 10B non-LB exotic |
| mistralai/Mistral-Nemo-Instruct-2407 | 12.2B | 0.4340 | 0.4177 | +0.016 | 10B LB |
| mistralai/Ministral-8B-Instruct-2410 | 8.0B | 0.3500 | — | — | non-LB (gen collapse) |

- **LB 8종 모두 public 재현**(Δ −0.048~+0.052, 대부분 ±0.02). 10B/20B/30B 각 bucket에 LB·non-LB ≥1.
- exotic: Qwen3.5-9B(Qwen3_5 MM arch, text-only 정상), Qwen3-30B-A3B-FP8(sm80 emulated, 강함) 모두 동작.
- gemma-3-27b −0.048은 gemma 계열 생성형(telemath/telelogs) emission 취약이 ot-lite 소표본에서 증폭된 것(MC는 정상).

### SKIP/artifact 확정
| 모델 | 사유 |
|---|---|
| openai/gpt-oss-20b | 로드 OK(MXFP4 vLLM 0.23 지원)이나 harmony 추론채널(`<|channel|>analysis`)이 단답 MC(max_gen_toks:8)에서 truncate → MC collapse=artifact(R1-distill류). |
| google/gemma-4-E4B-it | vLLM이 Gemma4 any-to-any 토크나이저 인스턴스화 실패(`Couldn't instantiate the backend tokenizer`). |
| Qwen/Qwen3.6-27B-FP8 | 다운로드/로드 실패(재시도 대상, 이번 미채택). |
| deepseek-ai/DeepSeek-R1-Distill-14B | (PR#4) reasoning collapse artifact. |

### 환경 주의 (이 호스트, PASS5에서 발견)
- 동일 호스트에 QEMU VM 가동 시: (1) NCCL 인터페이스 자동탐지가 VM의 vnet0/virbr/ibp* 에 hang → `NCCL_SOCKET_IFNAME=lo NCCL_IB_DISABLE=1` 필수. (2) vLLM/lm_eval **in-process HF-hub 다운로드 hang** → standalone `snapshot_download` 선다운로드 후 `HF_HUB_OFFLINE=1`로 평가. (3) 강제종료 후 stale `~/.cache/huggingface/**/*.lock` 삭제 + EngineCore zombie reap 필수.
- ot-lite 기본 `GPU_MEMORY_UTILIZATION=0.5`는 9B+ 모델 KV cache 부족 → `0.9` 사용.

### 다음
- ot-full_gsma overnight(승인됨): `outputs/overnight-otfull-run-plan.md` 참조. 결과는 `outputs/overnight-otfull-results.md`.
