public with sharing class CcLabelTranslatorController {
    public String label_lang {get;set;}
    public String label {get;set;}
    public CcLabelTranslatorController() {
        Map<String, String> reqParams = ApexPages.currentPage().getParameters(); 
        label_lang = reqParams.get('label_lang');
        system.debug(reqParams.get('label'));
       label = reqParams.get('label');
    }
}