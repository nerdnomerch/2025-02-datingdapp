# [H-1]Denial Of Service `MultiSigWallet` not accessible to users.
## Summary

Once users match, a `MultiSigWallet` is created with the two users address, where they can access the funds. This MultiSigWallet address is not saved anywhere. The user wont be able to interact with the wallet.


## Vulnerability Details
In [`LikeReistry::matchRewards`](https://github.com/CodeHawks-Contests/2025-02-datingdapp/blob/878bd34ef6607afe01f280cd5aedf3184fc4ca7b/src/LikeRegistry.sol#L50) a new `MultiSigWallet` is created with the two users addresses but it is not saved. The matched users can't access the wallet as they don't have the address.

## Impact
Matched users are unable to access `MultiSigWallet` as they can't see the contract address.

## Tools Used
```Solidity
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
       // this deploys a new wallet.
        MultiSigWallet multiSigWallet = new MultiSigWallet(user, user2);

        assertEq(address(multiSigWallet).balance, 1.8e18);
    }
```

## Recommendations
1. Emit an event with the wallet address after sending eth to the wallet. 
```Solidity
emit LikeRegistry_MatchRewardsEvent(address(multiSigWallet),   from,  to)
```
2. Add wallet registry in LikeRegistry contract that tracks the users and wallets.

# [H-1] Denial Of Service  in `LikeRegistry::likeUser` function as User Balances are Not Populated . Users can't access the funds when matched.

## Summary

LikeRegistry main function likeUser `LikeRegistry::likeUser`doesn't save user balances when a user likes another user nft profile. This leads to not tracking the users funds and they won't be able to withdraw  when they match.&#x20;

## Vulnerability Details

[LikeRegistry::likeUser](https://github.com/CodeHawks-Contests/2025-02-datingdapp/blob/878bd34ef6607afe01f280cd5aedf3184fc4ca7b/src/LikeRegistry.sol#L31) User balances are not populated with the eth amount sent to the contract as likeUser is called. LikeRegistry contract tracks users funds in the storage variable `userBalances`. This variable is not

## Impact

Matched users are not able to access their funds.
Contract owner is unable to access fees as the fees are calculated from the user balances as they are withdrawing.

## Proof of Code

Running this test confirms fees are not calculated as user balances are 0.
It reverts with  ` No fees to withdraw`

```JavaScript
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

```

```bash

forge test --mt testFeeWithdrawal      
[⠒] Compiling...
No files changed, compilation skipped

Ran 1 test for test/testLikeRegistry.t.sol:LikeRegistryTest
[FAIL: revert: No fees to withdraw] testFeeWithdrawal() (gas: 714043)
Suite result: FAILED. 0 passed; 1 failed; 0 skipped; finished in 1.07ms (177.37µs CPU time)

Ran 1 test suite in 7.15ms (1.07ms CPU time): 0 tests passed, 1 failed, 0 skipped (1 total tests)

Failing tests:
Encountered 1 failing test in test/testLikeRegistry.t.sol:LikeRegistryTest
[FAIL: revert: No fees to withdraw] testFeeWithdrawal() (gas: 714043)
```

## Recommendations

`userBalances[msg.sender] += msg.value;` should be add in the  `LikeRegistry::likeUser` as below. This will fix this vulnerability

```javascript
function likeUser(
        address liked
    ) external payable {
        require(msg.value >= 1 ether, "Must send at least 1 ETH");
        require(!likes[msg.sender][liked], "Already liked");
        require(msg.sender != liked, "Cannot like yourself");
        require(profileNFT.profileToToken(msg.sender) != 0, "Must have a profile NFT");
        require(profileNFT.profileToToken(liked) != 0, "Liked user must have a profile NFT");

        likes[msg.sender][liked] = true;
        userBalances[msg.sender] += msg.value;
        emit Liked(msg.sender, liked);

        // Check if mutual like
        if (likes[liked][msg.sender]) {
            matches[msg.sender].push(liked);
            matches[liked].push(msg.sender);
            emit Matched(msg.sender, liked);
            matchRewards(liked, msg.sender);
        }
    }
```
