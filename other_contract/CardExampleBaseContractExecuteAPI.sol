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
    bytes32 messageId;
    uint8 card;

    function initialize(uint32 _DestinationDomain, address _hiddencard, address _iexRouter) public {
        DestinationDomain = _DestinationDomain;
        hiddencard = _hiddencard;
        iexRouter = _iexRouter;
    }

    function CardGet(address user) public {
        HiddenCard _Hiddencard = HiddenCard(hiddencard);

        bytes memory _callback = abi.encodePacked(this.cardReceive.selector);

        messageId = IInterchainExecuteRouter(iexRouter).callRemote(
            DestinationDomain,
            address(_Hiddencard),
            0,
            abi.encodeCall(_Hiddencard.returnCard, (user)),
            _callback
        );
    }

    function cardReceive(uint8 _card) external {
        card = _card;
    }

    function CardView() public view returns(uint8) {
        return card;
    }

    function getICA(address _contract) public view returns(address) {
        return IInterchainExecuteRouter(iexRouter).getRemoteInterchainAccount(DestinationDomain, _contract);
    }

}