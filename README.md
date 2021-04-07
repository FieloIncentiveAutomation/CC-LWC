# CC-LWC
Fielo Community LWC

# Deploy instructions

If you already have an environment with Salesforce CLI and Visual Studio Code set up, jump to **Connecting to the target sandboxes / orgs**

### Working with a Salesforce DX project

Associating a SSH public key with your Github account to streamline access
In order to facilitate your access through a git client, you can associate a public ssh certificate into your Github account, so you are not prompted every time that you want to execute a command against the remote repository to enter your credentials. You can do that following the instructions provided here: [Adding a new SSH key to your GitHub account](https://docs.github.com/en/github/authenticating-to-github/adding-a-new-ssh-key-to-your-github-account)

### Configuring your development environment for a Salesforce DX project

The following software list is a recommendation for your development environment:

- Git client
- Salesforce CLI
- Visual Studio Code with the following plug-gins:
- GitLens
- Salesforce Extension Pack
- Salesforce CLI Integration

You will also have to clone the Github repository locally. To do that, navigate to a folder where you want your project to be locally stored and execute the following command:

`git clone git@github.com:FieloIncentiveAutomation/CC-LWC.git`

### Connecting to the target sandboxes / orgs

You will need to authenticate your Salesforce CLI client against your development / testing / production sandboxes / orgs that have the latest FieloPLT package installed in order to be able to deploy and use the components. To do that, in your Salesforce DX project folder execute the following command:

`sfdx force:auth:web:login -r https://test.salesforce.com -a <SANDBOX_ALIAS>`

Or

`sfdx force:auth:web:login -a <ORG_ALIAS>`

### Metadata deployment

If you didn't convert the source into metadata, execute the following command:

`sfdx force:source:deploy -u <SANDBOX/ORG_ALIAS> -p force-app`

(Optional) convert the source into metadata with the following command:

`sfdx force:source:convert -r force-app -d <CONVERTED_METADATA_FOLDER>`

(Optional) deploy the converted metadata with the following command:

`sfdx force:mdapi:deploy -u <SANDBOX/ORG_ALIAS> -d <CONVERTED_METADATA_FOLDER>`

