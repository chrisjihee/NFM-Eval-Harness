# CLAUDE.md — NFM-Eval-Harness 작업 지침

이 파일은 Claude Code가 이 저장소에서 작업할 때 자동으로 읽는 프로젝트 지침이다.
배경 맥락과 현재 상태는 `docs/HANDOFF.md`에 있다. 먼저 그 문서를 읽고 이 지침으로 돌아온다.
본 `CLAUDE.md`가 작업 규칙의 단일 진입점이며, Claude Code가 세션 시작 시 자동으로 읽는다.
(이 저장소는 현재 Claude Code 단독으로 작업한다. 다른 코딩 에이전트를 도입하게 되면 그 시점에 본 지침을 기준으로 해당 에이전트용 파일을 파생한다.)

---

## 프로젝트 정체성 (positioning)

이 저장소는 **내부 NFM-LLM baseline harness**이지 공식 GSMA leaderboard stack의 완전 복제가 아니다.
EleutherAI **lm-evaluation-harness 기반**으로 GSMA Open Telco AI 7개 통신 도메인 태스크를 실행한다.

- 소속 과제: ETRI 대형 국가 R&D `차세대 네트워크 AI 파운데이션 모델 개발`.
- 우리 랩: ETRI Language Intelligence Lab (NFM-LLM 언어 모델 평가 모듈 담당).
- 파트너 랩: Intelligent Network Lab.
- 공식 NFM benchmark framework(LLM/LMM/LAM 전반)는 POSTECH 담당이다. 이 저장소를 그 공식 프레임워크로 키우려 하지 말 것.
- 이 저장소 역할: NFM-LLM 후보 base 모델과 도메인 적응 변형을 통신 도메인 LLM 태스크에서 평가하는 baseline harness.

목적은 두 가지다.
1. NFM-LLM 후보 base 모델 간 상대 비교 및 도메인 적응 효과 측정.
2. 공개 GSMA leaderboard 점수에 **가능한 한 근접**하여 harness 신뢰도 확보. **완전 동일 재현은 목표가 아니다** — 공식 stack은 Inspect AI 기반, 우리는 lm-eval 기반이다.

## 읽을 순서 (코딩 전에)

1. `README.md`
2. `docs/HANDOFF.md` — 현재 상태/완료·진행·다음/GPU 승인 프로토콜/결과 위치/알려진 위험.
3. `docs/REPRODUCTION_NOTES.md` — local 결과와 GSMA public leaderboard 관계, 집계방식 정정.
4. `docs/TASK_MANIFEST.md` — task별 dataset/split/output type/metric/parser/알려진 이슈.
5. `docs/ENVIRONMENT.md` — 환경·`lm_eval` pin·재설치 절차.
6. `docs/TROUBLESHOOTING.md` — 알려진 장애 및 회피.
7. `docs/PLAN.md`, `docs/PROGRESS.md`, `docs/EXPERIMENTS.md`, `outputs/latest-summary.md`, `open_telco_lm_eval/README.md`.

저장소 진입점/역할 구분은 root `START_HERE_ENGINEERING.md`에 있다(engineering/provenance vs 전달 정본 `NFM-Eval-Harness-delivery`).

문서 체계: `CLAUDE.md`(본 지침·자동 read) / `docs/HANDOFF.md` / `docs/TASK_MANIFEST.md` / `docs/REPRODUCTION_NOTES.md` / `docs/ENVIRONMENT.md` / `docs/TROUBLESHOOTING.md`. 전달 정본은 별도 저장소 `NFM-Eval-Harness-delivery`.

그다음 코드를 본다.
- `run_open_telco_otlite.sh`, `run_open_telco_otfull.sh`, `setup-pre.sh` / `setup-main.sh` / `setup-post.sh`
- `open_telco_lm_eval/tasks/open_telco_otlite/*.yaml` 및 `utils.py`
- `open_telco_lm_eval/tasks/open_telco_otfull/*.yaml` 및 `utils.py`
- 최신 `results/` 산출물

## Task pack 구조

> **이름 규칙(RENAME, 2026-06).** 기본/권장 group = GSMA-compatible `_gsma`(run script 기본값; `TASKS` 생략 시 실행). legacy lm-eval/loglikelihood baseline은 삭제하지 않고 `_lm_eval_baseline` suffix로 rename(diagnostic only). **bare `open_telco_otlite` / `open_telco_otfull`은 rename되어 실행 불가** — run script가 fail-fast `exit 2`로 거부한다. 현재 task name으로 bare name을 쓰지 말 것.

| Task group | 현재 이름 | 구성 | 비고 |
|---|---|---|---|
| **기본/권장 (GSMA-compatible)** | `open_telco_otlite_gsma` / `open_telco_otfull_gsma` | 7-task: MC 4종 `*_mcgen`(teletables 포함) + 생성형 3종 `*_gsma` | run script 기본값(TASKS 생략 시 실행). leaderboard 비교 가능. scorer만 공식(`gsma-evals`) 정렬, engine은 미정렬(특히 MC). unweighted(`weight_by_size: false`). 상세는 `docs/GSMA_SCORING_CONTRACT.md` |
| legacy baseline (diagnostic only) | `open_telco_otlite_lm_eval_baseline` | 7-task: `open_telco_teleqna_lm_eval_baseline` / `…_teletables…` / `…_oranbench…` / `…_srsranbench…` / `…_telemath…` / `…_telelogs…` / `open_telco_3gpp_tsg_gen_lm_eval_baseline` | 3gpp 그룹은 **생성형** `open_telco_3gpp_tsg_gen_lm_eval_baseline`. lm-eval/loglikelihood baseline(과거 default). |
| legacy baseline (diagnostic only) | `open_telco_otlite_core4_lm_eval_baseline` | legacy 4-task MC | MC 변형 `open_telco_3gpp_tsg_lm_eval_baseline`는 **이 legacy core4 전용** |
| legacy baseline (diagnostic only) | `open_telco_otfull_lm_eval_baseline` | `open_telco_full_*_lm_eval_baseline` 7-task | `utils.py`가 ot-lite utils를 importlib로 재노출 |
| MC sensitivity diagnostic | `open_telco_otlite_mcgen` / `open_telco_otfull_mcgen` | MC 3종(`*_mcgen`)만 | MC-only generation-vs-constrained-decoding sensitivity 진단(불변) |

중요: 3gpp 그룹의 정확한 생성형 task 이름은 (기본 `_gsma` profile) `open_telco_3gpp_tsg_gsma`, (legacy baseline) `open_telco_3gpp_tsg_gen_lm_eval_baseline`이다. MC 변형 `open_telco_3gpp_tsg_lm_eval_baseline`는 legacy `open_telco_otlite_core4_lm_eval_baseline`에서만 쓴다.

**otfull 결합 주석**: `open_telco_lm_eval/tasks/open_telco_otfull/utils.py`는 ot-lite의 `utils.py`를 importlib로 재노출한다(`exec_module` 후 비-underscore 이름 전체를 globals로 복사). 결과적으로 **ot-lite parser/util 변경은 ot-full 동작을 동시에 변경**한다 — 단일 commit이 두 트랙에 동시 영향을 주며 독립 revert가 불가능하다. parser/util을 만질 때는 commit 메시지에 "affects both tracks via importlib re-export"를 명기한다.

**task별 `metadata.version` drift**(legacy `_lm_eval_baseline` 트랙 기준): group `open_telco_otlite_lm_eval_baseline` 및 `telelogs` / `telemath` / `teletables` / `3gpp_tsg_gen` = **v0.2**; `teleqna` / `3gpp_tsg` / `oranbench` / `srsranbench` / `core4` = **v0.1**. "ot-lite 7-task 전부 v0.2"라는 일괄 기술은 부정확하다.

MC task(legacy: `teleqna_lm_eval_baseline` / `teletables_lm_eval_baseline` / `oranbench_lm_eval_baseline` / `srsranbench_lm_eval_baseline`)는 `output_type: multiple_choice` → loglikelihood scoring.
생성형 task(legacy: `telemath_lm_eval_baseline` / `telelogs_lm_eval_baseline` / `3gpp_tsg_gen_lm_eval_baseline`)는 `generate_until`, 전부 `until: ["\n"]`, `do_sample=false`, `max_gen_toks`는 telemath **48** / telelogs **24** / 3gpp_tsg_gen **32**.

**GSMA 정렬 프로파일(`*_gsma` / `*_mcgen`, 비-default)**: scorer만 공식 `gsma-evals/src/evals/*` 소스와 정렬한 additive 그룹이다. default scoring은 동결. **"공식 GSMA 완전 재현"을 주장하지 않는다**(= public 코드 정렬 시도). scorer-aligned이되 **engine은 다르다**: MC 4종은 자유 single-letter `generate_until`(`max_gen_toks:8`)로 공식 제약 디코딩(`multiple_choice(cot=False)`)과 **미정렬 — 가장 큰 미정렬 축이자 지배적 후보 격차 동인**. 생성형 `*_gsma`는 `until:[]` + `max_gen_toks`(telemath/telelogs **1024**, 3gpp **256**)이고 scorer는 공식 동일(telemath isclose 0.01 / telelogs soft 첫 정수 / 3gpp WG regex first-match). telelogs/3gpp는 `\boxed{}`/WG token 미출력 시 soft scorer가 무조건 INCORRECT → **collapse 위험**이므로 smoke emission-rate(≥0.30)가 HARD gate, 미달 시 `*_gsma_hinted` 변형으로 대체 측정. 전체 contract는 `docs/GSMA_SCORING_CONTRACT.md` 참조.

## 핵심 진단 (north star — 독립 검증 완료, 귀인은 미확정)

> **집계방식 정정(중요).** 기존 문서의 "local 0.3718 vs public 0.397, 격차 2.5%p"는 집계방식 착시다.
> - local group acc `0.3718`은 **sample-weighted**다(fork의 `weight_by_size` default True + otlite group YAML 미override → teleqna 1000 sample이 지배). public `0.397`은 **unweighted task mean**이다. 이 `0.3718` run은 historical pre-rename group name `open_telco_otlite`(현재는 `open_telco_otlite_lm_eval_baseline`로 rename, bare name 실행 불가)에서 측정된 것이며 사실 기록으로 보존한다.
> - 동일 기준(둘 다 7-task 단순평균)으로 비교하면 local **0.259** vs public **0.397 ≈ −13.8%p**가 **후보 격차(candidate gap, 단정 아님)**다.
> - 현재 권장 실행 경로는 `_gsma` profile(`open_telco_otlite_gsma`)이며, leaderboard 비교는 이 unweighted profile로 한다.

격차의 **귀인은 미확정**이며 다음 세 요소 중 무엇으로도 설명될 수 있다. 단일 원인으로 단정하지 말 것.
- (a) scoring 방식(loglikelihood vs generation+extract).
- (b) 생성형 truncation(HF run에서 left-truncation 2902→2024 tokens 다발 관찰).
- (c) public row의 model variant 불일치(instruct/base/API/revision 미확인).

최대 후보 기여는 **객관식 MC 3종**(oranbench −0.293, teleqna −0.202, srsranbench −0.193), 그다음 three_gpp −0.130, telemath −0.127. (telelogs는 local이 오히려 +0.053 우위.)

공식 GSMA의 MC 추출 방식은 repo 문서상 **명시적 UNKNOWN**이다. generation 변형의 점수 상승을 "공식 정렬"로 명명/주장하지 말고 "generation-based scoring sensitivity 실험"으로만 다룬다.

비교 수치 스냅샷(재-pull 필요). public column 이름은 leaderboard 자체 라벨이고, local 수치는 historical pre-rename run(group `open_telco_otlite`, 현재 `open_telco_otlite_lm_eval_baseline`)에서 측정된 것이다:
- public gemma3-4b(unweighted): teleqna 0.652 / teletables 0.273 / oranbench 0.660 / srsranbench 0.740 / telemath 0.137 / telelogs 0.117 / three_gpp 0.200 / avg 0.397.
- local 7-task run(historical): teleqna 0.450 / teletables 0.200 / oranbench 0.367 / srsranbench 0.547 / telemath 0.010 / telelogs 0.170 / 3gpp_tsg_gen 0.070.

자세한 분해와 caveat는 `docs/REPRODUCTION_NOTES.md` 참조.

## 작업 순서 (측정 → 진단 → 수정)

1. **현황 재현·진단**: 위 읽을 순서 문서 + 7개 task YAML/parser를 전부 열어 현재 구현을 파악한다. gemma3-4b로 ot-lite를 재실행해 현재 점수를 확보하고 public과 **동일 기준(unweighted task mean)**으로 비교한다.
2. **객관식 4종 점검**: scoring 방식(loglikelihood vs generation-then-extract), few-shot 수, `acc` vs `acc_norm`, 프롬프트 포맷/choices 라벨링을 **한 번에 하나씩** 바꿔 점수 변화를 기록한다. (chat template은 항상 ON이므로 "chat template 테스트"는 끄거나 비교하는 형태로 한다 — 아래 참조.)
3. **생성형 3종 수정 (가장 중요)**: truncation을 먼저 잡고(max_length / max_gen_toks / `until` / left-truncation), parser를 robust하게 한다.
   - `telemath`: 출력에서 최종 수치만 추출(단위·서술 제거, 부호 처리).
   - `telelogs`: 라벨 추출(종종 `\boxed{C6}` 형태).
   - `3gpp_tsg_gen`: 출력 JSON에서 working group 값만 추출(예: `{"WORKING GROUP":"SA5"}` → "SA5").
   - 각 parser는 소형 pytest unit test(샘플 입력→기대 추출값)를 함께 둔다.
4. **비교·기록·패키징**: HF vs vLLM parity를 같은 모델로 비교하고, 비교 모델(`Qwen/Qwen2.5-7B-Instruct`) baseline을 추가한다. `results/`·`docs/EXPERIMENTS.md`·`docs/PROGRESS.md`·`outputs/latest-summary.md`(+ `outputs/run-index.jsonl`)를 갱신하고 commit한다.

## MC scoring 수정 방향 (무결성 우선)

generation-based MC는 **별도 실험 task family `open_telco_*_mcgen`(비-default)**로만 추가한다.
- default scoring은 **동결**한다(기존 결과와 비교 가능성 유지). 기존 multiple_choice task를 보존한다.
- 신규 generation prompt는 **정답 letter를 절대 노출하지 않는다**(leak-guard). 안전 템플릿 원본은 `doc_to_text_mc`(ot-lite `utils.py`)다.
- 점수 상승을 "공식 GSMA 정렬"로 명명/주장하지 않는다(추출 방식 UNKNOWN).
- 무결성 절대 금지: 정답 하드코딩, 데이터 누수, leaderboard 과적합, 특정 모델 출력에만 맞춘 parser 후처리.

## 재현 철학 (반드시 지킬 균형)

- 공식 leaderboard는 Inspect AI 기반, 우리는 lm-eval 기반이다. **완전히 같은 점수는 목표가 아니다.**
- 그러나 격차가 너무 크면 곤란하다(사용자 요구). → **격차를 좁히되, 남는 격차는 방법론 차이(집계방식 / split / prompt·scoring / Inspect AI stack / model variant)로 정직하게 분해·문서화**한다.
- 점수를 억지로 끼워 맞추지 말 것. 평가 무결성을 최우선한다.
- "재현 가능한 내부 baseline harness"와 "공식 GSMA stack 완전 재현"을 항상 명확히 구분한다(완전 재현 주장 금지).

## 코딩·작업 규칙

- **git 위생**: 변경 전 항상 `git status`. 사용자 작업을 명시 요청 없이 삭제/덮어쓰지 않는다. 변경은 작고 리뷰 가능하게, 한 commit에 무관한 변경을 섞지 않는다.
- **lm-eval 유지**: 기존 YAML task 정의와 `utils.py` parser 개선을 다른 프레임워크 도입보다 우선한다. Inspect AI로 전면 교체하지 않는다(비교 스크립트/노트는 추가 가능).
- **측정 우선, 한 번에 하나씩**: 추측으로 고치지 말고 변경 전후 점수를 항상 측정해 비교한다. 변경별로 작은 단위 commit + before/after 기록.
- **결과 추적**: 의미 있는 실행은 `docs/EXPERIMENTS.md` Run Index에 1줄 + 요약을 남긴다. raw 로그 전체를 문서에 붙이지 말고 경로만 연결한다. 평가에 영향을 주는 변경은 `docs/PROGRESS.md`를 갱신하고, run을 했다면 `docs/EXPERIMENTS.md`·`outputs/latest-summary.md`(+ `outputs/run-index.jsonl`)도 갱신한다.
- **commit 산출물 경량 유지**: model cache, 대용량 raw 로그, checkpoint, 거대 생성 artifact를 commit하지 않는다(`.gitignore` 준수). 추적 대상 summary는 `outputs/` 하위에만 둔다.
- **재현성 기록**: 모든 실행 명령(모델, 백엔드, few-shot, chat template 여부, batch_size, dataset split)을 기록한다. 결과가 public과 다르면 의심 원인을 정직하게 명시한다(숨기지 않는다).
- **스코프 경계 존중**: 멀티모달/LMM/LAM, 동적 제어, Planning(Intent→Recipe / TeleYAML), RAG-grounded QA, Korean Telco QA는 **이번 범위 밖(2차 과제)**다. 끌어들이지 말 것.
- **변경 후 체크리스트**(평가 동작에 영향을 준 경우): 관련 task README/문서 갱신 → `docs/PROGRESS.md`에 진행 기록 → run을 했으면 `docs/EXPERIMENTS.md` 요약 + `outputs/latest-summary.md` 반영 → 환경별 이슈는 `docs/ENVIRONMENT.md` 또는 `docs/TROUBLESHOOTING.md`에 남긴다.

## 환경 주의 (GPU 작업 전 필수)

- GPU: **A100 40GB ×6** 가용. gemma3-4b는 단일 GPU로 충분.
- lm-evaluation-harness(`lm_eval`)는 `setup-post.sh`가 PyPI에서 버전 고정으로 설치한다: `uv pip install "lm_eval[hf,vllm]==0.4.12"`(`[hf,vllm]` extra가 보조 deps 자동 설치, setup-main.sh의 torch/vllm/transformers 하드핀은 불변). `.venv`에 미설치이면 `make smoke`가 설치 명령을 안내한다. 재설치 SOP는 `docs/ENVIRONMENT.md` 참조. (과거 engineering 트랙은 git clone + SHA `97a5e2c7`=`v0.4.12`+12 commits를 editable `--no-deps`로 설치했고, 현재 `.venv`는 그 환경(`0.4.13.dev0`)이다 — 결과는 PyPI 0.4.12와 run-to-run 변동 범위 내 동일.)
- 환경 하드핀: Python 3.12.13, torch 2.11.0+cu128, transformers 5.12.1, vllm 0.23.0, lm_eval 0.4.12.
- **기본 backend = vLLM**(run 스크립트 기본값; `MAX_MODEL_LEN=8192`·`GPU_MEMORY_UTILIZATION=0.9` 기본 적용). HF backend(`BACKEND=hf`)는 긴 생성형 입력을 left-truncation 하여 telelogs 등 생성형 task가 collapse할 수 있으므로 경량/대체용이다.
- **vLLM은 CUDA forward-compat에 의존**한다 → GPU 작업 전 `.venv` activate가 필수다(run 스크립트는 activate를 수행함). 미적용 시 vLLM generate가 실패할 수 있으며 그때만 `BACKEND=hf` fallback을 쓴다.
- dataset 로컬 캐시 없음(첫 run에서 다운로드). HF 접근: user=chrisjihee, org=etri-lirs (gemma/llama/qwen 접근 가능).

## GPU 실행 프로토콜 (smoke-first + 단계 승인)

긴 run은 **항상 1장 smoke / bounded `LIMIT` → 예상 시간·GPU 수·측정 sample count·출력 경로 보고 → 승인 → 확대**한다.

- run 스크립트는 `--apply_chat_template`가 **항상 ON**이다. 따라서 chat template 효과를 보려면 끄거나 비교하는 형태로 실험한다.
- `run_open_telco_*.sh`의 주요 env: `MODEL_NAME` / `BACKEND`(기본 `vllm`; `hf`는 경량/대체) / `DEVICE`(hf 전용) / `BATCH_SIZE` / `TASKS` / `VLLM_VISIBLE_DEVICES` / `GPU_MEMORY_UTILIZATION`(기본 0.9) / `MAX_MODEL_LEN`(기본 8192) / `TENSOR_PARALLEL_SIZE`.
- `TELETABLES_ROOT`는 run 스크립트가 set하지 않는다. 기본 `_gsma` profile은 question+choices parity로 평가하므로 저평가가 아니다 — legacy/superset 표 원본이 필요할 때만 별도 export(기본 경로엔 불필요).

> **task name 규칙 재확인.** run script 기본값(TASKS 생략)은 `_gsma`(기본/권장). bare `open_telco_otlite`/`open_telco_otfull`은 rename되어 실행 불가(run script `exit 2`). legacy lm-eval baseline은 `_lm_eval_baseline` suffix를 명시해야 한다(diagnostic only).

```bash
# 환경 준비 (GPU 서버)
./setup-pre.sh && ./setup-main.sh && ./setup-post.sh

# GPU 없이 task 로딩 검증 (smoke)
make smoke

# 기본(권장) ot-lite_gsma 단일-task bounded run (기본 backend = vLLM) — leaf task name도 _mcgen/_gsma suffix
MODEL_NAME=google/gemma-3-4b-it TASKS=open_telco_teleqna_mcgen LIMIT=5 ./run_open_telco_otlite.sh

# 기본(권장) ot-lite_gsma 전체 (TASKS 생략 시 기본값 = open_telco_otlite_gsma; 기본 backend = vLLM; full run은 승인 플래그 필요)
MODEL_NAME=google/gemma-3-4b-it CONFIRM_FULL_RUN=1 ./run_open_telco_otlite.sh

# HF 백엔드 (경량/대체; 긴 입력 left-truncation 주의)
BACKEND=hf MODEL_NAME=google/gemma-3-4b-it CONFIRM_FULL_RUN=1 ./run_open_telco_otlite.sh

# (diagnostic only) legacy lm-eval/loglikelihood baseline — 명시적으로 _lm_eval_baseline 지정
MODEL_NAME=google/gemma-3-4b-it TASKS=open_telco_otlite_lm_eval_baseline CONFIRM_FULL_RUN=1 \
  OUTPUT_PATH=results/open_telco_otlite_lm_eval_baseline ./run_open_telco_otlite.sh

# GSMA 정렬 그룹 — 기본값이므로 TASKS 생략 가능, 명시도 동일(run 스크립트는 --include_path로 신규 YAML 자동 발견)
# 1) ot-lite_gsma smoke (HARD gate: drift guard + boxed/WG emission-rate ≥ 0.30 + cap-hit율 측정)
MODEL_NAME=google/gemma-3-4b-it TASKS=open_telco_otlite_gsma LIMIT=20 \
  OUTPUT_PATH=results/open_telco_otlite_gsma_smoke ./run_open_telco_otlite.sh
# 2) 게이트 통과 후 ot-lite_gsma full
MODEL_NAME=google/gemma-3-4b-it TASKS=open_telco_otlite_gsma CONFIRM_FULL_RUN=1 \
  OUTPUT_PATH=results/open_telco_otlite_gsma ./run_open_telco_otlite.sh
# 3) compare (per-task delta 표 먼저 + 라벨링된 unweighted mean + MC engine 미정렬 caveat)
python scripts/compare_gsma_leaderboard.py --profile gsma --model gemma3-4b \
  --local-result <ot-lite_gsma .json> --out-md results/<...>-gsma-delta.md
# 4) ot-full_gsma full (vLLM; 게이트 통과 + 사용자 승인 시에만)
BACKEND=vllm VLLM_VISIBLE_DEVICES=0 MODEL_NAME=google/gemma-3-4b-it TASKS=open_telco_otfull_gsma \
  CONFIRM_FULL_RUN=1 OUTPUT_PATH=results/open_telco_otfull_gsma ./run_open_telco_otfull.sh
```

**GSMA collapse gate 절차**: ot-lite_gsma smoke(LIMIT=20)에서 telemath/telelogs `\boxed{}` 출력률과 3gpp WG-token 매치율을 측정한다. 어느 하나라도 **< 0.30**이면 full ot-full_gsma run을 BLOCK하고, 해당 task를 `*_gsma_hinted`(+1-line gold-free 출력형식 지시) 변형으로 LIMIT=20 재측정해 emission-rate 회복 시에만 사용자 승인하에 비교군으로 진행한다(절차 상세: `docs/GSMA_SCORING_CONTRACT.md` §2.3).

프로덕션 실행은 raw `lm_eval` 직접 호출 대신 가드된 run 스크립트(`LIMIT=N` 또는 `CONFIRM_FULL_RUN=1`)를 사용한다.

## 절대 하지 말 것

- 정답 누수/하드코딩, 특정 모델 출력에만 맞춘 parser 과적합, leaderboard 과적합, 모델별 사후 튜닝.
- 측정 없이 "고쳤다"고 보고하기.
- "공식 GSMA leaderboard 완전 재현" 주장(내부 baseline harness와 구분).
- generation 변형 점수 상승을 "공식 정렬"이라 명명, default scoring 변경.
- 승인 없는 다중 GPU 장기 run, unbounded GPU job.
- 범위 밖 기능(멀티모달/동적/Planning/RAG/한국어셋) 선구현.
- `results`/cache/checkpoint 무분별 commit, 문서(`docs/EXPERIMENTS`/`docs/PROGRESS`/`outputs`) 갱신 없이 세션 종료.
