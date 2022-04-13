// SPDX-License-Identifier: UNLICENSED
/**
 * Author : Lil Ye, Ace, Anyx, Elmontos
 */
pragma solidity ^0.8.0;

import '../base/Ownable.sol';
import '../base/IERC20.sol';
import "../base/ERC721.sol";
import "../base/IMetadata.sol";
import "../base/IGameEngine.sol";
import "../base/IWhitelist.sol";
import "../base/Counters.sol";
// import "hardhat/console.sol";

contract testNftFactory is Ownable, ERC721{

    using Strings for uint;

    ////nfts
    mapping (uint => address) public tokenOwner;
    mapping (uint=>uint) public override actionTimestamp;

    //COUNTS
    using Counters for Counters.Counter;
    Counters.Counter private tokenId_;

    //SALES
    //uint public HungerBrainz_MAX_COUNT = 40000; //maxSupply
    bool public isPresale;

    //todo place the finalised price
    // To-change -> from 0 eth to 0.069 eth
    uint public HungerBrainz_MAINSALE_PRICE = 0 ether; //priceInMainSale

    function mainSalePriceSetter (uint _amount) public onlyOwner {
        //enter your price in ether
        HungerBrainz_MAINSALE_PRICE = _amount ether;
    }


    mapping(address=>uint) userPurchase;

    //AMOUNT
    uint[2] public amount;

    //CONTRACT
    GameEngine game;
    IERC20 SUP;
    IWhitelist whitelist;
    IMetadata metadataHandler;

    constructor(address _gameAddress, address _tokenAddress,address _whitelist,address _metadata) ERC721("HungBiz", "HBZ") {
        game = GameEngine(_gameAddress);
        SUP = IERC20(_tokenAddress);
        whitelist = IWhitelist(_whitelist);
        metadataHandler = IMetadata(_metadata);
    }

    function tokenOwnerSetter(uint tokenId, address _owner) external override {
        require(_msgSender() == address(game));
        tokenOwner[tokenId] = _owner;
    }

    function setContract(address _gameAddress, address _tokenAddress,address _whitelist,address _metadata) external onlyOwner {
        game = GameEngine(_gameAddress);
        SUP = IERC20(_tokenAddress);
        whitelist = IWhitelist(_whitelist);
        metadataHandler = IMetadata(_metadata);
    }

    function burnNFT(uint tokenId) override external {
        require (_msgSender() == address(game), "Not GameAddress");
        _burn(tokenId);
    }

    function setTimeStamp(uint tokenId) external override{
        require(msg.sender == address(game));
        actionTimestamp[tokenId] = block.timestamp;
    }

    function setPresale(bool presale) external onlyOwner{
        isPresale = presale;
    }



    function buyAndStake(bool stake,uint8 tokenType, uint tokenAmount,address receiver) external payable {
    //  By calling this function, you agreed that you have read and accepted the terms & conditions
    // available at this link: https://hungerbrainz.com/terms 
        require (HungerBrainz_MAINSALE_PRICE <= msg.value, "INSUFFICIENT_ETH");
        require(tokenType < 2,"Invalid type");
        require (tokenId_.current() <= 10000)
        if(isPresale){
            require(msg.sender == address(whitelist),"Not whitelisted");
            // require(userPurchase[receiver] + tokenAmount <= 3,"Purchase limit");
        }
        else{
            // require(userPurchase[msg.sender] + tokenAmount <= 13,"Purchase limit");
            receiver = msg.sender;
        }
        if (isApprovedForAll(_msgSender(),address(game))==false) {
            setApprovalForAll(address(game), true);
        }
        amount[tokenType] = amount[tokenType]+tokenAmount;
        // userPurchase[receiver] += tokenAmount;
        if(stake)
            for (uint i=0; i<tokenAmount; i++) {
                tokenId_.increment();
                _safeMint(address(game),tokenId_.current());
                metadataHandler.addMetadata(1,tokenType);
                tokenOwner[tokenId_.current()] = receiver;
                game.alertStake(tokenId_.current());
            }
        
        else{
            for (uint i =0;i<tokenAmount;i++) {
                tokenId_.increment();
                _safeMint(receiver,  tokenId_.current());
                metadataHandler.addMetadata(1,tokenType);
                tokenOwner[tokenId_.current()]=receiver;
            }
        }
    }

    function buyUsingSUPAndStake(bool stake, uint8 tokenType, uint tokenAmount) external {
        //  By calling this function, you agreed that you have read and accepted the terms & conditions
    // available at this link: https://hungerbrainz.com/terms
       require(tokenType < 2,"Invalid type");
       require (tokenId_.current() > 10000, "SUP MINTING IS YET TO START");
        SUP.transferFrom(_msgSender(), address(this), tokenAmount*1000 ether);
        SUP.burn(tokenAmount* 1000 ether); //1000 ether
        amount[tokenType] = amount[tokenType]+tokenAmount;

        for (uint i=0; i< tokenAmount; i++) {
            if (stake) {
                tokenId_.increment();
                _safeMint(address(game), tokenId_.current());
                metadataHandler.addMetadata(1,tokenType);
                game.alertStake(tokenId_.current());
            }
            else {
                tokenId_.increment();
                _safeMint(msg.sender,tokenId_.current());
                metadataHandler.addMetadata(1,tokenType);
            }
            tokenOwner[tokenId_.current()]=msg.sender;
        }
    }
    //todo : fix in transfer hook
    function tokenOwnerCall(uint tokenId) external view override returns (address) {
        return tokenOwner[tokenId];
    }

    function withdraw() external {
        uint balance = address(this).balance;
        require(balance > 0);
        address payable _devAddress = payable (0x3384392f12f90C185a43861E0547aFF77BD5134A);
        uint devFees =  (balance*(10))/(100);
        _devAddress.transfer(devFees);
        payable(owner()).transfer(address(this).balance);
    }

    //Better if Game Address directly calls metadata contract
    function restrictedChangeNft(uint tokenID, uint8 nftType, uint8 level, bool canClaim, uint stakedTime, uint lastClaimTime) external override {
        require(msg.sender == address(game),"Call restricted");
        metadataHandler.changeNft(tokenID,nftType,level,canClaim,stakedTime,lastClaimTime);
    }


    //#endregion
    function tokenURI(uint tokenId) public view override(ERC721) returns (string memory) {
        require(_exists(tokenId), "Cannot query non-existent token");
        return metadataHandler.getTokenURI(tokenId);
        // MetadataFactory.nftMetadata memory nft = //nfts[tokenId-1];
        // return MetadataFactory.buildMetadata(nft, nft.nftType==1);
    }
    //Owner functions
    function setHungerBrainz_MAX_COUNT(uint _maxCount) external onlyOwner{
        HungerBrainz_MAX_COUNT = _maxCount;
    }

    function setHungerBrainz_MAINSALE_PRICE(uint _price) external onlyOwner{
        HungerBrainz_MAINSALE_PRICE = _price;
    }


    function _transfer(
        address from,
        address to,
        uint tokenId
    ) internal override{
        if(to!=address(game) && to!=tokenOwner[tokenId]){
            tokenOwner[tokenId] = to;
        }
        super._transfer(from,to,tokenId);
    }

    function _mint(address to, uint tokenId) internal override{
        super._mint(to,tokenId);
        actionTimestamp[tokenId] = block.timestamp;
    }

    function _burn(uint tokenId) internal override {
        (uint8 nftType,,,,)=metadataHandler.getToken(tokenId);
        //console.log("Got metadata");
        amount[nftType]--;
        //console.log("Reduced Amount");
        super._burn(tokenId);
        //console.log("burnt");
    }
}
