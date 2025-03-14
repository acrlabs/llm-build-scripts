# Analysis

Overall approach: uses double-colon targets, but splits things out into a number of files that can be optionally
included.

## Evaluation criteria

1.  Score - 1
2.  Score - 0.1: does not include a standard command for generating docker images, leaves this up to the sub files
3.  Score - 0.5: does include a `k8s` and `run` target, but it leaves the implementation up to the project sub-files; it
    assumes I'm using helm, which I'm not, but it's standard and not a bad assumption, so whatever.
4.  Score - 0.75: using the double-colon lets users add extra commands, but you can't customize the dependencies of the
    targets with this solution.
5.  Score - 0; does not have any standardized mechanism for multiple build artifacts
6.  Score - 0; does not have any standardized mechanism for building inside a container
7.  Score - 1: it does implement the standard targets in each of the requested languages
8.  Score - 0.5: it does include a release target but it doesn't bump the version in golang (it does in Rust, and it
    includes a comment in python but no echo).  it doesn't `git tag`, I didn't ask it to, but this was a part of the
    example inputs.
9.  Score - 1
10. Score - 0.5: I believe it gets Golang cross-compilation right, Rust cross-compilation is a lot harder than just
    specifying a target triple
11. Score - 0
12. Score - 1: Technically it _did_ meet this criteria, because it ignored several other criteria
13. Score - 0.5: It didn't understand that it needed to set `CARGO_HOME` to get the cached stuff inside `.build`; but
    also this sorta doesn't matter since it just ignored the whole docker container build requirement.
14. Score - 1: this is how I solved the problem
15. Score - 1: it did allow for differences in CI versus local behaviour

## Unspoken/hidden evaluation criteria:

1.  Pre-commit usage: score 0, it didn't recognize that I'm using pre-commit for all linting rules
2.  grcov usage: score 0.25, it didn't recognize that's how I was doing code coverage in Rust, but it decided to use
    cargo tarpaulin, which doesn't look as complete as grcov
3.  Documentation and comments: score 0, it barely included any useful documentation
4.  DRY-ing: score 0.25, using the double-colon syntax lets you DRY some things but it still could have done more.
5.  Vibes score: 0.1, I like the solution _approach_ better than o3-mini but it still ignored a ton of requirements,
    and would still require a few hours of work to get functional.

**TOTAL SCORE**: 9.45/20
