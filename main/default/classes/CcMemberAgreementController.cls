public without sharing class CcMemberAgreementController {
    @AuraEnabled(cacheable=true)
    public static Map<String,Object> getAgreements(Id memberId) {

        Map<String,Object> agreements = new Map<String,Object>();

        if (memberId == null){
            return null; 
        }else{
            List<Map<String,Object>> incentives = new List<Map<String,Object>>();
            agreements.put('program', new Map<String,Object>());
            agreements.put('incentives', incentives);
            
            List<Agreement__c> allAgreements = AgreementService.getAgreementsToBeAcceptedByMember(memberId);

            for(Agreement__c agreement : allAgreements) {
                Map<String,Object> agreementItem = new Map<String,Object>();
                agreementItem.put('agreementId', agreement.Id);
                agreementItem.put('agreementText',agreement.FieloPLT__Agreement__c);
                
                if (agreement.FieloPLT__Challenge__c != null) {
                    agreementItem.put('title', agreement.FieloPLT__Challenge__r.Name);
                    agreementItem.put('recordId', agreement.FieloPLT__Challenge__c);
                    incentives.add(agreementItem);
                } else if (agreement.FieloPLT__Promotion__c != null) {
                    agreementItem.put('title', agreement.FieloPLT__Promotion__r.Name);
                    agreementItem.put('recordId', agreement.FieloPLT__Promotion__c);
                    incentives.add(agreementItem);
                } else {
                    agreementItem.put('title', agreement.FieloPLT__Program__r.Name);
                    agreementItem.put('recordId', agreement.FieloPLT__Program__c);
                    agreements.put('program', agreementItem);
                }
            }
            agreements.put('incentives', incentives);
            return agreements;
        }
        
    }
}
