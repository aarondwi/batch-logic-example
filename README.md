# batch-logic-example

An example for how to operate on typical business logic as a batch.
Primarily useful if you are using [together](https://github.com/aarondwi/together) library.

This repo just includes a few sql scripts, and few automated runner for performance testing.
On my laptop as of this writing, it can achieve 75-85K rps against a single object which is always updated,
with full fsync on postgres.
