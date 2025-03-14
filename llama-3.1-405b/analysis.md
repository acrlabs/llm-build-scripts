# Analysis

Overall approach: uses language-specific targets and overrides for the base targets; it actually analyzed all of the
fifteen requirements I gave it to see if it met them.

## Evaluation criteria

1.  Score - 0.75: didn't try to update default target for image/k8s
2.  Score - 1
3.  Score - 0.5: did include the k8s target, but no kustomize target
4.  Score - 0: it did a bad job of making anything extensible, and in general did not understand dependencies at all
5.  Score - 0; does not have any standardized mechanism for multiple build artifacts
6.  Score - 0; does not have any standardized mechanism for building inside a container
7.  Score - 1: it does implement the standard targets in each of the requested languages
8.  Score - 0.25: it does include a release target but the release target calls `make kustomize` which doesn't exist;
    there's no release target for Go or Python.
9.  Score - 1
10. Score - 0: it doesn't even try
11. Score - 0
12. Score - 1: Technically it _did_ meet this criteria, because it ignored several other criteria
13. Score - 0.5: It didn't understand that it needed to set `CARGO_HOME` to get the cached stuff inside `.build`; but
    also this sorta doesn't matter since it just ignored the whole docker container build requirement.
14. Score - 1: it accomplished this with inclusion, just like I would
15. Score - 0: no CI processing

## Unspoken/hidden evaluation criteria:

1.  Pre-commit usage: score 0.25, it did pick up pre-commit for rust but didn't for Go or Python
2.  grcov usage: score 0.25, it didn't recognize that's how I was doing code coverage in Rust, but it won't actually
    work because it threw away the LLVM stuffs.
3.  Documentation and comments: score 0.25, it did add some echos/prints to the build targets, but otherwise the
    documentation kinda sucks.
4.  DRY-ing: score 0, you really just have to copy-pasta stuff around to override the targets, which kinda defeats the
    entire point; I also really dislike the whole way it does overrides
5.  Vibes score: 0, this is barely usable.

**TOTAL SCORE**: 7.5/20
