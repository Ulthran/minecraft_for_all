# Cost Projections

## Notes

-  Need to consider payment platform. If we're expecting majority microtransactions we'll need to choose something that doesn't charge fees for every transaction.
-  Pricing below uses AWS us-east-1 on-demand rates as of 2023.
-  Payment fees assume Stripe's 2.9% + $0.30 per monthly invoice.

## Baseline Costs

-  t4g.small: $0.0168/hr (2 vCPU, 2 GiB RAM)
-  t4g.medium: $0.0336/hr (2 vCPU, 4 GiB RAM)
-  t3.large: $0.0832/hr (x86, 2 vCPU, 8 GiB RAM for modded servers)
-  gp3 storage: $0.08/GB-month
-  Outbound data: first 1 GB free, then $0.09/GB

## No one plays for the month

Assume 5 GB world with total inactivity. World doesn't move from EBS. No backups.

-  Server: $0.00
-  Data transfer: $0.00
-  Storage: $0.40

Total: $0.40

## 5 Players for 3 hours a week (vanilla or PaperMC)

Assume 15 GB world stored on gp3. The server runs on a t4g.medium instance for 12 hours total each month. Roughly 6 GB of outbound data for all players.

-  Server: $0.40
-  Data transfer: $0.45
-  Storage: $1.20

Subtotal: $2.05
-  Payment fees: ~$0.36

Total: ~$2.41

## 10 Players heavy usage with mods (PaperMC + mods)

Assume a 40 GB world with the server running 24/7 on a t3.large instance for mod compatibility. About 500 GB of outbound data for the month.

-  Server: $59.90
-  Data transfer: $44.91
-  Storage: $3.20

Subtotal: $108.01
-  Payment fees: ~$3.43

Total: ~$111.44

## Cheaper alternative: always-on vanilla on t4g.small

For a small vanilla or lightly modded server running all month with a 10 GB world and 50 GB of outbound data.

-  Server: $12.10
-  Data transfer: $4.41
-  Storage: $0.80

Subtotal: $17.31
-  Payment fees: ~$0.80

Total: ~$18.11

## Considerations for lower-cost cloud providers

Other cloud vendors like Oracle Cloud or DigitalOcean offer ARM instances around $0.02–$0.04/hr, often with free egress quotas. A comparable instance running 24/7 at $0.02/hr would cost about $14.40 per month before storage and payment fees. These platforms can reduce monthly totals for small servers but require manual setup outside of AWS.
