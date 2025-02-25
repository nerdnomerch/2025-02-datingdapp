// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/MultiSig.sol";

contract MultiSigTest is Test {
    address user = address(0x123);
    address user2 = address(0x456);

    MultiSigWallet multiSigWallet;
    constructor() {
        multiSigWallet = new MultiSigWallet(user, user2);

        // deal to the wallet
        vm.deal(address(multiSigWallet), 2 ether);
    }

    function testSubmitTransaction() public {
        vm.prank(user);
        
        vm.expectEmit();
        // We emit the event we expect to see.
        emit MultiSigWallet.TransactionCreated(0, address(user), 2 ether);

        multiSigWallet.submitTransaction(user, 2 ether);
    }

    function testNonOwnerCannotSubmitTransaction() public {
        address user3 = address(0x789);
        vm.prank(user3);
        vm.expectRevert();
        multiSigWallet.submitTransaction(user3, 2 ether);
    }

    function testCannotSubmitTransactionWithZeroValue() public {
        vm.prank(user);
        vm.expectRevert();
        multiSigWallet.submitTransaction(user, 0 ether);
    }

    function testApproveTransaction() public {
        vm.prank(user);
        multiSigWallet.submitTransaction(user, 2 ether);

        vm.prank(user);

        vm.expectEmit();
        // We emit the event we expect to see.
        emit MultiSigWallet.TransactionApproved(0, user);
        multiSigWallet.approveTransaction(0);

        vm.prank(user2);
        vm.expectEmit();
        // We emit the event we expect to see.
        emit MultiSigWallet.TransactionApproved(0, user2);
        multiSigWallet.approveTransaction(0);
    }

    function testExecuteTransaction() public {
        vm.prank(user);
        multiSigWallet.submitTransaction(user, 2 ether);

        vm.prank(user);
        multiSigWallet.approveTransaction(0);

        vm.prank(user2);
        multiSigWallet.approveTransaction(0);

        vm.prank(user);
        vm.expectEmit();
        // We emit the event we expect to see.
        emit MultiSigWallet.TransactionExecuted(0, user, 2 ether);
        multiSigWallet.executeTransaction(0);

        assertEq(address(user).balance, 2 ether);
        assertEq(address(multiSigWallet).balance, 0 ether);
    }
}
