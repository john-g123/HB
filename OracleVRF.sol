//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "../base/IOracle.sol";
import "../base/Ownable.sol";

contract TimestampVRF is Ownable{

    IOracle Oracle;

    constructor(address oracleAddress){
        Oracle = IOracle(oracleAddress);
    }

    function setOracle(address oracleAddress) external onlyOwner{
        Oracle = IOracle(oracleAddress);
    }
    
    function initiateRandomness(uint _tokenId,uint _timestamp) external view returns(uint){
        bytes32 tellorId = 0x0000000000000000000000000000000000000000000000000000000000000001;
        uint result = Oracle.getTimestampCountById(tellorId);
        uint tellorTimeStamp = Oracle.getReportTimestampByIndex(tellorId,result-1);
        if(tellorTimeStamp<_timestamp){
            return 0;
        }
        for(uint i=(result-2);i>0;i--){
            if(tellorTimeStamp < _timestamp)
            break;
            tellorTimeStamp = Oracle.getReportTimestampByIndex(tellorId,i);
        }
        bytes memory tellorValue = Oracle.getValueByTimestamp(tellorId,tellorTimeStamp);
        return uint(keccak256(abi.encodePacked(tellorValue,_tokenId)));
    }

    function stealRandomness() external view returns(uint){
        bytes32 tellorId = 0x0000000000000000000000000000000000000000000000000000000000000001;
        uint result = Oracle.getTimestampCountById(tellorId);
        uint tellorTimeStamp = Oracle.getReportTimestampByIndex(tellorId,result-1);
        bytes memory tellorValue = Oracle.getValueByTimestamp(tellorId,tellorTimeStamp);
        return uint(keccak256(abi.encodePacked(tellorValue,block.timestamp,block.difficulty)));
    }

}