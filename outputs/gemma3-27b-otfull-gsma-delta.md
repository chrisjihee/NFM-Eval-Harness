# GSMA leaderboard comparison (gsma profile): gemma3-27b

- Track detected: `ot-full`
- Public source: GSMA/leaderboard (datasets)
- Primary metric: `acc,none`

## Per-task deltas

| Public column | Local task | Public | Local | Delta (local-public) | Note |
|---|---|---:|---:|---:|---|
| `teleqna` | `open_telco_full_teleqna_mcgen` | 0.7131 | 0.7216 | +0.0085 | engine UNALIGNED (free gen vs constrained decode); dominant candidate-gap driver; measures gen-vs-constrained sensitivity |
| `teletables` | `open_telco_full_teletables_mcgen` | 0.3333 | 0.3120 | -0.0213 | engine UNALIGNED (free gen vs constrained decode); dominant candidate-gap driver; measures gen-vs-constrained sensitivity |
| `oranbench` | `open_telco_full_oranbench_mcgen` | 0.7158 | 0.7080 | -0.0078 | engine UNALIGNED (free gen vs constrained decode); dominant candidate-gap driver; measures gen-vs-constrained sensitivity |
| `srsranbench` | `open_telco_full_srsranbench_mcgen` | 0.8056 | 0.8049 | -0.0007 | engine UNALIGNED (free gen vs constrained decode); dominant candidate-gap driver; measures gen-vs-constrained sensitivity |
| `telemath` | `open_telco_full_telemath_gsma` | 0.4067 | 0.0620 | -0.3447 |  |
| `telelogs` | `open_telco_full_telelogs_gsma` | 0.1601 | 0.1574 | -0.0027 |  |
| `three_gpp` | `open_telco_full_3gpp_tsg_gsma` | 0.3957 | 0.4350 | +0.0393 |  |

## Leaderboard-convention unweighted mean (NOT computed by official GSMA code)

| Aggregate | Value |
|---|---:|
| local unweighted task mean | 0.4573 |
| public unweighted mean (computed from tasks) | 0.5043 |
| public average (reported) | 0.5043 |
| delta unweighted (local mean - public computed mean) | -0.0471 |
| local group acc (sample-weighted) | 0.4573 |

## Caveat

CAVEAT (gsma profile):
- For the 4 MC tasks (teleqna/teletables/oranbench/srsranbench) the engine -- official multiple_choice(cot=False)+choice() constrained decoding vs lm-eval generate_until + until:[\n] + max_gen_toks:8 free single-letter generation -- is the LARGEST UNALIGNED axis and the dominant candidate-gap driver; the MC delta primarily measures generation-vs-constrained-decoding sensitivity, NEVER official reproduction.
- The *_gsma generation scorer rules mirror the gsma-evals source, but the generation engine differs (lm-eval generate vs Inspect generate).
- The GSMA repo computes no cross-task average; the single unweighted task mean below is a leaderboard convention only, NOT computed by official GSMA code.
- No production runtime / provider / model-revision parity is claimed.
