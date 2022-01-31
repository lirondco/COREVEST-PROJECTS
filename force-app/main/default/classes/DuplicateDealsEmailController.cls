public class DuplicateDealsEmailController {
  public String recId { get; set; }

  public static final List<String> PROP_FIELDS = new List<String>{
    'Id',
    'Name',
    'Deal__c',
    'Deal__r.Name',
    'Deal__r.StageName',
    'CreatedDate',
    'Deal__r.Owner.Name',
    'Deal__r.CloseDate',
    'Deal__r.CAF_Analyst__r.Name'
  };

  public List<Property__c> properties {
    get {
      if (recId != null) {
        List<Map<String, String>> dupeList = DuplicateCheckJobHelper.getDupeListFromDeal(
          recId
        );
        Set<String> idSet = new Set<string>();
        for (Map<String, String> d : dupeList) {
          idSet.add(String.valueOf(d.get('sourceId')));
          idSet.add(String.valueOf(d.get('matchId')));
        }

        String queryString =
          'SELECT ' +
          String.join(PROP_FIELDS, ',') +
          ' FROM Property__c WHERE Id IN :idSet';
        List<Property__c> dupePropertes = Database.query(queryString);

        return dupePropertes;
      } else {
        return new List<Property__c>();
      }
    }
    private set;
  }

  public String baseUrl {
    get {
      return URL.getOrgDomainUrl().toExternalForm() + '/';
    }
    private set;
  }

  public Boolean hasDuplicates {
    get {
      return properties.size() > 0;
    }
    private set;
  }

  public Integer numDuplicates {
    get {
      return properties.size();
    }
    private set;
  }
}
