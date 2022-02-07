// SPDX-License-Identifier: MIT

// Amended by HashLips
/**
    !Disclaimer!
    These contracts have been used to create tutorials,
    and was created for the purpose to teach people
    how to create smart contracts on the blockchain.
    please review this code on your own before using any of
    the following code for production.
    HashLips will not be liable in any way if for the use 
    of the code. That being said, the code has been tested 
    to the best of the developers' knowledge to work as intended.
*/

pragma solidity >=0.7.0 <0.9.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NFT is ERC721Enumerable, Ownable {
    using Strings for uint256;

    string baseURI;
    string public baseExtension = ".json";
    uint256 public mintCost = 0;

    uint256 public maxSupply = 10;
    uint256 public maxMintAmount = 3;
    bool public paused = false;
    bool public revealed = false;
    string public notRevealedUri;

    address public artist;
    uint256 public royaltyFeeArtist = 25;
    uint256 public royaltyFeeMinter = 25;
    address[20] public minters;

     event Sale(address from, address to, uint256 value);

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _initBaseURI,
        string memory _initNotRevealedUri
    ) ERC721(_name, _symbol) {
        setBaseURI(_initBaseURI);
        setNotRevealedURI(_initNotRevealedUri);
    }

    // internal
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

  // public
    function mint(uint256 _mintAmount) public payable {
        uint256 supply = totalSupply();
        if (supply > 3) mintCost = 0.01 ether;
        if (supply > 5) mintCost = 0.02 ether;
        if (supply > 7) mintCost = 0.03 ether;
        require(!paused);
        require(_mintAmount > 0);
        require(_mintAmount <= maxMintAmount);
        require(supply + _mintAmount <= maxSupply);

        if (msg.sender != owner()) {
         require(msg.value >= mintCost * _mintAmount);
        }

        for (uint256 i = 1; i <= _mintAmount; i++) {
            _safeMint(msg.sender, supply + i);
            minters[supply + i] = msg.sender;
        }
    }

    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
        tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
        _exists(tokenId),
        "ERC721Metadata: URI query for nonexistent token"
        );
        
        if(revealed == false) {
            return notRevealedUri;
        }

        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
            : "";
    }

    //only owner
    function reveal() public onlyOwner {
        revealed = true;
    }
    
    function setCost(uint256 _newCost) public onlyOwner {
        mintCost = _newCost;
    }

    function setmaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner {
        maxMintAmount = _newmaxMintAmount;
    }
    
    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
        baseExtension = _newBaseExtension;
    }

    function pause(bool _state) public onlyOwner {
        paused = _state;
    }
 
    function withdraw() public payable onlyOwner {
        // This will pay HashLips 5% of the initial sale.
        // You can remove this if you want, or keep it in to support HashLips and his channel.
        // =============================================================================
        // =============================================================================
        (bool hs, ) = payable(0xD59bcb64A7F3cd8C6B869117e8adbF759111E475).call{value: address(this).balance * 15 / 100}("");
        require(hs);
        // This will payout the owner 95% of the contract balance.
        // Do not remove this otherwise you will not be able to withdraw the funds.
        // =============================================================================
        (bool os, ) = payable(0xD59bcb64A7F3cd8C6B869117e8adbF759111E475).call{value: address(this).balance}("");
        require(os);
        // =============================================================================
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );

        if (msg.value > 0) {
            uint256 royaltyArtist = (msg.value * royaltyFeeArtist) / 100;
            _payRoyaltyArtist(royaltyArtist);

            uint256 royaltyMinter = (msg.value * royaltyFeeMinter) / 100;
            _payRoyaltyMinter(royaltyMinter, tokenId);

            emit Sale(from, to, msg.value);
        }

        _transfer(from, to, tokenId);
    }


    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public payable override {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );

        if (msg.value > 0) {
            uint256 royaltyArtist = (msg.value * royaltyFeeArtist) / 100;
            _payRoyaltyArtist(royaltyArtist);

             uint256 royaltyMinter = (msg.value * royaltyFeeMinter) / 100;
            _payRoyaltyMinter(royaltyMinter, tokenId);

            (bool success3, ) = payable(from).call{value: msg.value - royaltyArtist - royaltyMinter}(
                ""
            );
            require(success3);

            emit Sale(from, to, msg.value);
        }

        _safeTransfer(from, to, tokenId, _data);
    }


    function _payRoyaltyArtist(uint256 _royaltyFeeArtist) internal {
        (bool success1, ) = payable(0xD59bcb64A7F3cd8C6B869117e8adbF759111E475).call{value: _royaltyFeeArtist}("");
        require(success1);
    }

    function _payRoyaltyMinter(uint256 _royaltyFeeMinter, uint256 _tokenId) internal {
        (bool success2, ) = payable(minters[_tokenId]).call{value: _royaltyFeeMinter}("");
        require(success2);
    }
}