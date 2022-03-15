trigger property_Trigger on Property__c(
  before insert,
  before update,
  before delete,
  after insert,
  after update,
  after delete,
  after undelete
) {
  Settings__mdt settings = Settings__mdt.getInstance('Universal_Settings');
  if (!settings.Disable_Property_Trigger__c) {
    if (Trigger.isBefore && Trigger.isInsert) {
      Property_Helper.beforeInsert(Trigger.New);
    }
    if (Trigger.isAfter && Trigger.isInsert) {
      Property_Helper.afterInsert(Trigger.New);
      ChecklistHelper.createChecklistSectionProperty(Trigger.newMap.keySet());
    }
    if (
      Trigger.isBefore &&
      Trigger.isUpdate &&
      !property_Helper.hasBeforeUpdateRun
    ) {
      // property_Helper.hasBeforeUpdateRun=true;
      Property_Helper.beforeUpdate(Trigger.New, Trigger.Old);
    }
    if (
      Trigger.isAfter &&
      Trigger.isUpdate &&
      !property_Helper.hasafterUpdateRun
    ) {
      // property_Helper.hasafterUpdateRun=true;
		Property_Helper.afterUpdate(Trigger.New, Trigger.Old);
    // PropertyTriggerExtensions.checkStatusChanges(Trigger.oldMap, Trigger.newMap);
    }
    if (Trigger.isBefore && Trigger.isDelete) {
      //  Property__c_Helper.beforeDelete(Trigger.New);
    }
    if (Trigger.isAfter && Trigger.isDelete) {
      Property_Helper.afterDelete(Trigger.New, Trigger.Old);
    }
    if (Trigger.isAfter && Trigger.isUndelete) {
      //  Property__c_Helper.afterUndelete(Trigger.Old);
    }
  }
}