네, **가능합니다.** 다만 정확히는 두 수준으로 나누어 봐야 합니다.

1. **공식 GSMA 리더보드 재현**: GSMA의 공개 설명 기준으로 Open Telco는 현재 **Inspect AI 기반** 평가 suite로 운영됩니다. 따라서 리더보드와 완전히 동일한 점수를 재현하려면 GSMA의 Inspect AI/evals 또는 Satellite 쪽을 쓰는 것이 정석입니다. GSMA Hugging Face 설명에서도 Open Telco가 Inspect AI framework 위에 구축되어 있고, `ot-full`, `ot-lite`, leaderboard scores를 제공한다고 설명합니다. ([Hugging Face][1])

2. **LM-Evaluation-Harness로 기본 성능 측정**: 충분히 가능합니다. 특히 “우리 후보 모델이 통신 벤치마크에서 대략 어느 정도 나오는지”, “도메인 적응 전후 성능 차이가 있는지”, “NFM-LLM 베이스 모델 선정용 baseline을 만들지” 같은 목적이면 LM-Evaluation-Harness로 구현하는 것이 적절합니다.

## 왜 가능한가요?

첨부된 LM-Evaluation-Harness 자료에서처럼 `lm_eval`은 Hugging Face 모델을 불러와 task별로 평가하고, MMLU나 HellaSwag처럼 task를 지정해 accuracy를 계산하는 구조입니다.  Open Telco 벤치마크도 대부분은 “문항 → 모델 응답 → 정답 비교” 형태라서 `lm_eval` custom task로 옮길 수 있습니다.

EleutherAI 공식 문서 기준으로도 LM-Evaluation-Harness는 새로운 task를 YAML로 정의할 수 있고, Hugging Face dataset을 `dataset_path`, `dataset_name`으로 불러오며, `doc_to_text`, `doc_to_target`, `doc_to_choice`, `process_docs` 등을 통해 프롬프트와 정답 처리 방식을 정의할 수 있습니다. Multiple-choice task는 `doc_to_choice`와 정답 index를 사용하고, generation task는 생성 결과를 후처리해 metric을 계산하는 방식입니다. ([GitHub][2])

## 어떤 벤치마크부터 구현하면 좋을까요?

킥오프 자료에서 언급한 **GSMA Open-Telco LLM Benchmark 2.0**은 84개 모델 평가 결과를 바탕으로 TeleQnA, 3GPP-TSG, TeleMath, TeleLogs, TeleYAML 등을 제시하고, 특히 TeleYAML에서 전 모델이 30점 미만이라는 점을 가장 시급한 문제로 강조합니다. 

현재 공개 Hugging Face 기준으로는 GSMA가 `ot-lite`와 `ot-full`을 제공합니다. `ot-lite`는 빠른 반복 평가용이고, dataset viewer에는 `3gpp_tsg`, `oranbench`, `sixg_bench`, `srsranbench`, `telelogs`, `telemath`, `teleqna`, `teletables` config가 보입니다. ([Hugging Face][3]) `GSMA/leaderboard`에는 모델별 공개 점수가 있고, 현재 public dataset은 모델명, provider, rank, average, benchmark별 score/stderr를 포함합니다. ([Hugging Face][4])

따라서 **1차 구현 범위**는 아래처럼 잡는 것이 현실적입니다.

| 벤치마크            | LM-Eval 구현 난이도 | 권장 방식                                                |
| --------------- | -------------: | ---------------------------------------------------- |
| **TeleQnA**     |             낮음 | multiple_choice, `acc`/`acc_norm`                    |
| **3GPP-TSG**    |          낮음~중간 | working group 분류, exact match 또는 multiple_choice     |
| **ORANBench**   |             낮음 | multiple_choice                                      |
| **srsRANBench** |             낮음 | multiple_choice                                      |
| **TeleTables**  |             중간 | 표 기반 QA, multiple_choice 또는 generation 후 exact match |
| **TeleMath**    |             중간 | generation 후 수치 정답 parsing                           |
| **TeleLogs**    |          중간~높음 | RCA label/원인 추출 후 exact match 또는 custom parser       |
| **TeleYAML**    |             높음 | YAML/schema validation 기반 custom metric 필요           |

여기서 **TeleYAML은 별도 주의가 필요합니다.** GSMA의 2.0 관련 설명에서는 TeleYAML을 “intent-to-configuration”, 즉 자연어 intent를 schema-compliant configuration으로 변환하는 평가로 설명하고 있습니다. ([GSMA][5]) 이건 단순 정답 문자열 비교보다 **YAML 파싱, schema validation, 필드 단위 정합성, semantic equivalence**가 중요해서 LM-Eval에 custom metric을 붙여야 합니다.

## 구현 전략

가장 좋은 접근은 **GSMA/ot-lite → LM-Eval custom task → 후보 모델 baseline → ot-full 확장** 순서입니다.

```bash
pip install "lm_eval[hf]"
pip install datasets evaluate pyyaml jsonschema
```

예시 실행 형태는 첨부 자료의 MMLU/HellaSwag 실행 방식과 거의 같습니다. 

```bash
lm_eval \
  --model hf \
  --model_args pretrained=meta-llama/Llama-3.2-3B-Instruct,dtype=bfloat16 \
  --include_path ./open_telco_lm_eval/tasks \
  --tasks open_telco_teleqna,open_telco_3gpp_tsg,open_telco_telemath \
  --limit 5 \
  --device cuda:0 \
  --batch_size auto \
  --apply_chat_template \
  --output_path ./results/open_telco_baseline
```

위는 `--limit 5` 를 동반한 bounded smoke 예시입니다. 전체 run은 가드를 거쳐 실행합니다.
bounded smoke: `LIMIT=5 MODEL_NAME=google/gemma-3-4b-it ./run_open_telco_otlite.sh`,
full run: `CONFIRM_FULL_RUN=1 MODEL_NAME=google/gemma-3-4b-it ./run_open_telco_otlite.sh`.

예를 들어 `3gpp_tsg`는 처음에는 generation 방식으로 단순 구현할 수 있습니다.

```yaml
task: open_telco_3gpp_tsg
dataset_path: GSMA/ot-lite
dataset_name: 3gpp_tsg
test_split: test
output_type: generate_until

doc_to_text: "{{question}}\nAnswer:"
doc_to_target: "{{answer}}"

generation_kwargs:
  until:
    - "\n"
  max_gen_toks: 64
  temperature: 0.0

metric_list:
  - metric: exact_match
    aggregation: mean
    higher_is_better: true

metadata:
  version: 0.1
```

다만 실제 점수 신뢰도를 높이려면 `answer`가 `{"WORKING GROUP": "SA5"}` 같은 JSON 형식일 수 있으므로, 모델 출력에서 JSON을 파싱하고 `WORKING GROUP` 값만 비교하는 `utils.py` custom metric을 붙이는 편이 좋습니다.

## 재현성 측면에서 주의할 점

LM-Eval로 구현한 점수와 GSMA leaderboard 점수가 다를 수 있습니다. 이유는 대체로 다음입니다.

| 이슈                             | 영향                                        |
| ------------------------------ | ----------------------------------------- |
| 공식 GSMA는 Inspect AI 기반         | prompt, sampling, parser, scorer가 다를 수 있음 |
| `ot-lite`와 `ot-full` 차이        | lite 점수는 개발용, publishable 결과는 full 기준     |
| chat template 사용 여부            | instruct model 점수에 큰 영향                   |
| multiple-choice scoring 방식     | loglikelihood 방식과 생성 후 정답 추출 방식이 다름       |
| TeleLogs/TeleMath/TeleYAML 후처리 | 정답 parsing 규칙에 따라 점수 변동                   |
| proprietary API 모델             | 동일 모델명이라도 버전/날짜에 따라 결과 변동                 |

따라서 목표를 “GSMA leaderboard 공식 점수 복제”로 잡기보다는, 먼저 **ETRI 내부 후보 모델 간 상대 비교와 도메인 적응 효과 측정**으로 잡는 것이 좋습니다.

## NFM 과제 관점에서의 의미

RFP는 NFM 성능 검증을 위한 벤치마크 평가 체계 구축, 1단계 평가, 2단계 평가 고도화를 명시하고 있습니다.  또 NFM-LLM은 3GPP 표준·매뉴얼 기반 알람 상관 분석, 근본 원인 진단, 자연어 리포트 생성, intent 해석과 recipe 생성 역할을 담당하도록 정의되어 있습니다. 

그래서 LM-Evaluation-Harness 기반 Open Telco baseline은 과제 초기에 꽤 유용합니다. 특히 다음 세 가지 산출물로 연결하기 좋습니다.

| 산출물                            | 내용                                                     |
| ------------------------------ | ------------------------------------------------------ |
| **Baseline Report**            | 공개 LLM, 국산 LLM, 후보 base model의 Open Telco 점수 비교        |
| **NFM-LLM Evaluation Harness** | TeleQnA/3GPP/TeleMath/TeleLogs/TeleYAML custom task 묶음 |
| **Domain Adaptation 효과 분석**    | 사전학습/파인튜닝/RAG 적용 전후 점수 변화                              |

결론적으로, **LM-Evaluation-Harness로 구현 가능합니다.** 다만 공식 GSMA 리더보드의 완전 재현은 Inspect AI 설정과 scorer를 맞춰야 하고, LM-Eval 버전은 **NFM-LLM 후보 모델 선정과 도메인 적응 효과 검증용 내부 평가 harness**로 먼저 구축하는 것이 가장 현실적인 접근입니다.

[1]: https://huggingface.co/GSMA "GSMA (GSMA)"
[2]: https://github.com/EleutherAI/lm-evaluation-harness/blob/main/docs/new_task_guide.md "lm-evaluation-harness/docs/new_task_guide.md at main · EleutherAI/lm-evaluation-harness · GitHub"
[3]: https://huggingface.co/datasets/GSMA/ot-lite "GSMA/ot-lite · Datasets at Hugging Face"
[4]: https://huggingface.co/datasets/GSMA/leaderboard "GSMA/leaderboard · Datasets at Hugging Face"
[5]: https://www.gsma.com/newsroom/article/gsma-open-telco-llm-benchmarks-ranks-frontier-ai-models-for-telco-ai-revealing-critical-gap-in-network-automation-readiness/?utm_source=chatgpt.com "GSMA Open-Telco LLM Benchmarks ranks frontier AI models for Telco AI, revealing critical gap in network automation readiness"
