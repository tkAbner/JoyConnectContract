// SPDX-License-Identifier: BSD-3-Clause-Clear
pragma solidity >=0.8.13 <0.9.0;

import "fhevm/lib/TFHE.sol";
import "fhevm/gateway/GatewayCaller.sol";
import "@openzeppelin/contracts/access/Ownable2Step.sol";

contract JoyConnectVoter is GatewayCaller, Ownable2Step {
    event EncryptedVote(address indexed targetUser, euint64 likes);
    event releasedVote(address indexed targetUser, uint64 likes);

    mapping(address => euint64) internal encryptedVoteCounts;
    mapping(address => uint64) internal decryptedVoteCounts;
    mapping(address => bool) internal hasVoted;
    euint64 private totalVoteCountEncrypted;

    uint64 public totalVoteCount;

    constructor() Ownable(msg.sender) {}

    function init() external onlyOwner {
        totalVoteCountEncrypted = TFHE.asEuint64(0);

        // Allow the contract to manage these encrypted counts
        TFHE.allow(totalVoteCountEncrypted, owner());
        TFHE.allow(totalVoteCountEncrypted, address(this));
    }

    function voteMock(address targetUser, uint64 likes, bytes calldata inputProof) public {
        decryptedVoteCounts[targetUser] += likes;
    }

    function vote(address targetUser, einput likes, bytes calldata inputProof) public {
        euint64 userLikes = TFHE.asEuint64(likes, inputProof);

        // Update or initialize the encrypted vote count for the sender
        if (TFHE.isInitialized(encryptedVoteCounts[targetUser])) {
            encryptedVoteCounts[targetUser] = TFHE.add(encryptedVoteCounts[targetUser], userLikes);
        } else {
            encryptedVoteCounts[targetUser] = userLikes;
            TFHE.allow(encryptedVoteCounts[targetUser], address(this));
            TFHE.allow(encryptedVoteCounts[targetUser], owner());
        }

        // Add the computed vote powers to the encrypted tallies
        totalVoteCountEncrypted = TFHE.add(totalVoteCountEncrypted, userLikes);

        // Allow both the contract and owner to access these encrypted tallies in the future
        TFHE.allow(totalVoteCountEncrypted, address(this));
        TFHE.allow(totalVoteCountEncrypted, owner());

        emit EncryptedVote(targetUser, userLikes);
    }

    /**
     * @notice Allows the owner to reveal the final result by decrypting tallies
     */
    function revealTotalVotingResults() public onlyOwner {
        // Retrieve encrypted tallies
        euint64 totalvoteCount = totalVoteCountEncrypted;

        // Grant the contract permission to handle encrypted tallies
        TFHE.allow(totalvoteCount, address(this));

        // Request decryption of the final vote tallies
        uint256[] memory cts = new uint256[](2);
        cts[0] = Gateway.toUint256(totalvoteCount);

        Gateway.requestDecryption(cts, this.decryptionTotalVotingCallback.selector, 0, block.timestamp + 100, false);
    }

    /**
     * @notice Callback function to handle decrypted results from the gateway
     * @param totalVoteCountDecrypted Decrypted totalVoteCount
     * @return True if the callback is successful
     */
    function decryptionTotalVotingCallback(
        uint256 /*requestID*/,
        uint64 totalVoteCountDecrypted
    ) public onlyGateway returns (bool) {
        // Update plaintext tallies with decrypted values
        totalVoteCount = totalVoteCountDecrypted;
        return true;
    }

    /**
     * @notice Allows the owner to reveal the final result by decrypting tallies for a specific user
     */
    function revealVotingResultForUser(address targetUser) public onlyOwner {
        // Retrieve encrypted tallies
        // eaddress eUser = TFHE.asEaddress(targetUser);
        euint64 eCount = encryptedVoteCounts[targetUser];

        // Grant the contract permission to handle encrypted tallies
        // TFHE.allow(eUser, address(this));
        TFHE.allow(eCount, address(this));

        // Request decryption of the final vote tallies
        uint256[] memory cts = new uint256[](0);
        // cts[0] = Gateway.toUint256(eUser);
        cts[0] = Gateway.toUint256(eCount);

        Gateway.requestDecryption(cts, this.decryptionUserVotingCallback.selector, 0, block.timestamp + 100, false);
    }

    /**
     * @notice Callback function to handle decrypted results from the gateway
     * @param targetUser Decrypted targetUser
     * @param voteCount voteCount
     * @return True if the callback is successful
     */
    function decryptionUserVotingCallback(
        uint256 /*requestID*/,
        address targetUser,
        uint64 voteCount
    ) public onlyGateway returns (bool) {
        // Update plaintext tallies with decrypted values
        decryptedVoteCounts[targetUser] = voteCount;

        emit releasedVote(targetUser, decryptedVoteCounts[targetUser]);
        return true;
    }

    /**
     * @notice Allows a user to view their own encrypted vote count
     * @return The encrypted vote count of the sender
     */
    function getOwnEncryptedVoteCount() public view returns (euint64) {
        return encryptedVoteCounts[msg.sender];
    }

    /**
     * @notice Allows a user to view their own encrypted vote count
     * @return The encrypted vote count of the sender
     */
    function getUserEncryptedVoteCount(address targetUser) public view returns (euint64) {
        return encryptedVoteCounts[targetUser];
    }

    /**
     * @notice View the total encrypted count of in-favor votes
     * @return The encrypted in-favor vote count
     */
    function getEncryptedInFavorVoteCount() public view returns (euint64) {
        return totalVoteCountEncrypted;
    }

    function getDecryptedVoteCount(address targetUser) public view returns (uint64) {
        return decryptedVoteCounts[targetUser];
    }
}
