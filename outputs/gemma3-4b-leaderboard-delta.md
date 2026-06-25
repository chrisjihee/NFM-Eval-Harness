# GSMA leaderboard comparison: gemma3-4b

- Track detected: `ot-lite`
- Public source: GSMA/leaderboard (datasets)
- Primary metric: `acc,none`

## Per-task deltas

| Public column | Local task | Public | Local | Delta (local-public) |
|---|---|---:|---:|---:|
| `teleqna` | `open_telco_teleqna` | 0.6523 | 0.4510 | -0.2013 |
| `teletables` | `open_telco_teletables` | 0.2733 | 0.2000 | -0.0733 |
| `oranbench` | `open_telco_oranbench` | 0.6600 | 0.3733 | -0.2867 |
| `srsranbench` | `open_telco_srsranbench` | 0.7400 | 0.5200 | -0.2200 |
| `telemath` | `open_telco_telemath` | 0.1367 | 0.0100 | -0.1267 |
| `telelogs` | `open_telco_telelogs` | 0.1167 | 0.1700 | +0.0533 |
| `three_gpp` | `open_telco_3gpp_tsg_gen` | 0.2000 | 0.0600 | -0.1400 |

## Aggregates

| Aggregate | Value |
|---|---:|
| local group acc (sample-weighted) | 0.3700 |
| local unweighted task mean | 0.2549 |
| public average (reported) | 0.3970 |
| public unweighted mean (computed from tasks) | 0.3970 |
| delta unweighted (local mean - public computed mean) | -0.1421 |

## Caveat

CAVEAT:
- public avg is an UNWEIGHTED task mean, while the local group acc is SAMPLE-WEIGHTED. The honest like-for-like comparison is unweighted mean vs unweighted mean.
- The exact official GSMA extraction method and the public model variant are UNKNOWN, so each delta is a candidate gap, not a definitive conclusion.
- ot-lite uses a different split from ot-full / the public leaderboard; be careful comparing ot-lite directly against leaderboard numbers.
