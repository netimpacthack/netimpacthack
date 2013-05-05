public class CommandCenterController {

    public Opportunity opp {get; set;}
    public OpportunityLineItem oli {get; set;}
    private ApexPages.StandardController controller {get; set;}
    public List<PricebookEntry> productsList {get; set;}
    
    public PriceBookEntry selectedPriceBookEntry {get; set;}
    
    public String selectedProductId {get; set;}

    public CommandCenterController(ApexPages.StandardController controller) {
        this.controller = controller;
        oli = (OpportunityLineItem)controller.getRecord();
        oli.OpportunityId = System.currentPageReference().getParameters().get('addTo'); 
        opp = getOpp();
        productsList = refreshProducts();
    }
    
    private List<PriceBookEntry> refreshProducts() {
        String query = ' SELECT Id, Name, Product2.Product_Image__c, Product2.Id, Product2.Opportunity_Record_Type__c, UnitPrice, Product2.Require_Dates__c FROM PricebookEntry ';
               query += ' WHERE IsActive = true ';
               query += ' AND Product2.Add_to_Command_Center__c = true ';
               query += ' AND PriceBook2Id = \'' + opp.PriceBook2Id + '\' ';
               query += ' AND (Product2.Opportunity_Record_Type__c = \'' + opp.RecordType.Name + '\' ';
               query += '     OR Product2.Opportunity_Record_Type__c = null) ';
               
       productsList = Database.query(query);
       productsList = removeExistingProducts();
       System.debug(productsList);
       return productsList;
    }
    
    private List<PriceBookEntry> removeExistingProducts() {
        List<OpportunityLineItem> olis = opp.OpportunityLineItems;
        List<PricebookEntry> newProductsListNoDupes = new List<PricebookEntry>();
        for (PriceBookEntry p : productsList) {
            Boolean isDupe = false;
            for (OpportunityLineItem oli : olis) {
                if (oli.PricebookEntryId == p.Id) {
                    isDupe = true;
                    break;
                } 
            }
            
            if (!isDupe) {
                newProductsListNoDupes.add(p);
            }
        }
        productsList = newProductsListNoDupes;
        return productsList;
    }
    
    private Opportunity getOpp() {
        System.debug('Getting opp info...');
        List<Opportunity> opps = [SELECT Id, Name, RecordType.Name, AccountId, CloseDate, Pricebook2.Name, Pricebook2.Id,
                                (SELECT PricebookEntryId, PricebookEntry.Name, PricebookEntry.Product2.Id FROM OpportunityLineItems) currentProducts FROM Opportunity WHERE Id = :oli.OpportunityId];
        Opportunity o = opps[0];
        if (o.Pricebook2.Id == null) {
            Pricebook2 pb = [SELECT Id FROM Pricebook2 LIMIT 1];
            o.Pricebook2Id = pb.Id; 
        }
        return o;
    }
        
    public void setProductId() {    
        System.debug('Selected Product Id: ' + this.selectedProductId);
        List<PricebookEntry> products = [SELECT Id, Name, Product2.Description, UnitPrice, Product2.Name, Product2.Require_Dates__c
                                            FROM PricebookEntry WHERE Id = :selectedProductId];
        selectedPriceBookEntry = products[0];        
        oli.PricebookEntryId = selectedPriceBookEntry.Id;
        oli.PricebookEntry = selectedPriceBookEntry;      
        clearFields();   
        setDefaultValues();
    } 
    
    private void setDefaultValues() {
        oli.UnitPrice = selectedPriceBookEntry.UnitPrice;
        oli.Quantity = 1;
        if (oli.PricebookEntry.Product2.Require_Dates__c) {
            oli.ServiceDate = opp.CloseDate;
            oli.End_Date__c = oli.ServiceDate.addYears(1).addDays(-1);
        }
    }
        
    public PageReference specialSave() {
        System.debug('Saving record...');
          
        try {             
            forceValues();           
            insert oli;   
            return new PageReference('/' + oli.OpportunityId);
        } catch (Exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,e.getMessage()));
            return null;    
        }
    } 
    
    public void saveAndAdd() {
        System.debug('Saving and adding...');
        try {
            forceValues();
            insert oli;
            oli = new OpportunityLineItem();
            oli.OpportunityId = opp.Id;
            opp = getOpp();
            productsList = refreshProducts();
        } catch (Exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,e.getMessage()));
        }
    }
    
    public PageReference specialCancel() {
        return new PageReference('/' + oli.OpportunityId);
    }
    
    public void forceValues() {
        if (selectedPriceBookEntry.Product2.Id == '01ti0000000UdZRAA0') {
            oli.End_Date__c = oli.ServiceDate.addYears(1).addDays(-1);
        }
    }
    
    public void clearFields() {
        System.debug('Clearing fields...');    
        oli.UnitPrice = null;
        oli.ServiceDate = null;
        oli.End_Date__c = null;
    }
    
    public void vforceRefreshProducts() {   
        opp = getOpp();
        productsList = refreshProducts();
        selectedPriceBookEntry = null;
    }

}