// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

contract NonFungibleNickname is ERC721Burnable, Pausable, Ownable {
    using Strings for uint256;

    uint256 private idDigits = 18;
    uint256 private idModulus = 10**idDigits;
    uint256 private mintPrice = 0.02 ether;

    string private _baseUri;

    mapping(uint256 => string) public nicknames;
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

    function generateCard(uint256 tokenId) public view returns (string memory) {
        bytes memory svg = abi.encodePacked(
            '<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="250" height="250" viewBox="0 0 250 250" version="1.1" fill="none">',
            "<title>Non Fungible Nickname #",
            nicknames[tokenId],
            "</title>",
            '<g id="nonfungiblenickname" stroke="none" stroke-width="1" fill="none" fill-rule="evenodd">',
            '<path fill="#000" d="M0 0 H250 V250 H0 V0 z"/>',
            '<g id="Group-6" transform="translate(70.000000, 105.000000)">',
            '<text text-anchor="middle" id="nonfungiblenickname" font-family="system-ui, -apple-system, BlinkMacSystemFont, Segoe UI, Roboto, Ubuntu, Helvetica Neue, Oxygen, Cantarell, sans-serif" font-size="20" font-weight="bold" fill="#FFFFFF">',
            '<tspan x="22.5%" y="26" class= "nickname">',
            nicknames[tokenId],
            "</tspan>",
            "</text></g></g></svg>"
        );

        return
            string(
                abi.encodePacked(
                    "data:image/svg+xml;base64,",
                    Base64.encode(svg)
                )
            );
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        bytes memory dataURI = abi.encodePacked(
            "{",
            '"name": "Non Fungible Nickname #',
            nicknames[tokenId],
            '",',
            '"description": "Your non fungible nickname",',
            '"image": "',
            generateCard(tokenId),
            '",',
            '"attributes": [{',
            '"trait_type": "Nickname",',
            '"value":"',
            nicknames[tokenId],
            '"',
            "}]",
            "}"
        );
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(dataURI)
                )
            );
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
        delete nicknames[tokenId];
    }

    function burnByVoted(uint256 tokenId) public virtual onlyOwner {
        require(
            !_fireProtection[tokenId],
            "Non Fungible Nickname: this token protected"
        );

        _burn(tokenId);
        delete nicknames[tokenId];
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

        nicknames[tokenId] = name;

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
