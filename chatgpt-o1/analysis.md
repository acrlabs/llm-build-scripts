# Analysis

Overall approach: uses language-specific targets and overrides for the base targets; it actually analyzed all of the
fifteen requirements I gave it to see if it met them.

## Evaluation criteria

1.  Score - 1
2.  Score - 0.1: does not include a standard command for generating docker images, leaves this up to the sub files
3.  Score - 0.1: does include a `k8s` and `run` target, but it doesn't even try to come up with commands for them.
4.  Score - 0.5: technically this is correct, as users can just override the targets wholesale, but it kinda misses the
    intent of the criteria.
5.  Score - 0; does not have any standardized mechanism for multiple build artifacts
6.  Score - 0; does not have any standardized mechanism for building inside a container
7.  Score - 1: it does implement the standard targets in each of the requested languages
8.  Score - 0.75: it does include a release target but it only actually changes the version number in rust, the other
    two it says you have to do manually; it doesn't `git tag`, I didn't ask it to, but this was a part of the example
    inputs
9.  Score - 1
10. Score - 0.5: I believe it gets Golang cross-compilation right, Rust cross-compilation is a lot harder than just
    specifying a target triple
11. Score - 0
12. Score - 1: Technically it _did_ meet this criteria, because it ignored several other criteria
13. Score - 0.5: It didn't understand that it needed to set `CARGO_HOME` to get the cached stuff inside `.build`; but
    also this sorta doesn't matter since it just ignored the whole docker container build requirement.
14. Score - 1: it accomplished this with variables instead of inclusion, which isn't my preferred solution but it works
15. Score - 1: it did allow for differences in CI versus local behaviour

## Unspoken/hidden evaluation criteria:

1.  Pre-commit usage: score 0, it didn't recognize that I'm using pre-commit for all linting rules
2.  grcov usage: score 0.25, it didn't recognize that's how I was doing code coverage in Rust, but it decided to use
    cargo tarpaulin, which doesn't look as complete as grcov
3.  Documentation and comments: score 1, it did a decent job of including "echo" statements and other comments to say
    what it was doing and how to use it; I think this is the best model I've seen for this.
4.  DRY-ing: score 0, you really just have to copy-pasta stuff around to override the targets, which kinda defeats the
    entire point; I also really dislike the whole way it does overrides
5.  Vibes score: 0.5, this initially looks really nice; I like the way it splits up into files, and it does a good job
    of making you feel like it understood, but it still misses many key criteria and probably requires a few hours of
    work to get functional in general

**TOTAL SCORE**: 10.2/20
