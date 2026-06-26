# Latest Result Summary

마지막 갱신: 2026-06-26

## 이번 pass 핵심 결과 (원인 격리)

1. **MC 격차의 지배적 원인 = scoring 방식.** 객관식을 generation 후 답 추출(`*_mcgen`, 비-default 실험)로
   바꾸면 점수가 public에 거의 일치 — gemma·Qwen **두 모델에서 재현**.
   - gemma: teleqna 0.451→**0.658**(pub 0.652), oranbench 0.373→**0.667**(pub 0.660), srsranbench 0.520→**0.780**(pub 0.740)
   - qwen: teleqna 0.532→**0.720**(pub 0.702), oranbench 0.380→**0.720**(pub 0.698), srsranbench 0.420→**0.820**(pub 0.777)
   - 공식 방식은 UNKNOWN이므로 `*_mcgen`는 **비-default 유지**(default scoring 동결, "공식 정렬" 주장 아님, scoring sensitivity 분석).
2. **생성형 저점수는 truncation 때문이 아님.** `MAX_LENGTH` 2048→8192로 truncation 0건이어도 점수 불변
   (telemath 0.01, 3gpp 0.06). 다음 가설: `max_gen_toks=48` + `until:["\n"]`가 CoT를 절단 → 다음 실험 권고.
3. **hf ↔ vllm parity OK** (MC |Δ|≤0.02).
4. **집계방식 정정**: local group acc는 sample-weighted, public는 unweighted. gemma 동일기준 0.255 vs 0.397 = −0.142.

## 현재 Baseline (재현, 2026-06-26)

- 모델: `google/gemma-3-4b-it` | Backend: `hf` | Task group: `open_telco_otlite` (full)
- default group acc(sample-weighted): `0.370` / 7-task 단순평균: `0.255`
- `open_telco_otlite_mcgen`(비-default) group acc: `0.673`
- 결과: `results/otlite-gemma3-4b-hf-2/google__gemma-3-4b-it/`
- leaderboard 비교: `outputs/gemma3-4b-leaderboard-delta.md`

## 비교 모델

- `Qwen/Qwen2.5-7B-Instruct` | `hf` | `open_telco_otlite`: default group `0.423`(uw 0.286), mcgen group `0.732`
- 결과: `results/otlite-qwen2.5-7b-hf-1/`

## ot-full 최초 full run (public와 동일 split, 2026-06-26)

- 모델: `google/gemma-3-4b-it` | Backend: `vllm`(tp=2) | 16,866 docs
- default unweighted **0.251** vs public **0.397** (delta −0.146); group(sample-weighted) 0.354
- **mcgen near-reproduction (대규모 N)**: teleqna 0.422→**0.630**(pub 0.652, N=10k), oranbench 0.353→**0.635**(pub 0.660), srsranbench 0.551→**0.777**(pub 0.740)
- teletables degraded(표 데이터 부재), generation(telemath/3gpp) 여전히 낮음(별도 원인)
- 결과: `results/otfull-gemma3-4b-vllm-1/` · 비교: `outputs/gemma3-4b-otfull-leaderboard-delta.md`

## 미실행 / 다음 단계

- generation-budget 실험(`max_gen_toks`↑ + `until` 완화)로 telemath/3gpp 저점수 원인 확정.
- TeleTables 원본 표(`TELETABLES_ROOT`) 확보 시 teletables 재측정.
- (선택) `*_mcgen` 공식 추출 방식 확인 시 default 승격 재검토(별도 승인).
