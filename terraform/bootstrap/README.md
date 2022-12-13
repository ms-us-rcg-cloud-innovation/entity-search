# Terraform Bootstrap (Run Once)

This folder contains the terraform bootstrapping files. These files create a resource group and storage account specifically for storing terraform state. 

## Running

The easiest way to bootstrap the terraform infrastructure is to manually execute the .github/workflows/bootstrap-infrastructure.yml

You can do this from the command line using the github cli `gh`. 

```bash
# this is run from the repository root
gh workflow run .github/workflows/bootstrap-infrastructure.yml
```

## Outputs

When the scripts are finished running, the output will be a resource group suffixed with '_terraform' and a storage account to hold future terraform state. 

## Notes

The state for bootstrapping is thrown away after each invocation. Bootstrapping is meant to be run only once. 