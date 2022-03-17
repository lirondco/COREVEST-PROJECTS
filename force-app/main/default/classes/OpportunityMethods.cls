public without sharing class OpportunityMethods {
    public static void updatePaidOffProperties(Map<Id,Opportunity> dealMap) {
        List<Property__c> propertiesForUpdate = [
            SELECT Id, Status__c, Deal__c, Inactive_Date__c FROM Property__c WHERE Deal__c IN :dealMap.keySet() FOR UPDATE
        ];

        if (propertiesForUpdate.size() > 0) {
            for(Property__c p : propertiesForUpdate) {
                p.Status__c = 'Paid Off';
                p.Inactive_Date__c = dealMap.get(p.Deal__c).Payoff_Date__c;
            }
            
            update propertiesForUpdate;
        }
    }
}
