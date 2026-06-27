# Experiments

이 파일은 benchmark 실행을 짧게 정리하는 index입니다. Raw log나 큰 산출물은
넣지 않고, 필요하면 추적되는 summary 또는 local path만 연결합니다.

> **Rename 안내 (historical preservation).** 아래 Run Index와 과거 run 섹션의
> task 이름(`open_telco_otlite` / `open_telco_otfull` 및 결과 경로
> `results/open_telco_otlite/...`)은 **그 run이 실제로 그 이름으로 실행된
> 역사적 사실**이며 그대로 보존합니다. 이후 rename 정책으로 bare
> `open_telco_otlite` / `open_telco_otfull`은 실행 불가가 되었고, 현재 실행
> 이름은 권장/기본 `open_telco_{otlite,otfull}_gsma` 또는 legacy
> `open_telco_{otlite,otfull}_lm_eval_baseline`입니다. 새 실행 명령은 이 새
> 이름을 씁니다.

## Run Index

| Date | Run ID | Model | Backend | Tasks | Result | Notes |
|---|---|---|---|---|---:|---|
| 2026-05-15 | `otlite-gemma3-4b-hf-main` | `google/gemma-3-4b-it` | `hf` | `open_telco_otlite` | `0.3718 acc` | 첫 7-task `ot-lite` baseline. Generation task 점수가 낮고 truncation warning이 관찰됨. |
| 2026-06-26 | `otlite-gemma3-4b-hf-2` | `google/gemma-3-4b-it` | `hf` | `open_telco_otlite`(+`_mcgen`) | `0.370 acc` (uw 0.255) | 재현 baseline. mcgen(generation MC) group=`0.673`. |
| 2026-06-26 | `otlite-gemma3-4b-hf-maxlen8192` | `google/gemma-3-4b-it` | `hf` | `open_telco_otlite` | `0.366 acc` | `MAX_LENGTH=8192`. truncation 0건이나 generation 점수 불변(=truncation 원인 아님). |
| 2026-06-26 | `otlite-gemma3-4b-vllm-3` | `google/gemma-3-4b-it` | `vllm` | `open_telco_otlite` | `0.365 acc` | hf와 parity(노이즈 내). |
| 2026-06-26 | `otlite-qwen2.5-7b-hf-1` | `Qwen/Qwen2.5-7B-Instruct` | `hf` | `open_telco_otlite`(+`_mcgen`) | `0.423 acc` (uw 0.286) | 비교 모델. mcgen group=`0.732`. |
| 2026-06-26 | `otfull-gemma3-4b-vllm-1` | `google/gemma-3-4b-it` | `vllm`(tp=2) | `open_telco_otfull`(+`_mcgen`) | `0.354 acc` (uw 0.251) | **public와 동일 split**. mcgen group=`0.648`. teletables(default column) degraded; `_mcgen`/`_gsma`는 question-only=GSMA parity. |
| 2026-06-27 | `otlite-gsma-gemma3-4b-vllm` | `google/gemma-3-4b-it` | `vllm` | `open_telco_otlite_gsma` | `0.3992 acc` (unweighted) | **GSMA-aligned scorer. unweighted ≈ public 0.397 (+0.002).** |
| 2026-06-27 | `telelogs-gsma-hinted-gemma3-4b-vllm` | `google/gemma-3-4b-it` | `vllm` | `open_telco_telelogs_gsma_hinted` | `0.13 acc` | telelogs raw collapse(0.090) → format-hint 회복 ≈ public 0.117. |
| 2026-06-27 | `otfull-gsma-gemma3-4b-vllm` | `google/gemma-3-4b-it` | `vllm` | `open_telco_otfull_gsma` | `0.3926 acc` (unweighted) | **public 동일 split·대규모 N에서 ≈ public 0.397 (−0.004).** telelogs faithful 0.118≈0.117. |
| 2026-06-27 | `otlite-gsma-qwen2.5-7b-vllm` | `Qwen/Qwen2.5-7B-Instruct` | `vllm` | `open_telco_otlite_gsma` | `0.4544` (unweighted) | **delivery LB.** ≈ public 0.4579 (−0.0035), 근접재현. |
| 2026-06-27 | `otlite-gsma-falcon3-10b-vllm` | `tiiuae/Falcon3-10B-Instruct` | `vllm` | `open_telco_otlite_gsma` | `0.4791` (unweighted) | **delivery LB.** vs public 0.4588 (+0.0203). |
| 2026-06-27 | `otlite-gsma-gemma3-12b-vllm` | `google/gemma-3-12b-it` | `vllm` | `open_telco_otlite_gsma` | `0.4277` (unweighted) | **delivery LB.** vs public 0.4638 (−0.0362); `MAX_MODEL_LEN=8192`(128K KV>40GB); telemath 0.04 emission. |
| 2026-06-27 | `otlite-gsma-qwen3-4b-vllm` | `Qwen/Qwen3-4B` | `vllm` | `open_telco_otlite_gsma` | `0.4463` (unweighted) | **delivery 내부.** `enable_thinking=False`, 응답 `<think>` 0/1700. |
| 2026-06-27 | `otlite-gsma-qwen3-14b-vllm` | `Qwen/Qwen3-14B` | `vllm`(tp=2) | `open_telco_otlite_gsma` | `0.4678` (unweighted) | **delivery 내부.** think-OFF 0/1700. telelogs 0.0=`\boxed{}` 미출력(emission 0.01). |
| 2026-06-27 | `otlite-gsma-deepseek-r1-distill-14b-vllm` | `deepseek-ai/DeepSeek-R1-Distill-Qwen-14B` | `vllm`(tp=2) | `open_telco_otlite_gsma` | `0.0514` (unweighted) ⚠ | **delivery 내부.** MC 붕괴=artifact: reasoning 모델이 `enable_thinking=False` 무시→MC max_gen_toks:8에 추론 산문 truncate. 능력치 아님. |

## 2026-05-15: Gemma 3 4B IT On ot-lite

- 명령:
  `MODEL_NAME=google/gemma-3-4b-it ./run_open_telco_otlite.sh`
- 출력:
  `results/open_telco_otlite/google__gemma-3-4b-it/results_2026-05-15T15-40-57.791797.md`
- Group score: `open_telco_otlite acc=0.3718`

Task별 점수:

| Task | `acc` | `acc_norm` |
|---|---:|---:|
| `open_telco_teleqna` | `0.4500` | `0.4490` |
| `open_telco_teletables` | `0.2000` | `0.2300` |
| `open_telco_oranbench` | `0.3667` | `0.5000` |
| `open_telco_srsranbench` | `0.5467` | `0.5467` |
| `open_telco_telemath` | `0.0100` | - |
| `open_telco_telelogs` | `0.1700` | - |
| `open_telco_3gpp_tsg_gen` | `0.0700` | - |

해석:

- 상대적으로 강한 영역은 `srsranbench`, `teleqna`입니다.
- 약한 영역은 `telemath`, `3gpp_tsg_gen`, `telelogs`입니다.
- 긴 prompt에서 left-truncation warning이 반복적으로 발생했으므로, 일부
  generation-heavy task 점수에는 context 손실 영향이 섞였을 수 있습니다.

## 2026-06-26: 원인 격리 실험 (gemma-3-4b-it, Qwen2.5-7B-Instruct, ot-lite full)

### 1) MC scoring 방식이 격차의 지배적 원인 (mcgen A/B) — 2개 모델에서 재현

객관식(MC) task를 default(loglikelihood scoring)와 `*_mcgen`(generation 후 letter 추출, **비-default 실험**)으로 비교.

| MC task | gemma default(LL) | gemma **mcgen** | public gemma3-4b | qwen default(LL) | qwen **mcgen** | public qwen2.5-7b |
|---|---:|---:|---:|---:|---:|---:|
| `teleqna` | 0.4510 | **0.6580** | 0.6523 | 0.5320 | **0.7200** | 0.7024 |
| `oranbench` | 0.3733 | **0.6667** | 0.6600 | 0.3800 | **0.7200** | 0.6982 |
| `srsranbench` | 0.5200 | **0.7800** | 0.7400 | 0.4200 | **0.8200** | 0.7772 |

- generation-based MC가 public 값에 거의 일치 → **공식 GSMA stack이 generation 답 추출 방식일 가능성이 매우 높음**.
- 단, 공식 추출 방식은 repo 문서상 UNKNOWN(`REPRODUCTION_NOTES.md`)이고 `GSMA/leaderboard`에 variant/method 메타데이터가 없어 **확정은 불가**. 따라서 `*_mcgen`는 **비-default 유지**(default scoring 동결). 이는 "공식 정렬"이 아니라 **scoring sensitivity 분석**으로 명명.
- 무결성: `doc_to_text_mc_gen`는 gold-비의존(leak-guard 테스트 통과). 점수 상승은 누수/과적합이 아니라 scoring 방식 차이.

### 2) 생성형 task 저점수의 원인은 truncation이 아님 (gemma, 음성 결과)

`MAX_LENGTH` 2048 → 8192 비교(같은 모델/task):

| generation task | max_length=2048 | max_length=8192 |
|---|---:|---:|
| `telemath` | 0.0100 | 0.0100 |
| `telelogs` | 0.1700 | 0.1000 |
| `3gpp_tsg_gen` | 0.0600 | 0.0600 |

- left-truncation warning 13건 → 0건으로 사라졌으나 점수는 사실상 불변(telelogs 변화는 n=100 노이즈).
- → **생성형 격차는 context truncation 때문이 아니다.** 다음 유력 가설: `max_gen_toks=48` + `until:["\n"]`가 chain-of-thought를 잘라냄(telemath/3gpp). → generation-budget 실험을 다음 단계로 권고.

### 3) Backend parity (hf ↔ vllm, gemma)

- MC task |Δ| ≤ 0.02, group 0.370(hf) vs 0.365(vllm). 작은 n의 generation task만 노이즈. → **backend는 격차 요인 아님.**

### 4) 집계방식 정정 (재확인)

- gemma `open_telco_otlite` group acc `0.370`은 **sample-weighted**(teleqna 1000샘플 지배). 7-task **단순평균 0.255**.
- public `0.397`은 unweighted task mean → 동일기준 delta `−0.142`(후보 격차).
- 비교 산출물: `outputs/gemma3-4b-leaderboard-delta.md` (`scripts/compare_gsma_leaderboard.py`).

## 2026-06-26 (2): ot-full 최초 full run (gemma-3-4b-it, vLLM tp=2, public와 동일 split)

16,866 docs (teleqna 10000 등). 결과: `results/otfull-gemma3-4b-vllm-1/`, 비교: `outputs/gemma3-4b-otfull-leaderboard-delta.md`.

### default vs public (동일 split)

| public_column | local default | public gemma3-4b | delta |
|---|---:|---:|---:|
| `teleqna` | 0.4220 | 0.6523 | −0.2303 |
| `teletables` | 0.2120 | 0.2733 | −0.0613 (degraded: TELETABLES_ROOT 없음) |
| `oranbench` | 0.3533 | 0.6600 | −0.3067 |
| `srsranbench` | 0.5513 | 0.7400 | −0.1887 |
| `telemath` | 0.0080 | 0.1367 | −0.1287 |
| `telelogs` | 0.1262 | 0.1167 | +0.0095 |
| `three_gpp` | 0.0865 | 0.2000 | −0.1135 |
| **unweighted mean** | **0.2513** | **0.3970** | **−0.1457** |
| group acc (sample-weighted) | 0.3540 | — | — |

### mcgen(generation MC) vs public — 동일 split, 대규모 N에서 near-reproduction

| MC task | default(LL) | **mcgen(gen)** | public | N |
|---|---:|---:|---:|---:|
| `teleqna` | 0.4220 | **0.6302** | 0.6523 | 10000 |
| `oranbench` | 0.3533 | **0.6347** | 0.6600 | 1500 |
| `srsranbench` | 0.5513 | **0.7770** | 0.7400 | 1502 |
| group | 0.40대 | **0.6477** | — | — |

- **결론(강화)**: public과 동일 split + 대규모 N(teleqna 10k)에서도 generation-based MC가 public에 근접 → 공식 GSMA가 generation 답 추출 방식이라는 가설을 강하게 지지. (여전히 공식 미확정 → `*_mcgen` 비-default 유지.)
- teletables(default loglikelihood column)는 표주입 경로 미설정으로 −0.061; **단 `_mcgen`/`_gsma` teletables는 question-only=GSMA parity(공식도 표 미주입) — degraded 아님**. generation(telemath/3gpp)은 ot-lite와 동일하게 낮음(scoring 아닌 generation budget/parser 이슈). telelogs는 public과 동률.
- 실행 메모: vLLM tp=2 종료 시 NCCL/c10 teardown 경고가 로그에 남으나 평가 결과(JSON, full n-samples)는 정상 생성됨.

## 2026-06-27: GSMA-aligned profile (open_telco_*_gsma, gemma-3-4b-it, vLLM)

scorer를 `gsma-evals/src/evals/*` 소스와 1:1 정렬한 **비-default** 프로파일. MC 4종=`*_mcgen`(generation+letter), 생성형 3종=`*_gsma`(telemath isclose 0.01 / telelogs soft 첫정수 / 3gpp WG regex). 그룹은 **unweighted**(`weight_by_size: false`). 상세 contract: `GSMA_SCORING_CONTRACT.md`. **"공식 재현" 주장 아님**(engine 미정렬: MC는 자유 gen vs 공식 제약 디코딩; lm-eval vs Inspect; variant 미확정).

### open_telco_otlite_gsma (faithful, full) vs public gemma3-4b

| task | local `_gsma` | public | delta |
|---|---:|---:|---:|
| teleqna | 0.6610 | 0.652 | +0.0087 |
| oranbench | 0.6733 | 0.660 | +0.0133 |
| srsranbench | 0.7800 | 0.740 | +0.0400 |
| teletables | 0.2500 | 0.273 | −0.0233 |
| telemath | 0.1000 | 0.137 | −0.0367 |
| telelogs (faithful raw) | 0.0900 | 0.117 | −0.0267 |
| three_gpp | 0.2400 | 0.200 | +0.0400 |
| **unweighted mean** | **0.3992** | **0.397** | **+0.0022** |

- **핵심**: GSMA-aligned scoring으로 unweighted 평균 `0.3992` ≈ public `0.397`(+0.0022). 즉 기존 ~−13.8%p 후보 격차의 **거의 전부가 scoring 방식(loglikelihood→generation) + 집계(sample-weighted→unweighted)** 로 설명됨.
- **telelogs prompt-format 효과**: faithful raw `0.090`(collapse) vs `_gsma_hinted`(+1줄 형식 지시) `0.13` ≈ public `0.117`. 격차 원인은 raw question에서 4B가 라벨 미출력 → format hint로 회복. (hinted는 공식 raw-contract 이탈 비교군으로 명시.)
- collapse gate 기록: telemath/telelogs는 `max_gen_toks:256`에서 CoT가 `\boxed{}` 전에 잘려 boxed-rate 0.00 → **1024로 상향**(GSMA 무캡 생성 정합) 후 telemath boxed-rate 0.80 회복.
- 결과: `results/open_telco_otlite_gsma/`, `results/telelogs_gsma_hinted/`. 비교표: `outputs/gemma3-4b-otlite-gsma-delta.md`(`compare_gsma_leaderboard.py --profile gsma`).
- 무결성: per-task delta가 ±0.04 내(아웃라이어 없음), 점수 끼워맞춤·누수·하드코딩 없음. MC engine 미정렬이 최대 미정렬 축임을 compare/contract에 명시.

### open_telco_otfull_gsma (public 동일 split, full, vLLM) vs public gemma3-4b

| task | local `_gsma` | public | delta | N |
|---|---:|---:|---:|---:|
| teleqna | 0.6305 | 0.652 | −0.0218 | 10000 |
| oranbench | 0.6333 | 0.660 | −0.0267 | 1500 |
| srsranbench | 0.7776 | 0.740 | +0.0376 | 1502 |
| teletables | 0.2620 | 0.273 | −0.0113 | 500 |
| telemath | 0.0980 | 0.137 | −0.0390 | 500 |
| telelogs (faithful raw) | 0.1181 | 0.117 | +0.0011 | 864 |
| three_gpp | 0.2285 | 0.200 | +0.0285 | 2000 |
| **unweighted mean** | **0.3926** | **0.397** | **−0.0044** |

- **public 동일 split + 대규모 N에서 재확인**: GSMA-aligned unweighted `0.3926` ≈ public `0.397`(−0.0044). ot-lite(0.3992)와 일관.
- **telelogs faithful `0.118` ≈ public `0.117`**: ot-full(864샘플 + 1024 budget + max_model_len 8192)에서는 raw question collapse가 사라짐 → ot-lite의 collapse는 small-n/budget 아티팩트였음(hinted 없이도 정합). teletables도 0.262≈0.273.
- 결과: `results/open_telco_otfull_gsma/`. 비교표: `outputs/gemma3-4b-otfull-gsma-delta.md`.
- 결론(정직): 기존 ~−13.8%p 후보 격차의 거의 전부가 **scoring 방식 + 집계 방식** 차이로 설명됨(ot-lite·ot-full 양쪽, gemma·Qwen MC 양쪽에서 일관). 여전히 **"공식 재현" 아님**(MC engine 자유 gen vs 제약 디코딩, lm-eval vs Inspect, model variant 미확정).
