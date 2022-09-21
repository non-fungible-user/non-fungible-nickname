// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NonFungibleNickname is ERC721Burnable, Pausable, Ownable {
    uint256 private idDigits = 18;
    uint256 private idModulus = 10**idDigits;
    uint256 private mintPrice = 0.02 ether;

    string private _baseUri;

    mapping(uint256 => string) nicknames;
    mapping(uint256 => bool) private _fireProtection;

    event Mint(address indexed to, uint256 indexed tokenId);

    constructor() ERC721("Non Fungible Nickname", "NFN") {}

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseUri = baseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseUri;
    }

    function _generateRandomId(string memory _str)
        private
        view
        returns (uint256)
    {
        uint256 rand = uint256(keccak256(abi.encodePacked(_str)));
        return rand % idModulus;
    }

    function generateRandomId(string memory _name)
        public
        view
        returns (uint256)
    {
        uint256 randId = _generateRandomId(_name);
        randId = randId - (randId % 100);
        return randId;
    }

    function burn(uint256 tokenId) public virtual override {
        //solhint-disable-next-line max-line-length
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "Non Fungible Nickname: caller is not token owner nor approved"
        );

        require(
            !_fireProtection[tokenId],
            "Non Fungible Nickname: this token protected"
        );
        _burn(tokenId);
    }

    function burnByVoted(uint256 tokenId) public virtual onlyOwner {
        require(
            !_fireProtection[tokenId],
            "Non Fungible Nickname: this token protected"
        );
        _burn(tokenId);
    }

    function protectFromFire(uint256 tokenId) public onlyOwner {
        _fireProtection[tokenId] = true;
    }

    function dispelProtectionFromFire(uint256 tokenId) public onlyOwner {
        _fireProtection[tokenId] = false;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function safeMint(string memory name) public payable {
        if (msg.sender != owner()) {
            require(
                msg.value == mintPrice,
                "Non Fungible Nickname: wrong value"
            );
        }

        uint256 tokenId = generateRandomId(name);
        _safeMint(msg.sender, tokenId);

        emit Mint(msg.sender, tokenId);
    }

    function withdraw() external onlyOwner {
        (bool success, ) = owner().call{value: address(this).balance}("");
        require(success);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId);
    }
}
