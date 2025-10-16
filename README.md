# CircActin: ImageJ Macros for Circumferential Actin and Vessel Constriction Analysis

This repository contains Fiji/ImageJ macros developed for the study  
**"Circumferential actomyosin bundles drive endothelial cell deformations to constrict blood vessels"**  
by *Yan Chen et al.*

These scripts automate preprocessing, measurement, and analysis of actomyosin organization, vessel geometry, and intensity dynamics in zebrafish intersegmental vessels (ISVs).

---

## 🧰 Contents

| File | Description |
|------|--------------|
| `yc_AO_preprocessing.ijm` | Preprocesses actin organization (AO) images — includes background correction, ROI cropping, channel separation, and saving ready-to-analyze images (without orthogonal view). |
| `yc_ActinLaser_GapDistance.ijm` | Measures actin gap distance or intensity recovery after laser ablation; designed for analyzing actin reorganization dynamics. |
| `yc_Measure_actomyosin_intensity.ijm` | Quantifies junctional vs cortical actomyosin intensity along vessel edges, normalizes signals, and outputs results as CSV. |

---

## ⚙️ Requirements
- **Fiji/ImageJ** (tested on version ≥1.54)
- **Bio-Formats plugin** enabled
- Multi-channel `.tif` input images (e.g., EGFP-UCHD, mCherry-Myl9b)
- Consistent file naming for batch analysis

---

## 🚀 Usage

1. Open ImageJ/Fiji  
2. Drag and drop the `.ijm` macro into the Fiji window  
3. Edit input/output folder paths inside the macro if needed  
4. Run via `Plugins → Macros → Run...`

Each macro will:
- Process all `.tif` files in the selected folder
- Generate projected and filtered outputs
- Export measurement tables to `.csv`

---

## 📂 Recommended File Naming

For clear batch processing and traceability:
