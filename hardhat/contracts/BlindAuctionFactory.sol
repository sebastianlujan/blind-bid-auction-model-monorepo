// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./BlindAuction.sol";
import "fhevm/lib/TFHE.sol";
import "fhevm/config/ZamaFHEVMConfig.sol";
import "fhevm/config/ZamaGatewayConfig.sol";
import "fhevm/gateway/GatewayCaller.sol";
import "./MyConfidentialERC20.sol";

contract BlindAuctionFactory is SepoliaZamaFHEVMConfig {
    // Array to keep track of all created auctions
    BlindAuction[] public auctions;
    
    // Mapping from auction address to creator
    mapping(address => address) public auctionToCreator;
    
    // Event emitted when new auction is created
    event AuctionCreated(address indexed creator, address auctionAddress, uint biddingTime);

    // Create new auction
    function createAuction(uint biddingTime) external returns (address) {
        // Create new auction with msg.sender as beneficiary
        BlindAuction newAuction = new BlindAuction(msg.sender, biddingTime);
        
        // Store auction details
        auctions.push(newAuction);
        auctionToCreator[address(newAuction)] = msg.sender;
        
        emit AuctionCreated(msg.sender, address(newAuction), biddingTime);
        
        return address(newAuction);
    }

    // Get all auctions
    function getAuctions() external view returns (BlindAuction[] memory) {
        return auctions;
    }

    // Get number of auctions
    function getAuctionsCount() external view returns (uint) {
        return auctions.length;
    }

    // Get auctions created by a specific address
    function getAuctionsByCreator(address creator) external view returns (BlindAuction[] memory) {
        uint count = 0;
        
        // First count matching auctions
        for (uint i = 0; i < auctions.length; i++) {
            if (auctionToCreator[address(auctions[i])] == creator) {
                count++;
            }
        }
        
        // Create result array
        BlindAuction[] memory result = new BlindAuction[](count);
        uint index = 0;
        
        // Fill result array
        for (uint i = 0; i < auctions.length; i++) {
            if (auctionToCreator[address(auctions[i])] == creator) {
                result[index] = auctions[i];
                index++;
            }
        }
        
        return result;
    }
} 