// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.13 <0.9.0;

interface IInterchainAccountRouter {

    function callRemote(
        uint32 _destination,
        address _to,
        uint256 _value,
        bytes calldata _data
    ) external returns (bytes32);

    function getRemoteInterchainAccount(uint32 _destination, address _owner)
        external
        view
        returns (address);

}

interface HiddenCard {
    function getCard(address user) external;
}

contract Card {
    
    uint32 DestinationDomain;
    // HiddenCard contract in Inco Network
    address hiddencard;
    // InterchainExcuteRouter contract address in current chain
    address iacRouter;
    bytes32 messageId;
    uint8 card;
    // Virtul Account of HiddenCard contract in current chain
    address inco_contract;

    function initialize(uint32 _DestinationDomain, address _hiddencard, address _iacRouter) public {
        DestinationDomain = _DestinationDomain;
        hiddencard = _hiddencard;
        iacRouter = _iacRouter;
    }

    function CardGet(address user) public {
        HiddenCard _Hiddencard = HiddenCard(hiddencard);

        messageId = IInterchainAccountRouter(iacRouter).callRemote(
            DestinationDomain,
            address(_Hiddencard),
            0,
            abi.encodeCall(_Hiddencard.getCard, (user))
        );
    }

    function getICA(address _contract) public view returns(address) {
        return IInterchainAccountRouter(iacRouter).getRemoteInterchainAccount(DestinationDomain, _contract);
    }

}