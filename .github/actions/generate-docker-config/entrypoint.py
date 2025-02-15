#!/usr/bin/env -S python3 -B

import itertools
import sys
import os

if __name__ == "__main__" :
    dockerTags = sys.argv[1].split(",")
    strategies = sys.argv[2].split(",")
    runId = sys.argv[3]

    isPr = os.getenv("GITHUB_EVENT_NAME") == "pull_request_target"
    strategyPrefix = (runId,) if isPr else ()

    allStrategies = map(
        lambda strategy: "-".join(strategyPrefix + strategy),
        list(itertools.permutations(strategies))
    )

    allTags = list(
        map(
            lambda tag: tag if isPr else tag.replace("-default", ""),
            map(
                lambda values: "-".join(values),
                itertools.product(dockerTags, allStrategies)
            )
        )
    )

    lastStrategy = strategies[-1]
    context = "." if lastStrategy == "default" else f"./prepost_strategies/{lastStrategy}"

    print(f"tags: {','.join(allTags)}")
    print(f"primaryTag: {allTags[0]}")
    print(f"context: {context}")

    if "GITHUB_OUTPUT" in os.environ:
        with open(os.environ["GITHUB_OUTPUT"], "a") as file:
            print(f"tags={','.join(allTags)}", file=file)
            print(f"primaryTag={allTags[0]}", file=file)
            print(f"context={context}", file=file)
