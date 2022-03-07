trigger deal_Document_Trigger on Deal_Document__c(
  before insert,
  before update,
  before delete,
  after insert,
  after update,
  after delete,
  after undelete
) {
  Settings__mdt settings = Settings__mdt.getInstance('Universal_Settings');
  CAFTestSetting__mdt cafTestSetting = CAFTestSetting__mdt.getInstance('Master');
  Boolean allowCafTest = false;
  if (cafTestSetting != null) {
    allowCafTest = cafTestSetting.Active__c;
  }

  if (!settings.Disable_Deal_Document_Trigger__c) {
    if (Trigger.isBefore && Trigger.isInsert) {
      Deal_Document_Helper.beforeInsert(Trigger.New);
    }
    if (Trigger.isAfter && Trigger.isInsert) {
      //Deal_Document_Helper.afterInsert(Trigger.New);
    }
    if (Trigger.isBefore && Trigger.isUpdate) {
      Deal_Document_Helper.beforeUpdate(Trigger.New, Trigger.Old);
    }
    if (Trigger.isAfter && Trigger.isUpdate) {
      Deal_Document_Helper.afterUpdate(Trigger.New, Trigger.Old);
      if(allowCafTest || Test.isRunningTest()) {
      CAFTestingClass.checkUploadedDocs(Trigger.oldMap, Trigger.newMap);
      }
    }
    if (Trigger.isBefore && Trigger.isDelete) {
      //	Deal_Document__c_Helper.beforeDelete(Trigger.New);
    }
    if (Trigger.isAfter && Trigger.isDelete) {
      //	Deal_Document__c_Helper.afterDelete(Trigger.New, Trigger.Old);
    }
    if (Trigger.isAfter && Trigger.isUndelete) {
      //	Deal_Document__c_Helper.afterUndelete(Trigger.Old);
    }
  }
}