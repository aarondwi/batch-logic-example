# batch-logic-example

An example for how to operate on typical business logic as a batch.
Primarily useful if you are using [together](https://github.com/aarondwi/together) library.

This repo just includes a few sql scripts, and few automated runner for performance testing.
On my laptop as of this writing, it can achieve 75-85K rps against a single object which is always updated,
with full fsync on postgres.

I've tried a few way beside this version, such as:

1. Doing call one-by-one, with fsync on each
2. Doing a full block using `SELECT ... FOR UPDATE`, and then do the logic
3. Do entire logic as batch on client

And I found this way to be the fastest and most stable, for maximizing throughput.
