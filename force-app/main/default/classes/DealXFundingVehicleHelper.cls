public without sharing class DealXFundingVehicleHelper {

  public static void beforeInsert(List<Deal_x_Funding_Vehicle__c> newList) {

    // Set<Id> fvIdsToCheck = new Set<Id>();

    for (Deal_x_Funding_Vehicle__c x : newList) {
      if(!x.Include_Yes_No__c) {
        // fvIdsToCheck.add(x.Funding_Vehicle__c);
      }
    }
  
    // Set<Id> fvSecIds = filterForSecuritizations(fvIdsToCheck);

    // for (Deal_x_Funding_Vehicle__c x : newList) {
    //   if(!x.Include_Yes_No__c && fvSecIds.contains(x.Funding_Vehicle__c)) {
    //     x.Include_Yes_No__c = true;
    //   }
    // }


  }

  public static void afterUpdate(
    Map<Id, Deal_x_Funding_Vehicle__c> oldMap,
    List<Deal_x_Funding_Vehicle__c> newList
  ) {
    Map<Id, Boolean> toggledDeals = new Map<Id, Boolean>();
    List<Id> toggledFundingVehicles = new List<Id>();

    for (Deal_x_Funding_Vehicle__c n : newList) {
      Deal_x_Funding_Vehicle__c o = oldMap.get(n.Id);
      if (
        n.Funding_Vehicle__c != null &&
        n.Deal__c != null &&
        o.Include_Yes_No__c !=
        n.Include_Yes_No__c
      ) {
        toggledFundingVehicles.add(n.Funding_Vehicle__c);
        toggledDeals.put(n.Deal__c, n.Include_Yes_No__c);
      }
    }

    if (toggledDeals.size() > 0 && toggledFundingVehicles.size() > 0) {
      toggleDealSecuritisation(toggledDeals, toggledFundingVehicles);
    }
  }

  public static void toggleDealSecuritisation(
    Map<Id, Boolean> dealToggledMap,
    List<Id> fvIds
  ) {
    Map<Id, Securitization__c> securitizationMap = new Map<Id, Securitization__c>(
      [
        SELECT Id
        FROM Securitization__c
        WHERE
          Id IN (
            SELECT Securitization__c
            FROM Funding_Vehicle__c
            WHERE Id IN :fvIds
          )
      ]
    );

    if (securitizationMap.size() > 0) {
      List<Opportunity> updatedDeals = new List<Opportunity>();

      for (Opportunity o : [
        SELECT Id, Securitization__c
        FROM Opportunity
        WHERE
          Id IN :dealToggledMap.keySet()
          AND Securitization__c IN :securitizationMap.keySet()
      ]) {
        o.Securitized__c = dealToggledMap.get(o.Id);
        // o.Securitization__c = null;
        updatedDeals.add(o);
      }

      if (updatedDeals.size() > 0) {
        update updatedDeals;
      }
    }
  }
  
  public static Set<Id> filterForSecuritizations(Set<Id> fvIds) {
    Map<Id, Funding_Vehicle__c> fvMap = new Map<Id, Funding_Vehicle__c>([
      SELECT Id
      FROM Funding_Vehicle__c
      WHERE Securitization__c != NULL
      AND Id IN :fvIds
    ]);

    return fvMap.keySet();
  }
}