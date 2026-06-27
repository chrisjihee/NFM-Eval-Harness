# GSMA Scoring Contract — official task/scoring reference for the `*_gsma` profile

마지막 갱신: 2026-06-27

이 문서는 GSMA Open Telco AI 7-task의 **공식 task/scoring contract**를 코드 출처와 함께
정리하고, 이 저장소의 비-default `*_gsma` / `*_mcgen` 변형이 그 contract와 어디까지
정렬되고 어디서 어긋나는지를 명시한다.

원칙(절대 변하지 않음): 이 저장소는 **lm-eval 기반 내부 baseline harness**이며 공식 GSMA
Inspect AI stack의 **완전 재현이 아니다**. 아래 어디에도 "공식 GSMA 완전 재현" 주장은 없다.
`*_gsma` / `*_mcgen` 변형은 공식 *코드(scorer)와 정렬하려는 시도*이지 runtime / provider /
model revision 동일 보장이 아니다.

---

## 0. source of truth

- **공식 task/scoring contract의 원전 = `gsma-evals/src/evals/<task>/*.py`** (이 저장소에 vendored).
  본 문서의 모든 contract 행은 이 소스를 1:1 대조해 작성했다(파일·라인 인용).
- **HF Space `GSMA/open-telco-leaderboard` 는 `GSMA/leaderboard` dataset을 보여주는 UI**이지
  점수 계산 엔진이 아니다. 점수는 위 Inspect AI 코드가 생성하고, leaderboard dataset에 적재된다.
- 공식 stack = **Inspect AI** (lm-eval 아님). dataset = `GSMA/ot-lite`(default) / `GSMA/ot-full`(`full=True`),
  per-task `name=<dataset_name>`, `split=test`. **우리와 동일 dataset** (`gsma-evals/src/evals/_utils.py:6-24`).
- 공식 생성 설정: `temperature=0.0, epochs=1`, **max_tokens / until 미지정**(Inspect/provider default).
  (`gsma-evals/src/evals/run_evals.py:21-42`).

---

## 1. per-task 공식 contract 표

dataset은 7 task 전부 `GSMA/ot-lite`(또는 `--full` 시 `GSMA/ot-full`), config `name`은 아래
`dataset_name`, `split=test`. `target` 컬럼은 raw dataset의 `answer`.

| Task (public column) | dataset_name | solver (출처) | scorer (출처) | parser / regex / tolerance | 표 주입 | raw question | max_tokens |
|---|---|---|---|---|---|---|---|
| `teleqna` | `teleqna` | `multiple_choice(cot=False)` (`teleqna.py:45`) | `choice()` (`teleqna.py:46`) | 생성 후 letter 추출, `target=chr(65+answer)` exact (`teleqna.py:19`) | n/a | input=question, choices 주입 | provider-default |
| `teletables` | `teletables` | `multiple_choice(cot=False)` (`teletables.py:44`) | `choice()` (`teletables.py:45`) | `target=chr(65+answer)` exact (`teletables.py:25`) | **미주입** (질문+choices만; `record_to_sample`는 `input=question`만 사용, 표 본문 미로드) | input=question | provider-default |
| `oranbench` | `oranbench` | `multiple_choice(cot=False)` (`oranbench.py:45`) | `choice()` (`oranbench.py:46`) | `target=chr(65+answer)` exact (`oranbench.py:19`) | n/a | input=question | provider-default |
| `srsranbench` | `srsranbench` | `multiple_choice(cot=False)` (`srsranbench.py:37`) | `choice()` (`srsranbench.py:38`) | `target=chr(65+answer)` exact (`srsranbench.py:18`) | n/a | input=question | provider-default |
| `telemath` | `telemath` | `[system_message(SYSTEM_PROMPT), generate()]` (`telemath.py:87`) | `telemath_scorer()` accuracy+stderr (`telemath.py:53-70`) | `parse_boxed_answer` = `BOXED_PATTERN` 마지막 매치 → `WHITESPACE_PATTERN.sub("",...)` → `lstrip(":").rstrip("./")`; `math.isclose(rel_tol=0.01, abs_tol=0.01)` 후 비숫자 exact-string fallback (`telemath.py:42-62`) | n/a | input=question (+ system prompt) | provider-default |
| `telelogs` | `telelogs` | `generate()` raw (`telelogs.py:81`) | `telelogs_scorer(eval_type="soft")` accuracy+stderr+maj_at_k (`telelogs.py:47-63`) | soft = `extract_first_int(parse_boxed_answer)` vs `extract_first_int(target)` 첫 정수 비교; 둘 다 존재+동일 시 정답 (`telelogs.py:41-54`) | n/a | input=question (**템플릿 없음**) | provider-default |
| `three_gpp` | `3gpp_tsg` | `generate()` raw (`three_gpp.py:29`) | `pattern(WG_PATTERN, ignore_case=True)` (`three_gpp.py:30`) | `WG_PATTERN=r"([A-Z]+\d+(?:-[A-Z]+)?)"`; **first-match** group(1), raw `answer`와 case-insensitive 문자열 동등 (`three_gpp.py:12,30`) | n/a | input=question (**JSON 강제 없음**) | provider-default |

### sixg_bench note (8번째, 비-랭킹)

`sixg_bench`는 `GSMA/ot-lite`의 8번째 task다(`sixg_bench.py`: `multiple_choice(cot=False)` + `choice()`,
`target=chr(65+answer)`). 그러나 공식 `run_evals.py:21-30`의 7-task 랭킹 목록에서 **제외**된다.
이 저장소도 `*_gsma` 프로파일에 sixg_bench를 포함하지 않는다(7-task만).

---

## 2. 필수 명시 행 (scorer-aligned vs engine-different split)

아래는 plan Step 5에서 요구한 명시 행이다. 각 행은 "scorer는 공식과 정렬됨 / engine은 다름"의
경계를 분명히 한다.

### 2.1 MC 4종 (teleqna / teletables / oranbench / srsranbench) — 가장 큰 미정렬 축

- **공식**: `multiple_choice(cot=False)` + `choice()` → **제약 디코딩**(constrained decoding).
  모델이 선택지 집합 안에서만 답을 고르며, `target=chr(65+answer)` exact match.
- **우리 `*_mcgen`**: `output_type: generate_until` + `until: ["\n"]` + `max_gen_toks: 8`
  → **자유 single-letter generation**(free generation, 제약 없음). letter 추출 후
  `gold=int(doc["answer"])`(0-based)와 비교.
- **결론**: 이 **MC engine 축(제약 디코딩 vs 자유 생성)은 이번 pass에서 전혀 정렬되지 않았다.**
  MC 4종은 후보 격차 최대 기여(oranbench −0.293 / teleqna −0.202 / srsranbench −0.193)이므로,
  이 미정렬은 **가장 큰 미정렬 축이자 지배적 후보 격차 동인(dominant candidate-gap driver)**이다.
  `*_mcgen` delta는 **generation-vs-constrained-decoding sensitivity 측정일 뿐, 공식 재현이 아니다.**
- 참고: 별도 default(legacy) lm-eval MC task(`open_telco_teleqna` 등)는 `output_type: multiple_choice`
  → loglikelihood scoring으로, 공식 제약 디코딩과 또 다른 제3의 engine이다. `*_mcgen`은 이 두 축
  어느 쪽과도 동일하지 않다.

### 2.2 telemath — scorer 동일, prompt 결합은 known engine micro-difference

- **공식**: `solver=[system_message(SYSTEM_PROMPT), generate()]` (2-message 구조).
  SYSTEM_PROMPT = expert problem solver, 단위 관리, 최종답 `\boxed{number-only}` 요구(부정 예시 포함).
- **우리**: lm-eval에는 system-solver stage가 없어 SYSTEM_PROMPT를 단일 프롬프트로 결합
  (`doc_to_text_telemath_gsma` = SYSTEM_PROMPT + 빈 줄 + raw question). 이는 공식 2-message 구조와의
  **known engine micro-difference**이며 **parity가 아니다**.
- **scorer는 공식과 동일**: `extract_boxed_last`(마지막 boxed, `\n\s*` 제거, `lstrip(":").rstrip("./")`)
  → `math.isclose(rel_tol=0.01, abs_tol=0.01)` + 비숫자 exact-string fallback. (`telemath.py:42-62` 대조 완료.)

### 2.3 telelogs / 3gpp — raw question 유지, soft scorer collapse 위험

- **공식**: 둘 다 raw question을 그대로 `generate()`(템플릿/JSON/지시 없음). 우리도 raw question 유지
  (`doc_to_text_telelogs_gsma` / `doc_to_text_3gpp_gsma`는 `doc["question"].strip()`만 반환).
- **collapse 위험**: 공식 soft scorer는 모델이 `\boxed{}`(telelogs) / WG token(3gpp)을 출력하지 못하면
  **무조건 INCORRECT**다 (telelogs `parse_boxed_answer` 미매치 시 ""→첫 정수 None→오답;
  3gpp `pattern` 미매치 시 오답). raw prompt + 약/base 모델 조합에서 emission rate가 near-zero이면
  점수가 **collapse(~0)** 할 수 있다.
- **HARD gate**: smoke(LIMIT=20)에서 telemath/telelogs `\boxed{}` 출력률, 3gpp WG-token 매치율을
  측정하고, 어느 하나라도 **< 0.30**이면 full ot-full run을 BLOCK한다. 미달 task는 먼저
  `*_gsma_hinted`(+1-line output-format instruction, gold 비노출) 변형으로 emission rate 회복 여부를
  재측정한 뒤에만, 사용자 승인하에 비교군으로 진행한다(상세 절차: plan Step 7.3 / `REPRODUCTION_NOTES.md`).

### 2.4 3gpp pattern() = FIRST-match

- 공식 Inspect `pattern()` scorer는 `re.search`(첫 매치) · capture group(1) · `ignore_case=True`로
  target과 case-insensitive 문자열 동등을 판정한다(공개·안정 문서화된 Inspect 동작).
- 따라서 우리 `extract_wg_token`의 default는 **FIRST-match**(`last=False`)로 확정했다(`utils.py`
  `extract_wg_token`: `re.findall(...)[0]`). `last=True`(last-match)는 **confirmation measurement 전용**
  변형이며, smoke에서 first vs last acc를 동시 산출해 first가 공식 동작과 일치함을 확인하고 public 0.200과
  delta를 기록한다(gating 아님).

### 2.5 max_gen_toks=256 = 의도적 scorer-fit/cost 선택 (NOT parity-loss)

- 공식 Inspect는 max_tokens를 provider-default로 둔다(미지정). 우리 `*_gsma` 생성형 3종은
  `max_gen_toks: 256`, `until: []`로 둔다.
- scorer는 telemath/telelogs의 **마지막** boxed(`matches[-1]`) / 3gpp의 **첫** WG token만 읽으므로,
  더 큰 EOS-stop 예산은 점수 이득이 사실상 0이고 long-tail GPU 비용(vLLM ot-full에 곱)만 늘린다.
- 따라서 256은 **의도적 scorer-fit/cost 선택이며 parity-loss가 아니다.** smoke에서 cap-hit율
  (=256 도달 비율)을 측정하고, 높으면(예 >0.20) 추가 하향 vs 미세 점수 trade-off를 명시해 승인 요청한다.

### 2.6 cross-task average = 공식 코드 미계산; unweighted mean = leaderboard 관례

- 공식 repo(`run_evals.py:21-42`)는 7-task를 병렬 eval만 하고 **cross-task average를 계산하지 않는다.**
- public leaderboard 컬럼 단순평균(=0.397 for gemma3-4b)과 일치하는 **unweighted 7-task mean**은
  **leaderboard 관례이자 비교 기준일 뿐, 공식 코드가 산출하는 값이 아니다.**
- `open_telco_{otlite,otfull}_gsma` group은 `weight_by_size: false`로 이 unweighted 관례를 따른다
  (lm-eval fork default `weight_by_size=True`를 명시 override). 이는 비교 편의를 위한 것이며 공식
  계산의 일부라고 주장하지 않는다.

### 2.7 dataset 동일 / `*_gsma`의 한계

- dataset은 공식과 동일하다: `GSMA/ot-lite`(otlite) / `GSMA/ot-full`(otfull), config `name`=task별
  `dataset_name`, `split=test`. sixg_bench는 8번째이며 랭킹 제외.
- `*_gsma` / `*_mcgen`는 **공식 코드(scorer rules) 정렬 시도**이지, production runtime / provider /
  model revision 동일을 보장하지 않는다. scorer는 공식 소스와 동일하나(인용된 행), generation engine은
  lm-eval(`generate_until`)로 Inspect `generate()`와 다르다.

---

## 3. scorer-aligned vs engine-different — 한눈 요약

| Task | scorer 정렬 | engine 정렬 | 비고 |
|---|---|---|---|
| teleqna / teletables / oranbench / srsranbench (`*_mcgen`) | letter-match는 동치 | **미정렬** (자유 생성 vs 제약 디코딩) | 가장 큰 미정렬 축·지배 동인; sensitivity 측정 |
| telemath (`*_gsma`) | **동일** (isclose 0.01 + exact fallback) | micro-difference (prompt 결합) | scorer parity, engine micro-diff |
| telelogs (`*_gsma`) | **동일** (soft 첫 정수) | 다름 (lm-eval generate) + collapse 위험 | HARD gate 대상 |
| three_gpp (`*_gsma`) | **동일** (WG regex first-match ignorecase) | 다름 (lm-eval generate) + collapse 위험 | HARD gate 대상; first-match 확정 |

무결성: 정답 하드코딩 / 프롬프트 gold 누수 / leaderboard 과적합 / 특정 모델 출력 전용 후처리 없음.
prompt는 `doc["question"]`/`doc["choices"]`만 읽고, gold(`doc["answer"]`)는 **scoring target으로만** 쓰며
프롬프트에 주입하지 않는다. telemath tolerance / telelogs soft / 3gpp regex는 공식 소스와 동일 규칙(인용)
이므로 과적합이 아니다. `*_gsma_hinted` 변형도 gold 비노출·일반 출력형식 지시 1줄만 추가한다.
