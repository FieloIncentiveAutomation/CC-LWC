public with sharing class LWCService {

    // Code used by communities and backend
    public static Map<String, String> inputTypeMap {get{
        if (inputTypeMap == null) {
            inputTypeMap = new Map<String,String>{
                'address' => 'text',
                'anytype' => 'none',
                'base64' => 'text',
                'boolean' => 'checkbox',
                'combobox' => 'checkbox',
                'currency' => 'number',
                'datacategorygroupreference' => 'none',
                'date' => 'date',
                'datetime' => 'datetime',
                'double' => 'number',
                'email' => 'email',
                'encryptedstring' => 'text',
                'id' => 'text',
                'integer' => 'text',
                'multipicklist' => 'text',
                'percent' => 'number',
                'phone' => 'text',
                'picklist' => 'picklist',
                'reference' => 'reference',
                'string' => 'text',
                'textarea' => 'text',
                'time' => 'time',
                'url' => 'url'
            };
        }
        return inputTypeMap;
    } set;}

    // Code used by communities and backend
    public static Map<String, String> isQuoted {get{
        if (isQuoted == null) {
            isQuoted = new Map<String,String>{
                'address' => 'true',
                'anytype' => 'true',
                'base64' => 'true',
                'boolean' => 'false',
                'combobox' => 'false',
                'currency' => 'false',
                'datacategorygroupreference' => 'false',
                'date' => 'false',
                'datetime' => 'false',
                'double' => 'false',
                'email' => 'true',
                'encryptedstring' => 'true',
                'id' => 'true',
                'integer' => 'false',
                'multipicklist' => 'true',
                'percent' => 'false',
                'phone' => 'true',
                'picklist' => 'true',
                'reference' => 'true',
                'string' => 'true',
                'textarea' => 'true',
                'time' => 'false',
                'url' => 'true'
            };
        }
        return isQuoted;
    } set;}

    // Code used by communities and backend
    public static Map<String, String> jsPrimitiveTypeMap {get{
        if (jsPrimitiveTypeMap == null) {
            jsPrimitiveTypeMap = new Map<String,String>{
                'address' => 'string',
                'anytype' => 'object',
                'base64' => 'string',
                'boolean' => 'boolean',
                'combobox' => 'boolean',
                'currency' => 'number',
                'datacategorygroupreference' => 'object',
                'date' => 'string',
                'datetime' => 'string',
                'double' => 'number',
                'email' => 'string',
                'encryptedstring' => 'string',
                'id' => 'string',
                'integer' => 'number',
                'multipicklist' => 'string',
                'percent' => 'number',
                'phone' => 'string',
                'picklist' => 'string',
                'reference' => 'string',
                'string' => 'string',
                'textarea' => 'string',
                'time' => 'number',
                'url' => 'string'
            };
        }
        return jsPrimitiveTypeMap;
    } set; }

    @AuraEnabled(cacheable=true)
    public static Object getWiredFieldSet(String objectApiName, String fieldSetName){
        Map<String,Object> fieldMap = new Map<String,Object>();
        List<String> fieldset = new List<String>();
        List<Map<String,Object>> columns = new List<Map<String,Object>>();

        Schema.DescribeSObjectResult objectDescribe = ((sObject)Type.forName(objectApiName).newInstance()).getSObjectType().getDescribe();
        Schema.DescribeFieldResult fieldDescribe;
        Map<String,Object> col;
        String fieldType;
        Map<String,Object> fieldMeta;
        if( objectDescribe != null &&  fieldSetName != null ){
            for ( Schema.FieldSetMember fieldSetMemberObj : objectDescribe.FieldSets.getMap().get(fieldSetName).getFields()) {
                //The list with the api names
                if( fieldSetMemberObj.getFieldPath() == 'RecordTypeId'){
                    fieldset.add('RecordType');
                } else {
                    fieldDescribe = fieldSetMemberObj.getSObjectField().getDescribe();
                    fieldType = fieldDescribe.getType().name().toLowerCase();

                    fieldset.add(fieldSetMemberObj.getFieldPath());

                    fieldMeta = new Map<String,Object>();
                    fieldMap.put(fieldSetMemberObj.getFieldPath(), fieldMeta);

                    fieldMeta.put('type', (Object) fieldType);
                    fieldMeta.put('label', (Object) fieldDescribe.getLabel());
                    fieldMeta.put('jsType', (Object) jsPrimitiveTypeMap.get(fieldDescribe.getType().name().toLowerCase()));
                    fieldMeta.put('scale', (Object) String.valueOf(fieldDescribe.getScale()));
                    fieldMeta.put('relationshipName', (Object) fieldDescribe.getRelationshipName());
                    fieldMeta.put('referenceToNameField', (Object) (fieldDescribe.getReferenceTo() != null && !fieldDescribe.getReferenceTo().isEmpty() ?
                            getNameField(fieldDescribe.getReferenceTo()[0].getDescribe()) :
                            ''));
                    fieldMeta.put('name', (Object) fieldSetMemberObj.getFieldPath());
                    fieldMeta.put('precision', (Object) fieldDescribe.getPrecision());
                    fieldMeta.put('referenceTo', (Object) fieldDescribe.getReferenceTo() != null && !fieldDescribe.getReferenceTo().isEmpty() ?
                        fieldDescribe.getReferenceTo().get(0).getDescribe().getName() :
                        '');
                    fieldMeta.put('referenceToLabel', (Object) (fieldDescribe.getReferenceTo() != null && !fieldDescribe.getReferenceTo().isEmpty() ?
                            fieldDescribe.getReferenceTo().get(0).getDescribe().getLabel() :
                            ''));
                    fieldMeta.put('className', fieldSetMemberObj.getFieldPath().replaceAll('__','').replaceAll('.',''));

                    col = new Map<String,Object>();
                    col.put('name', (Object) fieldSetMemberObj.getFieldPath());
                    col.put('fieldName', (Object) fieldSetMemberObj.getFieldPath());


                    if (fieldSetMemberObj.getFieldPath().contains('.')) {
                        col.put('label', getPathLabel(objectApiName, fieldSetMemberObj.getFieldPath()));
                    } else {
                        col.put('label', (Object) fieldDescribe.getLabel());
                    }

                    // Customizations
                    switch on fieldSetName {
                        when 'FieloPLT__ccPayoutItems' {
                            if (fieldSetMemberObj.getFieldPath()=='Name') {
                                //col.put('label', (Object) Label.PayoutItemName);
                                col.put('label', (Object) 'Item Number');
                            }
                        }
                    }

                    switch on fieldType {
                        when 'text' {
                            col.put('type', (Object) 'text');
                            fieldMeta.put('isText', (Object) true);
                        }
                        when 'percent' {
                            col.put('type', (Object) 'percent');
                            fieldMeta.put('isPercent', (Object) true);
                        }
                        when 'currency' {
                            col.put('type', (Object) 'currency');
                            col.put('typeAttributes', (Object) new Map<String, String>{
                                'currencyCode' => 'USD'
                            });
                            col.put('cellAttributes', (Object) new Map<String, String>{
                                'alignment' => 'left'
                            });
                            fieldMeta.put('isCurrency', (Object) true);
                        }
                        when 'double','integer','decimal' {
                            col.put('type', (Object) 'number');
                            col.put('typeAttributes', (Object) new Map<String, String>{
                                'minimumFractionDigits' => String.valueOf(fieldDescribe.getScale())
                            });
                            col.put('cellAttributes', (Object) new Map<String, String>{
                                'alignment' => 'left'
                            });
                            fieldMeta.put('isNumber', (Object) true);
                        }
                        when 'reference' {
                            col.put('type', (Object) 'text');
                            col.put('fieldName', (Object) fieldDescribe.getRelationshipName() + '.' + String.valueOf( ((Map<String,Object>)fieldMap.get(fieldSetMemberObj.getFieldPath())).get('referenceToNameField')));
                            fieldMeta.put('isText', (Object) true);
                        }
                        when 'date' {
                            col.put('type', (Object) 'date');
                            col.put('typeAttributes', (Object) new Map<String, String>{
                                'timeZone' => 'UTC',
                                'year' => 'numeric',
                                'month' => 'numeric',
                                'day' => 'numeric'
                            });
                            fieldMeta.put('isDate', (Object) true);
                        }
                        when 'datetime' {
                            col.put('type', (Object) 'date');
                            col.put('typeAttributes', (Object) new Map<String, Object>{
                                'timeZone' => (Object) 'UTC',
                                'year' => (Object) 'numeric',
                                'month' => (Object) 'numeric',
                                'day' => (Object) 'numeric',
                                'hour' => (Object) '2-digit',
                                'minute' => (Object) '2-digit',
                                'hour12' => (Object) true
                            });
                            fieldMeta.put('isDatetime', (Object) true);
                        }
                        when else {
                            fieldMeta.put('isText', (Object) true);
                        }
                    }
                    columns.add(col);
                }
            }
        }

        return (Object) new Map<String,Object>{
            'fieldSet' => (Object) fieldset,
            'fieldMap' => (Object) fieldMap,
            'columns' => (Object) columns
        };
    }

    // Code used by backend
    // LwcVersion to use with wire
    @AuraEnabled(cacheable=true)
    public static List<SObject> getWiredRecords(String fields, String objectName, String dataFilters, String orderBy, String recordsPerPage, String offset) {
        return getRecords(fields, objectName, dataFilters, orderBy, recordsPerPage, offset);
    }

    // Code used by communities and backend
    @AuraEnabled(cacheable=true)
    public static String getFieldData(String objectName, String fieldNames, Boolean enableDependentPicklist) {
        if(String.isBlank(objectName)) return '';
        Boolean isRank = false;
        if( objectName == 'FieloPLT__RankMember__c' ){
            isRank = true;
            objectName = 'FieloPLT__LevelMember__c';
        } else if( objectName == 'FieloPLT__Rank__c' ){
            isRank = true;
            objectName = 'FieloPLT__Level__c';
        }

        DescribeSObjectResult objectDescribe = ((sObject)Type.forName(objectName).newInstance()).getSObjectType().getDescribe();
        Map<String, Object> objectInfo = new Map<String, Object>();
        String objectLabel = String.valueOf(objectDescribe.getLabel());
        String objectLabelPlural = String.valueOf(objectDescribe.getLabelPlural());
        String objectApiName = String.valueOf(objectDescribe.getName());
        if( isRank ){
            objectLabel = objectLabel.replace('Level', 'Rank');
            objectLabelPlural = objectLabelPlural.replace('Level', 'Rank');
            objectApiName = objectApiName.replace('Level', 'Rank');
        }

        //Object
        objectInfo.put('label', objectLabel);
        objectInfo.put('labelplural', objectLabelPlural);
        objectInfo.put('name', objectApiName);
        objectInfo.put('prefix', (Object) objectDescribe.getKeyPrefix());

        //Get fields
        Set<String> fieldNamesSet = new Set<String>();
        if( fieldNames != null && fieldNames != '' ){
            fieldNamesSet.addAll( fieldNames.split(',') );
        }
        Map<String,Schema.SObjectField> fieldMap = objectDescribe.fields.getMap();
        List<String> labels = new List<String>();
        Map<String, Schema.SObjectField> fieldsMap = new Map<String, Schema.SObjectField>();
        Map<String,String> objectNameByrelationship = new Map<String,String>();

        for(String s : fieldMap.keySet()){
            String campo = fieldMap.get(s).getDescribe().getName();
            if( isRank ){
                campo = campo.replace('Level', 'Rank');
            }
            if (fieldMap.get(s).getDescribe().getType().name().toLowerCase() == 'reference') {
                objectNameByrelationship.put( fieldMap.get(s).getDescribe().getRelationshipName(),
                    fieldMap.get(s).getDescribe().getReferenceTo().get(0).getDescribe().getName()
                );
            }
            if( fieldNamesSet.isEmpty() || (fieldNamesSet.contains(campo) && fieldMap.get(s).getDescribe().isAccessible()) ){
                String label = fieldMap.get(s).getDescribe().getLabel();
                if( isRank && label.contains('Level') ){
                    label = label.replace('Level', 'Rank');
                }
                if(labels.contains(label)){
                    label = label + ' (1)';
                }
                labels.add( label );
                fieldsMap.put(label, fieldMap.get(s));
            }
        }

        Map<String,Set<String>> relatedFields = new Map<String,Set<String>>();
        for (String fName : fieldNamesSet) {
            if (fName.contains('.')) {
                List<String> objectFieldArray = fName.split('\\.', 2);
                if (relatedFields.containsKey(objectFieldArray[0]) ) {
                    relatedFields.get(objectFieldArray[0]).add(objectFieldArray[1]);
                } else {
                    relatedFields.put(objectFieldArray[0], new Set<String>{objectFieldArray[1]});
                }
            }
        }
        labels.sort();

        DescribeSObjectResult relatedObjectDescribe;
        List<Map<String, Object>> fieldsInfo = new List<Map<String, Object>>();
        Map<String, Object> fieldAttributes;
        List<Map<String, String>> picklistEntries;
        DescribeFieldResult fieldDescribe;
        for( String l: labels ){
            fieldsInfo.add(new Map<String, Object>());
            fieldDescribe = fieldsMap.get(l).getDescribe();
            fieldAttributes = new Map<String, Object>();
            fieldAttributes.put('objectName', objectDescribe.getName());
            fieldAttributes.put('objectLabel', objectDescribe.getLabel());
            fieldAttributes.put('label', l);
            String fieldName = fieldDescribe.getName();
            if( isRank ){
                fieldName = fieldDescribe.getName().replace('Level', 'Rank');
            }
            fieldAttributes.put('name', fieldName);
            fieldAttributes.put('type', fieldDescribe.getType().name().toLowerCase());
            fieldAttributes.put('inputType', inputTypeMap.get(fieldDescribe.getType().name().toLowerCase()));
            fieldAttributes.put('jsType', jsPrimitiveTypeMap.get((String) fieldAttributes.get('type')));
            fieldAttributes.put('isQuoted', isQuoted.get((String) fieldAttributes.get('type')));
            fieldAttributes.put('soaptype', fieldDescribe.getSOAPType().name().toLowerCase());
            fieldAttributes.put('scale', String.valueOf(fieldDescribe.getScale()));
            fieldAttributes.put('precision', String.valueOf(fieldDescribe.getPrecision()));
            fieldAttributes.put('tooltip', fieldDescribe.getInlineHelpText());
            fieldAttributes.put('isAccessible', String.valueOf(fieldDescribe.isAccessible()));
            fieldAttributes.put('isCreateable', String.valueOf(fieldDescribe.isCreateable()));
            fieldAttributes.put('isUpdateable', String.valueOf(fieldDescribe.isUpdateable()));
            fieldAttributes.put('isIdLookup', String.valueOf(fieldDescribe.isIdLookup()));
            fieldAttributes.put('isNillable', String.valueOf(fieldDescribe.isNillable()));
            if (fieldDescribe.getScale()!=null) {
                if(fieldDescribe.getScale() == 0){
                    fieldAttributes.put('step', '1' );
                }else{
                    fieldAttributes.put('step', '0.' + '0'.repeat(fieldDescribe.getScale()-1) + '1' );
                }
            }
            fieldAttributes.put('helpText', fieldDescribe.getInlineHelpText());
            fieldAttributes.put('id', fieldDescribe.getName().replace('_',''));
            if ( fieldAttributes.get('type') == 'picklist' || fieldAttributes.get('type') == 'multipicklist' ) {
                picklistEntries = new List<Map<String, String>>();
                fieldAttributes.put('defaultValue', '');
                fieldAttributes.put('isDependentPicklist', String.valueOf(fieldDescribe.isDependentPicklist()));
                if(!enableDependentPicklist){
                    fieldAttributes.put('isDependentPicklist', String.valueOf(false));
                }
                if (enableDependentPicklist && fieldDescribe.isDependentPicklist()) {
                    fieldAttributes.put('controllerField', String.valueOf(fieldDescribe.getController()));
                    Map<String, Object> validPicklistOptions = (Map<String, Object>) JSON.deserializeUntyped(getDependentOptions(
                                fieldDescribe.getController().getDescribe().getPicklistValues(),
                                fieldDescribe.getPicklistValues()
                            ) );

                    fieldAttributes.put('validPicklistOptions', (Object) validPicklistOptions);
                }


                for (Schema.PicklistEntry pValues: fieldDescribe.getPicklistValues()) {
                    picklistEntries.add(new Map<String, String>{'value' => pValues.getValue(),'label'=> pValues.getLabel()});
                    if (pValues.isDefaultValue()) {
                        fieldAttributes.put('defaultValue', pValues.getValue());
                    }
                }
                if (!picklistEntries.isEmpty()) {
                    fieldsInfo.get(fieldsInfo.size()-1).put('picklistentries', (Object) picklistEntries);
                }
            }
            if (fieldAttributes.get('type') == 'date') {
                fieldAttributes.put('timeZone', UserInfo.getTimeZone().getID());
            }
            if (fieldAttributes.get('type') == 'currency') {
                fieldAttributes.put('currencyCode', UserInfo.getDefaultCurrency());
                fieldAttributes.put('formatter', 'currency');
            }
            if (fieldAttributes.get('type') == 'percent') {
                fieldAttributes.put('formatter', 'percent');
            }
            if (fieldAttributes.get('type') == 'reference') {
                relatedObjectDescribe = fieldDescribe.getReferenceTo()[0].getDescribe();
                fieldAttributes.put('referenceToNameField', getNameField(relatedObjectDescribe));
                if( isRank ){
                    fieldAttributes.put('referenceTo', relatedObjectDescribe.getName().replace('Level', 'Rank'));
                    fieldAttributes.put('referenceToLabel', relatedObjectDescribe.getLabel().replace('Level', 'Rank'));
                    fieldAttributes.put('relationshipName', fieldDescribe.getRelationshipName().replace('Level', 'Rank'));
                } else {
                    fieldAttributes.put('referenceTo', relatedObjectDescribe.getName());
                    fieldAttributes.put('referenceToLabel', relatedObjectDescribe.getLabel());
                    fieldAttributes.put('relationshipName', fieldDescribe.getRelationshipName());
                }
            }
            fieldsInfo.get(fieldsInfo.size()-1).put('attributes', (Object) fieldAttributes);
        }

        if (!relatedFields.isEmpty()) {
            for (String obj: relatedFields.keySet()) {
                try{
                    Map<String, Object> relFieldAttributes;
                    Map<String, Object> relFieldInfo;
                    Map<String, Object> data = (Map<String, Object>) JSON.deserializeUntyped(getFieldData(objectNameByrelationship.get(obj), String.join(new List<String>(relatedFields.get(obj)),','), enableDependentPicklist));
                    for (Object relField : ((List<Object>)data.get('fields'))) {
                        relFieldInfo = new Map<String, Object>((Map<String, Object>)relField);
                        relFieldAttributes = (Map<String, Object>) relFieldInfo.get('attributes');
                        relFieldAttributes.put('name', (object) obj + '.' + String.valueOf(relFieldAttributes.get('name')) );
                        if(relFieldAttributes.containsKey('labelPath')){
                            relFieldAttributes.put('labelPath', (object) String.valueOf(objectInfo.get('label')) + ' > ' + String.valueOf(relFieldAttributes.get('labelPath')) );
                        }else{
                            relFieldAttributes.put('labelPath', (object) String.valueOf(objectInfo.get('label')) + ' > ' + String.valueOf(relFieldAttributes.get('objectLabel'))  + ' > ' + String.valueOf(relFieldAttributes.get('label')) );
                        }

                        relFieldInfo.put('attributes', (object) relFieldAttributes);
                        fieldsInfo.add(relFieldInfo);
                    }
                } catch(Exception e) {
                    System.debug(e.getMessage());
                }
            }
        }
        objectInfo.put('fields', (Object) fieldsInfo);
        return JSON.serialize(objectInfo);
    }

    @AuraEnabled(cacheable=true)
    public static String getWiredFieldData(String objectName, String fieldNames, Boolean enableDependentPicklist) {
        return getFieldData(objectName, fieldNames, enableDependentPicklist);
    }

    @AuraEnabled(cacheable=true)
    public static String getLabel(String labelName, String language){
        if (String.isNotBlank(labelName)) {
            Pagereference r = Page.CcLabelTranslator;
            r.getParameters().put('label_lang', language);
            r.getParameters().put('label', labelName);
            String labelValue = r.getContent().toString();
            return labelValue;
        }
        return '';
    }

    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getEligibilitycriterion(Map<String, List<String>> records){
        return FieloPLT.EligibilityService.getEligibilitycriterion(records);
    }

    // Code used by backend
    // Moved the cache control to the BeUtils to be able to enable/disable
    // on the client side. Some components need this case.
    @AuraEnabled
    public static List<SObject> getRecords(String fields, String objectName, String dataFilters, String orderBy, String recordsPerPage, String offset) {
        Boolean isRank = false;
        if( objectName == 'FieloPLT__Rank__c' ){
            isRank = true;
            objectName = 'FieloPLT__Level__c';

            Map<String,Object> filter = (Map<String, Object>) JSON.deserializeUntyped(dataFilters);
            if (!filter.containsKey('FieloPLT__Challenge__c') || filter.get('FieloPLT__Challenge__c') == null) {
                filter.put('FieloPLT__Challenge__c', '!null');
            }
            dataFilters = JSON.serialize(filter);
        }else if( objectName == 'FieloPLT__Level__c' ){
            Map<String,Object> filter = (Map<String, Object>) JSON.deserializeUntyped(dataFilters);
            if (!filter.containsKey('FieloPLT__Challenge__c') || filter.get('FieloPLT__Challenge__c') == null) {
                filter.put('FieloPLT__Challenge__c', 'null');
            }
            dataFilters = JSON.serialize(filter);
        }
        Schema.DescribeSObjectResult objectDescribe = Schema.describeSObjects(new List<String>{objectName})[0];
        //Security Check
        if(!objectDescribe.isAccessible()){
            throw new FieloPLT.FieloApiException(objectName + ' cannot be read.');
        }
        Set<String> picklistTypes = new Set<String>{'PICKLIST','MULTIPICKLIST'};
        List<String> fieldset = new List<String>();

        List<String> listFields = fields != null ? fields.deleteWhitespace().split(',') : new List<String>();
        for( Integer i = 0; i < listFields.size(); i++ ){
            if ( listFields.get(i) == 'RecordType') {
                listFields.remove(i);
                listFields.add('RecordTypeId');
            }
        }
        Map<String,Schema.SObjectField> fieldMap = objectDescribe.fields.getMap();
        for(String fieldName: listFields){
            Schema.DescribeFieldResult fieldDescribe = fieldMap?.get(fieldName)?.getDescribe();
            if(fieldDescribe?.isAccessible() == false){
                throw new FieloPLT.FieloApiException('Field ' + objectName + ' on ' + fieldName + ' cannot be read.');
            }
            else if (fieldDescribe != null) {
                if(fieldMap.containskey(fieldName) && picklistTypes.contains(fieldDescribe.getType().name())){
                    fieldset.add('toLabel(' + fieldName + ') '+fieldName.toLowerCase()+'_label');
                } else if(fieldMap.containskey(fieldName) && fieldDescribe?.getType().name().tolowercase() == 'REFERENCE') {
                    Schema.DescribeFieldResult dfr = fieldDescribe;
                    String relatedObjNameField = getNameField( dfr.getReferenceTo()[0].getDescribe() );
                    if (String.isNotBlank(relatedObjNameField)) {
                        fieldset.add(dfr.getRelationshipName() + '.' + relatedObjNameField );
                    }
                }
            }
            fieldset.add(fieldName);
        }
        return queryPickListRecords(new List<String>(new Set<String>(fieldset)), fields, objectName, dataFilters, orderBy, recordsPerPage, offset);
    }

    //return the fieldset LandingList configured (api names) for the object.
    @AuraEnabled
    public static List<String> getFieldSet(String objectApiName, String fieldSetName){
        List<String> fielset = new List<String>();
        try{
            Schema.DescribeSObjectResult objectDescribe = ((sObject)Type.forName(objectApiName).newInstance()).getSObjectType().getDescribe();
            if( objectDescribe != null &&  fieldSetName != null ){
                for ( Schema.FieldSetMember fieldSetMemberObj : objectDescribe.FieldSets.getMap().get(fieldSetName).getFields()) {
                    //The list with the api names
					if( fieldSetMemberObj.getFieldPath() == 'RecordTypeId'){
					    fielset.add('RecordType');
					}else {
						fielset.add(fieldSetMemberObj.getFieldPath());
					}
                }
            }
        }catch(Exception e){
            return new List<String>{'Name','CreatedDate' };
        }
        return fielset;
    }

    public static string getNameField(Schema.DescribeSObjectResult dsr) {
        if (dsr != null) {
            for(Schema.SObjectField field : dsr.fields.getMap().values()) {
                if (field.getDescribe().isNameField()) {
                    return field.getDescribe().getName();
                }
            }
        }
        return null;
    }

    public static string getPathLabel(String objectName, String path) {
        Schema.DescribeSObjectResult describe = ((sObject)Type.forName(objectName).newInstance()).getSObjectType().getDescribe();

        if (path.contains('.')) {
            List<String> fieldPath = path.split('\\.');
            String relationShipName = fieldPath.remove(0);
            string fieldName = relationShipName.endsWith('__r') ? relationShipName.replace('__r','__c') : relationShipName + 'Id';
            return getPathLabel(
                describe.fields.getMap().get(fieldName).getDescribe().getReferenceTo().get(0).getDescribe().getName(),
                String.join(fieldPath,'.')
            );
        } else {
            if (!describe.fields.getMap().get(path).getDescribe().getLabel().trim().startsWith(describe.getLabel())) {
                return describe.getLabel() + ' ' + describe.fields.getMap().get(path).getDescribe().getLabel();
            } else {
                return describe.fields.getMap().get(path).getDescribe().getLabel();
            }
        }
    }

    public static List<SObject> queryPickListRecords(List<String> fieldset, String fields, String objectName, String dataFilters, String orderBy, String recordsPerPage, String offset) {
        List<SObject> result = new List<SObject>();
        String query = 'SELECT Id ';
        if (fields != '') {
            query += ', ' + String.join(fieldset, ',');
        }
        query += ' FROM ' + objectName;
        query += getWhereCondition(dataFilters, objectName);

        // ORDER BY
        if (orderBy == null){
            orderBy = 'LastModifiedDate DESC';
        }
        query += ' ORDER BY '+ orderBy;

        // LIMIT & OFFSET
        if (recordsPerPage != null) {
            query += ' LIMIT ' + recordsPerPage;
        }

        if ( offset != null ){
            query += ' OFFSET ' + offset;
        }
        if(Schema.describeSObjects(  new List<String>{objectName} )[0].isAccessible()) {
            result = Database.query(query);
        } else {
            throw new FieloPLT.FieloApiException(objectName + ' cannot be read.');
        }
        return result;
    }

    private static String getWhereCondition(String filterJson, String objectName) {
        Map<String, Schema.SObjectField> objectFields = ((sObject)Type.forName(objectName).newInstance()).getSObjectType().getDescribe().fields.getMap();

        String whereCondition = '';
        if (String.isNotBlank(filterJson) && filterJson != null ) {
            try {
                Map<String,Object> filter = (Map<String, Object>) JSON.deserializeUntyped( filterJson);
                for ( String k :filter.keySet() ) {
                    String value = string.valueOf(filter.get(k));
                    if (value == null || value == 'null') {
                        whereCondition += ' AND ' + String.escapeSingleQuotes(k) + ' = null';
                    } else if(value.toLowerCase() == '!null') {
                        whereCondition += ' AND ' + String.escapeSingleQuotes(k) + ' != null';
                    } else {
                        if(value.startsWith('BOOLEAN:')){
                                whereCondition += ' AND ' + String.escapeSingleQuotes(k) + ' = ' +  String.escapeSingleQuotes(value.removeStart('BOOLEAN:'));
                        } else if(value.startsWith('LIKE:')){
                                if (objectName.toLowerCase() == 'fieloplt__member__c' && String.escapeSingleQuotes(k).toLowerCase() == 'name') {
                                    whereCondition += ' AND (' + String.escapeSingleQuotes(k) + ' LIKE \'%' +  String.escapeSingleQuotes(value.removeStart('LIKE:')) + '%\'' +
                                    ' OR FieloPLT__Email__c LIKE \'%' +  String.escapeSingleQuotes(value.removeStart('LIKE:')) + '%\') ';
                                } else {
                                    whereCondition += ' AND ' + String.escapeSingleQuotes(k) + ' LIKE \'%' +  String.escapeSingleQuotes(value.removeStart('LIKE:')) + '%\'';
                                }
                        } else if ( value.startsWith('!') ) {
                                whereCondition += ' AND ' + String.escapeSingleQuotes(k) + ' <> \'' +  String.escapeSingleQuotes(value.substring(1)) + '\'';
                        } else if ( value.startsWith('IN:') ) {
                                string value2 = value.removeStart('IN:');
                                List<String> ids = new List<String>();

                                for(String str: value2.split(',')){
                                    string strc = '\'' + str  + '\'';
                                    ids.add(strc);
                                }
                                whereCondition += ' AND '  + String.escapeSingleQuotes(k) + ' IN ' + ids;
                        } else if ( value.startsWith('FROM:') ) {
                            value = value.removeStart('FROM:');

                            if (objectFields.get(k).getDescribe().getSOAPType().name().tolowercase() == 'double') {
                                List<String> numbers = new List<String>();

                                if (value.contains('TO:')) {
                                    numbers = value.split('TO:');
                                } else {
                                    numbers.add(value);
                                }

                                for (Integer i = 0; i < numbers.size(); i++) {
                                    whereCondition += ' AND ' + String.escapeSingleQuotes(k);
                                    if (i == 0) {
                                        // FROM
                                        whereCondition += ' >= ';
                                    } else {
                                        // TO
                                        whereCondition += ' <= ';
                                    }
                                    whereCondition += numbers[i];
                                }

                            } else {
                                Date tempDate = Date.today();
                                DateTime tempDateTime = DateTime.newInstance(0);
                                List<String> dates = new List<String>();

                                if (value.contains('TO:')) {
                                    dates = value.split('TO:');
                                } else {
                                    dates.add(value);
                                }

                                for (Integer i = 0; i < dates.size(); i++) {
                                    tempDate = Date.valueOf(dates[i]);
                                    tempDateTime = DateTime.newInstance(tempDate.year(), tempDate.month(), tempDate.day());

                                    whereCondition += ' AND ' + String.escapeSingleQuotes(k);
                                    if (i == 0) {
                                        // FROM
                                        whereCondition += ' >= ';
                                    } else {
                                        // TO
                                        whereCondition += ' <= ';
                                    }
                                    if (objectFields.get(k).getDescribe().getType().name().tolowercase() == 'datetime') {
                                        whereCondition += tempDateTime.format('yyyy-MM-dd\'T00:00:00Z\'');
                                    } else {
                                        whereCondition += tempDateTime.format('yyyy-MM-dd');
                                    }
                                }
                            }
                        } else if ( value.startsWith('TO:') ) {
                            Date tempDate = Date.valueOf(value.removeStart('TO:'));
                            DateTime tempDateTime = DateTime.newInstance(tempDate.year(), tempDate.month(), tempDate.day());

                            whereCondition += ' AND '  + String.escapeSingleQuotes(k) + ' <= ' + tempDateTime.format('yyyy-MM-dd\'T00:00:00Z\'') ;
                        } else if ( objectName.tolowercase() == 'FieloPLT__Reward__c' && k.tolowercase() == 'fieloplt__program__c'){
                                whereCondition += ' AND ( ' +
                                    String.escapeSingleQuotes(k) + ' = \'' +  String.escapeSingleQuotes(value) + '\' OR ' +
                                    String.escapeSingleQuotes(k) + ' = null ' +
                                    ')';
                        } else {
                                whereCondition += ' AND ' + String.escapeSingleQuotes(k) + ' = \'' +  String.escapeSingleQuotes(value) + '\'';
                        }
                    }
                }
                if ( whereCondition != '') {
                    whereCondition = ' WHERE ' + whereCondition.substring(4);
                }
            } catch( JSONException e ) {
                system.debug(LoggingLevel.ERROR, 'INVALID JSON ' + filterJson );
            }
        }
        return whereCondition;
    }

    public static String getDependentOptions( List<Schema.PicklistEntry> ctrl_ple, List<Schema.PicklistEntry> dep_ple ){
        Map<String, List<String>> objResults =  new Map<String, List<String>>();
        //iterate through the values and get the ones valid for the controlling field name
        Bitset objBitSet = new Bitset();
        //set up the results
        if(ctrl_ple != null){
          for(Integer pControllingIndex = 0; pControllingIndex < ctrl_ple.size(); pControllingIndex++){
              Schema.PicklistEntry ctrl_entry = ctrl_ple[pControllingIndex];
              String pControllingLabel = ctrl_entry.getValue();
              objResults.put(pControllingLabel,new List<String>());
          }
        }else{
          objResults.put('false',new List<String>());
          objResults.put('true',new List<String>());
        }
        //cater for null and empty
         //objResults.put('',new List<String>());
         //objResults.put(null,new List<String>());
        //check the dependent values
        for(Integer pDependentIndex=0; pDependentIndex<dep_ple.size(); pDependentIndex++){
            //get the pointer to the dependent index
            Schema.PicklistEntry dep_entry = dep_ple[pDependentIndex];
            //get the valid for
            String pEntryStructure = JSON.serialize(dep_entry);
            TPicklistEntry objDepPLE;
            try {
                objDepPLE = (TPicklistEntry)JSON.deserialize(pEntryStructure, TPicklistEntry.class);
            } catch( JSONException e ) {
                system.debug(LoggingLevel.ERROR, 'INVALID JSON: ' + pEntryStructure);
                return null;
            }
            //if valid for is empty, skip
            if (objDepPLE.validFor == null || objDepPLE.validFor == ''){
                continue;
            }
            //iterate through the controlling values
            if(ctrl_ple != null){
              for(Integer pControllingIndex = 0; pControllingIndex < ctrl_ple.size(); pControllingIndex++){
                  if (objBitSet.testBit(objDepPLE.validFor,pControllingIndex)){
                      //get the value
                      String pControllingLabel = ctrl_ple[pControllingIndex].getValue();
                      objResults.get(pControllingLabel).add(objDepPLE.value);
                  }
              }
            }else{
              List<String> booleanValues = new List<String>{'false','true'};
              for(Integer pControllingIndex = 0; pControllingIndex < booleanValues.size(); pControllingIndex++){
                if (objBitSet.testBit(objDepPLE.validFor,pControllingIndex)){
                  objResults.get(booleanValues[pControllingIndex]).add(objDepPLE.value);
                }
              }
            }
        }
        String validFor = '';
        for(String key: objResults.keySet()){
          if(objResults.get(key).size() > 0){
            validFor += ', "' +  key.replace('\'', '/\'') + '": [ "' + String.join( objResults.get(key), '","' ).replace('\'', '/\'')  +  '"]';
          }else{
            validFor += ', "' +  key.replace('\'', '/\'') + '": []';
          }
        }
        if ( validFor != '' ) {
            validFor = '{' + validFor.substring(1) + '}';
        }
        return validFor;
    }

    private class Bitset{
        public Map<String,Integer> AlphaNumCharCodes {get;set;}
        public Map<String, Integer> Base64CharCodes { get; set; }
        public Bitset(){
            LoadCharCodes();
        }
        //Method loads the char codes
        private void LoadCharCodes(){
            AlphaNumCharCodes = new Map<String,Integer>{
              '!'=>33,'\"'=>34, '#'=>35,'$'=>36,'%'=>37,'&'=>38,'\''=>39,'('=>40,')'=>41,'*'=>42,
              '+'=>43,','=>44,'-'=>45, '.'=>46,'/'=>47,'0'=>48,'1'=>49,'2'=>50,'3'=>51,'4'=>52,
              '5'=>53,'6'=>54,'7'=>55,'8'=>56,'9'=>57,':'=>58,';'=>59,'='=>61,'>'=>62,'?'=>63,
              '@'=>64,'A'=>65,'B'=>66,'C'=>67,'D'=>68,'E'=>69,'F'=>70,'G'=>71,'H'=>72,'I'=>73,
              'J'=>74,'K'=>75,'L'=>76,'M'=>77,'N'=>78,'O'=>79,'P'=>80,'Q'=>81,'R'=>82,'S'=>83,
              'T'=>84,'U'=>85,'V'=> 86,'W'=>87,'X'=>88,'Y'=>89,'Z'=>90
            };
            Base64CharCodes = new Map<String, Integer>();
            //lower case
            Set<String> pUpperCase = AlphaNumCharCodes.keySet();
            for(String pKey : pUpperCase){
                //the difference between upper case and lower case is 32
                AlphaNumCharCodes.put(pKey.toLowerCase(),AlphaNumCharCodes.get(pKey)+32);
                //Base 64 alpha starts from 0 (The ascii charcodes started from 65)
                Base64CharCodes.put(pKey,AlphaNumCharCodes.get(pKey) - 65);
                Base64CharCodes.put(pKey.toLowerCase(),AlphaNumCharCodes.get(pKey) - (65) + 26);
            }
            //numerics
            for (Integer i=0; i<=9; i++){
                AlphaNumCharCodes.put(string.valueOf(i),i+48);
                //base 64 numeric starts from 52
                Base64CharCodes.put(string.valueOf(i), i + 52);
            }
          Base64CharCodes.put('+', 62);
          Base64CharCodes.put('/', 63);
        }
        public Boolean testBit(String pValidFor,Integer n){
            //the list of bytes
            List<Integer> pBytes = new List<Integer>();
            //multiply by 6 since base 64 uses 6 bits
            Integer bytesBeingUsed = (pValidFor.length() * 6)/8;
            //will be used to hold the full decimal value
            Integer pFullValue = 0;
            //must be more than 1 byte
            if (bytesBeingUsed <= 1)
                return false;
            //calculate the target bit for comparison
            Integer bit = 7 - (Math.mod(n,8));
            //calculate the octet that has in the target bit
            Integer targetOctet = (bytesBeingUsed - 1) - (n >> bytesBeingUsed);
            //the number of bits to shift by until we find the bit to compare for true or false
            Integer shiftBits = (targetOctet * 8) + bit;
            //get the base64bytes
            for(Integer i=0;i<pValidFor.length();i++){
                //get current character value
                pBytes.Add((Base64CharCodes.get((pValidFor.Substring(i, i+1)))));
            }
            //calculate the full decimal value
            for (Integer i = 0; i < pBytes.size(); i++){
                Integer pShiftAmount = (pBytes.size()-(i+1))*6;//used to shift by a factor 6 bits to get the value
                pFullValue = pFullValue + (pBytes[i] << (pShiftAmount));
            }
            //& is to set the same set of bits for testing
            //shift to the bit which will dictate true or false
            Integer tBitVal = ((Integer)(Math.Pow(2, shiftBits)) & pFullValue) >> shiftBits;
            return  tBitVal == 1;
        }
    }

    private class TPicklistEntry{
        public string active {get;set;}
        public string defaultValue {get;set;}
        public string label {get;set;}
        public string value {get;set;}
        public string validFor {get;set;}
        public TPicklistEntry(){}
    }
}
