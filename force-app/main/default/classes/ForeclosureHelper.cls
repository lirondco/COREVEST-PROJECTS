public without sharing class ForeclosureHelper {
    public static void afterUpdate(Map<Id, Foreclosure__c> oldMap, Map<Id,Foreclosure__c> newMap) {
        Map<Id, Foreclosure__c> specAssetsToUpdate = new Map<Id, Foreclosure__c>();
        for(Id key : newMap.keySet()) {
            Foreclosure__c nFc = newMap.get(key);
            Foreclosure__c oFc = oldMap.get(key);
            if(nFc.Special_Asset__c != null && (nFc.REO_date__c != oFc.REO_date__c || nFc.Special_Asset__c != oFc.Special_Asset__c)) {
                specAssetsToUpdate.put(key, nFc);
            }
        }

        if(specAssetsToUpdate.size() > 0) {
            updateSpecialAssets(specAssetsToUpdate);
        }
    }

    public static void updateSpecialAssets(Map<Id,Foreclosure__c> fcMap) {
        Map<Id,Special_Asset__c> specAssets = new Map<Id,Special_Asset__c>([
            SELECT Id, REO_Date__c FROM Special_Asset__c WHERE Id IN (SELECT Special_Asset__c FROM Foreclosure__c WHERE Id IN :fcMap.keySet())
        ]);

        List<Special_Asset__c> forUpdate = new List<Special_Asset__c>();

        if(specAssets.size() > 0) {
            for(Foreclosure__c fc : fcMap.values()) {
                Special_Asset__c sa = specAssets.get(fc.Special_Asset__c);
                if(sa != null && sa.REO_Date__c != fc.REO_date__c) {
                    sa.REO_Date__c = fc.REO_date__c;
                    forUpdate.add(sa);
                }
            }
        }

        if(forUpdate.size() > 0) {
            update(forUpdate);
        }
    }
}
