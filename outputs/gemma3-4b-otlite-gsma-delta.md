# GSMA leaderboard comparison (gsma profile): gemma3-4b

- Track detected: `ot-lite`
- Public source: GSMA/leaderboard (datasets)
- Primary metric: `acc,none`

## Per-task deltas

| Public column | Local task | Public | Local | Delta (local-public) | Note |
|---|---|---:|---:|---:|---|
| `teleqna` | `open_telco_teleqna_mcgen` | 0.6523 | 0.6610 | +0.0087 | engine UNALIGNED (free gen vs constrained decode); dominant candidate-gap driver; measures gen-vs-constrained sensitivity |
| `teletables` | `open_telco_teletables_mcgen` | 0.2733 | 0.2500 | -0.0233 | engine UNALIGNED (free gen vs constrained decode); dominant candidate-gap driver; measures gen-vs-constrained sensitivity |
| `oranbench` | `open_telco_oranbench_mcgen` | 0.6600 | 0.6733 | +0.0133 | engine UNALIGNED (free gen vs constrained decode); dominant candidate-gap driver; measures gen-vs-constrained sensitivity |
| `srsranbench` | `open_telco_srsranbench_mcgen` | 0.7400 | 0.7800 | +0.0400 | engine UNALIGNED (free gen vs constrained decode); dominant candidate-gap driver; measures gen-vs-constrained sensitivity |
| `telemath` | `open_telco_telemath_gsma` | 0.1367 | 0.1000 | -0.0367 |  |
| `telelogs` | `open_telco_telelogs_gsma` | 0.1167 | 0.0900 | -0.0267 |  |
| `three_gpp` | `open_telco_3gpp_tsg_gsma` | 0.2000 | 0.2400 | +0.0400 |  |

## Leaderboard-convention unweighted mean (NOT computed by official GSMA code)

| Aggregate | Value |
|---|---:|
| local unweighted task mean | 0.3992 |
| public unweighted mean (computed from tasks) | 0.3970 |
| public average (reported) | 0.3970 |
| delta unweighted (local mean - public computed mean) | +0.0022 |
| local group acc (sample-weighted) | 0.3992 |

## Caveat

CAVEAT (gsma profile):
- For the 4 MC tasks (teleqna/teletables/oranbench/srsranbench) the engine -- official multiple_choice(cot=False)+choice() constrained decoding vs lm-eval generate_until + until:[\n] + max_gen_toks:8 free single-letter generation -- is the LARGEST UNALIGNED axis and the dominant candidate-gap driver; the MC delta primarily measures generation-vs-constrained-decoding sensitivity, NEVER official reproduction.
- The *_gsma generation scorer rules mirror the gsma-evals source, but the generation engine differs (lm-eval generate vs Inspect generate).
- The GSMA repo computes no cross-task average; the single unweighted task mean below is a leaderboard convention only, NOT computed by official GSMA code.
- No production runtime / provider / model-revision parity is claimed.
