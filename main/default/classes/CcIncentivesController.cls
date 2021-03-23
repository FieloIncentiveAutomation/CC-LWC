public with sharing class CcIncentivesController {

    @AuraEnabled(cacheable=true)
    public static List<Map<String, Object>> getIncentives(Map<string, Object> params){
        List<IncentivesAPI.IncentiveWrapper> results = new List<IncentivesAPI.IncentiveWrapper>();
        List<Map<String,Object>> listResult = new List<Map<String,Object>>();
        if( !params.isEmpty() || params != null) {
            // Set default params
            String  type = params.containsKey('type') ? string.valueOf(params.get('type')).toLowerCase() : '';
            Integer offset = params.containsKey('offset') ? Integer.valueOf(params.get('offset')) : 0;
            Integer quantity = params.containsKey('recordsPerPage') ? Integer.valueOf(params.get('recordsPerPage')) : 8;
            String  orderByMemberActivity = params.containsKey('orderByMemberActivity') ? String.valueOf(params.get('orderByMemberActivity')) : null;
            String  orderBy = params.containsKey('orderBy') ? String.valueOf(params.get('orderBy')) : null;
            String setName = params.containsKey('setName') ? String.valueOf (params.get('setName')) : null;
            Id memberId = params.containsKey('memberId') ? String.valueOf((params.get('memberId'))) : null;
            String fields = params.containsKey('fields') ? String.valueOf (params.get('fields')) : null;

            List<Map<Object, Object>> listMapFilters = new List<Map<Object, Object>>();
            List<Object> listObjectFilter = params.containsKey('filters') ? (List<Object>) params.get('filters') : new List<Object>();
            for (Object obj : listObjectFilter) {
                listMapFilters.add((Map<Object, Object>)obj);
            }
            String dynamicFilter = !listMapFilters.isEmpty() ? JSON.serialize(listMapFilters) : null;

            if ( fields != null ) {
                List<Object> fieldsObject = (List<Object>) params.get('fields');
                Set<String> fieldsSet = new Set<String>();
                for(Object field : fieldsObject){
                    fieldsSet.add(string.valueOf(field));
                }

                if( type == 'challenge'){
                    if (setName == 'My Incentives') {
                        setName = 'My Challenges';
                    }
                    results = FieloPLT.IncentivesAPI.getIncentives(
                        'challenge',
                        memberId,
                        null,
                        setName,
                        new Map<String, Set<String>>{'challenge' => fieldsSet},
                        new Map<String, String>{'challenge' => dynamicFilter},
                        new Map<String, String>{'orderbychallenge' => orderBy, 'orderByMemberActivity' => orderByMemberActivity},
                        quantity,
                        offset,
                        true,
                        false,
                        false);
                    if(!results.isEmpty()){
                        for(IncentivesAPI.IncentiveWrapper itemChallenge: results){
                            Map<String, Object> itemMap = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(itemChallenge));
                            // gets all properties of challenge into the upper level
                            itemMap.putAll((Map<String, Object>) itemMap.get('incentive'));
                            itemMap.put('type', 'challenge');
                            itemMap.remove('incentive');
                            itemMap.remove('attributes');
                            listResult.add(itemMap);
                        }
                    }
                }else if( type == 'promotion' ){
                    if (setName == 'My Incentives') {
                        setName = 'My Promotions';
                    }
                    results = FieloPLT.IncentivesAPI.getIncentives(
                        'promotion',
                        memberId,
                        null,
                        setName,
                        new Map<String, Set<String>>{'promotion' => fieldsSet},
                        new Map<String, String>{'promotion' => dynamicFilter},
                        new Map<String, String>{'orderbypromotion' => orderBy},
                        quantity,
                        offset,
                        true,
                        false,
                        false);
                    if(!results.isEmpty()){
                        for(IncentivesAPI.IncentiveWrapper itemPromotion: results){
                            Map<String, Object> itemMap = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(itemPromotion));
                            itemMap.putAll((Map<String, Object>) itemMap.get('incentive'));
                            itemMap.put('type', 'promotion');
                            itemMap.remove('incentive');
                            itemMap.remove('attributes');
                            listResult.add(itemMap);
                        }
                    }
                }
            }
        }
        return listResult;
    }

    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getIncentiveDetail(Map<string, Object> params){
        List<IncentivesAPI.IncentiveWrapper> incentives = new List<IncentivesAPI.IncentiveWrapper>();
        Map<String, Object> incentive = new Map<String, Object>();
        if( !params.isEmpty() || params != null){
            String type = params.containsKey('type') ? string.valueOf(params.get('type')).toLowerCase() : '';
            String incentiveId = params.containsKey('id') ? string.valueOf(params.get('id')) : '';
            Id memberId = params.containsKey('memberId') ? (Id) params.get('memberId') : null;

            Map<String, Set<String>> fieldsMap = new Map<String, Set<String>>();
            if (String.isNotEmpty(type) && String.isNotEmpty(incentiveId) ) {
                if(type == 'challenge'){
                    set<String> fieldsMission = new set<String>{'Id','Name','FieloPLT__Description__c'};
                    fieldsMap.put('mission', fieldsMission);
                }else if(type == 'promotion' ){
                    set<String> fieldsRule = new set<String>{'Id','Name','FieloPLT__Description__c'};
                    fieldsMap.put('rule', fieldsRule);
                }else{
                    return incentive;
                }
                // Incentive Detail
                incentives = FieloPLT.IncentivesAPI.getIncentives(type,
                                                                    memberId,
                                                                    new Set<Id>{incentiveId},
                                                                    null,
                                                                    fieldsMap,
                                                                    null,
                                                                    null,
                                                                    null,
                                                                    null,
                                                                    true,
                                                                    true,
                                                                    false);
                if(!incentives.isEmpty()){
                    incentive = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(incentives?.get(0)));
                    // gets all properties of challenge into the upper level
                    incentive.putAll((Map<String, Object>) incentive.get('incentive'));
                    incentive.put('type', 'challenge');
                    incentive.remove('incentive');
                    incentive.remove('attributes');
                    return incentive;
                }
            }
        }
        return incentive;
    }

    @auraEnabled
    public static Boolean enroll(Map<string, Object>  params) {
        Id memberId = params.containsKey('memberId') ? (Id) params.get('memberId') : null;
        Id incentiveId = params.containsKey('incentiveId') ? (Id) params.get('incentiveId') : null;

        try{
            Map<Id,Map<Id, String>> errorMessageMap = FieloPLT.IncentivesAPI.enroll(new Map<Id, Set<Id>>{memberId => new Set<Id>{incentiveId}}, false);
            if(!errorMessageMap.isEmpty()){
                return true;
            }else{
                return false;
            }
        } catch(DMLException e) {
            throw new AuraHandledException(e.getDMLMessage(0));
        } catch(Exception e){
            throw new AuraHandledException(e.getMessage());
        }
    }

    @auraEnabled
    public static List<FieloPLT__MissionMember__c> getMissionLeaderboard(Map<string, Object>  params){
        try{
            Set<String> fieldsMissionMember = new Set<String> {
                'FieloPLT__LeaderboardPosition__c',
                'FieloPLT__ChallengeMember__r.FieloPLT__Member__r.FieloPLT__ExternalURL__c',
                'FieloPLT__ChallengeMember__r.FieloPLT__Member__r.Name',
                'FieloPLT__ChallengeMember__r.FieloPLT__Member__r.FieloPLT__CurrentLevelMember__r.FieloPLT__Level__r.Name'
            };

        	List<FieloPLT__MissionMember__c> missionLeaderboard = ChallengeService.getMissionLeaderboard(
                fieldsMissionMember,
                (Id) params.get('missionId'),
                (Id) params.get('memberId'),
                null,
                3,
                0,
                ''
            );
            return missionLeaderboard;
        } catch(Exception e){
            throw new AuraHandledException(e.getMessage());
        }
    }
}
