// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import "fhevm/lib/TFHE.sol";
import {SepoliaZamaFHEVMConfig} from "fhevm/config/ZamaFHEVMConfig.sol";
import {SepoliaZamaGatewayConfig} from "fhevm/config/ZamaGatewayConfig.sol";
import {GatewayCaller} from "fhevm/gateway/GatewayCaller.sol";

import "./MyConfidentialERC20.sol";

contract BlindAuction is SepoliaZamaFHEVMConfig {
    address public beneficiary;
    uint public auctionEndTime;
    
    // Encrypted bid amount for each bidder
    mapping(address => euint32) private bids;
    
    // Track if address has bid
    mapping(address => bool) public hasBid;
    
    // Track highest bid and bidder (encrypted)
    euint32 private highestBid;
    address private highestBidder;
    bool private hasHighestBid;

    event AuctionEnded(address winner, uint amount);

    constructor(uint _biddingTime) SepoliaZamaFHEVMConfig() {
        beneficiary = msg.sender;
        auctionEndTime = block.timestamp + _biddingTime;
    }

    // Submit an encrypted bid
    function bid(bytes calldata encryptedBid) external {
        require(block.timestamp <= auctionEndTime, "Auction ended");
        require(!hasBid[msg.sender], "Already bid");

        // Convert encrypted input to euint32
        euint32 bidAmount = TFHE.asEuint32(encryptedBid);
        TFHE.allowThis(bidAmount);
        
        // Store the bid
        bids[msg.sender] = bidAmount;
        hasBid[msg.sender] = true;

        // Update highest bid if this is higher
        if (!hasHighestBid) {
            highestBid = bidAmount;
            highestBidder = msg.sender;
            hasHighestBid = true;
        } else {
            ebool isHigher = TFHE.gt(bidAmount, highestBid);
            if (TFHE.decrypt(isHigher)) {
                highestBid = bidAmount;
                highestBidder = msg.sender;
            }
        }
    }

    // End the auction and reveal winner
    function auctionEnd() external {
        require(block.timestamp >= auctionEndTime, "Auction not yet ended");
        require(msg.sender == beneficiary, "Only beneficiary can end auction");
        require(hasHighestBid, "No bids were made");

        // Decrypt the winning bid
        uint32 winningAmount = TFHE.decrypt(highestBid);
        
        emit AuctionEnded(highestBidder, winningAmount);
        
        // Transfer the winning bid amount to beneficiary
        // Note: In a real implementation, you'd want to handle the actual transfer of funds
    }

    // View your own bid (only the bidder can decrypt their bid)
    function viewMyBid() external view returns (euint32) {
        require(hasBid[msg.sender], "You haven't bid");
        return bids[msg.sender];
    }
}