# Section: File/Media

**Trigger tags:** `upload`, `storage`, `cdn`

**Purpose:** File upload, storage, delivery posture. Applies to phases handling user file uploads, image/video processing, CDN delivery, or object storage lifecycles.

## Dimensions (5)

| Dimension            | MVP                  | Δ(M→E) | Enterprise           | Δ(E→S) | Scale               |
|----------------------|----------------------|--------|----------------------|--------|---------------------|
| Upload               | direct-to-app        | L      | presigned S3         | M      | + multipart resume  |
| Virus scan           | none                 | L      | scan on upload       | M      | + async quarantine  |
| CDN                  | direct serve         | M      | CDN cached           | S      | + edge + invalid.   |
| Image pipeline       | original only        | M      | resize on write      | M      | + on-demand cached  |
| Retention            | never delete         | M      | TTL policy           | S      | + lifecycle + hold  |

## Notes

- **Upload:** MVP = multipart form POST direct to app server (app holds file in memory/disk, reuploads to storage). Enterprise = presigned S3/GCS URL (client uploads direct to blob storage). Scale = + multipart upload with resumable-upload protocol.
- **Virus scan:** MVP = trust the user. Enterprise = synchronous AV scan on upload (ClamAV, VirusTotal). Scale = async scan + quarantine bucket + reprocess after clear.
- **CDN:** MVP = app serves static assets directly. Enterprise = CDN-cached (CloudFront, Cloudflare). Scale = + edge logic (image transforms at edge, cache invalidation protocol).
- **Image pipeline:** MVP = original only, no resize/compress. Enterprise = resize on write to N preset sizes. Scale = on-demand resize + CDN caching (responsive images via URL params).
- **Retention:** MVP = files live forever. Enterprise = TTL-based cleanup policy. Scale = + bucket lifecycle rules + legal hold flag for compliance.

## Tier-cap enforcement

- **MVP phase:** presigned URL generation, ClamAV integration, image processing pipelines (sharp, Pillow with variants), CDN invalidation hooks trigger escalation.
- **Enterprise phase:** edge image transform (Cloudflare Images, imgix), legal hold metadata, resumable upload (tus.io) trigger Scale escalation.

## Known drift signals

| Pattern                                      | Tier floor | Finding severity |
|----------------------------------------------|------------|------------------|
| `boto3.generate_presigned_post` / `@aws-sdk/s3-presigned-post` | Enterprise | TIER_DRIFT-LOW |
| ClamAV / VirusTotal scan integration         | Enterprise | TIER_DRIFT-MED   |
| CloudFront / Cloudflare distribution config  | Enterprise | TIER_DRIFT-LOW   |
| tus.io / resumable.js multipart resume       | Scale      | TIER_DRIFT-MED   |
| On-demand resize via URL params (imgix, Cloudflare Images) | Scale | TIER_DRIFT-MED |
| S3 lifecycle rules + legal hold metadata     | Scale      | TIER_DRIFT-MED   |

## Red-line items

- **Virus scan on user uploads.** Any phase accepting user-supplied files for later serving MUST have virus scan at Enterprise minimum. `none` = malware distribution liability. Acceptable only for internal-only upload paths.
- **Direct-to-app uploads don't scale.** MVP direct upload to app is acceptable < 1MB files, < 100 req/day. Anything beyond = app server bottleneck. Flag if upload size or volume exceeds.
