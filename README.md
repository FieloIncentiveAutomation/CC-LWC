# CC-LWC
Fielo Community LWC

- ccIncentives (Fielo - Incentives (CC-LWC))
    - ccEligibility (Nome na tela)

- (MemberSelector) (Fielo - Member Selector)
    - ccMemberAgreement (Nome na tela)

- (MyPayouts) (Fielo - My Payouts)
    - ccDetail (Nome na tela)
    - ccRelatedList (Nome na tela)

### Incentives (ccIncentives)
Incentives gather in only one place all of your Program's incentives available for the members. It is a simple way of displaying Promotions or Challenges. It also allows members to enroll to the incentive. For more details on the components and how to use them, you can following the instructions provided here: [Build an Experience Cloud Site](https://docs.fielo.com/docs/incentives-1)

#### Eligibility (ccEligibility)
Eligibility Shows the requirements link, which will open a dashboard (Progress view option) or message (Description View option) detailing which actions the member need to accomplish in order to be able to participate in the Promotion or Challenge.

#### Agreement (ccMemberAgreement)
The agreement is a way of setting terms & conditions that Members need to accept in order to take part in your incentive. When you have a current agreement set in a Promotion or Challenge, the member will have to Agree to it the first time they access and try to enroll to that active incentive, or Cancel their enrollment.

# Deploy instructions

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

