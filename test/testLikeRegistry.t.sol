// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/LikeRegistry.sol";
import "../src/MultiSig.sol";

import {console} from "forge-std/Test.sol";

contract LikeRegistryTest is Test {
    address user = address(0x123);
    address user2 = address(0x456);
    address owner = address(this); // Test contract acts as the owner

    SoulboundProfileNFT soulboundNFT;
    LikeRegistry likeRegistry;

    function setUp() public {
        soulboundNFT = new SoulboundProfileNFT();
        likeRegistry = new LikeRegistry(address(soulboundNFT));
        vm.prank(user); // Simulates user calling the function
        soulboundNFT.mintProfile("Alice", 25, "ipfs://profileImage");

        vm.prank(user2); // Simulates user calling the function
        soulboundNFT.mintProfile("Bob", 39, "ipfs://profileImage");
    }


    function testUseCannotLikeUseWithoutEther() public {
        vm.prank(user);
        vm.expectRevert();
        likeRegistry.likeUser(address(user2)); // Should revert
    }

    function testCannotLikeSelf() public {
        vm.prank(user);
        vm.expectRevert();
        likeRegistry.likeUser(address(user)); // Should revert
    }

    function testCannotLikeUseWithoutProfile() public {
        address user3 = address(0x523);
        vm.prank(user);
        vm.expectRevert();
        likeRegistry.likeUser(address(user3)); // Should revert
    }

    function testCannotLikeWithoutProfile() public {
        address user3 = address(0x523);
        vm.prank(user3);
        vm.expectRevert();
        likeRegistry.likeUser(address(user2)); // Should revert
    }

    function testLikeUser() public {
        vm.deal(user, 2 ether);
        vm.prank(user);

        vm.expectEmit();
        // We emit the event we expect to see.
        emit LikeRegistry.Liked(address(user), address(user2));

        likeRegistry.likeUser{value: 1 ether}(address(user2));

        // assertEq(likeRegistry.userBalances[user], 1 ether);
    }

    function testMatchUser() public {
        vm.deal(user, 2 ether);
        vm.deal(user2, 2 ether);
        vm.prank(user);
        likeRegistry.likeUser{value: 1 ether}(address(user2));

        vm.expectEmit();
        // We emit the event we expect to see.
        emit LikeRegistry.Matched(user2, user);
        vm.prank(user2);
        likeRegistry.likeUser{value: 1 ether}(address(user));    

        // assertEq(likeRegistry.getUserBalance(user), 1 ether);

        vm.prank(user); 
        assertEq(likeRegistry.getMatches()[0], address(user2), "User should be matched");

    }


    function testMatchReward() public {
        vm.deal(user, 2 ether);
        vm.deal(user2, 2 ether);
        vm.prank(user);
        likeRegistry.likeUser{value: 1 ether}(address(user2));

        vm.prank(user2);
        likeRegistry.likeUser{value: 1 ether}(address(user));
        vm.prank(user2);
        assertEq(likeRegistry.getMatches()[0], address(user), "User should be matched");

        // How do we access the wallet without address
        MultiSigWallet multiSigWallet = new MultiSigWallet(user, user2);

        assertEq(address(multiSigWallet).balance, 1.8e18);
    }

    function testFeeWithdrawal() public {
        vm.deal(user, 2 ether);
        vm.deal(user2, 2 ether);
        vm.prank(user);
        likeRegistry.likeUser{value: 1 ether}(address(user2));

        vm.prank(user2);
        likeRegistry.likeUser{value: 1 ether}(address(user));
        vm.prank(user2);
        assertEq(likeRegistry.getMatches()[0], address(user), "User should be matched");

        uint256 pre_balance = address(owner).balance;
        vm.prank(owner);
        likeRegistry.withdrawFees();
        assertTrue(address(owner).balance > pre_balance, "Owner should receive fees");
    }

}
