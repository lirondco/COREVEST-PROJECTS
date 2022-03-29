public without sharing class PropertySnapshotHelper {
    public static final List<String> PROPERTY_ENTITY_TYPES = new List<String>{
        'Asset Paid Off',
        'Asset Sold'
    };

    public static final String PROP_EXT_ENTITY_NAME = 'Extension Completed';

    public static final String SPEC_ASSET_ENTITY_NAME = 'Special Asset Resolved';

    public static void createPropertySnapshot(Map<String, Map<Id, sObject>> entityTypeMap) {
        List<Property_Snapshot__c> propSnapshots = new List<Property_Snapshot__c>();
        
        for(String key : entityTypeMap) {
            Map<Id,sObject> sobjectMap = entityTypeMap.get(key);
            Property_Snapshot__c propSnapshot = new Property_Snapshot__c(Entity_Type__c = key);
            if(PROPERTY_ENTITY_TYPES.contains(key)) {
                // do something
            } else if (key == PROP_EXT_ENTITY_NAME) {
                // do something else
            } else if (key == SPEC_ASSET_ENTITY_NAME) {
                // do something else
            }
        }

    }
}
