# Causal Inference Final Project

Replication and extension of Sánchez-García, Rodon & Delgado-García (2025),
*Where has everyone gone? Depopulation and voting behaviour in Spain*,
*European Journal of Political Research*, 64, 296–319.
DOI: [10.1111/1475-6765.12702](https://doi.org/10.1111/1475-6765.12702).

Author: Giorgio Coppola. Hertie School, Causal Inference (Spring 2026).

[**Read the report here →**](https://raw.githack.com/giocopp/SRD-replication-extension/main/final_project.html)

## What's in the project

- **Paper summary** — research question, theoretical and empirical estimand,
  DAG, identification assumptions and challenges.
- **Replication** — Table 2 of the paper (controlled two-way fixed-effects
  estimates of depopulation on vote shares for PSOE, PP, UP, Cs, PANES, ES,
  Vox, 2011–2019).
- **Extension** — a `grf` causal forest on Vox vote share to test for
  heterogeneous treatment effects across municipalities.

Everything (fits, tables, figures, narrative) lives in `final_project.qmd`.
The pre-rendered `final_project.html` and `final_project.pdf` are committed,
so the document is readable without running anything.

## Data

The authors' replication package is not redistributed here. To re-render the
QMD you need to obtain it yourself.

- The article is at DOI [10.1111/1475-6765.12702](https://doi.org/10.1111/1475-6765.12702);
  its data-availability statement points to the authors' replication archive.
- Extract the package contents into `data_explore/sanchez_garcia/` (create the
  folder if needed). The symlinks under `replication/database/` and
  `replication/analysis_*.R` resolve to files in that directory.

## How to reproduce

```bash
quarto render final_project.qmd
```

Requires R and Quarto (and TinyTeX for the PDF: `quarto install tinytex`).
The QMD installs its own R packages on first render. The causal-forest fit
takes about a minute.
