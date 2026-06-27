# Progress

마지막 갱신: 2026-06-27

## 현재 상태

- 이 저장소에는 GSMA `ot-lite`와 `ot-full`을 위한 LM-Evaluation-Harness task
  정의가 들어 있습니다.
- `open_telco_otlite`는 7개 benchmark `acc` 점수의 단순 평균을 사용하는 비교용
  task pack입니다.
- `open_telco_otfull`은 공개 Open Telco leaderboard의 7개 benchmark column을
  맞추는 방향으로 구성되어 있습니다.
- 실행 스크립트는 Hugging Face backend와 vLLM backend를 지원합니다.
- 이후 agent가 commit된 repo 파일만 보고도 문맥을 회복할 수 있도록 Codex
  Local/Cloud handoff 문서를 추가했습니다.

## 최근 Baseline

- 날짜: 2026-05-15
- 모델: `google/gemma-3-4b-it`
- Backend: Hugging Face
- Task group: `open_telco_otlite`
- 결과: `acc=0.3718`
- 결과 파일:
  `results/open_telco_otlite/google__gemma-3-4b-it/results_2026-05-15T15-40-57.791797.md`

## 2026-06 패키징 pass (진행 중)

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

## 2026-06-27 GSMA 공식 코드 정렬 pass (진행 중)

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

진행 예정(GPU, 사용자 승인 후):
- pytest(`tests/test_gsma_parsers.py`) → `make smoke` → ot-lite_gsma smoke(LIMIT=20) **HARD gate**
  (drift guard + boxed/WG emission-rate ≥ 0.30 + cap-hit율 + 3gpp first/last confirmation) → 승인 →
  ot-lite_gsma full(gemma, hf) → compare(`--profile gsma`) → ot-full_gsma full(gemma, vLLM).

## 다음 작업

- **[critical 게이트]** `open_telco_otfull` 최초 full run (사용자 승인 후) — public leaderboard와 같은 split.
- generation-budget 실험(`max_gen_toks`↑ + `until` 완화)로 telemath/3gpp 저점수 원인 확정.
- TeleTables 원본 표 데이터(`TELETABLES_ROOT`) 확보 시도 후 teletables 재측정.
- (선택) `*_mcgen` 공식 추출 방식 확인 시 default 승격 재검토(별도 승인).

## Handoff Notes

- Agent 작업 규칙의 시작점은 `AGENTS.md`입니다.
- 전체 log를 계획 문서에 붙여넣기보다 `EXPERIMENTS.md`에 실행 요약을 남깁니다.
- 최신 경량 결과 snapshot은 `outputs/latest-summary.md`에 유지합니다.
