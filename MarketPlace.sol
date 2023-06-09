// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract Sniser is ERC721, ERC721URIStorage, Ownable, ERC721Enumerable {
    using Counters for Counters.Counter;

    uint256 rewardPercentage1 = 200;
    uint256 rewardPercentage2 = 40;
    uint256 rewardPercentage3 = 160;
    uint256 PercentageDivider = 1000;
    uint256 public tokenId;
    address public Token;
    address public taxReceiver;
    struct Token_list {
        uint256 price;
        address firstOwner;
        uint256 saleCounter;
        uint256 totalRoyalties;
    }

    mapping(uint256 => Token_list) public Sale;

    Counters.Counter private _tokenIdCounter;

    constructor(address _paymentToken) ERC721("Sniser", "MTK") {
        Token = _paymentToken;
        taxReceiver = msg.sender;
    }

    function changePaymentToken(address _Token) public onlyOwner {
        Token = _Token;
    }

    function safeMint(string memory uri, uint256 price) public {
        tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(msg.sender, tokenId);
        _setTokenURI(tokenId, uri);
        Sale[tokenId].price = price;
        Sale[tokenId].firstOwner = msg.sender;
    }

    function buyNfts(uint256 _tokenId, uint256 amount) public {
        Token_list storage sale = Sale[_tokenId];
        require(
            amount >= sale.price,
            "Please pay the required amount"
        );
        require(ownerOf(_tokenId) != msg.sender, "Owner can't buy his own NFT");
        require(_tokenId <= tokenId, "invalid NFT Id");
        if (sale.saleCounter < 1) {
            uint256 sniserPercentage = (amount * rewardPercentage1) /
                PercentageDivider;
            amount -= sniserPercentage;
            require(
                IERC20(Token).transferFrom(
                    msg.sender,
                    taxReceiver,
                    sniserPercentage
                ),
                "ERC20: Token transfer failed"
            );
            require(
                IERC20(Token).transferFrom(msg.sender, IERC721(address(this)).ownerOf(_tokenId), amount),
                "ERC720: Token transfer failed"
            );
            IERC721(address(this)).transferFrom(
                IERC721(address(this)).ownerOf(_tokenId),
                msg.sender,
                _tokenId
            );
        } else {
            uint256 sniserPercentage = (amount * rewardPercentage2) /
                PercentageDivider;
            uint256 firstOwnerPrecentage = (amount * rewardPercentage3) /
                PercentageDivider;
            amount = amount - (sniserPercentage + firstOwnerPrecentage);
            require(
                IERC20(Token).transferFrom(
                    msg.sender,
                    taxReceiver,
                    sniserPercentage
                ),
                "ERC20: Token transfer failed"
            );
            require(
                IERC20(Token).transferFrom(
                    msg.sender,
                    sale.firstOwner,
                    firstOwnerPrecentage
                ),
                "ERC20: Token transfer failed"
            );
            require(
                IERC20(Token).transferFrom(msg.sender, IERC721(address(this)).ownerOf(_tokenId), amount),
                "ERC20: Token transfer failed"
            );
            IERC721(address(this)).transferFrom(
                IERC721(address(this)).ownerOf(_tokenId),
                msg.sender,
                _tokenId
            );
            sale.totalRoyalties += firstOwnerPrecentage;
        }
        sale.saleCounter++;
    }

    function changeNftPrice(uint256 _tokenId, uint256 _price) public {
        require(
            ownerOf(_tokenId) == msg.sender,
            "Only Owner is able to change the price"
        );
        Sale[_tokenId].price = _price;
    }

    function withdrawToken(address _token, uint256 _amount) public onlyOwner {
        require(IERC20(_token).transfer(msg.sender, _amount));
    }

    function changeTaxReceiver(address _user) public onlyOwner {
        taxReceiver = _user;
    }

    function getNFtInfo(
        uint256 _tokenId
    )
        public
        view
        returns (
            uint256 _price,
            address _owner,
            address _firstOwner,
            uint256 _saleCounter,
            uint256 _totalRoyalties
        )
    {
        Token_list storage sale = Sale[_tokenId];
        _price = sale.price;
        _owner = IERC721(address(this)).ownerOf(_tokenId);
        _firstOwner = sale.firstOwner;
        _saleCounter = sale.saleCounter;
        _totalRoyalties = sale.totalRoyalties;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 _tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, _tokenId);
    }

    function _burn(
        uint256 _tokenId
    ) internal override(ERC721, ERC721URIStorage) {
        super._burn(_tokenId);
    }

    function tokenURI(
        uint256 _tokenId
    ) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(_tokenId);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}