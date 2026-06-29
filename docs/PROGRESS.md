# Progress

> **Historical / engineering note:** This file belongs to the engineering/provenance repository.
> For the current INL handoff package and curated final results, use `NFM-Eval-Harness-delivery`.
> Some commit hashes, result paths, or operational notes may reflect the state at the time this file was written.
>
> **역사/개발 메모:** 이 파일은 engineering/provenance 저장소의 문서입니다. 현재 INL 전달 정본과 최종 curated 결과는 `NFM-Eval-Harness-delivery`를 기준으로 확인하세요. 본문 일부 commit hash·result path·운영 메모는 작성 당시 상태를 반영할 수 있습니다.

마지막 갱신: 2026-06-27

## 현재 상태

- 이 저장소에는 GSMA `ot-lite`와 `ot-full`을 위한 LM-Evaluation-Harness task
  정의가 들어 있습니다.
- **task name 정책 (rename)**: 기본/권장 GSMA-compatible 그룹은
  `open_telco_otlite_gsma` / `open_telco_otfull_gsma`입니다(run 스크립트 기본값 —
  `TASKS`를 생략하면 이 그룹이 실행됨, unweighted). legacy lm-eval/loglikelihood
  baseline은 `open_telco_otlite_lm_eval_baseline` /
  `open_telco_otfull_lm_eval_baseline`로 보존됩니다(삭제 안 함, diagnostic).
  bare `open_telco_otlite` / `open_telco_otfull`은 **실행 불가**입니다(run
  스크립트가 fail-fast). `*_mcgen`은 diagnostic(불변)입니다.
- `open_telco_otlite_lm_eval_baseline`(구 `open_telco_otlite`)은 7개 benchmark
  `acc` 점수의 평균을 사용하는 비교용 task pack입니다.
- `open_telco_otfull_lm_eval_baseline`(구 `open_telco_otfull`)은 공개 Open Telco
  leaderboard의 7개 benchmark column을 맞추는 방향으로 구성되어 있습니다.
- 실행 스크립트는 Hugging Face backend와 vLLM backend를 지원합니다.
- **2026-06-27 전달판 검증 pass(지능네트워크연구실)**: `open_telco_otlite_gsma`
  full로 6모델 평가 완료. leaderboard 3종(Qwen2.5-7B 0.4544/−0.0035,
  Falcon3-10B 0.4791/+0.0203, gemma-3-12b 0.4277/−0.0362) + 내부 비교 3종
  (Qwen3-4B 0.4463, Qwen3-14B 0.4678, DeepSeek-R1-Distill-14B 0.0514⚠).
  R1-Distill은 `enable_thinking=False`를 무시하는 reasoning 모델이라 MC가
  구조적으로 붕괴(artifact, 능력치 아님). 후보 계획은 `outputs/model-candidate-plan.md`. TeleTables `_gsma`=question-only
  =GSMA parity(저평가 아님), TeleMath 문서 max_gen_toks per-task(1024/256) 정정.

## 최근 Baseline

- 날짜: 2026-05-15
- 모델: `google/gemma-3-4b-it`
- Backend: Hugging Face
- Task group: `open_telco_otlite` (historical pre-rename name; 현재 실행 이름은
  legacy `open_telco_otlite_lm_eval_baseline`. 권장 기본은 `open_telco_otlite_gsma`.)
- 결과: `acc=0.3718`
- 결과 파일:
  `results/open_telco_otlite/google__gemma-3-4b-it/results_2026-05-15T15-40-57.791797.md`

## 2026-06 패키징 pass (완료)

deep-interview → ralplan(consensus) → autopilot 흐름으로 진행. 계획:
`.omc/plans/nfm-eval-harness-consensus-plan.md`.

완료(GPU 불필요):
- Claude/GPT 중복 문서 6종을 한국어 중심 `CLAUDE.md`/`HANDOFF.md`/`FIRST_PROMPT.md`로
  통합하고 분리본은 `git rm`.
- **집계방식 정정**: local group acc `0.3718`은 sample-weighted(teleqna 1000샘플 지배),
  7-task 단순평균은 `0.259`. public `0.397`은 unweighted task mean →
  동일기준 실제 격차 약 `−13.8%p`(후보, 단정 아님). 최대 격차는 객관식 MC 3종.
- `scripts/smoke_test.sh` + `make smoke`(GPU 없이 task loading 검증) 추가 →
  18개 task(otlite/otlite_core4/otfull) 전부 로드 OK.
- `scripts/compare_gsma_leaderboard.py`(local↔`GSMA/leaderboard` delta, 가중/비가중 병기) 추가.
- `run_open_telco_*.sh`에 `LIMIT`/`CONFIRM_FULL_RUN` 가드 추가(가드 없는 full run 거부).
- 추적 문서의 raw `lm_eval` 실행 예시를 전부 `--limit`/가드 형태로 교체.
- `lm_eval`(pin `97a5e2c7`, `v0.4.12-12-g97a5e2c7`)를 `.venv`에 editable 설치
  (`--no-deps` + 보조 deps 6종, 하드핀 torch/vllm/transformers/datasets 불변 확인).
- Phase 0.5(attribution probe): `GSMA/leaderboard`에는 variant/extraction 컬럼이 없어
  public `gemma3-4b` variant pin 불가 → 재현 주장은 bounded 유지, `*_mcgen`는 비-default 동결.

완료(Phase 3, GPU 불필요):
- 비-default `open_telco_{teleqna,oranbench,srsranbench}_mcgen` + group 추가
  (leak-guard pytest 통과, default scoring 동결, append-only).

완료(Phase 4, GPU — 비-critical 자동 실행, ot-lite full):
- **MC 격차의 지배적 원인 = scoring 방식**: mcgen(generation MC)이 public에 거의 일치,
  gemma·Qwen 2개 모델에서 재현(상세 `EXPERIMENTS.md` 2026-06-26).
- **생성형 저점수는 truncation 아님**: `MAX_LENGTH` 2048→8192로 truncation 0건이어도 점수 불변.
- `hf`↔`vllm` parity OK. 비교 모델 `Qwen/Qwen2.5-7B-Instruct` baseline 확보.
- 산출물: `outputs/gemma3-4b-leaderboard-delta.md`, `results/otlite-*-{2,maxlen8192,vllm-3}`, `results/otlite-qwen2.5-7b-hf-1`.

## 2026-06-27 GSMA scoring contract 정렬 pass (완료)

계획: `.omc/plans/gsma-alignment-consensus-plan.md`, spec: `.omc/specs/gsma-alignment-2026-06.md`.
원칙: lm-eval 유지, additive only, default scoring 동결, "공식 GSMA 완전 재현" 미주장
(= public 코드 정렬 시도). 공식 contract는 `gsma-evals/src/evals/*` 소스 1:1 대조.

완료(코드, GPU 불필요):
- 신규 비-default 그룹 `open_telco_otlite_gsma` / `open_telco_otfull_gsma`(unweighted,
  `weight_by_size: false`) + 7-task 구성: MC 4종 `*_mcgen`(teletables 포함) + 생성형 3종 `*_gsma`.
- 신규 utils 함수/상수(append-only, ot-full에 importlib 재노출): `extract_boxed_last`,
  `extract_first_int`, `extract_wg_token`(default first-match), `process_results_{telemath,telelogs,3gpp}_gsma`,
  `doc_to_text_*_gsma`(+ `*_hinted` collapse 대체), `BOXED_NESTED_RE`/`WG_GSMA_RE`/`WS_COLLAPSE_RE`/`DIGIT_GSMA_RE`.
  scorer는 공식 소스와 동일(telemath isclose 0.01+exact fallback / telelogs soft 첫 정수 / 3gpp WG regex ignorecase first-match).
- `compare_gsma_leaderboard.py`에 `--profile gsma`(per-task delta 표 먼저 + 라벨링된 unweighted mean + MC engine 미정렬 caveat).

완료(문서, 이번 항목):
- 신규 `GSMA_SCORING_CONTRACT.md`(per-task 공식 contract 표 + scorer-aligned vs engine-different split
  + MC engine 미정렬이 지배 동인 + boxed/WG collapse risk + max_gen_toks 의도 + sixg_bench note).
- `TASK_MANIFEST.md`/`REPRODUCTION_NOTES.md`/`CLAUDE.md`/`HANDOFF.md` 갱신(신규 그룹/프로파일 사용법·run 명령·collapse gate 절차·미주장 원칙).

완료(GPU run, gemma-3-4b-it, vLLM):
- collapse gate 통과: telemath `max_gen_toks` 256→1024로 boxed-rate 0.00→0.80 회복(commit).
- **`open_telco_otlite_gsma` unweighted `0.3992` ≈ public `0.397` (+0.0022)**.
- **`open_telco_otfull_gsma`(public 동일 split, 대규모 N) unweighted `0.3926` ≈ public `0.397` (−0.0044)**.
- telelogs: ot-lite raw collapse(0.090) / `_gsma_hinted` 0.13 / ot-full faithful 0.118 ≈ public 0.117(대규모에선 collapse 없음).
- 결론: ~−13.8%p 후보 격차의 거의 전부가 **scoring 방식 + 집계 차이**(ot-lite·ot-full 일관). "공식 재현" 아님(engine 미정렬).
- 산출물: `outputs/gemma3-4b-{otlite,otfull}-gsma-delta.md`, `results/open_telco_{otlite,otfull}_gsma/`, `results/telelogs_gsma_hinted/`.

## 완료된 PR / milestone

- **PR #1** — 문서 통합 + GSMA 재현 진단(격차 = 집계 artifact).
- **PR #2** — GSMA 공개 scoring contract 정렬(`*_gsma` profile; gemma3-4b ≈ public 0.397).
- **PR #3** — 이름/실행경로 정리(`*_gsma` 기본화, legacy `*_lm_eval_baseline`, bare name fail-fast).
- **PR #4** — 전달용 6모델 ot-lite 평가 + TeleMath/TeleTables 정정 + R1-Distill collapse artifact 규명.
- **PR #5** — 확장 후보 검증(ot-lite 11종 + ot-full 14종 full-split; LB 전부 public 재현).

## 남은 필수 blocker

- 없음. (`open_telco_otfull_gsma` full split 14종 평가 완료, 전달 문서/manifest 정리 완료.)

## 선택적 후속 작업 (인수 후, 필요 시에만)

- 신규 모델 추가 시 `open_telco_otlite_gsma` smoke → `open_telco_otfull_gsma` 순서로 확장.
- reasoning/harmony 모델용 별도 non-GSMA diagnostic profile 설계(현재는 단답 MC engine과 비호환 → artifact).
- legacy/internal teletables superset가 필요할 때만 `TELETABLES_ROOT` 사용(GSMA `_gsma` 결과에는 불필요).
- generation-budget 실험으로 gemma 계열 telemath/telelogs emission 개선 탐색.
- (선택) `*_mcgen` 공식 추출 방식이 확인되면 default 승격 재검토(별도 승인 필요).
- NFM 고유 task 확장(2차 과제 범위): telco Korean QA, intent-to-recipe, RCA, RAG-grounded QA.

## Handoff Notes

- 작업 규칙의 시작점은 `CLAUDE.md`입니다.
- 전체 log를 계획 문서에 붙여넣기보다 `EXPERIMENTS.md`에 실행 요약을 남깁니다.
- 최신 경량 결과 snapshot은 `outputs/latest-summary.md`에 유지합니다.
