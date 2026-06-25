# CLAUDE.md — NFM-Eval-Harness 작업 지침

이 파일은 Claude Code가 이 저장소에서 작업할 때 따르는 규칙이다.
배경 맥락은 `HANDOFF.md`에 있다. 먼저 그 문서를 읽고 이 지침으로 돌아온다.

---

## 프로젝트 미션

GSMA Open Telco AI Leaderboard의 7개 통신 도메인 태스크를 **lm-evaluation-harness 기반**으로 실행하는
내부 평가 하네스를 완성한다. 목적은 두 가지다.
1. NFM-LLM 후보 베이스 모델 간 상대 비교 및 도메인 적응 효과 측정.
2. 공개 리더보드 점수를 **가능한 한 재현**하여 신뢰도를 확보(완전 동일 재현은 목표 아님 — 아래 참조).

## 현재 최우선 목표 (이번 작업의 정의된 끝)

> **gemma3-4b로 7개 태스크를 돌렸을 때, 리더보드 공식 점수(평균 0.397)에 태스크별로 납득 가능한 수준까지
> 근접시키는 것.** 특히 지금 바닥인 생성형 3종(`telemath`, `telelogs`, `three_gpp/3gpp_tsg`)을
> 0점대에서 끌어올리는 것이 가장 시급하다.

성공 기준(Definition of Done):
- [ ] 객관식 4종(teleqna/oranbench/srsranbench/teletables)이 공식 점수와 **±5%p 이내**.
- [ ] 생성형 3종이 0점대를 벗어나 공식과 **같은 자릿수**(최소한 telemath≳0.10, three_gpp≳0.15 수준).
- [ ] `gemma3-4b` 전체 평균이 리더보드 0.397과 **±0.05 이내**.
- [ ] 위 결과가 `EXPERIMENTS.md`와 `outputs/latest-summary.md`에 기록되고 commit됨.
- [ ] 6/30 전달용 실행 가이드(README 또는 별도 RUNBOOK)가 제3자(지능네트워크연구실)도 따라 할 수 있게 정리됨.

## 작업 순서 (이 순서를 지킬 것)

### 1단계: 현황 재현·진단 (먼저 측정, 그다음 수정)
1. `HANDOFF.md`, `README.md`, `PLAN.md`, `PROGRESS.md`, `EXPERIMENTS.md`, `TROUBLESHOOTING.md`를 읽는다.
2. `open_telco_lm_eval/tasks/` 아래 7개 태스크 YAML과 util/parser 코드를 **전부 열어 현재 구현을 파악**한다.
   - 각 태스크의 `output_type`(multiple_choice / generate_until), `doc_to_text`, `doc_to_target`,
     `doc_to_choice`, `filter`/`process_results`, metric 정의를 표로 정리한다.
3. gemma3-4b로 ot-lite 7-task를 재실행해 현재 점수를 확보한다(가능하면 빠르게 작은 sample로).
4. 공식 리더보드 gemma3-4b 점수(HANDOFF §2.3)와 태스크별로 비교하는 진단표를 만든다.

### 2단계: 객관식 4종 정렬 (설정 문제)
다음을 하나씩 바꿔가며 점수 변화를 측정한다. **한 번에 하나씩** 바꾸고 기록한다.
- `--apply_chat_template` 적용 (gemma-3-4b-**it**는 instruct 모델 → 거의 필수).
- few-shot 수를 공식과 맞추기 (0-shot인지 확인).
- `acc` vs `acc_norm` 중 리더보드가 쓰는 지표 확인 및 정렬.
- multiple_choice scoring 방식(loglikelihood vs generation-then-extract) 점검.
- 프롬프트 포맷(choices 라벨링, 정답 인덱스 표기) 점검.

### 3단계: 생성형 3종 수정 (parser + truncation 문제) ← 가장 중요
- **truncation 먼저 잡는다**: left-truncation warning의 원인(prompt가 max_length 초과)을 확인하고
  `max_length`/`max_gen_toks`/truncation 설정을 조정해 핵심 정보가 잘리지 않게 한다.
- **parser/metric을 태스크별로 제대로 붙인다**:
  - `telemath`: 출력에서 **최종 수치**만 robust하게 추출(정답 예: 80). 단위·서술 제거, 부호 처리.
  - `telelogs`: **라벨 추출**(정답 예: "C6", 종종 `\boxed{C6}` 형태). boxed/패턴 우선 추출.
  - `three_gpp`(3gpp_tsg): 출력 JSON에서 **working group 값**만 추출해 비교(정답 예: `{"WORKING GROUP":"SA5"}` → "SA5").
- 각 parser는 작은 단위 테스트(샘플 입력→기대 추출값)를 함께 둔다.

### 4단계: 비교·기록·패키징
- hf vs vllm 백엔드 결과를 같은 모델로 비교해 run index에 남긴다.
- gemma3-4b 외에 비교군 1~2개(중위권 예: Qwen2.5-7B-Instruct, 통신특화 TeleLLM 등)도 돌려 baseline 표를 만든다.
- `outputs/latest-summary.md`, `EXPERIMENTS.md`, `PROGRESS.md`를 갱신하고 commit.
- 6/30 전달용 RUNBOOK(설치→실행→결과 해석)을 정리.

## 재현 철학 (반드시 지킬 균형)

- 공식 리더보드는 **Inspect AI** 기반, 우리는 **lm-eval** 기반이다. **완전히 같은 점수는 목표가 아니다.**
- 그러나 "너무 많이 차이 나면 곤란"하다는 것이 사용자 요구다. → **격차를 좁히되, 남는 격차는 방법론 차이로
  정직하게 문서화**한다(PLAN.md 재현성 표 양식 활용).
- 점수를 억지로 끼워 맞추지 말 것. 평가 무결성을 우선한다. parser를 정답에 과적합시키는 짓(데이터 누수,
  정답 하드코딩, 특정 모델 출력에만 맞춘 후처리)은 금지.

## 코딩·작업 규칙

- **측정 우선**: 추측으로 고치지 말고, 바꾸기 전후 점수를 항상 측정해 비교한다. 변경은 한 번에 하나씩.
- **결과 추적**: 모든 의미 있는 실행은 `EXPERIMENTS.md` Run Index에 1줄 + 필요한 요약을 남긴다.
  raw 로그 전체를 문서에 붙이지 말고 경로만 연결한다.
- **문서 동기화**: 작업 후 `PROGRESS.md`의 "현재 상태/다음 작업"을 갱신한다. 다음 세션이 문맥을 복구할 수 있게.
- **재현성**: 모든 실행 명령(모델, 백엔드, few-shot, chat template 여부, batch_size, 데이터셋 split)을 기록.
- **GPU 환경 가정**: A6000 48GB×4. gemma3-4b는 단일 GPU로 충분. vLLM 사용 시 `VLLM_VISIBLE_DEVICES` 지정.
- **transformers 버전 주의**: 새 모델 평가가 실패하면 transformers 버전부터 확인.
- **commit 메시지**: 무엇을/왜 바꿨고 점수에 어떤 영향이 있었는지 한 줄로 남긴다.
- **스코프 경계 존중**: 멀티모달/동적제어/Planning(TeleYAML)/한글셋은 **이번 범위 밖**(2차 과제). 끌어들이지 말 것.

## 실행 빠른 참조

```bash
# 환경 준비 (GPU 서버)
./setup-pre.sh && ./setup-main.sh && ./setup-post.sh

# ot-lite 실행 (HF 백엔드)
MODEL_NAME=google/gemma-3-4b-it ./run_open_telco_otlite.sh

# vLLM 백엔드
BACKEND=vllm VLLM_VISIBLE_DEVICES=0 MODEL_NAME=google/gemma-3-4b-it ./run_open_telco_otlite.sh

# 직접 lm_eval 호출 예 (chat template 적용 — 객관식 정렬 실험 시)
lm_eval --model hf \
  --model_args pretrained=google/gemma-3-4b-it,dtype=bfloat16 \
  --include_path ./open_telco_lm_eval/tasks \
  --tasks open_telco_teleqna \
  --apply_chat_template \
  --num_fewshot 0 \
  --device cuda:0 --batch_size auto \
  --output_path ./results/align-teleqna
```

## 절대 하지 말 것
- 정답 누수, 정답 하드코딩, 특정 모델 출력에만 맞춘 parser 과적합.
- 측정 없이 "고쳤다"고 보고하기.
- 범위 밖 기능(멀티모달/동적/Planning/한글) 선구현.
- 문서(EXPERIMENTS/PROGRESS) 갱신 없이 세션 종료.
