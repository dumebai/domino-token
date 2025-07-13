pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/DominoVault.sol";
import "../src/DominoToken.sol";

contract DominoVaultTest is Test {
    DominoVault internal vault;
    DominoToken internal token;
    address internal alice = address(0x1);

    function setUp() public {
        token = new DominoToken();
        vault = new DominoVault(IDominoToken(address(token)));
        token.grantMintAndBurnRole(address(vault));
    }

    function testDepositMintsTokens() public {
        vm.deal(alice, 1 ether);
        vm.prank(alice);
        vault.deposit{value: 1 ether}();
        assertEq(token.balanceOf(alice), 1 ether);
    }

    function testRedeemBurnsAndReturnsEth() public {
        vm.deal(alice, 1 ether);
        vm.prank(alice);
        vault.deposit{value: 1 ether}();
        vm.prank(alice);
        vault.redeem(1 ether);
        assertEq(token.balanceOf(alice), 0);
        assertEq(alice.balance, 1 ether);
    }

    function testFuzzDepositRedeem(uint96 amount) public {
        vm.assume(amount > 0);
        vm.assume(amount < 10 ether);
        address user = address(0x11);
        vm.deal(user, uint256(amount));
        vm.prank(user);
        vault.deposit{value: amount}();
        assertEq(token.balanceOf(user), uint256(amount));
        vm.prank(user);
        vault.redeem(amount);
        assertEq(token.balanceOf(user), 0);
        assertEq(user.balance, uint256(amount));
    }

    function testRedeemRevertsOnTransferFail() public {
        NonPayableReceiver receiver = new NonPayableReceiver(vault);
        vm.deal(address(receiver), 1 ether);
        vm.expectRevert(DominoVault.DominoVault__RedeemFailed.selector);
        receiver.depositAndRedeem{value: 1 ether}(1 ether);
    }

    function testGetTokenAddress() public {
        assertEq(vault.getTokenAddress(), address(token));
    }
}

contract NonPayableReceiver {
    DominoVault internal vault;

    constructor(DominoVault _vault) {
        vault = _vault;
    }

    function depositAndRedeem(uint256 amount) external payable {
        vault.deposit{value: amount}();
        vault.redeem(amount);
    }

    fallback() external {
        revert("cannot receive");
    }
}
