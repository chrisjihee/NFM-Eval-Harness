# Experiments

이 파일은 benchmark 실행을 짧게 정리하는 index입니다. Raw log나 큰 산출물은
넣지 않고, 필요하면 추적되는 summary 또는 local path만 연결합니다.

## Run Index

| Date | Run ID | Model | Backend | Tasks | Result | Notes |
|---|---|---|---|---|---:|---|
| 2026-05-15 | `otlite-gemma3-4b-hf-main` | `google/gemma-3-4b-it` | `hf` | `open_telco_otlite` | `0.3718 acc` | 첫 7-task `ot-lite` baseline. Generation task 점수가 낮고 truncation warning이 관찰됨. |
| 2026-06-26 | `otlite-gemma3-4b-hf-2` | `google/gemma-3-4b-it` | `hf` | `open_telco_otlite`(+`_mcgen`) | `0.370 acc` (uw 0.255) | 재현 baseline. mcgen(generation MC) group=`0.673`. |
| 2026-06-26 | `otlite-gemma3-4b-hf-maxlen8192` | `google/gemma-3-4b-it` | `hf` | `open_telco_otlite` | `0.366 acc` | `MAX_LENGTH=8192`. truncation 0건이나 generation 점수 불변(=truncation 원인 아님). |
| 2026-06-26 | `otlite-gemma3-4b-vllm-3` | `google/gemma-3-4b-it` | `vllm` | `open_telco_otlite` | `0.365 acc` | hf와 parity(노이즈 내). |
| 2026-06-26 | `otlite-qwen2.5-7b-hf-1` | `Qwen/Qwen2.5-7B-Instruct` | `hf` | `open_telco_otlite`(+`_mcgen`) | `0.423 acc` (uw 0.286) | 비교 모델. mcgen group=`0.732`. |

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
