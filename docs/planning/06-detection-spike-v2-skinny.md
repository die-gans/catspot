# Catspot — Spike Plan v2: Detection & AI Pipeline (Skinny, 2 Weeks)

> **Status:** Proposed · **Date:** August 4, 2026  
> **Supersedes:** `docs/planning/03-detection-spike-plan.md` (v1 is preserved for the deferred phases: custom training, dedup, cutouts, Android).  
> **Owner:** Engineering · **Duration:** 2 weeks · **Type:** Time-boxed technical spike

---

## 1. Why This Spike Exists

Founder direction: **no custom model training, no duplicate detection/embeddings, no cutouts — yet.** The only question that matters right now is whether a first-time user can point the phone at a real cat, get it confirmed, and have the photo saved. Everything else is a later-phase problem.

**Spike question, one sentence:** *Can a first-time user point the phone at a real cat, get it confirmed, and have the photo saved — "it just works"?*

**Out of scope for this spike:** custom YOLO/TFLite training, duplicate detection, silhouette cutouts, Android, adversarial spoof hardening beyond a light `is_live_photo` check, economy/social/map.

---

## 2. Architecture Under Test

```
[Flutter app: new scan debug screen + camera preview]
   └── iOS platform channel → Apple Vision VNRecognizeAnimalsRequest
        └── returns {label: "Cat", confidence, boundingBox}
   └── on stable cat detection → capture full-resolution JPEG
        │
        ▼
[Convex action]
   1. (optional) Resize/quality pre-check
   2. Call Firebase AI Logic → Gemini 2.5 Flash (image + prompt)
   3. Parse structured verdict JSON
   4. If approved: get R2 presigned PUT URL → client uploads original JPEG
   5. Write record to Convex (scanId, userId, r2Key, verdict, metadata)
   6. Return result to app
```

**Structured verdict from Gemini:**

```json
{
  "is_real_cat": true,
  "is_live_photo": true,
  "confidence": 0.94,
  "reject_reason": null
}
```

Optional fields may include `breed_guess`, `coat_colors[]`, `quality_flags[]` — but they are not gating.

---

## 3. Explicitly Deferred

| Item | Reason |
|---|---|
| Custom model training | Only if Apple Vision fails G1; use v1 plan as fallback backlog. |
| Duplicate detection / embeddings | Uniqueness/rarity is not part of the "first cat saved" promise. |
| Cutouts / silhouette generation | Cards can use the full photo first; cutouts are a polish layer. |
| Deep spoof adversarial hardening | Light `is_live_photo` check only; screen/print rejection is a follow-up spike. |
| Android on-device detection | iOS-first; Android will reuse server verification later and can adopt MLKit/Custom at that time. |

---

## 4. Success Criteria (the GO/NO-GO Gate)

All metrics measured on the **held-out field test set** (§5), not public warmup images.

| # | Gate | Metric | GO threshold | Measured how |
|---|---|---|---|---|
| G1 | Vision cat detection recall | ≥85% of real-cat frames get a "Cat" bbox | Frame-level eval harness on labeled clips |
| G2 | End-to-end first-scan success | ≥90% of real-cat scans result in a saved photo | Full pipeline over field test set |
| G3 | Gemini verdict latency | p95 ≤30s from upload start to verdict | Instrumented calls in the eval harness |
| G4 | Cost per scan | ≤$0.01 per Gemini verdict | Actual token/image counts × model price |
| G5 | TestFlight real-device pipeline | Capture → saved pipeline works on Dan's iPhone via TestFlight | Manual smoke test on device |

**Decision rule (end of Week 2):**

- **GO** — G1–G5 all met. Proceed to build the MVP scan loop on this stack.
- **CONDITIONAL GO** — G2 met but G1 missed by ≤10 points: document the fallback (custom model / server-primary detection) and proceed with a written risk note.
- **NO-GO** — G2 missed, or G4/G5 blown: the core "point → confirm → save" promise is not yet buildable with this stack. Revisit detector strategy before coding the MVP.

---

## 5. Dataset (Skinny)

| Set | Size | Source | Purpose |
|---|---|---|---|
| Warm-up cat images | ~50–100 | Public datasets (Oxford-IIIT Pet cat classes, unsplash/COCO cat samples) | Sanity-check Vision + Gemini integration before real captures |
| Field capture set | **~100–200 real captures** | Dan + partner + friends' cats | Primary gating set |

**Coverage goals for the field set:**

- Lighting: bright daylight, indoor ambient, low light, backlit.
- Distance: <1m, 1–3m, 3–5m (intentionally include the incumbent's failure zone).
- Pose: front, side, back, sleeping, moving.
- Occlusion: none / partial.
- Coat: solid, tabby, bicolor, dark cats in dark rooms.

**No paid recruitment for this spike.** If the field set is smaller than 100 captures, widen the capture window by one day before changing scope.

---

## 6. Week-by-Week Schedule

### Week 1 — Scan screen + Vision detection + upload path

- Create a new scan debug screen in the Flutter app (behind a dev flag).
- Implement the iOS platform channel for `VNRecognizeAnimalsRequest`:
  - Run on `camera` plugin image stream or captured still.
  - Return normalized `Cat` bbox + confidence to Dart.
- Add stable-detection gating: require ≥3 consecutive frames with a cat bbox before enabling capture.
- Wire capture → JPEG → Convex action that returns a presigned R2 PUT URL.
- Client uploads the JPEG directly to R2, then reports success back to Convex.
- **Checkpoint Fri:** a real cat in the frame enables the shutter; tapping save puts the original in R2 with a Convex record.

### Week 2 — Gemini verification + gates measured on field set + GO/NO-GO memo

- Add Gemini (Firebase AI Logic) call inside the Convex action, with structured JSON verdict.
- Prompt explicitly asks for real cat vs. photo-of-screen/print/plush and for liveness cues.
- Instrument latency and token usage.
- Run the field set through the pipeline; compute G1–G4.
- Run the TestFlight smoke test on Dan's iPhone (G5).
- **Write the GO/NO-GO memo:** scorecard vs. §4, per-slice weaknesses, and follow-up backlog for MVP.
- **Checkpoint Fri (gate review):** decision per §4.

---

## 7. Research Findings

### 7.1 Apple Vision animal detection

- **`VNRecognizeAnimalsRequest`** recognizes animals in an image and is available on iOS 13.0+ [^1].
- Revision 1 supports only two identifiers: **Cat and Dog** [^2][^3].
- Results are returned as `[VNRecognizedObjectObservation]`, which exposes a `boundingBox` and `labels` (each with `identifier` and `confidence`) [^1][^4].
- There is no built-in liveness / screen-spoof check; it is purely a cat/dog detector.
- Flutter access: there is no first-party Flutter plugin that exposes this request. The closest community umbrella is `apple_vision` (v0.1.0, July 2026), but it covers face/object/pose APIs and is not yet proven for animal recognition [^5]. The recommended approach for this spike is a **thin MethodChannel** to `VNRecognizeAnimalsRequest` — only two classes, minimal Swift code.

### 7.2 Firebase AI Logic (Gemini) for image understanding

- Firebase AI Logic provides client SDKs (including Flutter/Dart) and a proxy to the Gemini API [^6].
- **Structured JSON output is supported** via `responseMIMEType: 'application/json'` and a `responseSchema` in `GenerationConfig`; the Flutter SDK example is documented [^7].
- **App Check gating is supported** — the docs explicitly recommend Firebase App Check to protect the Gemini API from abuse by unauthorized clients, and the proxy keeps the API key server-side [^6][^8].
- **Auth gating:** Firebase Auth is already wired in Catspot; the Convex action can require a valid Firebase ID token. App Check provides app attestation, not user identity — both are useful.
- **Pricing:** Using Firebase AI Logic itself is free of charge; you pay for the underlying Gemini API usage [^9]. For the chosen model class (Gemini 2.5 Flash), paid-tier pricing is roughly **$0.30 per 1M input tokens** and **$2.50 per 1M output tokens** [^10]. A 1024×1024 image is billed at approximately 1,290 tokens, so a single verdict is expected to cost **~$0.0006–$0.001** — well under the $0.01 gate. A free tier exists but has model/rate limits; production should use the Blaze plan.

### 7.3 Flutter iOS → R2 via Convex

- The standard pattern is **presigned URL**: a Convex action generates an R2 presigned PUT URL (e.g. via `@convex-dev/r2` or a small S3-compatible helper), the Flutter client `PUT`s the JPEG directly to R2, then calls another action to sync metadata [^11][^12].
- This avoids streaming image bytes through Convex and is cheaper/faster for mobile uploads.

---

## 8. Red Flags Surfaced

1. **Apple Vision animal detector is binary (cat/dog only) and may miss cats in hard conditions.** It is known to work best on reasonably centered, well-lit cats; it can miss small/distant cats, heavy occlusion, backlit silhouettes, and low-light frames [^3][^4]. G1 must be measured on real captures, not just public images.
2. **No built-in liveness / anti-spoof in Vision.** The entire `is_live_photo` signal has to come from Gemini + light heuristics (e.g., moiré/screen reflections). This is acceptable for the spike but will need hardening later.
3. **Flutter Apple Vision ecosystem is immature.** `apple_vision` is brand new (v0.1.0); relying on it for animal recognition is risky. A custom MethodChannel is safer and keeps the spike small.
4. **Gemini model churn.** 2.5 Flash is currently live but Google has been sunsetting older Flash models quickly; we should pin to a stable model string and watch the Firebase AI Logic model guidance. The cost gate is comfortable even on newer Flash-class models.
5. **Free tier is not for production.** Production verification calls require a Blaze plan / Cloud Billing account. The project should be upgraded before TestFlight users hit the scan path.
6. **R2 presigned URLs need CORS and token hygiene.** The bucket must allow `PUT` from the app origin with `Content-Type: image/jpeg`, and R2 credentials must stay in Convex secrets, never in the client [^12].

---

## 9. Deliverables (end of Week 2)

1. **GO/NO-GO memo** with G1–G5 scorecard and decision per §4.
2. Throwaway scan debug screen + iOS platform channel code.
3. Convex action(s) for R2 presigned upload + Gemini verdict.
4. Field-set capture log and per-slice metrics.
5. Follow-up backlog for MVP (e.g., Android detection, spoof hardening, cutouts, dedup).

---

## References

[^1]: Apple Developer, *VNRecognizeAnimalsRequest* — https://developer.apple.com/documentation/vision/vnrecognizeanimalsrequest
[^2]: Kamil Tustanowski, *Animals detection using the Vision framework* — https://medium.com/@kamil.tustanowski/animals-detection-using-the-vision-framework-1a755fbc639f
[^3]: AppCoda, *Working with Text and Image Recognition in iOS* — https://www.appcoda.com/animal-recognition-vision-framework/
[^4]: zhgchg.li, *iOS Vision Framework — RecognizeAnimalsRequest example* — https://en.zhgchg.li/posts/kkday-tech-blog/ios-vision-framework-explore-swift-api-enhancements-from-wwdc-24-session-755509180ca8/
[^5]: pub.dev, *apple_vision* — https://pub.dev/packages/apple_vision
[^6]: Firebase, *Gemini API using Firebase AI Logic* — https://firebase.google.com/docs/ai-logic
[^7]: Firebase, *Generate structured output (JSON and enums) using the Gemini API* — https://firebase.google.com/docs/ai-logic/generate-structured-output
[^8]: Firebase, *Enable App Check enforcement* — https://firebase.google.com/docs/app-check/enable-enforcement
[^9]: Firebase, *Understand Firebase AI Logic pricing* — https://firebase.google.com/docs/ai-logic/pricing
[^10]: Google AI for Developers, *Gemini Developer API pricing* — https://ai.google.dev/gemini-api/docs/pricing
[^11]: Convex, *Cloudflare R2 component* — https://www.convex.dev/components/cloudflare-r2
[^12]: Cloudflare, *Presigned URLs* — https://developers.cloudflare.com/r2/api/s3/presigned-urls/
