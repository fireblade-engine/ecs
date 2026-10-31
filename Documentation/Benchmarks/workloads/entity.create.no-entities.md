# `entity.create.no-entities`

[Back to the report](../REPORT.md) · [Glossary](../REPORT.md#glossary). FirebladeECS benchmark comparison.

- Parity (1.4.3, main): adapted: nexus teardown is outside the timed region; upstream times registry teardown; per-iteration untimed setup counts against the package's 0.5 s wall budget, so measured time and sample count are below upstream's 0.5 s of measured time, especially at large scales

`median`, `CI low`, `CI high`, `replicates` and `iterations` are defined in the [report](../REPORT.md). `mean` is the median over replicates of each replicate's mean per iteration; it is descriptive (upstream parity), not an inference input. Percentile columns are the median over replicates of each replicate's percentile.

## Time (wall clock) (smaller is better)

### Time (wall clock): Entity counts up to 1,024

<table>
<thead>
<tr><th rowspan="3">Entities</th><th colspan="6">1.4.3 (class) - baseline</th><th colspan="24">main (value)</th></tr>
<tr><th colspan="6">default</th><th colspan="12">archetype</th><th colspan="12">sparseSet</th></tr>
<tr><th>median (ns)</th><th>CI low (ns)</th><th>CI high (ns)</th><th>mean (ns)</th><th>replicates</th><th>iterations</th><th>median (ns)</th><th>CI low (ns)</th><th>CI high (ns)</th><th>mean (ns)</th><th>replicates</th><th>iterations</th><th>speed (×)</th><th>CI low (×)</th><th>CI high (×)</th><th>change (%)</th><th>q</th><th>verdict</th><th>median (ns)</th><th>CI low (ns)</th><th>CI high (ns)</th><th>mean (ns)</th><th>replicates</th><th>iterations</th><th>speed (×)</th><th>CI low (×)</th><th>CI high (×)</th><th>change (%)</th><th>q</th><th>verdict</th></tr>
</thead>
<tbody>
<tr><td align="right">0</td><td align="right">42</td><td align="right">42</td><td align="right">42</td><td align="right">43.0</td><td align="right">10</td><td align="right">116,416</td><td align="right">42</td><td align="right">42</td><td align="right">42</td><td align="right">43.2</td><td align="right">10</td><td align="right">97,523</td><td align="right">1.00</td><td align="right">1.00</td><td align="right">1.00</td><td align="right">0</td><td align="right">1.000</td><td align="right">equivalent</td><td align="right">42</td><td align="right">42</td><td align="right">42</td><td align="right">42.5</td><td align="right">10</td><td align="right">111,105</td><td align="right">1.00</td><td align="right">1.00</td><td align="right">1.00</td><td align="right">0</td><td align="right">1.000</td><td align="right">equivalent</td></tr>
</tbody>
</table>

### Percentiles, entity counts up to 1,024

<table>
<thead>
<tr><th rowspan="3">Entities</th><th colspan="7">1.4.3 (class) - baseline</th><th colspan="14">main (value)</th></tr>
<tr><th colspan="7">default</th><th colspan="7">archetype</th><th colspan="7">sparseSet</th></tr>
<tr><th>p0 (ns)</th><th>p25 (ns)</th><th>p50 (ns)</th><th>p75 (ns)</th><th>p90 (ns)</th><th>p99 (ns)</th><th>p100 (μs)</th><th>p0 (ns)</th><th>p25 (ns)</th><th>p50 (ns)</th><th>p75 (ns)</th><th>p90 (ns)</th><th>p99 (ns)</th><th>p100 (μs)</th><th>p0 (ns)</th><th>p25 (ns)</th><th>p50 (ns)</th><th>p75 (ns)</th><th>p90 (ns)</th><th>p99 (ns)</th><th>p100 (μs)</th></tr>
</thead>
<tbody>
<tr><td align="right">0</td><td align="right">41</td><td align="right">41</td><td align="right">42</td><td align="right">42</td><td align="right">42</td><td align="right">83</td><td align="right">12.1</td><td align="right">41</td><td align="right">41</td><td align="right">42</td><td align="right">42</td><td align="right">42</td><td align="right">83.5</td><td align="right">9.06</td><td align="right">41</td><td align="right">41</td><td align="right">42</td><td align="right">42</td><td align="right">42</td><td align="right">62.5</td><td align="right">3.54</td></tr>
</tbody>
</table>

## Time (total CPU) (smaller is better)

### Time (total CPU): Entity counts up to 1,024

<table>
<thead>
<tr><th rowspan="3">Entities</th><th colspan="6">1.4.3 (class) - baseline</th><th colspan="12">main (value)</th></tr>
<tr><th colspan="6">default</th><th colspan="6">archetype</th><th colspan="6">sparseSet</th></tr>
<tr><th>median (ns)</th><th>CI low (ns)</th><th>CI high (ns)</th><th>mean (ns)</th><th>replicates</th><th>iterations</th><th>median (ns)</th><th>CI low (ns)</th><th>CI high (ns)</th><th>mean (ns)</th><th>replicates</th><th>iterations</th><th>median (ns)</th><th>CI low (ns)</th><th>CI high (ns)</th><th>mean (ns)</th><th>replicates</th><th>iterations</th></tr>
</thead>
<tbody>
<tr><td align="right">0</td><td align="right">688</td><td align="right">667</td><td align="right">709</td><td align="right">705</td><td align="right">10</td><td align="right">123,076</td><td align="right">708</td><td align="right">667</td><td align="right">750</td><td align="right">713</td><td align="right">10</td><td align="right">102,316</td><td align="right">730</td><td align="right">708</td><td align="right">750</td><td align="right">733</td><td align="right">10</td><td align="right">119,161</td></tr>
</tbody>
</table>

### Percentiles, entity counts up to 1,024

<table>
<thead>
<tr><th rowspan="3">Entities</th><th colspan="7">1.4.3 (class) - baseline</th><th colspan="14">main (value)</th></tr>
<tr><th colspan="7">default</th><th colspan="7">archetype</th><th colspan="7">sparseSet</th></tr>
<tr><th>p0 (ns)</th><th>p25 (ns)</th><th>p50 (ns)</th><th>p75 (ns)</th><th>p90 (ns)</th><th>p99 (ns)</th><th>p100 (μs)</th><th>p0 (ns)</th><th>p25 (ns)</th><th>p50 (ns)</th><th>p75 (ns)</th><th>p90 (ns)</th><th>p99 (ns)</th><th>p100 (μs)</th><th>p0 (ns)</th><th>p25 (ns)</th><th>p50 (ns)</th><th>p75 (ns)</th><th>p90 (ns)</th><th>p99 (ns)</th><th>p100 (μs)</th></tr>
</thead>
<tbody>
<tr><td align="right">0</td><td align="right">583</td><td align="right">667</td><td align="right">688</td><td align="right">709</td><td align="right">751</td><td align="right">875</td><td align="right">20.5</td><td align="right">583</td><td align="right">667</td><td align="right">708</td><td align="right">729</td><td align="right">751</td><td align="right">875</td><td align="right">17.9</td><td align="right">584</td><td align="right">708</td><td align="right">730</td><td align="right">751</td><td align="right">772</td><td align="right">896</td><td align="right">16.0</td></tr>
</tbody>
</table>

## Throughput (# / s) (larger is better)

### Throughput (# / s): Entity counts up to 1,024

<table>
<thead>
<tr><th rowspan="3">Entities</th><th colspan="6">1.4.3 (class) - baseline</th><th colspan="12">main (value)</th></tr>
<tr><th colspan="6">default</th><th colspan="6">archetype</th><th colspan="6">sparseSet</th></tr>
<tr><th>median (Mops/s)</th><th>CI low (Mops/s)</th><th>CI high (Mops/s)</th><th>mean (Mops/s)</th><th>replicates</th><th>iterations</th><th>median (Mops/s)</th><th>CI low (Mops/s)</th><th>CI high (Mops/s)</th><th>mean (Mops/s)</th><th>replicates</th><th>iterations</th><th>median (Mops/s)</th><th>CI low (Mops/s)</th><th>CI high (Mops/s)</th><th>mean (Mops/s)</th><th>replicates</th><th>iterations</th></tr>
</thead>
<tbody>
<tr><td align="right">0</td><td align="right">23.8</td><td align="right">23.8</td><td align="right">23.8</td><td align="right">23.8</td><td align="right">10</td><td align="right">116,416</td><td align="right">23.8</td><td align="right">23.8</td><td align="right">23.8</td><td align="right">23.7</td><td align="right">10</td><td align="right">97,523</td><td align="right">23.8</td><td align="right">23.8</td><td align="right">23.8</td><td align="right">23.9</td><td align="right">10</td><td align="right">111,105</td></tr>
</tbody>
</table>

### Percentiles, entity counts up to 1,024

<table>
<thead>
<tr><th rowspan="3">Entities</th><th colspan="7">1.4.3 (class) - baseline</th><th colspan="14">main (value)</th></tr>
<tr><th colspan="7">default</th><th colspan="7">archetype</th><th colspan="7">sparseSet</th></tr>
<tr><th>p0 (Mops/s)</th><th>p25 (Mops/s)</th><th>p50 (Mops/s)</th><th>p75 (Mops/s)</th><th>p90 (Mops/s)</th><th>p99 (Mops/s)</th><th>p100 (Kops/s)</th><th>p0 (Mops/s)</th><th>p25 (Mops/s)</th><th>p50 (Mops/s)</th><th>p75 (Mops/s)</th><th>p90 (Mops/s)</th><th>p99 (Mops/s)</th><th>p100 (Kops/s)</th><th>p0 (Mops/s)</th><th>p25 (Mops/s)</th><th>p50 (Mops/s)</th><th>p75 (Mops/s)</th><th>p90 (Mops/s)</th><th>p99 (Mops/s)</th><th>p100 (Kops/s)</th></tr>
</thead>
<tbody>
<tr><td align="right">0</td><td align="right">24.4</td><td align="right">24.4</td><td align="right">23.8</td><td align="right">23.8</td><td align="right">23.8</td><td align="right">12.1</td><td align="right">89.0</td><td align="right">24.4</td><td align="right">24.4</td><td align="right">23.8</td><td align="right">23.8</td><td align="right">23.8</td><td align="right">12.0</td><td align="right">159</td><td align="right">24.4</td><td align="right">24.4</td><td align="right">23.8</td><td align="right">23.8</td><td align="right">23.8</td><td align="right">17.9</td><td align="right">323</td></tr>
</tbody>
</table>

## Memory (resident peak) (smaller is better)

### Memory (resident peak): Entity counts up to 1,024

<table>
<thead>
<tr><th rowspan="3">Entities</th><th colspan="6">1.4.3 (class) - baseline</th><th colspan="12">main (value)</th></tr>
<tr><th colspan="6">default</th><th colspan="6">archetype</th><th colspan="6">sparseSet</th></tr>
<tr><th>median (MB)</th><th>CI low (MB)</th><th>CI high (MB)</th><th>mean (MB)</th><th>replicates</th><th>iterations</th><th>median (MB)</th><th>CI low (MB)</th><th>CI high (MB)</th><th>mean (MB)</th><th>replicates</th><th>iterations</th><th>median (MB)</th><th>CI low (MB)</th><th>CI high (MB)</th><th>mean (MB)</th><th>replicates</th><th>iterations</th></tr>
</thead>
<tbody>
<tr><td align="right">0</td><td align="right">10.5</td><td align="right">10.5</td><td align="right">10.5</td><td align="right">10.5</td><td align="right">10</td><td align="right">123,076</td><td align="right">10.9</td><td align="right">10.9</td><td align="right">11.0</td><td align="right">10.9</td><td align="right">10</td><td align="right">102,316</td><td align="right">10.8</td><td align="right">10.8</td><td align="right">10.9</td><td align="right">10.8</td><td align="right">10</td><td align="right">119,161</td></tr>
</tbody>
</table>

### Percentiles, entity counts up to 1,024

<table>
<thead>
<tr><th rowspan="3">Entities</th><th colspan="7">1.4.3 (class) - baseline</th><th colspan="14">main (value)</th></tr>
<tr><th colspan="7">default</th><th colspan="7">archetype</th><th colspan="7">sparseSet</th></tr>
<tr><th>p0 (MB)</th><th>p25 (MB)</th><th>p50 (MB)</th><th>p75 (MB)</th><th>p90 (MB)</th><th>p99 (MB)</th><th>p100 (MB)</th><th>p0 (MB)</th><th>p25 (MB)</th><th>p50 (MB)</th><th>p75 (MB)</th><th>p90 (MB)</th><th>p99 (MB)</th><th>p100 (MB)</th><th>p0 (MB)</th><th>p25 (MB)</th><th>p50 (MB)</th><th>p75 (MB)</th><th>p90 (MB)</th><th>p99 (MB)</th><th>p100 (MB)</th></tr>
</thead>
<tbody>
<tr><td align="right">0</td><td align="right">10.0</td><td align="right">10.5</td><td align="right">10.5</td><td align="right">10.5</td><td align="right">10.5</td><td align="right">10.5</td><td align="right">10.5</td><td align="right">10.3</td><td align="right">10.9</td><td align="right">10.9</td><td align="right">10.9</td><td align="right">10.9</td><td align="right">10.9</td><td align="right">10.9</td><td align="right">10.3</td><td align="right">10.8</td><td align="right">10.8</td><td align="right">10.8</td><td align="right">10.8</td><td align="right">10.8</td><td align="right">10.8</td></tr>
</tbody>
</table>

## Malloc (total) (smaller is better)

### Malloc (total): Entity counts up to 1,024

<table>
<thead>
<tr><th rowspan="3">Entities</th><th colspan="6">1.4.3 (class) - baseline</th><th colspan="12">main (value)</th></tr>
<tr><th colspan="6">default</th><th colspan="6">archetype</th><th colspan="6">sparseSet</th></tr>
<tr><th>median</th><th>CI low</th><th>CI high</th><th>mean</th><th>replicates</th><th>iterations</th><th>median</th><th>CI low</th><th>CI high</th><th>mean</th><th>replicates</th><th>iterations</th><th>median</th><th>CI low</th><th>CI high</th><th>mean</th><th>replicates</th><th>iterations</th></tr>
</thead>
<tbody>
<tr><td align="right">0</td><td align="right">0</td><td align="right">0</td><td align="right">0</td><td align="right">0</td><td align="right">10</td><td align="right">123,076</td><td align="right">0</td><td align="right">0</td><td align="right">0</td><td align="right">0</td><td align="right">10</td><td align="right">102,316</td><td align="right">0</td><td align="right">0</td><td align="right">0</td><td align="right">0</td><td align="right">10</td><td align="right">119,161</td></tr>
</tbody>
</table>

### Percentiles, entity counts up to 1,024

<table>
<thead>
<tr><th rowspan="3">Entities</th><th colspan="7">1.4.3 (class) - baseline</th><th colspan="14">main (value)</th></tr>
<tr><th colspan="7">default</th><th colspan="7">archetype</th><th colspan="7">sparseSet</th></tr>
<tr><th>p0</th><th>p25</th><th>p50</th><th>p75</th><th>p90</th><th>p99</th><th>p100</th><th>p0</th><th>p25</th><th>p50</th><th>p75</th><th>p90</th><th>p99</th><th>p100</th><th>p0</th><th>p25</th><th>p50</th><th>p75</th><th>p90</th><th>p99</th><th>p100</th></tr>
</thead>
<tbody>
<tr><td align="right">0</td><td align="right">0</td><td align="right">0</td><td align="right">0</td><td align="right">0</td><td align="right">0</td><td align="right">0</td><td align="right">0</td><td align="right">0</td><td align="right">0</td><td align="right">0</td><td align="right">0</td><td align="right">0</td><td align="right">0</td><td align="right">0</td><td align="right">0</td><td align="right">0</td><td align="right">0</td><td align="right">0</td><td align="right">0</td><td align="right">0</td><td align="right">0</td></tr>
</tbody>
</table>

