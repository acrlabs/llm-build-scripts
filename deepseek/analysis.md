# Analysis

Overall approach: uses language-specific targets and overrides for the base targets; it actually analyzed all of the
fifteen requirements I gave it to see if it met them.

## Evaluation criteria

1.  Score - 0.75: it doesn't update the default target correctly.
2.  Score - 1: It read and understood the docker command that I gave in the examples, and made it a little more flexible
3.  Score - 0.4: It didn't try to guess about how the k8s manifests were getting generated, and it dropped the kustomize
    target; it also kept the `pre-k8s` target in my example, but doesn't set this in the k8s.mk file.
4.  Score - 1: Each target has an explicit pre, post, and run step, which can be overridden or use the defaults.
5.  Score - 0.5: the docker and k8s files (and the rust file) uses the ARTIFACTS variable, but this isn't replicated in
    the golang/python/generic build files; also it's annoying to have to manually specify the `DOCKER_BUILD_ARTIFACTS`
    and the `ARTIFACTS_WITH_IMAGES`, though I suppose in principle these could be different.
6.  Score - 0.5: Only rust has build-in-docker requirements
7.  Score - 0.75: it does implement the standard targets in each of the requested languages; it doesn't implement `lint`
    for any languages.
8.  Score - 1: it actually bumps the tag on everything, which I think is the only one I've seen to do this
9.  Score - 1
10. Score - 0.75: I believe it gets Golang cross-compilation right, I think the Rust cross-compilation is close
11. Score - 1: I think it got this right for Rust; go doesn't build in a container so it technically did this correct
12. Score - 0.5:  These targets are a little wonky
13. Score - 1: It looks like it did this correctly for rust, and go doesn't build in a container
14. Score - 1: it accomplished this with variables instead of inclusion, which isn't my preferred solution but it works
15. Score - 0.5: there is one reference to the IN_CI variable but it's not really complete or well-documented

## Unspoken/hidden evaluation criteria:

1.  Pre-commit usage: score 0, it didn't define any lint rules or recognize that I'm using pre-commit
2.  grcov usage: score 0, I don't think it actually recognized the requirements for coverage in rust
3.  Documentation and comments: score 0, it didn't really document or comment anything
4.  DRY-ing: score 0.75, I don't hate this version, it looks almost the most extensible of all of them
5.  Vibes score: 0.5, this does a "pretty good job" but still misses some things.  I think with some massaging I could
    get it into a spot that I was happy with.

**TOTAL SCORE**: 12.9/20
