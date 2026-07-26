# Correctness Labeling Guide

## Purpose

This guide separates source presence from source correctness. A locator and an
exact quote make evidence inspectable, but they do not by themselves prove that
the evidence supports the claim.

## Retrieval Labels

Each query keeps a stable canonical intent and one or more independently written
variants. Annotators select every evidence chunk that directly answers that
intent. Lexically similar chunks that contradict, overstate, or discuss another
boundary are hard negatives, not relevant evidence.

Query variants use these labels:

- `canonical`: compact technical wording;
- `zh_paraphrase`: a natural Chinese restatement;
- `en_paraphrase`: a natural English restatement.

Recall and reciprocal rank are reported separately for each variant. A combined
score must not hide a paraphrase regression.

## Claim Support Labels

- `full`: the cited evidence supports the complete claim without adding a new
  condition, scope, guarantee, number, or causal conclusion.
- `partial`: the evidence supports part of the claim, but at least one material
  detail is absent or narrower than the claim.
- `none`: the evidence is irrelevant, contradictory, or only shares keywords.

A quote can be present for all three labels. Quote containment is therefore an
inspection check, not the semantic ground truth.

## Refusal Labels

Use `refusal_required` when the available evidence cannot support a formal
answer at the requested specificity. A refusal is incorrect when full evidence
exists, and an answer is unsupported when refusal was required but the system
states the claim as fact.

## Review Process

Labels should be assigned without looking at the system ranking. A second human
reviews disagreements involving `full` versus `partial`, source conflicts, and
every hard negative. Record the resolved label and rationale; do not use an LLM
judge as the sole ground truth.

The versioned fixture is a regression set, not a production-quality estimate.
New topics and naturally collected user queries must be kept outside the tuning
set until their first evaluation is recorded.
