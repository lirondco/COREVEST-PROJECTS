public without sharing class SpecialAssetHelper {
  public static final String SNAPSHOT_ENTITY = 'Special Asset Resolved';
  public static Boolean nameIsUpdated = false;
  public static void afterInsert(Map<Id, Special_Asset__c> newMap) {
    Map<String, Map<Id, Special_Asset__c>> forSnapshotMap = new Map<String, Map<Id, Special_Asset__c>>();

    for (Special_Asset__c sa : newMap.values()) {
      if (sa.Resolved_Date__c != null) {
        if (forSnapshotMap.containsKey(SNAPSHOT_ENTITY)) {
          Map<Id, Special_Asset__c> saMap = forSnapshotMap.get(SNAPSHOT_ENTITY);
          saMap.put(sa.id, sa);
          forSnapshotMap.put(SNAPSHOT_ENTITY, saMap);
        } else {
          forSnapshotMap.put(
            SNAPSHOT_ENTITY,
            new Map<Id, Special_Asset__c>{ sa.Id => sa }
          );
        }
      }
    }

    if (forSnapshotMap.size() > 0) {
      PropertySnapshotHelper.createPropertySnapshot(forSnapshotMap);
    }
  }

  public static void afterUpdate(
    Map<Id, Special_Asset__c> oldMap,
    Map<Id, Special_Asset__c> newMap
  ) {
    Set<Id> propertiesToUpdate = new Set<Id>();
    Map<String, Map<Id, Special_Asset__c>> forSnapshotMap = new Map<String, Map<Id, Special_Asset__c>>();

    for (Id id : newMap.keySet()) {
      Special_Asset__c o = oldMap.get(id);
      Special_Asset__c n = newMap.get(id);

      if (o.Resolved_Date__c == null && n.Resolved_Date__c != null) {
        if (String.isNotEmpty(n.Resolution_Type__c)) {
          propertiesToUpdate.add(n.Property__c);
        }

        if (forSnapshotMap.containsKey(SNAPSHOT_ENTITY)) {
          Map<Id, Special_Asset__c> saMap = forSnapshotMap.get(SNAPSHOT_ENTITY);
          saMap.put(id, n);
          forSnapshotMap.put(SNAPSHOT_ENTITY, saMap);
        } else {
          forSnapshotMap.put(
            SNAPSHOT_ENTITY,
            new Map<Id, Special_Asset__c>{ id => n }
          );
        }
      }
    }

    if (propertiesToUpdate.size() > 0) {
      removeSpecialAssetFromProperties(propertiesToUpdate);
    }

    if (forSnapshotMap.size() > 0) {
      PropertySnapshotHelper.createPropertySnapshot(forSnapshotMap);
    }

    if (!nameIsUpdated && propertiesToUpdate.size() > 0) {
      nameIsUpdated = true;
      Map<Id, Property__c> propertyMap = new Map<Id, Property__c>(
        [
          SELECT Id, (SELECT Id FROM Special_Assets__r)
          FROM Property__c
          WHERE Id IN :propertiesToUpdate
        ]
      );
      List<Special_Asset__c> specialAssets = new List<Special_Asset__c>();

      for (Special_Asset__c sa : newMap.values()) {
        if (
          sa.Resolved_Date__c != null &&
          propertyMap.containsKey(sa.Property__c) &&
          propertyMap.get(sa.Property__c).Special_Assets__r != null
        ) {
          Integer saCount = propertyMap.get(sa.Property__c)
            .Special_Assets__r.size();
          String newName = sa.Name + '(' + saCount + ')';
          specialAssets.add(new Special_Asset__c(Id = sa.Id, Name = newName));
        }
      }
      if (specialAssets.size() > 0) {
        update specialAssets;
      }
    }
  }

  public static void removeSpecialAssetFromProperties(Set<Id> propIds) {
    List<Property__c> properties = new List<Property__c>();

    for (Id id : propIds) {
      properties.add(
        new Property__c(
          Id = id,
          Special_Asset__c = null,
          Is_Special_Asset__c = false
        )
      );
    }

    update properties;
  }
}
