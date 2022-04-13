pragma solidity ^0.8.0;

import "../metadata/MetadataFactory.sol";
import "../base/IGameEngine.sol";
import "../base/Ownable.sol";

//please wait only 20 deployment left
contract metadata is Ownable{

    MetadataFactory.nftMetadata[] nfts;

    uint nonce;

    address nftContract;

    constructor(address _nftFactory){
        nftContract = _nftFactory;
    }

    modifier onlyNFTFactory{
        require(msg.sender == nftContract,"Not NFT factory");
        _;
    }

    function setContracts(address _nftFactory) external onlyOwner{
        nftContract = _nftFactory;
    }

    function getToken(uint256 _tokenId) external view returns(uint8, uint8, bool, uint,uint) {
        _tokenId--;
        return (
        nfts[_tokenId].nftType,
        nfts[_tokenId].level,
        nfts[_tokenId].canClaim,
        nfts[_tokenId].stakedTime,
        nfts[_tokenId].lastClaimTime) ;
    }
    
    function addMetadata(uint8 level,uint8 tokenType) external onlyNFTFactory{
        nonce++;
        nfts.push(MetadataFactory.createRandomMetadata(level, tokenType,nonce));
    }

    function getTokenURI(uint tokenId) external view returns (string memory)
    {
        MetadataFactory.nftMetadata memory nft = nfts[tokenId-1];
        return MetadataFactory.buildMetadata(nft, nft.nftType==1,tokenId);
    }

    function changeNft(uint tokenID, uint8 nftType, uint8 level, bool canClaim, uint stakedTime, uint lastClaimTime) external onlyNFTFactory {
            MetadataFactory.nftMetadata memory original = nfts[tokenID-1];
            nonce++;
            if(original.level != level) { //level up if level changes, level will only ever go up 1 at a time
                original = MetadataFactory.levelUpMetadata(original,nonce);
            } 
            
            if(original.nftType != nftType) { //only recreate metadata if type changes (steal)
                uint8[] memory traits;
                if(nftType == 0) {
                    (traits,,,,) = MetadataFactory.createRandomZombie(level,nonce);
                } else {
                    (traits,,,,) = MetadataFactory.createRandomSurvivor(level,nonce);
                }
                original = MetadataFactory.constructNft(nftType, traits, level, canClaim, stakedTime, lastClaimTime);
            } else {
                //Level and type have not changed, change everything else
                original.canClaim = canClaim;
                original.stakedTime = stakedTime;
                original.lastClaimTime = lastClaimTime;
            }
        nfts[tokenID - 1] = original;
    }
}