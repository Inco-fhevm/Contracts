// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.13 <0.9.0;

interface IInterchainExecuteRouter {

    function callRemote(
        uint32 _destination,
        address _to,
        uint256 _value,
        bytes calldata _data,
        bytes memory _callback
    ) external returns (bytes32);

    function getRemoteInterchainAccount(uint32 _destination, address _owner)
        external
        view
        returns (address);

}

interface HiddenCard {
    function returnCard(address user) external returns(uint8);
}

contract Card {
    
    uint32 DestinationDomain;
    // HiddenCard contract in Inco Network
    address hiddencard;
    // InterchainExcuteRouter contract address in current chain
    address iexRouter;
    address caller_contract;
    bytes32 messageId;
    mapping (address => uint8) public Cards;

    function initialize(uint32 _DestinationDomain, address _hiddencard, address _iexRouter, address _caller_contract) public {
        DestinationDomain = _DestinationDomain;
        hiddencard = _hiddencard;
        iexRouter = _iexRouter;
        caller_contract = _caller_contract;
    }

    function CardGet(address user) public {
        HiddenCard _Hiddencard = HiddenCard(hiddencard);

        bytes memory _callback = abi.encodePacked(this.cardReceive.selector, (uint256(uint160(user))));

        messageId = IInterchainExecuteRouter(iexRouter).callRemote(
            DestinationDomain,
            address(_Hiddencard),
            0,
            abi.encodeCall(_Hiddencard.returnCard, (user)),
            _callback
        );
    }

    function cardReceive(uint256 user, uint8 _card) external {
        require(caller_contract == msg.sender, "not right caller contract");
        Cards[address(uint160(user))] = _card;
    }

    function CardView(address user) public view returns(uint8) {
        return Cards[user];
    }

    function getICA(address _contract) public view returns(address) {
        return IInterchainExecuteRouter(iexRouter).getRemoteInterchainAccount(DestinationDomain, _contract);
    }

}