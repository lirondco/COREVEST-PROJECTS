public with sharing class OpportunityProductHelper {
  public static final Map<String, String> PRODUCT_GOAL_NAME_MAP = retrieveGoalMapFromMeta();

  public static void afterInsert(List<OpportunityLineItem> newList) {
    List<OpportunityLineItem> oppLinesNewProdGoal = new List<OpportunityLineItem>();
    Set<Integer> monthList = new Set<Integer>();
    Set<Integer> yearList = new Set<Integer>();
    for (OpportunityLineItem ol : newList) {
      if (
        ol.ServiceDate != null &&
        (PRODUCT_GOAL_NAME_MAP.keySet().contains(ol.ProductCode))
      ) {
        monthList.add(ol.ServiceDate.Month());
        yearList.add(ol.ServiceDate.Year());
        oppLinesNewProdGoal.add(ol);
      }
    }
    if (oppLinesNewProdGoal.size() > 0) {
      updateProductGoals(oppLinesNewProdGoal, monthList, yearList);
    }
  }

  public static void afterUpdate(
    Map<Id, OpportunityLineItem> oldMap,
    List<OpportunityLineItem> newList
  ) {
    List<OpportunityLineItem> oppLinesNewProdGoal = new List<OpportunityLineItem>();
    Set<Integer> monthList = new Set<Integer>();
    Set<Integer> yearList = new Set<Integer>();
    for (OpportunityLineItem newOp : newList) {
      OpportunityLineItem oldOp = oldMap.get(newOp.Id);
      if (
        oldOp.ServiceDate != newOp.ServiceDate &&
        PRODUCT_GOAL_NAME_MAP.keySet().contains(newOp.ProductCode)
      ) {
        oppLinesNewProdGoal.add(newOp);
        monthList.add(newOp.ServiceDate.Month());
        yearList.add(newOp.ServiceDate.Year());
      }
    }

    if (oppLinesNewProdGoal.size() > 0) {
      updateProductGoals(oppLinesNewProdGoal, monthList, yearList);
    }
  }

  public static void updateProductGoals(
    List<OpportunityLineItem> oliList,
    Set<Integer> monthList,
    Set<Integer> yearList
  ) {
    Map<String, Map<Integer, Map<Integer, Id>>> goalMap = generateGoalMap(
      monthList,
      yearList
    );
    System.debug(goalMap);

    List<OpportunityLineItem> newOlis = new List<OpportunityLineItem>();
    for (OpportunityLineItem oli : oliList) {
      String prodType = PRODUCT_GOAL_NAME_MAP.get(oli.ProductCode);
      Map<Integer, Map<Integer, Id>> yearMap = goalMap.get(prodType);
      OpportunityLineItem updOli = new OpportunityLineItem(
        Id = oli.Id,
        Product_Goal__c = null
      );
      if (yearMap.size() > 0) {
        Map<Integer, Id> monthMap = yearMap.containsKey(oli.ServiceDate.Year())
          ? yearMap.get(oli.ServiceDate.Year())
          : new Map<Integer, Id>();
        updOli.Product_Goal__c = monthMap.containsKey(oli.ServiceDate.Month())
          ? monthMap.get(oli.ServiceDate.Month())
          : null;
      }
      newOlis.add(updOli);
    }
    if (newOlis.size() > 0) {
      update newOlis;
    }
  }

  public static Map<String, Map<Integer, Map<Integer, Id>>> generateGoalMap(
    Set<Integer> monthList,
    Set<Integer> yearList
  ) {
    Map<String, Map<Integer, Map<Integer, Id>>> returnedMap = new Map<String, Map<Integer, Map<Integer, Id>>>();

    for (String pcode : PRODUCT_GOAL_NAME_MAP.values()) {
      returnedMap.put(pcode, new Map<Integer, Map<Integer, Id>>());
    }

    List<Product_Goal__c> prodGoals = [
      SELECT Id, Product__c, Month_Start_Date__c
      FROM Product_Goal__c
      WHERE
        Product__c IN :PRODUCT_GOAL_NAME_MAP.values()
        AND CALENDAR_MONTH(Month_Start_Date__c) IN :monthList
        AND CALENDAR_YEAR(Month_Start_Date__c) IN :yearList
    ];

    for (Product_Goal__c pg : prodGoals) {
      Map<Integer, Map<Integer, Id>> yearMap = returnedMap.get(pg.Product__c);
      Map<Integer, Id> monthMap = new Map<Integer, Id>();

      monthMap.put(pg.Month_Start_Date__c.Month(), pg.Id);
      yearMap.put(pg.Month_Start_Date__c.Year(), monthMap);
      returnedMap.put(pg.Product__c, yearMap);
    }

    return returnedMap;
  }

  public static Map<String, String> retrieveGoalMapFromMeta() {
    Map<String, String> retMap = new Map<String, String>();

    for (Product_Goal_Map__mdt m : [
      SELECT Goal_Product__c, Opportunity_Product_Code__c
      FROM Product_Goal_Map__mdt
    ]) {
      retMap.put(m.Opportunity_Product_Code__c, m.Goal_Product__c);
    }

    return retMap;
  }
}