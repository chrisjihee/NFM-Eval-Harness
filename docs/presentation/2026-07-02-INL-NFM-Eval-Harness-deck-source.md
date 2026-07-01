<!--
문서: NFM-Eval-Harness 발표자료 Source MD (source-of-truth, deck 생성 전 단계)
작성일: 2026-07-01  ·  발표: 2026-07-02(수) 14:00, ETRI 387호
발표자: 류지희 선임연구원 (ETRI 언어지능연구실)
청중: 지능네트워크연구실(INL) 박세형 책임연구원 및 NFM 과제 관련자

수치 단일 출처(source of truth):
  - nested delivery clone: ~/code/NFM-Eval-Harness/nfm-eval-harness (ETRI GitLab lirs-nfm/nfm-eval-harness, HEAD 645c1f9)
  - docs/04-final-results.md 표 = results/final/*/_aggregate.json 20개와 교차검증 완료(일치)
engineering/provenance repo: ~/code/NFM-Eval-Harness (GitHub, HEAD fb26716 시점)

주의: 이 문서는 .pptx/.pdf/.html이 아니라, Claude Design/Gemini/GPT에 넣을 발표자료의 원천 MD다.
새 실험/GPU run/결과 수정 없이 repo 실측값만 사용해 작성했다.
-->

# NFM-Eval-Harness 발표자료 Source MD

> 이 파일 하나만으로 발표자료(15장 내외, 본 문서는 17장 구성)를 제작할 수 있도록 구성했다.
> 모든 수치는 `docs/04-final-results.md` + `results/final/*/_aggregate.json`에서 확인한 값만 사용한다.
> 불확실한 값은 `[확인 필요]`로 남겼다.

---

## 0. 이 문서의 목적

- 2026-07-02 INL 발표에서 **NFM-Eval-Harness를 왜 만들었고 · 무엇을 구현했고 · 어떤 문제를 풀었고 · 지금 어떻게 실행/검증/전달하는지**를 설명하기 위한 원천 자료다.
- 이 단계에서는 발표 슬라이드의 **내용(문구·수치·발표자 노트·시각화 힌트)**만 확정한다. 실제 디자인/렌더링(Claude Design/Gemini/GPT)은 다음 단계다.
- 핵심 원칙: **과장 금지, 근거 중심, 공식 GSMA(Inspect AI) 스택을 그대로 재현했다고 주장하지 않음.**
- 표현은 항상 "GSMA 공개 scoring contract 정렬 local lm-eval harness"로 통일한다.

---

## 1. 발표 맥락

### 회의 정보
- 일시/장소: **2026-07-02(수) 14:00, ETRI 387호**
- 제안 배경: 박세형 책임연구원이 NFM-Eval-Harness 실행 방법과 1차 결과를 함께 보고, 보고서/발표에 담을 task/benchmark 후보 정리를 시작하자고 제안.

### 청중
- 지능네트워크연구실(INL) 박세형 책임연구원 및 NFM 과제 관련자.
- 통신망 도메인 benchmark · 데이터 정합성 · 평가 기준 정의를 맡을 가능성이 큼.
- lm-eval / vLLM / GSMA scoring의 세부 구현에는 익숙하지 않을 수 있음 → 용어는 처음 나올 때 한 줄로 풀어 설명.

### 메일에서 정리된 역할 분담
- **언어지능연구실**: 실행 환경, 채점(scoring) 파이프라인, 일반 LLM 평가 하네스 골격.
- **지능네트워크연구실(INL)**: 네트워크 도메인 특화 benchmark, 데이터 정합성 검증, 평가 기준 정의.
- **POSTECH / 한글 데이터셋** 작업 결과와의 연결도 후속 논의 대상.

### 발표 목표
1. 이번 1차 전달물(하네스 + 1차 결과)이 무엇인지 공유.
2. INL이 바로 실행/검증할 수 있음을 보이기.
3. 다음 단계(도메인 특화 task·데이터 정합성·평가 기준)를 **함께 정할 지점**을 명확히 구분.

---

## 2. 한 문장 요약

> **NFM-Eval-Harness는 Open Telco AI Leaderboard의 7개 통신 도메인 task를 local lm-eval 환경에서 실행·비교·검증할 수 있게 만든 평가 하네스이며, 공식 GSMA(Inspect AI) 스택의 재현물이 아니라 GSMA 공개 scoring contract에 정렬한 local evaluation package다. 이번 전달의 의미는 "NFM 고유 benchmark 완성"이 아니라, 모델 후보를 공통 기준으로 돌리고 결과를 설명하며 다음 domain-specific benchmark 설계를 논의할 기반을 마련한 것이다.**

---

## 3. 발표자료 전체 스토리 (한 흐름)

- **배경**: NFM 과제에서 통신 도메인 LLM을 공통 기준으로 평가할 실행 기반이 필요했다. 공식 GSMA leaderboard는 Inspect AI 기반이라, 우리는 널리 쓰이는 lm-evaluation-harness로 같은 7개 task를 돌릴 수 있게 만들었다.
- **문제**: 처음에는 (1) 문서/코드가 흩어져 있었고, (2) local 점수가 public leaderboard와 잘 맞지 않는 것처럼 보였다.
- **진단**: 격차의 거의 전부가 **집계 방식(sample-weighted vs 7-task unweighted)** + **MC scoring 방식(loglikelihood vs generation 후 추출)** 차이였다. 능력 격차가 아니라 기준 차이였다.
- **해결**: `_gsma` profile(공개 scoring contract 정렬)을 기본 실행 경로로 만들고, 이름 규칙을 정리하고, 생성형 task의 parser/생성 budget과 실행 환경(vLLM 기본 등)을 안정화했다.
- **검증**: 10개 모델 × {ot-lite, ot-full} × 3회 반복으로 재현성을 확인했다(60 result JSON + 20 aggregate JSON, 실패 0). leaderboard 7개 모델 중 6개가 public에 근접(|Δ|≤0.021, 평균 0.009).
- **전달**: ETRI GitLab `lirs-nfm/nfm-eval-harness`로 패키징해 INL에 전달. `make smoke` / `make delivery-check` / acceptance run으로 바로 검증 가능.
- **다음 단계**: INL과 함께 NFM 도메인 task 후보·데이터 포맷·정답 스키마·평가 기준을 정의하고, 한글 telco QA·POSTECH 데이터와 연결한다.

---

## 4. 반드시 지켜야 할 표현

### 사용해도 되는 표현
- "GSMA 공개 scoring contract 정렬 local lm-eval harness" / "GSMA public scoring contract aligned local harness"
- "public leaderboard에 근접했다(공식 재현은 아님)"
- "scorer는 공식 코드에 정렬을 시도했으나 engine·stack·model variant는 다르다"
- "MC 4종은 자유 generation engine으로 공식 제약 디코딩과 미정렬 — 남은 격차의 지배적 후보 동인"
- "비교 기준은 7-task unweighted task mean"
- (TeleTables) "GSMA parity(question+choices) 기준" — 저평가가 아님

### 피해야 할 표현
- "공식 GSMA leaderboard를 그대로/완전히 재현했다" (금지)
- "우리 점수가 곧 공식 점수다" (금지)
- generation 변형 점수 상승을 "공식 정렬"이라고 명명 (금지)
- ot-lite 점수를 caveat 없이 public과 직접 비교 (금지 — public 비교는 동일 split인 **ot-full** 기준)
- TeleTables 현재 상태를 "성능 저하/저평가"로 서술 (금지 — 과거의 오해였음은 역사로만 언급 가능)
- 특정 모델의 낮은 점수를 "능력 부족"으로 단정 (reasoning/emission artifact 구분 필요)

---

## 5. 핵심 수치와 근거 표 (전부 repo 실측 · 3회 평균)

> 출처: nested delivery clone `results/final/*/_aggregate.json`(20개) = `docs/04-final-results.md` 표(교차검증 일치).
> `overall`은 per-run **7-task unweighted mean**을 3회 평균한 값(n=3, 실패 0). public은 `GSMA/leaderboard`의 7-task unweighted mean.
> **public 비교는 동일 split인 ot-full 기준.** ot-lite는 다른 split이므로 public과 직접 비교하지 않는다.

### 5.1 최종 결과 — 10개 모델 (ot-lite_gsma / ot-full_gsma, 3회 평균)

| 모델 | LB | ot-lite_gsma | ot-full_gsma | public | Δ(ot-full−pub) |
|---|:--:|---:|---:|---:|---:|
| google/gemma-3-4b-it | ✓ | 0.3956 | 0.3887 | 0.3970 | −0.008 |
| Qwen/Qwen2.5-7B-Instruct | ✓ | 0.4558 | 0.4479 | 0.4579 | −0.010 |
| tiiuae/Falcon3-10B-Instruct | ✓ | 0.4714 | 0.4620 | 0.4588 | +0.003 |
| google/gemma-3-12b-it | ✓ | 0.4357 | 0.4267 | 0.4638 | −0.037 |
| microsoft/phi-4 | ✓ | 0.5279 | 0.4971 | 0.5045 | −0.008 |
| mistralai/Mistral-Small-24B-Instruct-2501 | ✓ | 0.5078 | 0.4954 | 0.5163 | −0.021 |
| Qwen/Qwen2.5-32B-Instruct | ✓ | 0.5068 | 0.5048 | 0.5067 | −0.002 |
| Qwen/Qwen3-4B | — | 0.4530 | 0.4368 | (내부) | — |
| Qwen/Qwen3-14B | — | 0.4644 | 0.4623 | (내부) | — |
| Qwen/Qwen3-30B-A3B-Instruct-2507-FP8 | — | 0.4707 | 0.4629 | (내부) | — |

- `±spread`(표본표준편차, n=3)는 `docs/04`에 있음. gemma-3-4b/phi-4/qwen3-14b는 greedy로 3회 동일(`±0.0000`).
- 공통 패턴: 모든 모델에서 통신 MC(srsranbench/oranbench)가 강하고 생성형(telelogs/telemath)이 약함.

### 5.2 leaderboard 근접도 — 7개 public-comparable 모델 (ot-full − public)

| 모델 | Δ |
|---|---:|
| gemma3-4b | −0.008 |
| qwen2.5-7b | −0.010 |
| falcon3-10b | **+0.003** |
| gemma3-12b | **−0.037** |
| phi-4 | −0.008 |
| mistral-small-24b | −0.021 |
| qwen2.5-32b | −0.002 |

- **gemma3-12b 제외 6개: |Δ| ≤ 0.021, 평균 0.009.** 부호가 +/−로 엇갈려(falcon +0.003) 억지 정렬이 아님을 보인다.
- reference anchor: **gemma-3-4b-it ot-full 0.3887 ≈ public 0.397**.
- gemma3-12b만 −0.037: telemath/telelogs에서 `\boxed{}`/라벨 emission이 취약해 생성형 점수가 낮음(능력 저하가 아니라 emission 특성).

### 5.3 내부 비교 — leaderboard 미등재 3개 (public delta 없음)

| 모델 | ot-lite_gsma | ot-full_gsma | 비고 |
|---|---:|---:|---|
| Qwen/Qwen3-4B | 0.4530 | 0.4368 | internal ref; enable_thinking=False |
| Qwen/Qwen3-14B | 0.4644 | 0.4623 | internal ref; enable_thinking=False |
| Qwen/Qwen3-30B-A3B-Instruct-2507-FP8 | 0.4707 | 0.4629 | internal ref; tp=2; FP8 |

- 이 3개는 public row가 없어 **상대 비교(internal comparison)**로만 다룬다(public delta로 해석 금지).

### 5.4 제외/미포함 모델과 사유

| 모델 | 사유 |
|---|---|
| openai/gpt-oss-20b | harmony special-format 강제 → 단답 MC collapse (engine 비호환 artifact, 능력 아님) |
| deepseek-ai/DeepSeek-R1-Distill-Qwen-14B | always-reasoning, `enable_thinking=False` 무시 → MC truncate collapse (artifact) |
| google/gemma-4-E4B | 토크나이저 비호환 |
| Qwen3.6-27B-FP8 | 다운로드 실패 (※ rerun #10 `Qwen3-30B-A3B-Instruct-2507-FP8`와 다른 모델) |

- 이번 rerun에서 **모델 대체는 없었다**(fallback 미사용). 제외 모델의 붕괴 점수는 engine 비호환 artifact이며 모델 능력 평가가 아니다.

### 규모 지표 (검증 요약)
- **10개 모델 × 2 profile(ot-lite_gsma / ot-full_gsma) × 3회 반복 = 20 trio / 60 result JSON + 20 `_aggregate.json`, 실패 0.**
- public-comparable(leaderboard 등재): **7개**. 내부 전용: **3개**.
- 데이터 규모: ot-lite **1,700 docs** / ot-full **16,866 docs**(public 동일 split).

---

## 6. Slide-by-slide deck source (17장)

> 각 slide는 **Title / One-line message / On-slide bullets / Visual / speaker notes / Source files** 항목을 포함한다.
> 발표자 노트는 발표자가 그대로 읽어도 자연스럽게 4~7문장으로 작성했다.

---

### Slide 1 — 제목

- **Title**: NFM-Eval-Harness 1차 전달 및 실행 결과
- **One-line message**: Open Telco 기반 LLM 평가 하네스를 구축·검증하고 INL에 전달합니다.
- **On-slide bullets**:
  - 부제: Open Telco 7개 task를 local에서 실행·비교·검증하는 평가 하네스
  - 발표자: 류지희 선임연구원 (ETRI 언어지능연구실)
  - 일시: 2026-07-02 · 대상: 지능네트워크연구실(INL) 및 NFM 과제 관련자
- **Visual**: 표지 레이아웃. 상단 제목 크게, 하단에 소속/일자. 배경 흰색 + navy 포인트.
- **speaker notes**:
  오늘은 NFM 과제에서 사용할 수 있는 LLM 평가 하네스, NFM-Eval-Harness의 1차 전달 내용을 공유드리겠습니다. 이 하네스는 Open Telco AI Leaderboard의 7개 통신 도메인 태스크를 우리 서버에서 직접 돌려 모델들을 같은 기준으로 비교할 수 있게 만든 것입니다. 오늘 발표의 목적은 성능 몇 점을 자랑하는 것이 아니라, 어떤 기반을 만들었고 앞으로 지능네트워크연구실과 무엇을 함께 정해야 하는지를 명확히 하는 데 있습니다. 발표는 배경, 구현, 해결한 문제, 검증 결과, 전달 방법, 다음 단계 순으로 진행하겠습니다.
- **Source files**: README.md, docs/00-overview.md

---

### Slide 2 — 오늘 논의할 것

- **Title**: 오늘 논의할 세 가지
- **One-line message**: 무엇을 전달했고, 무엇을 검증했고, 무엇을 함께 정해야 하는지.
- **On-slide bullets**:
  - 무엇을 전달했는가 — 7개 task 실행 하네스 + 1차 결과
  - 무엇을 검증했는가 — 10개 모델 재현성, leaderboard 근접도
  - 무엇을 함께 정해야 하는가 — 도메인 task·데이터 정합성·평가 기준
- **Visual**: 3분할 카드(전달 / 검증 / 협의). 각 카드에 아이콘 1개.
- **speaker notes**:
  발표를 세 갈래로 나눠 말씀드리겠습니다. 첫째는 이번에 무엇을 전달했는가입니다. 둘째는 그 전달물이 믿을 만한지를 어떻게 검증했는가입니다. 셋째가 가장 중요한데, 이 기반 위에서 지능네트워크연구실과 무엇을 함께 정해야 하는가입니다. 앞의 두 가지는 저희가 이미 한 일이고, 세 번째가 오늘 이후 함께 시작할 일입니다. 이 구분을 계속 유지하면서 설명드리겠습니다.
- **Source files**: docs/06-inl-handoff.md

---

### Slide 3 — 요청 배경과 역할 분담

- **Title**: 왜 만들었나 — 과제 배경과 역할 분담
- **One-line message**: 언어실은 평가 실행 기반을, INL은 도메인 benchmark를 맡는 구조입니다.
- **On-slide bullets**:
  - NFM 과제: 차세대 네트워크 AI 파운데이션 모델 (국가 대형 R&D)
  - 언어지능연구실 — 실행 환경 · 채점 파이프라인 · 일반 LLM 평가 하네스 골격
  - 지능네트워크연구실(INL) — 도메인 특화 benchmark · 데이터 정합성 · 평가 기준
  - POSTECH / 한글 데이터셋과의 연결은 후속 논의
- **Visual**: 좌우 2열 역할 분담 다이어그램(언어실 ↔ INL) + 하단에 POSTECH 연결 화살표.
- **speaker notes**:
  이 하네스는 NFM 과제의 큰 그림 안에서 역할을 나눈 결과물입니다. 저희 언어지능연구실은 모델을 실제로 돌리고 채점하는 실행 환경과 평가 파이프라인의 골격을 맡았습니다. 지능네트워크연구실은 네트워크 도메인에 특화된 benchmark를 정의하고, 데이터의 정합성을 검증하며, 평가 기준을 세우는 역할을 맡으시게 됩니다. 즉 저희가 만든 것은 "실행 기반"이고, 그 위에 올릴 "도메인 내용"은 함께 설계해야 합니다. POSTECH의 한글 데이터셋 작업과의 연결도 이후 논의가 필요합니다.
- **Source files**: docs/00-overview.md, docs/06-inl-handoff.md

---

### Slide 4 — 이번 하네스의 범위

- **Title**: 이번 전달의 범위 — 무엇이고 무엇이 아닌가
- **One-line message**: NFM 고유 benchmark 완성이 아니라, Open Telco 7개 task의 실행 기반입니다.
- **On-slide bullets**:
  - 이것은 ✓ — Open Telco AI 7개 task를 local에서 실행 가능한 평가 하네스
  - 이것은 ✗ — NFM 고유 planning benchmark, 도메인 특화 신규 데이터셋
  - 공식 GSMA(Inspect AI) 스택의 재현물이 아님 → 공개 scoring contract 정렬 local harness
  - 후속 domain-specific benchmark로 확장 가능한 골격
- **Visual**: "이것은 ✓ / 이것은 ✗" 대비 박스. 하단에 "확장 가능" 화살표.
- **speaker notes**:
  범위를 먼저 분명히 하는 것이 오해를 줄이는 길이라 생각합니다. 이번 하네스는 NFM만의 고유 benchmark를 완성한 것이 아니라, 이미 공개된 Open Telco AI Leaderboard의 7개 태스크를 우리 환경에서 재현 가능하게 돌리는 1차 평가 기반입니다. 또한 공식 GSMA 리더보드는 Inspect AI라는 다른 도구로 채점하는데, 저희는 널리 쓰이는 lm-evaluation-harness를 썼습니다. 그래서 저희 결과를 "공식 점수와 똑같다"가 아니라 "공개된 채점 방식에 최대한 맞춘 값"으로 이해해 주시면 됩니다. 이 기반은 앞으로 도메인 특화 태스크를 얹어 확장할 수 있습니다.
- **Source files**: docs/00-overview.md, docs/03-gsma-alignment-and-caveats.md

---

### Slide 5 — 평가 대상: Open Telco 7개 task

- **Title**: 무엇을 측정하나 — 7개 통신 도메인 task
- **One-line message**: 객관식 4종 + 생성형 3종으로 통신 지식·계산·분류를 평가합니다.
- **On-slide bullets**:
  - 객관식(MC) — teleqna(통신 QA) · oranbench(O-RAN) · srsranbench(srsRAN) · teletables(표준 표 추론)
  - 생성형 — telemath(수식·수치 계산) · telelogs(로그 라벨 분류) · 3gpp_tsg(3GPP WG 분류)
  - 규모: ot-lite 1,700 docs / ot-full 16,866 docs(public 동일 split)
  - 비교 기준: 항상 7-task **unweighted** 평균
- **Visual**: 7개 task 카드(MC 4 + 생성형 3), 각 카드에 유형 태그(객관식/수식/로그/표/표준문서).
- **speaker notes**:
  평가 대상은 통신 도메인 7개 태스크입니다. 크게 두 종류인데, 앞의 네 개는 객관식으로 통신 QA, O-RAN, srsRAN, 그리고 표준 문서의 표를 읽는 문제입니다. 뒤의 세 개는 생성형으로, 수식 계산인 telemath, 로그에 라벨을 붙이는 telelogs, 3GPP 워킹그룹을 분류하는 3gpp입니다. 데이터는 가벼운 ot-lite와 public 리더보드와 같은 split인 ot-full 두 가지가 있습니다. 한 가지 기억해 주실 점은, 저희는 7개 태스크 점수를 단순 평균한 값으로 비교한다는 것입니다. 이 "단순 평균" 기준이 뒤에서 중요한 이야기로 이어집니다.
- **Source files**: docs/00-overview.md, docs/02-profiles-and-scoring.md

---

### Slide 6 — 저장소 구조와 전달 방식

- **Title**: 어떻게 전달하나 — 두 저장소 구조
- **One-line message**: 개발 이력은 GitHub 원본에, 전달본은 ETRI GitLab에 있습니다.
- **On-slide bullets**:
  - engineering/provenance — GitHub `NFM-Eval-Harness` (개발 이력·근거 보존)
  - 전달본(정본) — **ETRI GitLab `lirs-nfm/nfm-eval-harness`** (INL 인수 대상)
  - 읽는 흐름: README → docs/01(quickstart) → docs/04(결과) → results/final
  - (참고) 준비본은 GitHub `NFM-Eval-Harness-delivery`로 시작 → ETRI GitLab로 이관
- **Visual**: 좌(engineering repo) / 우(delivery repo) 2분할 다이어그램 + "README→docs→results" 흐름 화살표.
- **speaker notes**:
  전달 방식은 저장소 두 개로 나뉩니다. 하나는 개발 과정과 근거를 모두 보존한 원본 저장소이고, 다른 하나는 지능네트워크연구실이 실제로 받으실 전달본입니다. 전달본은 ETRI 내부 GitLab의 lirs-nfm 그룹에 nfm-eval-harness라는 이름으로 올라가 있습니다. 처음에는 GitHub에 준비본을 만들었는데, 사내 배포를 위해 ETRI GitLab로 옮겼고 지금은 그쪽이 정본입니다. 받으신 뒤에는 README에서 시작해 quickstart, 결과 문서, 그리고 실제 결과 폴더 순으로 보시면 전체를 파악하실 수 있습니다.
- **Source files**: README.md, START_HERE_ENGINEERING.md, docs/06-inl-handoff.md, docs/08-results-manifest.md

---

### Slide 7 — 실행/검증 방법 (acceptance)

- **Title**: 바로 돌려보기 — 3단계 acceptance
- **One-line message**: GPU 없이 로딩 검증 → 1-sample 파이프라인 → 전달 게이트 순으로 확인합니다.
- **On-slide bullets**:
  - `make smoke` — GPU 없이 7개 task 로딩·파서 검증
  - `LIMIT=1 ... ./run_open_telco_otlite.sh` — 1-sample 파이프라인 통과 확인
  - `make delivery-check` — 문서·secret·용량·tree 게이트
  - (선택) `pytest -q` — parser·정합성 단위 테스트
- **Visual**: 세로 3단계 terminal card(명령 1줄씩). 시간 수치는 넣지 않는다.
- **speaker notes**:
  받으신 뒤 가장 먼저 하실 일은 세 단계 점검입니다. 첫째, make smoke는 GPU 없이도 7개 태스크가 제대로 로딩되는지 확인합니다. 둘째, LIMIT=1로 한 문제만 돌려서 실제 추론 파이프라인이 끝까지 도는지 봅니다. 셋째, make delivery-check로 문서와 결과 트리, 민감정보 여부, 파일 용량을 자동 점검합니다. 이 세 가지가 통과하면 기본 설치가 정상이라는 뜻입니다. 명령은 모두 한 줄이고, 필요하면 pytest로 파서 단위 테스트까지 돌려볼 수 있습니다.
- **Source files**: docs/01-quickstart.md, docs/06-inl-handoff.md

---

### Slide 8 — 시행착오 1: 평균 산출 방식

- **Title**: 가장 큰 시행착오 ① — 평균을 어떻게 내느냐
- **One-line message**: local이 낮아 보인 이유의 상당 부분은 "가중 평균 vs 단순 평균" 차이였습니다.
- **On-slide bullets**:
  - sample-weighted(문항 수 가중) → teleqna 1000문항이 지배 → 착시
  - public leaderboard = 7-task **unweighted**(단순) 평균
  - 같은 기준으로 맞추자 해석이 정리됨 (동일 기준 비교가 원칙)
  - 과거 "local 0.26 vs public 0.40" 격차의 핵심 요인 중 하나
- **Visual**: 두 막대(가중 평균 vs 단순 평균) 비교 + "같은 기준으로 비교" 강조.
- **speaker notes**:
  처음에는 우리 점수가 public보다 많이 낮아 보였습니다. 그런데 원인을 파고들어 보니 상당 부분이 "평균을 어떻게 내느냐"의 차이였습니다. 우리는 문항 수로 가중한 평균을 쓰고 있었는데, 이러면 문항이 1000개나 되는 태스크 하나가 전체를 좌우합니다. 반면 public 리더보드는 7개 태스크 점수를 그냥 단순 평균합니다. 기준을 단순 평균으로 똑같이 맞추자 숫자가 훨씬 자연스럽게 정리됐습니다. 여기서 얻은 교훈은, 점수를 비교할 때는 반드시 같은 계산 기준으로 놓고 봐야 한다는 것입니다.
- **Source files**: docs/03-gsma-alignment-and-caveats.md (§1), docs/04-final-results.md

---

### Slide 9 — 시행착오 2: MC scoring 방식

- **Title**: 가장 큰 시행착오 ② — 객관식 채점 방식
- **One-line message**: 객관식을 "확률 비교"가 아니라 "답 생성 후 추출"로 채점하니 public에 근접했습니다.
- **On-slide bullets**:
  - 기존(lm-eval 기본): 보기별 loglikelihood(확률) 비교
  - 대안: 모델이 답 문자를 생성 → 문자 추출(generation-based)
  - `*_mcgen`은 이 민감도를 재는 진단용(비-default)
  - 단, 공식 추출 방식은 UNKNOWN → "공식 정렬"이라 부르지 않음
- **Visual**: 채점 방식 2가지 대비(확률 비교 vs 생성 후 추출) + 화살표로 점수 상승 표시.
- **speaker notes**:
  두 번째 시행착오는 객관식을 채점하는 방식이었습니다. lm-eval 기본은 각 보기의 확률을 계산해 가장 높은 것을 고르는 방식인데, 공개 리더보드의 방식과는 차이가 있었습니다. 그래서 모델이 실제로 답 문자를 생성하게 하고 그 문자를 뽑아 채점하는 방식을 함께 실험했더니, 객관식 점수가 public에 훨씬 가까워졌습니다. 다만 공식 리더보드가 정확히 어떤 추출 방식을 썼는지는 공개되어 있지 않기 때문에, 저희는 이것을 "공식과 똑같이 맞췄다"고 주장하지 않습니다. 이 민감도 분석은 `_mcgen`이라는 별도 진단용 프로파일로 남겨 두었고, 기본 실행 경로와는 구분합니다.
- **Source files**: docs/03-gsma-alignment-and-caveats.md (§2,§3), docs/02-profiles-and-scoring.md

---

### Slide 10 — TeleTables / TeleMath 정리

- **Title**: 오해를 바로잡은 두 태스크 — TeleTables · TeleMath
- **One-line message**: TeleTables는 저평가가 아니라 GSMA와 같은 방식이었고, TeleMath는 생성 길이 문제였습니다.
- **On-slide bullets**:
  - TeleTables — `_gsma`는 question+choices만 사용 = GSMA parity (저평가 아님)
  - `TELETABLES_ROOT`는 legacy/internal 확장에만 관련(기본 경로엔 불필요)
  - TeleMath — `\boxed{}` 안의 수치를 tolerance(isclose)로 채점
  - 생성 길이가 짧아 답이 잘리던 문제 → 생성 budget 상향으로 회복
- **Visual**: 좌(TeleTables 정정) / 우(TeleMath 정정) 2열. 각 열에 "과거 오해 → 현재 이해".
- **speaker notes**:
  두 태스크는 처음에 오해가 있었다가 바로잡은 사례입니다. TeleTables는 표 내용이 빠져서 점수가 낮게 나온 줄 알았는데, 확인해 보니 공식 GSMA 방식도 문제와 보기만 쓰고 표 원문을 넣지 않았습니다. 즉 우리 방식이 공식과 같았고 저평가가 아니었습니다. 표 원문이 필요한 경우는 내부 확장용 설정으로만 별도로 다룹니다. TeleMath는 모델이 계산 과정을 쓰다가 정답을 담는 부분이 잘려 점수가 낮았는데, 생성 길이를 늘려주니 회복됐습니다. 채점은 박스 안 숫자를 약간의 오차 허용범위로 비교합니다.
- **Source files**: docs/03-gsma-alignment-and-caveats.md, docs/04-final-results.md, EXPERIMENTS.md(원본 repo)

---

### Slide 11 — 최종 profile 구조

- **Title**: 실행 경로 정리 — profile 이름 규칙
- **One-line message**: 기본은 `_gsma`, legacy는 진단용, bare 이름은 실행 불가로 막았습니다.
- **On-slide bullets**:
  - 기본/권장 — `open_telco_otlite_gsma` / `open_telco_otfull_gsma` (leaderboard 비교용)
  - legacy(진단) — `*_lm_eval_baseline` (과거 loglikelihood 방식, 비교 금지)
  - 진단 — `*_mcgen`(MC 민감도), hinted 변형
  - bare `open_telco_otlite` / `open_telco_otfull` — 실행 불가(fail-fast)
- **Visual**: 3-tier 계층도(기본 → 진단 → 금지). 기본만 강조색.
- **speaker notes**:
  실행 경로도 처음 보는 분이 헷갈리지 않도록 정리했습니다. 기본이자 권장 경로는 이름 끝에 gsma가 붙은 프로파일로, 이것이 리더보드와 비교하는 값을 냅니다. 과거의 확률 기반 방식은 삭제하지 않고 이름 끝에 lm_eval_baseline을 붙여 진단용으로만 남겼습니다. 이건 리더보드와 직접 비교하면 안 됩니다. 그리고 아무 접미사 없는 옛 이름을 그냥 실행하면 오해할 수 있어서, 아예 실행되지 않고 안내 메시지를 내도록 막아 두었습니다. 그래서 README대로 그냥 실행하면 자동으로 올바른 gsma 경로가 돌아갑니다.
- **Source files**: docs/02-profiles-and-scoring.md, docs/00-overview.md, README.md

---

### Slide 12 — 최종 검증 결과 요약

- **Title**: 1차 검증 결과 — 10개 모델 × 3회 반복
- **One-line message**: leaderboard 7개 중 6개가 public에 근접(|Δ|≤0.021, 평균 0.009)했습니다.
- **On-slide bullets**:
  - 규모: 10개 모델 × {ot-lite, ot-full} × 3회 = 60 result JSON + 20 aggregate JSON, 실패 0
  - reference: gemma-3-4b-it ot-full **0.3887 ≈ public 0.397**
  - 6개 모델 |Δ| ≤ 0.021(평균 0.009), 부호 +/− 혼재 → 억지 정렬 아님
  - gemma3-12b만 −0.037(생성형 emission 취약; 능력 저하 아님)
- **Visual**: leaderboard 7개 모델 delta 막대차트(0 기준선, +/− 색 구분). 표는 작게, 메시지 크게.
- **speaker notes**:
  이제 검증 결과입니다. 신뢰도를 보이려고 10개 모델을 두 데이터셋에서 각각 세 번씩 돌렸고, 실패 없이 60개의 결과 파일을 얻었습니다. 리더보드에 등재된 7개 모델을 public과 비교했더니, 한 모델을 빼면 여섯 개가 차이 0.021 이내, 평균 0.009로 매우 가까웠습니다. 기준점으로 삼은 gemma-3-4b는 우리 값 0.3887, public 0.397로 거의 일치합니다. 차이의 부호가 플러스와 마이너스로 섞여 있다는 점도 중요한데, 억지로 점수를 끼워 맞춘 게 아니라는 근거가 됩니다. 다만 이것은 어디까지나 공개 채점 방식에 근접한 것이지 공식 재현은 아니라는 점을 함께 말씀드립니다.
- **Source files**: docs/04-final-results.md, docs/08-results-manifest.md, results/final/*/_aggregate.json

---

### Slide 13 — 추가 모델과 내부 비교

- **Title**: 리더보드 밖 모델도 같은 기준으로
- **One-line message**: 최신 open-weight 모델까지 같은 하네스로 상대 비교할 수 있습니다.
- **On-slide bullets**:
  - 10개 중 7개는 leaderboard 등재(public delta), 3개는 내부 전용(상대 비교)
  - 내부 전용: Qwen3-4B / Qwen3-14B / Qwen3-30B-A3B-FP8
  - 계열 다양성: Qwen · Gemma · Mistral · Phi · Falcon
  - 내부 모델은 public delta로 해석하지 않음(상대 순위만)
- **Visual**: 10개 모델 ot-full 점수 가로 막대(등재=진한색, 내부=연한색).
- **speaker notes**:
  이 하네스의 장점은 리더보드에 있는 모델만이 아니라 최신 공개 모델도 같은 기준으로 돌려볼 수 있다는 점입니다. 이번에는 10개 중 7개가 리더보드 등재 모델이라 public과 비교가 가능했고, 나머지 세 개, Qwen3 계열은 리더보드에 없어서 우리끼리의 상대 비교로만 다뤘습니다. 모델 계열도 Qwen, Gemma, Mistral, Phi, Falcon으로 다양해서, NFM 후보 모델을 고를 때 참고가 될 수 있습니다. 다만 리더보드에 없는 모델은 public 대비 몇 점 차이라는 식으로 말하지 않고, 우리 안에서의 상대 순위로만 봅니다.
- **Source files**: docs/04-final-results.md (§결과 표, §제외 모델)

---

### Slide 14 — 운영상 정리한 문제

- **Title**: 돌릴 수 있게 만드느라 정리한 것들
- **One-line message**: backend·분산 실행·환경 문제를 정리해 "그냥 돌아가게" 만들었습니다.
- **On-slide bullets**:
  - 기본 backend = vLLM(HF는 긴 입력을 잘라 생성형 붕괴 위험 → 대체용)
  - 병렬 실행(Multi-GPU): vLLM tensor/data parallel, HF accelerate 지원
  - VM/NCCL/HF 오프라인 캐시 등 host 문제 recipe화(사전 다운로드·offline·NCCL 옵션)
  - 대형 모델: `MAX_MODEL_LEN`, `enforce_eager`, tensor parallel 등 운영 변수
- **Visual**: "문제 → 해결" 4행 표(backend / 병렬 / 환경 / 대형 모델). terminal card 최소.
- **speaker notes**:
  겉으로는 안 보이지만 실제로 돌아가게 만드는 데 손이 많이 갔습니다. 우선 backend를 vLLM으로 기본 설정했는데, 다른 방식은 긴 입력을 잘라버려 생성형 태스크 점수가 0으로 무너지는 문제가 있었기 때문입니다. 큰 모델이나 처리량을 위해 여러 GPU로 나눠 도는 병렬 실행도 지원하도록 최근 보강했습니다. 또 같은 서버에 가상머신이 떠 있을 때 통신이 멈추거나 모델 다운로드가 걸리는 문제들을 미리 피하는 방법을 문서로 정리해 두었습니다. 큰 모델을 위한 메모리·실행 옵션들도 함께 정리했습니다. 덕분에 받으시는 쪽에서는 문서대로 하면 대부분 그대로 돌아갑니다.
- **Source files**: docs/05-operations-and-troubleshooting.md, docs/06-inl-handoff.md (§7), README.md(병렬 실행)

---

### Slide 15 — INL이 받아서 무엇을 하면 되는가

- **Title**: 받으신 뒤 하실 일
- **One-line message**: 바로 실행해 보시고, 도메인 task·데이터·기준 논의를 시작합니다.
- **On-slide bullets**:
  - 먼저 실행: setup → make smoke → 대표 full run → 결과 확인
  - 결과표 검토: docs/04-final-results.md
  - NFM-specific task 후보 정의(무엇을, 어떤 형식으로 평가할지)
  - 데이터셋 포맷 · 정답 스키마 · 평가 기준 협의
  - POSTECH 한글 데이터셋과의 연결 검토
- **Visual**: 좌(바로 할 일: 실행/검토) / 우(함께 정할 일: task/데이터/기준) 2열 체크리스트.
- **speaker notes**:
  이제 지능네트워크연구실에서 하실 일을 정리하겠습니다. 먼저 실제로 한번 돌려봐 주십시오. 설치 후 smoke 점검, 대표 실행, 그리고 결과표 확인까지가 바로 하실 수 있는 부분입니다. 그다음이 오늘 이후 함께 시작할 부분인데, NFM에 맞는 태스크 후보를 정의하고, 그 데이터의 형식과 정답 스키마, 그리고 무엇을 정답으로 볼지 평가 기준을 함께 정하는 일입니다. 이 부분은 도메인 지식이 필요해서 저희만으로는 결정할 수 없습니다. POSTECH의 한글 데이터셋과 어떻게 연결할지도 함께 논의하면 좋겠습니다.
- **Source files**: docs/06-inl-handoff.md (§9 체크리스트), docs/01-quickstart.md

---

### Slide 16 — 다음 단계

- **Title**: 다음 단계 — 도메인 benchmark 후보
- **One-line message**: 실행 기반 위에 통신 도메인 특화 태스크를 함께 얹어갑니다.
- **On-slide bullets**:
  - 한국어 telco QA
  - 3GPP / O-RAN / RAG-grounded QA
  - log / alarm 기반 근본원인(RCA) 분석
  - intent-to-recipe / tool-use / planning benchmark
  - 보고서·발표용 benchmark 후보 우선순위 정리
- **Visual**: 로드맵 타임라인(현재: 실행 기반 → 다음: 도메인 task 후보들). 후보는 "2차 과제" 태그.
- **speaker notes**:
  다음 단계는 이 실행 기반 위에 통신 도메인 태스크를 얹는 일입니다. 후보로는 한국어 통신 QA, 3GPP나 O-RAN 문서를 근거로 답하는 문제, 로그와 알람에서 원인을 찾는 분석, 그리고 의도를 실행 절차로 바꾸는 planning 계열이 있습니다. 다만 이 후보들은 대부분 2차 과제 범위라서, 오늘 당장 구현하자는 것이 아니라 우선순위를 함께 정하자는 취지입니다. 어떤 태스크가 NFM 보고와 발표에 가장 필요한지 지능네트워크연구실의 관점을 듣고 싶습니다. 그 논의 결과를 다음 benchmark 설계의 출발점으로 삼겠습니다.
- **Source files**: docs/06-inl-handoff.md, CLAUDE.md(범위 경계 — 2차 과제)

---

### Slide 17 — 마무리

- **Title**: 마무리 — 지금 준비된 것, 함께 정할 것
- **One-line message**: 평가 실행 기반은 준비됐고, 이제 도메인 task 정의를 함께 시작합니다.
- **On-slide bullets**:
  - 준비됨: 7개 task 실행 하네스 + 재현 가능한 1차 결과 + 정직한 격차 분해
  - 근접: leaderboard 6개 모델 public 근접(공식 재현은 아님)
  - 함께 정할 것: 도메인 task · 데이터 정합성 · 평가 기준
  - 다음 미팅에서 task 후보 우선순위부터 논의
- **Visual**: 2열 요약(왼쪽 "준비된 것" ✓ / 오른쪽 "함께 정할 것" →). 하단에 한 줄 결론.
- **speaker notes**:
  정리하겠습니다. 이번 전달로 통신 도메인 LLM을 같은 기준으로 돌리고 결과를 설명할 수 있는 평가 실행 기반이 준비됐습니다. 리더보드 모델 대부분에서 public에 근접한 값을 얻었고, 남은 차이는 숨기지 않고 방법론 차이로 정직하게 분해해 문서화했습니다. 다시 강조드리면, 이것은 공개된 채점 방식에 맞춘 것이지 공식 리더보드를 그대로 재현한 것은 아닙니다. 이제 이 기반 위에 어떤 도메인 태스크를 올릴지, 데이터와 평가 기준을 어떻게 정할지 지능네트워크연구실과 함께 설계할 차례입니다. 오늘 이후 태스크 후보 우선순위부터 논의를 시작하면 좋겠습니다.
- **Source files**: docs/00-overview.md, docs/04-final-results.md, docs/06-inl-handoff.md

---

## 7. Appendix A — 개발 이력 요약

> 근거: 원본 repo `docs/CLAUDE_WORKLOG.md`(세션1~4), `docs/PROGRESS.md`, `docs/EXPERIMENTS.md`, `docs/REPRODUCTION_NOTES.md`.

### PR / PASS / 세션 흐름
- **PR #1** — 흩어진 Claude/GPT 문서 6종 통합, GSMA 재현 진단(격차 = 집계 artifact 가설).
- **PR #2** — `_gsma` profile 도입(공개 scoring contract 정렬). 격차의 거의 전부가 scoring+집계 차이임을 확인.
- **PR #3** — 이름 규칙 정리(`_gsma` 기본화, legacy `_lm_eval_baseline`, bare name fail-fast).
- **PR #4** — 다중 모델 검증(delivery), TeleMath 생성 budget 상향, TeleTables/DeepSeek artifact 해석 정정.
- **PR #5** — 확장 검증(ot-lite/ot-full full split), leaderboard 모델 public 근접 확인.
- **PR #6 / PASS7+** — INL 패키징, 별도 slim 전달본 생성, 10모델 × 2profile × 3회 정본 rerun.
- **세션3(2026-06-29)** — 설치를 버전 고정 pip(`uv pip install "lm_eval[hf,vllm]==0.4.12"`)로, 기본 backend를 vLLM로 전환, 두 저장소 sync, compare 가드 추가.
- **세션4** — ETRI GitLab 전달본 검토: 병렬 실행(Multi-GPU) 모드·ray 의존성·vLLM 체크 수정·.sh 권한 등 6커밋 정적 검증 + INL 전달 준비.

### 주요 이슈와 해결 상태 (A–G)
- **A. 문서/코드 분산** → engineering vs delivery 저장소 역할 분리, docs 중심 재편. (해결)
- **B. leaderboard-local 불일치** → sample-weighted vs 7-task unweighted 집계 차이가 핵심. 동일 기준(unweighted) 비교로 정리 + compare 스크립트. (해결)
- **C. MC scoring 방식** → loglikelihood vs generation 후 추출. `_mcgen` 진단 추가 + `_gsma` 정렬, "공식 정렬" 주장 금지. (해결/원칙 고정)
- **D. TeleTables 해석 정정** → 과거 저평가로 오해 → 현재는 question+choices parity(= GSMA와 동일). `TELETABLES_ROOT`는 legacy/internal 확장 전용. (해결)
- **E. TeleMath / parser / 생성 budget** → `\boxed{}` 수치 + tolerance 채점, 생성 길이 상향으로 emission 회복. 모델별 출력 형식 차이는 caveat로. (해결/caveat)
- **F. 실행 환경 문제** → vLLM 기본화(HF는 truncation 대체용), 병렬 실행, VM/NCCL/HF offline recipe, 대형 모델 운영 변수. (해결/문서화)
- **G. 최종 전달 패키징** → 전달본(ETRI GitLab), `results/final`, docs/04·06·08, `make delivery-check`. (완료)

> ⚠️ 수치 주의: 일부 옛 문서/요약에는 gemma-3-4b ot-lite `0.3992`·ot-full `0.3926` 같은 **단일-run(PR#2/#4)** 값이 남아 있으나, **정본은 3회 평균인 ot-lite 0.3956 / ot-full 0.3887**(docs/04)이다. 발표에는 정본만 사용한다.

---

## 8. Appendix B — 실행 명령어 (최소)

```bash
# 0) 환경 준비 (GPU 서버 저장소 루트)
./setup-pre.sh && ./setup-main.sh && ./setup-post.sh
#    setup-post: uv pip install "lm_eval[hf,vllm]==0.4.12"

# 1) GPU 없이 로딩 검증
make smoke

# 2) 1-sample 파이프라인 (기본 backend = vLLM, 기본 task = open_telco_otlite_gsma)
LIMIT=1 MODEL_NAME=google/gemma-3-4b-it ./run_open_telco_otlite.sh

# 3) 대표 full run (ot-lite / ot-full)
CONFIRM_FULL_RUN=1 MODEL_NAME=google/gemma-3-4b-it ./run_open_telco_otlite.sh
CONFIRM_FULL_RUN=1 VLLM_VISIBLE_DEVICES=0 MODEL_NAME=google/gemma-3-4b-it ./run_open_telco_otfull.sh

# 4) 전달 게이트 + 결과 비교
make delivery-check
python scripts/compare_gsma_leaderboard.py --profile gsma --model gemma3-4b \
  --local-result <full-run result JSON> --out-md outputs/gemma3-4b-delta.md
```

- 비교의 `--local-result`는 **전체 run 결과**여야 한다(LIMIT=1 smoke는 0/1 noise → 스크립트가 BOUNDED 경고).
- 대형 모델(24~33B): `TENSOR_PARALLEL_SIZE=2 VLLM_VISIBLE_DEVICES=0,1`.
- 슬라이드에는 위 중 2~3줄만 발췌해 terminal card로 넣는다(전체 나열 금지).

---

## 9. Appendix C — Claude Design / Gemini / GPT에 넘길 때 주의사항 (deck-generation brief)

> 이 단계에서는 **최종 프롬프트가 아니다.** 아래는 deck을 렌더링할 때 지킬 style/constraints 메모다.

### 디자인 스타일
- 한국어 연구소 내부 발표자료, 16:9, 흰 배경.
- 색: navy / muted red / gray 중심. 화려하지 않게.
- 표는 작게, one-line message는 크게. 각 슬라이드 하단에 출처 문서(docs/0N) 1줄.
- 개발 과정은 "문제 → 진단 → 해결 → 현재 상태" 흐름으로 시각화.
- 저장소 구조는 engineering vs delivery 2분할 다이어그램.
- 실행 명령어는 terminal card 형태, 2~3줄 이내.

### 내용 제약 (반드시)
- 수치는 §5 표에서만 인용. 임의 생성 금지. 불확실하면 `[확인 필요]` 유지.
- 모든 점수 비교는 "7-task unweighted task mean" 기준임을 명시.
- public 비교는 ot-full 기준. ot-lite를 caveat 없이 public과 비교하지 말 것.
- "공식 GSMA를 그대로 재현" 류 과장 금지 → "공개 scoring contract 정렬 local harness".
- TeleTables 현재 상태를 성능 저하로 쓰지 말 것(과거 오해였음은 역사로만).
- 발표자 노트는 §6의 speaker notes를 그대로 쓰거나 자연스럽게 다듬되 의미·수치 보존.
- raw chat/log를 슬라이드 본문에 길게 넣지 말 것.

### 산출 형식
- 이 단계 산출물은 슬라이드 개요(텍스트)까지. `.pptx`/`.pdf`/`.html`은 만들지 않는다.

---

## 10. Appendix D — Open questions for INL (함께 정할 것)

- **도메인 task**: NFM에서 우선 평가할 통신 도메인 태스크는 무엇인가? (한국어 telco QA / 3GPP·O-RAN QA / log RCA / planning 중 우선순위)
- **데이터셋**: 태스크별 데이터 출처·규모·라이선스·정합성 검증 주체는? 공개 가능 여부?
- **정답 스키마 / scoring**: 정답 형식(단답/수치/라벨/JSON)과 채점 기준(정확일치/tolerance/soft-match)은?
- **한국어 telco QA**: 한글 데이터셋을 별도 task로 추가할지, 기존 task의 한글화로 갈지?
- **POSTECH 연결**: POSTECH 데이터/공식 NFM benchmark framework와의 접점·역할 경계는?
- **모델 후보**: NFM base/도메인 적응 모델을 이 하네스에 언제·어떤 형태로 넣을지?

---

<!-- 검증용 필수 토큰: NFM-Eval-Harness / GSMA / open_telco_otlite_gsma / open_telco_otfull_gsma / results/final / speaker notes / 지능네트워크연구실 -->
