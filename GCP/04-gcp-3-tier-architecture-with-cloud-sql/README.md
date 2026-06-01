# Project 04: GCP 3-Tier Architecture With Cloud SQL

This project builds a 3-tier architecture on Google Cloud using Terraform.

It is the GCP equivalent of an AWS 3-tier setup with VPC, public subnet, private subnet, NAT Gateway, EC2 instances, and RDS.

## Architecture

```text
Internet
   |
Public Web VM
   |
Private App VM
   |
Cloud SQL MySQL
Private IP only
```

Private outbound flow:

```text
Private App VM
   |
Private Subnet
   |
Cloud Router
   |
Cloud NAT
   |
Internet
```

## Resources Created

- Custom VPC
- Public subnet
- Private subnet
- Firewall rules
- Cloud Router
- Cloud NAT
- Public web Compute Engine VM
- Private app Compute Engine VM
- Private Service Access allocated range
- Service Networking connection
- Cloud SQL MySQL instance with private IP
- Application database
- Database user
- Random database password

## AWS To GCP Mapping

| AWS | GCP |
| --- | --- |
| VPC | `google_compute_network` |
| Subnet | `google_compute_subnetwork` |
| Security group rules | `google_compute_firewall` |
| EC2 | `google_compute_instance` |
| NAT Gateway | Cloud NAT with Cloud Router |
| RDS MySQL | Cloud SQL MySQL |
| DB subnet group/private DB networking | Private Service Access |
| AMI data source | `google_compute_image` data source |
| `user_data` | `metadata_startup_script` |

## Key GCP Concepts Learned

GCP VPC does not have a CIDR block at the VPC level. The VPC is a global resource, and CIDR ranges are configured on regional subnets.

```hcl
resource "google_compute_network" "main" {
  name                    = "${local.name_prefix}-vpc"
  auto_create_subnetworks = false
}
```

Subnets carry the CIDR:

```hcl
resource "google_compute_subnetwork" "private" {
  ip_cidr_range = var.private_subnet_cidr
  region        = var.gcp_region
  network       = google_compute_network.main.id
}
```

Public and private VM behavior is controlled mainly by whether the VM has an external IP.

Public VM:

```hcl
access_config {
  # Public IP
}
```

Private VM:

```hcl
network_interface {
  subnetwork = google_compute_subnetwork.private.id
}
```

No `access_config` means no public IP.

## Firewall Learning

GCP firewall rules apply to VMs using network tags.

Example:

```hcl
target_tags = ["ssh"]
```

The VM must have the same tag:

```hcl
tags = ["ssh", "app"]
```

If the firewall target tag does not match the VM tag, traffic is blocked even if the source range is open.

For IAP SSH, the source range is:

```text
35.235.240.0/20
```

Example:

```hcl
source_ranges = ["35.235.240.0/20"]
target_tags   = ["ssh"]
```

## Cloud NAT Learning

Cloud NAT is used so private VMs can access the internet without having public IP addresses.

Cloud NAT requires Cloud Router.

Important fields:

```hcl
resource "google_compute_router_nat" "main_nat" {
  router                             = google_compute_router.main.name
  region                             = var.gcp_region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"
}
```

Common mistake:

```hcl
router = google_compute_router.main.id
```

For Cloud NAT, use router name:

```hcl
router = google_compute_router.main.name
```

## VM Size Learning

CentOS Stream 9 needed more resources than `e2-micro` during package updates and installs.

Working VM setting:

```hcl
machine_type = "e2-small"
```

When changing machine type on a running VM, Terraform needs permission to stop and restart the instance:

```hcl
allow_stopping_for_update = true
```

## Cloud SQL Private IP Learning

Cloud SQL private IP requires Private Service Access.

The main resources are:

```hcl
resource "google_compute_global_address" "private_service_range" {
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.main.id
}
```

```hcl
resource "google_service_networking_connection" "private_service_connection" {
  network                 = google_compute_network.main.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_service_range.name]
}
```

Cloud SQL then uses the VPC private network:

```hcl
ip_configuration {
  ipv4_enabled    = false
  private_network = google_compute_network.main.id
}
```

## Required APIs

The following APIs are needed:

```bash
gcloud services enable compute.googleapis.com
gcloud services enable servicenetworking.googleapis.com
gcloud services enable sqladmin.googleapis.com
```

If Service Networking API is disabled, Terraform can fail with:

```text
Service Networking API has not been used in project before or it is disabled
```

Fix:

```bash
gcloud services enable servicenetworking.googleapis.com \
  --project=YOUR_GCP_PROJECT_ID
```

## Testing

SSH to the private app VM through IAP:

```bash
gcloud compute ssh gcp-3tier-dev-app \
  --zone us-central1-a \
  --tunnel-through-iap
```

Test private VM internet through Cloud NAT:

```bash
curl -I https://www.google.com
sudo dnf makecache
```

Get Cloud SQL private IP:

```bash
terraform output cloud_sql_private_ip
```

Get database password:

```bash
terraform output -raw database_password
```

Connect from app VM:

```bash
mysql -h CLOUD_SQL_PRIVATE_IP -u appuser -p
```

Inside MySQL:

```sql
SHOW DATABASES;
USE appdb;
SELECT DATABASE();
```

## Troubleshooting Notes

### IAP SSH Gets Stuck

The NumPy warning is not an error:

```text
To increase the performance of the tunnel, consider installing NumPy
```

If IAP SSH hangs, run:

```bash
gcloud compute ssh VM_NAME \
  --zone us-central1-a \
  --tunnel-through-iap \
  --troubleshoot
```

Check that:

- VM is running
- VM has the `ssh` tag
- firewall allows TCP 22 from `35.235.240.0/20`
- IAP API is enabled
- user has IAP tunnel permission

### Public Or Private VM Cannot Update Packages

Check DNS and internet from inside the VM:

```bash
curl -I https://www.google.com
nslookup google.com
ip route
cat /etc/resolv.conf
```

For CentOS Stream 9:

```bash
sudo dnf clean all
sudo dnf makecache
sudo dnf update -y
```

In this practice, the issue was related to VM size and local DNS confusion. Moving from `e2-micro` to `e2-small` helped package update/install operations.

### Private Service Access Destroy Issue

Cloud SQL private IP creates a Service Networking / VPC peering connection:

```text
servicenetworking-googleapis-com
```

During destroy, Cloud SQL must be deleted before Private Service Access can be deleted.

Sometimes Cloud SQL is deleted, but GCP still reports:

```text
Failed to delete connection; Producer services are still using this connection
```

Check Cloud SQL:

```bash
gcloud sql instances list \
  --project=YOUR_GCP_PROJECT_ID
```

Check VPC peering:

```bash
gcloud services vpc-peerings list \
  --network=gcp-3tier-dev-vpc \
  --project=YOUR_GCP_PROJECT_ID
```

Try deleting the peering manually:

```bash
gcloud services vpc-peerings delete \
  --service=servicenetworking.googleapis.com \
  --network=gcp-3tier-dev-vpc \
  --project=YOUR_GCP_PROJECT_ID
```

If GCP still says producer services are using the connection, wait and retry later. This cleanup can be delayed on the Google producer side.

### Terraform GCS State Lock Issue

The GCS backend creates a lock file like:

```text
gs://gcp-terraform-dev/terraform/state/default.tflock
```

If Terraform is interrupted, a stale lock can block future commands.

Example error:

```text
Error acquiring the state lock
```

Fix with the lock ID from the error:

```bash
terraform force-unlock LOCK_ID
```

If needed, remove the stale lock file manually only after confirming no Terraform command is running:

```bash
gcloud storage rm gs://gcp-terraform-dev/terraform/state/default.tflock
```

If a resource is already deleted or must be unmanaged, remove it from Terraform state:

```bash
terraform state rm google_service_networking_connection.private_service_connection
```

## Interview Notes

In GCP, a VPC is global and does not have a CIDR block. Subnets are regional and define CIDR ranges.

Cloud NAT requires Cloud Router and allows private instances to access the internet without public IP addresses.

Cloud SQL private IP requires Private Service Access, which uses Service Networking and VPC peering.

For SSH to private VMs, use IAP tunneling instead of public SSH.

Firewall target tags must match VM tags, otherwise the firewall rule will not apply.

Changing a Compute Engine machine type requires stopping the VM. In Terraform, use `allow_stopping_for_update = true`.

During destroy, Cloud SQL private IP resources can delay deletion of the Service Networking connection because producer-side cleanup is not always immediate.

## Cleanup

Destroy resources:

```bash
terraform destroy
```

If destroy fails on Private Service Access, confirm Cloud SQL is gone, then retry after some time:

```bash
gcloud sql instances list --project=YOUR_GCP_PROJECT_ID
terraform destroy
```
