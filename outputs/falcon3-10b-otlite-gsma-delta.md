# GSMA leaderboard comparison (gsma profile): falcon3-10b

- Track detected: `ot-lite`
- Public source: GSMA/leaderboard (datasets)
- Primary metric: `acc,none`

## Per-task deltas

| Public column | Local task | Public | Local | Delta (local-public) | Note |
|---|---|---:|---:|---:|---|
| `teleqna` | `open_telco_teleqna_mcgen` | 0.6866 | 0.7370 | +0.0504 | engine UNALIGNED (free gen vs constrained decode); dominant candidate-gap driver; measures gen-vs-constrained sensitivity |
| `teletables` | `open_telco_teletables_mcgen` | 0.2767 | 0.2800 | +0.0033 | engine UNALIGNED (free gen vs constrained decode); dominant candidate-gap driver; measures gen-vs-constrained sensitivity |
| `oranbench` | `open_telco_oranbench_mcgen` | 0.6369 | 0.7133 | +0.0764 | engine UNALIGNED (free gen vs constrained decode); dominant candidate-gap driver; measures gen-vs-constrained sensitivity |
| `srsranbench` | `open_telco_srsranbench_mcgen` | 0.7679 | 0.7933 | +0.0254 | engine UNALIGNED (free gen vs constrained decode); dominant candidate-gap driver; measures gen-vs-constrained sensitivity |
| `telemath` | `open_telco_telemath_gsma` | 0.3433 | 0.3900 | +0.0467 |  |
| `telelogs` | `open_telco_telelogs_gsma` | 0.1910 | 0.1600 | -0.0310 |  |
| `three_gpp` | `open_telco_3gpp_tsg_gsma` | 0.3093 | 0.2800 | -0.0293 |  |

## Leaderboard-convention unweighted mean (NOT computed by official GSMA code)

| Aggregate | Value |
|---|---:|
| local unweighted task mean | 0.4791 |
| public unweighted mean (computed from tasks) | 0.4588 |
| public average (reported) | 0.4588 |
| delta unweighted (local mean - public computed mean) | +0.0203 |
| local group acc (sample-weighted) | 0.4791 |

## Caveat

CAVEAT (gsma profile):
- For the 4 MC tasks (teleqna/teletables/oranbench/srsranbench) the engine -- official multiple_choice(cot=False)+choice() constrained decoding vs lm-eval generate_until + until:[\n] + max_gen_toks:8 free single-letter generation -- is the LARGEST UNALIGNED axis and the dominant candidate-gap driver; the MC delta primarily measures generation-vs-constrained-decoding sensitivity, NEVER official reproduction.
- The *_gsma generation scorer rules mirror the gsma-evals source, but the generation engine differs (lm-eval generate vs Inspect generate).
- The GSMA repo computes no cross-task average; the single unweighted task mean below is a leaderboard convention only, NOT computed by official GSMA code.
- No production runtime / provider / model-revision parity is claimed.
