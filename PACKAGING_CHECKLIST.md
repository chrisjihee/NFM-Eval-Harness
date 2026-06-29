# PACKAGING CHECKLIST — INL delivery

> **Historical / engineering note:** This file belongs to the engineering/provenance repository.
> For the current INL handoff package and curated final results, use `NFM-Eval-Harness-delivery`.
> Some commit hashes, result paths, or operational notes may reflect the state at the time this file was written.
>
> **역사/개발 메모:** 이 파일은 engineering/provenance 저장소의 문서입니다. 현재 INL 전달 정본과 최종 curated 결과는 `NFM-Eval-Harness-delivery`를 기준으로 확인하세요. 본문 일부 commit hash·result path·운영 메모는 작성 당시 상태를 반영할 수 있습니다.

전달(또는 release tag) 직전 점검. 대부분 `make delivery-check` 한 번으로 자동 확인된다.

## 자동 점검 (`make delivery-check`)

- [ ] `git status` clean (working tree)
- [ ] `bash -n run_open_telco_otlite.sh run_open_telco_otfull.sh` 통과
- [ ] `make smoke` 통과 (task 로딩)
- [ ] `pytest -q tests/` 통과 (73)
- [ ] stale 표현 없음 (`nfm-final-delivery-2026-06` / `진행 중` / `미실행/다음 단계`)
- [ ] secret 없음 (HF token / api key / password 패턴)
- [ ] tracked 파일 50MB 초과 없음 (`scripts/check_tracked_file_sizes.py`)

```bash
make delivery-check
```

## 수동 확인

- [ ] **no model weights / cache / raw sample dump** 가 추적되지 않음 (`RESULTS_MANIFEST.md` §3).
- [ ] `RESULTS_MANIFEST.md` 의 경로가 실제 tracked 파일과 일치, `outputs/run-index.jsonl`/`EXPERIMENTS.md`와 정합.
- [ ] `FINAL_DELIVERY_SUMMARY.md`/`INL_HANDOFF.md` 의 결과 요약이 `outputs/overnight-otfull-results.md`와 모순 없음(수치는 출처 1곳에만).
- [ ] 의도된 무결성 caveat("공식 GSMA 완전 재현 아님" 등) 유지됨.
- [ ] **license 결정** — 현재 **미정(TBD)**. 외부 배포 시 GSMA dataset/lm-eval/vLLM/model license와 별개로 결정. 내부 전달이면 `USAGE_SCOPE.md` 추가 또는 README에 "internal research handoff; license TBD" 명시.

## (선택) acceptance — GPU 가능 시

- [ ] `LIMIT=1 MODEL_NAME=google/gemma-3-4b-it ./run_open_telco_otlite.sh` 1-sample 통과.
- [ ] `LIMIT=1 BACKEND=vllm VLLM_VISIBLE_DEVICES=0 MODEL_NAME=google/gemma-3-4b-it ./run_open_telco_otlite.sh` (vLLM 경로; VM-induced hang 시 `INL_HANDOFF.md` §8 레시피 적용).

## Release tag (사용자가 최종 확인 후 직접 실행)

> Claude/agent는 tag를 push하지 않는다. 아래는 명령 안내일 뿐이다.

```bash
git tag -a v0.1-inl-delivery-2026-06-28 -m "NFM-Eval-Harness INL delivery package after PR5"
git push origin v0.1-inl-delivery-2026-06-28
```
