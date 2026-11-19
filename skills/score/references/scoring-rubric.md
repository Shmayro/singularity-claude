# Singularity Scoring Rubric

Rate each dimension 0-20. Total: 0-100.

## Dimensions

### 1. Correctness (0-20)
Did the skill achieve the stated goal?

| Score | Meaning |
|-------|---------|
| 0-5   | Failed completely or produced wrong output |
| 6-10  | Partially correct, major issues |
| 11-15 | Mostly correct, minor issues |
| 16-20 | Fully correct, goal achieved |

### 2. Completeness (0-20)
Were all requirements addressed?

| Score | Meaning |
|-------|---------|
| 0-5   | Most requirements missed |
| 6-10  | Some requirements addressed |
| 11-15 | Most requirements addressed, minor gaps |
| 16-20 | All requirements fully addressed |

### 3. Edge Case Handling (0-20)
Did it handle unusual inputs, errors, and boundary conditions?

| Score | Meaning |
|-------|---------|
| 0-5   | No edge case handling, fragile |
| 6-10  | Basic error handling only |
| 11-15 | Handles common edge cases |
| 16-20 | Robust against unusual inputs and failures |

### 4. Efficiency (0-20)
Was the approach direct and token-efficient?

| Score | Meaning |
|-------|---------|
| 0-5   | Wasteful, unnecessary steps, verbose |
| 6-10  | Some unnecessary work |
| 11-15 | Mostly efficient, minor overhead |
| 16-20 | Direct, minimal, no wasted effort |

### 5. Reusability (0-20)
Could the output be reused or adapted for similar tasks?

| Score | Meaning |
|-------|---------|
| 0-5   | One-off, hardcoded, not adaptable |
| 6-10  | Limited reusability |
| 11-15 | Reasonably adaptable |
| 16-20 | Highly reusable, well-parameterized |

## Output Format

Return as JSON:

```json
{
  "totalScore": 75,
  "dimensions": {
    "correctness": { "score": 18, "rationale": "..." },
    "completeness": { "score": 15, "rationale": "..." },
    "edgeCases": { "score": 12, "rationale": "..." },
    "efficiency": { "score": 16, "rationale": "..." },
    "reusability": { "score": 14, "rationale": "..." }
  },
  "strengths": ["...", "..."],
  "weaknesses": ["..."],
  "edgeCasesEncountered": ["..."]
}
```
