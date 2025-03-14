# Analysis

Overall approach: uses underscore targets which can be overridden in sub-makefiles

## Evaluation criteria

1.  Score - 0.9: supports all the build targets but gets confused about the default and verify targets
2.  Score - 0.1: does not include a standard command for generating docker images, leaves this up to the sub files
3.  Score - 0.5: does include a `k8s` and `run` target, but it makes up the existence of a generate-manifests script; I
    didn't tell it I had a script to generate manifests, but I do, so this is fine-ish.  It doesn't track the docker
    image tag in any way.  It leaves the specific generate command up to the sub-files.
4.  Score - 0.5: technically this is correct, as users can just override the targets wholesale, but it kinda misses the
    intent of the criteria.
5.  Score - 0; does not have any standardized mechanism for multiple build artifacts
6.  Score - 0; does not have any standardized mechanism for building inside a container
7.  Score - 1: it does implement the standard targets in each of the requested languages
8.  Score - 0.75: it does include a release target but it hilariously just asks you to go update the version on its own;
    it doesn't `git tag`, I didn't ask it to, but this was a part of the example inputs
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
2.  grcov usage: score 0, it didn't recognize that's how I was doing code coverage in Rust, it just made up "insert
    coverage here"
3.  Documentation and comments: score 0.8, it did a decent job of including "echo" statements and other comments to say
    what it was doing and how to use it
4.  DRY-ing: score 0, you really just have to copy-pasta stuff around to override the targets, which kinda defeats the
    entire point.
5.  Vibes score: 0, this mostly misses the point of the exercise, ignores a bunch of key requirements, and probably
    requires a few hours of work to get functional in general

**TOTAL SCORE**: 9.3/20
