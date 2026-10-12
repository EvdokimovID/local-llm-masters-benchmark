"""Рисунок 2 статьи: скорость генерации и занятая видеопамять по моделям.

Запуск (нужен Python 3 и matplotlib):
    pip install matplotlib
    python analysis/plot_speed_vram.py
Данные берутся из results/summary/tech_summary_all.csv, рисунок сохраняется в analysis/fig_speed_vram.png.
"""
import csv
from pathlib import Path

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.patches import Patch

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "results" / "summary" / "tech_summary_all.csv"
OUT = ROOT / "analysis" / "fig_speed_vram.png"
RUSSIAN = {"Сбер", "Яндекс", "Т-Технологии"}
VRAM_LIMIT_GIB = 15.9  # 16303 МиБ

plt.rcParams["font.family"] = ["Times New Roman", "Liberation Serif", "DejaVu Serif"]

with open(SRC, encoding="utf-8") as f:
    rows = list(csv.DictReader(f, delimiter=";"))
rows.sort(key=lambda r: float(r["gen_tps_long"]))  # снизу вверх по скорости

names = [r["model"] for r in rows]
ru = [r["developer"] in RUSSIAN for r in rows]
offload = [int(r["gpu_share_pct"]) < 100 for r in rows]
RU, FO, INK = "#3a3a3a", "#bdbdbd", "#1a1a1a"

fig, (a1, a2) = plt.subplots(1, 2, figsize=(6.7, 3.3), dpi=300, sharey=True, gridspec_kw=dict(wspace=0.08))
for ax, key, title, xmax, fmt in (
    (a1, "gen_tps_long", "Скорость генерации, ток/с", 340, "{:.0f}"),
    (a2, "vram_gib", "Занятая видеопамять, ГБ", 19, "{:.1f}"),
):
    for i, r in enumerate(rows):
        v = float(r[key])
        ax.barh(i, v, height=0.62, color=RU if ru[i] else FO, edgecolor=INK, linewidth=0.6,
                hatch="////" if (offload[i] and key == "vram_gib") else None)
        ax.text(v + xmax * 0.012, i, fmt.format(v).replace(".", ","), va="center", ha="left", fontsize=8.5)
    ax.set_xlim(0, xmax)
    ax.set_title(title, fontsize=9.5, weight="bold")
    ax.tick_params(axis="x", labelsize=8)
    ax.tick_params(axis="y", length=0, labelsize=8.5)
    for sp in ("top", "right"):
        ax.spines[sp].set_visible(False)
    ax.grid(axis="x", color="#dddddd", lw=0.5)
    ax.set_axisbelow(True)

a1.set_yticks(range(len(rows)))
a1.set_yticklabels(names)
a2.axvline(VRAM_LIMIT_GIB, color=INK, ls="--", lw=1)
a2.text(VRAM_LIMIT_GIB - 0.15, len(rows) - 0.45, "объём\nвидеопамяти\n16 ГБ", ha="right", va="top", fontsize=7.5, style="italic")
for i, r in enumerate(rows):
    if offload[i]:
        pct = int(r["gpu_share_pct"])
        a2.annotate(f"{pct} % на GPU,\n{100 - pct} % в ОЗУ", xy=(12.5, i + 0.2), xytext=(8.6, i + 0.97),
                    fontsize=7.5, style="italic", ha="left", va="center",
                    arrowprops=dict(arrowstyle="-", lw=0.6, color=INK))
fig.legend(handles=[Patch(fc=RU, ec=INK, lw=0.6, label="российские модели"),
                    Patch(fc=FO, ec=INK, lw=0.6, label="зарубежные модели")],
           loc="lower center", ncol=2, fontsize=8.5, frameon=False, bbox_to_anchor=(0.55, -0.06))
fig.savefig(OUT, bbox_inches="tight", pad_inches=0.05)
print("Сохранено:", OUT)
