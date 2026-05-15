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
  --model_args pretrained=google/gemma-3-4b-it \
  --device cuda:0 \
  --batch_size 2
```

```bash
lm_eval \
  --model hf \
  --tasks hellaswag \
  --model_args pretrained=google/gemma-3-4b-it,dtype=bfloat16 \
  --device cuda:0 \
  --batch_size 2
```

```bash
lm_eval \
  --model vllm \
  --model_args pretrained=google/gemma-3-4b-it,dtype=bfloat16,tensor_parallel_size=1,gpu_memory_utilization=0.5 \
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
  --model_args pretrained=google/gemma-3-4b-it \
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
- leaderboard-style 7-task pack
- teleqna, teletables, oranbench, srsranbench, telemath, telelogs, 3gpp_tsg

```bash
lm_eval \
  --model hf \
  --model_args pretrained=google/gemma-3-4b-it \
  --include_path open_telco_lm_eval/tasks \
  --tasks open_telco_otlite \
  --device cuda:0 \
  --batch_size 4 \
  --apply_chat_template \
  --output_path results/otlite-gemma3-4b-hf-1
```

```bash
CUDA_VISIBLE_DEVICES=1 lm_eval \
  --model vllm \
  --model_args pretrained=google/gemma-3-4b-it,dtype=bfloat16,tensor_parallel_size=1,gpu_memory_utilization=0.5 \
  --include_path open_telco_lm_eval/tasks \
  --tasks open_telco_otlite \
  --batch_size 4 \
  --apply_chat_template \
  --output_path results/otlite-gemma3-4b-vllm-1
```

```bash
CUDA_VISIBLE_DEVICES=2,3 lm_eval \
  --model vllm \
  --model_args pretrained=google/gemma-3-4b-it,dtype=bfloat16,tensor_parallel_size=2,data_parallel_size=1,gpu_memory_utilization=0.5 \
  --include_path open_telco_lm_eval/tasks \
  --tasks open_telco_otlite \
  --batch_size 4 \
  --apply_chat_template \
  --output_path results/otlite-gemma3-4b-vllm-2
```

```bash
BACKEND=vllm \
  VLLM_VISIBLE_DEVICES=2,3 \
  TENSOR_PARALLEL_SIZE=2 \
  MODEL_NAME=google/gemma-3-4b-it \
  ./run_open_telco_otlite.sh
```

```bash
TASKS=open_telco_otlite_core4 \
  MODEL_NAME=google/gemma-3-4b-it \
  ./run_open_telco_otlite.sh
```

- `open_telco_otlite` group score는 7개 벤치마크의 `acc` 단순 평균으로 집계
- `open_telco_otlite_core4`는 기존 4-task 실험 재현용 legacy 그룹

---

## LM-Evaluation-Harness(open_telco_otfull)

- open_telco_otfull
- leaderboard-style 7-task pack
- teleqna, teletables, oranbench, srsranbench, telemath, telelogs, 3gpp_tsg

```bash
BACKEND=hf \
  DEVICE=cuda:0 \
  MODEL_NAME=google/gemma-3-4b-it \
  BATCH_SIZE=4 \
  OUTPUT_PATH=results/otfull-gemma3-4b-hf \
  ./run_open_telco_otfull.sh
```

```bash
BACKEND=vllm \
  VLLM_VISIBLE_DEVICES=3 \
  MODEL_NAME=google/gemma-3-4b-it \
  BATCH_SIZE=4 \
  OUTPUT_PATH=results/otfull-gemma3-4b-vllm \
  ./run_open_telco_otfull.sh
```

```bash
BACKEND=vllm \
  VLLM_VISIBLE_DEVICES=2,3 \
  TENSOR_PARALLEL_SIZE=2 \
  MODEL_NAME=google/gemma-3-4b-it \
  BATCH_SIZE=4 \
  OUTPUT_PATH=results/otfull-gemma3-4b-vllm-tp2 \
  ./run_open_telco_otfull.sh
```

- `open_telco_otfull` group score는 7개 벤치마크의 `acc` 단순 평균으로 집계
- `3gpp_tsg`, `telemath`, `telelogs`는 generation 후 custom parser로 채점
- `teletables`는 `GSMA/ot-full` 공개 row만으로도 실행되며, 원본 표 파일이 있으면 `TELETABLES_ROOT=/path/to/tables`를 주어 프롬프트에 자동 주입 가능
