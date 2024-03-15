// SPDX-License-Identifier: BSD-3-Clause-Clear

pragma solidity >=0.8.13 <0.9.0;

import "fhevm/lib/TFHE.sol";
import "fhevm/abstracts/EIP712WithModifier.sol";

contract Voting is EIP712WithModifier {
   // A mapping from address to an encrypted balance.
    struct EncryptedVote {
        euint8 encryptedVoteCount;
        euint8 encryptedChoice;
        bool initialized;
    }
    mapping(address => EncryptedVote) internal encryptedVotes;
    mapping(address => bool) internal hasVoted;
    euint8 public inFavorCountEncrypted;
    euint8 public againstCountEncrypted;
    address public owner;
    uint8 public inFavorCount;
    uint8 public againstCount;

    constructor() EIP712WithModifier("Authorization token", "1") {
        inFavorCountEncrypted = TFHE.asEuint8(0);
        againstCountEncrypted = TFHE.asEuint8(0);
        inFavorCount = 0;
        againstCount = 0;
        owner = msg.sender;
    }

    modifier OnlyOwner {
        require(msg.sender == owner, "Only Owner");
        _;
    }

    // encryptedChoice can be 0 (against) or 1 (in favor)
    function castVote(bytes calldata encryptedVoteCount, bytes calldata encryptedChoice) public {
        require(!encryptedVotes[msg.sender].initialized, "Already voted");
        
        // Store the encrypted vote and choice in the mapping
        encryptedVotes[msg.sender] = EncryptedVote(TFHE.asEuint8(encryptedVoteCount), TFHE.asEuint8(encryptedChoice), true);

        ebool choice = TFHE.eq(TFHE.asEuint8(1), TFHE.asEuint8(encryptedChoice));
        euint8 inFavorCountToCast = TFHE.cmux(choice, TFHE.asEuint8(encryptedVoteCount), TFHE.asEuint8(0));
        euint8 againstCountToCast = TFHE.cmux(choice, TFHE.asEuint8(0), TFHE.asEuint8(encryptedVoteCount));
        inFavorCountEncrypted = TFHE.add(inFavorCountEncrypted, inFavorCountToCast);
        againstCountEncrypted = TFHE.add(againstCountEncrypted, againstCountToCast);
    }

    function revealResult() public OnlyOwner {
        inFavorCount = TFHE.decrypt(inFavorCountEncrypted);
        againstCount = TFHE.decrypt(againstCountEncrypted);
    }
    
    // EIP 712 signature is required to prove that the user is requesting to view his/her own credit score
    // Information is decrypted then re-encrypted using a publicKey provided by the user client to make sure that RPC cannot peek. 
    // The user can decrypt their credit score with the respective privateKey (stored on client)
    function viewOwnVoteCount(bytes32 publicKey, bytes calldata signature) public view onlySignedPublicKey(publicKey, signature) returns (bytes memory) {
        return TFHE.reencrypt(encryptedVotes[msg.sender].encryptedVoteCount, publicKey, 0);
    }

    function viewOwnVoteChoice(bytes32 publicKey, bytes calldata signature) public view onlySignedPublicKey(publicKey, signature) returns (bytes memory) {
        return TFHE.reencrypt(encryptedVotes[msg.sender].encryptedChoice, publicKey, 0);
    }
}
