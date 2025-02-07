// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract SoulboundProfileNFT is ERC721, Ownable {
    error ERC721Metadata__URI_QueryFor_NonExistentToken();
    error SoulboundTokenCannotBeTransferred();

    uint256 private _nextTokenId;

    struct Profile {
        string name;
        uint8 age;
        string profileImage; // IPFS or other hosted image URL
    }

    mapping(address => uint256) public profileToToken; // Maps user to their profile NFT
    mapping(uint256 => Profile) private _profiles; // Stores profile metadata

    event ProfileMinted(address indexed user, uint256 tokenId, string name, uint8 age, string profileImage);
    event ProfileBurned(address indexed user, uint256 tokenId);

    constructor() ERC721("DatingDapp", "DTN") Ownable(msg.sender) {}

    /// @notice Mint a soulbound NFT representing the user's profile.
    function mintProfile(string memory name, uint8 age, string memory profileImage) external {
        require(profileToToken[msg.sender] == 0, "Profile already exists");

        uint256 tokenId = ++_nextTokenId;
        _safeMint(msg.sender, tokenId);

        // Store metadata on-chain
        _profiles[tokenId] = Profile(name, age, profileImage);
        profileToToken[msg.sender] = tokenId;

        emit ProfileMinted(msg.sender, tokenId, name, age, profileImage);
    }

    /// @notice Allow users to delete their profile (burn the NFT).
    function burnProfile() external {
        uint256 tokenId = profileToToken[msg.sender];
        require(tokenId != 0, "No profile found");
        require(ownerOf(tokenId) == msg.sender, "Not profile owner");

        _burn(tokenId);
        delete profileToToken[msg.sender];
        delete _profiles[tokenId];

        emit ProfileBurned(msg.sender, tokenId);
    }

    /// @notice App owner can block users
    function blockProfile(address blockAddress) external onlyOwner {
        uint256 tokenId = profileToToken[blockAddress];
        require(tokenId != 0, "No profile found");

        _burn(tokenId);
        delete profileToToken[blockAddress];
        delete _profiles[tokenId];

        emit ProfileBurned(blockAddress, tokenId);
    }

    /// @notice Override of transferFrom to prevent any transfer.
    function transferFrom(address, address, uint256) public pure override {
        // Soulbound token cannot be transferred
        revert SoulboundTokenCannotBeTransferred();
    }

    function safeTransferFrom(address, address, uint256, bytes memory) public pure override {
        // Soulbound token cannot be transferred
        revert SoulboundTokenCannotBeTransferred();
    }

    /// @notice Return on-chain metadata
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (ownerOf(tokenId) == address(0)) {
            revert ERC721Metadata__URI_QueryFor_NonExistentToken();
        }
        string memory profileName = _profiles[tokenId].name;
        uint256 profileAge = _profiles[tokenId].age;
        string memory imageURI = _profiles[tokenId].profileImage;
        return string(
            abi.encodePacked(
                _baseURI(),
                Base64.encode(
                    bytes( // bytes casting actually unnecessary as 'abi.encodePacked()' returns a bytes
                        abi.encodePacked(
                            '{"name":"',
                            profileName,
                            '", ',
                            '"description":"A soulbound dating profile NFT.", ',
                            '"attributes": [{"trait_type": "Age", "value": ',
                            Strings.toString(profileAge),
                            "}], ",
                            '"image":"',
                            imageURI,
                            '"}'
                        )
                    )
                )
            )
        );
    }
}
