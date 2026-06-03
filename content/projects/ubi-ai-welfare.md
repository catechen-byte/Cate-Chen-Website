---
title: "UBI, AI, and Social Welfare"
date: "2026-06-01"
summary: "R project estimating how Universal Basic Income changes social welfare under AI labor-market disruption scenarios for the U.S."
tags: ["R", "economics", "UBI", "AI", "welfare"]
pdf: "/projects/ubi-ai-welfare/ubi_ai_welfare.pdf"
draft: false
---

This project models how **Universal Basic Income (UBI)** affects aggregate social welfare under three AI labor-market scenarios:

1. **Historical innovation** — productivity gains with limited displacement
2. **Aligned augmentation** — AI complements human labor
3. **Misaligned automation** — rapid displacement and inequality pressure

## What it includes

- Household microsimulation with CRRA welfare aggregation
- Difference-in-differences and synthetic control panels
- Machine-learning prediction of exposure effects
- Interactive **Shiny dashboard** and a full PDF report

## Artifacts

- [Download the PDF report](/projects/ubi-ai-welfare/ubi_ai_welfare.pdf)
- Source code lives in `projects/ubi-ai-welfare/` in this repo

## Reproduce locally

```bash
cd projects/ubi-ai-welfare
make install
make data
make pdf
make preview
```

The dashboard runs at `http://127.0.0.1:3838`.
