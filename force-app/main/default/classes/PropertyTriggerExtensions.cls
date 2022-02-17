public without sharing class PropertyTriggerExtensions {
    public static void checkStatusChanges(Map<Id, Property__c> oldMap, Map<Id,Property__c> newMap) {
        Map<Id, Property__c> cxledProperties = new Map<Id,Property__c>();
        for(Id key : newMap.keySet()) {
            Property__c oP = oldMap.get(key);
            Property__c nP = newMap.get(key);
            if(oP.Status__c != nP.Status__c && nP.Status__c == 'Cancelled') {
                cxledProperties.put(key, new Property__c(
                    Id = key,
                    Advance__c = null,
                    Initial_Advance__c = null
                ));
            }
        }

        if(cxledProperties.size() > 0) {
            delete [
             SELECT Id FROM Property_Advance__c WHERE Property__c IN :cxledProperties.keySet()
            ];

            update cxledProperties.values();
        }
    }

    public static void checkAdvancesPropertyCount(Map<Id, Advance__c> oldMap, Map<Id, Advance__c> newMap) {
        List<Id> advancesToDelete = new List<Id>();

        for(Id key : newMap.keySet()) {
            Advance__c oA = oldMap.get(key);
            Advance__c nA = newMap.get(key);
            if(oA.Property_Count__c != nA.Property_Count__c && nA.Property_Count__c == 0) {
                advancesToDelete.add(key);
            }
        }

        if(advancesToDelete.size() > 0) {
            delete [
             SELECT Id FROM Advance__c WHERE Id IN :advancesToDelete
            ];
        }
    }
}
