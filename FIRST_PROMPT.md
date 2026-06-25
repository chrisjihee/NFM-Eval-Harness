# FIRST_PROMPT — 새 Claude Code 세션 kickoff 지시문

이 문서는 **clone한 `NFM-Eval-Harness` 저장소 루트에서 새 Claude Code 세션을 시작할 때 그대로 붙여넣는 첫 대화 지시문**이다.
아래의 가로줄(`---`) 아래 블록 전체를 복사해 Claude Code에게 붙여넣으면 된다. 이 문서의 본문(가로줄 위)은 사람이 읽는 설명이고, 가로줄 아래가 실제 kickoff prompt다.

작성 원칙: 한국어 prose 중심. 코드·command·task·metric·model명·경로는 영어로 표기한다.

---

안녕. 이 저장소(`NFM-Eval-Harness`)를 이어받아 작업을 마무리할 거야. 코드부터 고치지 말고, **먼저 맥락을 정확히 잡고 현황을 진단**하는 것이 오늘의 첫 임무다. 아래 순서를 그대로 따라줘.

## 1. 먼저 읽을 것 (이 순서로, 읽기 전용)

루트에 있는 문서를 아래 순서대로 읽어. 일부는 통합 작업 중이라 존재하지 않을 수 있는데, 없으면 "없음"으로 기록하고 다음으로 넘어가면 된다(이 문서들의 통합도 작업 범위의 일부다).

```text
CLAUDE.md
HANDOFF.md
README.md
PLAN.md
PROGRESS.md
EXPERIMENTS.md
outputs/latest-summary.md
open_telco_lm_eval/README.md
AGENTS.md
TASK_MANIFEST.md
REPRODUCTION_NOTES.md
ENVIRONMENT.md
TROUBLESHOOTING.md
```

`AGENTS.md`는 agent 작업 규칙의 단일 진입점이다. `CLAUDE.md`/`HANDOFF.md`는 통합 대상 문서이므로, 만약 `CLAUDE-claude.md`/`CLAUDE-gpt.md`/`HANDOFF-claude.md`/`HANDOFF-gpt.md` 같은 분리본만 보이면 그 사실을 그대로 보고해줘(분리본은 이후 단계에서 통합·정리한다).

## 2. git status 게이트 (코드 수정 전 필수)

읽기를 마친 뒤, **어떤 파일도 수정하기 전에** 먼저 저장소 상태를 확인해.

```bash
git status
```

그리고 **현재 repo 상태 요약 + 네가 세운 계획을 먼저 보고하기 전에는 파일을 수정하지 마라.** 이건 하드 게이트다.

## 3. 이 프로젝트가 뭔지 (한 줄 + 배경)

GSMA Open Telco AI Leaderboard의 7개 통신 도메인 task를 `EleutherAI/lm-evaluation-harness`(이하 `lm-eval`) 기반으로 재현하는 **내부 평가 하네스**다. 이건 ETRI 지능네트워크연구실의 NFM-LLM 평가 작업용이고, 공식 GSMA Inspect AI 스택을 **완전 재현하는 것이 목표가 아니라**, public leaderboard와 비교 가능할 만큼 신뢰성 있는 내부 baseline harness를 만드는 것이 목표다. 골격은 거의 완성됐고, 지금 핵심 문제는 **공식 리더보드 점수가 깔끔하게 재현되지 않는다**는 점이다.

### 배경 수치 (집계방식 정정 — 매우 중요)

baseline 모델은 `google/gemma-3-4b-it`다. public GSMA leaderboard에는 다음과 같이 올라 있다.

```text
model: gemma3-4b
provider: Google
rank: 78 (약 76~78위)
average: 0.397   (unweighted task mean)
```

로컬에서 추적 중인 run은 다음과 같다.

```text
model: google/gemma-3-4b-it
backend: hf
task group: open_telco_otlite
group acc: 0.3718   (sample-weighted)
```

여기서 **반드시 짚어야 할 정정**이 있다. 로컬의 `0.3718`은 **sample-weighted** 집계(teleqna가 1000 sample로 지배적)이고, public의 `0.397`은 **unweighted task mean**이라 **집계방식이 서로 다르다.** 두 값을 직접 빼서 "격차 약 2.5%p"라고 말하면 틀린 비교다.

동일 기준(둘 다 7-task 단순평균)으로 맞추면 로컬은 **0.259**, public은 **0.397**, 즉 **실제 격차는 약 −13.8%p**다. 이게 진짜 후보 격차(candidate gap)이며 단정은 아니다. 보고서/문서에서 격차를 말할 때는 항상 이 동일 기준 비교를 쓰고, 단일 원인으로 단정하지 마라.

### task-wise 격차 (스냅샷, 재-pull 필요)

```text
                public(gemma3-4b)   local(7-task)
teleqna         0.652               0.450      (MC)
teletables      0.273               0.200      (MC)
oranbench       0.660               0.367      (MC)
srsranbench     0.740               0.547      (MC)
telemath        0.137               0.010      (generative)
telelogs        0.117               0.170      (generative; local이 +0.053 우위)
3gpp_tsg_gen    0.200               0.070      (generative)
```

- 최대 격차는 **객관식 MC 3종**: `oranbench` (약 −0.29), `teleqna` (약 −0.20), `srsranbench` (약 −0.19).
- 생성형 3종은 거의 바닥이다: `telemath` 0.01, `3gpp_tsg_gen` 0.07, `telelogs` 0.17.

## 4. 원인 가설 (코드로 검증할 대상 — 추측 금지)

아래는 가설일 뿐이다. 추측이나 창작으로 단정하지 말고, **코드 근거로 확인**해줘.

- **MC scoring 방식**: 현재 MC는 `output_type: multiple_choice`라 loglikelihood scoring을 쓴다. 공식 GSMA는 generation 후 답 추출(generated-answer selection) 방식일 가능성이 있으나 **공식 추출 방식은 repo 문서상 명시적으로 UNKNOWN**이다(`REPRODUCTION_NOTES.md` 참조). 따라서 generation 변형의 점수 상승을 "공식 정렬"이라고 명명하거나 주장하지 마라.
- **생성형 truncation / parser**: 긴 prompt의 left-truncation(예: 2902→2024 tokens 잘림) + 답 추출 parser 취약성(`telemath` 수치 추출, `telelogs` 라벨/`\boxed{}` 추출, `3gpp_tsg` working group 값 추출)이 저점수 후보.
- **ot-lite vs ot-full split**: 어떤 split로 측정했는지에 따라 sample 구성이 다르다.
- **model variant mismatch**: public의 `gemma3-4b` row가 instruct/base/API/특정 revision 중 무엇인지 미확인. 격차의 다수가 이 variant 불일치로 설명될 수도 있다(미확정).
- **TeleTables 데이터**: `teletables`는 디스크의 원본 표 파일에 의존한다. `TELETABLES_ROOT`가 set되지 않으면 metadata-only로 저평가될 수 있고, run 스크립트는 이 변수를 자동 export하지 않는다.

## 5. 환경 주의사항

- **`lm_eval` 설치 여부 확인 필수**: 현재 `.venv`에 `lm_eval`이 설치되어 있지 않을 수 있다. **설치 전에는 task 실행이 불가능**하다. clone pin은 commit `97a5e2c7`(EleutherAI upstream main)이다. 설치가 필요하면 이 pin을 기준으로 설치하고, 재설치 후 task-loading/import가 정상인지 먼저 검증해라.
- **vLLM backend는 `.venv` activate가 필수**다. vLLM은 CUDA forward-compat에 의존해 취약하므로, activate 없이 직접 호출하면 실패할 수 있다.
- 환경 스택은 하드핀되어 있다: `torch 2.11.0+cu128` / `transformers 5.12.1` / `vllm 0.23.0`. 이들과 `lm_eval` pin 재설치 간 호환이 깨질 수 있으니 주의.
- GPU는 A100 40GB 최대 6장 가용. `gemma-3-4b-it`는 단일 GPU로 충분하다. 데이터셋 로컬 캐시는 없을 수 있어 첫 run에서 다운로드가 발생한다.

## 6. 오늘 너에게 부탁하는 첫 작업 (진단 우선)

지금 당장 코드를 고치지 말고, **먼저 현황을 정확히 진단**해줘. 순서는 이렇다.

1. (코드 수정 전) `git status`로 상태 확인 — 위 2번 게이트.
2. task 정의를 정독해라. task는 **flat 7개 파일이 아니라** 아래 두 디렉터리 하위에 있다.
   ```text
   open_telco_lm_eval/tasks/open_telco_otlite/    # ot-lite 7-task + core4 legacy + utils.py
   open_telco_lm_eval/tasks/open_telco_otfull/    # open_telco_full_* 7-task + utils.py
   ```
   ot-lite의 논리적 7-task는 MC 4종(`teleqna`, `teletables`, `oranbench`, `srsranbench`)과 생성형 3종(`telemath`, `telelogs`, `3gpp_tsg_gen`)이다. 각 task의 YAML과 `utils.py`의 parser/util 코드를 **전부** 열어봐라. (참고: `open_telco_otfull/utils.py`는 ot-lite의 `utils.py`를 importlib로 재노출하므로, ot-lite parser를 바꾸면 ot-full도 동시에 영향받는다.)
3. 각 task에 대해 다음 항목을 **진단표**로 정리해라.
   ```text
   output_type · doc_to_text · target · choice · filter · process_results · metric
   ```
4. 그 표를 근거로, MC 4종과 생성형 3종 각각에서 "공식 점수와 벌어지는 원인"으로 의심되는 지점을 **코드 근거로** 구체적으로 짚어줘(추측 금지).
5. 그다음 수정 계획을 우선순위와 함께 제안해줘. 내 판단으로는 생성형 3종의 truncation/parser와 MC scoring 정렬 진단이 시급한데, 코드를 보고 동의하는지/다른 의견이 있는지 알려줘.

실제 평가 실행이 필요하면, 작은 sample(`--limit`)로 빠르게 먼저 돌려 파이프라인부터 확인하자.

## 7. 작업 원칙 / 하드 제약

- **lm-eval 기반 유지. Inspect AI로의 전면 교체 금지.** (차이는 분석·문서화만.)
- **정답 하드코딩 / 데이터 누수(leak) / leaderboard 과적합 / 모델별 사후 튜닝 금지.**
- **default scoring 동결(불변).** scoring 변형을 실험하더라도 기존 default 동작을 바꾸지 마라.
- **측정 우선. 한 번에 하나씩 변경**하고, 변경 전후(before/after) 점수를 항상 비교·기록해라.
- **GPU가 없으면 결과를 위조하지 마라.** GPU가 없으면 스크립트·문서를 정비하고, 사용자가 직접 돌릴 수 있는 정확한 command를 제공해라.
- **긴 GPU run은 smoke-first + 승인.** 항상 1장 smoke / bounded `--limit`로 먼저 돌리고 → 예상 소요시간·GPU 수·측정 sample count·출력 경로를 보고 → 승인을 받은 뒤 확대해라.
- **대용량 아티팩트 commit 금지.** raw log / cache / checkpoint / 대용량 결과를 무분별하게 commit하지 마라(`.gitignore` 준수). 기존 결과를 삭제하지도 마라.
- **"공식 leaderboard 완전 재현" 주장 금지.** "내부 baseline harness"와 명확히 구분해라.
- 이번 pass 범위 밖(끌어들이지 말 것): NFM 고유 Planning benchmark(Intent→Recipe, TeleYAML), 멀티모달/LMM/LAM, RAG-grounded QA, Korean Telco QA, 전체 레포 리팩터링.
- 문서는 한국어 중심, 코드·command·task·metric·model명은 영어로.

## 8. End-of-pass 체크리스트 (이번 작업을 마칠 때 보고할 것)

이번 pass를 끝낼 때 아래를 간결한 보고로 정리해줘.

1. 무엇을 바꿨는가 (변경 파일·요지).
2. 어떤 task가 어떻게 구현되어 있는가 (진단표 요약).
3. 어떤 command를 실행했는가.
4. 로컬 Gemma 3 4B 결과 (집계방식 명시: sample-weighted vs unweighted).
5. public leaderboard와의 비교 (동일 기준 0.259 vs 0.397 ≈ −13.8%p 명시).
6. task별 delta.
7. 어떤 격차 원인을 (코드 근거로) 확인/수정했는가.
8. 아직 미해결로 남은 것 (model-variant 미확정, TeleTables 부재 등 caveat 포함).
9. GPU full 평가가 불가능했다면, 사용자가 다음에 직접 실행해야 할 정확한 command.

먼저 위 1~6번 순서대로 시작해줘: 읽기 → `git status` → task 정독 → 진단표 작성. 코드 수정은 그 다음이다.
