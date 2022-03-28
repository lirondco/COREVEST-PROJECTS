public without sharing class PropertyExtensionHelper {
  public static void afterInsert(Map<Id, Property_Extension__c> newMap) {
    Set<Id> propertyIds = new Set<Id>();

    for (Property_Extension__c pE : newMap.values()) {
      propertyIds.add(pE.Property__c);
    }

    Map<Id, Property__c> propMap = getFirstPropertyExtensions(propertyIds);

    if (propMap.size() > 0) {
      List<Property_Extension__c> propExtensions = new List<Property_Extension__c>();

      for (Property_Extension__c pE : newMap.values()) {
        Property__c p = propMap.get(pE.Property__c);
        if(p.Property_Extensions__r != null && p.Property_Extensions__r[0].Id == pE.Id) {
          Property_Extension__c updatedPe = new Property_Extension__c(Id = pE.Id, Is_First__c = true);
          propExtensions.add(updatedPe);
        }
      }

      if (propExtensions.size() > 0) {
        update propExtensions;
      }
    }
  }

  public static void afterUpdate(
    Map<Id, Property_Extension__c> oldMap,
    Map<Id, Property_Extension__c> newMap
  ) {
    Set<Id> propertyIds = new Set<Id>();
    for(Id key : newMap.keySet()) {
      Property_Extension__c oldPe = oldMap.get(key);
      Property_Extension__c newPe = newMap.get(key);

      if(oldPe.Extension_Date__c != newPe.Extension_Date__c ||
        oldPe.Original_Asset_Maturity_Date_Formula__c != newPe.Original_Asset_Maturity_Date_Formula__c ||
        oldPe.New_Asset_Maturity_Date__c != newPe.New_Asset_Maturity_Date__c) {
        propertyIds.add(newPe.Property__c);
      }

    }

    if(propertyIds.size() > 0) {
      Map<Id, Property__c> propMap = getFirstPropertyExtensions(propertyIds);

      if(propMap.size() > 0) {
        List<Property_Extension__c> propExtensions = new List<Property_Extension__c>();

        for(Property_Extension__c pE : newMap.values()) {
          Property__c p = propMap.get(pE.Property__c);
          Property_Extension__c updatedPe = new Property_Extension__c(Id = pE.Id);
          if(pE.Extension_Date__c != null) {
            // // updatedPe.Days_To_Resolve__c = calculateDaysToResolve(
            //   pE,
            //   p.Property_Extensions__r != null &&
            //   p.Property_Extensions__r.size() > 0 &&
            //   p.Property_Extensions__r[0].Id == pE.Id
            // );

            propExtensions.add(updatedPe);
          }
        }

        if(propExtensions.size() > 0) {
          update propExtensions;
        }
      }
    }
  }

  public static Map<Id, Property__c> getFirstPropertyExtensions(
    Set<Id> propIds
  ) {
    return propIds.size() > 0
      ? new Map<Id, Property__c>(
          [
            SELECT
              Id,
              (
                SELECT Id
                FROM Property_Extensions__r
                ORDER BY CreatedDate ASC
                LIMIT 1
              )
            FROM Property__c
            WHERE Id IN :propIds
          ]
        )
      : new Map<Id, Property__c>();
  }

  public static Integer calculateDaysToResolve(
    Property_Extension__c pE,
    Boolean isFirst
  ) {
      //Original_Asset_Maturity_Date_Formula__c
      //Extension_Date__c
      //New_Asset_Maturity_Date__c
      Date compDate = pE.Extension_Date__c;
      if(isFirst && pE.Original_Asset_Maturity_Date_Formula__c != null) {
        Date origMatureDate = pE.Original_Asset_Maturity_Date_Formula__c;
        Date sixtyDaysPrior = origMatureDate.addDays(-60);
        return sixtyDaysPrior.daysBetween(compDate);
      } else if (!isFirst && pE.New_Asset_Maturity_Date__c != null) {
        Date newAssetDate = pE.New_Asset_Maturity_Date__c;
        Date sixtyDaysPrior = newAssetDate.addDays(-60);
        return sixtyDaysPrior.daysBetween(compDate);
      } else {
        return null;
      }
  }

  public static void forceTrigger(List<Id> dealIds, List<Id> propIds) {
    // List<Property_Extension__c> propExts = [
    //   SELECT Id, Force_Trigger__c
    //   FROM Property_Extension__c
    //   WHERE Property__c IN :propIds
    //   OR Property__r.Deal__c IN :dealIds
    // ];

    // if(propExts.size() > 0) {
    //   for(Property_Extension__c pE : propExts) {
    //     pE.Force_Trigger__c = !pE.Force_Trigger__c;
    //   }
      
    //   update propExts;
  
    // }
  }
}
