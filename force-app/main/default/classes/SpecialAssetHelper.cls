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

  public static void beforeUpdate(
    Map<Id, Special_Asset__c> oldMap,
    Map<Id, Special_Asset__c> newMap
  ) {
    Set<Id> propIds = new Set<Id>();
    for (Special_Asset__c sa : newMap.values()) {
      Special_Asset__c oldSa = oldMap.get(sa.id);
      if (
        (sa.REO_Date__c != null && oldSa.REO_date__c != sa.REO_Date__c) ||
        (sa.REO_Sell_Date__c != null &&
        oldSa.REO_Sell_Date__c != sa.REO_Sell_Date__c) 
      ) {
        sa.Resolved_Date__c = sa.REO_Date__c != null
          ? sa.REO_Date__c
          : sa.REO_Sell_Date__c;
        if (sa.REO_Sell_Date__c != null) {
          propIds.add(sa.Property__c);
        }
      }
    }

    if (propIds.size() > 0) {
      Map<Id, Property__c> propMap = new Map<Id, Property__c>(
        [
          SELECT
            Id,
            (
              SELECT REO_Date__c
              FROM Special_Assets__r
              WHERE REO_Date__c != NULL
              ORDER BY CreatedDate DESC
              LIMIT 1
            )
          FROM Property__c
          WHERE Id IN :propIds
        ]
      );

      if (propMap.size() > 0) {
        for (Special_Asset__c sa : newMap.values()) {
          if (
          propMap.containsKey(sa.Property__c) &&
            propMap.get(sa.Property__c).Special_Assets__r != null &&
            propMap.get(sa.Property__c).Special_Assets__r.size() > 0
          ) {
            sa.Days_to_Resolve_REO_to_REO_Sold__c = propMap.get(sa.Property__c)
            .Special_Assets__r[0]
            .REO_Date__c.daysBetween(sa.REO_Sell_Date__c);
          }
        }
      }
    }
  }

  public static void afterUpdate(
    Map<Id, Special_Asset__c> oldMap,
    Map<Id, Special_Asset__c> newMap
  ) {
    Set<Id> propertiesToUpdate = new Set<Id>();
    Map<String, Map<Id, Special_Asset__c>> forSnapshotMap = new Map<String, Map<Id, Special_Asset__c>>();
    Map<Id, Special_Asset__c> forForeclosure = new Map<Id, Special_Asset__c>();

    for (Id id : newMap.keySet()) {
      Special_Asset__c o = oldMap.get(id);
      Special_Asset__c n = newMap.get(id);

      if (n.REO_Date__c != o.REO_Date__c) {
        forForeclosure.put(id, n);
      }

      if (String.isNotEmpty(n.Resolution_Type__c) && n.Resolved_Date__c != null && (
        n.Resolved_Date__c != o.Resolved_Date__c || n.Resolution_Type__c != o.Resolution_Type__c
      )) {
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

    if(forForeclosure.size() > 0) {
      updateForeclosureRecords(forForeclosure);
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

  public static void updateForeclosureRecords(Map<Id, Special_Asset__c> saMap) {
    List<Foreclosure__c> relatedForclosures = [
      SELECT Id, REO_Date__c, Special_Asset__c
      FROM Foreclosure__c
      WHERE Special_Asset__c IN :saMap.keySet()
      FOR UPDATE
    ];

    List<Foreclosure__c> toUpdate = new List<Foreclosure__c>();

    if (relatedForclosures.size() > 0) {
      for (Foreclosure__c foreclosure : relatedForclosures) {
        if(foreclosure.REO_Date__c != saMap.get(foreclosure.Special_Asset__c).REO_Date__c) {
        foreclosure.REO_Date__c = saMap.get(foreclosure.Special_Asset__c).REO_Date__c;
        toUpdate.add(foreclosure);
        }
      }
      if(toUpdate.size() > 0) {
        update toUpdate;

      }
    }

  }
}
