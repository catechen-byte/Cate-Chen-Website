---
title: "UBI and AI Labor Shocks — Welfare Framework"
date: "2026-06-01"
summary: "Research note on a micro-founded welfare framework for evaluating UBI under heterogeneous AI exposure."
tags: ["UBI", "AI", "welfare", "microsimulation"]
citation: "Chen, C. (2026). UBI and AI Labor Shocks: A Welfare Framework. Working paper."
abstract: "This note develops a CRRA-based social welfare aggregator over synthetic U.S. households with occupation-level AI exposure, funding UBI via progressive taxation and comparing counterfactual AI scenarios."
pdf: "/projects/ubi-ai-welfare/ubi_ai_welfare.pdf"
draft: false
---

## Abstract

How should policymakers evaluate Universal Basic Income when AI reshapes labor demand unevenly across occupations? This working note builds a transparent microsimulation pipeline:

- Synthetic households calibrated to U.S. income and employment patterns
- Occupation-level AI exposure shocks under three narrative scenarios
- UBI levels from $250–$1,500 per month, funded through configurable tax rules
- Social welfare comparisons using CRRA utility and inequality metrics

## Methods snapshot

The analysis combines reduced-form causal designs (DiD/event studies, synthetic control) with predictive models of exposure effects. Full methods and sensitivity grids appear in the [PDF report](/projects/ubi-ai-welfare/ubi_ai_welfare.pdf).

## Data & code

All code is in `projects/ubi-ai-welfare/`. Generated outputs are kept out of Git; rebuild with `make data` and `make pdf`.
