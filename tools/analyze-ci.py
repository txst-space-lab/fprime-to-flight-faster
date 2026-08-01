#!/usr/bin/env python3
"""Derive the poster's CI numbers and figures from the raw GitHub Actions export.

    python3 tools/analyze-ci.py

Reads  data/ci-runs.csv, data/ci-jobs.csv   (produced by tools/fetch-ci-data.sh)
Writes data/ci-summary.csv                  headline numbers for the stat tiles
       data/ci-pipeline-stages.csv          figure 1 source
       data/ci-hil-monthly.csv              figure 2 source
       data/ci-feedback-time.csv            figure 3 source
       figures/fig-pipeline-stages.svg
       figures/fig-hil-reliability.svg
       figures/fig-feedback-time.svg

Figures are sized for the 48x36in poster: 7in wide to match the template's
picture placeholders, with type set large enough to survive at 4ft viewing
distance. Typst places them at native size, so do not rescale on import.
"""

import os
from pathlib import Path

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt
import pandas as pd
from matplotlib import font_manager
from matplotlib.lines import Line2D
from matplotlib.patches import Patch

ROOT = Path(__file__).resolve().parent.parent
DATA = ROOT / "data"
FIGS = ROOT / "figures"

# The uart/radio split landed on this date. Everything after it is the pipeline
# the poster actually describes, so timing figures are scoped to it; anything
# before mixes in a differently-shaped `integration` job and would understate
# how much hardware testing the current gate does.
CURRENT_ERA = pd.Timestamp("2026-05-19", tz="UTC")

# All three figures share one canvas size so they can sit in a single row on the
# poster with their titles and captions on a common baseline. 7in matches the
# template's picture placeholder width; Typst places them at native size.
FIGSIZE = (7, 5.6)

# Palette: poster ink/maroon plus the validated categorical slots 1-2 and the
# reserved status pair. Slots 1-2 clear the all-pairs CVD and normal-vision
# floors on a white surface; pass/fail is state, so it takes status colors and
# never the series hues.
MAROON = "#501214"
INK = "#1a1a1a"
MUTED = "#5c5c5c"
GRID = "#e1e0d9"
AXIS = "#c3c2b7"
CLOUD = "#2a78d6"  # categorical slot 1 - software-only jobs
HARDWARE = "#eb6834"  # categorical slot 2 - jobs against the real satellite

# The split that matters for the poster is "does this job need the satellite",
# not "is the runner self-hosted" — `build` runs on the lab's own build box
# (deathstar) but never touches flight hardware, so it sits with the cloud jobs.
SOFTWARE_ONLY = "software only"
ON_SATELLITE = "real satellite"
GOOD = "#0ca30c"
CRITICAL = "#d03b3b"

# Stage display names and where each one runs. Order is pipeline order.
STAGES = [
    ("lint", "Lint", CLOUD),
    ("unit-test", "Unit tests", CLOUD),
    ("build", "Build FSW", CLOUD),
    ("yamcs-build", "YAMCS check", CLOUD),
    ("integration-uart", "HIL: UART", HARDWARE),
    ("integration-radio", "HIL: LoRa RF", HARDWARE),
]


def setup_fonts():
    """Prefer Inter so figures match the poster body text; fall back silently.

    The Nix shell exposes the pinned fonts through TYPST_FONT_PATHS, which
    matplotlib does not scan on its own, so register them by hand.
    """
    roots = [d for d in os.environ.get("TYPST_FONT_PATHS", "").split(":") if d]
    paths = font_manager.findSystemFonts(fontpaths=roots) if roots else font_manager.findSystemFonts()
    for path in paths:
        if "Inter" in Path(path).name:
            try:
                font_manager.fontManager.addfont(path)
            except RuntimeError:
                pass
    available = {f.name for f in font_manager.fontManager.ttflist}
    stack = [f for f in ("Inter", "Source Sans 3", "Liberation Sans", "DejaVu Sans") if f in available]
    plt.rcParams.update(
        {
            "font.family": "sans-serif",
            "font.sans-serif": stack or ["DejaVu Sans"],
            "font.size": 19,
            "text.color": INK,
            "axes.labelcolor": MUTED,
            "xtick.color": MUTED,
            "ytick.color": MUTED,
            "svg.fonttype": "none",  # keep text as text so Typst can subset it
        }
    )


def header(fig, title, subtitle=None):
    """Left-aligned title block in figure coords.

    Titles go on the figure rather than the axes so a long one can run the full
    width instead of being clipped to the plot box, and so the legend can sit
    directly beneath it without colliding with the marks.
    """
    fig.text(0.012, 0.965, title, color=MAROON, fontsize=21, fontweight="bold", va="top", ha="left")
    if subtitle:
        fig.text(0.012, 0.893, subtitle, color=MUTED, fontsize=16, va="top", ha="left")


def save(fig, name):
    """Write the SVG the poster imports, plus a PNG proof for eyeballing.

    The PNG exists because the SVG keeps its text as text (`svg.fonttype: none`)
    and standalone SVG rasterisers here have no fontconfig, so they substitute a
    fallback face and misreport the layout. Typst resolves Inter correctly.
    """
    fig.savefig(FIGS / f"{name}.svg", transparent=True)
    proof = FIGS / "proof"
    proof.mkdir(exist_ok=True)
    fig.savefig(proof / f"{name}.png", dpi=150, facecolor="white")
    plt.close(fig)


def style_axes(ax, xgrid=False, ygrid=False):
    """Recessive chrome: hairline grid on one axis only, no box, no tick marks."""
    for side in ("top", "right"):
        ax.spines[side].set_visible(False)
    for side in ("left", "bottom"):
        ax.spines[side].set_color(AXIS)
        ax.spines[side].set_linewidth(1.2)
    ax.tick_params(length=0, pad=8)
    if xgrid:
        ax.xaxis.grid(True, color=GRID, linewidth=1.2)
    if ygrid:
        ax.yaxis.grid(True, color=GRID, linewidth=1.2)
    ax.set_axisbelow(True)


def load():
    runs = pd.read_csv(DATA / "ci-runs.csv", parse_dates=["created_at", "updated_at", "run_started_at"])
    jobs = pd.read_csv(DATA / "ci-jobs.csv", parse_dates=["started_at", "completed_at"])
    # `cancelled` and `skipped` say nothing about the code under test, so every
    # rate in this file is computed over decided (success|failure) jobs only.
    jobs["decided"] = jobs.conclusion.isin(["success", "failure"])
    jobs["is_hil"] = jobs.job_name.str.startswith("integration")
    return runs, jobs


def fig_pipeline_stages(jobs):
    """Where the wall-clock goes in the current pipeline, cloud vs hardware."""
    cur = jobs[(jobs.started_at >= CURRENT_ERA) & jobs.decided]
    rows = []
    for name, label, color in STAGES:
        d = cur[cur.job_name == name].duration_s
        if d.empty:
            continue
        rows.append(
            {
                "stage": name,
                "label": label,
                "runs_on": ON_SATELLITE if color == HARDWARE else SOFTWARE_ONLY,
                "n": len(d),
                "median_s": round(d.median()),
                "p90_s": round(d.quantile(0.9)),
            }
        )
    df = pd.DataFrame(rows)
    df.to_csv(DATA / "ci-pipeline-stages.csv", index=False)

    fig = plt.figure(figsize=FIGSIZE)
    ax = fig.add_axes([0.30, 0.16, 0.68, 0.60])
    y = range(len(df))
    colors = [HARDWARE if r == ON_SATELLITE else CLOUD for r in df.runs_on]
    # p90 sits behind the median bar as a lighter tail rather than an errorbar,
    # so the "usual" number is the one that reads first.
    ax.barh(y, df.p90_s, height=0.6, color=colors, alpha=0.22, linewidth=0)
    ax.barh(y, df.median_s, height=0.6, color=colors, linewidth=0)
    ax.set_yticks(list(y), df.label, fontsize=18)
    ax.invert_yaxis()
    ax.set_xlim(0, df.p90_s.max() * 1.30)
    for i, row in df.iterrows():
        ax.text(
            row.p90_s + df.p90_s.max() * 0.03,
            i,
            f"{row.median_s / 60:.1f}",
            va="center",
            ha="left",
            fontsize=18,
            color=INK,
            fontweight="bold",
        )
    ax.set_xlabel("median job duration (minutes)", fontsize=17)
    ax.set_xticks(
        [0, 120, 240, 360, 480, 600, 720],
        ["0", "2", "4", "6", "8", "10", "12"],
        fontsize=16,
    )
    style_axes(ax, xgrid=True)
    header(
        fig,
        "Hardware testing dominates the pipeline",
        "solid bar = median, pale tail = 90th percentile",
    )
    fig.legend(
        handles=[
            Patch(facecolor=CLOUD, label="Software only"),
            Patch(facecolor=HARDWARE, label="On the real satellite (HIL)"),
        ],
        loc="upper left",
        bbox_to_anchor=(0.012, 0.855),
        frameon=False,
        fontsize=17,
        ncol=2,
        handlelength=1.1,
        columnspacing=1.4,
    )
    save(fig, "fig-pipeline-stages")
    return df


def fig_hil_reliability(jobs):
    """Monthly HIL outcomes: volume on top, pass rate below, one shared x axis.

    Deliberately two stacked panels rather than one dual-axis chart — counts and
    a percentage share no scale, and overlaying them would invite reading a
    crossing point that means nothing.
    """
    hil = jobs[jobs.is_hil & jobs.decided].copy()
    hil["month"] = hil.started_at.dt.tz_convert(None).dt.to_period("M")
    g = hil.groupby("month").conclusion.value_counts().unstack(fill_value=0)
    g = g.reindex(columns=["success", "failure"], fill_value=0)
    g = g.rename(columns={"success": "passed", "failure": "failed"})
    g["total"] = g.passed + g.failed
    g["pass_rate_pct"] = (g.passed / g.total * 100).round(1)
    g.index = g.index.astype(str)
    g.index.name = "month"
    g.to_csv(DATA / "ci-hil-monthly.csv")
    # The export ends mid-month, so the last bucket is a few days of data whose
    # rate swings wildly on a handful of jobs. Chart only complete months; the
    # CSV keeps the partial one so nothing is silently dropped from the record.
    last_complete = hil.started_at.max().tz_convert(None).to_period("M") - 1
    g = g[g.index <= str(last_complete)]

    fig = plt.figure(figsize=FIGSIZE)
    ax1 = fig.add_axes([0.155, 0.465, 0.825, 0.31])
    ax2 = fig.add_axes([0.155, 0.135, 0.825, 0.235], sharex=ax1)
    x = range(len(g))
    ax1.bar(x, g.passed, color=GOOD, width=0.66, linewidth=0, label="passed")
    # A 2px surface-colored edge is the gap between stacked segments.
    ax1.bar(x, g.failed, bottom=g.passed, color=CRITICAL, width=0.66, linewidth=2, edgecolor="white", label="failed")
    ax1.set_ylabel("HIL jobs run", fontsize=17)
    ax1.tick_params(labelbottom=False)
    style_axes(ax1, ygrid=True)
    header(
        fig,
        "The gate got more reliable as it got busier",
        f"complete months only, {g.index[0]} – {g.index[-1]}",
    )
    fig.legend(
        handles=[Patch(facecolor=GOOD, label="passed"), Patch(facecolor=CRITICAL, label="failed")],
        loc="upper left",
        bbox_to_anchor=(0.012, 0.865),
        frameon=False,
        fontsize=17,
        ncol=2,
        handlelength=1.1,
        columnspacing=1.4,
    )

    ax2.plot(x, g.pass_rate_pct, color=CLOUD, linewidth=3, marker="o", markersize=9, zorder=3)
    ax2.set_ylim(-6, 122)
    ax2.set_yticks([0, 50, 100], ["0", "50", "100"], fontsize=16)
    ax2.set_ylabel("pass rate (%)", fontsize=17)
    style_axes(ax2, ygrid=True)
    # Label only the endpoints; a number on every point would be noise.
    for i in (0, len(g) - 1):
        ax2.annotate(
            f"{g.pass_rate_pct.iloc[i]:.0f}%",
            (i, g.pass_rate_pct.iloc[i]),
            textcoords="offset points",
            xytext=(0, 15),
            ha="center",
            fontsize=18,
            fontweight="bold",
            color=INK,
        )
    ax2.set_xticks(list(x), [m[2:] for m in g.index], rotation=45, fontsize=15)
    for lbl in ax2.get_xticklabels():
        lbl.set_ha("right")
    save(fig, "fig-hil-reliability")
    return g


def fig_feedback_time(runs, jobs):
    """End-to-end commit-to-verdict wall clock for the current pipeline."""
    hil_runs = set(jobs[jobs.is_hil & (jobs.started_at >= CURRENT_ERA)].run_id)
    cur = runs[
        runs.run_id.isin(hil_runs) & runs.conclusion.isin(["success", "failure"]) & (runs.created_at >= CURRENT_ERA)
    ].copy()
    cur["duration_min"] = cur.duration_s / 60
    cur[["run_id", "run_number", "created_at", "event", "conclusion", "head_branch", "duration_s", "duration_min"]].to_csv(
        DATA / "ci-feedback-time.csv", index=False
    )

    med = cur.duration_min.median()
    p90 = cur.duration_min.quantile(0.9)
    fig = plt.figure(figsize=FIGSIZE)
    ax = fig.add_axes([0.135, 0.185, 0.845, 0.60])
    # The tail is long and thin; clipping into a final ">60" bucket keeps the
    # bulk of the distribution legible instead of squashing it against the axis.
    ax.hist(cur.duration_min.clip(upper=60), bins=range(0, 63, 3), color=CLOUD, linewidth=2, edgecolor="white")
    ax.axvline(med, color=MAROON, linewidth=3, zorder=5)
    top = ax.get_ylim()[1]
    ax.annotate(
        f"median\n{med:.0f} min",
        (med, top * 0.98),
        textcoords="offset points",
        xytext=(12, 0),
        va="top",
        fontsize=19,
        fontweight="bold",
        color=MAROON,
    )
    ax.set_xticks([0, 15, 30, 45, 60], ["0", "15", "30", "45", "60+"], fontsize=16)
    ax.set_xlabel("commit to hardware verdict (minutes)", fontsize=17)
    ax.set_ylabel("pipeline runs", fontsize=17)
    ax.tick_params(axis="y", labelsize=16)
    style_axes(ax, ygrid=True)
    header(
        fig,
        "Hardware feedback in minutes, not days",
        f"{len(cur):,} runs since {CURRENT_ERA.date()}  ·  90% inside {p90:.0f} min",
    )
    save(fig, "fig-feedback-time")
    return cur, med, p90


def summary(runs, jobs, stages, monthly, feedback, med, p90):
    hil = jobs[jobs.is_hil & jobs.decided]
    m = jobs.merge(runs[["run_id", "event", "head_branch"]], on="run_id")
    pr_hil = m[m.is_hil & m.decided & (m.event == "pull_request")]
    seq = pr_hil.sort_values("started_at").groupby("head_branch").conclusion.agg(list)
    caught = sum(1 for v in seq if "failure" in v and v[-1] == "success")

    cur = jobs[(jobs.started_at >= CURRENT_ERA) & jobs.decided]
    hw = cur[cur.is_hil].duration_s.median()
    critical_path = stages.loc[stages.stage == "build", "median_s"].iloc[0] + stages.loc[
        stages.stage == "integration-radio", "median_s"
    ].iloc[0]
    last6 = monthly.tail(6)

    benches = jobs.loc[jobs.is_hil, "runner_name"].dropna()
    n_benches = benches[~benches.str.startswith("GitHub Actions ")].str.lower().nunique()

    all_hil = jobs[jobs.is_hil]
    # Clip pathological durations: one hung job sat at the 24h runner timeout and
    # would otherwise add a fifth of the total on its own.
    hil_hours = round(all_hil.duration_s.clip(lower=0, upper=3600).sum() / 3600)

    rows = [
        ("window_start", runs.created_at.min().date(), "first CI run in the export"),
        ("window_end", runs.created_at.max().date(), "last CI run in the export"),
        ("pipeline_runs", len(runs), "total ci.yaml workflow runs"),
        ("commits_gated", runs.head_sha.nunique(),
         "distinct head commits that ran the pipeline — fewer than the run count because a commit "
         "re-runs on retry; and far fewer than the HIL job count because each run has dispatched TWO "
         "HIL jobs (UART + LoRa RF) since the 2026-05-19 split"),
        ("hil_jobs_dispatched", len(all_hil), "HIL jobs sent to a bench, any conclusion"),
        ("hil_hours", hil_hours, "total HIL job runtime, hours, individual jobs clipped to 1h"),
        ("hil_jobs_decided", len(hil), "HIL jobs that passed or failed (excludes cancelled/skipped)"),
        ("hil_jobs_failed", int((hil.conclusion == "failure").sum()), "HIL jobs that failed"),
        ("pr_branches_gated", pr_hil.head_branch.nunique(), "distinct PR branches the HIL gate ran on"),
        ("branches_blocked_then_fixed", caught,
         "PR branches where HIL failed and a later run passed — the gate blocked a merge until it was fixed "
         "(mixes real regressions with flakes; CI history cannot separate them)"),
        ("median_feedback_min", round(med, 1), f"median commit-to-verdict wall clock since {CURRENT_ERA.date()}"),
        ("p90_feedback_min", round(p90, 1), f"90th percentile commit-to-verdict since {CURRENT_ERA.date()}"),
        ("critical_path_min", round(critical_path / 60, 1), "build + slowest HIL job, medians, current pipeline"),
        ("median_hil_job_min", round(hw / 60, 1), "median HIL job duration, current pipeline"),
        ("hil_pass_rate_first_month_pct", monthly.pass_rate_pct.iloc[0], f"HIL pass rate in {monthly.index[0]}"),
        ("hil_pass_rate_last6mo_pct", round(last6.passed.sum() / last6.total.sum() * 100, 1),
         f"HIL pass rate over {last6.index[0]}..{last6.index[-1]}"),
        ("hil_benches", n_benches,
         "distinct self-hosted lab benches that ran HIL jobs — ephemeral 'GitHub Actions NNN' runner names "
         "are excluded and names are case-folded, so this counts machines rather than runner registrations"),
    ]
    df = pd.DataFrame(rows, columns=["metric", "value", "definition"])
    df.to_csv(DATA / "ci-summary.csv", index=False)
    return df


def main():
    setup_fonts()
    FIGS.mkdir(exist_ok=True)
    runs, jobs = load()
    stages = fig_pipeline_stages(jobs)
    monthly = fig_hil_reliability(jobs)
    feedback, med, p90 = fig_feedback_time(runs, jobs)
    s = summary(runs, jobs, stages, monthly, feedback, med, p90)
    print(s.to_string(index=False, max_colwidth=70))
    print(f"\nwrote 4 derived CSVs to {DATA}/ and 3 SVGs to {FIGS}/")


if __name__ == "__main__":
    main()
