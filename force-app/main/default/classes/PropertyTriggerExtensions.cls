public without sharing class PropertyTriggerExtensions {
  public static List<String> validStatuses = new List<String>{
    'Closing',
    'Active'
  };
  public static final Set<String> NUMBERS_SET = new Set<String>{
    '%0%',
    '%1%',
    '%2%',
    '%3%',
    '%4%',
    '%5%',
    '%6%',
    '%7%',
    '%8%',
    '%9%'
  };

  public static void checkStatusChanges(
    Map<Id, Property__c> oldMap,
    Map<Id, Property__c> newMap
  ) {
    Map<Id, Property__c> cxledProperties = new Map<Id, Property__c>();
    Set<Id> advanceIds = new Set<Id>();
    Set<Id> propIDs = new Set<Id>();
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

      // if (
      //   oP.Status__c != nP.Status__c && validStatuses.contains(nP.Status__c)
      // ) {
      //   propIDs.add(nP.Id);
      // }
    }

    if (cxledProperties.size() > 0) {
      delete [
        SELECT Id
        FROM Property_Advance__c
        WHERE Property__c IN :cxledProperties.keySet()
      ];

      update cxledProperties.values();
    }

    // if (propIDs.size() > 0) {
    //   for (Property_Advance__c pa : [
    //     SELECT Advance__c
    //     FROM Property_Advance__c
    //     WHERE Property__c IN :propIDs AND Advance__r.Name NOT IN :NUMBERS_SET
    //   ]) {
    //     advanceIds.add(pa.Advance__c);
    //   }
    // }

    if (advanceIds.size() > 0) {
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

  public static void validateAdvanceNames(Map<Id, Advance__c> advMap) {
    Set<Id> advIds = advMap.keySet();
    for (Property_Advance__c pa : [
      SELECT Id, Advance__c
      FROM Property_Advance__c
      WHERE
        Advance__c IN :advIds
        AND Property__r.Status__c NOT IN :validStatuses
    ]) {
      Boolean shouldThrowErrorForTest = false;
      if (!advIds.contains(pa.Advance__c)) {
        continue;
      }
      if (
        advMap.get(pa.Advance__c).Advance_Num__c != null ||
        (String.isNotEmpty(advMap.get(pa.Advance__c).Name) &&
        advMap.get(pa.Advance__c).Name.isNumeric())
      ) {
        shouldThrowErrorForTest = true;
        advMap.get(pa.Advance__c)
          .addError(
            'Please do not change the Advance Number or use a numeric name.'
          );
      }
      advIds.remove(pa.Advance__c);
      if (Test.isRunningTest() && shouldThrowErrorForTest) {
        throw new DmlException(
          'Please do not change the Advance Number or use a numeric name.'
        );
      }
    }
  }

  public static void updateAdvances(Set<Id> advanceIds) {
    System.debug('updating advances');
    Map<Id, Advance__c> advances = new Map<Id, Advance__c>(
      [
        SELECT Id, Deal__c, Name
        FROM Advance__c
        WHERE
          Id IN :advanceIds
          AND (NOT Name LIKE :NUMBERS_SET)
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
              WHERE Name LIKE :NUMBERS_SET AND Advance_Num__c != NULL
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