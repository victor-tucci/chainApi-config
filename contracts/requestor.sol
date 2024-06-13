//SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@api3/airnode-protocol/contracts/rrp/requesters/RrpRequesterV0.sol";

contract BNSEthAddressFetch is RrpRequesterV0 {

    address public airnode;
    address public sponsor;
    address public sponsorWallet;
    address public owner;
    
    constructor(address _rrpAddress) RrpRequesterV0(_rrpAddress) {
            sponsor = address(this);
            owner = msg.sender;
    }

    modifier ownerOnly(){
        require(owner == msg.sender,"Requestor is not a owner");
        _;
    }

    modifier addressMust(){
        require(airnode != address(0),"Must specify the airnode address");
        require(sponsorWallet != address(0),"Must specify the sponsorWallet address");
        _;
    }

    function setAirNodeConfig(address _airnode, address _sponsorWallet) ownerOnly external{
        require(_airnode != address(0) && _sponsorWallet != address(0),"The given address is not valid");
        airnode = _airnode;
        sponsorWallet = _sponsorWallet;
    }

    mapping(bytes32 => bool) public incomingFulfillments;
    mapping(bytes32 => bytes) public fulfilledEncodedData;
    
    function getEncodeData(string memory _bnsName) public pure returns(bytes memory){
        // string memory params = string(abi.encodePacked('{"name":"', _bnsName, '"}'));
        return abi.encode( 
                        bytes32("1SSS"),
                        bytes32("name"),_bnsName,
                        bytes32("_path"),"ethAddress,status",
                        bytes32("_type"),"string,string"  
                        );
    }

    function makeRequest(bytes32 endpointId, string memory _bnsName, bytes memory _parameter) addressMust external {
        bytes memory parameters = (_parameter.length > 0)? _parameter : getEncodeData(_bnsName);
        bytes32 requestId = airnodeRrp.makeFullRequest(airnode, endpointId, sponsor, sponsorWallet,
                                                             address(this), this.fulfill.selector, parameters);
        incomingFulfillments[requestId] = true;
    }

    function fulfill(bytes32 requestId, bytes calldata data) external onlyAirnodeRrp
    {
        require(incomingFulfillments[requestId], "No such request made");
        delete incomingFulfillments[requestId];
         fulfilledEncodedData[requestId] = data;
    }

    function getEncodedData(bytes32 _requestId) external view returns(string memory _ethAddr, string memory _status){
        (_ethAddr,_status) = abi.decode(fulfilledEncodedData[_requestId], (string,string));

    }
}