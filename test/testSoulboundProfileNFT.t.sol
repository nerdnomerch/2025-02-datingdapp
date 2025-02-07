// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/SoulboundProfileNFT.sol";

contract SoulboundProfileNFTTest is Test {
    SoulboundProfileNFT soulboundNFT;
    address user = address(0x123);
    address user2 = address(0x456);
    address owner = address(this); // Test contract acts as the owner

    function setUp() public {
        soulboundNFT = new SoulboundProfileNFT();
    }

    function testMintProfile() public {
        vm.prank(user); // Simulates user calling the function
        soulboundNFT.mintProfile("Alice", 25, "ipfs://profileImage");

        uint256 tokenId = soulboundNFT.profileToToken(user);
        assertEq(tokenId, 1, "Token ID should be 1");

        string memory uri = soulboundNFT.tokenURI(tokenId);
        assertTrue(bytes(uri).length > 0, "Token URI should be set");
    }

    function testMintDuplicateProfile() public {
        vm.prank(user);
        soulboundNFT.mintProfile("Alice", 25, "ipfs://profileImage");

        vm.prank(user);
        vm.expectRevert("Profile already exists");
        soulboundNFT.mintProfile("Alice", 25, "ipfs://profileImage");
    }

    function testTokenURI() public {
        vm.prank(user);
        soulboundNFT.mintProfile("Alice", 25, "ipfs://profileImage");

        uint256 tokenId = soulboundNFT.profileToToken(user);
        string memory uri = soulboundNFT.tokenURI(tokenId);

        assertTrue(bytes(uri).length > 0, "Token URI should be encoded in Base64");
    }

    function testTransferShouldRevert() public {
        vm.prank(user);
        soulboundNFT.mintProfile("Alice", 25, "ipfs://profileImage");

        uint256 tokenId = soulboundNFT.profileToToken(user);

        vm.prank(user);
        vm.expectRevert();
        soulboundNFT.transferFrom(user, user2, tokenId); // Should revert
    }

    function testSafeTransferShouldRevert() public {
        vm.prank(user);
        soulboundNFT.mintProfile("Alice", 25, "ipfs://profileImage");

        uint256 tokenId = soulboundNFT.profileToToken(user);

        vm.prank(user);
        vm.expectRevert();
        soulboundNFT.safeTransferFrom(user, user2, tokenId); // Should revert
    }

    function testBurnProfile() public {
        vm.prank(user);
        soulboundNFT.mintProfile("Alice", 25, "ipfs://profileImage");

        uint256 tokenId = soulboundNFT.profileToToken(user);
        assertEq(tokenId, 1, "Token ID should be 1 before burning");

        vm.prank(user);
        soulboundNFT.burnProfile();

        uint256 newTokenId = soulboundNFT.profileToToken(user);
        assertEq(newTokenId, 0, "Token should be removed after burning");
    }

    function testBlockProfileAsOwner() public {
        vm.prank(user);
        soulboundNFT.mintProfile("Alice", 25, "ipfs://profileImage");

        uint256 tokenId = soulboundNFT.profileToToken(user);
        assertEq(tokenId, 1, "Token should exist before blocking");

        vm.prank(owner);
        soulboundNFT.blockProfile(user);

        uint256 newTokenId = soulboundNFT.profileToToken(user);
        assertEq(newTokenId, 0, "Token should be removed after blocking");
    }

    function testNonOwnerCannotBlockProfile() public {
        vm.prank(user);
        soulboundNFT.mintProfile("Alice", 25, "ipfs://profileImage");

        uint256 tokenId = soulboundNFT.profileToToken(user);
        assertEq(tokenId, 1, "Token should exist before blocking");

        vm.prank(user2);
        vm.expectRevert();
        soulboundNFT.blockProfile(user); // Should revert
    }
}
