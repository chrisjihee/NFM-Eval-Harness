# GSMA leaderboard comparison (gsma profile): qwen2.5-7b

- Track detected: `ot-full`
- Public source: GSMA/leaderboard (datasets)
- Primary metric: `acc,none`

## Per-task deltas

| Public column | Local task | Public | Local | Delta (local-public) | Note |
|---|---|---:|---:|---:|---|
| `teleqna` | `open_telco_full_teleqna_mcgen` | 0.7024 | 0.6985 | -0.0039 | engine UNALIGNED (free gen vs constrained decode); dominant candidate-gap driver; measures gen-vs-constrained sensitivity |
| `teletables` | `open_telco_full_teletables_mcgen` | 0.3007 | 0.2640 | -0.0367 | engine UNALIGNED (free gen vs constrained decode); dominant candidate-gap driver; measures gen-vs-constrained sensitivity |
| `oranbench` | `open_telco_full_oranbench_mcgen` | 0.6982 | 0.7047 | +0.0065 | engine UNALIGNED (free gen vs constrained decode); dominant candidate-gap driver; measures gen-vs-constrained sensitivity |
| `srsranbench` | `open_telco_full_srsranbench_mcgen` | 0.7772 | 0.8009 | +0.0237 | engine UNALIGNED (free gen vs constrained decode); dominant candidate-gap driver; measures gen-vs-constrained sensitivity |
| `telemath` | `open_telco_full_telemath_gsma` | 0.2973 | 0.2340 | -0.0633 |  |
| `telelogs` | `open_telco_full_telelogs_gsma` | 0.1431 | 0.1366 | -0.0065 |  |
| `three_gpp` | `open_telco_full_3gpp_tsg_gsma` | 0.2867 | 0.2830 | -0.0037 |  |

## Leaderboard-convention unweighted mean (NOT computed by official GSMA code)

| Aggregate | Value |
|---|---:|
| local unweighted task mean | 0.4460 |
| public unweighted mean (computed from tasks) | 0.4579 |
| public average (reported) | 0.4579 |
| delta unweighted (local mean - public computed mean) | -0.0120 |
| local group acc (sample-weighted) | 0.4460 |

## Caveat

CAVEAT (gsma profile):
- For the 4 MC tasks (teleqna/teletables/oranbench/srsranbench) the engine -- official multiple_choice(cot=False)+choice() constrained decoding vs lm-eval generate_until + until:[\n] + max_gen_toks:8 free single-letter generation -- is the LARGEST UNALIGNED axis and the dominant candidate-gap driver; the MC delta primarily measures generation-vs-constrained-decoding sensitivity, NEVER official reproduction.
- The *_gsma generation scorer rules mirror the gsma-evals source, but the generation engine differs (lm-eval generate vs Inspect generate).
- The GSMA repo computes no cross-task average; the single unweighted task mean below is a leaderboard convention only, NOT computed by official GSMA code.
- No production runtime / provider / model-revision parity is claimed.
