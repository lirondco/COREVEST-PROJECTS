public without sharing class SpecialAssetHelper {
    public static void afterUpdate(Map<Id,Special_Asset__c> oldMap, Map<Id, Special_Asset__c> newMap) {
        Set<Id> propertiesToUpdate = new Set<Id>();

        for(Id id : newMap.keySet()) {
            Special_Asset__c o = oldMap.get(id);
            Special_Asset__c n = newMap.get(id);

            if(String.isEmpty(o.Resolution_Type__c) && String.isNotEmpty(n.Resolution_Type__c) && o.Resolved_Date__c == null && n.Resolved_Date__c != null) {
                propertiesToUpdate.add(n.Property__c);
            }
        }

        if(propertiesToUpdate.size() > 0) {
            removeSpecialAssetFromProperties(propertiesToUpdate);
        }
    }

    public static void removeSpecialAssetFromProperties(Set<Id> propIds) {
        List<Property__c> properties = new List<Property__c>();

        for(Id id : propIds) {
            properties.add(new Property__c(
                Id = id,
                Special_Asset__c = null,
                Is_Special_Asset__c = false
            ));
        }

        update properties;
    }
}
