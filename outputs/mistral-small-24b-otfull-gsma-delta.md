# GSMA leaderboard comparison (gsma profile): mistral-small-24b

- Track detected: `ot-full`
- Public source: GSMA/leaderboard (datasets)
- Primary metric: `acc,none`

## Per-task deltas

| Public column | Local task | Public | Local | Delta (local-public) | Note |
|---|---|---:|---:|---:|---|
| `teleqna` | `open_telco_full_teleqna_mcgen` | 0.7374 | 0.7269 | -0.0105 | engine UNALIGNED (free gen vs constrained decode); dominant candidate-gap driver; measures gen-vs-constrained sensitivity |
| `teletables` | `open_telco_full_teletables_mcgen` | 0.2973 | 0.2900 | -0.0073 | engine UNALIGNED (free gen vs constrained decode); dominant candidate-gap driver; measures gen-vs-constrained sensitivity |
| `oranbench` | `open_telco_full_oranbench_mcgen` | 0.7171 | 0.7300 | +0.0129 | engine UNALIGNED (free gen vs constrained decode); dominant candidate-gap driver; measures gen-vs-constrained sensitivity |
| `srsranbench` | `open_telco_full_srsranbench_mcgen` | 0.7630 | 0.6984 | -0.0646 | engine UNALIGNED (free gen vs constrained decode); dominant candidate-gap driver; measures gen-vs-constrained sensitivity |
| `telemath` | `open_telco_full_telemath_gsma` | 0.3613 | 0.3040 | -0.0573 |  |
| `telelogs` | `open_telco_full_telelogs_gsma` | 0.2311 | 0.2141 | -0.0170 |  |
| `three_gpp` | `open_telco_full_3gpp_tsg_gsma` | 0.5067 | 0.5075 | +0.0008 |  |

## Leaderboard-convention unweighted mean (NOT computed by official GSMA code)

| Aggregate | Value |
|---|---:|
| local unweighted task mean | 0.4958 |
| public unweighted mean (computed from tasks) | 0.5163 |
| public average (reported) | 0.5163 |
| delta unweighted (local mean - public computed mean) | -0.0204 |
| local group acc (sample-weighted) | 0.4958 |

## Caveat

CAVEAT (gsma profile):
- For the 4 MC tasks (teleqna/teletables/oranbench/srsranbench) the engine -- official multiple_choice(cot=False)+choice() constrained decoding vs lm-eval generate_until + until:[\n] + max_gen_toks:8 free single-letter generation -- is the LARGEST UNALIGNED axis and the dominant candidate-gap driver; the MC delta primarily measures generation-vs-constrained-decoding sensitivity, NEVER official reproduction.
- The *_gsma generation scorer rules mirror the gsma-evals source, but the generation engine differs (lm-eval generate vs Inspect generate).
- The GSMA repo computes no cross-task average; the single unweighted task mean below is a leaderboard convention only, NOT computed by official GSMA code.
- No production runtime / provider / model-revision parity is claimed.
