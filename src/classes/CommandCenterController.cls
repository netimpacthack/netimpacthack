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
               query += ' AND (Product2.Opportunity_Record_Type__c = \'' + opp.RecordType.Name + '\' ';
               query += '     OR Product2.Opportunity_Record_Type__c = null) ';
               
       List<PricebookEntry> newProductsList = Database.query(query);
       System.debug(newProductsList);
       return newProductsList;
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
        
        return newProductsListNoDupes;
    }
    
    private Opportunity getOpp() {
        System.debug('Getting opp info...');
        List<Opportunity> opps = [SELECT Id, Name, RecordType.Name, AccountId, CloseDate, Pricebook2.Name, 
                                (SELECT PricebookEntryId, PricebookEntry.Name, PricebookEntry.Product2.Id FROM OpportunityLineItems) currentProducts FROM Opportunity WHERE Id = :oli.OpportunityId];
        return opps[0];
    }
        
    public void setProductId() {    
        System.debug('Selected Product Id: ' + this.selectedProductId);
        List<PricebookEntry> products = [SELECT Id, Name, Product2.Description, UnitPrice, Product2.Name, Product2.Require_Dates__c
                                            FROM PricebookEntry WHERE Id = :selectedProductId];
        selectedPriceBookEntry = products[0];        
        oli.PricebookEntry = selectedPriceBookEntry;         
        setDefaultValues();
    } 
    
    private void setDefaultValues() {
        oli.UnitPrice = selectedPriceBookEntry.UnitPrice;
        if (oli.PricebookEntry.Product2.Require_Dates__c) {
            oli.Start_Date__c = opp.CloseDate;
            oli.End_Date__c = oli.Start_Date__c.addYears(1).addDays(-1);
        }
    }
        
    public PageReference specialSave() {
        System.debug('Saving record...');
          
        try {                        
            PageReference saveResults = controller.save();   
            return new PageReference('/' + oli.OpportunityId);
        } catch (Exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,e.getMessage()));
            return null;    
        }
    } 
    
    public void saveAndAdd() {
        System.debug('Saving and adding...');
        try {
            controller.save();
            oli = new OpportunityLineItem();
            oli.OpportunityId = opp.Id;
        } catch (Exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,e.getMessage()));
        }
    }
    
    public void clearFields() {
        System.debug('Clearing fields...');    
        oli.UnitPrice = null;
        oli.Start_Date__c = null;
        oli.End_Date__c = null;
    }
    
    public void vforceRefreshProducts() {   
        opp = getOpp();
        productsList = refreshProducts();
        selectedPriceBookEntry = null;
    }

}