public without sharing class PropertyTriggerExtensions {
 public static List<String> validStatuses = new List<String>{ 'Closing', 'Active' };

  public static void checkStatusChanges(
    Map<Id, Property__c> oldMap,
    Map<Id, Property__c> newMap
  ) {
    Map<Id, Property__c> cxledProperties = new Map<Id, Property__c>();
    Set<Id> advanceIds = new Set<Id>();
    for (Id key : newMap.keySet()) {
      Property__c oP = oldMap.get(key);
      Property__c nP = newMap.get(key);
      if (oP.Status__c != nP.Status__c && nP.Status__c == 'Cancelled') {
        cxledProperties.put(
          key,
          new Property__c(
            Id = key,
            Advance__c = null,
            Initial_Advance__c = null
          )
        );
      }

      if(oP.Status__c != nP.Status__c && validStatuses.contains(nP.Status__c)) {
        advanceIds.add(nP.Initial_Advance__c);
      }
    }

    if (cxledProperties.size() > 0) {
      delete [
        SELECT Id
        FROM Property_Advance__c
        WHERE Property__c IN :cxledProperties.keySet()
      ];

      update cxledProperties.values();
    }

    if(advanceIds.size() >0) {
        updateAdvances(advanceIds);
    }
  }

  public static void checkAdvancesPropertyCount(
    Map<Id, Advance__c> oldMap,
    Map<Id, Advance__c> newMap
  ) {
    List<Id> advancesToDelete = new List<Id>();

    for (Id key : newMap.keySet()) {
      Advance__c oA = oldMap.get(key);
      Advance__c nA = newMap.get(key);
      if (
        oA.Property_Count__c != nA.Property_Count__c &&
        nA.Property_Count__c == 0
      ) {
        advancesToDelete.add(key);
      }
    }

    if (advancesToDelete.size() > 0) {
      delete [SELECT Id FROM Advance__c WHERE Id IN :advancesToDelete];
    }
  }

  public static void checkAdvancePropertyStatuses(
    Map<Id, Property_Advance__c> newMap
  ) {
    Set<Id> advanceIds = new Set<Id>();
    for (Id key : newMap.keySet()) {
      Property_Advance__c pa = newMap.get(key);
      advanceIds.add(pa.Advance__c);
    }

    if (advanceIds.size() > 0) {
        updateAdvances(advanceIds);
    }
  }

  public static void updateAdvances(Set<Id> advanceIds) {

    Map<Id, Advance__c> advances = new Map<Id, Advance__c>(
      [
        SELECT Id, Deal__c, Name
        FROM Advance__c
        WHERE
          Id IN :advanceIds
          AND Name = 'TBD'
          AND Id NOT IN (
            SELECT Advance__c
            FROM Property_Advance__c
            WHERE
              Advance__c IN :advanceIds
              AND Property__r.Status__c NOT IN :validStatuses
          )
      ]
    );
    if (advances.size() > 0) {
      Map<Id, Opportunity> deals = new Map<Id, Opportunity>(
        [
          SELECT
            Id,
            (
              SELECT Id, Name, Advance_Num__c
              FROM Advances__r
              WHERE Name != 'TBD'
              ORDER BY Advance_Num__c DESC
              LIMIT 1
            )
          FROM Opportunity
          WHERE
            Id IN (
              SELECT Deal__c
              FROM Advance__c
              WHERE Id IN :advances.keySet()
            )
        ]
      );
      List<Advance__c> advancesToUpdate = new List<Advance__c>();
      for (Id key : advances.keySet()) {
        Advance__c a = advances.get(key);
        Opportunity d = deals.get(a.Deal__c);
        if (d.Advances__r != null && d.Advances__r.size() > 0) {
          advancesToUpdate.add(
            new Advance__c(
              Id = a.Id,
              Name = String.valueOf(d.Advances__r[0].Advance_Num__c + 1),
              Advance_Num__c = d.Advances__r[0].Advance_Num__c + 1
            )
          );
        } else {
          advancesToUpdate.add(
            new Advance__c(Id = a.Id, Name = '1', Advance_Num__c = 1)
          );
        }
      }
      update advancesToUpdate;
    }
  }
}
