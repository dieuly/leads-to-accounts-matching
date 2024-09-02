public class TestDataFactory {
    
    private static final String OPEN_LEAD_STATUS = 'Open - Not Contacted';

    private static final String FIRST_NAME = 'Firstname';
    private static final String LAST_NAME = 'Lastname';

    public static final String AIVEN = 'Aiven';
    public static final String KONE = 'Kone';
    public static final String SUPER_CLOTHES = 'Super Clothes';
    public static final String RAW_MEOW = 'Raw Meow';

    public static Map<String, String> ACCOUNT_DATA_MAP = new Map<String, String>{
        AIVEN => 'avien.io',
        KONE => 'kone.com',       
        SUPER_CLOTHES => 'superclothes.com',
        RAW_MEOW => 'rawmeow.com'       
    };

    public static String createEmail(String domain) {
        return (FIRST_NAME + '.' + LAST_NAME + '@' + domain).toLowerCase().trim();
    }

    public static Account createAccount(String name, String website) {
        return new Account(
            Name = name,
            Website = website
        );
	}

    public static Lead createLead(String company, String email) {
        return new Lead(
            LastName = LAST_NAME,
            Company = company,
            Email = email,
            Status = OPEN_LEAD_STATUS
        );
	}

    public static List<Lead> createLeads(Integer count, String company1, String company2) {
        List<Lead> leads = new List<Lead>();
        for (Integer i = 0; i < count; i++) {
            leads.add(new Lead (
                LastName = LAST_NAME + i,
                Company = i < 150 ? company1 : company2,
                Status = OPEN_LEAD_STATUS
            ));
        }
        return leads;
	}

}