# Benchmarks for FirebladeECS

Originally seeded by replicating performance tests into a new form leveraging [package-benchmark](https://swiftpackageindex.com/ordo-one/package-benchmark/) [Documentation](https://swiftpackageindex.com/ordo-one/package-benchmark/main/documentation/benchmark).

To run the all the available benchmarks:

    swift package benchmark
    swift package benchmark --format markdown

For more help on the package-benchmark SwiftPM plugin:

    swift package benchmark help

Creating a local baseline:

    swift package --allow-writing-to-package-directory benchmark baseline update dev
    swift package benchmark baseline list
    
Comparing to a the baseline 'alpha'

    swift package benchmark baseline compare dev

For more details on creating and comparing baselines, read [Creating and Comparing Benchmark Baselines](https://swiftpackageindex.com/ordo-one/package-benchmark/main/documentation/benchmark/creatingandcomparingbaselines).
