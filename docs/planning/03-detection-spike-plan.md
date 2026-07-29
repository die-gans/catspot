# Catspot — Spike Plan: Detection & AI Pipeline (4 Weeks)

**Document 03 in the Catspot planning series.**
**Status:** Proposed · **Date:** July 29, 2026
**Basis:** `docs/research/03-prd-north-star.md` (F1, §9 metrics), `docs/research/02-technical-blueprint.md` (§5 AI/ML Pipeline, §10 costs, §12 risks)
**Owner:** Engineering · **Duration:** 4 weeks · **Type:** Time-boxed technical spike (throwaway code allowed, learnings mandatory)

---

## 1. Why This Spike Exists

Per PRD Principle #1 — *"The catch is sacred"* — detection reliability is the game's core verb and its biggest technical risk (Blueprint Risk #1: **fatal if it fails**). The incumbent holds 3.0★ primarily because detection doesn't work. Before committing 4 months to an MVP, we must prove with numbers, on real hardware, with real cats, that our multi-stage pipeline can hit:

- **≥90% detection recall at ≤5m** on a 2020–2021 mid-range device (PRD F1, §9)
- **≥95% precision rejecting photos-of-screens/prints** (PRD F1)
- **≥80% first-scan success** when the full degrade chain (on-device → server → manual) is engaged (Phase 1 gate)
- **Duplicate detection accurate enough** that "same cat merges, different cats don't" (Blueprint Risk #5)
- **AI cost per scan ≤ $0.007** at our chosen thresholds (Blueprint §10 margin note)

**Spike question, one sentence:** *Can we build a detect → verify → dedupe → cutout pipeline that a first-time user experiences as "it just works," at a cost the economy can afford?*

**Out of scope for the spike:** full app shell, economy, maps, social, IAP, auth. We build the pipeline + a minimal test harness app, nothing more.

---

## 2. Success Criteria (the GO/NO-GO Gate)

All metrics measured on the **held-out field test set** (§4.3), not training data.

| # | Metric | GO threshold | Stretch | Measured how |
|---|---|---|---|---|
| G1 | On-device detector recall (any cat in frame, ≤5m, day/indoor) | ≥85% | ≥90% | Frame-level eval harness on labeled clips |
| G2 | **End-to-end first-scan success rate** (any stage of the degrade chain returns a keepsake for a real cat) | ≥90% | ≥95% | Full-pipeline harness over field test set |
| G3 | Screen/print spoof rejection precision | ≥95% | ≥98% | Adversarial subset (photos of phones, prints, monitors) |
| G4 | Spoof recall (real cats *not* falsely rejected as spoof) | ≥97% | ≥99% | Same eval; a false-spoof-reject is a lost player |
| G5 | Same-cat dedup: pairwise accuracy on labeled same/different cat pairs | ≥90% | ≥95% | Threshold sweep on embeddings + pHash, ROC/AUC report |
| G6 | Server verdict p95 latency (upload → vision-LLM verdict) | ≤30s | ≤15s | Timed runs; ≤60s is PRD hard max |
| G7 | Cutout quality: human-rated "usable as card sticker" (2 reviewers, 100 samples) | ≥80% usable | ≥90% | Blind review rubric (edges, fur, occlusion) |
| G8 | Blended AI cost per successful scan | ≤$0.010 | ≤$0.007 | Actual API invoices / metered usage during spike |
| G9 | On-device inference on 2020 mid-range Android | ≥15fps, ≤40°C sustained | 30fps | Frame processor instrumentation |

**Decision rule (end of Week 4):**
- **GO** — all of G1–G8 met (G9 advisory). Proceed to Phase 0/1 of the blueprint plan.
- **CONDITIONAL GO** — G2 (end-to-end) met but one of G1/G3/G5 missed by ≤5 points: proceed only with a written mitigation in the MVP plan (e.g., lean harder on server verification, adjust dedup UX to "merge or keep both" prompt).
- **NO-GO** — G2 missed, or G8 blown by >2×: the core promise is not yet buildable with this stack. Options: pivot detector strategy (e.g., server-primary detection), re-scope the first-catch experience, or pause. Re-spike requires founder decision.

---

## 3. Architecture Under Test

We test exactly the pipeline from Blueprint §3/§5, in throwaway form:

```
[Flutter test app: camera plugin + google_mlkit_object_detection / tflite_flutter]
   on-device detect (MLKit baseline AND custom TFLite candidate)
   → capture JPEG + bbox + device meta
        │
        ▼
[Throwaway ingest endpoint (Convex action or plain Cloudflare Worker — spike's choice)]
   1. pHash (exact-dup reject)
   2. Vision-LLM verdict: is_real_cat / is_live_photo / breed / colors / confidence
   3. Embedding (512-d) → cosine vs. prior scans (same-cat dedup threshold sweep)
   4. BiRefNet/rembg cutout → PNG
   5. Structured result logged to eval DB (PostHog events or plain SQLite/Sheets)
```

**Deliberate simplifications for the spike:** no cans/economy, no rarity rolls, no moderation console (a spreadsheet + folder of flagged images is fine), no geohash logic, no auth (a single test token).

---

## 4. Dataset Collection Plan

This is the foundation of the whole spike. **All metrics are meaningless without a representative, labeled field set.**

### 4.1 Sources & target sizes

| Set | Size (target) | Source | Purpose |
|---|---|---|---|
| **Training/fine-tune pool** | ~8,000 imgs | Oxford-IIIT Pet (cat classes, ~2,400), OpenImages V7 `Cat` subset (~6,000 sampled), Kaggle cat breeds | Fine-tune custom detector; embedding fine-tune (optional) |
| **Hard negatives** | ~1,500 imgs | Dogs (Oxford-IIIT dog classes), plush/stuffed cats, cat drawings/anime, cat figurines, humans in cat costumes, cat videos paused on screens | Detector + vision-LLM eval |
| **Field capture set (primary)** | **≥600 real captures, ≥40 distinct cats** | Team + ~10 recruited friends/local volunteers shooting *their own cats and neighborhood cats* with the actual test phones | The only set that matters for G1–G4, G6 |
| **Adversarial spoof set** | ≥200 imgs | Photos of cats displayed on phone screens, laptop monitors, printed photos, TV screens — taken with test phones at realistic angles/light | G3 |
| **Same-cat pairs (dedup)** | ≥150 pairs | Same physical cat, different pose/lighting/day/device; plus ≥150 hard different-cat pairs (same breed/color, e.g., two tabbies) | G5 |
| **Cutout quality set** | 100 imgs | Sampled from field set, including occlusions (cat behind furniture), motion blur, long-hair fur | G7 |

### 4.2 Field capture diversity matrix (mandatory coverage)

Each field capture is tagged with these attributes; the eval harness reports metrics *per slice*, not just aggregate:

- **Lighting:** bright daylight / indoor ambient / low light (evening, no flash) / backlit — target ≥20% low-light
- **Distance:** <1m / 1–3m / 3–5m / >5m — target ≥30% at 3–5m (the incumbent's failure zone)
- **Pose:** facing camera / side / back / sleeping / moving
- **Occlusion:** none / partial (behind furniture, grass, human hand)
- **Coat:** solid / tabby / bicolor / dark cats in dark rooms (worst case — explicitly oversample)
- **Device tier:** see hardware matrix §7
- **Indoor / outdoor**

Recruitment: post in local cat-owner groups + team networks. Incentive: $20 coffee voucher per ~30 usable tagged captures. Written consent + GDPR note (images used for internal eval only; faces blurred/avoided).

### 4.3 Labeling

- **Tool:** [CVAT](https://www.cvat.ai/) (free self-host) or Roboflow free tier for bbox labels; a simple CSV/Google Sheet for image-level tags (real_cat, live_photo, lighting, distance, cat_id).
- **cat_id assignment:** every distinct physical cat gets an ID (`cat_001`…) — required for dedup pairs and for per-cat bias checks (don't let one cooperative cat dominate).
- **Split:** field set is **held out entirely** — never used for fine-tuning. Fine-tune only on the public datasets + hard negatives.
- **Two-person labeling pass on the dedup pairs** — same/different labels are the ground truth for G5 and must be unanimous.

---

## 5. Technical Tracks & Specific Choices

### Track A — On-device detector (Weeks 1–3)

**Baseline (must work Day 1):** MLKit Object Detection, stream mode, via the Flutter `camera` plugin image stream + `google_mlkit_object_detection` (with `google_mlkit_commons` for `InputImage.fromBytes` conversion).
- MLKit's generic detector has **no cat class** — test whether bbox + "any object, animal-ish size/aspect" heuristics suffice as a gate, or whether we need the custom model immediately. **This is a key open question the spike must answer.**

**Candidate 2 — Custom YOLOv8n cat detector (TFLite):**
- Train/fine-tune on public cat datasets (Oxford-IIIT, parts of COCO, plus collected negatives).
- Export: `yolo export model=best.pt format=tflite int8` (INT8 quantization for NNAPI/GPU delegate)
- Runtime: `tflite_flutter` with GPU delegates (Android NNAPI / iOS Core ML / GPU), 320×320 input, score threshold swept 0.25–0.5.
- **Targets:** ≥15fps sustained on Pixel 4a-class hardware; recall per G1 on the field set; report precision too (false boxes on dogs/plush matter for UX trust).

**Liveness heuristics on-device (light version for spike):** ≥5 consecutive detected frames with bbox micro-jitter (parallax/motion) before enabling the capture button; basic moiré check (FFT high-frequency spike on the crop) flagged into device meta. Don't over-build — server layer is the authority.

**Manual fallback UX (test in harness):** after 5s without a stable detection, show "Capture anyway" → routes to server verification with a "we're checking this one" state. **This path must exist and be measured** — it's a load-bearing part of G2 (PRD F1).

### Track B — Server verification (Weeks 2–3)

- **Primary: OpenAI GPT-4.1-mini** vision, structured output (JSON schema):
  `{is_real_cat: bool, is_live_photo: bool, confidence: 0–1, breed_guess, coat_colors[], quality_flags[], reject_reason?}`
  Prompt explicitly instructs: detect bezels, moiré, screen glare, perspective keystone, print texture; classify plush/drawing/costume as not-real.
- **Challenger: Gemini 2.0 Flash** — same prompt, same eval. If it matches accuracy at lower cost/latency, it becomes primary (Blueprint Risk #2 mitigation).
- **Thresholding:** sweep the confidence threshold on the eval set. `< threshold` → "verifying…" state → mock moderation queue (spreadsheet). Measure: what % of *real* field scans need the queue, and does the queue path keep G2 ≥90%?
- **Latency:** measure p50/p95 end-to-end per G6; test image resize pre-upload (1280px long edge, JPEG q80) vs full-res for the cost/latency/accuracy tradeoff.

### Track C — Duplicate detection (Week 3)

- **Layer 1 — pHash:** `imagehash` (Python) or sharp-based pHash in the ingest worker; Hamming distance ≤5 = exact-dup reject (re-uploads, screenshots of own album). Measure latency (<5ms target) and false-reject rate on *different* photos of the same cat (should be near zero — that's Layer 2's job).
- **Layer 2 — embeddings:** **MobileCLIP-S2** (or OpenCLIP `ViT-B-32` if MobileCLIP serving is awkward) via Replicate or a small Modal/fal endpoint; 512-d vectors, cosine similarity.
  - Sweep threshold τ ∈ [0.80, 0.95] on the labeled same/different pairs (§4.1). Report ROC/AUC, pick τ maximizing accuracy per G5, and identify the ambiguity band (e.g., τ±0.03) where MVP should ask the user "merge or keep both?" instead of deciding silently (Blueprint Risk #5 mitigation).
  - Also evaluate **breed/color metadata from Track B as a cheap pre-filter** — does `same breed + same colors + cosine > τ` beat cosine alone on hard tabby-vs-tabby pairs?
- Deliverable: chosen τ, ambiguity band, and a written dedup decision-tree for MVP.

### Track D — Silhouette / cutout generation (Week 3–4)

- **Primary: BiRefNet** on Replicate (`men1scus/birefnet` or current best-listed BG-removal model). **Fallback: `rembg` (U²-Net / ISNet)** — cheaper, worse fur edges; and fal.ai BiRefNet endpoint as a second provider (Blueprint Risk #6).
- Crop to detector bbox (+15% margin) before cutout to reduce cost and improve edges.
- **Eval (G7):** 100-sample blind review, 2 reviewers, rubric: edge cleanliness (fur), no background bleed, no missing limbs/tail/ears, usable on sticker card. Record inter-rater agreement.
- Measure per-image cost and p95 latency; verify "card shows photo first, cutout pops in later" async UX assumption holds (latency ≤60s p95 is acceptable; ≤20s preferred).

### Track E — Evaluation harness (Week 1, used all weeks)

- A single script/harness that: iterates the labeled field set → runs a given pipeline config → outputs per-slice metrics (lighting/distance/device/pose) + aggregate G1–G8 scorecard.
- Store results in a simple SQLite/CSV + a results dashboard (even a markdown table generator is fine). Every experiment run gets an ID, config hash, and scorecard — **no vibes-based decisions at the gate.**

---

## 6. Week-by-Week Schedule

### Week 1 — Data & harness foundation
- Finalize dataset download scripts; assemble training pool + hard negatives (§4.1)
- Recruit field volunteers; distribute capture instructions + consent; begin captures
- Build **Flutter** test app skeleton: camera preview, capture, upload to ingest endpoint (web + mobile targets)
- MLKit baseline running with the `camera` plugin image stream; instrument fps/latency
- Eval harness v0 (runs a folder of labeled images → metrics table)
- **Checkpoint Fri:** harness runs end-to-end on public data; ≥150 field captures in hand

### Week 2 — Detectors & server verification
- Label field set in CVAT (bbox + tags); finalize splits
- Fine-tune YOLOv8n-cat; export TFLite INT8; run on-device on ≥2 test phones
- Stand up Track B: GPT-4.1-mini + Gemini Flash verdicts on field set; first threshold sweep
- Adversarial spoof set captured
- **Checkpoint Fri:** G1 preliminary number (custom model, on-device); G3/G4 preliminary (vision-LLM); cost/scan meter running

### Week 3 — Dedup, cutouts, degrade-chain integration
- pHash layer live; embedding endpoint live; threshold sweep on labeled pairs → G5 number + τ + ambiguity band
- BiRefNet + rembg cutouts on the 100-sample set; blind review scheduled
- Wire the full degrade chain in the test app: on-device → (5s timeout) → manual capture → server verify → mock moderation → verdict
- Run full-pipeline harness on the complete field set → preliminary G2
- **Checkpoint Fri:** preliminary scorecard for all G-metrics; identify the 1–2 weakest

### Week 4 — Harden weakest metrics, finalize gate
- Targeted fixes only (threshold tuning, prompt iteration, bbox-crop for cutouts, hard-negative top-up)
- Complete hardware matrix runs (§7); final G9 fps/thermal numbers
- Final blind cutout review; final full-pipeline runs (3 repetitions for stability)
- Compile cost ledger from actual API usage → G8
- **Write the GO/NO-GO memo:** scorecard vs §2, per-slice weaknesses, MVP implications (chosen detector, chosen vision model, dedup τ + ambiguity-band UX, cutout provider, cost model), and follow-up backlog for Phase 1
- **Checkpoint Fri (gate review):** decision per §2 decision rule

---

## 7. Hardware Test Matrix

| Tier | Device | OS | Why |
|---|---|---|---|
| Mid-range Android (gate device) | Pixel 4a or Galaxy A52 | Android 13/14 | G1/G9 targets are defined against this class (2020–2021 mid-range) |
| Low Android | Galaxy A13 or similar (~$150 class) | Android 13 | Failure-mode discovery; manual-fallback importance |
| Flagship Android | Pixel 8 / Galaxy S23 | Android 14 | Best-case + multi-lens sanity |
| iPhone mid | iPhone 12/13 | iOS 17+ | Core ML delegate path; parity check |
| iPhone recent | iPhone 15 | iOS 17+ | Reference performance |

Minimum bar: full field-set on-device runs on the gate device + one iPhone; the rest get a 50-capture subset + fps/thermal runs.

---

## 8. Cost Estimate (spike itself)

| Item | Est. cost |
|---|---|
| Vision-LLM evals: ~5,000 verdict calls × ~$0.002 avg (both models) | ~$15 |
| Embeddings: ~3,000 calls | ~$10 |
| Cutouts: ~400 images × $0.005–0.02 | ~$10 |
| Replicate/fal/Modal compute misc | ~$25 |
| Volunteer incentives (10 × $20) | $200 |
| Devices (only if we lack a tier; prefer borrowing) | $0–200 |
| **Total** | **~$260–460** |

Note: the spike also *validates* the production per-scan cost model (G8) — the real number to watch is blended cost/successful scan from the metered runs.

---

## 9. Risks & Mitigations (spike-level)

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| Field capture recruitment is slow; <600 captures | Med | High — weakens all G-metrics | Start Week 1 Day 1; team's own cats count; reduce to 400 minimum with wider per-cat coverage; borrow public "cat in home" video stills as supplement (label provenance) |
| YOLOv8n→TFLite export/integration eats a week | Med | Med | EfficientDet-Lite0 via Model Maker is the sanctioned fallback; timebox integration to 3 days, then fall back |
| MLKit-only gate proves useless (no cat class) | High | Low | Expected — that's why the custom model exists; quantify *how* useless as data for the memo |
| Vision-LLM spoof precision <95% | Low-Med | High | Prompt iteration + moiré/metadata features as auxiliary signals; ensemble on-device moiré flag + LLM verdict; if still short → conditional GO with tightened manual-review band |
| Same-cat embeddings can't separate look-alike tabbies | Med | Med | Pre-filter on breed/colors; ambiguity band → user-prompt UX (already the blueprint mitigation); per-cat-ID eval exposes worst slices |
| BiRefNet fur edges disappoint | Med | Low | Cutout is not on the G2 critical path; rembg/fal fallback; worst case MVP ships photo-first cards and improves cutouts in Phase 2 |
| Vision-LLM cost >2× model | Low | Med | Gemini Flash fallback; resize-to-1280px; skip LLM for pHash-rejected and high-confidence on-device passes only if precision allows (measure, don't assume) |
| Team time (solo/small team doing data labeling + 4 tracks) | High | Med | Tracks E and B are mandatory; D can slip a week; cut anything else before cutting data labeling |

---

## 10. Deliverables (end of Week 4)

1. **GO/NO-GO memo** with the G1–G9 scorecard, per-slice breakdowns, and decision per §2
2. Labeled dataset (CVAT export + tags CSV + cat_id registry) — reusable for Phase 2 model v1
3. Eval harness + all run scorecards (config-hash-addressed)
4. Chosen-config record: detector + thresholds, vision model + prompt + threshold, dedup τ + ambiguity band, cutout provider, image-preprocessing params
5. Dedup decision-tree + spoof-rejection decision-tree for MVP implementation
6. Throwaway test app + ingest endpoint (archived, not productized)
7. Follow-up backlog for Phase 1 (e.g., moderation console, real auth, latency hardening)
