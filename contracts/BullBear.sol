// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@chainlink/contracts/src/v0.8/KeeperCompatible.sol";


contract BullBear is ERC721, ERC721Enumerable, ERC721URIStorage, Ownable, KeeperCompatibleInterface {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;
    uint256 public /*immutable*/ interval;
    uint256 public lastTimeStamp;

    AggregatorV3Interface public priceFeed;
    int256 public currentPrice;

    string[] bullUrisIpfs = [
        "https://ipfs.filebase.io/ipfs/bafkreic3japs25s27r5k4ptt7ydein427quoceyo4rp6ac3m3umpw3msqu",
        "https://ipfs.filebase.io/ipfs/bafkreiaafatqttb3gvvq6fh3q27koiq3i5tn2xr5kz3ssoi55gp6jp5a24",
        "https://ipfs.filebase.io/ipfs/bafkreidihcyg5pu5ovbvtwrgyfkx4idimqqkbbikrhnhivfsgtejx4v7gi"
        ];

    string[] bearUrisIpfs = [
        "https://ipfs.filebase.io/ipfs/bafkreib34nlgc2ahuu524ef3pupziqzm4wihl5hp2ih245wghytjl2oeva",
        "https://ipfs.filebase.io/ipfs/bafkreigcvajzfkyb7flg4zldjexvat5vycyyznfkf4z73unnbybtw2grou",
        "https://ipfs.filebase.io/ipfs/bafkreibfz66q2pkzvlvwz2lrp72zz2aesiniba5asu7ewrm74tyb2slgdm"
    ];

    event TokensUpdated(string marketTrend);

    constructor(uint256 updateInterval, address _priceFeed) ERC721("Bull&Bear", "BBTK") {
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
                updateAllTokenUris("bear");
            } else {
                //bull
                updateAllTokenUris("bull");
            }

            currentPrice = latestPrice;

        } else {
            //Interval not elapsed. No upkeep.
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

    function updateAllTokenUris(string memory trend) internal {
        if(compareStrings("bear", trend)) {
            for(uint256 i = 0; i < _tokenIdCounter.current(); i++) {
                _setTokenURI(i, bearUrisIpfs[0]);
            }
        } else {
            for(uint256 i = 0; i < _tokenIdCounter.current(); i++) {
                _setTokenURI(i, bullUrisIpfs[0]);
            }
        }

        emit TokensUpdated(trend);
    }

    function setInterval(uint256 newInterval) public onlyOwner {
        interval = newInterval;
    }

    function setPriceFeed(address newFeed) public onlyOwner {
        priceFeed = AggregatorV3Interface(newFeed);
    }

    //helpers
    function compareStrings(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
    }

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