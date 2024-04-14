//SPDX-License-Identifier: MIT
 
pragma solidity ^0.8.20;
 
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
 
contract PriceFeed is Ownable {
 
    // create a struct holding addresses of Chainlink price feeds and description of the conversion pair
    struct FeedInfo {
        AggregatorV3Interface aggregator;
        string description;
    }
 
    // map integer to FeedInfo struct
    mapping(uint => FeedInfo) public feeds;
 
    // mapping price feed ID to the price returned from Chainlink
    mapping(uint => int) public lastFetchedPrice;
 
    // events
    event FeedAddressUpdated(uint feedid, address newAddress, string description);
    event PriceRequested(string description, int price);
 
    constructor() Ownable() {
        // Chainlink smart contract addresses for the conversion pairs
        // These are the contract addresses on Avalanche Fuji
        feeds[1] = FeedInfo(AggregatorV3Interface(0x31CF013A08c6Ac228C94551d535d5BAfE19c602a), "BTC/USD");
        feeds[2] = FeedInfo(AggregatorV3Interface(0x86d67c3D38D2bCeE722E601025C25a575021c6EA), "ETH/USD");
        feeds[3] = FeedInfo(AggregatorV3Interface(0x34C4c526902d88a3Aa98DB8a9b802603EB1E3470), "LINK/USD");
        feeds[4] = FeedInfo(AggregatorV3Interface(0x378E78509a907B1Ec5c24d9f0243BD39f7A7b007), "BTC/ETH");
    }
 
    // retrieve current price from Chainlink contract, then update the stored price
    function updatePrice(uint feedid) public {
        FeedInfo storage feed = feeds[feedid];
        require(address(feed.aggregator) != address(0), "Contract address not found.");
        (, int price,,,) = feed.aggregator.latestRoundData();
        // update lastFetchedPrice mapping
        lastFetchedPrice[feedid] = price;
        // emit event
        emit PriceRequested(feed.description, price);    
 
    }
 
    // return latest price conversion for the pair requested from Chainlink
    function getLastFetchedPrice(uint feedid) public view returns(int) {
        require(lastFetchedPrice[feedid] != 0, "Latest price conversion has not been retrieved.");
        return lastFetchedPrice[feedid];
    }
 
    // change the data feed contract address, corresponding to the feed id
    function updateFeedAddress(uint feedid, address newAddress) public onlyOwner {
        // modifier so that only the contract owner can execute this function ^
        require(newAddress != address(0), "Updated address is undefined.");
        // feedid must be 1,2,3 or 4 in this example
        require(feedid > 0 && feedid < 5, "invalid feed ID.");
        feeds[feedid].aggregator = AggregatorV3Interface(newAddress);
        emit FeedAddressUpdated(feedid, newAddress, feeds[feedid].description);
    }
}