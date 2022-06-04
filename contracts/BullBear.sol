// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@chainlink/contracts/src/v0.8/KeeperCompatible.sol";

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";



contract BullBear is ERC721, ERC721Enumerable, ERC721URIStorage, Ownable, KeeperCompatibleInterface, VRFConsumerBaseV2 {

    VRFCoordinatorV2Interface COORDINATOR;

    uint64 s_subscriptionId;
    bytes32 keyHash = 0xd89b2bf150e3b9e13446986e571fb9cab24b13cea0a43ea20a6049a85cc807cc;
    uint32 callbackGasLimit = 500000;
    uint16 requestConfirmations = 3;
    uint32 numWords = 1;

    uint256[] public s_randomWords;
    uint256 public s_requestId;
    address s_owner;

    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;
    uint256 public /*immutable*/ interval;
    uint256 public lastTimeStamp;

    AggregatorV3Interface public priceFeed;
    int256 public currentPrice;

    enum MarketTrend{BULL, BEAR}
    MarketTrend public currentMarketTrend = MarketTrend.BULL;

    string[] bullUrisIpfs = [
        "https://cloudflare-ipfs.com//ipfs/bafkreic3japs25s27r5k4ptt7ydein427quoceyo4rp6ac3m3umpw3msqu",
        "https://cloudflare-ipfs.com//ipfs/bafkreiaafatqttb3gvvq6fh3q27koiq3i5tn2xr5kz3ssoi55gp6jp5a24",
        "https://cloudflare-ipfs.com//ipfs/bafkreidihcyg5pu5ovbvtwrgyfkx4idimqqkbbikrhnhivfsgtejx4v7gi"
        ];

    string[] bearUrisIpfs = [
        "https://cloudflare-ipfs.com//ipfs/bafkreib34nlgc2ahuu524ef3pupziqzm4wihl5hp2ih245wghytjl2oeva",
        "https://cloudflare-ipfs.com//ipfs/bafkreigcvajzfkyb7flg4zldjexvat5vycyyznfkf4z73unnbybtw2grou",
        "https://cloudflare-ipfs.com//ipfs/bafkreibfz66q2pkzvlvwz2lrp72zz2aesiniba5asu7ewrm74tyb2slgdm"
    ];

    event TokensUpdated(string marketTrend);

    constructor(uint256 updateInterval, address _priceFeed, uint64 subscriptionId, address _vrfcoordinator) ERC721("Bull&Bear", "BBTK") VRFConsumerBaseV2(_vrfcoordinator) {
        
        s_owner = msg.sender;
        s_subscriptionId = subscriptionId;

        COORDINATOR = VRFCoordinatorV2Interface(_vrfcoordinator);

        interval = updateInterval;
        lastTimeStamp = block.timestamp;

        priceFeed = AggregatorV3Interface(_priceFeed);

        currentPrice = getLatestPrice();

    }

    function safeMint(address to) public onlyOwner {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);

        string memory defaultUri = bullUrisIpfs[0];
        _setTokenURI(tokenId, defaultUri);
    }

    function checkUpkeep(bytes calldata /*checkData*/) external view override returns (bool upkeepNeeded, bytes memory /*performData*/) {
        upkeepNeeded = (block.timestamp - lastTimeStamp) > interval;
    }

    function performUpkeep(bytes calldata /*performData*/) external override {
        if ((block.timestamp - lastTimeStamp) > interval) {
            lastTimeStamp = block.timestamp;
            int256 latestPrice = getLatestPrice();

            if(latestPrice == currentPrice) {
                return;
            }
            if(latestPrice < currentPrice) {
                //bear
                currentMarketTrend = MarketTrend.BEAR;
            } else {
                //bull
                currentMarketTrend = MarketTrend.BULL;
            }

            requestRandomnessForNFTUris();

            currentPrice = latestPrice;

        } else {
            //Interval not elapsed. No upkeep.
            return;
        }
    }

    function getLatestPrice() public view returns (int256) {
        (
            /*uint80 roundID*/,
            int price,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = priceFeed.latestRoundData();

        return price;
    }

    function setInterval(uint256 newInterval) public onlyOwner {
        interval = newInterval;
    }

    function setPriceFeed(address newFeed) public onlyOwner {
        priceFeed = AggregatorV3Interface(newFeed);
    }

    function requestRandomnessForNFTUris() internal {
        require(s_subscriptionId !=0, "subscripotion ID not set");

        s_requestId = COORDINATOR.requestRandomWords(keyHash, s_subscriptionId, requestConfirmations, callbackGasLimit, numWords);
    }

    function fulfillRandomWords(uint256, /* requestId */ uint256[] memory randomWords) internal override {
        s_randomWords = randomWords;

        string[] memory urisForTrend = currentMarketTrend == MarketTrend.BULL ? bullUrisIpfs : bearUrisIpfs;
        uint256 idx = randomWords[0] % urisForTrend.length;

        for (uint i = 0; i < _tokenIdCounter.current(); i++) {
            _setTokenURI(i, urisForTrend[idx]);
        }

        string memory trend = currentMarketTrend == MarketTrend.BULL ? "bullish" : "bearish";
        emit TokensUpdated(trend);
    }

    //helpers

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}