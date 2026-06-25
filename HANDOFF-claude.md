# NFM-Eval-Harness 핸드오프 문서

> 작성일: 2026-06-25
> 목적: 이 저장소(`NFM-Eval-Harness`)를 이어받아 작업하는 Claude Code가 프로젝트의 전체 맥락,
> 현재 구현 수준, 그리고 무엇을 마무리해야 하는지를 한 번에 파악하기 위한 문서.
> 이 문서는 배경 설명용이다. 실제 작업 규칙·우선순위는 `CLAUDE.md`를 따른다.

---

## 0. 한 줄 요약

GSMA Open Telco AI Leaderboard의 7개 통신 도메인 태스크를 **EleutherAI lm-evaluation-harness 기반**으로
재현하는 내부 평가 하네스다. 골격은 거의 완성됐고, **생성형(generation) 태스크 3종의 채점 신뢰도가 미완**이라
공식 리더보드 점수와 크게 벌어지는 것이 지금의 핵심 문제다. 이걸 좁히는 것이 당면 목표다.

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
  멀티모달 환각 정량화, LAM 동적 제어 평가 등 차별화 전략 담당. 한글 데이터셋 작업도 여기서 나옴.
- **언어지능연구실(우리)**: 평가를 실제로 실행하는 *엔진(하네스)* = 이 저장소. 일반 능력 평가 + 실행/채점 파이프라인.
- **지능네트워크연구실**: 도메인 특화 벤치마크·데이터 정합성·평가 기준 정의를 준비해 연동.

> 즉 이 저장소는 "엔진"이다. 도메인 콘텐츠(특화셋·한글셋)는 포항공대/지능실이 채워 넣는다.

---

## 2. GSMA Open Telco AI Leaderboard (재현 대상)

- 리더보드: https://huggingface.co/spaces/GSMA/open-telco-leaderboard
- 점수 데이터셋: https://huggingface.co/datasets/GSMA/leaderboard
- 평가 데이터(Lite): https://huggingface.co/datasets/GSMA/ot-lite
- 평가 데이터(Full): https://huggingface.co/datasets/GSMA/ot-full
- **공식 평가 stack은 Inspect AI 기반**이다 (우리는 lm-eval 기반이므로 점수 차이가 날 수 있음 — §5 참조).
- 데이터셋에는 8개 태스크가 있으나 **리더보드 랭킹은 7개**로 매긴다.

### 2.1 7개 태스크와 성격
| 태스크 | 내용 | 형식 | 채점 난이도 |
|---|---|---|---|
| `teleqna` | 통신 도메인 QA (10,000문항) | 객관식 | 낮음 (acc) |
| `oranbench` | O-RAN 아키텍처·규격 (200) | 객관식 | 낮음 |
| `srsranbench` | srsRAN 소스코드 이해 (300) | 객관식 | 낮음 |
| `teletables` | 3GPP 문서 표 데이터 해석 (500) | 객관식 | 중간 |
| `three_gpp` (3gpp_tsg) | 3GPP 문서 → working group 분류 (3,780) | 생성/추출 | **높음** (JSON에서 값 추출) |
| `telemath` | 통신 수학·공학 단답 수치 (1,500) | 생성/단답 | **높음** (수치 파싱) |
| `telelogs` | 장비 로그 → 장애 원인 분류 (586) | 생성/추출 | **높음** (예: 정답 "C6" 추출) |

(8번째 태스크 `sixg_bench`는 ot-lite viewer에 보이나 리더보드 랭킹 대상이 아님.)

### 2.2 리더보드 상위/기준 모델 (확인 시점: 2026-06)
- 1위 **OTel-LLM-8.3B-QnA (AT&T)** 평균 0.86 — 소형 통신특화 모델이 프론티어 모델 제압
- 상위권: gemini-3.1-pro 0.756, gemini-3-pro 0.747, LTM(SoftBank) 0.736, claude-opus-4.6 0.733, gpt-5 0.719
- 통신특화: TeleLLM(China Telecom) 0.68 (15위)
- **우리 baseline 모델 `gemma3-4b` = 평균 0.397, 76~78위권** ← 우리가 맞춰야 할 기준점

### 2.3 gemma3-4b의 리더보드 태스크별 공식 점수 (재현 목표 기준선)
- teleqna 0.6523, teletables 0.2733, oranbench 0.66, srsranbench 0.74,
  telemath 0.1367, telelogs 0.1167, three_gpp 0.20
- 평균 ≈ 0.397

---

## 3. 현재 저장소 구현 수준 (commit 47개 기준)

### 3.1 구조
```
open_telco_lm_eval/tasks/
  open_telco_otlite/    # GSMA/ot-lite task pack (빠른 반복 평가용, 7-task acc 단순평균)
  open_telco_otfull/    # GSMA/ot-full task pack (공개 리더보드 컬럼 정렬 지향)
run_open_telco_otlite.sh  # MODEL_NAME=... ./run_...sh  (HF/vLLM 백엔드 지원)
run_open_telco_otfull.sh
setup-pre.sh / setup-main.sh / setup-post.sh  # GPU 서버 환경 준비 3단계
PLAN.md / PROGRESS.md / EXPERIMENTS.md / ENVIRONMENT.md / TROUBLESHOOTING.md / AGENTS.md
check_vllm_runtime.py / lm-eval-ls-task / version-dep.txt
results/  outputs/  doc/
```
- 언어 구성: Python 54% / Shell 46%
- HF 백엔드, vLLM 백엔드 모두 지원. `BACKEND=vllm ... ./run_...sh`
- Codex Local/Cloud handoff 워크플로 문서화돼 있음(이제는 Claude Code가 이어받음).

### 3.2 검증된 baseline 실행 (EXPERIMENTS.md, 2026-05-15)
- 모델 `google/gemma-3-4b-it`, HF 백엔드, `open_telco_otlite`, 7-task
- **그룹 평균 acc = 0.3718**
- 태스크별:

| Task | 우리 acc | 리더보드 공식 | 격차 |
|---|---|---|---|
| `teleqna` | 0.4500 | 0.6523 | 크게 낮음 |
| `teletables` | 0.2000 | 0.2733 | 낮음 |
| `oranbench` | 0.3667 (norm 0.50) | 0.66 | 크게 낮음 |
| `srsranbench` | 0.5467 | 0.74 | 낮음 |
| `telemath` | **0.0100** | 0.1367 | 심각 |
| `telelogs` | **0.1700** | 0.1167 | 비슷/약간 높음 |
| `3gpp_tsg_gen` | **0.0700** | 0.20 | 심각 |

> 주의: 평균 0.3718이 우연히 리더보드 평균 0.397과 가까워 보이지만, **태스크별로 뜯어보면
> 객관식은 전반적으로 낮고 생성형은 바닥**이라 "맞다"고 볼 수 없다. 재현이 안 된 상태다.

### 3.3 이미 식별된 문제 (PROGRESS.md "다음 작업")
- generation-heavy 태스크에서 **left-truncation warning 반복** → 긴 prompt가 잘려 생성 품질 저하
- `telemath`, `telelogs`, `3gpp_tsg_gen` **parser 안정성** 미흡
- hf vs vllm 백엔드 결과 비교를 run index에 남기기
- task loading만 확인하는 smoke-test 경로 추가
- results/ 를 git으로 계속 추적할지 / summary만 남길지 결정

---

## 4. 핵심 문제 진단 — 왜 점수가 안 나오는가

작성자(류지희 선임)가 가장 걱정하는 지점: **gemma3-4b가 리더보드 평균 39.7인데 우리 재현치는
태스크별로 너무 벌어진다.** 원인은 두 층위로 나뉜다.

### 4.1 객관식 태스크의 격차 (teleqna/oranbench/srsranbench가 공식보다 낮음)
주요 용의자:
- **chat template 미적용**: instruct 모델은 `--apply_chat_template` 유무로 점수가 크게 달라진다.
  gemma-3-4b-**it**는 instruct 모델이므로 chat template이 거의 필수.
- **scoring 방식**: lm-eval의 multiple_choice는 loglikelihood 비교가 기본인데, 공식(Inspect AI)은
  생성 후 정답 추출일 수 있음. `acc` vs `acc_norm` 중 무엇을 리더보드가 쓰는지 정렬 필요.
- **few-shot 수**: 공식이 0-shot인지 few-shot인지 확인하고 맞춰야 함.
- **프롬프트 포맷**: choices 제시 방식, 정답 레터/인덱스 형식 차이.

### 4.2 생성형 태스크의 바닥 점수 (telemath/3gpp_tsg/telelogs)
- **truncation**: max prompt length 초과로 left-truncation 발생 → 핵심 정보 유실.
  `max_length`, `max_gen_toks`, truncation 방향 설정 점검 필요.
- **parser 부재/취약**:
  - `telemath`: 정답이 수치(예: 80). 모델 출력에서 숫자만 정확히 추출해야 함.
  - `telelogs`: 정답이 라벨(예: "C6", `\boxed{}` 안의 값). 추출 규칙 필요.
  - `three_gpp`: 정답이 `{"WORKING GROUP": "SA5"}` 같은 JSON. 값만 파싱 비교해야 함.
  - 현재는 단순 exact_match/generate_until 수준이라 거의 0점이 나오는 것으로 보임.

> 결론: 객관식은 "설정 정렬"(chat template, scoring, few-shot)로, 생성형은 "parser+truncation 수정"으로
> 접근한다. 두 갈래를 분리해서 다뤄야 한다.

---

## 5. 재현 목표의 현실적 기준 (중요)

공식 리더보드는 **Inspect AI** 기반이고 우리는 **lm-eval** 기반이므로 **완전 동일 재현은 목표가 아니다.**
README "현재 범위"에 명시됐듯 이 저장소의 목적은 *후보 NFM-LLM 모델 간 상대 비교 + 도메인 적응 효과 측정*이다.

다만 작성자의 요구는 분명하다: **"너무 많이 차이 나면 곤란하다. 가능한 한 리더보드를 재현하고 싶다."**

따라서 현실적 합의선은:
- 객관식 4종(teleqna/oranbench/srsranbench/teletables): 공식과 **±5%p 이내**로 좁히는 것을 1차 목표.
- 생성형 3종(telemath/telelogs/3gpp_tsg): 일단 **0점 수준을 벗어나 공식과 같은 자릿수**로 만드는 것이 1차 목표.
- 남는 격차는 "Inspect AI vs lm-eval 방법론 차이"로 문서에 정직하게 기록(§ PLAN.md 재현성 표 참고).

---

## 6. 환경
- GPU: A6000(48GB) 4장. 현재 10B 이하 모델 검증 중. gemma3-4b는 단일 GPU로 충분.
- 의존성: torch, transformers, vllm, lm_eval, datasets, evaluate, pyyaml, jsonschema 등.
- **transformers 버전이 최신 모델 지원을 좌우**하므로 새 모델 평가 시 버전 확인 필요.
- GGUF 양자화 모델도 lm-eval로 평가 가능(향후 경량화 모델 대비).

---

## 7. 마일스톤 / 외부 일정
- **6/30**: 1차로 7개 태스크 평가 가능 패키지를 지능네트워크연구실(박세형 책임)에 전달하기로 메일로 약속됨.
- 다음 주 목/금 오후: 박세형 책임과 1차 데모 미팅(실행법·결과 소개) 예정.
- 10월: 진도점검보고서.
- 이후(2차): 포항공대 한글 데이터셋·도메인 특화 태스크 들어오면 하네스 확장. Planning(Intent→Recipe,
  TeleYAML류)·RCA·멀티모달·동적제어는 현재 범위 밖 → 2차 과제.

---

## 8. 작업자가 먼저 읽어야 할 저장소 문서
1. `CLAUDE.md` — 작업 규칙·우선순위 (필독, 이 핸드오프와 함께 제공)
2. `README.md` — 빠른 실행법, 현재 범위
3. `PLAN.md` — lm-eval로 Open Telco 재현 가능성 기술 검토 + 재현성 주의표 + task YAML 예시
4. `PROGRESS.md` — 현재 상태, 다음 작업 목록
5. `EXPERIMENTS.md` — 실행 인덱스, gemma3-4b baseline 태스크별 점수
6. `TROUBLESHOOTING.md` — 반복 오류와 해결
7. `AGENTS.md` — 기존 에이전트 작업 규칙(참고)
