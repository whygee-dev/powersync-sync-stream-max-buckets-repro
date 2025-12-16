# PowerSync Bucket Limit Reproduction

Minimal reproduction demonstrating PowerSync's bucket counting behavior with sync streams 

## Hypothesis

**Two sync streams + one old-style bucket definition, each resolving to 600 buckets, will hit the default 1000 bucket limit (600 × 3 = 1800)**, because bucket IDs include stream/bucket names and aren't deduplicated across sources.

## Background

PowerSync has a `max_buckets_per_connection` limit (default: 1000). When a client connects, PowerSync counts all buckets from all sources. Each source has a unique bucket ID prefix:
- Old-style: `by_resource["resource-1"]`
- Streams: `stream_a|0["test-user-1","resource-1"]`

Even if all sources resolve to the same underlying data, they produce distinct bucket IDs and count separately.

## Setup

This reproduction creates:
- `user_access` table: 600 entries mapping `test-user-1` to resources (used for bucket parameters)
- `resource` table: 600 resources with actual data (synced to client)
- 1 old-style bucket definition (`by_resource`) using parameters from `user_access`, data from `resource`
- 2 sync streams (`stream_a` and `stream_b`) querying `resource` with subquery on `user_access`
- Each source produces 600 buckets → 1800 total → exceeds 1000 limit

## How to Run

```bash
# Start backend services
docker compose up -d

npm install
npm run dev

# Open http://localhost:5173 in browser
# Click "Connect to PowerSync" to trigger the error
```

## Cleanup

```bash
docker compose down -v
```

## Expected Behavior

When connecting as `test-user-1`:

**Expected Error:**
```
[PSYNC_S2305] Too many parameter query results: 1800 (limit of 1000)
```

**Note:** The same error occurs with any combination exceeding 1000 buckets:
- 1 sync rule + 1 sync stream (600 + 600 = 1200)
- 2 sync streams only (600 + 600 = 1200)

## What the Web App Shows

The web app uses `@powersync/web` SDK and calls `db.getBucketStates()` to display:
- Total bucket count
- Bucket count per stream
- Sample bucket IDs showing the naming pattern

## Root Cause Hypothesis

Bucket IDs include the source name as a prefix. Even though all sources resolve to the same underlying data (same `user_id` + `resource_id` combinations), they generate distinct buckets

There is no cross-source deduplication, so bucket counts are cumulative across all bucket definitions and sync streams.
