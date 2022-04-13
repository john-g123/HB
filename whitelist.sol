// SPDX-License-Identifier: UNLICENSED
/**
 * Author : Lil Ye, Ace
 */
pragma solidity ^0.8.0;

import "../base/EIP721.sol";
import "../base/Ownable.sol";

interface IERC721{
    function buyAndStake(bool stake,uint8 tokenType, uint tokenAmount,address receiver) external payable;
}

contract whitelistCheck is EIP712,Ownable{

    string private constant SIGNING_DOMAIN = "Some Signing Domain";
    string private constant SIGNATURE_VERSION = "1";

    struct Whitelist{
        address userAddress;
        bytes signature;
    }

    IERC721 nftFactory;

    address designatedSigner;

    constructor(address _nftAddress) EIP712(SIGNING_DOMAIN, SIGNATURE_VERSION){
        nftFactory = IERC721(_nftAddress);
    }

    function setContract(address _nftAddress) external onlyOwner{
        nftFactory = IERC721(_nftAddress);
    }

    function setSigner(address _newSigner) external onlyOwner{
        designatedSigner = _newSigner;
    }

    function buy(bool stake, uint8 tokenType, uint tokenAmount,Whitelist memory whitelist) external payable{
        require(getSigner(whitelist) == designatedSigner,"Signer doesn't match");
        nftFactory.buyAndStake{value:msg.value}(stake,tokenType,tokenAmount,whitelist.userAddress);
    }

    function getSigner(Whitelist memory whitelist) internal view returns(address){
        return _verify(whitelist);
    }

    /// @notice Returns a hash of the given whitelist, prepared using EIP712 typed data hashing rules.
  
    function _hash(Whitelist memory whitelist) internal view returns (bytes32) {
    return _hashTypedDataV4(keccak256(abi.encode(
      keccak256("Whitelist(address userAddress)"),
      whitelist.userAddress
    )));
    }

    function _verify(Whitelist memory whitelist) internal view returns (address) {
        bytes32 digest = _hash(whitelist);
        return ECDSA.recover(digest, whitelist.signature);
    }

}
