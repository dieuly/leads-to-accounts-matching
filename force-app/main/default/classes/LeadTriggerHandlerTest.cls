@isTest(SeeAllData=false)
private class LeadTriggerHandlerTest {

    @TestSetup
    static void createTestData(){
        List<Account> accounts = new List<Account>();
        // TestDataFactory.createAccount(String name, String webiste);
		accounts.add(
            TestDataFactory.createAccount(
                TestDataFactory.AIVEN, 
                TestDataFactory.ACCOUNT_DATA_MAP.get(TestDataFactory.AIVEN)
            )
        );
        accounts.add(
            TestDataFactory.createAccount(
                TestDataFactory.KONE,
                TestDataFactory.ACCOUNT_DATA_MAP.get(TestDataFactory.KONE)
            )
        );
        accounts.add(
            TestDataFactory.createAccount(
                TestDataFactory.SUPER_CLOTHES,
                TestDataFactory.ACCOUNT_DATA_MAP.get(TestDataFactory.SUPER_CLOTHES)
            )
        );
        accounts.add(
            TestDataFactory.createAccount(
                TestDataFactory.RAW_MEOW,
                TestDataFactory.ACCOUNT_DATA_MAP.get(TestDataFactory.RAW_MEOW)
            )
        );
        insert accounts;
    }

    // Match exact company name test
    @isTest
    static void testLeadMatchCompanyName() {
        List<Lead> newLeads = new List<Lead>();
        // TestDataFactory.createLead(String company, String email);
        newLeads.add(
            TestDataFactory.createLead(
                TestDataFactory.AIVEN,
                TestDataFactory.createEmail(TestDataFactory.ACCOUNT_DATA_MAP.get(TestDataFactory.AIVEN))
            )
        );
        newLeads.add(
            TestDataFactory.createLead(
                TestDataFactory.AIVEN,
                TestDataFactory.createEmail(TestDataFactory.ACCOUNT_DATA_MAP.get(TestDataFactory.AIVEN))
            )
        );

        Test.startTest();
        insert newLeads;

        Test.stopTest();
        List<Lead> leads = queryMatchedLeads();
        System.assertEquals(
            2, 
            leads.size(), 
            'There should be 2 leads matched'
        );
        Account matchAccount = queryAccount(TestDataFactory.AIVEN);
        System.assertEquals(
            matchAccount.Id, 
            leads[0].Account__c, 
            'The first lead should match with' + TestDataFactory.AIVEN + ' account'
        );
        System.assertEquals(
            matchAccount.Id, 
            leads[1].Account__c, 
            'The second lead should match with ' + TestDataFactory.AIVEN + ' account'
        );
    }

    // Match exact email domain and account domain test
    @isTest
    static void testLeadMatchEmailDomain() {
        List<Lead> newLeads = new List<Lead>();
        newLeads.add(
            TestDataFactory.createLead(
                'Kone Finland Oy',
                TestDataFactory.createEmail(TestDataFactory.ACCOUNT_DATA_MAP.get(TestDataFactory.KONE))
            )
        );
        newLeads.add(
            TestDataFactory.createLead(
                'Konecranes Oy',
                TestDataFactory.createEmail('konecranes.com')
            )
        );

        Test.startTest();
        insert newLeads;

        Test.stopTest();
        List<Lead> leads = queryMatchedLeads();
        System.assertEquals(
            1, 
            leads.size(), 
            'There should be 1 lead matched'
        );
        Account matchAccount = queryAccount(TestDataFactory.KONE);
        System.assertEquals(
            matchAccount.Id, 
            leads[0].Account__c, 
            'This lead should match with ' + TestDataFactory.KONE + ' account because of the email domain match'
        );
    }

    // Match fuzzy company name test
    @isTest
    static void testLeadFuzzyMatchCompanyName() {
        List<Lead> newLeads = new List<Lead>();
        newLeads.add(
            TestDataFactory.createLead(
                'Super Clothes Corporation',
                TestDataFactory.createEmail('superclothescorp.com')
            )
        );
        newLeads.add(
            TestDataFactory.createLead(
                'Raw Meow Europe',
                TestDataFactory.createEmail('rawmeow.eu')
            )
        );
        newLeads.add(
            TestDataFactory.createLead(
                'Raw Meow Oy',
                TestDataFactory.createEmail('gmail.fi')
            )
        );
        newLeads.add(
            TestDataFactory.createLead(
                'Simple Company',
                TestDataFactory.createEmail('simplecompany.se')
            )
        );

        Test.startTest();
        insert newLeads;

        Test.stopTest();
        List<Lead> leads = queryMatchedLeads();
        System.assertEquals(
            3, 
            leads.size(), 
            'There should be 3 leads matched'
        );
        
        Account matchAccount1 = queryAccount(TestDataFactory.RAW_MEOW);
        List<Lead> leadsMatchWithAccount1 = [SELECT Id, Account__c FROM Lead WHERE Account__c =: matchAccount1.Id];
        System.assertEquals(
            2, 
            leadsMatchWithAccount1.size(), 
            'There should be 2 leads matched with ' + TestDataFactory.RAW_MEOW + ' account because of company name fuzzy match'
        );

        Account matchAccount2 = queryAccount(TestDataFactory.SUPER_CLOTHES);
        List<Lead> leadsMatchWithAccount2 = [SELECT Id, Account__c FROM Lead WHERE Account__c =: matchAccount2.Id];
        System.assertEquals(
            2, 
            leadsMatchWithAccount1.size(), 
            'There should be 1 lead matched with ' + TestDataFactory.SUPER_CLOTHES + ' account because of company fuzzy match'
        );
    }

    // Match exact company name bulk test
    @isTest
    static void testBulkLeads() {
        List<Lead> newLeads = TestDataFactory.createLeads(200, TestDataFactory.AIVEN, 'Simple Company');
        Test.startTest();
        insert newLeads;

        Test.stopTest();
        Account matchAccount = queryAccount(TestDataFactory.AIVEN);
        List<Lead> leads = [SELECT Id FROM Lead WHERE Account__c =: matchAccount.Id];
        System.assertEquals(
            150, 
            leads.size(), 
            'There should be 150 leads matched with ' + TestDataFactory.AIVEN + ' account'
        );
    }

    // Incomplete lead data test (missing Company)
    @isTest
    static void testIncompleteLeadData() {
        List<Lead> leads = new List<Lead>();
        leads.add(TestDataFactory.createLead('', 'hank.missle@bingo.com'));

        Test.startTest();
        try {
            insert leads;
        } catch (DMLException e) {
            System.assertEquals(
                Lead.Company, 
                e.getDmlFields(0)[0], 
                'Insert failed because of Company field'
            );
            System.assertEquals(
                'REQUIRED_FIELD_MISSING', 
                e.getDmlStatusCode(0),
                'Cannot insert Lead record because of missing required field'
            );
        }
        Test.stopTest();
    }

    // Incorect lead data test (invalid Email format)
    @isTest
    static void testIncorrectLeadData() {
        List<Lead> leads = new List<Lead>();
        leads.add(TestDataFactory.createLead('Bingo Inc.', 'hank.missle.bingo.com'));

        Test.startTest();
        try {
            insert leads;
        } catch (DMLException e) {
            System.assertEquals(
                Lead.Email, 
                e.getDmlFields(0)[0], 
                'Insert failed because of Email field'
            );
            System.assertEquals(
                'INVALID_EMAIL_ADDRESS', 
                e.getDmlStatusCode(0),
                'Cannot insert Lead record because of invalid email address'
            );
        }
        Test.stopTest();
    }

    private static List<Lead> queryMatchedLeads() {
        return [
            SELECT
                Id,
                Account__c
            FROM Lead
            WHERE Account__c != NULL
            LIMIT 200
        ];
    }

    private static Account queryAccount(String accountName) {
        return [
            SELECT
                Id
            FROM Account
            WHERE Name =: accountName
            LIMIT 1
        ];
    }

}