trigger SpecialAssetTrigger on Special_Asset__c (after update) {
  if(Trigger.isAfter && Trigger.isUpdate) {
    SpecialAssetHelper.afterUpdate(Trigger.oldMap, Trigger.newMap);
  }
}