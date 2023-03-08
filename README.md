## Orchestrated Event Routing

This repository is a companion to the Orchestrated Event Routing Using Graphs article. 

## Running the Sample

Clone the repository and change directories to the terraform directory.

> cd terraform

Init the terraform directory

> terraform init

Optionally update the required variables in variables.tf (region, vpc_id, vpc_subnets_private_ids) and run the apply command.

> terraform apply

... or run apply with the variables passed on the command line like the following...

> terraform apply -var="region=us-west-2" -var="vpc_id=<vpc-xyz>" -var='vpc_subnets_private_ids=["<subnet-abc>", "<subnet-xyz>"]'

... and approve the provisioning when prompted after you've seen the expected changes.

## Security & Contributing

See [CONTRIBUTING](CONTRIBUTING.md#security-issue-notifications) for more information.

## License

This library is licensed under the MIT-0 License. See the LICENSE file.
