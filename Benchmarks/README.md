# Benchmarks for FirebladeECS

Originally seeded by replicating performance tests into a new form leveraging [benchmark](https://github.com/ordo-one/benchmark) [Documentation](https://swiftpackageindex.com/ordo-one/package-benchmark/main/documentation/benchmark).

The iteration-only (`IterOnly...`) and storage (`S2...`) benchmarks run on both storages of `Nexus(storage:)`: the name carries the storage in brackets, for example `IterOnlyForEachReadWrite [archetype]`. The `S2...` benchmarks are ported from the storage spike and cover iteration at several arities, filtered and fragmented families, 100k entities in permuted storage order, random access and structural churn.

Note: These are macro-benchmarks using `package-benchmark`. For micro-benchmarks or performance unit tests, use traits-gated unit test performance benchmarks (`swift test --traits benchmarks`).

To run all the available benchmarks from the repository root:

    make benchmark

or from this directory:

    swift package benchmark --format markdown

For more help on the package-benchmark SwiftPM plugin:

    swift package benchmark help

Creating a local baseline:

    swift package --allow-writing-to-package-directory benchmark baseline update dev
    swift package benchmark baseline list

Comparing to the baseline 'dev'

    swift package benchmark baseline compare dev

For more details on creating and comparing baselines, read [Creating and Comparing Benchmark Baselines](https://swiftpackageindex.com/ordo-one/package-benchmark/main/documentation/benchmark/creatingandcomparingbaselines).
