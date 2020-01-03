pragma solidity ^0.5.9;
pragma experimental ABIEncoderV2;

contract KYC
{
    //Admin account
    address public admin;

    constructor() public {
        admin = msg.sender;
    }

    /*
    Member of struct customer
    @member customername - Username of the customer
    @member customerdata - Customer data hash of the data or identification documents
    @member upvote - This is the number of upvotes received from  banks
    @member Bank - Address of the bank that validated the customer account
    @member password - password for accessing customer data
    @member bankesvotedforcustomer - list of  banks voted for the customer
    */
    struct customer {
        string customername;
        string customerdata;
        uint upvote;
        address Bank;
        uint rating;
        string password;
        address [] bankesvotedforcustomer;
    }

    /*
    Member of struct bank
    @member name - Name of the bank
    @member ethAddress - Address of the bank
    @member regNumber - This is the registration number for the bank
    @member KYC_count - These are the number of KYC requests initiated by the bank/organisation
    @member bankupvote - vote received for the bankesvoted
    @member bankesvoted - list of other banks voted for the bank
    */
    struct bank {
       string name;
       address ethAddress;
       string regNumber;
       uint256 bankrating;
       uint KYC_count;
       address [] bankesvoted;
       uint bankupvote;
    }

     /*
    Member of struct kyc_request
    @member username - Username of the customer
    @member userdata - Customer data hash of the data or identification documents
    @member BankAddress - The address of the bank initiated the request
    @member IsAllowed -  if the request is added by a trusted bank or not
    */
    struct kyc_request {
        string username;
        string userdata;
        address BankAddress;
        bool IsAllowed;
    }
    /*
    Mapping a customer's username to the kyc_request_structs struct
    to track the kyc request
    */
    mapping (string=>kyc_request) kyc_request_structs;
    /*
    Mapping a customer's username to the Customer struct
    */
    mapping (string=>customer) customer_request_structs;
    /*
    Mapping a bank address to the bank details
    */
    mapping(address=>bank) banks;
    //List of banks
    address[] bankAddresses;
    //List of kyc requests
    string [] kyc_request_list;
    //List of cusotmers applied for kyc submission
    string [] customer_list;
    /*
    Mapping a username to cutomer details
    */
    mapping (string=>customer) final_customer_list;

    //List of validated customers which can be used by banks
    string [] final_customer_list_name;

    event addRequest(address bank, string username, string userdata);
    event addCustomer(address bank, string customername, string customerdata);

    /**
      Initiating a new KYC request
      The sender of message call is the bank
      @param  {string} customername The name of the customer for whom KYC is to be done
      @param  {string} customerdata The data/document
      @return {(uint}  1 if successful else 0
     */
    function AddRequest(string calldata customername, string calldata customerdata) external returns (uint){
        uint flag = 1;
        /*
        If the bank rating is less than or equal to 0.5 (convert to 5 as fixedpoint is not supported over all versions)
        then assign IsAllowed to false. Else assigning IsAllowed to true
        */
        if(banks[msg.sender].bankrating < uint(5)){
            kyc_request_structs[customername].IsAllowed = false;
            flag = 0;
        }
        else {
            kyc_request_structs[customername].IsAllowed = true;
        }
        kyc_request_structs[customername].username = customername;
        kyc_request_structs[customername].userdata = customerdata;
        kyc_request_structs[customername].BankAddress = msg.sender;
        kyc_request_list.push(customername);
        emit addRequest(kyc_request_structs[customername].BankAddress,kyc_request_structs[customername].username,kyc_request_structs[customername].userdata);
        return flag;
    }
    /**
      Add a new customer
      @param {string} customername Name of the customer to be added
      @param {string} customerdata the customer's document submitted for the process
      @return {uint} 1 if function executed successful else 0
     */
    function AddCustomer(string calldata customername, string calldata customerdata) external returns (uint){
       //Check if the request is valid
       require(kyc_request_structs[customername].IsAllowed == true, "This is not valid request");
       uint flagc;
       if(kyc_request_structs[customername].IsAllowed){
        flagc = 1;
        customer_request_structs[customername].customername = customername;
        customer_request_structs[customername].customerdata = customerdata;
        customer_request_structs[customername].Bank = msg.sender;
        customer_request_structs[customername].upvote = 0;
        customer_request_structs[customername].password = "o";
        customer_request_structs[customername].bankesvotedforcustomer.push(msg.sender);
        customer_list.push(customername);
        emit addCustomer(customer_request_structs[customername].Bank,customer_request_structs[customername].customername,customer_request_structs[customername].customerdata);
       }
        else {flagc = 0;
        }
        return flagc;
    }

    /**
      edit customer information
      @param  {public} customername name of the customer
      @param  {public} newcustomerdata the  updated document provided by the customer
      @return {uint}   1 if function executed successful else 0
     */
    function ModifyCustomer (string calldata customername, string calldata newcustomerdata, string calldata passwordcustomer) external returns (uint)  {

        uint flagmc = 0;
        for (uint i = 0; i < final_customer_list_name.length;i++){
            if (stringsEquals(final_customer_list_name[i],customername)){
                 bool passwordcheck = stringsEquals(customer_request_structs[customername].password,passwordcustomer);
                 if (passwordcheck == true){
                     //remove the entry from the final list
                     delete final_customer_list[customername];
                     flagmc = 1;
                      break;
                 }
                 else {
                     continue;
                 }
            }
            else{
                continue;
            }
        }
        customer_request_structs[customername].customerdata = newcustomerdata;
        customer_request_structs[customername].upvote = 0;
        customer_request_structs[customername].rating = 0;
        customer_request_structs[customername].Bank = msg.sender;
        return(flagmc);
    }

    /**
      Remove the kyc request raised
      @param  {string} customername name of the customer
      @return {uint8}  1 if function executed successful else 0
     */
    function removeRequest (string calldata customername, string calldata cusotmerdata) external returns(uint){
        uint flagr;
        //check if the customer request is present in the list
        for (uint i = 0;i < kyc_request_list.length; i++){
            string memory keycusotmer = kyc_request_list[i];
            if(stringsEquals(kyc_request_list[i],customername) && stringsEquals(kyc_request_structs[keycusotmer].userdata,cusotmerdata)) {
                //remove the entry
            delete kyc_request_structs[customername];
            flagr = 1;
            break;
       }
       else{
           flagr=0;
           continue;
       }
        }
    return (flagr);
    }
    /**
      Remove the customer
      @param  {string} customername name of the customer
      @return {uint8}  1 if function executed successful else 0
     */
    function removeCustomer (string memory customername) public returns(uint)
    {
        uint flagrc;
        for (uint i = 0;i < customer_list.length; i++)
         {
             if(stringsEquals(customer_list[i],customername)) {
                 //remove the entry
                 delete customer_request_structs[customername];
                 flagrc = 1;
                break;
               }
            else
            {   flagrc=0;
                continue;
             }
         }
     return flagrc;
    }
    /**
      view the customer
      @param  {string} customername name of the customer
      @return {uint8}  1 if function executed successful else 0
     */
    function viewCustomer (string memory customername, string memory password) public view returns (string memory) {
        //checks if password pprovided is correct
       bool passwordcheck = stringsEquals(customer_request_structs[customername].password,password);
        if(passwordcheck){
            return (customer_request_structs[customername].customerdata);
            }
            else{
                //if password didnt match
                return "password entered is wrong";
            }
        }

    /**
      cast an upvote for a customer.
      @param  {string} customername name of the customer
      @return {uint}  1 if function executed successful else 0
     */
    function upvote ( string calldata customername) external returns(uint){
        uint flagup = 1;
        uint len = customer_request_structs[customername].bankesvotedforcustomer.length;
        for (uint j = 0; j < len; j++){
            //check if bank already voted
            if (customer_request_structs[customername].bankesvotedforcustomer[j]==msg.sender){
            flagup = 0;
            break;
            }
        }

        if(flagup == 0)
        {return 0;}

        else
        {
            customer_request_structs[customername].upvote += 1;
            customer_request_structs[customername].rating = (customer_request_structs[customername].upvote/bankAddresses.length)*10;
            customer_request_structs[customername].bankesvotedforcustomer.push(msg.sender);
            ////check for the rating
            if(customer_request_structs[customername].rating > 5 ){
                final_customer_list[customername] = customer_request_structs[customername];
                final_customer_list_name.push(customername);
                return (1);
                }
            else
            {return 0;
            }
        }
    }

    /**
      kyc requests of the bank
      @param  {address} bankaddress address of the bank
      @return {struct}  list of request raised by the bank
     */
    function getbankrequest (address bankaddress) public view returns (kyc_request [] memory){
        kyc_request [] memory kyc_requests;
        for(uint i = 0; i < kyc_request_list.length; i++){
            if (kyc_request_structs[kyc_request_list[i]].BankAddress == bankaddress) {
                kyc_requests[i] = kyc_request_structs[kyc_request_list[i]];
            }
        }
       return (kyc_requests);
    }
    /**
      votes for the banks
      @param  {address} bankaddress address of the bank
      @return {uint}  1 if function executed successful else 0
     */
    function upvote_bank (address bankaddress) public returns (uint)
    {
      bool is_to_vote = false;
      for (uint i= 0 ; i < banks[bankaddress].bankesvoted.length;i++){
          //check if this bank have already voted
          if(banks[bankaddress].bankesvoted[i] == msg.sender){
              is_to_vote = true;
              break;
          }
          else {
              continue;
          }
      }
      if(is_to_vote)
      {return 0;}
      else
      {
          banks[bankaddress].bankesvoted.push(bankaddress);
          banks[bankaddress].bankupvote = (banks[bankaddress].bankupvote +1);
          banks[bankaddress].bankrating = ((banks[bankaddress].bankupvote*10)/bankAddresses.length);
          return 1;
      }
    }
    /**
      fetch customer rating from the smart contract
      @param  {string} customername name of the cutomer whose rating to be fetched
      @return {uint}  1 if function executed successful else 0
     */
    function getcustomerrating (string memory customername) public view returns (uint){
        return (final_customer_list[customername].rating);
    }

    /**
      fetch bank rating
      @param  {address} bankaddresses address of the bank whose rating to be fetched
      @return {uint}  1 if function executed successful else 0
     */
     function getbankrating (address bankaddresses) public view returns (uint256){
         uint256 banktemprate = banks[bankaddresses].bankrating;
        //return (banks[bankaddresses].bankrating);
        return (banktemprate);
    }
    /**
      to fetch the bank details which made the last changes to the customer data.
      @param  {string} customername name of the cutomer whose data edited
      @return {address}  address of the bank who edited
     */
    function retrievehistory (string memory customername) public view returns(address){
        return (customer_request_structs[customername].Bank);
    }
    /**
      Setting password for the user data default value is "o"
      @param  {string} customername name of the cutomer
      @param  {string} customerpassword password of the cutomer
      @return {bool}   true if function executed successful else false
     */
    function setpassword (string memory customername, string memory newpassword) public returns (bool){
      bool flag = false;
      for (uint i = 0; i<customer_list.length; i++){
          if (stringsEquals(customer_list[i],customername)){
          flag =true;
          break;
          }
      }

      if(flag)
      {customer_request_structs[customername].password = newpassword;
       return flag;
      }
      else{
          return flag;
      }
    }
    /**
      fetch the bank details.
      @param  {address} address of the bank
      @return bank details
     */
    function getbankdetails (address bankadd) public view returns (string memory, address,string memory, uint)
    {
        return (banks[bankadd].name,banks[bankadd].ethAddress,banks[bankadd].regNumber,banks[bankadd].bankrating);
    }
    /**
      used by the admin to add a bank
      @param  {string} bank name
      @param  {address} bank address
       @param  {string} bank registration number
      @return true if function executed successful else false
     */
    function addBank (string memory bankname, address bankaddress, string memory bankregnumber) public returns (bool)
    {
        require (msg.sender == admin, "ADMIN CAN ONLY CREATE Bank");
        bool flagb = true;
        for(uint i = 0 ; i < bankAddresses.length;i++){
            if(bankAddresses[i]==bankaddress){
                flagb = false;
                break;
            }
        }
        if(flagb == true)
        {bankAddresses.push(bankaddress);
        banks[bankaddress].name = bankname;
        banks[bankaddress].regNumber = bankregnumber;
        banks[bankaddress].ethAddress = bankaddress;
        return flagb;}
        else{
            return flagb;
        }
    }
    /**
      used by the admin to remove a bank
      @param  {address} bank address
      @return true if function executed successful else false
      */
    function removeBank (address bankaddress) public returns (bool)
    {
        require (msg.sender == admin, "ADMIN CAN ONLY DELETE Bank");
        bool flagb = false;
        for(uint i = 0 ; i < bankAddresses.length;i++){
            if(bankAddresses[i]==bankaddress){
                flagb = true;
                break;
            }
        }
        if(flagb == true){
            delete banks[bankaddress];
        }
        else{
            return flagb;
        }
    }

     /**
      used by compare string in storage and temperoray one passed
      @param  {string} string to be compared
      @param  {string} string to be compared
      @return true if function executed successful else false
      */
    function stringsEquals(string storage _string1, string memory _string2) internal view returns (bool) {
        bytes storage string1 = bytes(_string1);
        bytes memory string2 = bytes(_string2);
        if (string1.length != string2.length)
            return false;
        // @todo unroll this loop
        for (uint i = 0; i < string1.length; i ++){
            if (string1[i] != string2[i])
                return false;
        }
        return true;
    }

}
