// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";


contract vnt is  ERC20 {

    constructor() public ERC20("vnt", "VNT") {
    }

    address VUSD = 0x1bbb625A372A337bee53b29e12b7E3276CDbDb25;

    mapping(address => uint) balances;
    uint _initPrice = 10**17 ;  // 0.1 VUSD
    uint _releaseAmount = 10**6 * 10 **18; // 10^6 VNT  
    uint public _tokenInPool ;
    uint public _moneyInPool ;
    enum statusEnum { ICO, IDO, subIDO }
    
    statusEnum public state = statusEnum.ICO;
    uint public currentStep = 1;
    uint subIDOSold = 0;
    uint constant sqrt2 = 14142135623730951 ;  //1.4142135623730951 = sqrt2/10^16


    function icoPrice() public view returns (uint){
        return icoPriceAt(currentStep); 
    }

    function icoPriceAt(uint k) public view returns (uint){
        return 2**(k-1) * _initPrice; 
    }

    function poolConstant() public view returns (uint) {
        return _tokenInPool * _moneyInPool;
    }

    function currentPrice() public view returns (uint) {
        return balanceOf(address(this)) == 0 ? 0 : (IERC20(VUSD).balanceOf(address(this)) / balanceOf(address(this)) * 1000); // *1000
    }

    function tokenBeforeICO(uint k) public view returns (uint) {
        return tokenAfterICO(k - 1) / sqrt2 * 10**16;
    }

    function tokenAfterICO(uint k) public  view returns (uint) {
        return k == 0 ? 0 : tokenBeforeICO(k) + _releaseAmount /2;
    }

    function moneyAfterICO(uint k) public view returns (uint) {
        uint delta = k > 1 ? poolConstantAt(k-1) * sqrt2 * 10**16 : 0;
        return delta + _releaseAmount/2 * icoPriceAt(k);
    }

    function moneyIcanUse() public view returns (uint){
        return IERC20(VUSD).balanceOf(address(this)) ;
    }

    function poolConstantAt(uint k) public view returns(uint) {
        return k == 0 ? 0 : tokenAfterICO(k) * moneyAfterICO(k) ;
    }

    function checktotalSupply() public view returns (uint) {
        return totalSupply() ;
    }

    function checkBalance(address _address) public view returns(uint){
        return balances[_address];
    }

    function checkVUSD() public view returns(uint) {
        return IERC20(VUSD).balanceOf(address(this)) ;
    }


    function buyToken(uint amount) public {
        require(amount > 0, "Please input amount greater than 0");
        require(IERC20(VUSD).allowance(msg.sender, address(this)) == amount,"You must approve in web3");
        require(IERC20(VUSD).transferFrom(msg.sender, address(this),amount), "Transfer failed");

        uint nextBreak;
        uint assumingToken;
        uint buyNowCost = 0;
        uint buyNowToken;
        while (amount  >  0) {
            if (state == statusEnum.ICO) {
                nextBreak = tokenAfterICO(currentStep) - _tokenInPool;
                assumingToken = amount  / icoPrice() * 10**18;
            }

            if (state == statusEnum.IDO) {
                nextBreak = _tokenInPool - tokenBeforeICO(currentStep + 1 );
                assumingToken = _tokenInPool - poolConstant() / (_moneyInPool + amount);
            }

            if (state == statusEnum.subIDO) {
                nextBreak =  subIDOSold;
                assumingToken =   _tokenInPool - poolConstant() / (_moneyInPool + amount);
            }

            buyNowToken = nextBreak >= assumingToken ? assumingToken : nextBreak;
            buyNowCost = amount;    
            if ( assumingToken>nextBreak ){
	        buyNowCost = state == statusEnum.ICO ? buyNowToken*icoPrice() / 10**18 : (poolConstant()/(_tokenInPool - buyNowToken) - _moneyInPool);
            }
            _moneyInPool += buyNowCost;
            if (state == statusEnum.ICO) {
                _mint(address(this), buyNowToken);
                _mint(msg.sender, buyNowToken);
                _tokenInPool += buyNowToken;
            } else {
                IERC20(address(this)).transfer(msg.sender, buyNowToken);
                _tokenInPool -= buyNowToken;
                }
            balances[msg.sender] = balances[msg.sender] + buyNowToken;

            if (assumingToken >= nextBreak) {
                if (state == statusEnum.ICO) {
                    state = statusEnum.IDO;
                }else if (state == statusEnum.IDO) {
                    state = statusEnum.ICO;
                    currentStep +=1;
                }else {
                    state = statusEnum.ICO;
                    subIDOSold = 0;
                }

            } 

            amount = amount - buyNowCost;
        }
    }

    function sellToken(uint amount) public {
        require(amount > 0, "Please input amount greater than 0");
        require(IERC20(address(this)).allowance(msg.sender, address(this)) == amount,"You must approve in web3");
        require(IERC20(address(this)).transferFrom(msg.sender, address(this),amount), "Transfer failed");
	uint currentMoney = _moneyInPool;
        uint moneyInpool = poolConstant() / (_tokenInPool + amount);
        uint receivedMoney = currentMoney - moneyInpool ;
        _moneyInPool -= receivedMoney;
        _tokenInPool += amount ;
        balances[msg.sender] = balances[msg.sender] - amount;     
        IERC20(VUSD).transfer(msg.sender,receivedMoney );
        if (state == statusEnum.ICO) {
            state = statusEnum.subIDO;
        } 
        if (state == statusEnum.subIDO) {
            subIDOSold +=amount;
        }
    }
}



 


        
    




             
                


       
    


    
    
