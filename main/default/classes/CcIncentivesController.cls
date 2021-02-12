public with sharing class CcIncentivesController {
    // Property declaration
   public static Set<Id> segmentsIds {get;set;}

    @AuraEnabled(cacheable=true)
    public static List<Map<String, Object>> getIncentives(Map<string, Object> params){
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

            //if you need to add a new filter you can edit this map
            List<Map<Object, Object>> listMapFilters = new List<Map<Object, Object>>();
            List<Object> listObjectFilter = params.containsKey('filters') ? (List<Object>) params.get('filters') : new List<Object>();
            for (Object obj : listObjectFilter) {
                listMapFilters.add((Map<Object, Object>)obj);
            }
            String dynamicFilter = !listMapFilters.isEmpty() ? JSON.serialize(listMapFilters) : null;

            if ( fields != null ) {
                List<Object> fieldsChRewardObject = (List<Object>) params.get('fields');
                Set<String> fieldsSet = new Set<String>();
                for(Object field : fieldsChRewardObject){
                    fieldsSet.add(string.valueOf(field));
                }


                Set<String> fieldsChRewardSet = new Set<String>();
                Set<String> fieldsChMemberSet = new Set<String>();
                Set<String> fieldsMission = new Set<String>();
                Set<String> fieldsMissionMember = new Set<String>();
                Set<String> fieldsTransaction = new Set<String>();
                Set<Id> challengeIdsSet = new Set<Id>();

                if( type == 'challenge'){
                    if (setName == 'My Incentives') {
                        setName = 'My Challenges';
                    }
                    List<FieloPLT.ChallengeService.ChallengeWrapper> resultService = FieloPLT.ChallengeService.getChallengesMap(
                        fieldsSet,//fieldsChallenge
                        fieldsMission,//fieldsMission
                        null,//fieldsRanks
                        fieldsChRewardSet,//fieldsChReward
                        fieldsMissionMember,//fieldsMissionMember
                        fieldsChMemberSet,//fieldsChMember
                        fieldsTransaction,//fieldsTransaction
                        null,//challengeIds
                        memberId,//memberId
                        setName,//setName
                        orderBy,//orderBy
                        orderByMemberActivity, //orderByMemberActivity
                        quantity,//quantity
                        offset,//offset
                        dynamicFilter,//dynamicFilter
                        true);
                        if( !resultService.isEmpty() ){
                            for(FieloPLT.ChallengeService.ChallengeWrapper itemChallenge: resultService){
                                Map<String, Object> itemMap = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(itemChallenge));
                                // gets all properties of challenge into the upper level
                                itemMap.putAll((Map<String, Object>) itemMap.get('challenge'));
                                itemMap.put('type', 'challenge');
                                itemMap.remove('challenge');
                                itemMap.remove('attributes');
                                listResult.add(itemMap);
                            }
                        }
                }else if( type == 'promotion' ){
                    if (setName == 'My Incentives') {
                        setName = 'My Promotions';
                    }
                List<Promotion__c> PromotionResult = FieloPLT.PromotionService.getPromotions(
                    fieldsSet,    //  fieldsPromotion,
                    null,   //     fieldsRule,
                    null,   //     promotionIds,
                    memberId,   // memberId,
                    false,   //    filterBySegments,
                    orderBy,   //  orderBy,
                    quantity,   // quantity,
                    offset,   //   offset,
                    dynamicFilter, //       dynamicFilter
                    true, //      Boolean translate,
                    setName //     setName
                );

                if( !PromotionResult.isEmpty()){
                    // get the segments the member applies: manuals, dynamics and meta
                    segmentsIds = SegmentService.calculateMemberSegments(memberId, null);
                    segmentsIds.add(null);

                    for( Promotion__c itemPromotion: PromotionResult){
                        Map<String, Object> itemMap = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(itemPromotion));
                        itemMap.put('type', 'promotion');
                        itemMap.put('eligible', false);
                        if(segmentsIds.contains((Id) itemMap.get('FieloPLT__Segment__c'))) {
                            itemMap.put('eligible', true);
                            }
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
    public static IncentiveWrapper getIncentiveDetail(Map<string, Object> params){
        IncentiveWrapper incentive ;
        List<FieloPLT.ChallengeService.ChallengeWrapper> resultService = new List<FieloPLT.ChallengeService.ChallengeWrapper>();
        List<Promotion__c> PromotionResult = new List<Promotion__c>();
        if( !params.isEmpty() || params != null){
            String type = params.containsKey('type') ? string.valueOf(params.get('type')).toLowerCase() : '';
            String Id = params.containsKey('id') ? string.valueOf(params.get('id')) : '';
            Id memberId = params.containsKey('memberId') ? (Id) params.get('memberId') : null;

            if ( String.isNotEmpty(type) && String.isNotEmpty(Id) ) {
                set<Id>incentiveId = new set<Id>();
                incentiveId.add(Id);

                if( type == 'challenge'){
                    set<String> fieldsMission = new set<String>{'id','name','FieloPLT__Description__c','FieloPLT__StartDate__c','FieloPLT__EndDate__c','FieloPLT__MinValue__c','FieloPLT__MaxValue__c','FieloPLT__Type__c','FieloPLT__Status__c','FieloPLT__ObjectiveType__c','FieloPLT__Operator__c','FieloPLT__ObjectiveValue__c','FieloPLT__ObjectiveField__c','FieloPLT__ValueMode__c','FieloPLT__LeaderboardMode__c'};
                    set<string> fieldsRanks = new set<String>{'Name','FieloPLT__MaintainMissionList__c', 'FieloPLT__IsActive__c'};
                    Set<String> fieldsMissionMember = new Set<String>{'FieloPLT__Mission__c','FieloPLT__Counter__c','FieloPLT__Summary__c','FieloPLT__Goal__c'};
                    resultService = FieloPLT.ChallengeService.getChallengesMap(
                        null,//fieldsChallenge
                        fieldsMission,//fieldsMission
                        fieldsRanks,//fieldsRanks
                        null,//fieldsChReward
                        fieldsMissionMember,//fieldsMissionMember
                        null,//fieldsChMember
                        null,//fieldsTransaction
                        incentiveId,//challengeIds
                        memberId,//memberId
                        null,//setName
                        null,//orderBy
                        null, //orderByMemberActivity
                        null,//quantity
                        null,//offset
                        null,//dynamicFilter
                        true);
                        Map<String, Object> itemMap = new Map<String, Object>();
                        if( !resultService.isEmpty() ){
                            incentive = new IncentiveWrapper(resultService.get(0));
                        }
                }else if( type == 'promotion' ){
                    set<String> fieldsRule = new set<String>{'Id','Name','FieloPLT__Description__c'};
                    List<Promotion__c> promotionDetails = FieloPLT.PromotionService.getPromotions(
                        null,
                        fieldsRule,
                        incentiveId,
                        memberId,
                        false,
                        null,
                        null,
                        null,
                        null,
                        true, //      Boolean translate,
                        null //  setName
                    );
                    if( !promotionDetails.isEmpty()){
                        incentive = new IncentiveWrapper(promotionDetails.get(0));
                    }
                }
            }
        }
        return incentive;
    }

    @auraEnabled
    public static Boolean enroll(Map<string, Object>  params) {
        Id agreementId = params.containsKey('agreementId') ? (Id) params.get('agreementId') : null;
        Id memberId = params.containsKey('memberId') ? (Id) params.get('memberId') : null;
        Id incentiveId = params.containsKey('incentiveId') ? (Id) params.get('incentiveId') : null;
        String type = params.containsKey('type') ? (String) params.get('type') : null;

        try{
            Boolean agreed = true;
            if(agreementId != null) {
                agreed = AgreementService.acceptAgreement(agreementId, memberId, incentiveId);
            }

            if(agreed && type == 'challenge') {
                ChallengeMember__c challengeMember =
                    FieloPLT.ChallengeService.subscribeToChallenge(memberId, incentiveId);
            }

           return true;
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

    public class IncentiveWrapper{
        @AuraEnabled public sObject incentive {get; private set;}
        @AuraEnabled public string type {get; private set;}
        @AuraEnabled public List<ChallengeMember__c> challengeMembers {get; private set;}
        @AuraEnabled public List<Mission__c> missions {get; private set;}
        @AuraEnabled public Map<Id,List<MissionMember__c>> mapChMemberIdListMissionMember {get; private set;}
        @AuraEnabled public List<Rule__c> rules {get; private set;}
        @AuraEnabled public Boolean eligible {get; private set;}
        @AuraEnabled public Map<Id, Progress> progress {get; private set;}//key: MemberId

        public IncentiveWrapper(FieloPLT.ChallengeService.ChallengeWrapper challengeWrapper){
            if(challengeWrapper != null){
                Map<Id, Member__c>  mapMembers = new Map<Id, Member__c>();
                Map<Id, Map<Id, MissionMember__c>> mapIdMissionMissionMemberByMember = new Map<Id, Map<Id, MissionMember__c>>();
                Map<Id, Progress> mapProgress = new Map<Id, Progress>();//key: memberid
                this.incentive = challengeWrapper.challenge;
                this.eligible = challengeWrapper.eligible;
                this.missions = challengeWrapper.missions;
                this.mapChMemberIdListMissionMember = challengeWrapper.mapChMemberIdListMissionMember;
                this.challengeMembers = challengeWrapper.teamChallengesMembers;
                this.type = 'challenge';
                mapMembers = getMembers(this.missions, this.challengeMembers);

                if(this.challengeMembers != null && !this.challengeMembers.isEmpty()){
                    for(ChallengeMember__c chM: this.challengeMembers){
                        mapIdMissionMissionMemberByMember.put(chM.Member__c, new Map<Id, MissionMember__c>());
                        if(this.mapChMemberIdListMissionMember.containsKey(chM.Id)){
                            for(MissionMember__c mm: this.mapChMemberIdListMissionMember.get(chM.Id)){
                                mapIdMissionMissionMemberByMember.get(chM.Member__c).put(mm.Mission__c, mm);
                            }
                        }
                    }
                    for(Id memberId: mapIdMissionMissionMemberByMember.keySet()){
                        Progress progress = new Progress();
                        Map<Id, Mission> mapMissionProgress = new Map<Id, Mission>();
                        for(Mission__c mission: this.missions){
                            Mission mc = new Mission();
                            mc.type = mission.FieloPLT__Type__c;
                            mc.ObjectiveType = mission.ObjectiveType__c;
                            mc.status = mission.Status__c;
                            if(mapIdMissionMissionMemberByMember.get(memberId).containskey(mission.Id) && mission.ObjectiveType__c == 'Counter'){
                                mc.value = mapIdMissionMissionMemberByMember.get(memberId).get(mission.Id).Counter__c;
                            }else if(mapIdMissionMissionMemberByMember.get(memberId).containskey(mission.Id) && mission.ObjectiveType__c == 'Summary'){
                                mc.value = mapIdMissionMissionMemberByMember.get(memberId).get(mission.Id).Summary__c;
                            }else{
                                //si no tiene missionmember
                                mc.value = 0;
                            }
                            if(mission.FieloPLT__Type__c == 'With Objective'){
                                if(mission.ValueMode__c == 'Dynamic' && !String.isBlank(mission.ObjectiveField__c)){
                                    mc.objectiveValue = (Decimal) mapMembers.get(memberId).get(mission.ObjectiveField__c) != null ? (Decimal) mapMembers.get(memberId).get(mission.ObjectiveField__c) : 0;
                                }else if(mission.ValueMode__c == 'Fixed' && mission.FieloPLT__ObjectiveValue__c != null){
                                    mc.objectiveValue = mission.ObjectiveValue__c;
                                }else if(mission.ValueMode__c == 'HistoricalData'){
                                    if(mapIdMissionMissionMemberByMember.get(memberId).containskey(mission.Id) && mapIdMissionMissionMemberByMember.get(memberId).get(mission.Id).Goal__c != null){
                                        mc.objectiveValue = mapIdMissionMissionMemberByMember.get(memberId).get(mission.Id).Goal__c;
                                    }else{
                                        mc.objectiveValue = 0;
                                    }
                                }
                            } else {
                                mc.objectiveValue = 0;
                            }
                            mapMissionProgress.put(mission.Id, mc);
                        }
                        progress.missions = mapMissionProgress;
                        mapProgress.put(memberId, progress);
                    }
                }
                this.progress = mapProgress;
            }
        }

        public IncentiveWrapper(Promotion__c promotion){
            this.incentive = promotion;
            this.rules = null;
            this.eligible = false;
            this.type = 'promotion';
            // TODO: when uncommented make sure we are getting the field
            // if(segmentsIds.contains((Id) promotion.FieloPLT__Segment__c)) {
            //     this.eligible = false;
            // }
            // add Rules
            if(!promotion.fieloplt__rules__r.isEmpty()) {
                this.rules = promotion.fieloplt__rules__r;
            }

        }
    }

    public class Progress{
        @AuraEnabled public Map<Id, Mission> missions {get; private set;}//key idmission

        public Progress(){
            this.missions = null;
        }
    }
    public class Mission{
        @AuraEnabled public String type {get; private set;}
        @AuraEnabled public String status {get; private set;}
        @AuraEnabled public String ObjectiveType {get; private set;}//ObjectiveType__c
        @AuraEnabled public Decimal value {get; private set;}
        @AuraEnabled public Decimal objectiveValue {get; private set;}

        public Mission(){
            this.type = null;
            this.status = null;
            this.value = null;
            this.objectiveValue = null;
        }
    }

    private static Map<Id, Member__c> getMembers(List<Mission__c> missions, List<ChallengeMember__c> challengeMembers){
        Set<Id> membersId = new Set<Id>();
        Set<String> ObjectiveFields = new Set<String>();
        Map<Id, FieloPLT__Member__c> members = new Map<Id, FieloPLT__Member__c>();
        if(challengeMembers == null){
            return members;
        }
        for(ChallengeMember__c chm: challengeMembers){
            membersId.add(chm.Member__c);
        }

        for(Mission__c mission: missions){
            if(mission.Type__c == 'With Objective'){
                if(mission.FieloPLT__ValueMode__c == 'Dynamic' && !String.isBlank(mission.ObjectiveField__c)){
                    ObjectiveFields.add(mission.ObjectiveField__c);
                }
            }
        }

        if(!ObjectiveFields.isEmpty()){
            //querymember
            String querymember = 'SELECT Id,' + String.join(new List<String>(ObjectiveFields), ',') + ' FROM FieloPLT__Member__c WHERE Id IN: membersId';
            members = new Map<Id, FieloPLT__Member__c>((List<FieloPLT__Member__c>)Database.query(querymember));
        }
        return members;
    }
}
