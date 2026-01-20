// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract CryptoVenturesDAO {

    // Each member's stake information
    struct Member {
        uint256 stake; // ETH deposited (in wei)
    }

    // Mapping of member address to stake data
    mapping(address => Member) public members;

    // Total ETH staked in the DAO
    uint256 public totalStaked;

    /**
     * @notice Deposit ETH into the DAO treasury to gain governance power
     */
    function deposit() external payable {
        require(msg.value > 0, "Deposit must be greater than zero");
        members[msg.sender].stake += msg.value;
        totalStaked += msg.value;
    }

    /**
     * @notice Returns the voting power of a member (anti-whale)
     */
    function getVotingPower(address member) public view returns (uint256) {
        return _sqrt(members[member].stake);
    }

    /**
     * @dev Integer square root function
     */
    function _sqrt(uint256 x) internal pure returns (uint256 y) {
        if (x == 0) return 0;
        uint256 z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }
}
