// SPDX-License-Identifier: MIT
// Mem Token TradeManager
pragma solidity 0.8.23;


import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";


contract TradeManager {
	 using SafeERC20 for IERC20;
    
    struct Fee {
    	uint256 total;
    	uint256 claimed;
    }

    uint256 constant public START_PRICE = 1;         
    uint256 constant public PRICE_INCREASE_STEP = 1; // 1 decimal unit of stable coin
    uint256 constant public INCREASE_FROM_ROUND = 0;
    uint256 immutable public ROUND_VOLUME = 1_000_000 * 10**_distributionTokenDecimals(); // in wei
    uint256 constant public FEE_PERCENT_POINT = 50000;
    uint256 constant public PERCENT_DENOMINATOR = 10000;
    
    address immutable public BENEFICIARY;
    uint8 immutable public TRADE_DECIMALS;

    Fee public fee;

    IERC20 public tradeToken;

    event Deal(
        address indexed User,
        address indexed assetIn,
        uint256 amountIn,
        uint256 amountOut
    );

    constructor (
    	address _feeBeneficiary,
        address _tradeFor,       // e.g. USDT address
        uint8   _tradeDecimals     // e.g. 6 for USDT
    ) 
    {
    	BENEFICIARY = _feeBeneficiary;
    	TRADE_DECIMALS = 18;
    	if (_tradeFor != address(0)) {
    		require(_tradeDecimals != 0, 'ERC20 decimals cant be zero');
    		tradeToken = IERC20(_tradeFor);
    		TRADE_DECIMALS = _tradeDecimals;
    	}
        
    }

    /// @notice Mint tokens for stable coins (or native)
    /// @dev _inAmount in wei. Don't forget approve
    /// @param _inAmount amount of stable (or native) to spent
    /// @param _outNotLess minimal desired amount of  tokens (anti slippage)
    function mintTokensForExactStableWithSlippage(
        uint256 _inAmount, 
        uint256 _outNotLess
    ) 
        external 
    {
        (uint256 out, ) = _calcMintTokensForExactStable(_inAmount);
        require(out >= _outNotLess, "Slippage occur");
        mintTokensForExactStable(_inAmount); 

    }     

    /// @notice Mint tokens for stable coins (or native)
    /// @dev _inAmount in wei. Don't forget approve
    /// @param _inAmount amount of stable to spent
    function mintTokensForExactStable(uint256 _inAmount) 
        public 
    {

        // 1. Calc distribution tokens
        (uint256 outAmount, uint256 inAmountFee)= _calcMintTokensForExactStable(_inAmount);
        require(outAmount > 0, 'Cant buy zero');
        
        // 2. Get payment
        tradeToken.safeTransferFrom(msg.sender, address(this), _inAmount);
        
        // 3. Charge Fee
        fee.total += inAmountFee;
        // 4. Mint distribution token
        _mintFor(msg.sender, outAmount);
        emit Deal(msg.sender, address(tradeToken), _inAmount, outAmount);

    }
    
    //////////////////
    //   GETTERS    //
    //////////////////

    /// @notice Returns amount of tokens that will be
    /// get by user if he(she) pay given stable coin amount
    /// @dev _inAmount must be with given in wei (eg 1 USDT =1000000)
    /// @param _inAmount stable coin amount that user want to spend
    /// @param outAmount stable coin amount that user will get
    /// @param inAmountFee fee that will given from _inAmount
    function calcMintTokensForExactStable(uint256 _inAmount) 
        external 
        view 
        returns(uint256 outAmount, uint256 inAmountFee) 
    {
        (outAmount, inAmountFee) = _calcMintTokensForExactStable(_inAmount);
    }

    /// @notice Returns amount of stable coins that must be spent
    /// for user get given  amount of  token
    /// @dev _outAmount must be with given in wei (eg 1 UBDN =1e18)
    /// @param _outAmount distributing token amount that user want to get
    /// @param inAmount amount of stable coins that must be spent with fee includede
    /// @param includeFee fee amount that already included in inAmount
    function calcMintStableForExactTokens(uint256 _outAmount) 
        external 
        view 
        returns(uint256 inAmount, uint256 includeFee) 
    {
        
        (inAmount, includeFee) =  _calcMintStableForExactTokens(_outAmount);
    }

    /// @notice Returns price  and distributing token rest
    /// for given round
    /// @dev returns tuple  (price, rest)
    /// @param _round round number
    function priceInUnitsAndRemainByRound(uint256 _round) 
        external 
        view 
        returns(uint256, uint256) 
    {
        return _priceInUnitsAndRemainByRound(_round);
    }


    /// @notice Returns current round number
    function getCurrentRound() external view returns(uint256){
        return _currenRound();   
    }

    /////////////////////////////////////////////////////////////////////

    function _calcMintStableForExactTokens(uint256 _outAmount) 
        internal
        virtual 
        view 
        returns(uint256 inAmount, uint256 includeFee) 
    {
        uint256 outA = _outAmount;
        uint256 curR = _currenRound();
        uint256 curPrice; 
        uint256 curRest;
        uint8 dstTokenDecimals = _distributionTokenDecimals();
        while (outA > 0) {
            (curPrice, curRest) = _priceInUnitsAndRemainByRound(curR); 
            if (outA > curRest) {
                inAmount += curRest 
                    * curPrice * 10**TRADE_DECIMALS
                    / (10**dstTokenDecimals);
                outA -= curRest;
                ++ curR;
            } else {
                inAmount += outA 
                    * curPrice * 10**TRADE_DECIMALS
                    / (10**dstTokenDecimals);
                //return inAmount;
                break;
            }
        }
        // Fee Charge
        includeFee = inAmount * FEE_PERCENT_POINT / (100 * PERCENT_DENOMINATOR);
        inAmount += includeFee; // return inAmount with fee incleded
    }

    function _calcMintTokensForExactStable(uint256 _inAmount) 
        internal
        virtual 
        view 
        returns(uint256 outAmount, uint256 inAmountFee) 
    {
        // Calc realy inamount with excluded fee
        uint256 inA = _inAmount * 100 * PERCENT_DENOMINATOR 
            / (100 * PERCENT_DENOMINATOR + FEE_PERCENT_POINT);
        inAmountFee = _inAmount - inA;
        uint256 curR = _currenRound();
        uint256 curPrice; 
        uint256 curRest;
        uint8 dstTokenDecimals = _distributionTokenDecimals();
        while (inA > 0) {
            (curPrice, curRest) = _priceInUnitsAndRemainByRound(curR); 
            if (
                // calc out amount
                inA 
                * (10**dstTokenDecimals)
                / (curPrice * 10**TRADE_DECIMALS)
                   > curRest
                ) 
            {
                // Case when inAmount more then price of all tokens 
                // in current round
                outAmount += curRest;
                inA -= curRest 
                       * curPrice * 10**TRADE_DECIMALS
                       / (10**dstTokenDecimals);
                ++ curR;
            } else {
                // Case when inAmount less or eqal then price of all tokens 
                // in current round
                outAmount += inA 
                  * 10**dstTokenDecimals
                  / (curPrice * 10**TRADE_DECIMALS);
                return (outAmount, inAmountFee);
            }
        }
    }

    function _priceInUnitsAndRemainByRound(uint256 _round) 
        internal 
        view 
        virtual 
        returns(uint256 price, uint256 rest) 
    {
        if (_round < INCREASE_FROM_ROUND){
            price = START_PRICE;
        } else {
            price = START_PRICE + PRICE_INCREASE_STEP * (_round - INCREASE_FROM_ROUND + 1); 
        }
        
        // in finished rounds rest always zero
        if (_round < _currenRound()){
            rest = 0;
        
        // in current round need calc 
        } else if (_round == _currenRound()){
            if (_round == 1){
                // first round
                rest = ROUND_VOLUME - _distributedAmount(); 
            } else {
                rest = ROUND_VOLUME - (_distributedAmount() % ROUND_VOLUME); 
            } 
        
        // in future rounds rest always ROUND_VOLUME
        } else {
            rest = ROUND_VOLUME;
        }
    }

    function _currenRound() internal view virtual returns(uint256){
        return _distributedAmount() / ROUND_VOLUME + 1;
    }

    

    //////////////////////////////////////////////////////////////////////
    function _mintFor(address _user, uint256 _amount) internal virtual {

    }

    function _burnFor(address _user, uint256 _amount) internal virtual {
    	
    }

    function _distributedAmount() internal view virtual returns(uint256) {
    	return 0;
    }

    function _distributionTokenDecimals() internal view virtual returns(uint8){
    	return 18;
    }
}