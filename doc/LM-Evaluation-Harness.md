# lm-eval-harness
평가 프레임워크

---

## lm-eval-harness

* https://github.com/EleutherAI/lm-evaluation-harness
* Language Model Evaluation Harness
* Eleuther.ai가 주도하여 개발된 평가 프레임워크
  - Huggingface의 LLM leaderboard와 korean LLM leaderboard에서 평가 프레임워크로 채택하여 운영
* ARC(추론을 필요로 하는 질의응답), HellaSwag(상식 기반 추론), MMLU(57개 영역의 지식 테스트), 그리고 TruthfulQA(사실성 및 정확성 평가)와 같은 다양한 벤치마크를 통해 언어모델을 평가

---

## LM-Evaluation-Harness

- 설치

```bash
git clone --depth 1 https://github.com/EleutherAI/lm-evaluation-harness
cd lm-evaluation-harness
pip3 install -e .
```

- 설치

```bash
pip3 install "lm_eval[hf]"
pip3 install "lm_eval[vllm]"
pip3 install "lm_eval[api]"
pip3 show lm_eval

which lm_eval
lm_eval --help
lm-eval ls tasks
```

---

## LM-Evaluation-Harness(hellaswag)

- 태스크 목록 / 실행

```bash
lm_eval \
  --model hf \
  --tasks hellaswag \
  --model_args pretrained=meta-llama/Llama-3.2-1B-Instruct \
  --device cuda:0 \
  --batch_size 2
```

```bash
lm_eval \
  --model hf \
  --tasks hellaswag \
  --model_args pretrained=meta-llama/Llama-3.2-1B-Instruct,dtype=bfloat16 \
  --device cuda:0 \
  --batch_size 2
```

```bash
lm_eval \
  --model vllm \
  --model_args pretrained=meta-llama/Llama-3.2-1B-Instruct,dtype=bfloat16,tensor_parallel_size=1,gpu_memory_utilization=0.5 \
  --tasks hellaswag \
  --batch_size auto
```

---

## LM-Evaluation-Harness(MMLU)

- MMLU

```bash
lm_eval \
  --model hf \
  --tasks mmlu \
  --model_args pretrained=meta-llama/Llama-3.2-1B-Instruct \
  --device cuda:0 \
  --batch_size 2
```

---

## LM-Evaluation-Harness(MMLU)

| Tasks |Version|Filter|n-shot|Metric| |Value | |Stderr|
|---------------------------------------|------:|------|-----:|------|---|-----:|---|-----:|
|mmlu | 2|none | |acc | |0.4827|± |0.0041|
| - humanities | 2|none | 0|acc |↑ |0.4587|± |0.0071|
| - formal_logic | 1|none | 0|acc |↑ |0.3571|± |0.0429|
| - high_school_european_history | 1|none | 0|acc |↑ |0.6606|± |0.0370|
| - high_school_us_history | 1|none | 0|acc |↑ |0.5931|± |0.0345|
| - high_school_world_history | 1|none | 0|acc |↑ |0.6456|± |0.0311|
| - international_law | 1|none | 0|acc |↑ |0.6777|± |0.0427|
| - jurisprudence | 1|none | 0|acc |↑ |0.5556|± |0.0480|
| - logical_fallacies | 1|none | 0|acc |↑ |0.5276|± |0.0392|
| - moral_disputes | 1|none | 0|acc |↑ |0.4653|± |0.0269|
| - moral_scenarios | 1|none | 0|acc |↑ |0.3620|± |0.0161|
| - philosophy | 1|none | 0|acc |↑ |0.5209|± |0.0284|
| - prehistory | 1|none | 0|acc |↑ |0.5247|± |0.0278|
| - professional_law | 1|none | 0|acc |↑ |0.3722|± |0.0123|
| - world_religions | 1|none | 0|acc |↑ |0.6667|± |0.0362|
| - other | 2|none | 0|acc |↑ |0.5494|± |0.0087|
| - business ethics | 1|none | 0|acc |↑ |0 4500|± |0 0500|

---

## LM-Evaluation-Harness(MMLU/GGUF)

- .gguf 평가 실행

```bash
pip install gguf

lm_eval \
  --model hf \
  --model_args pretrained=/home/std/.lmstudio/models/lmstudio-community/Llama-3.2-1B-Instruct-GGUF,gguf_file=Llama-3.2-1B-Instruct-Q4_K_M.gguf \
  --tasks mmlu \
  --device cuda:0 \
  --batch_size 8
```

---

## LM-Evaluation-Harness(open_telco_otlite)

- open_telco_otlite

```bash
lm_eval \
  --model hf \
  --model_args pretrained=meta-llama/Llama-3.2-1B-Instruct \
  --include_path open_telco_lm_eval/tasks \
  --tasks open_telco_otlite \
  --device cuda:0 \
  --batch_size 2 \
  --apply_chat_template \
  --output_path results/open_telco_otlite
```

```bash
lm_eval \
  --model vllm \
  --model_args pretrained=meta-llama/Llama-3.2-1B-Instruct,dtype=bfloat16,tensor_parallel_size=1,gpu_memory_utilization=0.5 \
  --include_path open_telco_lm_eval/tasks \
  --tasks open_telco_otlite \
  --batch_size 2 \
  --apply_chat_template \
  --output_path results/open_telco_otlite
```
