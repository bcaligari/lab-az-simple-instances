# lab-az-simple-instances

Spin up one or more identical SLES instances in Azure.

These scripts use Terraform resources rather than modules for finer graned control over what is being instantiated.

## Requirements

### Versions used

* [Terraform](https://www.terraform.io/downloads.html) - 0.12.24
    * AZURERM - 2.7.0
* [Python](https://www.anaconda.com/products/individual) - 3.8.2
    * Jinja2 - 2.11.2
    * Ansible - 2.9.7
    * PyYAML - 5.3.1
* [B1 Systems SUSEConnect Ansible role](https://github.com/b1-systems/ansible-role-suseconnect)

### Discovering SUSE images on Azure

```{text}
az vm image list --all --publisher SUSE --offer SLES --output table
```

## Secrets

### `~/.credentials/az_imports.sh`

```{text}
export AZURE_SUBSCRIPTION_ID='xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx'
export AZURE_CLIENT_ID='xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx'
export AZURE_SECRET='xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx'
export AZURE_TENANT='xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx'
```

### `~/.credentials/reg_codes.yaml`

```{yaml}
---
reg_key:
  sles_x86_64: "..."
  sles_sap_x86_64: "..."
```

### `~/.credentials/id_rsa[.pub]`

Key pair for sshing into instances.

## Workflow

### Config

#### Config variables

Most relevant variables can be found in `./terraform.tfvars`.  Unlikely that the remaining
Terraform variables in `./terraform/variables.tf` need to be overridden.

#### Azure credentials

```{text}
source ~/.credentials/az_imports.sh
```

#### SLES registration codes

Which key to load has to be uncommented in `./ansible/finalise.yaml`:

```{yaml}
  roles:
    - name: register the system
      role: b1-systems.suseconnect
      become: true
      vars:
        suseconnect_products:
          - product: 'SLES'
            key: "{{ reg_key['sles_x86_64'] }}"
          #- product: 'SLES_SAP'
          #  key: "{{ reg_key['sles_sap_x86_64'] }}
```

#### Config checklist recap

* Azure credentials in `~/.credentials/az_imports.sh` (and sourced)
* SLES registration codes in `~/.credentials/reg_cods.yaml`
* SSH Keys in `~/.credentials/`
* Terraform specifics in `./terraform.tfvars`
* Registration code selection in `./ansible/finalise.yaml`

### Terraform to spin up infrastructure

#### Init terraform

```{text}
terraform init terraform/
```

#### Plan and apply deployment

```{text}
terraform plan -out tfplan.out terraform/
```

```{text}
terraform apply tfplan.out
```

### Python script to create artefacts

```{text}
python ./scripts/tfout-exporter.py ./artefacts.yaml ./terraform.tfstate
```

### Ansible to configure instances

```{text}
ansible-playbook -i inventory.yaml ansible/finalise.yaml 
```

### Teardown & Cleanup

#### Destorying all infrastructure in Azure

```{text}
terraform destroy -auto-approve terraform/
```

### Cleaning up local files

```{text}
rm -rf ./.terraform
rm -f ./tfplan.out
rm -f ./terraform.tfstate
rm -f ./terraform.tfstate.backup
rm -f ./inventory.yaml
rm -f ./ansible/files/hosts
```
