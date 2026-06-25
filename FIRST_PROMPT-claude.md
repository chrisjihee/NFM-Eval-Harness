# Claude Code 첫 대화 지시문

아래 내용을 클론한 저장소 루트에서 Claude Code에게 그대로 붙여넣으면 된다.
(`HANDOFF.md`와 `CLAUDE.md`를 저장소 루트에 먼저 추가/commit 해두고 시작하는 것을 권장.)

---

안녕. 이 저장소(NFM-Eval-Harness)를 이어받아 작업을 마무리할 거야. 먼저 맥락을 정확히 잡고 시작하자.

**먼저 읽을 것 (이 순서로):**
1. `HANDOFF.md` — 프로젝트 전체 배경과 현재 상황. 반드시 먼저 읽어.
2. `CLAUDE.md` — 작업 규칙과 우선순위, 성공 기준.
3. `README.md`, `PLAN.md`, `PROGRESS.md`, `EXPERIMENTS.md`, `TROUBLESHOOTING.md`.

**이 프로젝트가 뭔지 한 줄로:**
GSMA Open Telco AI Leaderboard의 7개 통신 도메인 태스크를 lm-evaluation-harness 기반으로 재현하는
내부 평가 하네스야. 골격은 거의 완성됐고, 지금 핵심 문제는 **공식 리더보드 점수가 재현이 안 된다**는 거야.

**구체적인 문제:**
baseline 모델인 `google/gemma-3-4b-it`는 공식 리더보드에서 평균 0.397(76~78위)인데,
현재 우리 하네스 재현치는 평균 0.3718이고 태스크별로 뜯어보면 어긋나 있어. 특히:
- 객관식(teleqna/oranbench/srsranbench)이 공식보다 전반적으로 낮고
- 생성형 3종(telemath 0.01, three_gpp/3gpp_tsg 0.07, telelogs 0.17)은 거의 바닥이야.
공식 평가는 Inspect AI 기반이고 우리는 lm-eval 기반이라 완전히 같을 순 없지만, **너무 벌어지면 곤란해.
가능한 한 좁히는 게 목표야.**

**원인 가설(HANDOFF §4 참고):**
- 객관식: chat template 미적용(gemma-3-4b-it는 instruct 모델이라 거의 필수), few-shot 수,
  acc vs acc_norm, scoring 방식 정렬 문제일 가능성.
- 생성형: 긴 prompt의 left-truncation + parser 취약(telemath 수치 추출, telelogs 라벨/`\boxed{}` 추출,
  three_gpp JSON working group 값 추출).

**오늘 너에게 부탁하는 첫 작업 (CLAUDE.md의 1단계):**
지금 당장 코드를 고치지 말고, **먼저 현황을 정확히 진단**해줘.
1. `open_telco_lm_eval/tasks/` 아래 7개 태스크의 YAML과 parser/util 코드를 전부 열어서,
   각 태스크의 output_type, doc_to_text/target/choice, filter/process_results, metric 정의를
   **표로 정리**해줘.
2. 그 표를 보고, 객관식 4종과 생성형 3종 각각에서 "공식 점수와 벌어지는 원인"으로 의심되는 지점을
   구체적으로 짚어줘. (추측이 아니라 코드 근거로)
3. 그다음 수정 계획을 우선순위와 함께 제안해줘. 생성형 3종 parser/truncation이 가장 시급하다는 게
   내 판단인데, 코드를 보고 동의하는지/다른 의견이 있는지 알려줘.

**작업 원칙(중요):**
- 측정 우선. 바꾸기 전후 점수를 항상 비교하고, 변경은 한 번에 하나씩.
- 점수를 억지로 끼워 맞추지 마. 정답 하드코딩·데이터 누수·특정 출력 과적합은 금지.
- 멀티모달/동적제어/Planning(TeleYAML)/한글셋은 이번 범위 밖이야. 끌어들이지 마.
- 6/30까지 지능네트워크연구실에 전달할 패키지가 목표라, 제3자가 따라 할 수 있는 실행 가이드도 결국 필요해.

우선 1번(코드 읽고 진단표 만들기)부터 시작해줘. 환경은 A6000 48GB×4, gemma3-4b는 단일 GPU로 충분해.
실제 평가 실행이 필요하면 작은 sample로 빠르게 먼저 돌려서 파이프라인부터 확인하자.
