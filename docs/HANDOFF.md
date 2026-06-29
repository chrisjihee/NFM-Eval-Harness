# NFM-Eval-Harness 핸드오프 문서

> 작성일: 2026-06-27
> 목적: 이 저장소(`NFM-Eval-Harness`)를 이어받아 작업하는 Claude Code가 프로젝트의 전체 맥락,
> 현재 구현 수준, 확정된 진단, 그리고 무엇을 마무리해야 하는지를 한 번에 파악하기 위한 문서.
> 이 문서는 배경·상태 전달용이다. 실제 작업 규칙·우선순위는 `CLAUDE.md`, agent 작업 규칙은 `AGENTS.md`를 따른다.
> 확정 진단/요구사항의 원전(source of truth)은 `.omc/specs/deep-interview-nfm-eval-harness.md`와
> `.omc/plans/nfm-eval-harness-consensus-plan.md`(APPROVED)이다.

---

## 0. 한 줄 요약

GSMA Open Telco AI Leaderboard의 7개 통신 도메인 task를 **EleutherAI lm-evaluation-harness 기반**으로
재현·비교하는 내부 평가 하네스다. 골격은 거의 완성됐고, 핵심 문제는 두 가지다.
첫째, **집계방식 차이를 정정하고 보니 public leaderboard와의 실제 격차가 종전 인식보다 크다**(후보 격차 약 −13.8%p, 단정 아님).
둘째, **생성형(generation) task 3종의 채점 신뢰도가 미완**이고 객관식(MC) 3종도 공식과 크게 벌어진다.
이번 pass의 목표는 이 격차를 정직하게 진단·문서화하고, 안전한 가드 아래 원인을 측정 가능한 형태로 격리하는 것이다.

---

## 1. 이 프로젝트가 속한 큰 그림

### 1.1 상위 국책 과제
- **과제명**: 차세대 네트워크 AI 파운데이션 모델(NFM) 개발
- **주관**: 한국전자통신연구원(ETRI), 연구책임자 이주영 책임
- **기간/규모**: 2026.04 ~ 2030.12 (4년 9개월), 정부지원 252억 등 총 약 280억 원, TRL 3→7
- **공동기관**: KT, 써로마인드, HFR, KCA(한국방송통신전파진흥원), 이화여대, 성균관대, 포항공대
- **목표**: 멀티모달 네트워크 데이터를 이해·대응하는 자립형 네트워크 파운데이션 모델(NFM) 개발.
  TM Forum 자율네트워크(AN) Level 4 인증, 개방형/상용 NFM 공개가 핵심 성과지표.

NFM은 세 모델군으로 구성된다:
- **NFM-LMM**: 멀티모달(로그·시계열·토폴로지·스칼라) 특화. From Scratch, 1B~5B 목표.
- **NFM-LAM**: 네트워크 제어 액션 생성 특화. RT/Near-RT/Non-RT 차등 크기.
- **NFM-LLM**: 언어 기반 네트워크 특화. 범용 LLM 도메인 적응, 2B~30B. ← **우리 파트**

### 1.2 우리(NFM-LLM 파트)의 위치
- **주관**: ETRI 지능네트워크연구실 (윤승현 책임 등) = 데이터·PoC 담당
- **협업**: ETRI 언어지능연구실 (류지희 선임 등) = **모델 코어 담당** ← 이 저장소 작성자 소속
- 6/12 통합업무회의에서 R&R 확정:
  - 언어지능연구실 = 모델 코어
  - 지능네트워크연구실 = 데이터, PoC
  - **평가 하네스 구축 = 언어지능연구실이 만들어 지능네트워크연구실에 전달** ← 이 저장소의 미션

### 1.3 평가 업무의 3주체 분업
- **포항공대(DPNM, 홍원기 교수·최원석)**: NFM 벤치마크 평가 *체계 전체*를 설계·자동화하는 주관.
  벤치마크 개념·요구사항, metric·측정 방법, LLM/LMM/LAM 모델별 시나리오, 데이터셋·digital-twin/PoC 검증,
  공식 평가 software·보고서를 담당. 멀티모달 환각 정량화, LAM 동적 제어 평가 등 차별화 전략과 한글 데이터셋 작업도 여기서 나온다.
- **언어지능연구실(우리)**: 평가를 실제로 실행하는 *엔진(하네스)* = 이 저장소. 일반 능력 평가 + 실행/채점 파이프라인.
  lm-eval custom task, model runner, baseline 모델 비교, 결과 요약, Open Telco AI 정렬 노트, 이후 NFM-LLM 고유 task adapter.
- **지능네트워크연구실**: 도메인 특화 벤치마크·데이터 정합성·평가 기준 정의를 준비해 연동.

> 즉 이 저장소는 "엔진"이다. 도메인 콘텐츠(특화셋·한글셋)는 포항공대/지능실이 채워 넣는다.
> 이 저장소는 포항공대의 공식 NFM 벤치마크 체계 전체를 중복 구현하지 않는다.

### 1.4 NFM-LLM의 확장 역할 (참고 — 이번 pass 범위 밖)
NFM-LLM은 단순 문서 QA 챗봇이 아니다. 과제 논의상 두 역할을 가진다.
1. **네트워크 지식 이해·추론·생성**: 3GPP/O-RAN/manual QA, alarm correlation 분석, root-cause 진단, 자연어 운영 보고서 생성.
2. **Agentic AI brain / planning**: high-level 네트워크 intent/policy 해석, 실행 가능한 `Recipe`/`Coordination Sheet` 생성,
   LMM/LAM/tool/MCP/NETCONF/API 호출 결정(KPI 관측·loop 주기·safety constraint·검증·rollback 조건 포함).

현재 저장소는 이 중 **첫 번째 baseline layer(Open Telco LLM benchmark 실행)만** 다룬다.
Intent-to-Recipe, RAG-grounded QA 같은 NFM 고유 task는 2차로 미룬다(§9 참조).

---

## 2. GSMA Open Telco AI Leaderboard (재현 대상)

- 리더보드: https://huggingface.co/spaces/GSMA/open-telco-leaderboard
- 점수 데이터셋: https://huggingface.co/datasets/GSMA/leaderboard
- 평가 데이터(Lite): https://huggingface.co/datasets/GSMA/ot-lite
- 평가 데이터(Full): https://huggingface.co/datasets/GSMA/ot-full
- 저장소(public): https://github.com/chrisjihee/NFM-Eval-Harness
- **공식 평가 stack은 Inspect AI 기반**이다. 우리는 lm-eval 기반이므로 점수 차이가 날 수 있다(§5 참조).
  "공식 leaderboard 완전 재현"이 아니라 "재현 가능한 내부 baseline harness"임을 항상 구분한다.
- 데이터셋에는 8개 task가 있으나 **리더보드 랭킹은 7개**로 매긴다.

### 2.1 7개 task와 성격
| task | 내용 | 형식 | 채점 난이도 |
|---|---|---|---|
| `teleqna` | 통신 도메인 QA (10,000문항) | 객관식(MC) | 낮음 (acc) |
| `oranbench` | O-RAN 아키텍처·규격 (200) | 객관식(MC) | 낮음 |
| `srsranbench` | srsRAN 소스코드 이해 (300) | 객관식(MC) | 낮음 |
| `teletables` | 3GPP 문서 표 데이터 해석 (500) | 객관식(MC) | 중간 (표 컨텍스트 의존) |
| `three_gpp` (3gpp_tsg) | 3GPP 문서 → working group 분류 (3,780) | 생성/추출 | **높음** (JSON에서 값 추출) |
| `telemath` | 통신 수학·공학 단답 수치 (1,500) | 생성/단답 | **높음** (수치 파싱) |
| `telelogs` | 장비 로그 → 장애 원인 분류 (586) | 생성/추출 | **높음** (예: 정답 "C6" 추출) |

(8번째 task `sixg_bench`는 ot-lite viewer에 보이나 리더보드 랭킹 대상이 아님.)

### 2.2 리더보드 상위/기준 모델 (확인 시점: 2026-06)
- 1위 **OTel-LLM-8.3B-QnA (AT&T)** 평균 0.86 — 소형 통신특화 모델이 프론티어 모델 제압
- 상위권: gemini-3.1-pro 0.756, gemini-3-pro 0.747, LTM(SoftBank) 0.736, claude-opus-4.6 0.733, gpt-5 0.719
- 통신특화: TeleLLM(China Telecom) 0.68 (15위)
- **우리 baseline 모델 `gemma3-4b` = 평균 0.397, 76~78위권** ← 우리가 맞춰야 할 기준점

### 2.3 public gemma3-4b row (스냅샷 — 재현 목표 기준선)
`GSMA/leaderboard`의 `gemma3-4b`(provider Google, rank 78, benchmarks_completed 7) 스냅샷.
**unweighted task mean** 기준이며, compare 스크립트는 실행 시 재-pull 한다.

| column | public score |
|---|---:|
| `teleqna` | 0.652333 |
| `teletables` | 0.273333 |
| `oranbench` | 0.660000 |
| `srsranbench` | 0.740000 |
| `telemath` | 0.136667 |
| `telelogs` | 0.116667 |
| `three_gpp` | 0.200000 |
| `average` | 0.397000 (unweighted task mean) |

> **중요한 미확정 사항**: public row의 `gemma3-4b`가 instruct/base/API/특정 revision 중 무엇인지(model variant)는
> 현재 **UNKNOWN**이다. local run은 `google/gemma-3-4b-it`(instruct)이다. 이 variant 불일치가 격차의 다수를 설명할 수 있으므로,
> public과의 attribution(귀인) 해석은 variant pin 시도 결과에 조건부로 다룬다(§4, §5).

---

## 3. 현재 저장소 구현 수준

> commit 수는 버전 의존적이라 본 문서에 고정 숫자로 적지 않는다. 필요 시 `git rev-list --count HEAD`로 확인한다.

### 3.1 구조
> 주의: 아래 디렉터리/스크립트 이름(`open_telco_otlite/`, `run_open_telco_otlite.sh`)은 **on-disk 경로명**이며 rename 대상이 아니다.
> 실행 가능한 **group/task name**은 별개로 `_gsma`(기본/권장) / `_lm_eval_baseline`(legacy)로 rename되었고, bare group name `open_telco_otlite`/`open_telco_otfull`은 실행 불가다(§3.2 참조).
```
open_telco_lm_eval/tasks/
  open_telco_otlite/        # ot-lite task pack 디렉터리 (group: *_gsma 기본 / *_lm_eval_baseline legacy)
  open_telco_otfull/        # ot-full task pack 디렉터리 (group: *_gsma 기본 / *_lm_eval_baseline legacy)
run_open_telco_otlite.sh    # MODEL_NAME=... ./run_...sh  (HF/vLLM; TASKS 생략 시 기본 open_telco_otlite_gsma)
run_open_telco_otfull.sh    # TASKS 생략 시 기본 open_telco_otfull_gsma
setup-pre.sh / setup-main.sh / setup-post.sh   # GPU 서버 환경 준비 3단계
README.md / PLAN.md / PROGRESS.md / EXPERIMENTS.md / ENVIRONMENT.md / TROUBLESHOOTING.md / AGENTS.md
TASK_MANIFEST.md / REPRODUCTION_NOTES.md
check_vllm_runtime.py / lm-eval-ls-task
results/  outputs/  docs/
```
- 언어 구성: Python / Shell 중심.
- HF 백엔드, vLLM 백엔드 모두 지원. `BACKEND=vllm ... ./run_...sh`
- 두 run 스크립트 모두 `--apply_chat_template` 항상 ON, `.venv` activate 수행.

### 3.2 정확한 task 인벤토리 (정정 반영 + 2026-06 RENAME)

> **이름 규칙(RENAME, 2026-06).** 기본/권장 group = GSMA-compatible `_gsma`(run script 기본값; `TASKS` 생략 시 실행).
> legacy lm-eval/loglikelihood baseline은 삭제하지 않고 모든 group/leaf task에 `_lm_eval_baseline` suffix로 rename(diagnostic only).
> **bare `open_telco_otlite` / `open_telco_otfull`은 rename되어 실행 불가** — run script가 fail-fast `exit 2`로 거부한다.
> 과거 run/결과 설명에서 보이는 bare name은 historical pre-rename task name이며 사실 기록으로 보존한다.

네 개의 task pack이 있고, group 단위로 등록된다.

**(1) `open_telco_otlite_gsma`** — **기본/권장 (run script 기본값)**, GSMA-leaderboard-comparable 7-task pack:
```text
open_telco_teleqna_mcgen      # MC, 자유 single-letter gen (engine 미정렬)
open_telco_oranbench_mcgen    # MC
open_telco_srsranbench_mcgen  # MC
open_telco_teletables_mcgen   # MC, 표 미주입
open_telco_telemath_gsma      # generate_until, until:[], max_gen_toks:256
open_telco_telelogs_gsma      # generate_until, collapse gate 대상
open_telco_3gpp_tsg_gsma      # generate_until, first-match WG regex, collapse gate 대상
```
- 집계: **unweighted**(`weight_by_size: false` 명시 override; lm-eval fork default True를 끔).
- scorer만 공식 `gsma-evals/src/evals/*` 소스와 정렬(scorer-aligned), **engine은 다름**(engine-different).
  특히 MC 4종의 자유 생성 vs 공식 제약 디코딩(`multiple_choice(cot=False)`)이 **가장 큰 미정렬 축이자
  지배적 후보 격차 동인**이다. `*_mcgen` delta는 generation-vs-constrained-decoding sensitivity 측정일 뿐 재현 아님.
- **"공식 GSMA 완전 재현"을 주장하지 않는다**(= GSMA 공개 scoring contract 정렬 시도). 전체 contract와 출처 인용은
  `GSMA_SCORING_CONTRACT.md` 참조. utils 신규 함수/상수도 importlib 재노출로 ot-full_gsma에 자동 반영된다.

**(2) `open_telco_otlite_lm_eval_baseline`** — legacy lm-eval/loglikelihood baseline(과거 default, diagnostic only),
`GSMA/ot-lite` 기반 7-task:
```text
open_telco_teleqna_lm_eval_baseline          # MC
open_telco_teletables_lm_eval_baseline       # MC (disk 표 파일 I/O 의존)
open_telco_oranbench_lm_eval_baseline        # MC
open_telco_srsranbench_lm_eval_baseline      # MC
open_telco_telemath_lm_eval_baseline         # generate_until
open_telco_telelogs_lm_eval_baseline         # generate_until
open_telco_3gpp_tsg_gen_lm_eval_baseline     # generate_until (3gpp는 생성형 task로 등록됨)
```
- 집계: group acc는 **sample-weighted**(아래 §4.0 정정 참조).
- historical pre-rename group name: `open_telco_otlite`(현재 bare name 실행 불가).

**(3) `open_telco_otlite_core4_lm_eval_baseline`** — legacy 4-task MC starter pack(초기 구현 경로 보존, diagnostic only):
```text
open_telco_teleqna_lm_eval_baseline
open_telco_oranbench_lm_eval_baseline
open_telco_srsranbench_lm_eval_baseline
open_telco_3gpp_tsg_lm_eval_baseline         # MC 변형 (core4 전용)
```
- 주의: `doc_to_target_3gpp_tsg`가 `THREE_GPP_LABELS.index(answer)`를 사용 → gold가 16개 라벨에 정확히 없으면
  `ValueError` 크래시 위험(MC 변형, core4 전용). smoke test가 core4를 포함해 이 위험을 조기 노출한다.
- historical pre-rename group name: `open_telco_otlite_core4`.

**(4) `open_telco_otfull_gsma`** (기본/권장, run script 기본값) / `open_telco_otfull_lm_eval_baseline` (legacy baseline, diagnostic only)
— `GSMA/ot-full` 기반 7-task:
```text
# open_telco_otfull_gsma (기본/권장):
open_telco_full_teleqna_mcgen
open_telco_full_oranbench_mcgen
open_telco_full_srsranbench_mcgen
open_telco_full_teletables_mcgen
open_telco_full_telemath_gsma
open_telco_full_telelogs_gsma
open_telco_full_3gpp_tsg_gsma

# open_telco_otfull_lm_eval_baseline (legacy, diagnostic only):
open_telco_full_teleqna_lm_eval_baseline
open_telco_full_teletables_lm_eval_baseline
open_telco_full_oranbench_lm_eval_baseline
open_telco_full_srsranbench_lm_eval_baseline
open_telco_full_telemath_lm_eval_baseline
open_telco_full_telelogs_lm_eval_baseline
open_telco_full_3gpp_tsg_lm_eval_baseline
```
- 집계: `_gsma`는 unweighted; `_lm_eval_baseline` group acc는 sample-weighted.
- historical pre-rename group name: `open_telco_otfull`(현재 bare name 실행 불가).
- **핵심 결합(coupling)**: `open_telco_lm_eval/tasks/open_telco_otfull/utils.py`는 ot-lite utils를
  **importlib로 재노출**한다(`exec_module` 후 비-underscore 이름 전체를 globals로 복사). 그 결과
  **ot-lite parser 변경이 ot-full에 동시에 상속된다.** 단일 commit이 두 트랙을 동시에 바꾸며 "독립 revert"가 불가능하다.
  parser/utils 관련 모든 변경 commit 메시지에는 "affects both tracks via importlib re-export"를 명기한다.

(MC-only sensitivity diagnostic group `open_telco_otlite_mcgen` / `open_telco_otfull_mcgen`(MC 3종)도 존재하며 불변이다.)

#### task별 `metadata.version` (drift 정정, legacy `_lm_eval_baseline` 트랙 기준)
"ot-lite 7-task v0.2"로 일괄 기술하던 것은 부정확하다. 실제 version은 task마다 다르다.
- **v0.2**: group `open_telco_otlite_lm_eval_baseline`, telelogs, telemath, teletables, 3gpp_tsg_gen
- **v0.1**: teleqna, 3gpp_tsg, oranbench, srsranbench, core4

(teleqna 등 v0.1→v0.2 bump 여부는 동작 변경 없음 확인 후 결정할 항목 — §10 Open Questions.)

#### 생성형 task 채점 kwargs (실측 — TASK_MANIFEST와 정합 유지)
- 전부 `output_type: generate_until`, `until: ["\n"]`, `do_sample=false`.
- `max_gen_toks`: telemath **48**, telelogs **24**, 3gpp_tsg_gen **32**.
- HF 7-task run에서 left-truncation(2902→2024 tokens) 다발 → 생성형 저점수의 후보 원인.

#### run 스크립트 env
`MODEL_NAME` / `DEVICE` / `BATCH_SIZE` / `TASKS` / `BACKEND`(hf|vllm) / `VLLM_VISIBLE_DEVICES` /
`GPU_MEMORY_UTILIZATION` / `MAX_MODEL_LEN` / `TENSOR_PARALLEL_SIZE`.
**`TELETABLES_ROOT`는 스크립트가 set하지 않는다** → teletables 표 컨텍스트가 필요하면 별도 export 해야 한다.

### 3.3 검증된 baseline 실행 (EXPERIMENTS.md, 2026-05-15) — historical pre-rename run
- 모델 `google/gemma-3-4b-it`, HF 백엔드, group `open_telco_otlite`(**historical pre-rename task name**; 현재는 `open_telco_otlite_lm_eval_baseline`로 rename되어 bare name 실행 불가), 7-task
- **group acc = 0.3718 (sample-weighted)**
- 결과 파일(historical 경로 보존): `results/open_telco_otlite/google__gemma-3-4b-it/results_2026-05-15T15-40-57.791797.{json,md}`
- 아래 task 라벨은 historical pre-rename leaf name이다(현재는 각 `+_lm_eval_baseline`).

| task (historical) | local acc | public (unweighted) |
|---|---:|---:|
| `open_telco_teleqna` | 0.4500 | 0.6523 |
| `open_telco_teletables` | 0.2000 | 0.2733 |
| `open_telco_oranbench` | 0.3667 | 0.6600 |
| `open_telco_srsranbench` | 0.5467 | 0.7400 |
| `open_telco_telemath` | 0.0100 | 0.1367 |
| `open_telco_telelogs` | 0.1700 | 0.1167 |
| `open_telco_3gpp_tsg_gen` | 0.0700 | 0.2000 |
| local group acc (sample-weighted) | **0.3718** | — |
| local 7-task 단순평균 (unweighted) | **0.259** | **0.397** |

---

## 4. 핵심 문제 진단 — 왜 점수가 안 나오는가

> 본 절은 `.omc/plans/nfm-eval-harness-consensus-plan.md`의 north star 진단을 그대로 따른다.
> 독립 검증은 완료됐으나 **귀인(attribution)은 미확정**이다.

### 4.0 집계방식 정정 (가장 중요)
종전 인식("local 0.3718 vs public 0.397, 격차 약 −2.5%p")은 **집계방식 혼동**이다.
- local group acc `0.3718`은 **sample-weighted**다. teleqna가 1000 샘플로 압도적이라 평균을 끌어올린다
  (lm-eval fork의 group 집계 default가 `weight_by_size=True`이고 otlite group YAML이 이를 override 하지 않음).
- public `0.397`은 **unweighted task mean**(7개 task 단순평균)이다.
- **동일 기준(둘 다 7-task 단순평균)으로 맞추면 local 0.259 vs public 0.397 ≈ −13.8%p가 후보 격차다.**
  이것은 **후보 격차(candidate gap)이며 단정이 아니다**(귀인 미확정, 아래 caveat 참조).

따라서 공정 비교는 **unweighted task mean끼리** 해야 한다. group acc 0.3718을 public 0.397과 직접 비교하는 것은 부적절하다.

### 4.1 격차의 분포 (최대 기여 = MC 3종)
동일 기준 비교에서 task별 후보 기여(local − public):
- `oranbench` **−0.293**, `teleqna` **−0.202**, `srsranbench` **−0.193** (MC 3종이 최대 격차)
- `three_gpp` −0.130, `telemath` −0.127
- `telelogs`는 local이 오히려 **+0.053** 우위

즉 "격차는 주로 생성형 parser 문제"라는 종전 가정은 틀렸다. **최대 격차는 객관식 MC 3종**이다.

### 4.2 귀인 미확정 — 중대 caveat
이 후보 격차는 다음 세 요인 중 무엇으로도 설명될 수 있고, 단일 원인으로 단정하면 안 된다.
- **(a) scoring 방식**: lm-eval MC는 choices에 대한 loglikelihood 비교가 기본인데, 공식(Inspect AI)은
  생성 후 정답 추출일 수 있다. **공식 GSMA 추출 방식은 repo 문서상 명시적 UNKNOWN**이다
  (`REPRODUCTION_NOTES.md:155`: "Official stack may use generated answer selection or a different answer-label prompt").
- **(b) generation truncation**: max prompt length 초과로 left-truncation 발생 → 핵심 정보 유실.
  `max_length`/`max_gen_toks`/truncation 방향 점검 필요.
- **(c) public row의 model variant 불일치**: instruct/base/API/revision 미확인(UNKNOWN). **(c)가 격차의 다수를 설명하면
  (a)(b) 실측은 격차와 무관한 현상을 측정하는 셈이 된다.** 그래서 (c)를 GPU 0으로 먼저 pin 시도하고
  (Phase 0.5 attribution-readiness gate), 실패 시 비싼 비교 run의 **attribution 해석만** 보류한다(재현성 검증은 진행).

> 결론: (a)(b)(c) 세 요인을 항상 병기하고, generation 변형의 점수 상승을 "공식 GSMA 정렬"로 명명/주장하지 않는다.
> generation scoring 차이는 "generation-based scoring sensitivity 실험"으로만 다룬다.

---

## 5. 재현 목표의 현실적 기준 (중요)

공식 리더보드는 **Inspect AI** 기반이고 우리는 **lm-eval** 기반이므로 **완전 동일 재현은 목표가 아니다.**
이 저장소의 목적은 *후보 NFM-LLM 모델 간 상대 비교 + 도메인 적응 효과 측정*이다.

다만 작성자의 요구는 분명하다: **"너무 많이 차이 나면 곤란하다. 가능한 한 리더보드를 재현하고 싶다."**

따라서 이번 pass의 운영 원칙은 다음과 같다(consensus plan APPROVED 기준).
- **사전 고정 수치 목표를 합격 기준으로 사용하지 않는다.** 측정-우선·과적합 금지. 수치는 참고용 기대값(관찰 메트릭)으로만 병기한다.
  (참고 기대값: MC ±0.10 근접, telemath ≥0.10, three_gpp ≥0.15. 합격선 아님.)
- 객관식과 생성형을 분리해 다룬다: 객관식은 scoring 메커니즘 sensitivity 격리(loglikelihood vs generation+extract),
  생성형은 truncation/parser 완화로 접근한다.
- 남는 격차는 "Inspect AI vs lm-eval 방법론 차이 + variant 불일치"로 문서에 정직하게 기록한다.
- **"근거 기반 보류(deferred — uninterpretable as attribution)"와 "미완료"를 명확히 구분 표기한다.**

---

## 6. 알려진 이슈 (반드시 인지)

- **TeleTables 원본 표 서버 부재**: `tables/`·`data/TeleTables/tables/`·`.cache_hf/...` 모두 부재하고
  `TELETABLES_ROOT`가 미설정이라, 모델이 metadata + choices만 보고 표 본문을 못 본다 → **metadata-only 저평가**.
  ot-full teletables 점수는 "lower bound under teletables degradation"으로 라벨한다. 원본 확보 시도 결과를 문서화한다.
- **생성형 left-truncation**: HF run에서 `Left truncation applied. Original sequence length was 2902, truncating to last 2024 tokens.`
  경고 다발 → TeleLogs 등 long-context 입력 파손. max context length / model args / prompt length 점검 필요.
- **lm_eval upstream main unpinned**: 설치본 sha = `97a5e2c710e2b56b9dd48f367bb6fe87bbb2c176`(2026-06-25 확인).
  upstream main이 unpinned이라 변동 위험이 있고, **현재 `.venv`에 lm_eval가 미설치 상태일 수 있다.**
  pin 재설치 시 transformers 5.12.1 / vllm 0.23.0 하드핀과 충돌 위험 → 재설치 후 `make smoke`(GPU 0) 검증 게이트 통과,
  실패 시 현재 sha로 즉시 롤백(SOP는 `ENVIRONMENT.md`).
- **vLLM CUDA forward-compat 의존**: vLLM 0.23.0가 cuda forward-compat(cuda-compat-13.3)에 의존해 취약하다.
  반드시 `.venv` activate 후 실행(run 스크립트가 activate 수행). 실패 시 hf backend로 fallback.
- **3gpp_tsg ValueError 위험**: core4 전용 MC 변형 `doc_to_target_3gpp_tsg`의 `THREE_GPP_LABELS.index` (§3.2 참조).
- **results raw artifact git 추적 실태**: `.gitignore`에 `results/`·`*.json` 무시 규칙이 없어 raw 결과 JSON이 이미 추적 중이다
  → 이번 pass에서 ignore 규칙 추가 + `git rm --cached`로 추적 해제(히스토리·워킹트리 유지). 추적 summary는 `outputs/` 하위에만 둔다.

---

## 7. 현재 산출물 상태 (갱신 대상 vs 신규)

### 이미 존재 (= 이번 pass 갱신 대상)
- `TASK_MANIFEST.md` — 실제 task YAML/parser와 정합 필요(미존재 스크립트 참조 제거, `max_gen_toks` drift,
  per-task `metadata.version` 표, "unweighted mean" 오기 정정, otfull importlib 결합 명시).
- `REPRODUCTION_NOTES.md` — 집계방식 정정(0.259 vs 0.397 ≈ −13.8%p 후보 격차, 3요소 귀인 명기).
- `ENVIRONMENT.md` — lm_eval pin sha + 재설치 SOP + provisional caveat.
- `TROUBLESHOOTING.md` — 반복 오류와 해결.
- `PROGRESS.md` / `EXPERIMENTS.md` / `outputs/latest-summary.md`(+`outputs/run-index.jsonl`) — 의미 있는 run 후 갱신.

### 이번 pass 신규
- `scripts/compare_gsma_leaderboard.py` — local lm-eval JSON ↔ `GSMA/leaderboard` 비교.
- `scripts/smoke_test.sh` + `make smoke` — GPU 없이 task-loading 검증.
- `scripts/scoring_ablation.py` — 1회성 scoring sensitivity(`--limit` 필수).
- `tests/test_parsers.py` + `make test` — parser edge case + leak-guard + ot-full exposed-but-unused guard.
- `Makefile` — `smoke` / `test` 타깃.
- 통합 문서 `CLAUDE.md` / `HANDOFF.md`(본 문서) / `FIRST_PROMPT.md` — 기존 `*-claude.md`/`*-gpt.md` 6종은 `git rm`.

> `scripts/`, `tests/`, `Makefile`은 현재 모두 부재 → 신규 생성 대상이다. `AGENTS.md`는 단일 진입점으로 **유지**한다.

---

## 8. 이번 pass 결정 사항 (consensus plan APPROVED — 본 블록 우선)

1. **MC scoring 수정 = 옵션 A(별도 실험 task family).** generation-based MC를 `open_telco_*_mcgen`
   (예: `open_telco_teleqna_mcgen`)로 **무조건 추가**하되 **비-default**다. default scoring은 **동결**하고,
   leak-guard를 적용하며, "공식 정렬"이라 명명하지 않는다("generation-based scoring sensitivity 실험"으로만 다룸).
   **과적합 금지.** 변형 task는 무조건 등록하되, **default 승격만** 2개 unknown 해소
   (공식 extraction-method 확인 OR public variant pin 성공)에 게이트한다.
2. **leak-guard unit test = 실제 dataset docs(bounded N) 대상.** 렌더된 `doc_to_text_mc_gen` 출력이
   doc의 gold(letter/문자열)를 포함하지 않음을 단언한다. `doc_to_text_mc`(`utils.py:59-69`)를 안전 템플릿 원본으로 명시한다.
3. **실행 = autopilot으로 Phase 0–3 자동 수행.** Phase 4 GPU run은 **critical일 때만 정지·사전보고**, 그 외 자동 진행 후 결과 보고.
   - **Critical(정지·사전보고)**: (a) `ot-full` 최초 full run(미실행·데이터셋 다운로드·소요 미지수),
     (b) 예상 소요 **> 약 60분 또는 GPU > 2장**, (c) `lm_eval` pin 재설치 등 env 변형(하드핀 충돌 위험),
     (d) 반복 실패·OOM·네트워크 장애.
   - **자동 진행(보고만)**: smoke, 단일 task(teleqna, telemath), ot-lite 전체, scoring ablation(`--limit`),
     vLLM↔HF parity, Qwen2.5-7B, 수정 after 측정.

---

## 9. 작업 계획 요약 (work order) — consensus plan 기준

> 상세·검증 가능 기준·commit 메시지는 `.omc/plans/nfm-eval-harness-consensus-plan.md`(source of truth) 참조.
> 모든 GPU 경로는 bounded(가드된 run 스크립트 경유 또는 명시적 `--limit`/`CONFIRM_FULL_RUN`)여야 한다.

- **Phase 0 — 사전 정합 (GPU 0)**: lm_eval pin sha 기록 + `.gitignore` 실제 수정(`results/**/*.{json,md}` ignore +
  `git rm --cached`로 추적 해제) + summary 위치를 `outputs/` 하위로 확정; pin 재설치 검증 SOP(`make smoke` + 롤백) 명문화.
- **Phase 0.5 — attribution-readiness gate (GPU 0)**: public gemma3-4b variant pin + 공식 extraction-method 확인 시도.
  결과는 `outputs/attribution-readiness.md`. variant pin 성공/실패 + extraction-method 상태 + 게이트 결정 +
  (3.1b 영구 등록 입력값)을 기록. 둘 다 실패 시 비싼 비교 run의 **attribution 해석만** 보류.
- **Phase 1 — 문서 통합 (GPU 0)**: `CLAUDE.md`/`HANDOFF.md`/`FIRST_PROMPT.md` 통합 + 6종 `git rm`(히스토리 보존) +
  사실 오류 정정(고정 commit 수 제거→`git rev-list --count` 표기, 죽은 링크, task명, "unweighted mean" 오기, `max_gen_toks` drift) +
  `TASK_MANIFEST.md` 코드 정합 + per-task version 표 + **추적 문서의 unguarded lm_eval 예시 전수 교체**
  (가드된 run 스크립트 또는 `--limit` 동반 형태로).
- **Phase 2 — smoke/compare/run 가드 (GPU 0)**: `scripts/smoke_test.sh` + `make smoke`;
  run 스크립트에 `LIMIT`/`CONFIRM_FULL_RUN` 가드 추가(미설정 full run 거부);
  `scripts/compare_gsma_leaderboard.py`(두 평균 + caveat 4종 + 3요소 귀인 + teletables degraded inline + lower-bound 라벨);
  `REPRODUCTION_NOTES.md` 집계방식 정정.
- **Phase 3 — 원인 격리 + unit test (코드 변경, GPU는 검증 시에만)**:
  raw 예시 2건 검사(`outputs/raw-example-inspection.md`);
  `scripts/scoring_ablation.py`(1회성, `--limit` 필수, loglikelihood vs generation+extract);
  `open_telco_*_mcgen` 변형 task 등록(비-default, leak-guard); 생성형 truncation/parser 완화(한 번에 하나씩, CPU 선행 + 양 트랙 GPU 1회 배치);
  `tests/test_parsers.py`(parser edge case + 3gpp ValueError 가드 + leak-guard + ot-full exposed-but-unused guard) + `make test`.
- **Phase 4 — benchmark 재현 시퀀스 (단계별 GPU 게이트)**:
  4.1 task-loading smoke → 4.2 ot-lite teleqna 단일 → 4.3 telemath baseline(before) → 4.4 ot-lite 전체 7-task →
  4.5a ot-full sample count dry pass → 4.5b ot-full 최초 full run(critical) → 4.6 vLLM↔HF parity(cuda-compat 캡처 + hf fallback) →
  4.7 Qwen2.5-7B baseline → 4.8 수정 효과 after 재측정(단일 변경별 before/after delta).
  ot-full/parity/Qwen은 **재현성/smoke 목적으로 1차 진행**하고, public과의 **attribution 해석만** variant pin 성공에 조건부.

### 9.1 GSMA 정렬 프로파일 사용법 (2026-06-27 pass)

`_gsma` 그룹은 `--include_path open_telco_lm_eval/tasks`로 자동 발견되며, **2026-06 RENAME 이후 run script 기본값**이다
(`TASKS` 생략 시 `open_telco_otlite_gsma` / `open_telco_otfull_gsma` 실행). 아래는 명시적 형태이며, legacy 비교가 필요하면
`TASKS=open_telco_otlite_lm_eval_baseline`를 명시한다(diagnostic only). bare `open_telco_otlite`/`open_telco_otfull`은
실행 불가(`exit 2`). `OUTPUT_PATH`만 바꾸면 된다. 상세 contract는 `GSMA_SCORING_CONTRACT.md`.

```bash
# 1) ot-lite_gsma smoke (HARD gate): drift guard + boxed/WG emission-rate ≥ 0.30 + cap-hit율
MODEL_NAME=google/gemma-3-4b-it TASKS=open_telco_otlite_gsma DEVICE=cuda:0 LIMIT=20 \
  OUTPUT_PATH=results/open_telco_otlite_gsma_smoke ./run_open_telco_otlite.sh
# 2) 게이트 통과 후 full
MODEL_NAME=google/gemma-3-4b-it TASKS=open_telco_otlite_gsma CONFIRM_FULL_RUN=1 \
  OUTPUT_PATH=results/open_telco_otlite_gsma ./run_open_telco_otlite.sh
# 3) compare (per-task delta 먼저 + 라벨링된 unweighted mean + MC engine 미정렬 caveat)
python scripts/compare_gsma_leaderboard.py --profile gsma --model gemma3-4b \
  --local-result <ot-lite_gsma .json> --out-md results/<...>-gsma-delta.md
# 4) ot-full_gsma full (vLLM; 게이트 통과 + 사용자 승인 시에만)
BACKEND=vllm VLLM_VISIBLE_DEVICES=0 MODEL_NAME=google/gemma-3-4b-it TASKS=open_telco_otfull_gsma \
  CONFIRM_FULL_RUN=1 OUTPUT_PATH=results/open_telco_otfull_gsma ./run_open_telco_otfull.sh
```

**collapse gate 절차**: ot-lite_gsma smoke(LIMIT=20)에서 telemath/telelogs `\boxed{}` 출력률,
3gpp WG-token 매치율을 측정한다. 어느 하나라도 **< 0.30**이면 full ot-full_gsma run을 BLOCK하고,
해당 task를 `*_gsma_hinted`(+1-line gold-free 출력형식 지시) 변형으로 재측정해 emission-rate 회복 시에만
사용자 승인하에 비교군으로 진행한다. 공식 soft scorer는 boxed/WG token 미출력 시 무조건 INCORRECT이므로
raw prompt + 약/base 모델에서 점수가 collapse(~0)할 수 있다(원인·출처: `GSMA_SCORING_CONTRACT.md` §2.3).

> 원칙 재확인: `*_gsma` / `*_mcgen`는 **공식 코드(scorer) 정렬 시도**이지 runtime/provider/revision 동일
> 보장이 아니다. **"공식 GSMA 완전 재현" 주장 금지.** unweighted mean은 leaderboard 관례일 뿐
> 공식 `run_evals.py`가 계산하지 않는다.

---

## 10. 완료 기준 (Definition of Done) 요약

> 전체·검증 가능 항목은 consensus plan의 "Success Criteria" 참조. 핵심만 발췌.

- 통합 3종 문서(`CLAUDE.md`/`HANDOFF.md`/`FIRST_PROMPT.md`) 존재 + 6종 `*-claude.md`/`*-gpt.md` `git rm`
  + 오류(고정 commit 수/죽은 링크/task명/집계 wording/version) 정정.
- 추적 문서 내 unguarded lm_eval run 예시 = 0 (grep testable); 신규 문서는 가드 예시만.
- `.gitignore`가 `results/**/*.{json,md}` 무시 + `git ls-files 'results/**/*.json'`=0; 추적 summary는 `outputs/` 하위만.
- `TASK_MANIFEST.md`가 실제 task YAML/parser/`max_gen_toks`/per-task version과 1:1 일치 + otfull importlib 결합 명시.
- `scripts/compare_gsma_leaderboard.py`가 두 평균(sample-weighted group acc + unweighted task mean) + caveat 4종 +
  3요소 귀인 + (ot-full) teletables degraded inline + lower-bound 라벨 출력.
- `REPRODUCTION_NOTES.md`에 0.259 vs 0.397 ≈ −13.8%p를 **후보 격차(단정 아님)** + 3요소 귀인으로 기술.
- `make smoke` / `make test` GPU 없이 종료코드 0(leak-guard + exposed-but-unused 포함).
- run 스크립트 가드: `CONFIRM_FULL_RUN`·`LIMIT` 미설정 호출 시 거부(비0); `LIMIT=N`이면 `--limit N` 전달.
- `scripts/scoring_ablation.py` `--limit` 없이 실행 시 종료코드 비0.
- attribution-readiness gate(`outputs/attribution-readiness.md`): variant pin 성공/실패 + extraction-method 상태 + 게이트 결정.
- raw 예시 최소 2건(`outputs/raw-example-inspection.md`).
- scoring sensitivity 결과 기록. **generation 변형의 default 승격은 (통계 유의 AND (extraction-method 확인 OR variant pin 성공))
  충족 시에만; 미충족이 default(미등록 + 사유).**
- 생성형 수정은 단일 변경별 분리 before/after delta 측정·기록(parser는 CPU 선행 + 양 트랙 GPU 1회 배치).
- gemma3-4b ot-lite 재현(4.4) + ot-full 최초 실행(4.5b) + parity(4.6) + Qwen(4.7)을 재현성/smoke 목적 1차 진행;
  attribution 해석은 variant pin 성공 시 또는 "근거 기반 보류(deferred — uninterpretable)"로 미완료와 구분 표기.
- ot-full teletables degraded(lower bound) 프레이밍 + TeleTables 확보 시도 결과 + lm_eval pin 미적용 잠정 caveat 명시.
- 4.6에 vLLM cuda-compat 경고 캡처 + hf fallback 자동 트리거 조건 명시.

### Open Questions (미해소 — 사용자/측정 대기)
- public GSMA gemma3-4b variant(instruct/base/API/revision) — Phase 0.5 pin 시도, 실패 시 attribution deferred.
- 공식 GSMA MC 추출 방식(generated-selection vs answer-label loglikelihood) — 0.5.1 확인 시도.
- lm_eval pin 적용 시점(재현 run 전 권고) + 하드핀 충돌 시 롤백 — 사용자 승인.
- scoring ablation "유의 우월" 통계 임계(잠정: 일관 방향 AND delta>합산 stderr) + 2-unknown AND 조건.
- teleqna/3gpp_tsg/oranbench/srsranbench/core4 v0.1→v0.2 bump 여부(동작 변경 없음 확인 필요).
- parser 변경 ot-full 측정 범위(CPU 선행 + 양 트랙 GPU 1회 배치 vs ot-lite 한정 선언).

---

## 11. 환경
- GPU: 최대 6장(A100 40GB) 가용. 10B 이하 모델 검증 중. gemma3-4b는 단일 GPU로 충분.
- Python 3.12.13, uv 0.11.23, `.venv` editable.
- 하드핀: torch 2.11.0+cu128 / transformers 5.12.1 / vllm 0.23.0.
- **lm_eval = upstream main git clone(unpinned), 설치본 sha `97a5e2c...`(미설치 상태일 수 있음 — §6 참조).**
  fork된 `group.py`/`metrics.py`가 자체 aggregation 수행(sample-weighted group acc의 원인).
- 데이터셋 로컬 캐시 없음(첫 run 다운로드). HF 접근: user=chrisjihee, org=etri-lirs(gemma/llama/qwen 접근 가능).
- **transformers 버전이 최신 모델 지원을 좌우**하므로 새 모델 평가 시 버전 확인 필요. GGUF 양자화 모델도 lm-eval로 평가 가능.

---

## 12. 마일스톤 / 외부 일정
- **6/30**: 1차로 7개 task 평가 가능 패키지를 지능네트워크연구실(박세형 책임)에 전달하기로 메일로 약속됨.
- 다음 주 목/금 오후: 박세형 책임과 1차 데모 미팅(실행법·결과 소개) 예정.
- 10월: 진도점검보고서.
- 이후(2차): 포항공대 한글 데이터셋·도메인 특화 task가 들어오면 하네스 확장.
  Planning(Intent→Recipe, TeleYAML류)·RCA·멀티모달·동적제어는 현재 범위 밖 → 2차 과제.

---

## 13. 새 작업자가 먼저 읽어야 할 순서
1. `../AGENTS.md` — agent 작업 규칙(단일 진입점)
2. `../CLAUDE.md` — 작업 규칙·우선순위 (얇은 진입점)
3. `HANDOFF.md` — 본 문서(전체 맥락·상태·계획 요약)
4. `REPRODUCTION_NOTES.md` — 집계방식 정정·재현성 caveat
5. `TASK_MANIFEST.md` — task별 dataset/split/metric/parser/known issue/public column mapping
6. `.omc/specs/deep-interview-nfm-eval-harness.md` — 확정 진단/요구사항
7. `.omc/plans/nfm-eval-harness-consensus-plan.md` — 확정 계획·결정(current state source of truth)
8. `../README.md` / `PLAN.md` / `PROGRESS.md` / `EXPERIMENTS.md` / `ENVIRONMENT.md` / `TROUBLESHOOTING.md` — 보조 문서

---

## 14. 팀 설명용 요약 (한국어)

> NFM-Eval-Harness는 GSMA Open Telco AI task를 EleutherAI lm-evaluation-harness 기반으로 실행하는
> ETRI 언어지능연구실의 내부 baseline 평가 하네스다. 현재 기본/권장 실행 group은 GSMA-compatible `open_telco_otlite_gsma` /
> `open_telco_otfull_gsma`(run script 기본값, TASKS 생략 시 실행)이고, legacy lm-eval baseline은 `_lm_eval_baseline` suffix로
> 보존(diagnostic only)되며 core4도 마찬가지다(bare `open_telco_otlite`/`open_telco_otfull`은 실행 불가).
> HF·vLLM 백엔드로 동작한다. historical pre-rename local gemma3-4b ot-lite 결과는 group acc 0.3718(sample-weighted)인데,
> public GSMA leaderboard의 gemma3-4b는 0.397(unweighted task mean)이다. **두 수치는 집계방식이 달라 직접 비교할 수 없으며,
> 동일 기준(7-task 단순평균)으로 맞추면 0.259 vs 0.397, 약 −13.8%p의 후보 격차가 있다(단정 아님).**
> 이 격차는 scoring 방식(loglikelihood vs 공식 추출, 추출 방식 UNKNOWN), generation truncation,
> public row의 model variant 불일치(UNKNOWN) 셋 중 무엇으로도 설명될 수 있어 단일 원인으로 단정하지 않는다.
> 이번 pass는 lm-eval 기반을 유지하면서 이 격차를 정직하게 진단·문서화하고, GPU 안전 가드 아래 원인을 측정 가능한 형태로
> 격리한다. 공식 GSMA Inspect AI stack의 완전 재현이 아니라 "재현 가능한 내부 baseline harness"임을 명확히 구분한다.
