public class LeadTriggerHandler {

    private static final String ACCOUNT_NAME_FUZZY_DUPLICATE_RULE = 'Account_Name_Fuzzy_Duplicate_Rule';

    public static void onBeforeInsert(List<Lead> newLeads) {
        matchLeadsToExistingAccounts(newLeads);
    }

    public static void matchLeadsToExistingAccounts(List<Lead> newLeads){
        // 1. Fuzzy/Exact match on lead company name and account name
        newLeads = matchFuzzyCompanyName(newLeads);
        // 2. Exact match on lead email domain and account domain
        newLeads = matchExactEmailDomain(newLeads);
    }

    // 1. Fuzzy/Exact match on lead company name and account name
    private static List<Lead> matchFuzzyCompanyName(List<Lead> newLeads) {
        Set<String> accountNamesFuzzy = new Set<String>();
        for (Lead lead : newLeads) {
            if (String.isBlank(lead.Account__c) && String.isNotBlank(lead.Company)) {
                accountNamesFuzzy.add(lead.Company);
            }
        }

        if (!accountNamesFuzzy.isEmpty()) {
            Map<String, Account> accountNameFuzzyMap = getAccountByNameFuzzyMap(accountNamesFuzzy);
            if (!accountNameFuzzyMap.isEmpty()) {
                for (Lead lead : newLeads) {
                    if (String.isBlank(lead.Account__c) && String.isNotBlank(lead.Company)) {
                        if (accountNameFuzzyMap.containsKey(lead.Company)) {
                            lead = populateAccountDataToLead(lead, accountNameFuzzyMap.get(lead.Company));
                        }
                    }
                }
            }     
        }
        return newLeads;
    }

    private static Map<String, Account> getAccountByNameFuzzyMap(Set<String> accountNamesFuzzy) {
        Map<String, Account> accountNameFuzzyMap = new Map<String, Account>();
        List<Account> accounts = new List<Account>();
        for (String accountName : accountNamesFuzzy) {
            accounts.add(new Account (Name = accountName));
        }

        // Find matched accounts based on Account Name Fuzzy Duplicate Rule 
        try {
            List<Datacloud.FindDuplicatesResult> accountDuplicates = Datacloud.FindDuplicates.findDuplicates(accounts);

            for (Integer i = 0; i < accountDuplicates.size(); i++) {
                Datacloud.FindDuplicatesResult dupResults = accountDuplicates.get(i);
                for (Datacloud.DuplicateResult dupResult : dupResults.getDuplicateResults()) {
                    if (dupResult.getDuplicateRule() == ACCOUNT_NAME_FUZZY_DUPLICATE_RULE) {
                        for (Datacloud.MatchResult matchResult: dupResult.getMatchResults()) {
                            if (!matchResult.getMatchRecords().isEmpty()) {
                                Datacloud.MatchRecord matchRecord = matchResult.getMatchRecords().get(0);
                                Account matchAccount = (Account) matchRecord.getRecord();
                                accountNameFuzzyMap.put(accounts.get(i).Name, matchAccount);
                            }
                        }
                    }
                }
            }
        } catch (Exception e) {
            // No active duplicate rules are defined for the Account object
        }

        return accountNameFuzzyMap;
    }

     // 2. Exact match on lead email domain and account domain
     private static List<Lead> matchExactEmailDomain(List<Lead> newLeads) {
        Set<String> accountDomains = new Set<String>();
        for (Lead lead : newLeads) {
            if (String.isBlank(lead.Account__c) && String.isNotBlank(lead.Email)) {
                if (parseEmailDomain(lead.Email) != null) {
                    accountDomains.add(parseEmailDomain(lead.Email));   
                }
            }
        }

        if (!accountDomains.isEmpty()) {
            Map<String, Account> accountDomainMap = getAccountByDomainMap(accountDomains);
            if (!accountDomainMap.isEmpty()) {
                for (Lead lead : newLeads) {
                    if (String.isBlank(lead.Account__c) && String.isNotBlank(lead.Email)) {
                        String emailDomain = parseEmailDomain(lead.Email);
                        if(emailDomain != null && accountDomainMap.containsKey(emailDomain)) {
                            lead = populateAccountDataToLead(lead, accountDomainMap.get(emailDomain));
                        }
                    }
                }
            }
        }
        return newLeads;
    }

    private static Map<String, Account> getAccountByDomainMap(Set<String> accountDomains) {
        Map<String, Account> accountDomainMap = new Map<String, Account>();
        List<Account> accounts = queryAccounts(accountDomains);
        for (Account account : accounts) {
            accountDomainMap.put(account.Account_Domain__c, account);
        }
        return accountDomainMap;
    }

    private static List<Account> queryAccounts(Set<String> accountDomains) {
        return [
            SELECT
                Id,
                Name,
                Account_Domain__c,
                Owner.Id
            FROM Account
            WHERE Account_Domain__c IN : accountDomains
            LIMIT 1000
        ];
    }

    private static Lead populateAccountDataToLead(Lead lead, Account account) {
        lead.Account__c = account.Id;
        lead.OwnerId = account.Owner.Id;
        return lead;
    }

    private static string parseEmailDomain(String email) {
        return (email.contains('@')) ? (email.split('@').get(1)).toLowerCase().trim() : null;
    }
 
}