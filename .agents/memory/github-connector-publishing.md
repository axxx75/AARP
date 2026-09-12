---
name: GitHub connector publishing
description: Constraints for publishing repository commits through the connected GitHub account.
---

The GitHub connector OAuth session does not authenticate `git push` over the
repository's HTTPS remote in this environment. When publishing through the Git
Data API, preserve blob bytes exactly and retain each tree entry's Git mode.

**Why:** Text normalization changes blob hashes, and treating executable shell
scripts as `100644` changes the tree even when their content is identical.

**How to apply:** Build API blobs from exact Git object bytes, derive modes from
the local tree, compare the generated tree SHA with the local tree SHA, and
update the branch ref only when its current parent still matches.